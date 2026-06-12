import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/screens/youtube/components/video_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final youtube = context.read<YoutubeProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search Youtube',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (query) => youtube.search(query),
          ),
        ),
        Expanded(
          child: Consumer<YoutubeProvider>(
            builder: (context, youtube, child) {
              return youtube.videos.fold(
                (failure) => const Center(child: Text('Error or no result')),
                (videos) =>
                    videos.isEmpty ? const EmptySearch() : const VideoList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
