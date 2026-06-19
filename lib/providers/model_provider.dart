import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../helpers/separation/executorch_demixing_engine.dart';
import '../models/model.dart';
import '../providers/preferences_provider.dart';
import '../constants.dart';

/// Provider handling the model downloads.
/// Uses Dio directly for reliable cross-platform downloads.
class ModelProvider extends ChangeNotifier {
  late PreferencesProvider _preferences;
  double progress = 0;
  int currentDownloaded = 0;
  bool isDownloading = false;

  /// True while the freshly-downloaded GPU model is being compiled/warmed up.
  bool warmingUp = false;
  String? errorMessage;
  String? currentUrl;

  CancelToken? _cancelToken;

  ModelProvider();

  /// Sets the [preferences] with the app [PreferencesProvider].
  void setPreferences(PreferencesProvider preferences) {
    _preferences = preferences;
  }

  /// Downloads the given [model] to the app storage directory.
  void downloadModel(Model model, {required VoidCallback onDone}) async {
    final url = model.downloadUrl;
    if (url == null) {
      _showDownloadError('This model is not available on this platform');
      return;
    }

    Get.toNamed('/model/download');

    final filename = '${model.name}${model.fileExtension}';
    final directory = await _preferences.repository.modelsPath;
    final path = p.join(directory, filename);

    // Verify the directory is writable
    final dir = Directory(directory);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        _showDownloadError('Could not create models directory: $e');
        return;
      }
    }

    // Verify we can write to the directory
    final testFile = File(p.join(directory, '.write_test'));
    try {
      await testFile.writeAsBytes([]);
      await testFile.delete();
    } catch (e) {
      _showDownloadError('Models directory is not writable: $e');
      return;
    }

    _cancelToken = CancelToken();
    isDownloading = true;
    errorMessage = null;
    currentUrl = url;
    notifyListeners();

    final dio = Dio(
      BaseOptions(
        receiveTimeout: const Duration(minutes: 30),
        sendTimeout: const Duration(minutes: 30),
        followRedirects: true,
        maxRedirects: 10,
      ),
    );

    try {
      await dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final newProgress = received / total;
            if ((newProgress - progress).abs() > 0.005) {
              progress = newProgress;
              currentDownloaded = received ~/ (1024 * 1024);
              notifyListeners();
            }
          }
        },
        cancelToken: _cancelToken,
      );

      // Download completed successfully
      _preferences.repository.setModelPath(path, model.name);
      _preferences.setModel(model);

      // Warm up the GPU engine now (the one-time CoreML compile) so the first
      // demix isn't stalled by it.
      if (model.engine == DemixingEngine.executorch) {
        warmingUp = true;
        notifyListeners();
        try {
          await ExecuTorchDemixingEngine.warmUp(path);
        } catch (e) {
          debugPrint('Model warm-up failed (non-fatal): $e');
        }
        warmingUp = false;
      }

      _clearDownload();
      onDone();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        return;
      }
      _showDownloadError(
        'Could not download the model: ${e.message ?? e.toString()}',
      );
    } catch (e) {
      _showDownloadError('Could not download the model: $e');
    }
  }

  void _showDownloadError(String message) {
    Get.snackbar(
      'Download error',
      message,
      backgroundColor: ColorPalette.errorContainer,
      colorText: ColorPalette.onError,
      duration: const Duration(seconds: 5),
    );
    _clearDownload();
    notifyListeners();
  }

  /// Cancels the current download.
  void cancelDownload() {
    _cancelToken?.cancel();
    _clearDownload();
    Get.back();
  }

  /// Clear the current download properties.
  void _clearDownload() {
    progress = 0;
    currentDownloaded = 0;
    isDownloading = false;
    warmingUp = false;
    errorMessage = null;
    currentUrl = null;
    _cancelToken = null;
  }
}
