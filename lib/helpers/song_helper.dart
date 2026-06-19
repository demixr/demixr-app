import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' show get;
import 'package:image/image.dart';

import '../models/song.dart';
import '../models/song_download.dart';
import '../models/exceptions/conversion_exception.dart';
import '../models/failure/failure.dart';
import '../models/failure/no_internet_connection.dart';
import '../models/failure/song_conversion_failure.dart';
import '../models/failure/song_download_failure.dart';
import '../models/failure/song_load_failure.dart';
import '../models/failure/song_not_found_on_youtube.dart';
import '../services/song_loader.dart';
import '../constants.dart';
import '../utils.dart';

/// Helper handling the loading of the songs.
///
/// Uses the service [SongLoader] to load from the device and [YoutubeExplode]
/// to download from Youtube and retrieve the song informations.
class SongHelper {
  final _service = SongLoader();

  /// Loads a song from the device and retrieve it's title, artists and cover.
  Future<Either<Failure, Song>> loadFromDevice() async {
    Either<Failure, PlatformFile> file = await _service.getFromDevice();

    return file.fold((failure) => Left(failure), (file) async {
      if (file.path == null) return Left(SongLoadFailure());

      File path = File(file.path!);
      final metadata = _readMetadata(path, getImage: false);

      Tuple2<String, List<String>> songInfos = _getSongInfos(
        metadata?.title,
        metadata?.artist != null ? [metadata!.artist!] : null,
        p.basename(path.path).removeExtension(),
      );

      String? coverPath = await _saveCover(path.path, songInfos.value1);

      String newPath;
      try {
        newPath = await convertToWav(file.path!);
      } on ConversionException {
        return Left(SongConversionFailure());
      }

      return Right(
        Song(
          title: songInfos.value1,
          artists: songInfos.value2,
          path: newPath,
          coverPath: coverPath,
          duration: metadata?.duration ?? Duration.zero,
        ),
      );
    });
  }

  /// Reads the audio metadata for the file at [path], returning `null` if the
  /// file's tags can't be parsed (the caller falls back to the filename).
  AudioMetadata? _readMetadata(File path, {required bool getImage}) {
    try {
      return readMetadata(path, getImage: getImage);
    } catch (_) {
      return null;
    }
  }

  /// Saves the song cover from the metadata to the app cache.
  Future<String?> _saveCover(String songPath, String title) async {
    final metadata = _readMetadata(File(songPath), getImage: true);
    final albumCover = (metadata != null && metadata.pictures.isNotEmpty)
        ? metadata.pictures.first.bytes
        : null;

    if (albumCover == null) return null;

    Image? image = decodeImage(albumCover);
    if (image == null) return null;

    final tempDir = await getAppTemp();
    final filePath = p.join(tempDir, '${sanitizeFilename(title)}_cover.jpg');

    File file = File(filePath);
    file.writeAsBytesSync(encodeJpg(image));

    return file.path;
  }

  /// Gets the informations from the song at the given Youtube [url].
  ///
  /// Finds the song title, artists and download the thumbnail.
  Future<Either<Failure, SongDownload>> getSongInfosFromYoutube(
    String url,
  ) async {
    final yt = YoutubeExplode();

    Video video;
    try {
      video = await yt.videos.get(url);
    } on SocketException {
      return Left(NoInternetConnection());
    } catch (_) {
      // ArgumentError (bad URL), VideoUnavailableException, VideoUnplayable,
      // or any other youtube_explode error: treat as "not found" so the flow
      // surfaces a failure instead of throwing into a fire-and-forget call.
      return Left(SongNotFoundOnYoutube());
    }

    String? coverPath;
    try {
      coverPath = await _downloadThumbnail(
        video.thumbnails.mediumResUrl,
        video.title,
      );
    } catch (e) {
      coverPath = null;
    }

    yt.close();

    return Right(
      SongDownload(
        title: video.title,
        artists: [video.author],
        url: url,
        coverPath: coverPath,
        duration: video.duration ?? Duration.zero,
      ),
    );
  }

  /// Downloads the given [song] from Youtube with [YoutubeExplode].
  ///
  /// [onProgress] is called with the download completion ratio (0.0 to 1.0)
  /// as bytes are received, so the UI can show real progress.
  Future<Either<Failure, Song>> downloadFromYoutube(
    SongDownload song, {
    void Function(double progress)? onProgress,
  }) async {
    final yt = YoutubeExplode();

    File file;
    try {
      // The androidVr client, combined with the watch page (the default, which
      // deciphers YouTube's throttling "n" parameter), reliably returns fast,
      // un-throttled audio streams. The default/other clients hand back
      // throttled URLs that download at a few KB/s or stall entirely.
      final manifest = await yt.videos.streamsClient.getManifest(
        song.url,
        ytClients: [YoutubeApiClient.androidVr],
      );
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      // Some streams don't report a content length; fall back to estimating it
      // from bitrate x duration so the progress bar still advances.
      var totalBytes = streamInfo.size.totalBytes;
      if (totalBytes <= 0) {
        totalBytes =
            (streamInfo.bitrate.bitsPerSecond / 8 * song.duration.inSeconds)
                .round();
      }

      final stream = yt.videos.streamsClient.get(streamInfo);

      file = File(p.join(await getAppTemp(), sanitizeFilename(song.title)));
      final fileStream = file.openWrite();

      // Write the stream chunk by chunk, reporting progress (throttled to ~1%).
      // An idle timeout guards against a stalled stream hanging forever.
      var received = 0;
      var lastReported = 0.0;
      await for (final chunk in stream.timeout(const Duration(seconds: 30))) {
        fileStream.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          final progress = received / totalBytes;
          if (progress - lastReported >= 0.01) {
            lastReported = progress;
            onProgress?.call(progress);
          }
        }
      }
      onProgress?.call(1);

      await fileStream.flush();
      await fileStream.close();
    } catch (_) {
      return Left(SongDownloadFailure());
    }

    yt.close();

    String newPath;
    try {
      newPath = await convertToWav(file.path);
    } on ConversionException {
      return Left(SongConversionFailure());
    }

    return Right(Song.fromDownload(song, newPath));
  }

  /// Download the Youtube video thumbnail at the given [url] to the cache.
  Future<String> _downloadThumbnail(String url, String title) async {
    final response = await get(Uri.parse(url));
    final tempDir = await getAppTemp();
    final filePath = p.join(tempDir, '${sanitizeFilename(title)}_cover.jpg');

    File file = File(filePath);
    file.writeAsBytesSync(response.bodyBytes);

    return file.path;
  }

  /// Determines a song informations either from the subscripted [title]
  /// and [artists] or from the [filename].
  Tuple2<String, List<String>> _getSongInfos(
    String? title,
    List<String>? artists,
    String filename,
  ) {
    const separator = songArtistTitleSeparator;
    var splitedFilename = filename.split(separator);
    var titleFromFilename = splitedFilename.length == 1
        ? splitedFilename[0].trim()
        : splitedFilename.sublist(1).join(separator).trim();

    title ??= titleFromFilename;
    artists ??= [splitedFilename[0].trim()];

    return Tuple2(title, artists);
  }
}

/// Converts the song at the given [path] to the Waveform format (`wav`).
///
/// Uses FFmpeg via [FFmpegKit] to retrieve the format of the current file and
/// convert it if needed.
/// Throws a [ConvertionException] if the format could not be found, or if the
/// convertion failed.
Future<String> convertToWav(String path) async {
  final session = await FFprobeKit.getMediaInformation(path);
  final information = session.getMediaInformation();

  String? format = information?.getFormat();

  if (format == null) {
    throw ConversionException('SongLoader: Failed to get the file format');
  } else if (format != 'wav') {
    final outputPath = '${p.withoutExtension(path)}.wav';
    File(outputPath).deleteIfExists();

    // 16-bit PCM, not 8-bit (pcm_u8): the demixing models read this file as
    // their input, and 8-bit quantization audibly degrades the separation.
    final convertSession = await FFmpegKit.execute(
      '-i "$path" -acodec pcm_s16le "$outputPath"',
    );
    final convertRc = await convertSession.getReturnCode();

    if (ReturnCode.isSuccess(convertRc)) {
      path = outputPath;
    } else {
      throw ConversionException(
        'SongLoader: Failed to convert audio file to wav',
      );
    }
  }

  return path;
}
