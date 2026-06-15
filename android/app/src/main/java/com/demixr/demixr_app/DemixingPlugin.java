package com.demixr.demixr_app;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/**
 * Demixing plugin stub for Android.
 *
 * All demixing logic has been migrated to the Dart layer using
 * executorch_flutter (v0.4.1) FFI bindings. This class exists only
 * to satisfy Flutter's plugin manifest. The actual demixing is
 * performed by ExecutorchManager.instance.loadModel() and
 * model.forward() through the executorch_flutter package.
 */
public class DemixingPlugin implements FlutterPlugin {
    private MethodChannel methodChannel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        BinaryMessenger messenger = binding.getBinaryMessenger();
        // No MethodChannel is registered — demixing happens entirely in Dart
        // through executorch_flutter's FFI bindings.
        methodChannel = new MethodChannel(messenger, "demixing");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
    }
}
