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
  Either<Failure, List<Video>> _videos = Left(NoSearchResult());
  VideoSearchList? _currentPage;
  bool _loadingMore = false;

  YoutubeProvider(this.songProvider);

  /// The videos of the current search.
  Either<Failure, List<Video>> get videos => _videos;

  /// Searches the [query] on youtube with [YoutubeExplode].
  Future<void> search(String query) async {
    try {
      final searchList = await _youtube.search(
        query,
        filter: TypeFilters.video,
      );
      _currentPage = searchList;
      _videos = Right(searchList.toList());
    } on SocketException {
      _currentPage = null;
      _videos = Left(NoInternetConnection());
      errorSnackbar('Search failed', 'Could not reach Youtube', seconds: 5);
    }

    notifyListeners();
  }

  /// Loads more videos.
  ///
  /// Loads the videos of the next page while keeping the precedent ones.
  Future<bool> loadMore() async {
    if (_loadingMore || _currentPage == null) return false;
    _loadingMore = true;

    try {
      final nextPage = await _currentPage!.nextPage();
      if (nextPage == null) return false;

      final accumulated = _videos.fold<List<Video>>(
        (_) => <Video>[],
        (videos) => List<Video>.from(videos),
      )..addAll(nextPage);

      _currentPage = nextPage;
      _videos = Right(accumulated);
      notifyListeners();
      return true;
    } finally {
      _loadingMore = false;
    }
  }

  /// Downloads the audio of the Youtube video at the given [url].
  ///
  /// Calls the [songProvider] to start the download.
  void download({
    required String url,
    required String title,
    required String author,
    required String? thumbnailUrl,
    required Duration? duration,
  }) {
    songProvider.downloadFromYoutube(
      url,
      title: title,
      author: author,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
    );
    Get.back();
  }
}
