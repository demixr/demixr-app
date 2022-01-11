import 'package:demixr_app/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PreferencesRepository {
  final _box = Hive.box<dynamic>(BoxesNames.preferences);

  void setModel(String modelName) {
    _box.put(Preferences.model, modelName);
  }

  String? getModel() {
    return _box.get(Preferences.model);
  }
}
