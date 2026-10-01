import 'dart:math';

import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/features/rss_feed/models/rss_feed_model.dart';
import 'package:flutter/material.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/homepage/models/feature_section_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/features/homepage/widgets/common_section_title.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/core/configs/app_config.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class Style5Section extends StatelessWidget {
  final FeatureSectionModel model;

  const Style5Section({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return style5Data(model, context);
  }

  Widget style5SingleNewsData(FeatureSectionModel model, BuildContext context) {
    bool isRssFeedsNews =
        model.newsType == newsTypeToString(NewsType.rssFeedsNews);
    final RSSFeedModel rssData = (isRssFeedsNews)
        ? (model.rssFeedNews?[0] ?? RSSFeedModel())
        : RSSFeedModel();
    NewsModel data = (model.newsType == newsTypeToString(NewsType.news) ||
            model.newsType == newsTypeToString(NewsType.userChoice))
        ? (model.news ?? [])[0]
        : (model.newsType == newsTypeToString(NewsType.authorNews))
            ? (model.authorNews ?? [])[0]
            : (model.newsType == newsTypeToString(NewsType.videos))
                ? (model.videos ?? [])[0]
                : NewsModel();
    return InkWell(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.28,
        width: double.maxFinite,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CustomNetworkImage(
                  networkImageUrl: (isRssFeedsNews)
                      ? (rssData.image ?? "")
                      : (data.image ?? ""),
                  height: MediaQuery.of(context).size.height * 0.28,
                  width: double.maxFinite,
                  fit: BoxFit.cover,
                  isVideo: model.newsType == newsTypeToString(NewsType.videos)
                      ? true
                      : false),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      shadowColor1,
                      shadowColor2,
                      shadowColor3,
                    ],
                    stops: [
                      0.0,
                      0.45,
                      0.65,
                      0.82,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.height * 0.01),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isRssFeedsNews &&
                        data.categoryName != null &&
                        data.categoryName!.trim().isNotEmpty)
                      Container(
                          // height: 20.0,
                          padding: const EdgeInsetsDirectional.only(
                              start: 8.0, end: 8.0, top: 2.5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Theme.of(context).primaryColor),
                          child: CustomTextLabel(
                              text: data.categoryName!,
                              textAlign: TextAlign.left,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: secondaryColor),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true)),
                    Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.01),
                        child: CustomTextLabel(
                            text: isRssFeedsNews
                                ? rssData.feedName ?? ""
                                : data.title ?? "",
                            textAlign: TextAlign.left,
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w700),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true)),
                    //  (data.publishDate != null || data.date != null)
                    Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPictureWidget(
                              assetName: 'calendar',
                              height: 20,
                              width: 20,
                              assetColor: ColorFilter.mode(
                                  secondaryColor, BlendMode.srcIn)),
                          Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 10),
                              child: CustomTextLabel(
                                  text: UiUtils.convertToAgo(
                                      context,
                                      DateTime.parse((isRssFeedsNews)
                                          ? rssData.pubDate ??
                                              rssData.date ??
                                              ""
                                          : data.publishDate ?? data.date!),
                                      0)!,
                                  textAlign: TextAlign.left,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: secondaryColor,
                                          fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true))
                        ],
                      ),
                    ),
                    // : const SizedBox.shrink(),
                    if (model.newsType == newsTypeToString(NewsType.videos))
                      InkWell(
                        child: Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.02),
                            child: UiUtils.setPlayButton(context: context)),
                        onTap: () {
                          List<NewsModel> allNewsList =
                              List.from(model.videos ?? [])
                                ..removeWhere((item) => item.id == data.id);
                          Navigator.of(context).pushNamed(Routes.newsVideo,
                              arguments: {
                                "from": 1,
                                "model": data,
                                "otherVideos": allNewsList
                              });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        // Open RSS feed links in external browser for RSS sections
        if (model.newsType == newsTypeToString(NewsType.rssFeedsNews) &&
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
          newsList.removeAt(0);
          Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
            "model": data,
            "newsList": newsList,
            "isFromBreak": false,
            "fromShowMore": false
          });
        }
      },
    );
  }

  Widget style5SingleBreakNewsData(
      FeatureSectionModel model, BuildContext context) {
    BreakingNewsModel data =
        model.newsType == newsTypeToString(NewsType.breakingNews)
            ? (model.breakNews ?? [])[0]
            : (model.breakVideos ?? [])[0];
    return InkWell(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.28,
        width: double.maxFinite,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      darkSecondaryColor.withOpacity(0.9)
                    ]).createShader(rect),
                blendMode: BlendMode.darken,
                child: CustomNetworkImage(
                    networkImageUrl: data.image!,
                    height: MediaQuery.of(context).size.height * 0.28,
                    width: double.maxFinite,
                    fit: BoxFit.cover,
                    isVideo: model.newsType == newsTypeToString(NewsType.videos)
                        ? true
                        : false),
              ),
            ),
            (model.newsType == newsTypeToString(NewsType.videos))
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.height * 0.01),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height *
                                        0.02),
                                child: CustomTextLabel(
                                    text: data.title!,
                                    textAlign: TextAlign.left,
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: secondaryColor,
                                            fontWeight: FontWeight.w700),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true)),
                            InkWell(
                              child: Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height *
                                          0.02),
                                  child:
                                      UiUtils.setPlayButton(context: context)),
                              onTap: () {
                                List<BreakingNewsModel> brNewsList = List.from(
                                    model.breakVideos ?? [])
                                  ..removeWhere((item) => item.id == data.id);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsVideo, arguments: {
                                  "from": 3,
                                  "breakModel": data,
                                  "otherBreakingVideos": brNewsList
                                });
                              },
                            ),
                          ],
                        )),
                  )
                : Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.height * 0.01),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15)),
                        child: CustomTextLabel(
                            text: data.title!,
                            textAlign: TextAlign.left,
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w700),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true)),
                  ),
          ],
        ),
      ),
      onTap: () {
        if (model.newsType == newsTypeToString(NewsType.breakingNews)) {
          //show interstitial ads
          UiUtils.showInterstitialAds(context: context);
          List<BreakingNewsModel> breakList = [];
          breakList.addAll(model.breakNews!);
          breakList.removeAt(0);
          Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
            "breakModel": data,
            "breakNewsList": breakList,
            "isFromBreak": true,
            "fromShowMore": false
          });
        }
      },
    );
  }

  Widget style5Data(FeatureSectionModel model, BuildContext context) {
    int limit = limitOfAllOtherStyle;
    int newsLength = (model.newsType == newsTypeToString(NewsType.news) ||
            model.newsType == newsTypeToString(NewsType.userChoice))
        ? (model.news?.length ?? 0)
        : (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
            ? (model.rssFeedNews?.length ?? 0)
            : (model.newsType == newsTypeToString(NewsType.authorNews))
                ? (model.authorNews?.length ?? 0)
                : (model.videos?.length ?? 0);
    int brNewsLength = model.newsType == newsTypeToString(NewsType.breakingNews)
        ? (model.breakNews?.length ?? 0)
        : (model.breakVideos?.length ?? 0);

    if (model.breakVideos!.isNotEmpty ||
        model.breakNews!.isNotEmpty ||
        model.videos!.isNotEmpty ||
        model.news?.isNotEmpty == true ||
        model.authorNews?.isNotEmpty == true ||
        model.rssFeedNews?.isNotEmpty == true) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commonSectionTitle(model, context),
          if ((model.newsType == newsTypeToString(NewsType.news) ||
                      model.videosType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice) ||
                      model.newsType == newsTypeToString(NewsType.authorNews) ||
                      model.newsType ==
                          newsTypeToString(NewsType.rssFeedsNews)) &&
                  (model.newsType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice) ||
                      model.newsType == newsTypeToString(NewsType.authorNews) ||
                      model.newsType == newsTypeToString(NewsType.rssFeedsNews))
              ? (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
                  ? model.rssFeedNews?.isNotEmpty == true
                  : (model.newsType == newsTypeToString(NewsType.authorNews))
                      ? model.authorNews?.isNotEmpty == true
                      : model.news!.isNotEmpty
              : model.videos!.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                style5SingleNewsData(model, context),
                if (newsLength > 1)
                  Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children:
                                List.generate(min(newsLength, limit), (index) {
                              if (newsLength > index + 1) {
                                bool isRssFeedsNews = model.newsType ==
                                    newsTypeToString(NewsType.rssFeedsNews);
                                final RSSFeedModel rssData = (isRssFeedsNews)
                                    ? (model.rssFeedNews?[index + 1] ??
                                        RSSFeedModel())
                                    : RSSFeedModel();
                                NewsModel data = (model.newsType ==
                                            newsTypeToString(NewsType.news) ||
                                        model.newsType ==
                                            newsTypeToString(
                                                NewsType.userChoice))
                                    ? (model.news ?? [])[index + 1]
                                    : (model.newsType ==
                                            newsTypeToString(
                                                NewsType.authorNews))
                                        ? (model.authorNews ?? [])[index + 1]
                                        : (model.newsType ==
                                                newsTypeToString(
                                                    NewsType.videos))
                                            ? (model.videos ?? [])[index + 1]
                                            : NewsModel();
                                return InkWell(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width /
                                        2.35,
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.only(
                                          start: index == 0 ? 0 : 10.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Stack(children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: CustomNetworkImage(
                                                  networkImageUrl:
                                                      (isRssFeedsNews)
                                                          ? (rssData.image ??
                                                              "")
                                                          : (data.image ?? ""),
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.15,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2.35,
                                                  fit: BoxFit.cover,
                                                  isVideo: model.newsType ==
                                                          newsTypeToString(
                                                              NewsType.videos)
                                                      ? true
                                                      : false),
                                            ),
                                            if (!isRssFeedsNews &&
                                                data.categoryName != null &&
                                                data.categoryName!
                                                    .trim()
                                                    .isNotEmpty)
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                    margin:
                                                        const EdgeInsetsDirectional.only(
                                                            start: 7.0,
                                                            top: 7.0),
                                                    padding:
                                                        const EdgeInsetsDirectional.symmetric(
                                                            horizontal: 6.0,
                                                            vertical: 2.0),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                5),
                                                        color: Theme.of(context)
                                                            .primaryColor),
                                                    child: CustomTextLabel(
                                                        text:
                                                            data.categoryName!,
                                                        textAlign:
                                                            TextAlign.left,
                                                        textStyle: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                                color:
                                                                    secondaryColor),
                                                        overflow: TextOverflow.ellipsis,
                                                        softWrap: true)),
                                              ),
                                            if (model.newsType ==
                                                newsTypeToString(
                                                    NewsType.videos))
                                              Positioned.directional(
                                                textDirection:
                                                    Directionality.of(context),
                                                top: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.058,
                                                start: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    8.5,
                                                end: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    8.5,
                                                child: InkWell(
                                                    onTap: () {
                                                      List<NewsModel>
                                                          allNewsList =
                                                          List.from(
                                                              model.videos ??
                                                                  [])
                                                            ..removeAt(index);
                                                      Navigator.of(context)
                                                          .pushNamed(
                                                              Routes.newsVideo,
                                                              arguments: {
                                                            "from": 1,
                                                            "model": data,
                                                            "otherVideos":
                                                                allNewsList
                                                          });
                                                    },
                                                    child:
                                                        UiUtils.setPlayButton(
                                                            context: context,
                                                            heightVal: 28)),
                                              ),
                                          ]),
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: CustomTextLabel(
                                                  text: isRssFeedsNews
                                                      ? rssData.feedName ?? ""
                                                      : data.title ?? "",
                                                  textStyle: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium!
                                                      .copyWith(
                                                          color: UiUtils
                                                                  .getColorScheme(
                                                                      context)
                                                              .primaryContainer),
                                                  softWrap: true,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis)),
                                          //(data.publishDate != null ||
                                          //      data.date != null)
                                          //?

                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPictureWidget(
                                                    assetName: 'calendar',
                                                    height: 15,
                                                    width: 15,
                                                    assetColor: ColorFilter.mode(
                                                        UiUtils.getColorScheme(
                                                                context)
                                                            .primaryContainer
                                                            .withOpacity(0.7),
                                                        BlendMode.srcIn)),
                                                Padding(
                                                    padding: const EdgeInsetsDirectional.only(
                                                        start: 5),
                                                    child: CustomTextLabel(
                                                        text: (isRssFeedsNews)
                                                            ? UiUtils.convertToAgo(
                                                                context,
                                                                DateTime.parse(rssData.pubDate ??
                                                                    rssData
                                                                        .date ??
                                                                    ""),
                                                                2)!
                                                            : UiUtils.convertToAgo(
                                                                context,
                                                                DateTime.parse(data
                                                                        .publishDate ??
                                                                    data.date!),
                                                                0)!,
                                                        textAlign:
                                                            TextAlign.left,
                                                        textStyle: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                                color: UiUtils.getColorScheme(context)
                                                                    .primaryContainer
                                                                    .withOpacity(0.7),
                                                                fontWeight: FontWeight.w500),
                                                        overflow: TextOverflow.ellipsis,
                                                        softWrap: true))
                                              ],
                                            ),
                                          ),
                                          //    : const SizedBox.shrink(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onTap: () async {
                                    // Open RSS feed links in external browser for RSS sections
                                    if (model.newsType ==
                                            newsTypeToString(
                                                NewsType.rssFeedsNews) &&
                                        rssData.feedUrl != null &&
                                        rssData.feedUrl!.isNotEmpty) {
                                      final uri =
                                          Uri.tryParse(rssData.feedUrl!);
                                      if (uri != null) {
                                        await launchUrl(uri,
                                            mode: LaunchMode.inAppBrowserView);
                                      }
                                      return;
                                    }

                                    if (model.newsType ==
                                            newsTypeToString(NewsType.news) ||
                                        model.newsType ==
                                            newsTypeToString(
                                                NewsType.userChoice) ||
                                        model.newsType ==
                                            newsTypeToString(
                                                NewsType.authorNews)) {
                                      //interstitial ads
                                      UiUtils.showInterstitialAds(
                                          context: context);
                                      List<NewsModel> newsList = [];
                                      newsList.addAll(model.newsType ==
                                              newsTypeToString(
                                                  NewsType.authorNews)
                                          ? (model.authorNews ?? [])
                                          : (model.news ?? []));
                                      newsList.removeAt(index + 1);
                                      Navigator.of(context).pushNamed(
                                          Routes.newsDetails,
                                          arguments: {
                                            "model": data,
                                            "newsList": newsList,
                                            "isFromBreak": false,
                                            "fromShowMore": false
                                          });
                                    }
                                  },
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            })),
                      )),
              ],
            ),
          if ((model.newsType == newsTypeToString(NewsType.breakingNews) &&
                  model.breakNews?.isNotEmpty == true) ||
              (model.videosType == newsTypeToString(NewsType.breakingNews) &&
                  model.breakVideos?.isNotEmpty == true))
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                style5SingleBreakNewsData(model, context),
                if (brNewsLength > 1)
                  Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(min(brNewsLength, limit),
                                (index) {
                              if (brNewsLength > index + 1) {
                                BreakingNewsModel data = model.newsType ==
                                        newsTypeToString(NewsType.breakingNews)
                                    ? (model.breakNews ?? [])[index + 1]
                                    : (model.breakVideos ?? [])[index + 1];
                                return InkWell(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width /
                                        2.35,
                                    padding: EdgeInsetsDirectional.only(
                                        start: index == 0 ? 0 : 10.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: CustomNetworkImage(
                                                networkImageUrl: data.image!,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.15,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2.35,
                                                fit: BoxFit.cover,
                                                isVideo: model.newsType ==
                                                        newsTypeToString(
                                                            NewsType.videos)
                                                    ? true
                                                    : false),
                                          ),
                                          if (model.newsType ==
                                                  newsTypeToString(
                                                      NewsType.videos) ||
                                              model.videosType ==
                                                  newsTypeToString(
                                                      NewsType.videos))
                                            Positioned.directional(
                                              textDirection:
                                                  Directionality.of(context),
                                              top: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.058,
                                              start: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  8.5,
                                              end: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  8.5,
                                              child: InkWell(
                                                  onTap: () {
                                                    List<BreakingNewsModel>
                                                        brNewsList = List.from(
                                                            model.breakVideos ??
                                                                [])
                                                          ..removeAt(index);
                                                    Navigator.of(context)
                                                        .pushNamed(
                                                            Routes.newsVideo,
                                                            arguments: {
                                                          "from": 3,
                                                          "breakModel": data,
                                                          "otherBreakingVideos":
                                                              brNewsList
                                                        });
                                                  },
                                                  child: UiUtils.setPlayButton(
                                                      context: context,
                                                      heightVal: 28)),
                                            ),
                                        ]),
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: CustomTextLabel(
                                                text: data.title!,
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall!
                                                    .copyWith(
                                                        color: UiUtils
                                                                .getColorScheme(
                                                                    context)
                                                            .primaryContainer),
                                                softWrap: true,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    if (model.newsType ==
                                            newsTypeToString(
                                                NewsType.breakingNews) ||
                                        model.videosType ==
                                            newsTypeToString(
                                                NewsType.breakingNews)) {
                                      //interstitial ads
                                      UiUtils.showInterstitialAds(
                                          context: context);
                                      List<BreakingNewsModel> breakList = [];
                                      breakList.addAll(model.breakNews!);
                                      breakList.removeAt(index + 1);
                                      Navigator.of(context).pushNamed(
                                          Routes.newsDetails,
                                          arguments: {
                                            "breakModel": data,
                                            "breakNewsList": breakList,
                                            "isFromBreak": true,
                                            "fromShowMore": false
                                          });
                                    }
                                  },
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            })),
                      )),
              ],
            )
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
