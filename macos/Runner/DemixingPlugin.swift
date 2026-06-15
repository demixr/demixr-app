//
//  DemixingPlugin.swift
//  Runner
//
//  macOS demixing plugin stub.
//  All demixing logic has been migrated to the Dart layer using
//  executorch_flutter (v0.4.1) FFI bindings.
//  This plugin registration exists only to satisfy Flutter's plugin manifest.

import FlutterMacOS

public class DemixingPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op: demixing is handled entirely in Dart via executorch_flutter.
    // The MethodChannel is intentionally not set up because the Dart
    // layer calls ExecutorchManager.instance.loadModel() and model.forward()
    // directly through the executorch_flutter package's FFI bindings.
  }
}
