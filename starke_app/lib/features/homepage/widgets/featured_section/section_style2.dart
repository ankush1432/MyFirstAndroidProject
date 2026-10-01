import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/features/homepage/widgets/common_section_title.dart';
import 'package:starke_app/features/rss_feed/models/rss_feed_model.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/homepage/models/feature_section_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/core/configs/app_config.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Style2Section extends StatelessWidget {
  final FeatureSectionModel model;
  bool isNews = true;

  Style2Section({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return style2Data(model, context);
  }

  Widget style2Data(FeatureSectionModel model, BuildContext context) {
    if (model.breakVideos!.isNotEmpty ||
        model.breakNews!.isNotEmpty ||
        model.videos!.isNotEmpty ||
        model.news?.isNotEmpty == true ||
        model.authorNews?.isNotEmpty == true ||
        (model.rssFeedNews != null && model.rssFeedNews!.isNotEmpty)) {
      final bool isRegularNewsType =
          model.newsType == newsTypeToString(NewsType.news) ||
              model.newsType == newsTypeToString(NewsType.userChoice) ||
              model.newsType == newsTypeToString(NewsType.authorNews) ||
              model.newsType == newsTypeToString(NewsType.rssFeedsNews) ||
              model.videosType == newsTypeToString(NewsType.news);

      final bool hasRegularNewsData = model.newsType ==
              newsTypeToString(NewsType.rssFeedsNews)
          ? model.rssFeedNews?.isNotEmpty == true
          : model.newsType == newsTypeToString(NewsType.authorNews)
              ? model.authorNews?.isNotEmpty == true
              : (model.newsType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice))
                  ? model.news?.isNotEmpty == true
                  : model.videos?.isNotEmpty == true;

      final bool isBreakingNewsType =
          model.newsType == newsTypeToString(NewsType.breakingNews) ||
              model.videosType == newsTypeToString(NewsType.breakingNews);

      final bool hasBreakingNewsData =
          model.newsType == newsTypeToString(NewsType.breakingNews)
              ? model.breakNews?.isNotEmpty == true
              : model.breakVideos?.isNotEmpty == true;

      if (isRegularNewsType && hasRegularNewsData) isNews = true;

      if (isBreakingNewsType && hasBreakingNewsData) isNews = false;

      int limit = limitOfAllOtherStyle;
      final List items = model.newsType ==
              newsTypeToString(NewsType.rssFeedsNews)
          ? model.rssFeedNews!
          : model.newsType == newsTypeToString(NewsType.authorNews)
              ? (model.authorNews ?? [])
              : (model.newsType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice))
                  ? model.news!
                  : model.videos!;

      final int newsLength = items.length;

      int brNewsLength =
          model.newsType == newsTypeToString(NewsType.breakingNews)
              ? model.breakNews!.length
              : model.breakVideos!.length;

      var totalCount =
          (isNews) ? min(newsLength, limit) : min(brNewsLength, limit);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commonSectionTitle(model, context),
          ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: totalCount,
              itemBuilder: (context, index) {
                if (isNews) {
                  if (model.newsType ==
                      newsTypeToString(NewsType.rssFeedsNews)) {
                    return setStyle2(
                        context: context,
                        index: index,
                        model: model,
                        rssFeedModel: model.rssFeedNews![index]);
                  } else {
                    final items =
                        (model.newsType == newsTypeToString(NewsType.news) ||
                                model.newsType ==
                                    newsTypeToString(NewsType.userChoice))
                            ? model.news!
                            : model.videos!;
                    final authorItems =
                        model.newsType == newsTypeToString(NewsType.authorNews)
                            ? (model.authorNews ?? [])
                            : [];

                    final item =
                        model.newsType == newsTypeToString(NewsType.authorNews)
                            ? authorItems[index]
                            : items[index];
                    return setStyle2(
                        context: context,
                        index: index,
                        model: model,
                        newsModel: item);
                  }
                } else {
                  return setStyle2(
                      context: context,
                      index: index,
                      model: model,
                      breakingNewsModel: (model.newsType ==
                              newsTypeToString(NewsType.breakingNews))
                          ? model.breakNews![index]
                          : model.breakVideos![index]);
                }
              })
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget setStyle2(
      {required BuildContext context,
      required int index,
      required FeatureSectionModel model,
      NewsModel? newsModel,
      BreakingNewsModel? breakingNewsModel,
      RSSFeedModel? rssFeedModel}) {
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 0 : 15),
      child: Column(
        children: [
          if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1" &&
              (context.read<AppConfigurationCubit>().getAdsType() != "unity" ||
                  context.read<AppConfigurationCubit>().getIOSAdsType() !=
                      "unity"))
            nativeAdsShow(context: context, index: index),
          InkWell(
            onTap: () async {
              // If RSS feed section, open link in external browser
              if (model.newsType == newsTypeToString(NewsType.rssFeedsNews) &&
                  rssFeedModel != null &&
                  rssFeedModel.feedUrl != null &&
                  rssFeedModel.feedUrl!.isNotEmpty) {
                final uri = Uri.tryParse(rssFeedModel.feedUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                }
                return;
              }

              //interstitial ads
              UiUtils.showInterstitialAds(context: context);
              if (model.newsType == newsTypeToString(NewsType.news) ||
                  model.newsType == newsTypeToString(NewsType.userChoice) ||
                  model.newsType == newsTypeToString(NewsType.authorNews)) {
                List<NewsModel> newsList = [];
                newsList.addAll(
                    model.newsType == newsTypeToString(NewsType.authorNews)
                        ? (model.authorNews ?? [])
                        : (model.news ?? []));
                newsList.removeAt(index);
                Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                  "model": newsModel,
                  "newsList": newsList,
                  "isFromBreak": false,
                  "fromShowMore": false
                });
              } else if (model.newsType ==
                  newsTypeToString(NewsType.breakingNews)) {
                List<BreakingNewsModel> breakList = [];
                breakList.addAll(model.breakNews!);
                breakList.removeAt(index);
                Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                  "breakModel": breakingNewsModel,
                  "breakNewsList": breakList,
                  "isFromBreak": true,
                  "fromShowMore": false
                });
              }
            },
            child: Stack(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            darkSecondaryColor.withOpacity(0.9)
                          ]).createShader(rect),
                      blendMode: BlendMode.darken,
                      child: Container(
                        color: primaryColor.withAlpha(5),
                        width: double.maxFinite,
                        height: MediaQuery.of(context).size.height / 3.3,
                        child: CustomNetworkImage(
                            networkImageUrl: (rssFeedModel != null)
                                ? rssFeedModel.image ?? ""
                                : (newsModel != null)
                                    ? newsModel.image!
                                    : breakingNewsModel!.image!,
                            fit: BoxFit.cover,
                            width: double.maxFinite,
                            height: MediaQuery.of(context).size.height / 3.3,
                            isVideo: model.newsType ==
                                    newsTypeToString(NewsType.videos)
                                ? true
                                : false),
                      ),
                    )),
                if (model.newsType == newsTypeToString(NewsType.videos) ||
                    model.videosType == newsTypeToString(NewsType.videos))
                  Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: MediaQuery.of(context).size.height * 0.12,
                      start: MediaQuery.of(context).size.width / 3,
                      end: MediaQuery.of(context).size.width / 3,
                      child: InkWell(
                          onTap: () {
                            List<NewsModel> newsList = [];
                            List<BreakingNewsModel> brNewsList = [];
                            if (model.breakVideos != null &&
                                model.breakVideos!.isNotEmpty)
                              brNewsList = List.from(model.breakVideos ?? [])
                                ..removeAt(index);
                            if (model.videos != null &&
                                model.videos!.isNotEmpty)
                              newsList = List.from(model.videos ?? [])
                                ..removeAt(index);
                            Navigator.of(context)
                                .pushNamed(Routes.newsVideo, arguments: {
                              "from": 1,
                              "model": (newsModel != null)
                                  ? newsModel
                                  : breakingNewsModel!,
                              if (newsList.isNotEmpty) "otherVideos": newsList,
                              if (brNewsList.isNotEmpty)
                                "otherBreakingVideos": brNewsList
                            });
                          },
                          child: UiUtils.setPlayButton(context: context))),
                Positioned.directional(
                    textDirection: Directionality.of(context),
                    bottom: 10,
                    start: 10,
                    end: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (newsModel != null && newsModel.categoryName != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Container(
                              color: primaryColor,
                              padding: const EdgeInsets.all(5),
                              child: CustomTextLabel(
                                  text: newsModel.categoryName!,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: secondaryColor),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true),
                            ),
                          ),
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: CustomTextLabel(
                                text: (rssFeedModel != null)
                                    ? rssFeedModel.feedName ?? ""
                                    : (newsModel != null)
                                        ? newsModel.title!
                                        : breakingNewsModel!.title!,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: secondaryColor,
                                        fontWeight: FontWeight.normal),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true)),
                      ],
                    ))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
