// Integration test: downloads a very short YouTube video and verifies the
// audio is extracted to a valid WAV file.
//
// This exercises the real pipeline (youtube_explode_dart download +
// ffmpeg_kit WAV conversion + path_provider), so it MUST run on a device or
// emulator and requires network access:
//
//   flutter test integration_test/youtube_download_test.dart -d <device-id>
//
// It is intentionally NOT under test/, so it never runs during a plain
// `flutter test` (unit) pass.
import 'dart:io';

import 'package:demixr_app/helpers/song_helper.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/models/song_download.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test(
    'downloads a YouTube video and extracts a valid WAV',
    () async {
      final helper = SongHelper();

      // A real music video (Despacito — the most-viewed video on YouTube, so a
      // very stable fixture). Crucially it exercises the throttled-stream path:
      // with the wrong API client the download stalls, so this guards that
      // regression. If it ever disappears, the test skips (see below).
      const url = 'https://www.youtube.com/watch?v=kJQP7kiw5Fk';

      final infos = await helper.getSongInfosFromYoutube(url);
      late SongDownload download;
      infos.fold(
        // YouTube itself being unreachable / changing its API is outside our
        // control, so skip rather than hard-fail the suite in that case.
        (failure) => markTestSkipped('YouTube unavailable: ${failure.message}'),
        (value) => download = value,
      );
      if (infos.isLeft()) return;

      var lastProgress = 0.0;
      final result = await helper.downloadFromYoutube(
        download,
        onProgress: (p) => lastProgress = p,
      );

      late Song song;
      result.fold(
        (failure) => fail('Download/convert failed: ${failure.message}'),
        (value) => song = value,
      );

      // Progress should have advanced and the output should be a real WAV file.
      expect(lastProgress, greaterThan(0.0));

      final file = File(song.path);
      expect(file.existsSync(), isTrue, reason: 'output file missing');
      expect(file.lengthSync(), greaterThan(1000), reason: 'output too small');
      expect(song.path.endsWith('.wav'), isTrue);

      // Valid WAV files start with the "RIFF" magic bytes followed by "WAVE".
      final header = file.readAsBytesSync().sublist(0, 12);
      expect(String.fromCharCodes(header.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(header.sublist(8, 12)), 'WAVE');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
