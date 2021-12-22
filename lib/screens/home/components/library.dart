import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class Library extends StatelessWidget {
  const Library({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      spacing: 40,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Library',
          style: TextStyle(color: ColorPalette.onSurface, fontSize: 36),
        ),
        SizedBox(
          width: double.maxFinite,
          child: LibrarySongs(),
        ),
      ],
    );
  }
}

class LibrarySongs extends StatelessWidget {
  const LibrarySongs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      spacing: 25,
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, 'player'),
          child: const Song(),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }
}

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          child: Image.asset(getAssetPath('astronaut', AssetType.image)),
        ),
        const SizedBox(
          width: 200,
          child: Text(
            'Your library is empty at the moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: ColorPalette.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
