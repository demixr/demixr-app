import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YoutubeProvider extends ChangeNotifier {

  final String _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
}