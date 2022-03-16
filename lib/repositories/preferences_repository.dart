import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../utils.dart';

/// Repository for the application preferences / settings.
///
/// Stores theses preferences in a dynamic Hive box, and the models
/// on the file system.
class PreferencesRepository {
  final _box = Hive.box<dynamic>(BoxesNames.preferences);
  final _modelsDirectoryName = 'models';

  /// The directory path where the models are stored.
  Future<String> get modelsPath async {
    final path = await getAppExternalStorage();
    var directory = Directory(p.join(path, _modelsDirectoryName));
    directory = await directory.createIfNotPresent();
    return directory.path;
  }

  /// Gets the name of the selected model.
  String? getModel() {
    return _box.get(Preferences.model);
  }

  /// Sets the selected model to the given [modelName].
  void setModel(String modelName) {
    _box.put(Preferences.model, modelName);
  }

  /// Gets the saved path of the given [modelName].
  String? getModelPath(String modelName) {
    return _box.get(modelName);
  }

  /// Saves the [path] of the given [modelName].
  void setModelPath(String path, String modelName) {
    _box.put(modelName, path);
  }
}
