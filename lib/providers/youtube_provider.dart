import 'package:demixr_app/providers/song_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:youtube_api/youtube_api.dart';

class YoutubeProvider extends ChangeNotifier {
  final String _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  late YoutubeAPI api;
  List<YouTubeVideo> _videos = [];
  final String _regionCode = 'US';
  final SongProvider songProvider;

  YoutubeProvider(this.songProvider) {
    api = YoutubeAPI(_apiKey);
  }

  List<YouTubeVideo> get videos => _videos;

  Future<void> loadTrends() async {
    _videos = await api.getTrends(regionCode: _regionCode);
    notifyListeners();
  }

  Future<void> search(String query) async {
    _videos = await api.search(query);
    notifyListeners();
  }

  Future<bool> loadMore() async {
    _videos.addAll(await api.nextPage());
    notifyListeners();
    return true;
  }

  void download(String url) {
    songProvider.downloadFromYoutube(url);
    Get.back();
  }
}
