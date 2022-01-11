import 'dart:io';

import 'package:demixr_app/constants.dart';
import 'package:demixr_app/utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

class PreferencesRepository {
  final _box = Hive.box<dynamic>(BoxesNames.preferences);
  final _modelsDirectoryName = 'models';

  Future<String> get modelsPath async {
    final path = await getAppExternalStorage();
    var directory = Directory(p.join(path, _modelsDirectoryName));
    directory = await directory.createIfNotPresent();
    return directory.path;
  }

  String? getModel() {
    return _box.get(Preferences.model);
  }

  void setModel(String modelName) {
    _box.put(Preferences.model, modelName);
  }

  String? getModelPath(String modelName) {
    return _box.get(modelName);
  }

  void setModelPath(String path, String modelName) {
    _box.put(modelName, path);
  }
}
