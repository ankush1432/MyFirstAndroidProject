import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart' as loc;
import 'package:marqueer/marqueer.dart';
import 'package:starke_app/commons/widgets/ad_spaces.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/error_container_widget.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/commons/widgets/snackbar_widget.dart';
import 'package:starke_app/core/constants/hive_box_keys.dart';
import 'package:starke_app/core/deep_link/reels_native_deep_link.dart';
import 'package:starke_app/core/deep_link/share_deep_link.dart';
import 'package:starke_app/core/error_handler/error_message_keys.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/features/authentication/cubits/auth_cubit.dart';
import 'package:starke_app/features/authentication/cubits/register_token_cubit.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:starke_app/features/dashboard/dashboard_screen.dart';
import 'package:starke_app/features/homepage/widgets/featured_section/section_style1.dart';
import 'package:starke_app/features/homepage/widgets/featured_section/section_style2.dart';
import 'package:starke_app/features/homepage/widgets/featured_section/section_style3.dart';
import 'package:starke_app/features/homepage/widgets/featured_section/section_style4.dart';
import 'package:starke_app/features/homepage/widgets/featured_section/section_style5.dart';
import 'package:starke_app/features/homepage/widgets/featured_section/section_style6.dart';
import 'package:starke_app/features/homepage/widgets/general_news_random_style.dart';
import 'package:starke_app/features/homepage/widgets/live_with_search_view.dart';
import 'package:starke_app/features/homepage/widgets/section_shimmer.dart';
import 'package:starke_app/features/homepage/widgets/weather_data.dart';
import 'package:starke_app/features/alerts/cubits/alerts_cubit.dart';
import 'package:starke_app/features/alerts/widgets/alerts_view.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:starke_app/commons/cubits/adspace/adspace_home_page_cubit.dart';
import 'package:starke_app/features/category/cubits/category_cubit.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/features/news/cubits/breaking_news_cubit.dart';
import 'package:starke_app/features/homepage/cubits/feature_section_cubit.dart';
import 'package:starke_app/features/homepage/cubits/general_news_cubit.dart';
import 'package:starke_app/commons/cubits/get_user_data_by_id_cubit.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/language/cubits/language_json_cubit.dart';
import 'package:starke_app/features/live_streaming/cubits/live_stream_cubit.dart';
import 'package:starke_app/features/dynamic_pages/cubits/other_pages_cubit.dart';
import 'package:starke_app/features/homepage/cubits/section_by_id_cubit.dart';
import 'package:starke_app/features/news/cubits/short_news_cubit.dart';
import 'package:starke_app/features/notification/screens/push_notification_service.dart';
import 'package:starke_app/features/profile/widgets/custom_alert_dialog.dart';
import 'package:starke_app/features/reels/cubits/video_shorts_cubit.dart';
import 'package:starke_app/commons/cubits/setting_cubit.dart';
import 'package:starke_app/features/homepage/cubits/weather_cubit.dart';
import 'package:starke_app/features/author/models/author_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/features/category/models/category_model.dart';
import 'package:starke_app/features/homepage/repositories/section_by_id/section_by_id_repository.dart';
import 'package:starke_app/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:starke_app/core/constants/strings.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/features/authentication/models/auth_model.dart';
import 'package:starke_app/features/homepage/models/feature_section_model.dart';
import 'package:starke_app/features/podcast/cubits/podcast_cubit.dart';
import 'package:starke_app/features/podcast/screens/channel_detail_screen.dart';
import 'package:starke_app/features/podcast/screens/widgets/podcast_card.dart';
import 'package:starke_app/features/podcast/screens/widgets/podcast_home_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  /// Clears the dashboard bottom bar (~60) + system inset + margin; matches scroll content bottom padding.
  static double _homeBottomNavClearance = (Platform.isIOS) ? 100 : 80.0;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late final ScrollController featuredSectionsScrollController =
      ScrollController()..addListener(hasMoreFeaturedSectionsScrollListener);

  final loc.Location _location = loc.Location();
  bool? _serviceEnabled;
  loc.PermissionStatus? _permissionGranted;
  double? lat;
  double? lon;
  bool updateList = false;
  Set<String> get locationValue =>
      SettingsLocalDataRepository().getLocationCityValues();
  late final appConfig, authConfig;
  String languageId = "14"; //set it as default language code
  String languageCode = "en"; //set it as default language code

  void getSections() {
    Future.delayed(Duration.zero, () {
      context.read<SectionCubit>().getSection(
          langCode: languageCode,
          latitude: locationValue.first,
          longitude: locationValue.last);
    }).whenComplete(() => getGeneralNews());
  }

  void getLiveStreamData() {
    Future.delayed(Duration.zero, () {
      context.read<LiveStreamCubit>().getLiveStream(langCode: languageCode);
    });
  }

  void getCategories() {
    Future.delayed(Duration.zero, () {
      context.read<CategoryCubit>().loadIfFailed(langCode: languageCode);
    });
  }

  void getPodcasts() {
    // Only fetch when the module is enabled from the Admin panel.
    if (context.read<AppConfigurationCubit>().getPodcastMode() != "1") return;
    Future.delayed(Duration.zero, () {
      context.read<PodcastCubit>().getPodcasts();
    });
  }

  void getMarketAlerts() {
    // No Admin-panel flag gates this one (get_settings carries no market-alert
    // mode), so it is always fetched — an empty response hides the section.
    Future.delayed(Duration.zero, () {
      context.read<AlertsCubit>().getMarketAlerts();
    });
  }

  void getBookmark() {
    Future.delayed(Duration.zero, () {
      context.read<BookmarkCubit>().getBookmark(langCode: languageCode);
    });
  }

  void getLikeNews() {
    Future.delayed(Duration.zero, () {
      context.read<LikeAndDisLikeCubit>().getLike(langCode: languageCode);
    });
  }

  void getUserData() {
    Future.delayed(Duration.zero, () {
      context.read<GetUserByIdCubit>().getUserById();
    });
  }

  checkForAppUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.read<AppConfigurationCubit>().state
          is AppConfigurationFetchSuccess) {
        if (context.read<AppConfigurationCubit>().isUpdateRequired()) {
          openUpdateDialog();
        }
      }
    });
  }

  openUpdateDialog() {
    bool isForceUpdate =
        (context.read<AppConfigurationCubit>().getForceUpdateMode() != "" &&
                context.read<AppConfigurationCubit>().getForceUpdateMode() ==
                    "1")
            ? true
            : false;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return PopScope(
              canPop: false,
              child: CustomAlertDialog(
                  isForceAppUpdate: (isForceUpdate) ? true : false,
                  context: context,
                  yesButtonText: 'yesLbl',
                  yesButtonTextPostfix: '',
                  noButtonText: (isForceUpdate) ? 'exitLbl' : 'noLbl',
                  imageName: '',
                  titleWidget: CustomTextLabel(
                      text: (isForceUpdate)
                          ? 'forceUpdateTitleLbl'
                          : 'newVersionAvailableTitleLbl',
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: UiUtils.getColorScheme(context)
                                  .primaryContainer)),
                  messageText: context
                      .read<LanguageJsonCubit>()
                      .getTranslatedLabels((isForceUpdate)
                          ? 'forceUpdateDescLbl'
                          : 'newVersionAvailableDescLbl'),
                  onYESButtonPressed: () => UiUtils.gotoStores(context)),
            );
          });
        });
  }

  showPermissionPopup() async {
    loc.LocationData locationData;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled!) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      SettingsLocalDataRepository().setLocationCityKeys(null, null);
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    locationData = await _location.getLocation();

    setState(() {
      lat = locationData.latitude;
      lon = locationData.longitude;
    });
    getLocationPermission();

    return (locationData);
  }

  getLocationPermission() async {
    if (appConfig.getLocationWiseNewsMode() == "1") {
      SettingsLocalDataRepository().setLocationCityKeys(lat, lon);
      //update latitude,longitude - along with token
      if (context.read<SettingsCubit>().getSettings().token != '') {
        context.read<RegisterTokenCubit>().registerToken(
            fcmId: context.read<SettingsCubit>().getSettings().token,
            context: context);
        context
            .read<SettingsCubit>()
            .changeFcmToken(context.read<SettingsCubit>().getSettings().token);
      }
    } else {
      SettingsLocalDataRepository().setLocationCityKeys(null, null);
    }

    if (appConfig.getWeatherMode() == "1") {
      getWeatherData();
    }
  }

  Future<void> getWeatherData() async {
    if (lat != null && lon != null) {
      context.read<WeatherCubit>().getWeatherDetails(
          langId: (Hive.box(settingsBoxKey).get(currentLanguageCodeKey)),
          lat: lat.toString(),
          lon: lon.toString());
    }
  }

  void getBreakingNews() {
    Future.delayed(Duration.zero, () {
      context.read<BreakingNewsCubit>().getBreakingNews(langCode: languageCode);
    });
  }

  void getGeneralNews() {
    context.read<GeneralNewsCubit>().getGeneralNews(
        langCode: languageCode,
        latitude: locationValue.first,
        longitude: locationValue.last);
  }

  @override
  void initState() {
    super.initState();

    final pushNotificationService = PushNotificationService(context: context);
    pushNotificationService.initialise();

    appConfig = context.read<AppConfigurationCubit>();
    authConfig = context.read<AuthCubit>();
    languageId = context.read<AppLocalizationCubit>().state.id;
    languageCode = context.read<AppLocalizationCubit>().state.languageCode;
    getSections();
    getShortNews();
    getVideoShorts();
    if (appConfig.getWeatherMode() == "1" ||
        appConfig.getLocationWiseNewsMode() == "1") showPermissionPopup();
    if (authConfig.getUserId() != "0") {
      getUserData();
    }
    getLiveStreamData();
    getCategories();
    getPodcasts();
    getMarketAlerts();
    if (appConfig.getBreakingNewsMode() == "1") getBreakingNews();
    if (appConfig.getMaintenanceMode() == "1")
      Navigator.of(context).pushReplacementNamed(Routes.maintenance);
    getAdSpaceForHomePage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingShareDeepLink();
    });
  }

  Future<void> _handlePendingShareDeepLink() async {
    if (isShared != true || routeSettingsName == null) return;

    final path = routeSettingsName!.contains('/reels')
        ? ShareDeepLink.resolveRouteName(routeSettingsName!)
        : routeSettingsName!;
    final slug = (newsSlug != null && newsSlug!.trim().isNotEmpty)
        ? newsSlug!.trim()
        : (ShareDeepLink.parseSlug(path) ??
            ShareDeepLink.parseSlug(ReelsNativeDeepLink.cachedFullUrl ?? '') ??
            '');

    if (slug.isEmpty && path.contains('/reels')) {
      isShared = false;
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await ShareDeepLinkHandler.handle(
      context,
      path: path,
      slug: slug,
      onOpenReelsTab: ShareDeepLinkHandler.openReelsTabOnDashboard,
    );
    isShared = false;
  }

  @override
  void dispose() {
    featuredSectionsScrollController.dispose();
    super.dispose();
  }

  void getAdSpaceForHomePage() {
    Future.delayed(Duration.zero, () {
      context.read<AdSpaceHomePageCubit>().getAdspaceForHomePage(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          page: "home_page");
    });
  }

  void hasMoreFeaturedSectionsScrollListener() {
    if (featuredSectionsScrollController.position.atEdge) {
      //(featuredSectionsScrollController.offset >= featuredSectionsScrollController.position.maxScrollExtent && !featuredSectionsScrollController.position.outOfRange) {
      if (context.read<SectionCubit>().hasMoreSections()) {
        context.read<SectionCubit>().getMoreSections(
            langCode: languageCode,
            latitude: locationValue.first,
            longitude: locationValue.last);
      } else {
        //debugPrint("No more Featured sections to show");
      }
    }
  }

  Widget breakingNewsMarquee() {
    return BlocBuilder<BreakingNewsCubit, BreakingNewsState>(
        builder: ((context, state) {
      return (state is BreakingNewsFetchSuccess &&
              state.breakingNews.isNotEmpty)
          ? Container(
              margin: const EdgeInsets.only(top: 10),
              color: darkSecondaryColor,
              height: 32,
              child: Marqueer.builder(
                pps: 25.0,
                restartAfterInteractionDuration: const Duration(seconds: 1),
                separatorBuilder: (_, index) => Center(
                    child: Text(' ● ',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.normal))),
                itemBuilder: (context, index) {
                  var multiplier = index ~/ state.breakingNews.length;
                  var i = index;
                  if (multiplier > 0) {
                    i = index - (multiplier * state.breakingNews.length);
                  }
                  final item = state.breakingNews[i];
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: CustomTextLabel(
                          text: item.title!,
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color: secondaryColor,
                                  fontWeight: FontWeight.normal)));
                },
              ),
            )
          : const SizedBox.shrink();
    }));
  }

  Widget getSectionList() {
    return BlocBuilder<GeneralNewsCubit, GeneralNewsState>(
        builder: (context, newsState) {
      return BlocBuilder<SectionCubit, SectionState>(
          builder: (context, sectionState) {
        if (sectionState is SectionFetchSuccess) {
          //if it has only one section and it doesn't have news in it  then show No data found message
          if (sectionState.section.length == 1) {
            final section = sectionState.section.first;

            final bool hasNoData = (section.newsType ==
                        newsTypeToString(NewsType.breakingNews) &&
                    section.breakNewsTotal == 0) ||
                ((section.newsType == newsTypeToString(NewsType.news) ||
                        section.newsType ==
                            newsTypeToString(NewsType.userChoice) ||
                        section.newsType ==
                            newsTypeToString(NewsType.videos)) &&
                    (section.newsTotal ?? -1) == 0) ||
                (section.newsType == newsTypeToString(NewsType.authorNews) &&
                    (section.authorNewsTotal ?? -1) == 0) ||
                (section.newsType == newsTypeToString(NewsType.rssFeedsNews) &&
                    (section.rssFeedTotal ?? -1) == 0);

            if (hasNoData) {
              return ErrorContainerWidget(
                errorMsg: ErrorMessageKeys.noDataMessage,
                onRetry: _refresh,
              );
            }
          }

          return ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              // 16px gap between feed sections.
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: ((context, index) {
                FeatureSectionModel model = sectionState.section[index];
                //check for more featured sections
                if (index == sectionState.section.length - 1 && index != 0) {
                  if (sectionState.hasMore) {
                    if (sectionState.hasMoreFetchError) {
                      return const SizedBox.shrink();
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

                return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionData(model: model),
                      if (index == 0) ...[
                        _buildCategorySection(),
                        _buildPodcastSection(),
                      ],
                    ]);
              }),
              itemCount: sectionState.section.length);
        }
        if (sectionState is SectionFetchFailure) {
          if (context.read<GeneralNewsCubit>().state
              is GeneralNewsFetchSuccess) {
            return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionData(
                      newsModelList: (context.read<GeneralNewsCubit>().state
                              as GeneralNewsFetchSuccess)
                          .generalNews),
                  _buildCategorySection(),
                  _buildPodcastSection(),
                ]);
          } else {
            return ErrorContainerWidget(
                errorMsg: (sectionState.errorMessage
                        .contains(ErrorMessageKeys.noInternet))
                    ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                    : sectionState.errorMessage,
                onRetry: _refresh);
          }
        }
        return sectionShimmer(
            context); //state is SectionFetchInProgress || state is SectionInitial
      });
    });
  }

  Widget _buildCategorySection() {
    if (appConfig.getCategoryMode() != "1") {
      return const SizedBox.shrink();
    }

    return BlocBuilder<CategoryCubit, CategoryState>(builder: (context, state) {
      if (state is CategoryFetchFailure) {
        return ErrorContainerWidget(
            errorMsg: (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                : state.errorMessage,
            onRetry: getCategories);
      }

      if (state is! CategoryFetchSuccess) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: UiUtils.showCircularProgress(
              true, Theme.of(context).primaryColor),
        );
      }

      if (state.category.isEmpty) {
        return const SizedBox.shrink();
      }

      // 16px gap above the Categories block; the ListView.separated below
      // supplies the 16px gap to the next section, so no bottom padding here.
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextLabel(
                    text: 'categoryLbl',
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer,
                            fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(Routes.category);
                  },
                  child: CustomTextLabel(
                      text: 'viewMore',
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                              color: UiUtils.getColorScheme(context).outline)),
                )
              ],
            ),
            // 12px header -> content gap, matching commonSectionTitle.
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      state.category.length > 10 ? 10 : state.category.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final CategoryModel category = state.category[index];
                    return _buildCategoryCard(category);
                  }),
            ),
          ],
        ),
      );
    });
  }

  /// Podcast module entry point, gated on `podcast_mode` from the Admin panel.
  /// This is the only way into the module, so hiding it here disables Podcast
  /// app-wide.
  ///
  /// PLACEMENT: directly under the Categories block of the first feed section
  /// (Figma 3131:7778) — not at the end of the feed.
  ///
  /// "View More" opens Routes.podcastList -> PodcastDashboardScreen
  /// (All / History / Bookmark), which leads on to the channel detail and
  /// player screens. See lib/features/podcast/.
  Widget _buildPodcastSection() {
    if (appConfig.getPodcastMode() != "1") {
      return const SizedBox.shrink();
    }

    return BlocBuilder<PodcastCubit, PodcastState>(
      builder: (context, state) {
        // While loading, hold the space with the same sectionShimmer the feed
        // sections use, so the section loads in place instead of popping into
        // the layout. A failure stays silent — the section is simply absent.
        if (state is PodcastInitial || state is PodcastFetchInProgress) {
          return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: sectionShimmer(context));
        }
        if (state is! PodcastFetchSuccess || state.podcasts.isEmpty) {
          return const SizedBox.shrink();
        }
        final cards = state.podcasts.map((p) => p.toCardData()).toList();
        // Home shows only the first two (Figma 3131:7778); the rest live
        // behind "View More".
        final homeCards = cards.take(2).toList();
        // 16px gap above, same as the Categories block; the enclosing
        // ListView.separated supplies the gap down to the next section.
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: PodcastHomeSection(
              title: 'Podcast',
              podcasts: homeCards,
              onViewMoreTap: () => Navigator.of(context).pushNamed(
                  Routes.podcastList,
                  arguments: {"podcasts": cards}),
              onPodcastTap: _openPodcastChannel),
        );
      },
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(Routes.subCat, arguments: {
          "catId": category.id,
          "catName": category.categoryName
        });
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
            color: UiUtils.getColorScheme(context).surface,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: CustomNetworkImage(
                        networkImageUrl: category.image ?? "",
                        fit: BoxFit.cover,
                        isVideo: false),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: CustomTextLabel(
                  text: category.categoryName ?? "",
                  textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionData(
      {FeatureSectionModel? model, List<NewsModel>? newsModelList}) {
    return (model != null)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (model.adSpaceDetails != null) ...[
                AdSpaces(adsModel: model.adSpaceDetails!), //sponsored ads
                // 16px gap between the sponsored block and the section content.
                const SizedBox(height: 16),
              ],
              if (model.styleApp == 'style_1') Style1Section(model: model),
              if (model.styleApp == 'style_2') Style2Section(model: model),
              if (model.styleApp == 'style_3') Style3Section(model: model),
              if (model.styleApp == 'style_4') Style4Section(model: model),
              if (model.styleApp == 'style_5') Style5Section(model: model),
              if (model.styleApp == 'style_6')
                BlocProvider(
                    create: (context) =>
                        SectionByIdCubit(SectionByIdRepository()),
                    child: Style6Section(model: model)),
            ],
          )
        : GeneralNewsRandomStyle(modelList: newsModelList!);
  }

  //refresh function to refresh page
  Future<void> _refresh() async {
    getSections();
    getLocationPermission();
    if (authConfig.getUserId() != "0") {
      getUserData();
      getBookmark();
      getLikeNews();
    }
    getLiveStreamData();
    getCategories();
    getPodcasts();
    getMarketAlerts();
    getPages();
    getShortNews();
    getVideoShorts();
    if (appConfig.getBreakingNewsMode() == "1") getBreakingNews();
    if (appConfig.getMaintenanceMode() == "1")
      Navigator.of(context).pushReplacementNamed(Routes.maintenance);
    if (appConfig.getWeatherMode() == "1") getWeatherData();
    getAdSpaceForHomePage();
  }

  getPages() {
    Future.delayed(Duration.zero, () {
      context.read<OtherPageCubit>().getOtherPage(
          langCode: languageCode,
          defaultLangCode:
              context.read<AppConfigurationCubit>().getDefaultLanguageCode());
    });
  }

  getShortNews() {
    Future.delayed(Duration.zero, () {
      context.read<ShortNewsCubit>().fetchShortNews(langCode: languageCode);
    });
  }

  getVideoShorts() {
    Future.delayed(Duration.zero, () {
      if (isReelsDeepLink || pendingReelsQueueLoad) return;
      //Reels are disabled from the Admin panel - nothing consumes the queue.
      if (context.read<AppConfigurationCubit>().getReelsMode() != "1") return;
      context.read<VideoShortsCubit>().getVideoShorts(langCode: languageCode);
    });
  }

  /// Opens the tapped podcast's channel detail screen (also reachable from the
  /// dashboard "All" tab). The channel screen fetches its own episodes by slug.
  void _openPodcastChannel(PodcastCardData card) {
    Navigator.of(context).pushNamed(Routes.podcastChannelDetail, arguments: {
      "channel": ChannelDetailData(
        id: card.id,
        slug: card.slug,
        imageUrl: card.imageUrl,
        tag: '',
        title: card.title,
        description: card.description ?? '',
        listenersCount: card.listenersCount,
        episodesCount: card.episodesCount,
        authorName: card.authorName,
        authorImageUrl: card.authorImageUrl,
        isFollowed: card.isFollowed,
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom + 60
            // _homeBottomNavClearance,
            ),
        child: BlocBuilder<ShortNewsCubit, ShortNewsState>(
            builder: (context, state) {
          return FloatingActionButton(
              backgroundColor: primaryColor,
              elevation: 10,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: secondaryColor, width: 2),
                borderRadius: BorderRadius.circular(100), // Makes it circular
              ),
              onPressed: state is ShortNewsFetchInProgress
                  ? null
                  : () {
                      //check cubit statehere
                      if (state is ShortNewsFetchSuccess) {
                        print(
                            "ShortNewsFetchSuccess: ${state.shortNews.length}");
                        if (state.shortNews.isNotEmpty) {
                          List<NewsModel> newsList = List.from(state.shortNews);
                          newsList.removeAt(0);
                          Navigator.of(context)
                              .pushNamed(Routes.newsDetails, arguments: {
                            "model": state.shortNews[0],
                            "newsList": newsList,
                            "isFromBreak": false,
                            "fromShowMore": false,
                            "fromShortNews": true
                          });
                        }
                        print(
                            "ShortNewsFetchSuccess: ${state.shortNews.length}");
                      } else if (state is ShortNewsFetchFailure) {
                        showSnackBar(state.errorMessage, context);
                      }
                    },
              child: state is ShortNewsFetchInProgress
                  ? SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : SvgPictureWidget(
                      assetName: "short_news",
                      assetColor:
                          ColorFilter.mode(secondaryColor, BlendMode.srcIn))
              //Icon(Icons.feed_rounded, color: secondaryColor),
              );
        }),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _refresh(),
        child: BlocListener<GetUserByIdCubit, GetUserByIdState>(
          bloc: context.read<GetUserByIdCubit>(),
          listener: (context, state) {
            if (state is GetUserByIdFetchSuccess) {
              var data = state.result;
              if (data[STATUS] == 0) {
                showSnackBar(UiUtils.getTranslatedLabel(context, 'deactiveMsg'),
                    context);
                Future.delayed(const Duration(seconds: 2), () {
                  UiUtils.userLogOut(contxt: context);
                });
              } else {
                authConfig.updateDetails(
                    authModel: AuthModel(
                        id: data[ID].toString(),
                        name: data[NAME],
                        status: data[STATUS].toString(),
                        mobile: data[MOBILE],
                        email: data[EMAIL],
                        type: data[TYPE],
                        profile: data[PROFILE],
                        // role: data[ROLE].toString(),
                        jwtToken: data[TOKEN],
                        isAuthor: data[IS_AUTHOR],
                        authorDetails: (data.containsKey(AUTHOR) &&
                                // data[IS_AUTHOR] == 1 &&
                                data[AUTHOR] != null &&
                                data[AUTHOR] != "null" &&
                                data[AUTHOR] != "")
                            ? Author.fromJson(data[AUTHOR])
                            : null));
              }
            }
          },
          child: SingleChildScrollView(
            controller: featuredSectionsScrollController,
            physics: ClampingScrollPhysics(), //To restrict scrolling on Refresh
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 15.0, end: 15.0, top: 30),
                  child: Column(
                    children: [
                      const LiveWithSearchView(),
                      BlocBuilder<WeatherCubit, WeatherState>(
                          builder: (context, state) {
                        if (state is WeatherFetchSuccess) {
                          return WeatherDataView(
                              weatherData: state.weatherData);
                        }
                        return SizedBox.shrink();
                      }),
                      // Market alerts (get_market_alerts) shown directly below
                      // the Weather Forecast. There is no Admin-panel flag for
                      // this section — an empty list is what hides it. Only the
                      // first two fit the row; "View More" opens the full list
                      // (Routes.alertsList -> AlertsScreen), which reads the
                      // same already-fetched AlertsCubit list.
                      BlocBuilder<AlertsCubit, AlertsState>(
                          builder: (context, state) {
                        if (state is AlertsFetchSuccess &&
                            state.alerts.isNotEmpty) {
                          return AlertsView(
                              alerts: state.alerts.take(2).toList(),
                              onViewMore: () => Navigator.of(context)
                                  .pushNamed(Routes.alertsList));
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
                breakingNewsMarquee(),
                SizedBox(height: 15),
                Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 15.0,
                      end: 15.0,
                      bottom: MediaQuery.viewPaddingOf(context).bottom +
                          _homeBottomNavClearance,
                    ),
                    child: Column(
                      children: [
                        BlocBuilder<AdSpaceHomePageCubit, AdSpaceHomePageState>(
                          builder: (context, state) {
                            return (state is AdSpaceHomePageFetchSuccess &&
                                    state.adSpaceTopData != null)
                                // 16px gap below the top ad to keep the same
                                // rhythm as the gap between feed sections.
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AdSpaces(adsModel: state.adSpaceTopData!),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                        // The Podcast section lives inside getSectionList(),
                        // under the Categories block of the first section —
                        // see _buildPodcastSection().
                        getSectionList(),
                        BlocBuilder<AdSpaceHomePageCubit, AdSpaceHomePageState>(
                          builder: (context, state) {
                            return (state is AdSpaceHomePageFetchSuccess &&
                                    state.adSpaceBottomData != null)
                                // 16px gap above the bottom ad to keep the same
                                // rhythm as the gap between feed sections.
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      AdSpaces(
                                          adsModel: state.adSpaceBottomData!),
                                    ],
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
