import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/core/app.dart';
import 'package:starke_app/core/configs/app_config.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/interstitial_ads/google_interstitial_ads.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/news_subdetails_screen.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/reward_ads/google_reward_ads.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/reward_ads/unity_reward_ads.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/core/error_handler/internet_connectivity.dart';
// import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsModel? model;
  final List<NewsModel>? newsList;
  final BreakingNewsModel? breakModel;
  final List<BreakingNewsModel>? breakNewsList;
  final bool isFromBreak;
  final bool fromShowMore;
  final String? slug;
  final bool? fromShortNews;

  const NewsDetailScreen(
      {super.key,
      this.model,
      this.breakModel,
      this.breakNewsList,
      this.newsList,
      this.slug,
      required this.isFromBreak,
      required this.fromShowMore,
      this.fromShortNews});

  @override
  NewsDetailsState createState() => NewsDetailsState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => NewsDetailScreen(
            model: arguments['model'],
            breakModel: arguments['breakModel'],
            breakNewsList: arguments['breakNewsList'],
            newsList: arguments['newsList'],
            isFromBreak: arguments['isFromBreak'],
            fromShowMore: arguments['fromShowMore'],
            slug: arguments['slug'],
            fromShortNews: arguments['fromShortNews'] ?? false));
  }
}

class NewsDetailsState extends State<NewsDetailScreen> {
  final PageController pageController = PageController();

  bool isScrollLocked = false;

  void _setScrollLock(bool lock) {
    setState(() {
      isScrollLocked = lock;
    });
  }

  @override
  void initState() {
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1") {
      if (context.read<AppConfigurationCubit>().checkAdsType() == "google") {
        createGoogleInterstitialAd(context);
        createGoogleRewardedAd(context);
      } else {
        if (context.read<AppConfigurationCubit>().unityGameId() != null) {
          // UnityAds.init(
          //   gameId: context.read<AppConfigurationCubit>().unityGameId()!,
          //   testMode: true, //set it to False @Deployement
          //   onComplete: () {
          //     loadUnityInterAd(
          //         context.read<AppConfigurationCubit>().interstitialId()!);
          //     loadUnityRewardAd(
          //         context.read<AppConfigurationCubit>().rewardId()!);
          //   },
          //   onFailed: (error, message) =>
          //       debugPrint('Initialization Failed: $error $message'),
          // );
        }
      }
    }

    super.initState();

    if (widget.model != null) {
      firebaseAnalytics.logEvent(
        name: 'news_opened',
        parameters: {
          'news_id': widget.model?.newsId ?? '',
          'category': widget.model?.categoryId ?? '',
          'title': widget.model?.title ?? '',
        },
      );
      debugPrint(
          'FirebaseAnalytics: logged news_opened ${widget.model?.newsId}');
    }
    if (widget.breakModel != null) {
      firebaseAnalytics.logEvent(
        name: 'breaking_news_opened',
        parameters: {
          'breaking_news_id': widget.breakModel?.id ?? '',
          'category': '',
          'title': widget.breakModel?.title ?? '',
        },
      );
      debugPrint(
          'FirebaseAnalytics: logged breaking_news_opened ${widget.breakModel?.id}');
    }
  }

  Widget showBreakingNews() {
    return PageView.builder(
        controller: pageController,
        onPageChanged: (index) async {
          if (await InternetConnectivity.isNetworkAvailable()) {
            if (index % rewardAdsIndex == 0) showRewardAds();
            UiUtils.showInterstitialAds(context: context);
          }
        },
        itemCount:
            (widget.breakNewsList == null || widget.breakNewsList!.isEmpty)
                ? 1
                : widget.breakNewsList!.length + 1,
        itemBuilder: (context, index) {
          return NewsSubDetails(
              onLockScroll:
                  (p0) {}, //no change for breaking news , No comments widget
              breakModel: (index == 0)
                  ? widget.breakModel
                  : widget.breakNewsList![index - 1],
              fromShowMore: widget.fromShowMore,
              isFromBreak: widget.isFromBreak,
              model: widget.model);
        });
  }

  void showRewardAds() {
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1") {
      if (context.read<AppConfigurationCubit>().checkAdsType() == "google") {
        showGoogleRewardedAd(context);
      } else {
        showUnityRewardAds(context.read<AppConfigurationCubit>().rewardId()!);
      }
    }
  }

  Widget showNews() {
    return PageView.builder(
        controller: pageController,
        physics: isScrollLocked
            ? NeverScrollableScrollPhysics()
            : AlwaysScrollableScrollPhysics(),
        onPageChanged: (index) async {
          if (await InternetConnectivity.isNetworkAvailable() &&
              widget.fromShortNews != true) {
            if (index % rewardAdsIndex == 0) showRewardAds();
            UiUtils.showInterstitialAds(context: context);
          }
        },
        itemCount: (widget.newsList == null || widget.newsList!.isEmpty)
            ? 1
            : widget.newsList!.length + 1,
        itemBuilder: (context, index) {
          return NewsSubDetails(
              onLockScroll: _setScrollLock,
              model: (index == 0) ? widget.model : widget.newsList![index - 1],
              fromShowMore: widget.fromShowMore,
              isFromBreak: widget.isFromBreak,
              breakModel: widget.breakModel,
              fromShortNews: widget.fromShortNews ?? false);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // FIGMA: news-details screen bg = Dark-bg (#061024) in dark, not the
        // Dark-card (#0E1B36). Keep the light surface untouched.
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? darkBackgroundColor
            : backgroundColor,
        body: widget.isFromBreak ? showBreakingNews() : showNews());
  }
}
