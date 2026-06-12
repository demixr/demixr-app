import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flowder/flowder.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../models/model.dart';
import '../providers/preferences_provider.dart';
import '../constants.dart';

/// Provider handling the model downloads.
///
/// Uses the [PreferencesProvider] to store the model informations
/// and holds the [progress] and [currentDownloade] metrics.
class ModelProvider extends ChangeNotifier {
  late PreferencesProvider _preferences;
  double progress = 0;
  int currentDownloaded = 0;

  DownloaderCore? downloader;

  ModelProvider();

  /// Sets the [preferences] with the app [PreferencesProvider].
  void setPreferences(PreferencesProvider preferences) {
    _preferences = preferences;
  }

  /// Downloads the given [model] to the app external storage.
  ///
  /// Displays the progress on the [DownloadScreen].
  /// Runs the [onDone] callback when the download is over.
  void downloadModel(Model model, {required VoidCallback onDone}) async {
    Get.toNamed('/model/download');

    final filename = '${model.name}${Models.fileExtension}';
    final directory = await _preferences.repository.modelsPath;

    final path = p.join(directory, filename);

    // Verify the directory is writable before starting the download
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

    final options = DownloaderUtils(
      progressCallback: (current, total) {
        progress = (current / total);
        currentDownloaded = current ~/ 1e6;
        notifyListeners();
      },
      file: File(path),
      progress: ProgressImplementation(),
      deleteOnCancel: true,
      onDone: () {
        _preferences.repository.setModelPath(path, model.name);
        _preferences.setModel(model);
        _clearDownload();

        onDone();
      },
    );

    try {
      downloader = await Flowder.download(model.url, options);
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

  /// Cancels the current download registered in the [downloader].
  void cancelDownload() {
    downloader?.cancel();
    _clearDownload();
    Get.back();
  }

  /// Clear the current download properties.
  void _clearDownload() {
    progress = 0;
    currentDownloaded = 0;
    downloader = null;
  }
}
