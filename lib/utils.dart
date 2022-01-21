import 'dart:io';

import 'package:get/route_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'constants.dart';

enum AssetType {
  image,
  icon,
  animation,
}

String getAssetPath(String name, AssetType assetType, {String? extension}) {
  String path;

  switch (assetType) {
    case AssetType.image:
      path = Paths.images + name + (extension ?? '.png');
      break;
    case AssetType.animation:
      path = Paths.animations + name + (extension ?? '.gif');
      break;
    case AssetType.icon:
      path = Paths.icons + name + (extension ?? '.svg');
      break;
  }

  return path;
}

SnackbarController errorSnackbar(String title, String message,
    {int seconds = 2}) {
  return Get.snackbar(
    title,
    message,
    backgroundColor: ColorPalette.errorContainer,
    colorText: ColorPalette.onError,
    duration: Duration(seconds: seconds),
  );
}

extension MoveFile on File {
  Future<File> move(String newPath) async {
    try {
      // prefer using rename as it is probably faster
      return await rename(newPath);
    } on FileSystemException {
      // if rename fails, copy the source file and then delete it
      final newFile = await copy(newPath);
      await delete();
      return newFile;
    }
  }

  deleteIfExists() async {
    if (await exists()) await delete();
  }
}

extension RemoveExtension on String {
  String removeExtension() {
    replaceAll(RegExp('.wav|.mp3'), '');
    return this;
  }
}

extension Create on Directory {
  Future<Directory> createIfNotPresent() async {
    if (await exists()) {
      return this;
    } else {
      return await create(recursive: true);
    }
  }

  Future<Directory> createUnique() async {
    var directory = this;
    if (await exists()) {
      directory = Directory("${path}_${DateTime.now().millisecondsSinceEpoch}");
    }

    return await directory.create(recursive: true);
  }
}

Future<String> getAppInternalStorage() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<String> getAppExternalStorage() async {
  Directory? directory;

  try {
    directory = await getExternalStorageDirectory();
  } on UnimplementedError {
    directory = await getApplicationDocumentsDirectory();
  }

  return directory?.path ?? await getAppInternalStorage();
}

Future<String> getAppTemp() async {
  final directory = await getTemporaryDirectory();
  return directory.path;
}

extension Format on Duration {
  String _padTwoDigits(int n) => n.toString().padLeft(2, '0');

  String formatMinSec() {
    final minutes = _padTwoDigits(inMinutes);
    final seconds = _padTwoDigits(inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
