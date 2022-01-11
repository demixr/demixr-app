import 'dart:io';

import 'package:demixr_app/models/model.dart';
import 'package:demixr_app/providers/preferences_provider.dart';
import 'package:demixr_app/repositories/preferences_repository.dart';
import 'package:flowder/flowder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../constants.dart';

class ModelProvider extends ChangeNotifier {
  PreferencesRepository repository;
  PreferencesProvider preferences;
  bool downloadInProgress = false;
  double progress = 0;
  int currentDownloaded = 0;

  DownloaderCore? downloader;

  ModelProvider({required this.repository, required this.preferences});

  void downloadModel(Model model) async {
    downloadInProgress = true;
    notifyListeners();

    final filename = '${model.name}${Models.fileExtension}';
    final directory = await repository.modelsPath;

    final path = p.join(directory, filename);
    repository.setModelPath(path, model.name);

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
        downloadInProgress = false;
        preferences.setModel(model);

        Get.offAllNamed('/');
      },
    );

    try {
      downloader = await Flowder.download(model.url, options);
    } catch (e) {
      Get.snackbar(
        'Download error',
        'You must be connected in order to download the model. '
            'Please check your connection and try again.',
        backgroundColor: ColorPalette.errorContainer,
        colorText: ColorPalette.onError,
        duration: const Duration(seconds: 5),
      );
      await Future.delayed(const Duration(seconds: 2));
      _clearDownload();
      notifyListeners();
    }
  }

  void cancelDownload() {
    downloader?.cancel();
    _clearDownload();
    notifyListeners();
  }

  void _clearDownload() {
    downloadInProgress = false;
    progress = 0;
    currentDownloaded = 0;
    downloader = null;
  }
}
