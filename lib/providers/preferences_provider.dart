import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';

import '../models/model.dart';
import '../models/failure/failure.dart';
import '../models/failure/no_model_selected.dart';
import '../repositories/preferences_repository.dart';
import '../constants.dart';

/// Provider handling the app preferences / settings.
///
/// Uses the [PreferencesRepository] to store these preferences.
/// Holds the currently selected [Model].
class PreferencesProvider extends ChangeNotifier {
  final _repository = PreferencesRepository();
  Either<Failure, Model> _model = Left(NoModelSelected());

  PreferencesProvider() {
    _loadPreferences();
  }

  /// Whether a model is selected.
  bool get hasModel => _model.fold((noModelSelected) => false, (model) => true);

  /// The current model name.
  String get modelName =>
      _model.fold((noModel) => 'unknown', (model) => model.name);

  /// The repository holding the preferences.
  PreferencesRepository get repository => _repository;

  /// Loads the app preferences from the repository.
  void _loadPreferences() {
    String? modelName = _repository.getModel();
    _model = modelName == null
        ? Left(NoModelSelected())
        : Right(Models.fromName(modelName));
  }

  /// Sets the current model to the given one.
  void setModel(Model model) {
    _repository.setModel(model.name);
    _model = Right(model);

    notifyListeners();
  }

  /// Checks if the given [model] is the selected one.
  ///
  /// If true, also checks if it's still available.
  Future<bool> isModelSelected(Model model) async {
    final selected = _repository.getModel();
    return model.name == selected && await isModelAvailable(model);
  }

  /// Checks if the selected [_model] is available.
  Future<bool> isSelectedModelAvailable() async {
    return await _model.fold(
      (noModel) => false,
      (model) => isModelAvailable(model),
    );
  }

  /// Checks if the given [model] is available.
  ///
  /// First checks if the model is registered in the [_repository]
  /// and then checks if the file is available in the file system.
  Future<bool> isModelAvailable(Model model) async {
    final modelPath = _repository.getModelPath(model.name);
    if (modelPath == null) return false;

    final file = File(modelPath);
    return await file.exists();
  }

  /// Get the selected [_model] path.
  ///
  /// Throws an [ArgumentError] if no model is selected or if the model path
  /// is not registered in the [_repository].
  String getModelPath() {
    return _model.fold(
      (noModelSelected) =>
          throw ArgumentError('Preferences: No model selected'),
      (model) {
        final String? path = _repository.getModelPath(model.name);
        if (path == null) {
          throw ArgumentError('Preferences: Model path not found');
        }

        return path;
      },
    );
  }
}
