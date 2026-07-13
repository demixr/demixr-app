import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Live smoke test for the YouTube path used by Demixr.
///
/// This intentionally performs real network traffic and is therefore kept out
/// of the normal offline unit-test suite. Run with:
///
///   dart run tool/youtube_download_smoke.dart [video URL]
Future<void> main(List<String> arguments) async {
  final url = arguments.isEmpty
      ? 'https://www.youtube.com/watch?v=u_yIGGhubZs'
      : arguments.first;
  final youtube = YoutubeExplode();

  try {
    stdout.writeln('Resolving audio manifest for $url');
    final manifest = await youtube.videos.streamsClient.getManifest(
      url,
      ytClients: [YoutubeApiClient.ios],
      requireWatchPage: false,
    );
    for (final candidate in manifest.audioOnly) {
      stdout.writeln(
        'Candidate: ${candidate.container.name}, '
        '${candidate.bitrate.kiloBitsPerSecond} kbps, '
        '${candidate.size.totalBytes} bytes',
      );
    }
    final usableAudio = manifest.audioOnly
        .where((candidate) => candidate.size.totalBytes > 0)
        .toList();
    if (usableAudio.isEmpty) {
      throw StateError('The manifest contains no sized audio streams.');
    }
    final audio = usableAudio.withHighestBitrate();
    stdout.writeln(
      'Resolved ${audio.container.name}, ${audio.bitrate.kiloBitsPerSecond} kbps',
    );

    final rangedUrl = audio.url.replace(
      queryParameters: {
        ...audio.url.queryParameters,
        'range': '0-${audio.size.totalBytes - 1}',
      },
    );
    final request = http.Request('GET', rangedUrl)
      ..headers['User-Agent'] =
          'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)';
    final response = await http.Client().send(request);
    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.partialContent) {
      throw HttpException('Audio request returned ${response.statusCode}.');
    }
    var received = 0;
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 30),
    )) {
      received += chunk.length;
    }

    if (received == 0) {
      throw StateError('The audio stream returned no bytes.');
    }
    stdout.writeln('PASS: downloaded $received audio bytes.');
  } finally {
    youtube.close();
  }
}
