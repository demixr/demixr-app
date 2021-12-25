import 'package:demixr_app/constants.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';

class Library extends StatelessWidget {
  const Library({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            'Library',
            style: TextStyle(color: ColorPalette.onSurface, fontSize: 36),
          ),
          Expanded(
            child: EmptyLibrary(),
          ),
        ],
      ),
    );
  }
}

// class LibrarySongs extends StatelessWidget {
//   const LibrarySongs({Key? key}) : super(key: key);

//   Widget buildSongButton(SongWidget song, BuildContext context) => TextButton(
//         onPressed: () => Navigator.pushNamed(context, 'player'),
//         child: song,
//         style: TextButton.styleFrom(
//             padding:
//                 const EdgeInsets.only(left: 2, top: 15, right: 2, bottom: 15)),
//       );

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.all(0),
//       children: [buildSongButton(const SongWidget(), context)],
//     );
//   }
// }

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
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
