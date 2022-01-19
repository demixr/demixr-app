import 'package:dartz/dartz.dart';
import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song_widget.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class SongSelection extends StatelessWidget {
  const SongSelection({Key? key}) : super(key: key);

  Widget buildButtons(SongProvider provider, BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Button(
            'Youtube link',
            icon: SvgPicture.asset(
              getAssetPath('youtube', AssetType.icon),
            ),
            textSize: 16,
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: ColorPalette.surfaceVariant,
                      content: FormBuilder(
                        key: provider.urlFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FormBuilderTextField(
                              name: 'url',
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(context),
                                FormBuilderValidators.url(context),
                              ]),
                            ),
                            Button('Ok', onPressed: () {
                              provider.downloadFromYoutube();
                              Get.back();
                            }),
                          ],
                        ),
                      ),
                    );
                  });
            },
          ),
          const SizedBox(width: 10),
          Button(
            'Browse files',
            icon: const Icon(
              Icons.file_upload,
              color: ColorPalette.onPrimary,
              size: 18,
            ),
            textSize: 16,
            onPressed: provider.loadFromDevice,
          ),
        ],
      );

  Widget buildSelectionCard(SongProvider provider, BuildContext context) =>
      Card(
        color: ColorPalette.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: SpacedColumn(
            spacing: 30,
            children: [
              const ListTile(
                title: Text(
                  'Song selection',
                  style: TextStyle(
                      color: ColorPalette.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'You can select a song from your device or directly from Youtube.',
                style: TextStyle(
                    color: ColorPalette.onSurfaceVariant, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              buildButtons(provider, context),
            ],
          ),
        ),
      );

  Widget buildSelectedSongCard(Song song, Either<Failure, String> coverPath,
          {VoidCallback? onRemovePressed}) =>
      Card(
        color: ColorPalette.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SongWidget(
            title: song.title,
            artists: song.artists,
            coverPath: coverPath,
            onRemovePressed: onRemovePressed,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        Either<Failure, Song> song = songProvider.song;
        List<Widget> children = [buildSelectionCard(songProvider, context)];

        // Add the song card if a song is selected
        song.fold(
          (failure) => null,
          (song) => children.add(
            buildSelectedSongCard(
              song,
              song.albumCover,
              onRemovePressed: () => songProvider.removeSelectedSong(),
            ),
          ),
        );

        return Column(
          children: children,
        );
      },
    );
  }
}
