import 'dart:math';

import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/features/homepage/widgets/common_section_title.dart';
import 'package:starke_app/features/rss_feed/models/rss_feed_model.dart';
import 'package:flutter/material.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/homepage/models/feature_section_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/core/configs/app_config.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Style1Section extends StatefulWidget {
  final FeatureSectionModel model;

  const Style1Section({super.key, required this.model});

  @override
  Style1SectionState createState() => Style1SectionState();
}

class Style1SectionState extends State<Style1Section> {
  int? style1Sel;
  PageController? _pageStyle1Controller = PageController();
  int limit = limitOfStyle1;
  int newsLength = 0;
  int brNewsLength = 0;

  @override
  void dispose() {
    _pageStyle1Controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    newsLength = (widget.model.newsType == newsTypeToString(NewsType.news) ||
            widget.model.newsType == newsTypeToString(NewsType.userChoice))
        ? (widget.model.news?.length ?? 0)
        : (widget.model.newsType == newsTypeToString(NewsType.rssFeedsNews))
            ? (widget.model.rssFeedNews?.length ?? 0)
            : widget.model.newsType == newsTypeToString(NewsType.authorNews)
                ? (widget.model.authorNews?.length ?? 0)
                : (widget.model.videos?.length ?? 0);
    brNewsLength =
        widget.model.newsType == newsTypeToString(NewsType.breakingNews)
            ? (widget.model.breakNews?.length ?? 0)
            : (widget.model.breakVideos?.length ?? 0);

    return style1Data(widget.model);
  }

  Widget style1Data(FeatureSectionModel model) {
    final isNewsType = model.newsType == newsTypeToString(NewsType.news) ||
        model.newsType == newsTypeToString(NewsType.userChoice) ||
        model.newsType == newsTypeToString(NewsType.authorNews) ||
        model.newsType == newsTypeToString(NewsType.rssFeedsNews);
    final isVideoNewsType = model.videosType == newsTypeToString(NewsType.news);

    final hasData = model.newsType == newsTypeToString(NewsType.rssFeedsNews)
        ? model.rssFeedNews?.isNotEmpty == true
        : model.newsType == newsTypeToString(NewsType.authorNews)
            ? model.authorNews?.isNotEmpty == true
            : isNewsType
                ? model.news?.isNotEmpty == true
                : model.videos?.isNotEmpty == true;
    if (model.breakVideos!.isNotEmpty ||
        model.breakNews!.isNotEmpty ||
        model.videos!.isNotEmpty ||
        model.news?.isNotEmpty == true ||
        model.authorNews?.isNotEmpty == true ||
        (model.rssFeedNews != null && model.rssFeedNews!.isNotEmpty)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commonSectionTitle(model, context),
          if ((isNewsType || isVideoNewsType) && hasData) style1NewsData(model),
          if ((model.newsType == newsTypeToString(NewsType.breakingNews) ||
                  model.videosType == newsTypeToString(NewsType.breakingNews) &&
                      (model.newsType ==
                          newsTypeToString(NewsType.breakingNews))
              ? model.breakNews!.isNotEmpty
              : model.breakVideos!.isNotEmpty))
            style1BreakNewsData(model)
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget style1NewsData(FeatureSectionModel model) {
    final int itemCount =
        model.newsType == newsTypeToString(NewsType.rssFeedsNews)
            ? model.rssFeedNews?.length ?? 0
            : model.newsType == newsTypeToString(NewsType.authorNews)
                ? model.authorNews?.length ?? 0
                : (model.newsType == newsTypeToString(NewsType.news) ||
                        model.newsType == newsTypeToString(NewsType.userChoice))
                    ? model.news?.length ?? 0
                    : model.videos?.length ?? 0;

    final bool hasMultipleItems = itemCount > 1;

    style1Sel = hasMultipleItems ? (style1Sel ?? 1) : 0;

    _pageStyle1Controller = PageController(
      initialPage: hasMultipleItems ? 1 : 0,
      viewportFraction: hasMultipleItems ? 0.87 : 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.36,
          width: double.maxFinite,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: min(newsLength, limit),
            scrollDirection: Axis.horizontal,
            pageSnapping: true,
            controller: _pageStyle1Controller,
            onPageChanged: (index) {
              setState(() => style1Sel = index);
            },
            itemBuilder: (BuildContext context, int index) {
              final List<NewsModel> sourceList = (model.newsType ==
                          newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice))
                  ? (model.news ?? [])
                  : model.newsType == newsTypeToString(NewsType.authorNews)
                      ? (model.authorNews ?? [])
                      : (model.videos ?? []);
              bool isRssFeedsNews =
                  model.newsType == newsTypeToString(NewsType.rssFeedsNews);
              final List<RSSFeedModel> rssSourceList =
                  isRssFeedsNews ? (model.rssFeedNews ?? []) : [];

              final NewsModel data =
                  sourceList.isNotEmpty ? sourceList[index] : NewsModel();
              final RSSFeedModel rssData =
                  isRssFeedsNews ? rssSourceList[index] : RSSFeedModel();

              return InkWell(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                      start: 7,
                      end: 7,
                      top: style1Sel == index
                          ? 0
                          : MediaQuery.of(context).size.height * 0.027),
                  child: Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CustomNetworkImage(
                            networkImageUrl: isRssFeedsNews
                                ? rssData.image ?? ""
                                : data.image ?? "",
                            height: style1Sel == index
                                ? MediaQuery.of(context).size.height / 4
                                : MediaQuery.of(context).size.height / 5,
                            width: double.maxFinite,
                            fit: BoxFit.cover,
                            isVideo: model.newsType ==
                                    newsTypeToString(NewsType.videos)
                                ? true
                                : false),
                      ),
                      if (model.newsType == newsTypeToString(NewsType.videos) ||
                          model.videosType == newsTypeToString(NewsType.videos))
                        Positioned.directional(
                          textDirection: Directionality.of(context),
                          top: MediaQuery.of(context).size.height * 0.075,
                          start: MediaQuery.of(context).size.width / 3,
                          end: MediaQuery.of(context).size.width / 3,
                          child: InkWell(
                              onTap: () {
                                List<NewsModel> newsList =
                                    List.from(model.videos ?? [])
                                      ..removeAt(index);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsVideo, arguments: {
                                  "from": 1,
                                  "model": data,
                                  "otherVideos": newsList
                                });
                              },
                              child: UiUtils.setPlayButton(context: context)),
                        ),
                      Positioned.directional(
                          textDirection: Directionality.of(context),
                          start: 8,
                          end: 8,
                          top: MediaQuery.of(context).size.height / 7,
                          child: Container(
                            alignment: Alignment.center,
                            height: MediaQuery.of(context).size.height / 5,
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsetsDirectional.all(10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: UiUtils.getColorScheme(context).surface),
                            padding: const EdgeInsets.all(13),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isRssFeedsNews &&
                                    data.categoryName != null &&
                                    data.categoryName!.trim().isNotEmpty)
                                  Container(
                                      height: 20.0,
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 8.0, end: 8.0, top: 2.5),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color:
                                              Theme.of(context).primaryColor),
                                      child: CustomTextLabel(
                                          text: data.categoryName!,
                                          textAlign: TextAlign.center,
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: secondaryColor),
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true)),
                                Padding(
                                    padding: const EdgeInsets.only(top: 15.0),
                                    child: CustomTextLabel(
                                        text: isRssFeedsNews
                                            ? rssData.feedName ?? ""
                                            : data.title ?? "",
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                                color: UiUtils.getColorScheme(
                                                        context)
                                                    .primaryContainer,
                                                fontWeight: FontWeight.normal),
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                onTap: () async {
                  // Open RSS feed links in external browser for RSS sections
                  if (isRssFeedsNews &&
                      rssData.feedUrl != null &&
                      rssData.feedUrl!.isNotEmpty) {
                    final uri = Uri.tryParse(rssData.feedUrl!);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                    }
                    return;
                  }

                  if (model.newsType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice) ||
                      model.newsType == newsTypeToString(NewsType.authorNews)) {
                    //interstitial ads
                    UiUtils.showInterstitialAds(context: context);
                    List<NewsModel> newsList = [];
                    newsList.addAll(
                        model.newsType == newsTypeToString(NewsType.authorNews)
                            ? (model.authorNews ?? [])
                            : (model.news ?? []));
                    newsList.removeAt(index);
                    Navigator.of(context).pushNamed(Routes.newsDetails,
                        arguments: {
                          "model": data,
                          "newsList": newsList,
                          "isFromBreak": false,
                          "fromShowMore": false
                        });
                  }
                },
              );
            },
          ),
        ),
        style1Indicator(model, min(newsLength, limit))
      ],
    );
  }

  Widget style1BreakNewsData(FeatureSectionModel model) {
    if (model.newsType == newsTypeToString(NewsType.breakingNews)
        ? (model.breakNews?.length ?? 0) > 1
        : (model.breakVideos?.length ?? 0) > 1) {
      style1Sel ??= 1;
      _pageStyle1Controller =
          PageController(initialPage: 1, viewportFraction: 0.87);
    } else {
      style1Sel = 0;
      _pageStyle1Controller =
          PageController(initialPage: 0, viewportFraction: 1);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.36,
          width: double.maxFinite,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: min(brNewsLength, limit),
            scrollDirection: Axis.horizontal,
            controller: _pageStyle1Controller,
            reverse: false,
            onPageChanged: (index) {
              setState(() => style1Sel = index);
            },
            itemBuilder: (BuildContext context, int index) {
              BreakingNewsModel data =
                  model.newsType == newsTypeToString(NewsType.breakingNews)
                      ? (model.breakNews ?? [])[index]
                      : (model.breakVideos ?? [])[index];

              return Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 7,
                    end: 7,
                    top: style1Sel == index
                        ? 0
                        : MediaQuery.of(context).size.height * 0.027),
                child: InkWell(
                  onTap: () {
                    if (model.newsType ==
                        newsTypeToString(NewsType.breakingNews)) {
                      //interstitial ads
                      UiUtils.showInterstitialAds(context: context);
                      List<BreakingNewsModel> breakList = [];
                      breakList.addAll(model.breakNews!);
                      breakList.removeAt(index);
                      Navigator.of(context)
                          .pushNamed(Routes.newsDetails, arguments: {
                        "breakModel": data,
                        "breakNewsList": breakList,
                        "isFromBreak": true,
                        "fromShowMore": false
                      });
                    }
                  },
                  child: Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CustomNetworkImage(
                            networkImageUrl: data.image!,
                            height: style1Sel == index
                                ? MediaQuery.of(context).size.height / 4
                                : MediaQuery.of(context).size.height / 5,
                            width: double.maxFinite,
                            fit: BoxFit.cover,
                            isVideo: model.newsType ==
                                    newsTypeToString(NewsType.videos)
                                ? true
                                : false),
                      ),
                      if (model.newsType == newsTypeToString(NewsType.videos) ||
                          model.videosType == newsTypeToString(NewsType.videos))
                        Positioned.directional(
                          textDirection: Directionality.of(context),
                          top: MediaQuery.of(context).size.height * 0.075,
                          start: MediaQuery.of(context).size.width / 3,
                          end: MediaQuery.of(context).size.width / 3,
                          child: InkWell(
                              onTap: () {
                                List<BreakingNewsModel> allBrNewsList =
                                    List.from(model.breakVideos ?? [])
                                      ..removeAt(index);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsVideo, arguments: {
                                  "from": 3,
                                  "breakModel": data,
                                  "otherBreakingVideos": allBrNewsList
                                });
                              },
                              child: UiUtils.setPlayButton(context: context)),
                        ),
                      Positioned.directional(
                          textDirection: Directionality.of(context),
                          start: 8,
                          end: 8,
                          top: MediaQuery.of(context).size.height / 7,
                          child: Container(
                              alignment: Alignment.center,
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsetsDirectional.all(10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color:
                                      UiUtils.getColorScheme(context).surface),
                              padding: const EdgeInsets.all(13),
                              child: CustomTextLabel(
                                  text: data.title!,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer,
                                          fontWeight: FontWeight.normal),
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        style1Indicator(model, min(brNewsLength, limit))
      ],
    );
  }

  Widget style1Indicator(FeatureSectionModel model, int len) {
    return len <= 1
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.center,
            child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: map<Widget>(
                    (model.newsType == newsTypeToString(NewsType.news) ||
                            model.newsType ==
                                newsTypeToString(NewsType.userChoice) ||
                            model.newsType ==
                                newsTypeToString(NewsType.authorNews) ||
                            model.newsType ==
                                newsTypeToString(NewsType.rssFeedsNews))
                        ? model.newsType ==
                                newsTypeToString(NewsType.authorNews)
                            ? (model.authorNews ?? [])
                            : (model.news ?? [])
                        : (model.newsType ==
                                newsTypeToString(NewsType.breakingNews))
                            ? (model.breakNews ?? [])
                            : (model.newsType ==
                                        newsTypeToString(NewsType.videos) &&
                                    ((model.videosTotal ?? 0) > 0 &&
                                        (model.videos?.isNotEmpty == true)))
                                ? (model.videos ?? [])
                                : (model.breakVideos ?? []),
                    (index, url) {
                      return Container(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 5.0, end: 5.0),
                          child: Container(
                              height: 14.0,
                              width: 14.0,
                              decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: UiUtils.getColorScheme(context)
                                          .primaryContainer)),
                              child: style1Sel == index
                                  ? Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle),
                                    )
                                  : const SizedBox.shrink()),
                        ),
                      );
                    },
                  ),
                )));
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    int mapLength = (widget.model.newsType == newsTypeToString(NewsType.news) ||
            widget.model.newsType == newsTypeToString(NewsType.userChoice) ||
            widget.model.newsType == newsTypeToString(NewsType.authorNews))
        ? (widget.model.newsType == newsTypeToString(NewsType.rssFeedsNews))
            ? min(widget.model.rssFeedNews?.length ?? 0, limit)
            : (widget.model.newsType == newsTypeToString(NewsType.authorNews))
                ? min(widget.model.authorNews?.length ?? 0, limit)
                : min(newsLength, limit)
        : min(brNewsLength, limit);
    for (var i = 0; i < mapLength; i++) {
      result.add(handler(i, list[i]));
    }
    return result;
  }
}
