import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/live_streaming/models/live_streaming_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/commons/widgets/custom_appbar.dart';
import 'package:starke_app/features/videos/widgets/other_videos_card.dart';
import 'package:starke_app/features/videos/widgets/video_card.dart';
import 'package:starke_app/utils/ui_utils.dart';

class VideoDetailsScreen extends StatefulWidget {
  int from;
  LiveStreamingModel? liveModel;
  NewsModel? model;
  BreakingNewsModel? breakModel;
  List<NewsModel>? otherVideos;
  List<BreakingNewsModel>? otherBreakingVideos;
  List<LiveStreamingModel>? otherLiveVideos;

  VideoDetailsScreen(
      {super.key,
      this.model,
      required this.from,
      this.liveModel,
      this.breakModel,
      required this.otherVideos,
      this.otherLiveVideos,
      this.otherBreakingVideos});

  @override
  State<StatefulWidget> createState() => VideoDetailsState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => VideoDetailsScreen(
            from: arguments['from'],
            liveModel: arguments['liveModel'],
            model: arguments['model'],
            breakModel: arguments['breakModel'],
            otherVideos: arguments['otherVideos'],
            otherLiveVideos: arguments['otherLiveVideos'],
            otherBreakingVideos: arguments['otherBreakingVideos']));
  }
}

class VideoDetailsState extends State<VideoDetailsScreen> {
  // late VideoModel currentVideo;
  // late List<VideoModel> otherVideos;

  bool isLiveVideo = false, isBreakingNewsVideo = false, isNewsVideo = true;
  //FROM VAL 1 = news, 2 = liveNews , 3 = breakingNews

  @override
  void initState() {
    isLiveVideo = (widget.from == 2);
    isBreakingNewsVideo = (widget.from == 3);
    isNewsVideo = !(isLiveVideo || isBreakingNewsVideo);

    // currentVideo = widget.selectedVideo;
    // otherVideos = widget.videos.where((v) => v.id != currentVideo.id).toList();
    super.initState();
  }

  @override
  void dispose() {
    // set screen back to portrait mode
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    return Scaffold(
      backgroundColor: UiUtils.getColorScheme(context).surface,
      //Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
          height: 45, isBackBtn: true, label: 'videosLbl', isConvertText: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VideoCard(
                model: (widget.model != null) ? widget.model : null,
                brModel: (widget.breakModel != null) ? widget.breakModel : null,
                liveModel:
                    (widget.liveModel != null) ? widget.liveModel : null),
            const SizedBox(height: 8),
            ((isLiveVideo &&
                        widget.otherLiveVideos != null &&
                        widget.otherLiveVideos!.isNotEmpty) ||
                    ((widget.otherVideos != null &&
                            widget.otherVideos!.isNotEmpty) ||
                        (widget.otherBreakingVideos != null &&
                            widget.otherBreakingVideos!.isNotEmpty)))
                ? Text(
                    UiUtils.getTranslatedLabel(context, 'recentVidLbl'),
                    style: TextStyle(
                        color: UiUtils.getColorScheme(context).onPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16),
                  )
                : SizedBox.shrink(),
            const SizedBox(height: 8),
            ((isLiveVideo &&
                        widget.otherLiveVideos != null &&
                        widget.otherLiveVideos!.isNotEmpty) ||
                    ((widget.otherVideos != null &&
                            widget.otherVideos!.isNotEmpty) ||
                        (widget.otherBreakingVideos != null &&
                            widget.otherBreakingVideos!.isNotEmpty)))
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (isLiveVideo)
                        ? widget.otherLiveVideos!.length
                        : (widget.otherVideos != null &&
                                widget.otherVideos!.isNotEmpty)
                            ? widget.otherVideos!.length
                            : widget.otherBreakingVideos!.length,
                    itemBuilder: (context, index) => OtherVideosCard(
                        brModel: (widget.otherBreakingVideos != null &&
                                widget.otherBreakingVideos!.isNotEmpty)
                            ? widget.otherBreakingVideos![index]
                            : null,
                        model: (widget.otherVideos != null &&
                                widget.otherVideos!.isNotEmpty)
                            ? widget.otherVideos![index]
                            : null,
                        liveModel: (widget.otherLiveVideos != null &&
                                widget.otherLiveVideos!.isNotEmpty)
                            ? widget.otherLiveVideos![index]
                            : null),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
