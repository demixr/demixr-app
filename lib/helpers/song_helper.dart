import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:demixr_app/constants.dart';
import 'package:demixr_app/models/exceptions/conversion_exception.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_album_cover.dart';
import 'package:demixr_app/models/failure/song_load_failure.dart';
import 'package:demixr_app/models/song.dart';
import 'package:demixr_app/services/song_loader.dart';
import 'package:demixr_app/utils.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:get/route_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' show get;

class SongHelper {
  final _service = SongLoader();

  Future<Either<Failure, Song>> loadFromDevice() async {
    Either<Failure, PlatformFile> file = await _service.getFromDevice();

    return file.fold((failure) => Left(failure), (file) async {
      if (file.path == null) return Left(SongLoadFailure());

      File path = File(file.path!);
      var metadata = await MetadataRetriever.fromFile(path);

      Tuple2<String, List<String>> songInfos = _getSongInfos(
        metadata.trackName,
        metadata.trackArtistNames,
        p.basename(path.path).removeExtension(),
      );

      String newPath;
      try {
        newPath = await convertToWav(file.path!);
      } on ConversionException catch (e) {
        Get.snackbar('Song conversion error', e.message);
        return Left(SongLoadFailure());
      }

      return Right(
        Song(
          title: songInfos.value1,
          artists: songInfos.value2,
          path: newPath,
        ),
      );
    });
  }

  Future<Either<Failure, Song>> downloadFromYoutube(String url) async {
    final yt = YoutubeExplode();
    final video = await yt.videos.get(url);

    final coverPath =
        _downloadThumbnail(video.thumbnails.mediumResUrl, video.title);

    // if (video == null) return Left(NoSongSelected());

    final manifest = await yt.videos.streamsClient.getManifest(url);
    final streamInfo = manifest.audioOnly.withHighestBitrate();

    // Get the actual stream
    final stream = yt.videos.streamsClient.get(streamInfo);

    // Open a file for writing.
    final file = File(p.join(await getAppTemp(), video.title));
    final fileStream = file.openWrite();

    // Pipe all the content of the stream into the file.
    await stream.pipe(fileStream);

    // Close the file.
    await fileStream.flush();
    await fileStream.close();

    yt.close();

    return Right(Song(
      title: video.title,
      artists: [video.author],
      path: file.path,
    ));
  }

  Future<String> _downloadThumbnail(String url, String title) async {
    final response = await get(Uri.parse(url));
    final tempDir = await getAppTemp();
    final filePath = p.join(tempDir, '${title}_thumbnail.jpg');

    File file = File(filePath);
    file.writeAsBytesSync(response.bodyBytes);

    return file.path;
  }

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

Future<String> convertToWav(String path) async {
  final session = await FFprobeKit.getMediaInformation(path);
  final information = session.getMediaInformation();

  String? format = information?.getProperties('format_name');

  if (format == null) {
    throw ConversionException('SongLoader: Failed to get the file format');
  } else if (format == 'mp3') {
    final outputPath = '${p.withoutExtension(path)}.wav';
    File(outputPath).deleteIfExists();

    final convertSession =
        await FFmpegKit.execute('-i "$path" -acodec pcm_u8 "$outputPath"');
    final convertRc = await convertSession.getReturnCode();

    if (ReturnCode.isSuccess(convertRc)) {
      path = outputPath;
    } else {
      throw ConversionException(
          'SongLoader: Failed to convert audio file to wav');
    }
  }

  return path;
}

extension Cover on Song {
  Future<Either<Failure, Uint8List>> get albumCover async {
    var metadata = await MetadataRetriever.fromFile(File(path));
    final albumCover = metadata.albumArt;

    if (albumCover == null) return Left(NoAlbumCover());

    return Right(albumCover);
  }
}
