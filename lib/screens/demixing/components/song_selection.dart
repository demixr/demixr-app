import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/song.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SongSelection extends StatelessWidget {
  const SongSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: ColorPalette.surfaceVariant,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SpacedColumn(
            spacing: 30,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: ListTile(
                  title: Text(
                    'Song selection',
                    style: TextStyle(
                        color: ColorPalette.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Text(
                'You can select a song from your device or directly from Youtube.',
                style: TextStyle(color: ColorPalette.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Button(
                    'Youtube link',
                    icon: Icon(
                      Icons.file_upload,
                      color: ColorPalette.onPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Button(
                    'Browse files',
                    icon: SvgPicture.asset(
                      getAssetPath('youtube', AssetType.icon),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Card(
          color: ColorPalette.surfaceVariant,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Song(),
          ),
        )
      ],
    );
  }
}
