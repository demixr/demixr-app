import 'package:demixr_app/components/extended_widgets.dart';
import 'package:demixr_app/components/navbar.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/screens/youtube/components/search_bar.dart';
import 'package:demixr_app/screens/youtube/components/video_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YoutubeScreen extends StatelessWidget {
  const YoutubeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) => YoutubeProvider(),
        child: Stack(
          fit: StackFit.expand,
            children: const [
              VideoList(),
              SearchBar(),
            ],
          ),
        ),
      );
  }
}
