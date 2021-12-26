import 'dart:io';

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

Future<File> moveFile(File sourceFile, String newPath) async {
  try {
    // prefer using rename as it is probably faster
    return await sourceFile.rename(newPath);
  } on FileSystemException {
    // if rename fails, copy the source file and then delete it
    final newFile = await sourceFile.copy(newPath);
    await sourceFile.delete();
    return newFile;
  }
}
