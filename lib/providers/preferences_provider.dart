import 'package:dartz/dartz.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_model_selected.dart';
import 'package:demixr_app/models/model.dart';
import 'package:demixr_app/repositories/preferences_repository.dart';
import 'package:flutter/material.dart';

class PreferencesProvider extends ChangeNotifier {
  final _repository = PreferencesRepository();
  Either<Failure, Model> _model = Left(NoModelSelected());

  PreferencesProvider() {
    _loadPreferences();
  }

  bool get hasModel => _model.fold((noModelSelected) => false, (model) => true);

  PreferencesRepository get repository => _repository;

  void _loadPreferences() {
    String? modelName = _repository.getModel();
    _model = modelName == null
        ? Left(NoModelSelected())
        : Right(Models.fromName(modelName));
  }

  void setModel(Model model) {
    _repository.setModel(model.name);
    _model = Right(model);

    notifyListeners();
  }

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
