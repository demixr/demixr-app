import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_api/youtube_api.dart';

class YoutubeProvider extends ChangeNotifier {

  final String _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  late YoutubeAPI api;
  List<YouTubeVideo> _videos = [];
  final String _regionCode = 'US';

  YoutubeProvider() {
    api = YoutubeAPI(_apiKey);
    loadTrends();
  }

  Future<void> loadTrends() async {
    _videos = await api.getTrends(regionCode: _regionCode);
    notifyListeners();
  }
}