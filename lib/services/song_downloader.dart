import 'dart:io';


import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/song.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SongDownload {

  Future<String> getAppTemp() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<Either<Failure, Song>> downloadFromYoutube(String url) async {
    var yt = YoutubeExplode();
    final video = await yt.videos.get(url);

    if (video == null) return Left(NoSongSelected());

    final manifest = await yt.videos.streamsClient.getManifest(url);
    final streamInfo = manifest.audioOnly.withHighestBitrate();

    // Get the actual stream
    var stream = yt.videos.streamsClient.get(streamInfo);

    // Open a file for writing.
    var file = File(p.join(await getAppTemp(), video.title));
    var fileStream = file.openWrite();

    // Pipe all the content of the stream into the file.
    await stream.pipe(fileStream);

    // Close the file.
    await fileStream.flush();
    await fileStream.close();

    yt.close();

    return Right(
        Song(
          title: video.title,
          artists: [video.author],
          path:,
        )
    );
  }
}