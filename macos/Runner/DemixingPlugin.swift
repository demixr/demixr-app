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
        reading,
        writing,
        closed
    }

    private static let bufferSize = 4096
    private static let fmtChunkId = 0x20746d66
    private static let dataChunkId = 0x61746164
    private static let riffChunkId = 0x46464952
    private static let riffTypeId = 0x45564157

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
        buffer = [UInt8](repeating: 0, count: bufferSize)
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

        let riffId = ByteOrder.bigEndian.decode(data[0..<4], as: UInt32.self)
        if riffId != riffChunkId {
            throw DemixingError("Not a WAV file (bad RIFF ID)")
        }

        let wavType = ByteOrder.bigEndian.decode(data[8..<12], as: UInt32.self)
        if wavType != riffTypeId {
            throw DemixingError("Not a WAV file (bad WAV type)")
        }

        var offset = 12
        while offset < 16 {
            let chunkIdData = [UInt8](repeating: 0, count: 4)
            guard stream.read(&data, maxLength: 4) == 4 else { break }
            let chunkId = ByteOrder.bigEndian.decode(data[0..<4], as: UInt32.self)

            if chunkId == fmtChunkId {
                guard stream.read(&data, maxLength: 24) == 24 else { break }

                let audioFormat = UInt16(ByteOrder.bigEndian.decode(data[0..<2], as: UInt16.self))
                if audioFormat != 1 {
                    throw DemixingError("Unsupported audio format: \(audioFormat)")
                }

                numChannels = Int(ByteOrder.bigEndian.decode(data[2..<4], as: UInt16.self))
                sampleRate = Int64(ByteOrder.bigEndian.decode(data[4..<8], as: UInt32.self))
                blockAlign = Int(ByteOrder.bigEndian.decode(data[16..<18], as: UInt16.self))
                validBits = Int(ByteOrder.bigEndian.decode(data[18..<20], as: UInt16.self))

                bytesPerSample = (validBits + 7) / 8
                floatScale = 1.0 / Float(pow(2.0, Double(validBits - 1)))
                floatOffset = 1.0

                let extraParamSize = Int(ByteOrder.bigEndian.decode(data[20..<22], as: UInt16.self))
                offset = 12 + 4 + 4 + 24 + extraParamSize
            } else if chunkId == dataChunkId {
                let dataSize = Int64(ByteOrder.bigEndian.decode(data[0..<4], as: UInt32.self))
                numFrames = dataSize / Int64(blockAlign)
                wordAlignAdjust = (dataSize % 2 != 0)
                break
            } else {
                let chunkSizeData = [UInt8](repeating: 0, count: 4)
                guard stream.read(&data, maxLength: 4) == 4 else { break }
                let chunkSize = Int(ByteOrder.bigEndian.decode(data[0..<4], as: UInt32.self))
                offset += 8 + chunkSize
            }
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

        var riffIdData = [UInt8](repeating: 0, count: 4)
        ByteOrder.bigEndian.encode(riffChunkId, into: &riffIdData)
        stream.write(&riffIdData, maxLength: 4)

        var fileSizeData = [UInt8](repeating: 0, count: 4)
        ByteOrder.bigEndian.encode(UInt32(fileSize), into: &fileSizeData)
        stream.write(&fileSizeData, maxLength: 4)

        var wavTypeData = [UInt8](repeating: 0, count: 4)
        ByteOrder.bigEndian.encode(riffTypeId, into: &wavTypeData)
        stream.write(&wavTypeData, maxLength: 4)

        var fmtIdData = [UInt8](repeating: 0, count: 4)
        ByteOrder.bigEndian.encode(fmtChunkId, into: &fmtIdData)
        stream.write(&fmtIdData, maxLength: 4)

        var fmtSizeData = [UInt8](repeating: 0, count: 4)
        ByteOrder.bigEndian.encode(UInt32(16), into: &fmtSizeData)
        stream.write(&fmtSizeData, maxLength: 4)

        var audioFormatData = [UInt8](repeating: 0, count: 2)
        ByteOrder.littleEndian.encode(UInt16(1), into: &audioFormatData)
        stream.write(&audioFormatData, maxLength: 2)

        var channelsData = [UInt8](repeating: 0, count: 2)
        ByteOrder.littleEndian.encode(UInt16(numChannels), into: &channelsData)
        stream.write(&channelsData, maxLength: 2)

        var sampleRateData = [UInt8](repeating: 0, count: 4)
        ByteOrder.littleEndian.encode(UInt32(sampleRate), into: &sampleRateData)
        stream.write(&sampleRateData, maxLength: 4)

        var byteRateData = [UInt8](repeating: 0, count: 4)
        ByteOrder.littleEndian.encode(UInt32(sampleRate * Int64(blockAlign)), into: &byteRateData)
        stream.write(&byteRateData, maxLength: 4)

        var blockAlignData = [UInt8](repeating: 0, count: 2)
        ByteOrder.littleEndian.encode(UInt16(blockAlign), into: &blockAlignData)
        stream.write(&blockAlignData, maxLength: 2)

        var validBitsData = [UInt8](repeating: 0, count: 2)
        ByteOrder.littleEndian.encode(UInt16(validBits), into: &validBitsData)
        stream.write(&validBitsData, maxLength: 2)

        var dataIdData = [UInt8](repeating: 0, count: 4)
        ByteOrder.bigEndian.encode(dataChunkId, into: &dataIdData)
        stream.write(&dataIdData, maxLength: 4)

        var dataSizeData = [UInt8](repeating: 0, count: 4)
        ByteOrder.littleEndian.encode(UInt32(dataSize), into: &dataSizeData)
        stream.write(&dataSizeData, maxLength: 4)

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
                    sample = Int32(ByteOrder.littleEndian.decode(bytes, as: Int16.self))
                case 3:
                    let b0 = Int32(bytes[0])
                    let b1 = Int32(bytes[1])
                    let b2 = Int32(bytes[2])
                    sample = (b2 << 16) | ((b1 & 0xFF) << 8) | (b0 & 0xFF)
                    if sample >= (1 << 15) {
                        sample -= 1 << 16
                    }
                case 4:
                    sample = Int32(ByteOrder.littleEndian.decode(bytes, as: Int32.self))
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

        for frame in 0..<numFrames {
            for stem in buffer.indices {
                for channel in 0..<numChannels {
                    let sample = buffer[stem][Int(frame) * numChannels + channel]
                    let intSample = Int32(sample * floatScale - floatOffset)

                    var bytes = [UInt8](repeating: 0, count: bytesPerSample)
                    switch bytesPerSample {
                    case 1:
                        bytes[0] = UInt8(max(0, min(255, Int(intSample) + 128)))
                    case 2:
                        ByteOrder.littleEndian.encode(Int16(max(-32768, min(32767, Int(intSample)))), into: &bytes)
                    case 4:
                        ByteOrder.littleEndian.encode(max(-2147483648, min(2147483647, Int(intSample))), into: &bytes)
                    default:
                        break
                    }
                    stream.write(&bytes, maxLength: bytesPerSample)
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
    private static let sampleRate = 44100

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
                sampleRate: Int64(sampleRate)
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
            if wavFile.getSampleRate() != Int64(sampleRate) {
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
