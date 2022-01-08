import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_song_selected.dart';
import 'package:demixr_app/models/song.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_youtube_downloader/flutter_youtube_downloader.dart';

class Download{

  late String path;

  Download({required this.path});

  Future<Either<Failure, String>> downloadSong(String ytLink, String title) async {
    final String result = await FlutterYoutubeDownloader.downloadVideo(ytLink,
        title, 18);

    if (result == null) return Left(NoSongSelected());

    return Right(result);
  }
}