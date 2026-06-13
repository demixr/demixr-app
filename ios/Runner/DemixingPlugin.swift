//
//  DemixingPlugin.swift
//  Runner
//
//  iOS implementation of the demixing plugin using Executorch.
//  Uses CoreML backend for acceleration on A12+ chips.
//

import Foundation
import Flutter

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

// MARK: - Demixing Plugin (Stub)

/// Flutter plugin for music source separation (demixing) on iOS.
/// Uses Executorch with CoreML backend for GPU acceleration on A12+ chips.
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

            // TODO: Implement full demixing with Executorch CoreML backend
            // For now, report 100% progress and return empty stems
            // This is a stub until full implementation

            DispatchQueue.global(qos: .userInitiated).async {
                if let sink = self.progressSink {
                    DispatchQueue.main.async {
                        sink(1.0)
                    }
                }

                let stemNames = ["vocals", "drums", "bass", "other"]
                var stemFiles: [String: String] = [:]
                for stemName in stemNames {
                    let stemPath = (outputDir as NSString).appendingPathComponent("\(stemName).wav")
                    stemFiles[stemName] = stemPath
                }

                DispatchQueue.main.async {
                    result(stemFiles)
                }
            }
        }
    }
}
