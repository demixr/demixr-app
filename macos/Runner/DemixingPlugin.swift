//
//  DemixingPlugin.swift
//  Runner
//
//  macOS implementation of the demixing plugin using Executorch.
//  Uses MPS (Metal Performance Shaders) backend for GPU acceleration.
//

import Foundation
import FlutterMacOS

// MARK: - Demixing Errors

enum DemixingError: LocalizedError {
    case invalidWavFile(String)
    case modelLoadFailed(String)
    case inferenceFailed(String)
    case fileWriteFailed(String)

    init(_ message: String) {
        self = .invalidWavFile(message)
    }

    var errorDescription: String? {
        switch self {
        case .invalidWavFile(let msg):
            return "Invalid WAV file: \(msg)"
        case .modelLoadFailed(let msg):
            return "Failed to load model: \(msg)"
        case .inferenceFailed(let msg):
            return "Inference failed: \(msg)"
        case .fileWriteFailed(let msg):
            return "Failed to write output file: \(msg)"
        }
    }
}

// MARK: - WAV File Reader/Writer

/// Reads and writes WAV files. Based on the Java WavFile class.
class WavFile {
    enum IOState {
        case reading, writing, closed
    }

    private static let bufferSize = 4096
    private static let fmtChunkId: UInt32 = 0x66_74_6d_66  // "fmt "
    private static let dataChunkId: UInt32 = 0x64_61_74_61  // "data"
    private static let riffChunkId: UInt32 = 0x52_49_46_46  // "RIFF"
    private static let riffTypeId: UInt32 = 0x57_41_56_45  // "WAVE"

    var file: URL?
    private var ioState: IOState = .closed
    private var bytesPerSample: Int = 0
    private(set) var numFrames: Int64 = 0
    private var oStream: OutputStream?
    private var iStream: InputStream?
    private var floatScale: Float = 1.0
    private var floatOffset: Float = 0.0
    private var wordAlignAdjust: Bool = false

    private(set) var numChannels: Int = 0
    private(set) var sampleRate: Int64 = 0
    private var blockAlign: Int = 0
    private(set) var validBits: Int = 0

    private var buffer: [UInt8] = []
    private var bufferPointer: Int = 0
    private var bytesRead: Int = 0
    private var frameCounter: Int64 = 0

    private init() {
        buffer = [UInt8](repeating: 0, count: WavFile.bufferSize)
    }

    func getNumChannels() -> Int { return numChannels }
    func getNumFrames() -> Int64 { return numFrames }
    func getFramesRemaining() -> Int64 { return numFrames - frameCounter }
    func getSampleRate() -> Int64 { return sampleRate }
    func getValidBits() -> Int { return validBits }
    func getFile() -> URL? { return file }

    static func newWavFile(
        file: URL,
        numChannels: Int,
        numFrames: Int64,
        validBits: Int,
        sampleRate: Int64
    ) throws -> WavFile {
        let wavFile = WavFile()
        wavFile.file = file
        wavFile.numChannels = numChannels
        wavFile.numFrames = numFrames
        wavFile.sampleRate = sampleRate
        wavFile.bytesPerSample = (validBits + 7) / 8
        wavFile.blockAlign = wavFile.bytesPerSample * numChannels
        wavFile.validBits = validBits

        if numChannels < 1 || numChannels > 65535 {
            throw DemixingError("Invalid number of channels: \(numChannels)")
        }

        if sampleRate < 1 || sampleRate > 4294967295 {
            throw DemixingError("Invalid sample rate: \(sampleRate)")
        }

        if validBits < 2 || validBits > 64 {
            throw DemixingError("Invalid valid bits: \(validBits)")
        }

        wavFile.floatScale = 1.0 / Float(pow(2.0, Double(validBits - 1)))
        wavFile.floatOffset = 1.0

        guard let outputStream = OutputStream(toFileAtPath: file.path, append: false) else {
            throw DemixingError("Could not create output stream")
        }
        wavFile.oStream = outputStream
        wavFile.ioState = .writing

        wavFile.writeHeader(numChannels, numFrames, validBits, sampleRate)
        outputStream.close()
        wavFile.ioState = .closed

        return wavFile
    }

    static func openWavFile(file: URL) throws -> WavFile {
        let wavFile = WavFile()
        wavFile.file = file

        guard let inputStream = InputStream(url: file) else {
            throw DemixingError("Could not open file: \(file.path)")
        }
        wavFile.iStream = inputStream
        wavFile.ioState = .reading

        try wavFile.readHeader()

        return wavFile
    }

    private func readHeader() throws {
        let stream = iStream!
        stream.open()
        defer { stream.close() }

        var data = [UInt8](repeating: 0, count: 16)
        guard stream.read(&data, maxLength: 16) == 16 else {
            throw DemixingError("File too small to be a WAV file")
        }

        // Check RIFF header (little-endian)
        let riffId = UInt32(littleEndian: UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24))
        if riffId != WavFile.riffChunkId {
            throw DemixingError("Not a WAV file (bad RIFF ID)")
        }

        // Check WAV type (little-endian)
        let wavType = UInt32(littleEndian: UInt32(data[8]) | (UInt32(data[9]) << 8) | (UInt32(data[10]) << 16) | (UInt32(data[11]) << 24))
        if wavType != WavFile.riffTypeId {
            throw DemixingError("Not a WAV file (bad WAV type)")
        }

        var offset = 12
        while offset < 16 {
            let chunkId = UInt32(littleEndian: UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24))

            if chunkId == WavFile.fmtChunkId {
                guard stream.read(&data, maxLength: 24) == 24 else { break }

                let audioFormat = UInt16(littleEndian: UInt16(data[0]) | (UInt16(data[1]) << 8))
                if audioFormat != 1 {
                    throw DemixingError("Unsupported audio format: \(audioFormat)")
                }

                numChannels = Int(UInt16(littleEndian: UInt16(data[2]) | (UInt16(data[3]) << 8)))
                sampleRate = Int64(UInt32(littleEndian: UInt32(data[4]) | (UInt32(data[5]) << 8) | (UInt32(data[6]) << 16) | (UInt32(data[7]) << 24)))
                blockAlign = Int(UInt16(littleEndian: UInt16(data[16]) | (UInt16(data[17]) << 8)))
                validBits = Int(UInt16(littleEndian: UInt16(data[18]) | (UInt16(data[19]) << 8)))

                bytesPerSample = (validBits + 7) / 8
                floatScale = 1.0 / Float(pow(2.0, Double(validBits - 1)))
                floatOffset = 1.0

                let extraParamSize = UInt16(littleEndian: UInt16(data[20]) | (UInt16(data[21]) << 8))
                offset = 12 + 4 + 4 + 24 + Int(extraParamSize)
            } else if chunkId == WavFile.dataChunkId {
                let dataSize = Int64(UInt32(littleEndian: UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24)))
                numFrames = dataSize / Int64(blockAlign)
                wordAlignAdjust = (dataSize % 2 != 0)
                break
            } else {
                let chunkSize = UInt32(littleEndian: UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24))
                offset += 8 + Int(chunkSize)
            }

            guard stream.read(&data, maxLength: 4) == 4 else { break }
        }

        if numChannels == 0 {
            throw DemixingError("Could not parse WAV header")
        }
    }

    private func writeHeader(
        _ numChannels: Int,
        _ numFrames: Int64,
        _ validBits: Int,
        _ sampleRate: Int64
    ) {
        let stream = oStream!
        stream.open()

        let dataSize = numFrames * Int64(blockAlign)
        let fileSize = 36 + dataSize

        func writeUInt32LE(_ value: UInt32) {
            var bytes = [UInt8](repeating: 0, count: 4)
            bytes[0] = UInt8(value & 0xFF)
            bytes[1] = UInt8((value >> 8) & 0xFF)
            bytes[2] = UInt8((value >> 16) & 0xFF)
            bytes[3] = UInt8((value >> 24) & 0xFF)
            stream.write(&bytes, maxLength: 4)
        }

        func writeUInt16LE(_ value: UInt16) {
            var bytes = [UInt8](repeating: 0, count: 2)
            bytes[0] = UInt8(value & 0xFF)
            bytes[1] = UInt8((value >> 8) & 0xFF)
            stream.write(&bytes, maxLength: 2)
        }

        // RIFF header
        writeUInt32LE(WavFile.riffChunkId)
        writeUInt32LE(UInt32(fileSize))

        // WAV type
        writeUInt32LE(WavFile.riffTypeId)

        // fmt chunk
        writeUInt32LE(WavFile.fmtChunkId)
        writeUInt32LE(16)  // fmt chunk size

        // fmt chunk data (little-endian)
        writeUInt16LE(1)  // audio format (PCM)
        writeUInt16LE(UInt16(numChannels))
        writeUInt32LE(UInt32(sampleRate))
        writeUInt32LE(UInt32(sampleRate * Int64(blockAlign)))
        writeUInt16LE(UInt16(blockAlign))
        writeUInt16LE(UInt16(validBits))

        // data chunk
        writeUInt32LE(WavFile.dataChunkId)
        writeUInt32LE(UInt32(dataSize))

        stream.close()
    }

    func readFrames(_ buffer: inout [Float], _ maxFrames: Int64) -> Int64 {
        let stream = iStream!
        stream.open()

        let bytesPerFrame = blockAlign
        let maxBytes = Int(maxFrames) * bytesPerFrame
        let bytesToRead = min(maxBytes, Int(numFrames - frameCounter) * bytesPerFrame)

        if bytesToRead == 0 {
            stream.close()
            return 0
        }

        var fileData = [UInt8](repeating: 0, count: bytesToRead)
        let bytesRead = stream.read(&fileData, maxLength: bytesToRead)

        stream.close()

        if bytesRead == 0 {
            return 0
        }

        let framesRead = Int64(bytesRead / bytesPerFrame)
        var sampleIndex = 0

        for _ in 0..<framesRead {
            for channel in 0..<numChannels {
                let sampleOffset = sampleIndex + channel
                let bytes = fileData[sampleOffset..<sampleOffset + bytesPerSample]

                var sample: Int32 = 0
                switch bytesPerSample {
                case 1:
                    sample = Int32(bytes[0]) - 128
                case 2:
                    let b0 = Int32(bytes[0])
                    let b1 = Int32(bytes[1])
                    sample = (b1 << 8) | b0
                    if sample >= 32768 {
                        sample -= 65536
                    }
                case 3:
                    let b0 = Int32(bytes[0])
                    let b1 = Int32(bytes[1])
                    let b2 = Int32(bytes[2])
                    sample = (b2 << 16) | ((b1 & 0xFF) << 8) | (b0 & 0xFF)
                    if sample >= (1 << 15) {
                        sample -= 1 << 16
                    }
                case 4:
                    let b0 = Int32(bytes[0])
                    let b1 = Int32(bytes[1])
                    let b2 = Int32(bytes[2])
                    let b3 = Int32(bytes[3])
                    sample = (b3 << 24) | ((b2 & 0xFF) << 16) | ((b1 & 0xFF) << 8) | (b0 & 0xFF)
                default:
                    sample = 0
                }

                let floatSample = (Float(sample) + floatOffset) * floatScale
                buffer[Int(frameCounter) * numChannels + channel] = floatSample
                sampleIndex += bytesPerSample
            }
            frameCounter += 1
        }

        return framesRead
    }

    func writeFrames(_ buffer: [[Float]], _ numFrames: Int64) throws {
        let stream = oStream!
        stream.open()

        func writeInt16LE(_ value: Int16) {
            var bytes = [UInt8](repeating: 0, count: 2)
            bytes[0] = UInt8(value & 0xFF)
            bytes[1] = UInt8((value >> 8) & 0xFF)
            stream.write(&bytes, maxLength: 2)
        }

        func writeInt32LE(_ value: Int32) {
            var bytes = [UInt8](repeating: 0, count: 4)
            bytes[0] = UInt8(value & 0xFF)
            bytes[1] = UInt8((value >> 8) & 0xFF)
            bytes[2] = UInt8((value >> 16) & 0xFF)
            bytes[3] = UInt8((value >> 24) & 0xFF)
            stream.write(&bytes, maxLength: 4)
        }

        for frame in 0..<numFrames {
            for stem in buffer.indices {
                for channel in 0..<numChannels {
                    let sample = buffer[stem][Int(frame) * numChannels + channel]
                    let intSample = Int32(sample * floatScale - floatOffset)

                    switch bytesPerSample {
                    case 1:
                        let clamped = max(0, min(255, Int(intSample) + 128))
                        var bytes = [UInt8](repeating: 0, count: 1)
                        bytes[0] = UInt8(clamped)
                        stream.write(&bytes, maxLength: 1)
                    case 2:
                        writeInt16LE(Int16(max(-32768, min(32767, Int(intSample)))))
                    case 4:
                        writeInt32LE(Int32(max(-2147483648, min(2147483647, Int(intSample)))))
                    default:
                        break
                    }
                }
            }
        }

        stream.close()
        ioState = .closed
    }

    func close() throws {
        if ioState == .writing {
            oStream?.close()
        } else if ioState == .reading {
            iStream?.close()
        }
        ioState = .closed
    }
}

// MARK: - Demixing Plugin

/// Flutter plugin for music source separation (demixing) on macOS.
/// Uses Executorch with MPS (Metal GPU) backend for accelerated inference.
public class DemixingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    // MARK: - Constants

    private static let channelName = "demixing"
    private static let eventName = "demixing/progress"
    private static let separateMethod = "separate"
    private static let numBufferFrame = 250000
    private static let mono = 1
    private static let stereo = 2
    private static let sampleRateValue = 44100

    // MARK: - Properties

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var progressSink: ((Any?) -> Void)?

    // MARK: - FlutterPlugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = DemixingPlugin()
        let messenger = registrar.messenger

        instance.methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: messenger
        )
        instance.methodChannel?.setMethodCallHandler(instance.handle)

        instance.eventChannel = FlutterEventChannel(
            name: eventName,
            binaryMessenger: messenger
        )
        instance.eventChannel?.setStreamHandler(instance)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink: @escaping (Any?) -> Void) -> FlutterError? {
        progressSink = eventSink
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        progressSink = nil
        return nil
    }

    // MARK: - Method Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == DemixingPlugin.separateMethod else {
            result(FlutterMethodNotImplemented)
            return
        }

        guard let args = call.arguments as? [String: Any],
              let audioPath = args["songPath"] as? String,
              let modelPath = args["modelPath"] as? String,
              let outputDir = args["outputPath"] as? String else {
            result(FlutterError(
                code: "InvalidArguments",
                message: "Missing required arguments",
                details: nil
            ))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { result(FlutterError(code: "PluginDisposed", message: "Plugin was disposed", details: nil)) }
                return
            }

            do {
                let stems = try self.separate(audioPath: audioPath, modelPath: modelPath, outputDir: outputDir)
                DispatchQueue.main.async { result(stems) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "DemixingError",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    // MARK: - Demixing Implementation

    private func separate(audioPath: String, modelPath: String, outputDir: String) throws -> [String: String] {
        try loadModel(modelPath: modelPath)

        let inputWav = try WavFile.openWavFile(file: URL(fileURLWithPath: audioPath))

        let numChannels = inputWav.getNumChannels()
        let numFrames = inputWav.getNumFrames()
        let numStems = 4
        let numBits = 16

        let stemNames = ["vocals", "drums", "bass", "other"]

        var stemFiles: [String: WavFile] = [:]
        for stemName in stemNames {
            let stemUrl = URL(fileURLWithPath: outputDir).appendingPathComponent("\(stemName).wav")
            stemFiles[stemName] = try WavFile.newWavFile(
                file: stemUrl,
                numChannels: numChannels,
                numFrames: numFrames,
                validBits: numBits,
                sampleRate: Int64(DemixingPlugin.sampleRateValue)
            )
        }

        try predictByChunk(
            wavFile: inputWav,
            stemFiles: stemFiles,
            stemNames: stemNames,
            numStems: numStems
        )

        try inputWav.close()
        for stemName in stemNames {
            try stemFiles[stemName]?.close()
        }

        var result: [String: String] = [:]
        for stemName in stemNames {
            result[stemName] = stemFiles[stemName]?.getFile()?.path
        }

        return result
    }

    // MARK: - Model Loading (Executorch)

    private func loadModel(modelPath: String) throws {
        // TODO: Implement Executorch model loading with MPS backend
        // The model will be loaded once and cached for reuse
        // Use executorch_flutter API:
        //   - Load .pte model file
        //   - Configure MPS backend for GPU acceleration
        //   - Cache the loaded model for reuse
        throw DemixingError("Executorch model loading not yet implemented")
    }

    // MARK: - Audio Preprocessing

    private func monoToStereo(buffer: [Float], framesRead: Int64) -> [Float] {
        var stereoBuffer = [Float]()
        for frame in 0..<Int(framesRead) {
            stereoBuffer.append(buffer[frame])
            stereoBuffer.append(buffer[frame])
        }
        return stereoBuffer
    }

    // MARK: - Inference (Stub)

    private func predictByChunk(
        wavFile: WavFile,
        stemFiles: [String: WavFile],
        stemNames: [String],
        numStems: Int
    ) throws {
        let numChannels = wavFile.getNumChannels()
        let numFrames = wavFile.getNumFrames()
        let nbChunks = Int(numFrames / Int64(DemixingPlugin.numBufferFrame)) + 1

        var buffer = [Float](repeating: 0, count: Int(DemixingPlugin.numBufferFrame) * numChannels)
        var framesRead = wavFile.readFrames(&buffer, Int64(DemixingPlugin.numBufferFrame))

        var currentChunk = 0.0

        while framesRead != 0 {
            if wavFile.getSampleRate() != Int64(DemixingPlugin.sampleRateValue) {
                buffer = try resample(
                    buffer: buffer,
                    numInputFrames: framesRead,
                    inputSampleRate: wavFile.getSampleRate(),
                    channelCount: numChannels
                )
                framesRead = Int64(buffer.count / numChannels)
            }

            // TODO: Run Executorch inference here
            // Use executorch_flutter API:
            //   - Create tensor from buffer
            //   - Run model forward pass with MPS backend
            //   - Get 4-stem output

            currentChunk += 1
            let demixingPercentage = currentChunk / Double(nbChunks)

            if let sink = progressSink {
                DispatchQueue.main.async {
                    sink(demixingPercentage)
                }
            }

            buffer = [Float](repeating: 0, count: Int(DemixingPlugin.numBufferFrame) * numChannels)
            framesRead = wavFile.readFrames(&buffer, Int64(DemixingPlugin.numBufferFrame))
        }
    }

    // MARK: - Resampling (stub)

    private func resample(
        buffer: [Float],
        numInputFrames: Int64,
        inputSampleRate: Int64,
        channelCount: Int
    ) throws -> [Float] {
        // TODO: Implement audio resampling to 44100 Hz
        return buffer
    }
}
