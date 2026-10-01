import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/reels/cubits/video_shorts_cubit.dart';
import 'package:starke_app/features/dashboard/dashboard_screen.dart';
import 'package:starke_app/commons/widgets/error_container_widget.dart';
import 'package:starke_app/core/error_handler/error_message_keys.dart';
import 'package:starke_app/features/reels/widgets/reels_card.dart';
import 'package:starke_app/utils/system_ui_helper.dart';
import 'package:starke_app/utils/ui_utils.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => ReelsScreenState();
}

class ReelsScreenState extends State<ReelsScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  /// Page that currently owns a live player. It deliberately lags
  /// [_currentIndex]: onPageChanged fires halfway through a drag, and swapping
  /// players there tears down one video (a WebView, for YouTube reels) and
  /// builds another in the middle of the gesture, which drops frames right when
  /// the finger is still moving. Updating it on scroll-end keeps the outgoing
  /// reel playing for the whole swipe and mounts the next one once the page has
  /// settled.
  int _playerIndex = 0;
  bool _commentsOpen = false;
  bool _deeplinkQueueScheduled = false;
  int _commentsDismissToken = 0;

  static const double bottomNavHeight = 72;

  /// Returns true when back was consumed (e.g. comments panel was open).
  bool handleBackPress() {
    if (!_commentsOpen) return false;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      setState(() {
        _commentsOpen = false;
        _commentsDismissToken++;
      });
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchVideoShorts();
    if (pendingReelsQueueLoad) _scheduleReelsQueueLoad();
    // Keep the system navigation bar visible and theme-coloured on Reels too,
    // matching the rest of the app. The top status bar uses light icons because
    // the reel content behind it is dark. The nav bar colour is driven by the
    // dashboard's themed overlay style (see UiUtils.overlayStyleForTheme).
    SystemUiHelper.showNavBar();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _fetchVideoShorts({bool force = false}) {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      final cubit = context.read<VideoShortsCubit>();
      if (!force && cubit.state is VideoShortsFetchSuccess) return;
      if (isReelsDeepLink || pendingReelsQueueLoad) return;
      cubit.getVideoShorts(
        langCode: context.read<AppLocalizationCubit>().state.languageCode,
      );
    });
  }

  void _loadReelsQueueAfterDeeplink() {
    if (!pendingReelsQueueLoad || !mounted || _currentIndex != 0) return;
    pendingReelsQueueLoad = false;
    isReelsDeepLink = false;
    context.read<VideoShortsCubit>().loadVideoShortsQueue(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
        );
  }

  void _scheduleReelsQueueLoad() {
    if (!pendingReelsQueueLoad || _deeplinkQueueScheduled) return;
    _deeplinkQueueScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentIndex != 0) return;
      Future.delayed(
          const Duration(milliseconds: 800), _loadReelsQueueAfterDeeplink);
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _commentsOpen = false;
    });
    // Keep the nav bar visible while scrolling reels (flick shows both bars on
    // each reel's init; the dashboard overlay keeps it theme-coloured).
    SystemUiHelper.showNavBar();
    if (index == 0) _scheduleReelsQueueLoad();

    final cubit = context.read<VideoShortsCubit>();

    final state = cubit.state;
    if (state is VideoShortsFetchSuccess &&
        index >= state.videoShorts.length - 1) {
      cubit.loadNextBatch(
        context.read<AppLocalizationCubit>().state.languageCode,
      );
    }
  }

  /// Hands the settled page its player. Called on scroll-end so a fast
  /// multi-page flick only mounts one player, at the page it lands on.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollEndNotification && _playerIndex != _currentIndex) {
      setState(() => _playerIndex = _currentIndex);
    }
    return false;
  }

  Future<void> _refreshVideoShorts() async {
    if (!mounted) return;
    await context.read<VideoShortsCubit>().getVideoShorts(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Reset to the app's default visible/edge-to-edge nav-bar mode (flick may
    // have switched the Flutter SystemUiMode while playing).
    SystemUiHelper.showNavBar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<VideoShortsCubit, VideoShortsState>(
        builder: (context, state) {
          if (state is VideoShortsFetchInProgress ||
              state is VideoShortsInitial) {
            return Center(
              child: UiUtils.showCircularProgress(
                true,
                Theme.of(context).primaryColor,
              ),
            );
          }

          if (state is VideoShortsFetchFailure) {
            return ColoredBox(
              color: Colors.grey,
              child: ErrorContainerWidget(
                errorMsg:
                    state.errorMessage.contains(ErrorMessageKeys.noInternet)
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : state.errorMessage,
                onRetry: () => _fetchVideoShorts(force: true),
              ),
            );
          }

          if (state is VideoShortsFetchSuccess) {
            if (state.videoShorts.isEmpty) {
              return ColoredBox(
                color: Colors.amber,
                child: Center(
                  child: Text(
                    UiUtils.getTranslatedLabel(context, 'videosLbl'),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshVideoShorts,
              color: Theme.of(context).primaryColor,
              child: SafeArea(
                top: false,
                bottom: false,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    clipBehavior: Clip.hardEdge,
                    physics: _commentsOpen
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                    onPageChanged: _onPageChanged,
                    itemCount: state.videoShorts.length,
                    itemBuilder: (context, index) {
                      return ReelsCard(
                        model: state.videoShorts[index],
                        isActive: index == _currentIndex,
                        canPlay: index == _playerIndex,
                        dismissCommentsToken:
                            index == _currentIndex ? _commentsDismissToken : 0,
                        onCommentsVisibilityChanged: index == _currentIndex
                            ? (open) => setState(() => _commentsOpen = open)
                            : null,
                      );
                    },
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
