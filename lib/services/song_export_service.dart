import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
import '../models/unmixed_song.dart';
import '../utils.dart';

class SongExportService {
  Future<bool> exportOriginal(UnmixedSong song) => _saveFile(
    File(song.mixture),
    '${sanitizeFilename(song.title)} - original.wav',
  );

  Future<bool> exportStem(UnmixedSong song, Stem stem) => _saveFile(
    File(song.getStem(stem)),
    '${sanitizeFilename(song.title)} - ${stem.value}.wav',
  );

  Future<bool> exportRemix(UnmixedSong song, Map<Stem, double> volumes) async {
    final gains = <Stem, double>{
      for (final stem in song.stems) stem: (volumes[stem] ?? 1).clamp(0, 1),
    };
    final output = File(
      p.join(
        (await getTemporaryDirectory()).path,
        '${sanitizeFilename(song.title)}-remix-${DateTime.now().microsecondsSinceEpoch}.wav',
      ),
    );
    final inputs = <String>[];
    final labels = <String>[];
    for (var index = 0; index < song.stems.length; index++) {
      final stem = song.stems[index];
      inputs.add('-i ${_quote(song.getStem(stem))}');
      labels.add('[$index:a]');
    }
    final weights = song.stems
        .map((stem) => gains[stem]!.toStringAsFixed(4))
        .join(' ');
    final filter =
        '${labels.join()}amix=inputs=${song.stems.length}:weights=\'$weights\':normalize=0:dropout_transition=0[out]';
    final session = await FFmpegKit.execute(
      '${inputs.join(' ')} -filter_complex ${_quote(filter)} -map "[out]" -c:a pcm_s16le -y ${_quote(output.path)}',
    );
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      await output.deleteIfExists();
      throw StateError('Could not render the remix.');
    }

    try {
      final profile = song.stems
          .map((stem) => '${stem.value}${(gains[stem]! * 100).round()}')
          .join('-');
      return await _saveFile(
        output,
        '${sanitizeFilename(song.title)} - remix-$profile.wav',
      );
    } finally {
      await output.deleteIfExists();
    }
  }

  Future<bool> exportAllStems(UnmixedSong song) async {
    final output = File(
      p.join(
        (await getTemporaryDirectory()).path,
        '${sanitizeFilename(song.title)}-stems-${DateTime.now().microsecondsSinceEpoch}.zip',
      ),
    );
    final encoder = ZipFileEncoder()..create(output.path);
    try {
      for (final stem in song.stems) {
        await encoder.addFile(File(song.getStem(stem)), '${stem.value}.wav');
      }
      await encoder.addFile(File(song.mixture), 'original.wav');
    } finally {
      await encoder.close();
    }

    try {
      return await _saveFile(
        output,
        '${sanitizeFilename(song.title)} - stems.zip',
      );
    } finally {
      await output.deleteIfExists();
    }
  }

  Future<bool> _saveFile(File source, String fileName) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Export from Demixr',
      fileName: fileName,
      bytes: Platform.isAndroid || Platform.isIOS
          ? await source.readAsBytes()
          : null,
    );
    if (path == null) return false;
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (p.equals(source.path, path)) return true;
      await source.copy(path);
    }
    return true;
  }

  String _quote(String value) => '"${value.replaceAll('"', '\\"')}"';
}
