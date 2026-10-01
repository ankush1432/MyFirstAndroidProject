import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/commons/enums.dart';
import 'package:starke_app/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:starke_app/commons/widgets/video_item.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/features/videos/cubits/videos_cubit.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/commons/widgets/custom_appbar.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/error_container_widget.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/core/error_handler/error_message_keys.dart';
import 'package:starke_app/utils/ui_utils.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({
    super.key,
    this.videos,
    this.currentVideo,
    this.initialIndex,
  });

  /// When [videos] is provided, [VideoScreen] will use this list instead of
  /// fetching from the API via [VideoCubit] in [initState].
  final List<NewsModel>? videos;

  /// Optionally mark the currently selected video when [videos] is provided.
  final NewsModel? currentVideo;

  /// Optionally specify the initial index within [videos] to show first.
  final int? initialIndex;

  @override
  VideoScreenState createState() => VideoScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const VideoScreen());
  }
}

class VideoScreenState extends State<VideoScreen> {
  late final PageController _videoScrollController = PageController()
    ..addListener(hasMoreVideoScrollListener);

  int currentIndex = 0;
  int totalItems = 0;
  String? initializedVideoId;
  late String latitude, longitude;
  VideoViewType? videoViewType;

  void getVideos() {
    Future.delayed(Duration.zero, () {
      context.read<VideoCubit>().getVideo(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          latitude: latitude,
          longitude: longitude);
    });
  }

  @override
  void initState() {
    videoViewType =
        context.read<AppConfigurationCubit>().getVideoTypePreference();

    setLatitudeLongitude();

    // If videos are injected (e.g. from SectionMoreNewsList), avoid calling API
    // in initState and use the provided list instead.
    if (widget.videos == null) {
      getVideos();
    } else {
      totalItems = widget.videos!.length;

      if (widget.initialIndex != null) {
        currentIndex = widget.initialIndex!.clamp(0, totalItems - 1);
      } else if (widget.currentVideo != null) {
        final idx = widget.videos!
            .indexWhere((v) => v.id != null && v.id == widget.currentVideo!.id);
        if (idx != -1) {
          currentIndex = idx;
        }
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _videoScrollController.dispose();
    super.dispose();
  }

  void setLatitudeLongitude() {
    latitude = SettingsLocalDataRepository().getLocationCityValues().first;
    longitude = SettingsLocalDataRepository().getLocationCityValues().last;
  }

  void hasMoreVideoScrollListener() {
    if (_videoScrollController.offset >=
            _videoScrollController.position.maxScrollExtent &&
        !_videoScrollController.position.outOfRange) {
      if (context.read<VideoCubit>().hasMoreVideo()) {
        context.read<VideoCubit>().getMoreVideo(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            latitude: latitude,
            longitude: longitude);
      } else {
        //debugPrint("No more videos");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            height: 44,
            isBackBtn: false,
            label: 'videosLbl',
            isConvertText: true),
        body: widget.videos != null
            ? _buildVideosFromList(videoViewType ?? VideoViewType.normal)
            : _buildVideos(videoViewType ?? VideoViewType.normal));
  }

  Widget _buildVideos(VideoViewType type) {
    return BlocBuilder<VideoCubit, VideoState>(builder: (context, state) {
      if (state is VideoFetchSuccess) {
        totalItems = state.video.length;
        if (type == VideoViewType.page) {
          return RefreshIndicator(
              onRefresh: () async {
                getVideos();
              },
              child: PageView.builder(
                  controller: _videoScrollController,
                  scrollDirection: Axis.vertical,
                  physics: PageScrollPhysics(),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    return _buildVideoContainer(
                        video: state.video[index],
                        hasMore: state.hasMore,
                        hasMoreVideoFetchError: state.hasMoreFetchError,
                        index: index,
                        totalCurrentVideo: state.video.length);
                  }));
        } else {
          return Padding(
            padding: EdgeInsets.only(
                top: 15.0,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 10),
            child: ListView.separated(
                controller: _videoScrollController,
                itemBuilder: (context, index) {
                  return _buildHorizontalViewContainer(
                      videosList: state.video,
                      video: state.video[index],
                      index: index,
                      totalCurrentVideo: state.video.length);
                },
                separatorBuilder: (context, index) {
                  return SizedBox(height: 16);
                },
                itemCount: state.video.length),
          );
        }
      }
      if (state is VideoFetchFailure) {
        return ErrorContainerWidget(
            errorMsg: (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                : state.errorMessage,
            onRetry: getVideos);
      }
      return SizedBox.shrink();
    });
  }

  /// Build videos UI using an injected list instead of [VideoCubit].
  Widget _buildVideosFromList(VideoViewType type) {
    final videos = widget.videos ?? [];
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    if (type == VideoViewType.page) {
      return PageView.builder(
          controller: _videoScrollController,
          scrollDirection: Axis.vertical,
          physics: const PageScrollPhysics(),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            return VideoItem(model: videos[index]);
          });
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: ListView.separated(
            controller: _videoScrollController,
            itemBuilder: (context, index) {
              return _buildHorizontalViewContainer(
                  videosList: videos,
                  video: videos[index],
                  index: index,
                  totalCurrentVideo: videos.length);
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 16);
            },
            itemCount: videos.length),
      );
    }
  }

  _buildVideoContainer(
      {required NewsModel video,
      required int index,
      required int totalCurrentVideo,
      required bool hasMoreVideoFetchError,
      required bool hasMore}) {
    if (index == totalCurrentVideo - 1 && index != 0) {
      if (hasMore) {
        if (hasMoreVideoFetchError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
              child: IconButton(
                onPressed: () {
                  context.read<VideoCubit>().getMoreVideo(
                      langCode: context
                          .read<AppLocalizationCubit>()
                          .state
                          .languageCode,
                      latitude: SettingsLocalDataRepository()
                          .getLocationCityValues()
                          .first,
                      longitude: SettingsLocalDataRepository()
                          .getLocationCityValues()
                          .last);
                },
                icon: Icon(Icons.error, color: Theme.of(context).primaryColor),
              ),
            ),
          );
        } else {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 8.0),
                  child: UiUtils.showCircularProgress(
                      true, Theme.of(context).primaryColor)));
        }
      }
    }

    return VideoItem(model: video);
  }

  Widget _buildHorizontalViewContainer(
      {required List<NewsModel> videosList,
      required NewsModel video,
      required int index,
      required int totalCurrentVideo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: VideoNewsCard(
        video: video,
        videosList: videosList,
      ),
    );
  }
}

class VideoNewsCard extends StatefulWidget {
  final NewsModel video;
  final List<NewsModel> videosList;
  const VideoNewsCard({
    super.key,
    required this.videosList,
    required this.video,
  });

  @override
  VideoNewsCardState createState() => VideoNewsCardState();
}

class VideoNewsCardState extends State<VideoNewsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: UiUtils.getColorScheme(context).surface,
          borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        onTap: () {
          List<NewsModel> videosList = List.from(widget.videosList)
            ..removeWhere((x) => x.id == widget.video.id);
          Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
            "from": 1,
            "model": widget.video,
            "otherVideos": videosList
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Container(
                height: 192, color: borderColor, child: _buildThumbnail()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  CustomTextLabel(
                      text: widget.video.title!,
                      textStyle: TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.video.date != null &&
                      widget.video.date!.isNotEmpty)
                    Row(
                      spacing: 8,
                      children: [
                        SvgPictureWidget(
                            assetName: 'calendar',
                            height: 18,
                            width: 18,
                            assetColor: ColorFilter.mode(
                                UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.7),
                                BlendMode.srcIn)),
                        CustomTextLabel(
                            text: UiUtils.formatDate(widget.video.date ?? ''),
                            textStyle: TextStyle(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.7)))
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    print(
        "video thumbnail = ${widget.video.image} -- title = ${widget.video.title}");
    return Container(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        darkSecondaryColor.withOpacity(0.6),
                        darkSecondaryColor.withOpacity(0.6)
                      ]).createShader(rect),
              blendMode: BlendMode.darken,
              child: Container(
                color: primaryColor.withAlpha(5),
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height / 3.3,
                child: CustomNetworkImage(
                    width: double.maxFinite,
                    networkImageUrl: widget.video.image ?? ''),
              )),
          Center(
            child: Icon(Icons.play_circle_outline_rounded,
                size: 50, color: backgroundColor),
          )
        ],
      ),
    );
  }
}
