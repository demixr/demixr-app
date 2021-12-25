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
