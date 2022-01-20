import 'package:demixr_app/constants.dart';
import 'package:demixr_app/providers/youtube_provider.dart';
import 'package:demixr_app/screens/youtube/components/video_widget.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:loadmore/loadmore.dart';
import 'package:provider/provider.dart';

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
            itemCount: youtube.videos.length,
            itemBuilder: (context, index) {
              final item = youtube.videos.elementAt(index);

              return VideoWidget(
                title: item.title,
                author: item.channelTitle,
                coverUrl: item.thumbnail.medium.url,
                url: item.url,
              );
            },
          ),
        );
      },
    );
  }
}
