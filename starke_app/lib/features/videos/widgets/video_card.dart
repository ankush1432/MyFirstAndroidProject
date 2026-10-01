import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:starke_app/commons/widgets/video_play_container.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/authentication/cubits/auth_cubit.dart';
import 'package:starke_app/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:starke_app/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/live_streaming/models/live_streaming_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/features/news/repositories/like_and_dislike_news/like_and_dislike_news_repository.dart';
import 'package:starke_app/commons/widgets/snackbar_widget.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/core/error_handler/internet_connectivity.dart';
import 'package:starke_app/core/constants/strings.dart';
import 'package:starke_app/utils/ui_utils.dart';

class VideoCard extends StatefulWidget {
  final NewsModel? model;
  final BreakingNewsModel? brModel;
  final LiveStreamingModel? liveModel;
  VideoCard({super.key, this.model, this.liveModel, this.brModel});

  @override
  State<StatefulWidget> createState() => VideoCardState();
}

class VideoCardState extends State<VideoCard> {
  late NewsModel? model;
  late BreakingNewsModel? brModel;
  late LiveStreamingModel? liveModel;
  bool isLiveVideo = false, isBreakingVideo = false;
  List<String>? tagList = [];
  List<String>? tagId = [];
  String formattedDate = "", contentType = "", contentValue = "", titleTxt = "";
  final GlobalKey<VideoPlayContainerState> _videoKey =
      GlobalKey<VideoPlayContainerState>();

  @override
  void initState() {
    super.initState();
    model = widget.model;
    brModel = widget.brModel;
    liveModel = widget.liveModel;
    isLiveVideo = (liveModel != null);
    isBreakingVideo = (brModel != null);
    setFormattedDate();
    setTitle();
    setContentValueAndContentType();
    setTags();
  }

  void setTitle() {
    titleTxt = (isLiveVideo)
        ? liveModel?.title ?? ""
        : (isBreakingVideo)
            ? brModel?.title ?? ""
            : model?.title ?? "";
  }

  void setTags() {
    if (model != null &&
        model?.tagName != null &&
        (model!.sourceType != null && model!.sourceType != BREAKING_NEWS)) {
      if (model?.tagId != null && model!.tagId!.isNotEmpty) {
        tagId = model?.tagId?.split(",");
      }

      if (model!.tagName!.isNotEmpty) {
        final tagName = model?.tagName!;
        tagList = tagName?.split(',');
      }
    }
  }

  void setFormattedDate() {
    String dateVal = (isLiveVideo)
        ? liveModel!.updatedDate ?? ""
        : (model?.publishDate ?? model?.date ?? "");
    if (dateVal.isNotEmpty) {
      DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(dateVal);
      formattedDate = DateFormat("MMM dd, yyyy").format(parsedDate);
    }
  }

  void setContentValueAndContentType() {
    contentType = (isLiveVideo)
        ? liveModel?.type ?? ""
        : ((model != null)
            ? model?.contentType ?? ""
            : brModel!.contentType ?? "");
    contentValue = (isLiveVideo)
        ? liveModel?.url ?? ""
        : (model != null)
            ? model?.contentValue ?? ""
            : brModel!.contentValue ?? "";
  }

  void openLandscapeVideo() {
    if (contentValue.isEmpty) return;

    final startTime =
        _videoKey.currentState?.getCurrentPosition() ?? Duration.zero;
    _videoKey.currentState?.pausePlayback();

    Navigator.of(context).pushNamed(
      Routes.videoLandscape,
      arguments: {
        "contentType": contentType,
        "contentValue": contentValue,
        "startTime": startTime,
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  Widget likeButton() {
    bool isLike = context
        .read<LikeAndDisLikeCubit>()
        .isNewsLikeAndDisLike(widget.model?.newsId ?? "0");

    return BlocProvider(
        create: (context) =>
            UpdateLikeAndDisLikeStatusCubit(LikeAndDisLikeRepository()),
        child: BlocConsumer<LikeAndDisLikeCubit, LikeAndDisLikeState>(
            bloc: context.read<LikeAndDisLikeCubit>(),
            listener: ((context, state) {
              if (state is LikeAndDisLikeFetchSuccess) {
                isLike = context
                    .read<LikeAndDisLikeCubit>()
                    .isNewsLikeAndDisLike(model?.newsId ?? "0");
              } else {
                isLike = false; //in case of failue - no other likes found
              }
            }),
            builder: (context, likeAndDislikeState) {
              return BlocConsumer<UpdateLikeAndDisLikeStatusCubit,
                      UpdateLikeAndDisLikeStatusState>(
                  bloc: context.read<UpdateLikeAndDisLikeStatusCubit>(),
                  listener: ((context, state) {
                    if (state is UpdateLikeAndDisLikeStatusSuccess) {
                      context.read<LikeAndDisLikeCubit>().getLike(
                          langCode: context
                              .read<AppLocalizationCubit>()
                              .state
                              .languageCode);
                    }
                  }),
                  builder: (context, state) {
                    return InkWell(
                        splashColor: Colors.transparent,
                        onTap: () {
                          if (context.read<AuthCubit>().getUserId() != "0") {
                            if (state is UpdateLikeAndDisLikeStatusInProgress) {
                              return;
                            }
                            context
                                .read<UpdateLikeAndDisLikeStatusCubit>()
                                .setLikeAndDisLikeNews(
                                    news: model ?? NewsModel(),
                                    status: (isLike) ? "0" : "1");
                          } else {
                            UiUtils.loginRequired(context);
                          }
                        },
                        child: designButtons(
                            childWidget: (state
                                    is UpdateLikeAndDisLikeStatusInProgress)
                                ? SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: UiUtils.showCircularProgress(
                                        true, Theme.of(context).primaryColor))
                                : SvgPictureWidget(
                                    assetName: isLike ? 'like_filled' : 'like',
                                    height: 20,
                                    width: 20,
                                    assetColor: ColorFilter.mode(
                                        UiUtils.getColorScheme(context)
                                            .onPrimary,
                                        BlendMode.srcIn))));
                  });
            }));
  }

  Widget showTags() {
    return SizedBox(
      height: 30.0,
      child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: tagList!.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsetsDirectional.only(start: index == 0 ? 0 : 5.5),
              child: InkWell(
                onTap: () async {
                  if (index >= tagId!.length || tagId![index].isEmpty) return;
                  Navigator.of(context).pushNamed(Routes.tagScreen, arguments: {
                    "tagId": tagId![index],
                    "tagName": tagList![index]
                  });
                },
                child: Container(
                    height: 25.0,
                    alignment: Alignment.center,
                    padding: const EdgeInsetsDirectional.only(
                        start: 7.0, end: 7.0, top: 1.0, bottom: 1.0),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: borderColor.withOpacity(0.6),
                          width: 1.0,
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15)),
                        color: borderColor.withOpacity(0.2)),
                    child: CustomTextLabel(
                        text: tagList![index],
                        textStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        softWrap: true)),
              ),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayContainer(
                    key: _videoKey,
                    contentType: contentType,
                    contentValue: contentValue,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: openLandscapeVideo,
                      child: Container(
                        height: 32,
                        width: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          (model != null && model!.sourceType != BREAKING_NEWS)
              ? showTags()
              : SizedBox.shrink(),
          const SizedBox(height: 10),
          CustomTextLabel(
              text: titleTxt,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: UiUtils.getColorScheme(context).onPrimary)),
          const SizedBox(height: 10),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              (formattedDate.isNotEmpty)
                  ? Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 20),
                        SizedBox(width: 4),
                        CustomTextLabel(
                            text: formattedDate,
                            textStyle: TextStyle(
                                fontSize: 12,
                                color:
                                    UiUtils.getColorScheme(context).onPrimary)),
                      ],
                    )
                  : SizedBox.shrink(),
              Row(
                children: [
                  if ((model?.sourceType != null && model?.newsId != null ||
                          model?.id != null) ||
                      (model?.sourceType == NEWS ||
                          model?.sourceType == VIDEOS))
                    Row(children: [
                      InkWell(
                          onTap: () async {
                            (await InternetConnectivity.isNetworkAvailable())
                                ? UiUtils.shareNews(
                                    context: context,
                                    slug: model?.slug ?? "",
                                    title: model?.title ?? "",
                                    isVideo: true,
                                    isReels: false,
                                    videoId: model?.id ?? "0",
                                    isBreakingNews: false,
                                    isNews: false, id: model?.id??'', image: model?.image??"")
                                : showSnackBar(
                                    UiUtils.getTranslatedLabel(
                                        context, 'internetmsg'),
                                    context);
                          },
                          splashColor: Colors.transparent,
                          child: designButtons(
                              childWidget: SvgPictureWidget(
                                  assetName: 'share',
                                  height: 20,
                                  width: 20,
                                  assetColor: ColorFilter.mode(
                                      UiUtils.getColorScheme(context).onPrimary,
                                      BlendMode.srcIn)))),
                      const SizedBox(height: 15),
                      BlocProvider(
                        create: (context) =>
                            UpdateBookmarkStatusCubit(BookmarkRepository()),
                        child: BlocBuilder<BookmarkCubit, BookmarkState>(
                            bloc: context.read<BookmarkCubit>(),
                            builder: (context, bookmarkState) {
                              bool isBookmark = context
                                  .read<BookmarkCubit>()
                                  .isNewsBookmark(model?.id ?? "0");
                              return BlocConsumer<UpdateBookmarkStatusCubit,
                                      UpdateBookmarkStatusState>(
                                  bloc:
                                      context.read<UpdateBookmarkStatusCubit>(),
                                  listener: ((context, state) {
                                    if (state is UpdateBookmarkStatusSuccess) {
                                      (state.wasBookmarkNewsProcess)
                                          ? context
                                              .read<BookmarkCubit>()
                                              .addBookmarkNews(state.news)
                                          : context
                                              .read<BookmarkCubit>()
                                              .removeBookmarkNews(state.news);
                                      setState(() {});
                                    }
                                  }),
                                  builder: (context, state) {
                                    return InkWell(
                                        onTap: () {
                                          if (context
                                                  .read<AuthCubit>()
                                                  .getUserId() !=
                                              "0") {
                                            if (state
                                                is UpdateBookmarkStatusInProgress)
                                              return;
                                            context
                                                .read<
                                                    UpdateBookmarkStatusCubit>()
                                                .setBookmarkNews(
                                                    news: model!,
                                                    status: (isBookmark)
                                                        ? "0"
                                                        : "1");
                                          } else {
                                            UiUtils.loginRequired(context);
                                          }
                                        },
                                        child: state
                                                is UpdateBookmarkStatusInProgress
                                            ? SizedBox(
                                                height: 15,
                                                width: 15,
                                                child: UiUtils
                                                    .showCircularProgress(
                                                        true,
                                                        Theme.of(context)
                                                            .primaryColor))
                                            : designButtons(
                                                childWidget: SvgPictureWidget(
                                                    assetName: isBookmark
                                                        ? 'save_filled'
                                                        : 'save',
                                                    height: 20,
                                                    width: 20,
                                                    assetColor: ColorFilter.mode(
                                                        UiUtils.getColorScheme(
                                                                context)
                                                            .onPrimary,
                                                        BlendMode.srcIn))));
                                  });
                            }),
                      ),
                      const SizedBox(height: 15),
                      likeButton()
                    ]),
                ],
              ),
            ],
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget designButtons({required Widget childWidget}) {
    return Container(
        height: 30,
        width: 30,
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(7),
            color: borderColor.withOpacity(0.2)),
        child: childWidget);
  }
}
