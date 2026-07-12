import 'package:demixr_app/providers/library_provider.dart';
import 'package:demixr_app/providers/player_provider.dart';
import 'package:demixr_app/services/song_export_service.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';

class InfosDialog extends StatelessWidget {
  const InfosDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryProvider>();

    String songTitle = library.currentSong.fold(
      (l) => 'unknown',
      (r) => r.title,
    );
    String modelName = library.currentSong.fold(
      (l) => 'unknown',
      (r) => r.modelName,
    );

    return AlertDialog(
      backgroundColor: ColorPalette.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: ColorPalette.outline),
      ),
      icon: const Icon(Icons.graphic_eq_rounded, color: ColorPalette.primary),
      title: Text(songTitle),
      elevation: 0,
      content: RichText(
        text: TextSpan(
          style: const TextStyle(color: ColorPalette.onSurfaceVariant),
          children: [
            const TextSpan(text: 'This song was unmixed with '),
            TextSpan(
              text: modelName,
              style: const TextStyle(
                color: ColorPalette.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const _ExportDialog(),
          ),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Export'),
        ),
        TextButton(onPressed: Get.back, child: const Text('Done')),
      ],
    );
  }
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  final _exporter = SongExportService();
  bool _busy = false;

  Future<void> _run(Future<bool> Function() export) async {
    setState(() => _busy = true);
    try {
      final saved = await export();
      if (!mounted || !saved) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export saved successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return AlertDialog(
      backgroundColor: ColorPalette.surfaceContainer,
      title: const Text('Export song'),
      content: SizedBox(
        width: 380,
        child: _busy
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing export…'),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune_rounded),
                    title: const Text('Current remix'),
                    subtitle: const Text('Uses the current stem levels'),
                    onTap: () => _run(
                      () => _exporter.exportRemix(song, player.stemVolumes),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.music_note_rounded),
                    title: const Text('Original song'),
                    subtitle: const Text('Audio before separation'),
                    onTap: () => _run(() => _exporter.exportOriginal(song)),
                  ),
                  for (final stem in song.stems)
                    ListTile(
                      leading: const Icon(Icons.graphic_eq_rounded),
                      title: Text('${stem.name} stem'),
                      onTap: () => _run(() => _exporter.exportStem(song, stem)),
                    ),
                  ListTile(
                    leading: const Icon(Icons.folder_zip_rounded),
                    title: const Text('All stems'),
                    subtitle: const Text('ZIP with stems and original'),
                    onTap: () => _run(() => _exporter.exportAllStems(song)),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
