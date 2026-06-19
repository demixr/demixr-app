import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/screens/youtube/components/video_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final youtube = context.read<YoutubeProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: ColorPalette.onSurface),
              decoration: InputDecoration(
                hintText: 'Search Youtube',
                hintStyle: const TextStyle(
                  color: ColorPalette.onSurfaceVariant,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: ColorPalette.onSurfaceVariant,
                ),
                filled: true,
                fillColor: ColorPalette.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (query) => youtube.search(query),
            ),
          ),
          Expanded(
            child: Consumer<YoutubeProvider>(
              builder: (context, youtube, child) {
                return youtube.videos.fold(
                  (failure) => const EmptySearch(),
                  (videos) =>
                      videos.isEmpty ? const EmptySearch() : const VideoList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
