import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/failure/failure.dart';
import '../models/failure/no_internet_connection.dart';
import '../models/failure/no_search_result.dart';
import '../providers/song_provider.dart';
import '../utils.dart';

/// Provider handling the Youtube search.
///
/// Uses the [YoutubeExplode] search client.
/// Calls the [songProvider] to download a song when selected.
class YoutubeProvider extends ChangeNotifier {
  final SongProvider songProvider;
  final SearchClient _youtube = YoutubeExplode().search;
  Either<Failure, SearchList> _videos = Left(NoSearchResult());

  YoutubeProvider(this.songProvider);

  /// The videos of the current search.
  Either<Failure, SearchList> get videos => _videos;

  /// Searches the [query] on youtube with [YoutubeExplode].
  Future<void> search(String query) async {
    try {
      final searchList = await _youtube.getVideos(query);
      _videos = Right(searchList);
    } on SocketException {
      _videos = Left(NoInternetConnection());
      errorSnackbar('Search failed', 'Could not reach Youtube', seconds: 5);
    }

    notifyListeners();
  }

  /// Loads more videos.
  ///
  /// Loads the videos of the next page while keeping the precedent ones.
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

  /// Downloads the audio of the Youtube video at the given [url].
  ///
  /// Calls the [songProvider] to start the download.
  void download(String url) {
    songProvider.downloadFromYoutube(url);
    Get.back();
  }
}
