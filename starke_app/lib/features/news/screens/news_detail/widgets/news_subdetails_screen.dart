import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:starke_app/commons/widgets/ad_spaces.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/commons/cubits/adspace/adSpaces_news_details_cubit.dart';
import 'package:starke_app/commons/cubits/font_size_cubit.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/news/cubits/comment_news_cubit.dart';
import 'package:starke_app/features/news/cubits/related_news_cubit.dart';
import 'package:starke_app/features/news/cubits/set_news_views_cubit.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';

import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/commons/widgets/snackbar_widget.dart';
import 'package:starke_app/commons/widgets/custom_appbar.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/core/error_handler/internet_connectivity.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/Image_view.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/comment_input_bar.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/comment_view.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/date_view.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/desc_view.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/horizontal_btn_list.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/related_news_list.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/reply_comment_view.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/set_banner_ads.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/tag_view.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/title_view.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/video_btn.dart';
import 'package:starke_app/utils/ui_utils.dart';
// import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';

class NewsSubDetails extends StatefulWidget {
  final NewsModel? model;
  final BreakingNewsModel? breakModel;
  final bool fromShowMore;
  final bool isFromBreak;
  final bool fromShortNews;
  final Function(bool) onLockScroll;

  const NewsSubDetails(
      {super.key,
      this.model,
      this.breakModel,
      required this.fromShowMore,
      required this.isFromBreak,
      required this.onLockScroll,
      this.fromShortNews = false});

  @override
  NewsSubDetailsState createState() => NewsSubDetailsState();
}

class NewsSubDetailsState extends State<NewsSubDetails> {
  bool comEnabled = false;
  bool isReply = false;
  int? replyComIndex;
  bool isPlaying = false;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  BannerAd? _bannerAd;
  NewsModel? newsModel;
  FlutterTts? _flutterTts;
  bool _isScrollingUp = false;
  bool _shortNewsExpanded = true;
  static const int _shortNewsDescLimit = 300;

  /// Per-article font size, set by the "Text Size" button on this screen.
  ///
  /// Null until the reader touches that slider, which means the article is
  /// rendered at the global size from [FontSizeCubit]. Once set, it overrides
  /// the global size for this screen only and is intentionally not saved: the
  /// global setting lives in Profile > Text Size and is the only one persisted.
  int? _fontSizeOverride;
  late final ScrollController controller = ScrollController()
    ..addListener(hasMoreCommScrollListener);

  @override
  void initState() {
    super.initState();
    newsModel = widget.model;
    getComments();
    getRelatedNews();
    initializeTts();
    setNewsViews(isBreakingNews: (widget.isFromBreak) ? true : false);
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1")
      bannerAdsInitialized();
    Future.delayed(Duration.zero, () {
      context.read<AdSpacesNewsDetailsCubit>().getAdspaceForNewsDetails(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          page: "news_details_screen");
    });
    if (widget.fromShortNews) _shortNewsExpanded = false;
  }

  setNewsViews({required bool isBreakingNews}) {
    Future.delayed(Duration.zero, () {
      context.read<SetNewsViewsCubit>().setNewsViews(
          newsId: isBreakingNews
              ? widget.breakModel!.id!
              : (newsModel!.newsId ?? newsModel!.id)!,
          isBreakingNews: isBreakingNews);
    });
  }

  getComments() {
    if (!widget.isFromBreak &&
        context.read<AppConfigurationCubit>().getCommentsMode() == "1") {
      Future.delayed(Duration.zero, () {
        context.read<CommentNewsCubit>().getCommentNews(
            newsId: (newsModel!.newsId != null &&
                    newsModel!.newsId!.trim().isNotEmpty)
                ? newsModel!.newsId!
                : newsModel!.id!);
      });
    }
  }

  getRelatedNews() {
    if (!widget.isFromBreak) {
      Future.delayed(Duration.zero, () {
        context.read<RelatedNewsCubit>().getRelatedNews(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            catId: (newsModel!.categoryId != "0" || newsModel!.categoryId == '')
                ? newsModel!.categoryId
                : null,
            subCatId: (newsModel!.subCatId != "0" || newsModel!.subCatId != '')
                ? newsModel!.subCatId
                : null);
      });
    }
  }

  @override
  void dispose() {
    _flutterTts!.stop();
    controller.removeListener(hasMoreCommScrollListener);
    controller.dispose();
    super.dispose();
  }

  initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts!.awaitSpeakCompletion(true);
    _flutterTts!.setStartHandler(() async {
      if (mounted) {
        setState(() => isPlaying = true);
      }
    });

    _flutterTts!.setCompletionHandler(() {
      if (mounted) {
        setState(() => isPlaying = false);
      }
    });

    _flutterTts!.setErrorHandler((err) {
      //print("TTS Error: $err");
      if (mounted) {
        setState(() => isPlaying = false);
      }
    });
  }

  bannerAdsInitialized() {
    if (context.read<AppConfigurationCubit>().checkAdsType() == "unity") {
      // UnityAds.init(
      //     gameId: context.read<AppConfigurationCubit>().unityGameId()!,
      //     testMode: true, //set it to false @Deployment
      //     onComplete: () {
      //       debugPrint('Unity Ads Initialization Completed');
      //     },
      //     onFailed: (error, message) {
      //       debugPrint('Unity Ads Initialization Failed: $error $message');
      //     });
    }

    if (context.read<AppConfigurationCubit>().checkAdsType() == "google") {
      _createBottomBannerAd();
    }
  }

  void _createBottomBannerAd() {
    if (context.read<AppConfigurationCubit>().bannerId() != "") {
      _bannerAd = BannerAd(
        adUnitId: context.read<AppConfigurationCubit>().bannerId()!,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) {},
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
          },
        ),
      );

      _bannerAd!.load();
    }
  }

  speak(String description) async {
    if (description.isNotEmpty) {
      await _flutterTts!.setVolume(volume);
      await _flutterTts!.setSpeechRate(rate);
      await _flutterTts!.setPitch(pitch);
      await _flutterTts!.setLanguage(() {
        return context.read<AppLocalizationCubit>().state.languageCode;
      }());
      int length = description.length;

      if (length < 4000) {
        setState(() => isPlaying = true);
        await _flutterTts!.speak(description);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            _flutterTts!.stop();
            isPlaying = false;
          });
        });
      } else if (length < 8000) {
        if (Platform.isAndroid) await _flutterTts!.setQueueMode(1);
        String temp1 = description.substring(0, length ~/ 2);
        await _flutterTts!.speak(temp1);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = true;
          });
        });
        String temp2 = description.substring(temp1.length, description.length);
        await _flutterTts!.speak(temp2);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
          });
        });
      } else if (length < 12000) {
        if (Platform.isAndroid) await _flutterTts!.setQueueMode(2);
        String temp1 = description.substring(0, 3999);
        await _flutterTts!.speak(temp1);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = true;
          });
        });
        String temp2 = description.substring(temp1.length, 7999);
        await _flutterTts!.speak(temp2);
        _flutterTts!.setCompletionHandler(() {
          setState(() {});
        });
        String temp3 = description.substring(temp2.length, description.length);
        await _flutterTts!.speak(temp3);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
          });
        });
      } else {
        String temp = description.substring(0, description.length);
        await _flutterTts!.speak(temp);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
          });
        });
      }
    }
  }

  stop() async {
    var result = await _flutterTts!.stop();
    if (result == 1) setState(() => isPlaying = false);
  }

  onBackPress(bool isTrue) {
    (widget.fromShowMore == true)
        ? Navigator.of(context).popUntil((route) => route.isFirst)
        : Navigator.pop(context);
  }

  Widget showViews() {
    final viewsCount = !widget.isFromBreak
        ? ((newsModel?.totalViews?.isNotEmpty ?? false) &&
                newsModel!.totalViews != "null"
            ? newsModel!.totalViews!
            : "0")
        : ((widget.breakModel?.totalViews?.isNotEmpty ?? false) &&
                widget.breakModel!.totalViews != "null"
            ? widget.breakModel!.totalViews!
            : "0");
    return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.remove_red_eye_rounded,
              size: 17,
              color: UiUtils.getColorScheme(context).primaryContainer),
          const SizedBox(width: 5),
          Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: CustomTextLabel(
                  text:
                      "$viewsCount ${UiUtils.getTranslatedLabel(context, 'viewsLbl')}",
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center))
        ]);
  }

  /// Author row shown above the title.
  ///
  /// The identity (name + profile picture) only ever comes from `user`, while
  /// `author` carries just the author record (bio/links/user_id). The backend
  /// sends them independently — admin posts have neither, and posts whose
  /// author account was removed keep `author` with `user` null — so resolve
  /// what is actually available and render nothing when there is no name.
  /// Previously this force-unwrapped `userAthorDetails`, which threw and took
  /// the whole row down whenever only `authorDetails` came back.
  Widget showAuthor() {
    final author = newsModel?.userAthorDetails;
    final name = author?.name?.trim() ?? '';
    if (name.isEmpty) return const SizedBox.shrink();

    final authorId =
        author?.id ?? newsModel?.authorDetails?.userId?.toString() ?? "0";
    final profile = author?.profile ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 5, right: 5),
      child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(Routes.authorDetails,
                arguments: {"authorId": authorId});
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              profile.isNotEmpty
                  ? UiUtils.setFixedSizeboxForProfilePicture(
                      childWidget: CircleAvatar(
                          backgroundImage: NetworkImage(profile), radius: 32))
                  : UiUtils.setFixedSizeboxForProfilePicture(
                      childWidget: const Icon(Icons.account_circle, size: 35)),
              SizedBox(width: 12),
              Expanded(
                child: CustomTextLabel(
                  text: name,
                  textAlign: TextAlign.left,
                  textStyle: TextStyle(
                    color: UiUtils.getColorScheme(context).primaryContainer,
                    fontWeight: FontWeight.w400, // SemiBold
                    fontSize: 16,
                  ),
                ),
              )
            ],
          )),
    );
  }

  otherMainDetails() {
    int readingTime = widget.isFromBreak
        ? (widget.breakModel!.readTime ?? 0)
        : (newsModel!.readTime ?? 0);
    String minutesPostfix = (readingTime == 1)
        ? UiUtils.getTranslatedLabel(context, 'minute')
        : UiUtils.getTranslatedLabel(context, 'minutes');
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0),
      width: double.maxFinite,
      // FIGMA: article body sits flat on the Dark-bg (#061024) in dark mode,
      // matching the rest of the screen; light keeps the surface colour.
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? darkBackgroundColor
              : backgroundColor),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            (_shortNewsExpanded)
                ? BlocBuilder<AdSpacesNewsDetailsCubit,
                    AdSpacesNewsDetailsState>(
                    builder: (context, state) {
                      return (state is AdSpacesNewsDetailsFetchSuccess &&
                              state.adSpaceTopData != null)
                          ? AdSpaces(adsModel: state.adSpaceTopData!)
                          : const SizedBox.shrink();
                    },
                  )
                : const SizedBox.shrink(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isFromBreak && !isReply && !comEnabled)
                  tagView(
                      model: newsModel!,
                      context: context,
                      isFromDetailsScreen: true),
                if (!isReply && !comEnabled)
                  Padding(
                      padding: const EdgeInsetsDirectional.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.max, children: [
                          if (!widget.isFromBreak)
                            dateView(context,
                                newsModel!.publishDate ?? newsModel!.date!),
                          if (!widget.isFromBreak) const SizedBox(width: 20),
                          showViews(),
                          const SizedBox(width: 10),
                          Icon(Icons.circle,
                              size: 12,
                              color: UiUtils.getColorScheme(context)
                                  .primaryContainer),
                          const SizedBox(width: 10),
                          // Wrapped in Flexible so the reading-time label shrinks
                          // to the available width instead of overflowing the Row
                          // (fixes the tiny right-edge RenderFlex overflow).
                          Flexible(
                            child: CustomTextLabel(
                                text:
                                    "$readingTime $minutesPostfix ${UiUtils.getTranslatedLabel(context, 'read')}",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: UiUtils.getColorScheme(context)
                                            .primaryContainer
                                            .withOpacity(0.8),
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w400)),
                          )
                        ]),
                      )),
                // showAuthor() decides for itself whether there is an author to
                // show, so admin posts fall through to the title as before.
                if (newsModel != null && !isReply && !comEnabled) showAuthor(),
                if (!isReply && !comEnabled)
                  titleView(
                      title: widget.isFromBreak
                          ? widget.breakModel!.title!
                          : newsModel!.title!,
                      context: context),
                if (!isReply && !comEnabled) _buildDescriptionContent(),
              ],
            ),
            if (!widget.isFromBreak && !isReply && comEnabled)
              CommentView(
                  newsId: newsModel!.id!,
                  updateComFun: updateCommentshow,
                  updateIsReplyFun: updateComReply),
            if (!widget.isFromBreak && isReply && comEnabled)
              ReplyCommentView(
                  replyComIndex: replyComIndex!,
                  replyComFun: updateComReply,
                  newsId: newsModel!.id!),
            (_shortNewsExpanded)
                ? BlocBuilder<AdSpacesNewsDetailsCubit,
                    AdSpacesNewsDetailsState>(
                    builder: (context, state) {
                      return (state is AdSpacesNewsDetailsFetchSuccess &&
                              state.adSpaceBottomData != null)
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 5),
                              child:
                                  AdSpaces(adsModel: state.adSpaceBottomData!))
                          : const SizedBox.shrink();
                    },
                  )
                : const SizedBox.shrink(),
            if (!widget.isFromBreak &&
                !isReply &&
                !comEnabled &&
                newsModel != null &&
                _shortNewsExpanded)
              RelatedNewsList(model: newsModel!),
          ]),
    );
  }

  bool get _isShortNewsCollapsed =>
      !widget.isFromBreak &&
      (newsModel?.isShortNews == true) &&
      !_shortNewsExpanded;

  /// Size this article renders at: the per-screen override if the reader used
  /// the Text Size button here, otherwise the saved global size.
  int _effectiveFontSize(FontSizeState globalState) =>
      _fontSizeOverride ?? globalState.fontSize;

  void _updateFontVal(int value) {
    setState(() => _fontSizeOverride = value);
  }

  /// Article body. Listens to [FontSizeCubit] so it picks up the global size,
  /// unless this screen has its own override.
  Widget _buildDescriptionContent() {
    return BlocBuilder<FontSizeCubit, FontSizeState>(
        builder: (context, fontSizeState) {
      final fontValue = _effectiveFontSize(fontSizeState).toDouble();
      final desc =
          widget.isFromBreak ? widget.breakModel!.desc! : newsModel!.desc!;

      if (!widget.isFromBreak && newsModel?.isShortNews == true) {
        final plainText = (html_parser.parse(desc).body?.text ?? '').trim();
        final showReadMore = plainText.length > _shortNewsDescLimit;
        final displayText = showReadMore && !_shortNewsExpanded
            ? '${plainText.substring(0, _shortNewsDescLimit)}...'
            : plainText;

        if (!_shortNewsExpanded && showReadMore) {
          return Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextLabel(
                  text: displayText,
                  textStyle: TextStyle(fontSize: fontValue),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _shortNewsExpanded = true),
                  child: Text(
                    UiUtils.getTranslatedLabel(context, 'readMoreLbl'),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ],
            ),
          );
        }
      }
      return descView(desc: desc, context: context, fontValue: fontValue);
    });
  }

  updateCommentshow(bool comEnabledUpdate) {
    setState(() {
      comEnabled = comEnabledUpdate;
      widget.onLockScroll(comEnabledUpdate);
    });
  }

  updateComReply(bool comReplyUpdate, int comIndex) {
    setState(() {
      isReply = comReplyUpdate;
      replyComIndex = comIndex;
      widget.onLockScroll(false);
    });
  }

  void hasMoreCommScrollListener() {
    if (!widget.isFromBreak && comEnabled && !isReply) {
      if (controller.position.maxScrollExtent == controller.offset) {
        if (context.read<CommentNewsCubit>().hasMoreCommentNews()) {
          context.read<CommentNewsCubit>().getMoreCommentNews(
              newsId: (newsModel!.newsId != null &&
                      newsModel!.newsId!.trim().isNotEmpty)
                  ? newsModel!.newsId!
                  : newsModel!.id!);
        } else {
          //debugPrint("No more Comments");
        }
      }
    }
    //for comments area
    if (controller.position.userScrollDirection == ScrollDirection.forward) {
      // User is scrolling up
      if (!_isScrollingUp) {
        setState(() {
          _isScrollingUp = true;
        });
      }
    } else if (controller.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // User is scrolling down
      if (_isScrollingUp) {
        setState(() {
          _isScrollingUp = false;
        });
      }
    }
  }

  Widget shareActionButton() {
    return Padding(
      padding: const EdgeInsets.only(
        right: 18,
        top: 10,
        bottom: 10,
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        child: SvgPictureWidget(
            assetName: 'share_button',
            height: 36,
            width: 36,
            assetColor: ColorFilter.mode(
                UiUtils.getColorScheme(context).primaryContainer,
                BlendMode.srcIn)),
        onTap: () async {
          if (await InternetConnectivity.isNetworkAvailable()) {
            UiUtils.shareNews(
                context: context,
                slug: (!widget.isFromBreak)
                    ? widget.model!.slug!
                    : widget.breakModel!.slug!,
                title: (!widget.isFromBreak)
                    ? widget.model!.title!
                    : widget.breakModel!.title!,
                isNews: (!widget.isFromBreak) ? true : false,
                isVideo: false,
                isReels: false,
                videoId: "",
                isBreakingNews: (!widget.isFromBreak) ? false : true,image: widget.model?.image??"", id: widget.model?.id??"");
          } else {
            showSnackBar(
                UiUtils.getTranslatedLabel(context, 'internetmsg'), context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      onPopInvoked: (bool isTrue) => onBackPress,
      child: AnimatedPadding(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(
            top: _isScrollingUp ? MediaQuery.of(context).viewPadding.top : 0),
        child: Column(children: [
          CustomAppBar(
            height: 54,
            isBackBtn: true,
            label: '',
            isConvertText: true,
            actionWidget: [shareActionButton()],
          ),
          Expanded(
            flex: (Platform.isAndroid) ? 12 : 9,
            child: SingleChildScrollView(
              controller: !widget.isFromBreak && comEnabled && !isReply
                  ? controller
                  : null,
              physics: (_isShortNewsCollapsed && !comEnabled && !isReply)
                  ? const NeverScrollableScrollPhysics()
                  : null,
              child: Column(
                children: [
                  Stack(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: screenWidth * 0.85,
                            child: Stack(
                              children: [
                                /// IMAGE
                                Positioned.fill(
                                  bottom: 72,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ImageView(
                                        isFromBreak: widget.isFromBreak,
                                        model: newsModel,
                                        breakModel: widget.breakModel,
                                      ),
                                      Positioned.fill(
                                        child: Center(
                                          child: videoBtn(
                                            context: context,
                                            isFromBreak: widget.isFromBreak,
                                            model: !widget.isFromBreak
                                                ? newsModel!
                                                : null,
                                            breakModel: widget.isFromBreak
                                                ? widget.breakModel!
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: BlocBuilder<FontSizeCubit,
                                          FontSizeState>(
                                      builder: (context, fontSizeState) {
                                    return allRowBtn(
                                        isFromBreak: widget.isFromBreak,
                                        context: context,
                                        breakModel: widget.isFromBreak
                                            ? widget.breakModel
                                            : null,
                                        model: !widget.isFromBreak
                                            ? newsModel!
                                            : null,
                                        fontVal:
                                            _effectiveFontSize(fontSizeState),
                                        updateFont: _updateFontVal,
                                        isPlaying: isPlaying,
                                        speak: speak,
                                        stop: stop,
                                        updateComEnabled: updateCommentshow);
                                  }),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  otherMainDetails(),
                ],
              ),
            ),
          ),
          // FIGMA(1500-4501): bottom-docked comment input bar, shown only while
          // the comment list is open (not in the reply view, which has its own
          // inline input). Lives outside the scroll so it stays above the
          // keyboard.
          if (!widget.isFromBreak && comEnabled && !isReply)
            CommentInputBar(newsId: newsModel!.id!),
          if ((context.read<AppConfigurationCubit>().getInAppAdsMode() ==
                  "1") ||
              _bannerAd != null)
            Flexible(child: setBannerAd(context, _bannerAd))
        ]),
      ),
    );
  }
}
