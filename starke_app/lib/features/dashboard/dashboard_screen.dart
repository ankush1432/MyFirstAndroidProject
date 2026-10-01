import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/snackbar_widget.dart';
import 'package:starke_app/features/app_open_ads/app_open_ad_manager.dart';
import 'package:starke_app/features/authentication/cubits/auth_cubit.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/features/homepage/screens/homepage.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:starke_app/commons/cubits/news_by_id_cubit.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/commons/cubits/theme_cubit.dart';
import 'package:starke_app/features/podcast/screens/widgets/podcast_mini_player.dart';
import 'package:starke_app/features/profile/profile_screen.dart';
import 'package:starke_app/features/reels/screens/reels_screen.dart';
import 'package:starke_app/features/rss_feed/screens/rssfeed_screen.dart';
import 'package:starke_app/features/videos/screens/video_screen.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/core/routes/routes.dart';

GlobalKey<HomeScreenState>? homeScreenKey;
GlobalKey<ReelsScreenState>? reelsScreenKey;
bool? isNotificationReceivedInbg, isShared;
String? notificationNewsId;
String? saleNotification;
String? routeSettingsName, newsSlug;
bool isReelsDeepLink = false;
bool pendingReelsQueueLoad = false;
String? pendingDashboardTab;

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  DashBoardState createState() => DashBoardState();

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const DashBoard());
  }
}

class DashBoardState extends State<DashBoard> {
  List<Widget> fragments = [];
  DateTime? currentBackPressTime;
  int _selectedIndex = 0;
  int _reelsIndex = -1;
  List<String> iconList = [];
  List<String> itemName = [];
  bool shouldPopScope = false;

  late final AppOpenAdManager _appOpenAdManager;

  @override
  void initState() {
    homeScreenKey = GlobalKey<HomeScreenState>();
    reelsScreenKey = GlobalKey<ReelsScreenState>();
    iconList = [
      "home",
      "video",
      //Add only if Reels Mode is enabled From Admin panel.
      if (context.read<AppConfigurationCubit>().getReelsMode() == "1") "reels",
      if (context.read<AppConfigurationCubit>().getRSSFeedMode() == "1") "rss",
      "profile",
    ];
    itemName = [
      'homeLbl',
      'videosLbl',
      if (context.read<AppConfigurationCubit>().getReelsMode() == "1")
        'reelsLbl',
      if (context.read<AppConfigurationCubit>().getRSSFeedMode() == "1")
        'rssFeed',
      'profile'
    ];
    fragments = [
      HomeScreen(key: homeScreenKey),
      const VideoScreen(),
      //Add only if Reels Mode is enabled From Admin panel.
      if (context.read<AppConfigurationCubit>().getReelsMode() == "1")
        ReelsScreen(key: reelsScreenKey),
      //const CategoryScreen(),
      if (context.read<AppConfigurationCubit>().getRSSFeedMode() == "1")
        RSSFeedScreen(),
      const ProfileScreen(),
    ];
    _reelsIndex = fragments.indexWhere((w) => w is ReelsScreen);
    if (pendingDashboardTab == 'reels' && _reelsIndex != -1) {
      _selectedIndex = _reelsIndex;
      pendingDashboardTab = null;
    }
    checkForPengingNotifications();
    checkMaintenanceMode();

    _appOpenAdManager = AppOpenAdManager()..loadAd(context);
    AppLifecycleReactor(
      appOpenAdManager: _appOpenAdManager,
      context: context,
    ).listenToAppStateChanges();

    super.initState();
  }

  void checkMaintenanceMode() {
    if (context.read<AppConfigurationCubit>().getMaintenanceMode() == "1") {
      //app is in maintenance mode - no function should be performed
      Navigator.of(context).pushReplacementNamed(Routes.maintenance);
    }
  }

  void checkForPengingNotifications() async {
    if (isNotificationReceivedInbg != null &&
        notificationNewsId != null &&
        notificationNewsId != "0" &&
        isNotificationReceivedInbg!) {
      context
          .read<NewsByIdCubit>()
          .getNewsById(
              newsId: notificationNewsId!,
              langCode: context.read<AppLocalizationCubit>().state.languageCode)
          .then((value) {
        if (value.isNotEmpty) {
          Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
            "model": value[0],
            "isFromBreak": false,
            "fromShowMore": false
          });
        }
      });
    }
  }

  void openReelsTab() {
    if (_reelsIndex != -1) {
      setState(() => _selectedIndex = _reelsIndex);
    }
  }

  void changeTab(int index) {
    if (index >= 0 && index < fragments.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// Returns the fragments list with the Reels tab replaced by an empty
  /// placeholder whenever it isn't the active tab. Swapping the widget at
  /// the reels index causes [IndexedStack] to dispose the previous
  /// [ReelsScreen] (and its [VideoPlayContainer]) so playback fully stops
  /// on tab change, then re-mounts when the user returns to the tab.
  List<Widget> _buildActiveFragments() {
    if (_reelsIndex == -1 || _selectedIndex == _reelsIndex) {
      return fragments;
    }
    final active = List<Widget>.from(fragments);
    active[_reelsIndex] = const SizedBox.shrink();
    return active;
  }

  /// Handles Android system back / iOS back gesture for all dashboard tabs.
  void _onDashboardPopInvoked(bool didPop) {
    if (didPop) return;

    if (_selectedIndex == _reelsIndex && _reelsIndex != -1) {
      final handled = reelsScreenKey?.currentState?.handleBackPress() ?? false;
      if (handled) return;
    }

    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        shouldPopScope = false;
      });
      return;
    }

    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      showSnackBar(UiUtils.getTranslatedLabel(context, 'exitWR'), context);
      setState(() => shouldPopScope = false);
      return;
    }

    setState(() => shouldPopScope = true);
  }

  Widget buildNavBarItem(String icon, String itemName, int index) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _selectedIndex = index);
        },
        child: Container(
          height: 60,
          width: MediaQuery.of(context).size.width / iconList.length,
          decoration: index == _selectedIndex
              ? BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          width: 3, color: Theme.of(context).primaryColor)))
              : null,
          child: Column(
            children: [
              SizedBox(height: 3),
              SvgPictureWidget(
                  height: 25,
                  width: 25,
                  fit: BoxFit.contain,
                  assetName: icon,
                  assetColor: ColorFilter.mode(
                      index == _selectedIndex
                          ? Theme.of(context).primaryColor
                          : UiUtils.getColorScheme(context)
                              .outline
                              .withOpacity(0.5),
                      BlendMode.srcIn)),
              SizedBox(height: 2.5),
              CustomTextLabel(
                  text: itemName,
                  softWrap: true,
                  textStyle: TextStyle(
                      color: (index == _selectedIndex)
                          ? Theme.of(context).primaryColor
                          : UiUtils.getColorScheme(context).outline,
                      fontSize: 12))
            ],
          ),
        ),
      ),
    );
  }

  bottomBar() {
    List<Widget> navBarItemList = [];
    for (var i = 0; i < iconList.length; i++) {
      navBarItemList.add(buildNavBarItem(iconList[i], itemName[i], i));
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        //UiUtils.getColorScheme(context).secondary,
        boxShadow: [
          // Keep the shadow entirely ABOVE the bar (offset.dy <= -blurRadius) so
          // it only lifts the bar off the content above and does not bleed a
          // faint line down onto the system navigation-bar strip below, which is
          // the same colour as this bar.
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, -6),
            blurRadius: 6,
          ),
        ],
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
      ),

      // padding: EdgeInsets.only(bottom: bottomInset > 0 ? 6 : 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: navBarItemList),
      ),
    );
  }

  SystemUiOverlayStyle dashboardOverlayStyle() {
    final navBarColor = Theme.of(context).colorScheme.surface;
    final iconBrightness =
        ThemeData.estimateBrightnessForColor(navBarColor) == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
    final appTheme = context.read<ThemeCubit>().state.appTheme;

    return UiUtils.overlayStyleForTheme(appTheme).copyWith(
      systemNavigationBarColor: navBarColor,
      systemNavigationBarDividerColor: navBarColor,
      systemNavigationBarIconBrightness: iconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  void dispose() {
    PodcastMiniPlayer.setSuppressed(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Reels tab runs immersive (it hides the system navigation bar), so the
    // podcast mini player stands down while it is the active tab rather than
    // floating over the video.
    PodcastMiniPlayer.setSuppressed(
        _reelsIndex != -1 && _selectedIndex == _reelsIndex);
    // final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardBottom =
        MediaQueryData.fromView(View.of(context)).viewInsets.bottom;
    final keyboardOpen = keyboardBottom > 0;
    return PopScope(
      canPop: shouldPopScope,
      onPopInvoked: _onDashboardPopInvoked,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Future.delayed(Duration.zero, () {
              context.read<BookmarkCubit>().getBookmark(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode);
              context.read<LikeAndDisLikeCubit>().getLike(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode);
            });
          }
        },
        builder: (context, state) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: dashboardOverlayStyle(),
            child: Scaffold(
              extendBody: true,
              extendBodyBehindAppBar: true,
              // backgroundColor: UiUtils.getColorScheme(context).secondary,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottomNavigationBar: keyboardOpen
                  ? null
                  : SafeArea(top: false, bottom: false, child: bottomBar()),
              // Keep the loaded tab content mounted at all times. Losing the
              // internet connection no longer wipes the whole dashboard — the
              // already-loaded data stays visible. Only an actual failed API
              // call (refresh, pagination, or opening a not-yet-loaded screen)
              // surfaces a "No Internet" error, and only on that screen/action.
              body: IndexedStack(
                index: _selectedIndex,
                children: _buildActiveFragments(),
              ),
            ),
          );
        },
      ),
    );
  }
}
