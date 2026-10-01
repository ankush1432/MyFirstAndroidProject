import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/features/homepage/widgets/common_section_title.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/homepage/models/feature_section_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/features/rss_feed/models/rss_feed_model.dart';
import 'package:starke_app/core/configs/app_config.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Style3Section extends StatelessWidget {
  final FeatureSectionModel model;

  const Style3Section({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return style3Data(model, context);
  }

  Widget style3Data(FeatureSectionModel model, BuildContext context) {
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
          if ((model.newsType == newsTypeToString(NewsType.breakingNews) ||
                  model.videosType ==
                      newsTypeToString(NewsType.breakingNews)) &&
              (model.newsType == newsTypeToString(NewsType.breakingNews)
                  ? model.breakNews?.isNotEmpty == true
                  : model.breakVideos?.isNotEmpty == true))
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.34,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: min(brNewsLength, limit),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      BreakingNewsModel data = model.newsType ==
                              newsTypeToString(NewsType.breakingNews)
                          ? (model.breakNews ?? [])[index]
                          : (model.breakVideos ?? [])[index];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((index != 0 && index % nativeAdsIndex == 0) &&
                              context
                                      .read<AppConfigurationCubit>()
                                      .getInAppAdsMode() ==
                                  "1" &&
                              (context
                                          .read<AppConfigurationCubit>()
                                          .getAdsType() !=
                                      "unity" ||
                                  context
                                          .read<AppConfigurationCubit>()
                                          .getIOSAdsType() !=
                                      "unity"))
                            SizedBox(
                                width: MediaQuery.of(context).size.width * 0.87,
                                child: nativeAdsShow(
                                    context: context, index: index)),
                          InkWell(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.87,
                              child: Stack(
                                children: <Widget>[
                                  Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      start: 0,
                                      end: 0,
                                      top: MediaQuery.of(context).size.height /
                                          15,
                                      child: Container(
                                        alignment: Alignment.center,
                                        height:
                                            MediaQuery.of(context).size.height /
                                                4,
                                        margin: EdgeInsetsDirectional.only(
                                            start: index == 0 ? 0 : 10,
                                            end: 10,
                                            top: 10,
                                            bottom: 10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            color:
                                                UiUtils.getColorScheme(context)
                                                    .surface),
                                        padding: const EdgeInsets.all(14),
                                        child: Padding(
                                            padding: EdgeInsets.only(
                                                top: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    9),
                                            child: CustomTextLabel(
                                                text: data.title!,
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .copyWith(
                                                        color: UiUtils
                                                                .getColorScheme(
                                                                    context)
                                                            .primaryContainer,
                                                        fontWeight:
                                                            FontWeight.normal),
                                                softWrap: true,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                      )),
                                  Positioned.directional(
                                    textDirection: Directionality.of(context),
                                    start: 30,
                                    end: 30,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: CustomNetworkImage(
                                          networkImageUrl: data.image!,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              4.7,
                                          width: double.maxFinite,
                                          fit: BoxFit.cover,
                                          isVideo: model.newsType ==
                                                  newsTypeToString(
                                                      NewsType.videos)
                                              ? true
                                              : false),
                                    ),
                                  ),
                                  if (model.newsType ==
                                          newsTypeToString(NewsType.videos) ||
                                      model.videosType ==
                                          newsTypeToString(NewsType.videos))
                                    Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      top: MediaQuery.of(context).size.height *
                                          0.085,
                                      start:
                                          MediaQuery.of(context).size.width / 3,
                                      end:
                                          MediaQuery.of(context).size.width / 3,
                                      child: InkWell(
                                          onTap: () {
                                            List<BreakingNewsModel> brNewsList =
                                                List.from(
                                                    model.breakVideos ?? [])
                                                  ..removeAt(index);
                                            Navigator.of(context).pushNamed(
                                                Routes.newsVideo,
                                                arguments: {
                                                  "from": 3,
                                                  "breakModel": data,
                                                  "otherBreakingVideos":
                                                      brNewsList
                                                });
                                          },
                                          child: UiUtils.setPlayButton(
                                              context: context)),
                                    ),
                                ],
                              ),
                            ),
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
                          ),
                        ],
                      );
                    })),
          if ((model.newsType == newsTypeToString(NewsType.news) ||
                  model.videosType == newsTypeToString(NewsType.news) ||
                  model.newsType == newsTypeToString(NewsType.userChoice) ||
                  model.newsType == newsTypeToString(NewsType.authorNews) ||
                  model.newsType == newsTypeToString(NewsType.rssFeedsNews)) &&
              ((model.newsType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice) ||
                      model.newsType == newsTypeToString(NewsType.authorNews) ||
                      model.newsType == newsTypeToString(NewsType.rssFeedsNews))
                  ? (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
                      ? model.rssFeedNews?.isNotEmpty == true
                      : (model.newsType ==
                              newsTypeToString(NewsType.authorNews))
                          ? model.authorNews?.isNotEmpty == true
                          : model.news?.isNotEmpty == true
                  : model.videos?.isNotEmpty == true))
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.34,
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: min(newsLength, limit),
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      bool isRssFeedsNews = model.newsType ==
                          newsTypeToString(NewsType.rssFeedsNews);

                      NewsModel data =
                          (model.newsType == newsTypeToString(NewsType.news) ||
                                  model.newsType ==
                                      newsTypeToString(NewsType.userChoice))
                              ? (model.news ?? [])[index]
                              : (isRssFeedsNews)
                                  ? NewsModel()
                                  : (model.newsType ==
                                          newsTypeToString(NewsType.authorNews))
                                      ? (model.authorNews ?? [])[index]
                                      : (model.videos ?? [])[index];
                      final RSSFeedModel rssData =
                          // model.rssFeedNews![index];

                          (model.newsType ==
                                  newsTypeToString(NewsType.rssFeedsNews))
                              ? (model.rssFeedNews?[index] ?? RSSFeedModel())
                              : RSSFeedModel();

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((index != 0 && index % nativeAdsIndex == 0) &&
                              context
                                      .read<AppConfigurationCubit>()
                                      .getInAppAdsMode() ==
                                  "1" &&
                              (context
                                          .read<AppConfigurationCubit>()
                                          .getAdsType() !=
                                      "unity" ||
                                  context
                                          .read<AppConfigurationCubit>()
                                          .getIOSAdsType() !=
                                      "unity"))
                            SizedBox(
                                width: MediaQuery.of(context).size.width * 0.87,
                                child: nativeAdsShow(
                                    context: context, index: index)),
                          InkWell(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.87,
                              child: Stack(
                                children: <Widget>[
                                  Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      start: 0,
                                      end: 0,
                                      top: MediaQuery.of(context).size.height /
                                          15,
                                      child: Container(
                                        alignment: Alignment.center,
                                        height:
                                            MediaQuery.of(context).size.height /
                                                3.8,
                                        margin: EdgeInsetsDirectional.only(
                                            start: index == 0 ? 0 : 10,
                                            end: 10,
                                            top: 10,
                                            bottom: 10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            color:
                                                UiUtils.getColorScheme(context)
                                                    .surface),
                                        padding: const EdgeInsets.all(14),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              top: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  8),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (!isRssFeedsNews &&
                                                  data.categoryName != null &&
                                                  data.categoryName!
                                                      .trim()
                                                      .isNotEmpty)
                                                Container(
                                                    height: 20.0,
                                                    padding:
                                                        const EdgeInsetsDirectional.only(
                                                            start: 8.0,
                                                            end: 8.0,
                                                            top: 2.5),
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
                                                            TextAlign.center,
                                                        textStyle: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                color:
                                                                    secondaryColor),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        softWrap: true)),
                                              Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 10.0),
                                                  child: CustomTextLabel(
                                                      text: isRssFeedsNews
                                                          ? rssData.feedName ??
                                                              ""
                                                          : data.title ?? "",
                                                      textStyle: Theme.of(
                                                              context)
                                                          .textTheme
                                                          .titleMedium!
                                                          .copyWith(
                                                              color: UiUtils
                                                                      .getColorScheme(
                                                                          context)
                                                                  .primaryContainer,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal),
                                                      softWrap: true,
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis)),
                                            ],
                                          ),
                                        ),
                                      )),
                                  Positioned.directional(
                                    textDirection: Directionality.of(context),
                                    start: 30,
                                    end: 30,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: CustomNetworkImage(
                                          networkImageUrl: isRssFeedsNews
                                              ? rssData.image ?? ""
                                              : data.image ?? "",
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              4.7,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          fit: BoxFit.cover,
                                          isVideo: model.newsType ==
                                                  newsTypeToString(
                                                      NewsType.videos)
                                              ? true
                                              : false),
                                    ),
                                  ),
                                  if (model.newsType ==
                                          newsTypeToString(NewsType.videos) ||
                                      model.videosType ==
                                          newsTypeToString(NewsType.videos))
                                    Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      top: MediaQuery.of(context).size.height *
                                          0.085,
                                      start:
                                          MediaQuery.of(context).size.width / 3,
                                      end:
                                          MediaQuery.of(context).size.width / 3,
                                      child: InkWell(
                                          onTap: () {
                                            List<NewsModel> allNewsList =
                                                List.from(model.videos ?? [])
                                                  ..removeAt(index);
                                            Navigator.of(context).pushNamed(
                                                Routes.newsVideo,
                                                arguments: {
                                                  "from": 1,
                                                  "model": data,
                                                  "otherVideos": allNewsList
                                                });
                                          },
                                          child: UiUtils.setPlayButton(
                                              context: context)),
                                    ),
                                ],
                              ),
                            ),
                            onTap: () async {
                              // Open RSS feed links in external browser for RSS sections
                              if (model.newsType ==
                                      newsTypeToString(NewsType.rssFeedsNews) &&
                                  rssData.feedUrl != null &&
                                  rssData.feedUrl!.isNotEmpty) {
                                final uri = Uri.tryParse(rssData.feedUrl!);
                                if (uri != null) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.inAppBrowserView);
                                }
                                return;
                              }

                              if (model.newsType ==
                                      newsTypeToString(NewsType.news) ||
                                  model.newsType ==
                                      newsTypeToString(NewsType.userChoice) ||
                                  model.newsType ==
                                      newsTypeToString(NewsType.authorNews)) {
                                //interstitial ads
                                UiUtils.showInterstitialAds(context: context);
                                List<NewsModel> newsList = [];
                                newsList.addAll(model.newsType ==
                                        newsTypeToString(NewsType.authorNews)
                                    ? (model.authorNews ?? [])
                                    : (model.news ?? []));
                                newsList.removeAt(index);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsDetails, arguments: {
                                  "model": data,
                                  "newsList": newsList,
                                  "isFromBreak": false,
                                  "fromShowMore": false
                                });
                              }
                            },
                          ),
                        ],
                      );
                    })),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
