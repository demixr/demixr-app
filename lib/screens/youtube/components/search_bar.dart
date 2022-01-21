import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/screens/youtube/components/video_list.dart';
import 'package:flutter/material.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final youtube = context.read<YoutubeProvider>();

    Color surfaceColor = ColorPalette.surface;
    Color textColor = ColorPalette.onSurface;

    return FloatingSearchAppBar(
      hint: 'Search Youtube',
      hintStyle: TextStyle(color: textColor),
      titleStyle: TextStyle(color: textColor),
      colorOnScroll: surfaceColor,
      color: surfaceColor,
      iconColor: textColor,
      accentColor: textColor,
      shadowColor: Colors.black,
      hideKeyboardOnDownScroll: true,
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
      debounceDelay: const Duration(milliseconds: 500),
      clearQueryOnClose: false,
      onSubmitted: (query) => youtube.search(query),
      alwaysOpened: true,
      actions: [
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      body: Consumer<YoutubeProvider>(
        builder: (context, youtube, child) {
          return youtube.videos.isLeft()
              ? const EmptySearch()
              : const VideoList();
        },
      ),
    );
  }
}
