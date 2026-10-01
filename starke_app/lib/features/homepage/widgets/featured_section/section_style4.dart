import 'dart:math';

import 'package:flutter/material.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/homepage/models/feature_section_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/features/rss_feed/models/rss_feed_model.dart';
import 'package:starke_app/features/homepage/widgets/common_section_title.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/core/configs/app_config.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class Style4Section extends StatelessWidget {
  final FeatureSectionModel model;

  const Style4Section({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return style4Data(model, context);
  }

  Widget style4Data(FeatureSectionModel model, BuildContext context) {
    int limit = limitOfAllOtherStyle;
    int newsLength = (model.newsType == newsTypeToString(NewsType.news) ||
            model.newsType == newsTypeToString(NewsType.userChoice))
        ? model.news!.length
        : (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
            ? model.rssFeedNews!.length
            : (model.newsType == newsTypeToString(NewsType.authorNews))
                ? (model.authorNews?.length ?? 0)
                : model.videos!.length;
    int brNewsLength = model.newsType == newsTypeToString(NewsType.breakingNews)
        ? model.breakNews!.length
        : model.breakVideos!.length;
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
                  model.newsType == newsTypeToString(NewsType.userChoice) ||
                  model.newsType == newsTypeToString(NewsType.authorNews) ||
                  model.newsType == newsTypeToString(NewsType.rssFeedsNews))
              ? (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
                  ? model.rssFeedNews!.isNotEmpty
                  : (model.newsType == newsTypeToString(NewsType.authorNews))
                      ? model.authorNews?.isNotEmpty == true
                      : model.news!.isNotEmpty
              : model.videos!.isNotEmpty)
            Column(
              children: [
                setGridLayout(
                    context: context,
                    totalCount: min(newsLength, limit),
                    childWidget: (context, index) {
                      bool isRssFeedsNews = model.newsType ==
                          newsTypeToString(NewsType.rssFeedsNews);
                      NewsModel data =
                          (model.newsType == newsTypeToString(NewsType.news) ||
                                  model.newsType ==
                                      newsTypeToString(NewsType.userChoice))
                              ? model.news![index]
                              : ((isRssFeedsNews)
                                  ? NewsModel()
                                  : (model.newsType ==
                                          newsTypeToString(NewsType.authorNews))
                                      ? (model.authorNews ?? [])[index]
                                      : model.videos![index]);
                      final RSSFeedModel rssData = (model.newsType ==
                              newsTypeToString(NewsType.rssFeedsNews))
                          ? (model.rssFeedNews?[index] ?? RSSFeedModel())
                          : RSSFeedModel();
                      return InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: UiUtils.getColorScheme(context).surface),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(children: [
                                setNewsImage(
                                    context: context,
                                    imageURL: (isRssFeedsNews)
                                        ? (rssData.image ?? "")
                                        : (data.image ?? "")),
                                if (!isRssFeedsNews &&
                                    data.categoryName != null &&
                                    data.categoryName!.trim().isNotEmpty)
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                        margin:
                                            const EdgeInsetsDirectional.only(
                                                start: 7.0, top: 7.0),
                                        height: 18.0,
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                start: 6.0, end: 6.0, top: 2.5),
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
                                                ?.copyWith(
                                                    color: secondaryColor),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true)),
                                  ),
                                if (model.newsType ==
                                        newsTypeToString(NewsType.videos) ||
                                    model.videosType ==
                                        newsTypeToString(NewsType.videos))
                                  Positioned.directional(
                                    textDirection: Directionality.of(context),
                                    top: MediaQuery.of(context).size.height *
                                        0.065,
                                    start:
                                        MediaQuery.of(context).size.width / 6,
                                    end: MediaQuery.of(context).size.width / 6,
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
                              ]),
                              Padding(
                                  padding: const EdgeInsets.only(top: 9.0),
                                  child: CustomTextLabel(
                                      text: isRssFeedsNews
                                          ? rssData.feedName ?? ""
                                          : data.title ?? "",
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              color: UiUtils.getColorScheme(
                                                      context)
                                                  .primaryContainer),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)),
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
                            //show interstitial ads
                            UiUtils.showInterstitialAds(context: context);
                            List<NewsModel> newsList = [];
                            newsList.addAll(model.newsType ==
                                    newsTypeToString(NewsType.authorNews)
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
                    }),
              ],
            ),
          if ((model.newsType == newsTypeToString(NewsType.breakingNews) ||
                  model.videosType ==
                      newsTypeToString(NewsType.breakingNews)) &&
              (model.newsType == newsTypeToString(NewsType.breakingNews)
                  ? model.breakNews!.isNotEmpty
                  : model.breakVideos!.isNotEmpty))
            setGridLayout(
                context: context,
                totalCount: min(brNewsLength, limit),
                childWidget: (context, index) {
                  BreakingNewsModel data =
                      model.newsType == newsTypeToString(NewsType.breakingNews)
                          ? model.breakNews![index]
                          : model.breakVideos![index];
                  return InkWell(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: UiUtils.getColorScheme(context).surface),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(children: [
                            setNewsImage(
                                context: context, imageURL: data.image!),
                            if (model.newsType ==
                                    newsTypeToString(NewsType.videos) ||
                                model.videosType ==
                                    newsTypeToString(NewsType.videos))
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                top: MediaQuery.of(context).size.height * 0.065,
                                start: MediaQuery.of(context).size.width / 6,
                                end: MediaQuery.of(context).size.width / 6,
                                child: InkWell(
                                    onTap: () {
                                      List<BreakingNewsModel> brNewsList =
                                          List.from(model.breakVideos ?? [])
                                            ..removeAt(index);
                                      Navigator.of(context).pushNamed(
                                          Routes.newsVideo,
                                          arguments: {
                                            "from": 3,
                                            "breakModel": data,
                                            "otherBreakingVideos": brNewsList
                                          });
                                    },
                                    child: UiUtils.setPlayButton(
                                        context: context)),
                              ),
                          ]),
                          Padding(
                              padding: const EdgeInsets.only(top: 9.0),
                              child: CustomTextLabel(
                                  text: data.title!,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer),
                                  softWrap: true,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis)),
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
                  );
                })
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // A fixed-height grid (mainAxisExtent) made every card taller than its
  // content, so short titles left an empty coloured gap below the text
  // (most visible when the section has only a couple of items). This builds the
  // 2-column grid manually so each card hugs its content, while both cards in a
  // row stay equal height (IntrinsicHeight) and aligned.
  Widget setGridLayout(
      {required BuildContext context,
      required int totalCount,
      required Widget? Function(BuildContext, int) childWidget}) {
    const int crossAxisCount = 2;
    const double crossAxisSpacing = 16;
    const double mainAxisSpacing = 16;
    final int rowCount = (totalCount / crossAxisCount).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: EdgeInsets.only(top: rowIndex == 0 ? 0 : mainAxisSpacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(crossAxisCount, (colIndex) {
                final int itemIndex = rowIndex * crossAxisCount + colIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                        end: colIndex == crossAxisCount - 1
                            ? 0
                            : crossAxisSpacing),
                    child: itemIndex < totalCount
                        ? childWidget(context, itemIndex)
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget setNewsImage(
      {required BuildContext context, required String imageURL}) {
    // Width the image is actually drawn at in the 2-column grid:
    // screen width - the section's 15+15 horizontal padding
    //             - the 16px gap between the two columns, split in half
    //             - the card's 8px inner padding on each side.
    final double imageWidth =
        (MediaQuery.of(context).size.width - 30 - 16) / 2 - 16;
    // Figma's grid card image is 155 x 142, so lock that ratio and let the
    // height follow the width. (The previous height = screen-height * 0.175
    // ignored the card's width, so the card's proportions drifted per device
    // and never matched the design.)
    final double imageHeight = imageWidth * (142 / 155);
    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomNetworkImage(
            networkImageUrl: imageURL,
            height: imageHeight,
            width: imageWidth,
            fit: BoxFit.cover,
            isVideo: model.newsType == newsTypeToString(NewsType.videos)
                ? true
                : false));
  }
}
