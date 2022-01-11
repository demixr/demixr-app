import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_model_selected.dart';
import 'package:demixr_app/models/model.dart';
import 'package:demixr_app/repositories/preferences_repository.dart';
import 'package:flowder/flowder.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:path/path.dart' as p;

class PreferencesProvider extends ChangeNotifier {
  final _repository = PreferencesRepository();
  bool downloadInProgress = false;
  double progress = 0;
  int currentDownloaded = 0;
  Either<Failure, Model> _model = Left(NoModelSelected());

  PreferencesProvider() {
    _loadPreferences();
  }

  bool get hasModel => _model.fold((noModelSelected) => false, (model) => true);

  void _loadPreferences() {
    String? modelName = _repository.getModel();
    _model = modelName == null
        ? Left(NoModelSelected())
        : Right(Models.fromName(modelName));
  }

  void downloadModel(Model model) async {
    downloadInProgress = true;
    notifyListeners();

    final filename = '${model.name}${Models.fileExtension}';
    final directory = await _repository.modelsPath;

    final path = p.join(directory, filename);
    _repository.setModelPath(path, model.name);

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
        setModel(model);

        Get.offAllNamed('/');
      },
    );

    try {
      await Flowder.download(model.url, options);
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
      downloadInProgress = false;
      notifyListeners();
    }
  }

  void setModel(Model model) {
    _repository.setModel(model.name);
    _model = Right(model);

    notifyListeners();
  }
}
