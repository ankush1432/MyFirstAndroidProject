import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/homepage/cubits/section_by_id_cubit.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/homepage/models/feature_section_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/features/rss_feed/models/rss_feed_model.dart';
import 'package:starke_app/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:starke_app/features/homepage/widgets/common_section_title.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:url_launcher/url_launcher.dart';

class Style6Section extends StatefulWidget {
  final FeatureSectionModel model;

  const Style6Section({super.key, required this.model});

  @override
  Style6SectionState createState() => Style6SectionState();
}

class Style6SectionState extends State<Style6Section> {
  int? style6Sel;
  bool isNews = true;
  late final ScrollController style6ScrollController = ScrollController()
    ..addListener(hasMoreSectionScrollListener);

  @override
  void initState() {
    super.initState();
    getSectionDataById();
  }

  @override
  void dispose() {
    style6ScrollController.removeListener(() {});
    super.dispose();
  }

  void hasMoreSectionScrollListener() {
    if (style6ScrollController.position.maxScrollExtent ==
        style6ScrollController.offset) {
      if (context.read<SectionByIdCubit>().hasMoreSections() &&
          !(context.read<SectionByIdCubit>().state
              is SectionByIdFetchInProgress)) {
        //print("style 6 : more section news to be fetched & state is ${context.read<SectionByIdCubit>().state}");
        context.read<SectionByIdCubit>().getMoreSectionById(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            sectionId: widget.model.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return style6Data();
  }

  void getSectionDataById() {
    Future.delayed(Duration.zero, () {
      context.read<SectionByIdCubit>().getSectionById(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          sectionId: widget.model.id!,
          latitude: SettingsLocalDataRepository().getLocationCityValues().first,
          longitude:
              SettingsLocalDataRepository().getLocationCityValues().last);
    });
  }

  Widget style6Data() {
    return BlocBuilder<SectionByIdCubit, SectionByIdState>(
        builder: (context, state) {
      //print(" state $state");
      if (state is SectionByIdFetchSuccess) {
        final bool isRssFeedsNews =
            state.type == newsTypeToString(NewsType.rssFeedsNews);

        if (!isRssFeedsNews) {
          isNews = (state.type == newsTypeToString(NewsType.news) ||
                      state.type == newsTypeToString(NewsType.userChoice) ||
                      state.type == newsTypeToString(NewsType.authorNews) ||
                      state.type == newsTypeToString(NewsType.videos)) &&
                  state.newsModel.isNotEmpty
              ? true
              : (state.type == newsTypeToString(NewsType.breakingNews) ||
                          state.type == newsTypeToString(NewsType.videos)) &&
                      state.breakNewsModel.isNotEmpty
                  ? false
                  : isNews;
        }

        final int totalCount = isRssFeedsNews
            ? state.rssFeedModel.length
            : (isNews ? state.newsModel.length : state.breakNewsModel.length);

        final bool hasContent = isRssFeedsNews
            ? state.rssFeedModel.isNotEmpty
            : (state.breakNewsModel.isNotEmpty || state.newsModel.isNotEmpty);

        return hasContent
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  commonSectionTitle(state.featuredSectionModel, context),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: style6NewsDetails(
                          newsData: state.newsModel,
                          brNewsData: state.breakNewsModel,
                          rssFeedData: state.rssFeedModel,
                          isRssFeedsNews: isRssFeedsNews,
                          total: totalCount,
                          type: state.type)),
                ],
              )
            : SizedBox.shrink();
      }
      return SizedBox.shrink();
    });
  }

  Widget style6NewsDetails(
      {List<NewsModel>? newsData,
      List<BreakingNewsModel>? brNewsData,
      List<RSSFeedModel>? rssFeedData,
      bool isRssFeedsNews = false,
      String? type,
      int total = 0}) {
    return SizedBox(
        height: MediaQuery.of(context).size.height / 2.8,
        child: SingleChildScrollView(
            controller: style6ScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
                children: List.generate(total, (index) {
              return SizedBox(
                  width: MediaQuery.of(context).size.width / 1.9,
                  child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: isRssFeedsNews
                          ? setImageCard(
                              index: index,
                              total: total,
                              type: type!,
                              rssFeedModel: rssFeedData![index])
                          : (isNews)
                              ? setImageCard(
                                  index: index,
                                  total: total,
                                  type: type!,
                                  newsModel: newsData![index],
                                  allNewsList: newsData)
                              : setImageCard(
                                  index: index,
                                  total: total,
                                  type: type!,
                                  breakingNewsModel: brNewsData![index],
                                  breakingNewsList: brNewsData)));
            }))));
  }

  Widget setImageCard(
      {required int index,
      required int total,
      required String type,
      NewsModel? newsModel,
      BreakingNewsModel? breakingNewsModel,
      RSSFeedModel? rssFeedModel,
      List<NewsModel>? allNewsList,
      List<BreakingNewsModel>? breakingNewsList}) {
    return InkWell(
      child: Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      darkSecondaryColor.withOpacity(0.9)
                    ]).createShader(bounds);
              },
              blendMode: BlendMode.darken,
              child: Container(
                color: primaryColor.withValues(alpha: 0.15),
                width: MediaQuery.of(context).size.width / 1.9,
                height: MediaQuery.of(context).size.height / 2.5,
                child: CustomNetworkImage(
                    networkImageUrl: rssFeedModel != null
                        ? (rssFeedModel.image ?? "")
                        : (newsModel != null)
                            ? newsModel.image!
                            : breakingNewsModel!.image!,
                    height: MediaQuery.of(context).size.height / 2.5,
                    width: MediaQuery.of(context).size.width / 1.9,
                    fit: BoxFit.cover,
                    isVideo: type == newsTypeToString(NewsType.videos)),
              ),
            )),
        (newsModel != null &&
                newsModel.categoryName != null &&
                newsModel.categoryName!.trim().isNotEmpty)
            ? Align(
                alignment: Alignment.topLeft,
                child: Container(
                    margin:
                        const EdgeInsetsDirectional.only(start: 7.0, top: 7.0),
                    height: 20.0,
                    padding: const EdgeInsetsDirectional.only(
                        start: 6.0, end: 6.0, top: 2.5),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Theme.of(context).primaryColor),
                    child: CustomTextLabel(
                        text: newsModel.categoryName!,
                        textAlign: TextAlign.center,
                        textStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: secondaryColor),
                        overflow: TextOverflow.ellipsis,
                        softWrap: true)))
            : (rssFeedModel != null &&
                    rssFeedModel.categoryName != null &&
                    rssFeedModel.categoryName!.trim().isNotEmpty)
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                        margin: const EdgeInsetsDirectional.only(
                            start: 7.0, top: 7.0),
                        height: 20.0,
                        padding: const EdgeInsetsDirectional.only(
                            start: 6.0, end: 6.0, top: 2.5),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Theme.of(context).primaryColor),
                        child: CustomTextLabel(
                            text: rssFeedModel.categoryName!,
                            textAlign: TextAlign.center,
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: secondaryColor),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true)))
                : const SizedBox.shrink(),
        (type == newsTypeToString(NewsType.videos))
            ? Positioned.directional(
                textDirection: Directionality.of(context),
                top: MediaQuery.of(context).size.height * 0.13,
                start: MediaQuery.of(context).size.width / 6,
                end: MediaQuery.of(context).size.width / 6,
                child: UiUtils.setPlayButton(context: context))
            : const SizedBox.shrink(),
        Positioned.directional(
          textDirection: Directionality.of(context),
          bottom: 5,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            (rssFeedModel != null &&
                    rssFeedModel.pubDateHuman != null &&
                    rssFeedModel.pubDateHuman!.trim().isNotEmpty)
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: CustomTextLabel(
                        text: rssFeedModel.pubDateHuman!,
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelSmall!
                            .copyWith(color: Colors.white)))
                : (newsModel != null)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: CustomTextLabel(
                            text: UiUtils.convertToAgo(
                                context,
                                DateTime.parse(
                                    newsModel.publishDate ?? newsModel.date!),
                                3)!,
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: Colors.white)))
                    : const SizedBox.shrink(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                width: MediaQuery.of(context).size.width * 0.50,
                child: CustomTextLabel(
                    text: rssFeedModel != null
                        ? (rssFeedModel.feedName ?? "")
                        : (newsModel != null)
                            ? newsModel.title!
                            : breakingNewsModel!.title!,
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(color: secondaryColor),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis))
          ]),
        ),
      ]),
      onTap: () async {
        if (type == newsTypeToString(NewsType.rssFeedsNews) &&
            rssFeedModel != null &&
            rssFeedModel.feedUrl != null &&
            rssFeedModel.feedUrl!.isNotEmpty) {
          final uri = Uri.tryParse(rssFeedModel.feedUrl!);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          }
          return;
        }

        if (type == newsTypeToString(NewsType.videos)) {
          List<NewsModel> newsList = [];
          List<BreakingNewsModel> brNewsList = [];
          if (newsModel != null &&
              allNewsList != null &&
              allNewsList.isNotEmpty) {
            newsList = List.from(allNewsList);
            newsList.removeAt(index);
          } else if (breakingNewsModel != null &&
              breakingNewsList != null &&
              breakingNewsList.isNotEmpty) {
            brNewsList = List.from(breakingNewsList);
            brNewsList.removeAt(index);
          }
          Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
            "from": (newsModel != null) ? 1 : 3,
            if (newsModel != null) "model": newsModel,
            if (breakingNewsModel != null) "breakModel": breakingNewsModel,
            "otherBreakingVideos": brNewsList,
            "otherVideos": newsList,
          });
        } else if (type == newsTypeToString(NewsType.news) ||
            type == newsTypeToString(NewsType.userChoice) ||
            type == newsTypeToString(NewsType.authorNews)) {
          //interstitial ads
          UiUtils.showInterstitialAds(context: context);
          if (allNewsList != null && allNewsList.isNotEmpty) {
            List<NewsModel> newsList = List.from(allNewsList);
            newsList.removeAt(index);
            Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
              "model": newsModel,
              "newsList": newsList,
              "isFromBreak": false,
              "fromShowMore": false
            });
          }
        } else {
          if (breakingNewsList != null && breakingNewsList.isNotEmpty) {
            //interstitial ads
            UiUtils.showInterstitialAds(context: context);
            List<BreakingNewsModel> breakList = List.from(breakingNewsList);
            breakList.removeAt(index);
            Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
              "breakModel": breakingNewsModel,
              "breakNewsList": breakList,
              "isFromBreak": true,
              "fromShowMore": false
            });
          }
        }
      },
    );
  }
}
