import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

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
    debugPrint('=== ModelProvider.downloadModel START ===');
    debugPrint('Model name: ${model.name}');
    debugPrint('Model URL: ${model.url}');
    debugPrint('File extension: ${Models.fileExtension}');

    Get.toNamed('/model/download');

    final filename = '${model.name}${Models.fileExtension}';
    final directory = await _preferences.repository.modelsPath;
    final path = p.join(directory, filename);

    debugPrint('Models directory: $directory');
    debugPrint('Full save path: $path');

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
    currentUrl = model.url;
    notifyListeners();

    final dio = Dio(BaseOptions(
      receiveTimeout: const Duration(minutes: 30),
      sendTimeout: const Duration(minutes: 30),
      followRedirects: true,
      maxRedirects: 10,
    ));

    try {
      debugPrint('Starting Dio download...');
      await dio.download(
        model.url,
        path,
        onReceiveProgress: (received, total) {
          final percent =
              total > 0 ? (received / total * 100).toStringAsFixed(1) : '?';
          final mb = received ~/ (1024 * 1024);
          debugPrint('  Progress: $mb MB ($percent%)');
          notifyListeners();
        },
        cancelToken: _cancelToken,
      );

      debugPrint('Download completed successfully!');

      // Download completed successfully
      _preferences.repository.setModelPath(path, model.name);
      _preferences.setModel(model);
      _clearDownload();
      onDone();
    } on DioException catch (e) {
      debugPrint('=== DioError ===');
      debugPrint('Type: ${e.type}');
      debugPrint('Message: ${e.message}');
      debugPrint('Response status: ${e.response?.statusCode}');
      debugPrint('Response headers: ${e.response?.headers}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Stack trace: ${e.stackTrace}');

      if (e.type == DioExceptionType.cancel) {
        debugPrint('Download was cancelled by user');
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        return;
      }
      _showDownloadError(
        'Could not download the model: ${e.message ?? e.toString()}',
      );
    } catch (e, stackTrace) {
      debugPrint('=== Unexpected Error ===');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Message: $e');
      debugPrint('Stack trace: $stackTrace');
      _showDownloadError('Could not download the model: $e');
    }
  }

  void _showDownloadError(String message) {
    debugPrint('=== SHOWING ERROR: $message ===');
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
    debugPrint('Cancel download called');
    _cancelToken?.cancel();
    _clearDownload();
    Get.back();
  }

  /// Clear the current download properties.
  void _clearDownload() {
    progress = 0;
    currentDownloaded = 0;
    isDownloading = false;
    errorMessage = null;
    currentUrl = null;
    _cancelToken = null;
  }
}
