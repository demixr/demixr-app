import 'package:dartz/dartz.dart';
import 'package:demixr_app/models/failure/failure.dart';
import 'package:demixr_app/models/failure/no_search_result.dart';
import 'package:demixr_app/providers/song_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeProvider extends ChangeNotifier {
  final SearchClient _youtube = YoutubeExplode().search;
  Either<Failure, SearchList> _videos = Left(NoSearchResult());
  final SongProvider songProvider;

  YoutubeProvider(this.songProvider);

  Either<Failure, SearchList> get videos => _videos;

  Future<void> search(String query) async {
    final searchList = await _youtube.getVideos(query);
    _videos = Right(searchList);
    notifyListeners();
  }

  Future<bool> loadMore() async {
    await _videos.fold(
      (failure) => null,
      (videos) async {
        final nextPage = await videos.nextPage();

        if (nextPage != null) {
          final allVideos = nextPage..insertAll(0, videos);
          _videos = Right(allVideos);
        }
      },
    );
    notifyListeners();

    return true;
  }

  void download(String url) {
    songProvider.downloadFromYoutube(url);
    Get.back();
  }
}
