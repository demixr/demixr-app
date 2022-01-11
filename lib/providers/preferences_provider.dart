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

  void _loadPreferences() {
    String? modelName = _repository.getModel();
    _model = modelName == null
        ? Left(NoModelSelected())
        : Right(Models.fromName(modelName));
  }
}
