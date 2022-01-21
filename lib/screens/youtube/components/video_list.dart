import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/screens/youtube/components/video_widget.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:loadmore/loadmore.dart';
import 'package:provider/provider.dart';

import '../../../utils.dart';

class CustomLoadMoreDelegate extends LoadMoreDelegate {
  @override
  Widget buildChild(LoadMoreStatus status,
      {LoadMoreTextBuilder builder = DefaultLoadMoreTextBuilder.english}) {
    if (status == LoadMoreStatus.loading) {
      return const SizedBox(
        height: 20,
        width: 40,
        child: LoadingIndicator(
          indicatorType: Indicator.lineScalePulseOutRapid,
          colors: ColorPalette.indicatorColors,
          strokeWidth: 4,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class EmptySearch extends StatelessWidget {
  const EmptySearch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 250,
            child: Image.asset(
              getAssetPath('search_astronaut', AssetType.image),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(
            width: 200,
            child: Text(
              'Type a song name to search Youtube',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: ColorPalette.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoList extends StatelessWidget {
  const VideoList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<YoutubeProvider>(
      builder: (context, youtube, child) {
        return LoadMore(
          onLoadMore: youtube.loadMore,
          delegate: CustomLoadMoreDelegate(),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0),
            itemCount:
                youtube.videos.fold((empty) => 0, (videos) => videos.length),
            itemBuilder: (context, index) => youtube.videos.fold(
              (empty) => const SizedBox.shrink(),
              (videos) {
                final item = videos.elementAt(index);

                return VideoWidget(
                  title: item.title,
                  author: item.author,
                  coverUrl: item.thumbnails.highResUrl,
                  duration: item.duration,
                  url: item.url,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
