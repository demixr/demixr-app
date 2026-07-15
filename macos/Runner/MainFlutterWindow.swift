import Cocoa
import FlutterMacOS
import CoreML

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = frame
        contentViewController = flutterViewController
        setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)
        ScnetCoreMlBridge.register(messenger: flutterViewController.engine.binaryMessenger)

        super.awakeFromNib()
    }
}

private final class ScnetCoreMlBridge {
    private static var model: MLModel?
    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "demixr/scnet_coreml", binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            handle(call, result: result)
        }
    }

    private static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "load":
                guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
                    throw BridgeError.invalidArguments
                }
                let configuration = MLModelConfiguration()
                configuration.computeUnits = .cpuAndGPU
                model = try MLModel(contentsOf: URL(fileURLWithPath: path), configuration: configuration)
                result(nil)
            case "run":
                guard let model, let args = call.arguments as? [String: Any],
                      let bytes = args["input"] as? FlutterStandardTypedData else {
                    throw BridgeError.invalidArguments
                }
                let input = try float16Input(bytes.data)
                guard let inputName = model.modelDescription.inputDescriptionsByName.keys.first,
                      let outputName = model.modelDescription.outputDescriptionsByName.keys.first else {
                    throw BridgeError.invalidModel
                }
                let features = try MLDictionaryFeatureProvider(dictionary: [inputName: MLFeatureValue(multiArray: input)])
                guard let output = try model.prediction(from: features).featureValue(for: outputName)?.multiArrayValue else {
                    throw BridgeError.invalidModel
                }
                result(FlutterStandardTypedData(bytes: float32Data(output)))
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(code: "SCNET_COREML", message: error.localizedDescription, details: nil))
        }
    }

    private static func float32Data(_ array: MLMultiArray) -> Data {
        let shape = array.shape.map { $0.intValue }
        let strides = array.strides.map { $0.intValue }
        let rowLength = shape.last ?? array.count
        let rows = array.count / rowLength
        let lastStride = strides.last ?? 1
        var values = [Float](repeating: 0, count: array.count)

        for row in 0..<rows {
            var remainder = row
            var physicalOffset = 0
            if shape.count > 1 {
                for dimension in stride(from: shape.count - 2, through: 0, by: -1) {
                    let coordinate = remainder % shape[dimension]
                    remainder /= shape[dimension]
                    physicalOffset += coordinate * strides[dimension]
                }
            }
            let logicalOffset = row * rowLength
            if array.dataType == .float16 {
                let source = array.dataPointer.assumingMemoryBound(to: UInt16.self)
                for column in 0..<rowLength {
                    values[logicalOffset + column] = Float(
                        Float16(bitPattern: source[physicalOffset + column * lastStride])
                    )
                }
            } else if array.dataType == .float32 {
                let source = array.dataPointer.assumingMemoryBound(to: Float.self)
                for column in 0..<rowLength {
                    values[logicalOffset + column] = source[physicalOffset + column * lastStride]
                }
            } else {
                for column in 0..<rowLength {
                    values[logicalOffset + column] = array[physicalOffset + column * lastStride].floatValue
                }
            }
        }
        return values.withUnsafeBytes { Data($0) }
    }

    private static func float16Input(_ data: Data) throws -> MLMultiArray {
        let input = try MLMultiArray(shape: [1, 4, 2049, 338], dataType: .float16)
        let destination = input.dataPointer.assumingMemoryBound(to: UInt16.self)
        data.withUnsafeBytes { raw in
            let source = raw.bindMemory(to: Float.self)
            for index in 0..<input.count { destination[index] = Float16(source[index]).bitPattern }
        }
        return input
    }

    private enum BridgeError: LocalizedError {
        case invalidArguments, invalidModel
        var errorDescription: String? { self == .invalidArguments ? "Invalid SCNet bridge arguments" : "Invalid SCNet Core ML model" }
    }
}
