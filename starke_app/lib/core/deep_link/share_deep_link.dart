import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/news/cubits/breaking_news_cubit.dart';
import 'package:starke_app/features/language/cubits/language_cubit.dart';
import 'package:starke_app/features/news/cubits/slug_news_cubit.dart';
import 'package:starke_app/features/podcast/cubits/podcast_episodes_cubit.dart';
import 'package:starke_app/features/podcast/models/podcast_model.dart';
import 'package:starke_app/features/podcast/screens/channel_detail_screen.dart';
import 'package:starke_app/features/reels/cubits/video_shorts_cubit.dart';
import 'package:starke_app/features/videos/cubits/videos_cubit.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/core/constants/strings.dart'; 
import 'package:starke_app/core/deep_link/reels_native_deep_link.dart';
import 'package:starke_app/features/dashboard/dashboard_screen.dart';
import 'package:starke_app/utils/ui_utils.dart';

enum ShareDeepLinkType { videoNews, breakingNews, reels, news, podcast }

/// Share / deeplink URL helpers (see [Routes.onGenerateRouted]).
class ShareDeepLink {
  ShareDeepLink._();

  static Uri uriFrom(String routeName) {
    final trimmed = routeName.trim();
    if (trimmed.contains('://')) {
      return Uri.parse(trimmed);
    }
    if (trimmed.startsWith('/')) {
      return Uri.parse('https://app$trimmed');
    }
    if (trimmed.contains('/') || trimmed.contains('?')) {
      return Uri.parse('https://$trimmed');
    }
    return Uri.parse('https://app/$trimmed');
  }

  /// Reels use `?slug=`; other share links keep [routeName] unchanged.
  static String resolveRouteName(String routeName) {
    final trimmed = routeName.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!uriFrom(trimmed).path.contains('/reels')) return trimmed;
    return ReelsNativeDeepLink.resolveReelsRouteName(trimmed);
  }

  static String? _slugFromQueryString(String raw) {
    final match =
        RegExp(r'[?&]slug=([^&#]+)', caseSensitive: false).firstMatch(raw);
    if (match == null) return null;
    final slug = Uri.decodeComponent(match.group(1)!.trim());
    return slug.isNotEmpty ? slug : null;
  }

  static String? parseSlug(String routeName) {
    final uri = uriFrom(routeName);
    if (uri.path.contains('/reels')) {
      final slug = uri.queryParameters['slug']?.trim();
      if (slug != null && slug.isNotEmpty) return slug;
      final fromRaw = _slugFromQueryString(routeName);
      if (fromRaw != null) return fromRaw;
      final segments = uri.pathSegments;
      final reelsIdx = segments.indexOf('reels');
      if (reelsIdx != -1 && reelsIdx + 1 < segments.length) {
        final pathSlug = segments[reelsIdx + 1].trim();
        if (pathSlug.isNotEmpty) return pathSlug;
      }
      return null;
    }
    if (uri.pathSegments.isEmpty) return null;
    final slug = uri.pathSegments.last.trim();
    return slug.isNotEmpty ? slug : null;
  }

  static bool isShareDeepLink(String routeName) {
    final path = uriFrom(routeName).path;
    return path.contains('/reels') ||
        path.contains('/video-news/') ||
        path.contains('/breaking-news/') ||
        path.contains('/podcast/') ||
        path.contains('/news/');
  }

  /// Language code from `/en/news/...` → `en`.
  static String? langCodeFromPath(String path) {
    final segments = uriFrom(path).pathSegments;
    if (segments.isEmpty) return null;
    return segments.first;
  }

  static ShareDeepLinkType? typeFromPath(String path) {
    final uriPath = uriFrom(path).path;
    if (uriPath.contains('/reels')) return ShareDeepLinkType.reels;
    if (uriPath.contains('/video-news/')) return ShareDeepLinkType.videoNews;
    if (uriPath.contains('/breaking-news/'))
      return ShareDeepLinkType.breakingNews;
    // Ahead of the `/news/` check only for symmetry with the others — a podcast
    // path never contains it.
    if (uriPath.contains('/podcast/')) return ShareDeepLinkType.podcast;

    if (uriPath.contains('/news/')) return ShareDeepLinkType.news;
    return null;
  }

  /// Normalizes route names from the platform (full URL or path-only).
  static String normalizeRouteName(String routeName) {
    final uri = uriFrom(routeName);
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }
}

/// Navigates to the correct screen for a parsed share deeplink.
class ShareDeepLinkHandler {
  ShareDeepLinkHandler._();

  /// Returns `true` when navigation succeeded.
  static Future<bool> handle(
    BuildContext context, {
    required String path,
    required String slug,
    VoidCallback? onOpenReelsTab,
    ValueNotifier<bool>? loadingNotifier,
    bool usePopAndPushForNews = false,
  }) async {
    final linkType = ShareDeepLink.typeFromPath(path);
    if (linkType == null) return false;

    final langCode = ShareDeepLink.langCodeFromPath(path);
    if (langCode == null || langCode.isEmpty) return false;

    final nav = Navigator.of(context);
    final root = UiUtils.rootNavigatorKey.currentContext ?? context;

    switch (linkType) {
      case ShareDeepLinkType.videoNews:
        if (root.read<LanguageCubit>().langList().isEmpty) {
          _failLoading(loadingNotifier);
          return false;
        }
        try {
          final location =
              SettingsLocalDataRepository().getLocationCityValues();
          await root.read<VideoCubit>().getVideo(
                langCode: langCode,
                latitude: location.first,
                longitude: location.last,
                slug: slug,
              );
          final videoState = root.read<VideoCubit>().state;
          if (videoState is! VideoFetchSuccess || videoState.video.isEmpty) {
            _failLoading(loadingNotifier);
            return false;
          }
          final model = videoState.video.first;
          if (usePopAndPushForNews) {
            nav.popAndPushNamed(Routes.newsVideo,
                arguments: {"from": 1, "model": model});
          } else {
            nav.pushNamed(Routes.newsVideo,
                arguments: {"from": 1, "model": model});
          }
          return true;
        } catch (_) {
          _failLoading(loadingNotifier);
          return false;
        }

      case ShareDeepLinkType.breakingNews:
        try {
          final value = await root.read<BreakingNewsCubit>().getBreakingNews(
                langCode: root.read<AppLocalizationCubit>().state.languageCode,
              );
          final brModel = value.isNotEmpty ? value[0] : null;
          if (brModel == null) {
            _failLoading(loadingNotifier);
            return false;
          }
          if (usePopAndPushForNews) {
            nav.popAndPushNamed(Routes.newsDetails, arguments: {
              "breakModel": brModel,
              "slug": slug,
              "isFromBreak": true,
              "fromShowMore": false,
            });
          } else {
            nav.pushNamed(Routes.newsDetails, arguments: {
              "breakModel": brModel,
              "slug": slug,
              "isFromBreak": true,
              "fromShowMore": false,
            });
          }
          return true;
        } catch (_) {
          _failLoading(loadingNotifier);
          return false;
        }

      case ShareDeepLinkType.reels:
        //Reels are disabled from the Admin panel - drop the link and close the
        //loader instead of leaving the user on an endless loading screen.
        if (root.read<AppConfigurationCubit>().getReelsMode() != "1") {
          _failLoading(loadingNotifier);
          if (nav.canPop()) nav.pop();
          return false;
        }
        final reelSlug = slug.trim();
        if (reelSlug.isEmpty) {
          _failLoading(loadingNotifier);
          return false;
        }
        isReelsDeepLink = true;
        await root.read<VideoShortsCubit>().getVideoShorts(
              langCode: langCode,
              slug: reelSlug,
            );
        if (root.read<VideoShortsCubit>().state is! VideoShortsFetchSuccess) {
          _failLoading(loadingNotifier);
          return false;
        }
        pendingReelsQueueLoad = true;
        if (usePopAndPushForNews) {
          _completeLoading(loadingNotifier);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            openReelsTabOnDashboard();
          });
        } else {
          onOpenReelsTab?.call();
        }
        return true;

      case ShareDeepLinkType.news:
        if (root.read<LanguageCubit>().langList().isEmpty) {
          _failLoading(loadingNotifier);
          return false;
        }
        try {
          final value = await root.read<SlugNewsCubit>().getSlugNews(
                langCode: langCode,
                newsSlug: slug,
              );
          if (value[DATA][DATA] == null) {
            _failLoading(loadingNotifier);
            return false;
          }
          final model = (value[DATA][DATA] as List)
              .map((e) => NewsModel.fromJson(e))
              .toList()
              .first;
          final args = {
            "model": model,
            "slug": slug,
            "isFromBreak": false,
            "fromShowMore": false,
          };
          if (usePopAndPushForNews) {
            nav.popAndPushNamed(Routes.newsDetails, arguments: args);
          } else {
            nav.pushNamed(Routes.newsDetails, arguments: args);
          }
          return true;
        } catch (_) {
          _failLoading(loadingNotifier);
          return false;
        }

      case ShareDeepLinkType.podcast:
        // Only block when the app config has finished loading AND podcast mode
        // is disabled. If the config hasn't loaded yet (getPodcastMode returns
        // "" or null), we let the request through — the server rejects invalid
        // slugs anyway and news deep links apply the same "proceed regardless"
        // approach. Blocking here when the state isn't ready was the root cause
        // of podcast deep links silently failing on cold-start.
        final podcastMode = root.read<AppConfigurationCubit>().getPodcastMode();
        if (podcastMode != null && podcastMode.isNotEmpty && podcastMode != "1") {
          _failLoading(loadingNotifier);
          if (nav.canPop()) nav.pop();
          return false;
        }
        final podcastSlug = slug.trim();
        if (podcastSlug.isEmpty) {
          _failLoading(loadingNotifier);
          return false;
        }
        try {
          // `get_episode` answers with the channel itself alongside its
          // episodes, so this one call fills the whole header the channel
          // screen would otherwise have to fetch again.
          await root.read<PodcastEpisodesCubit>().getEpisodes(podcastSlug);
          final episodesState = root.read<PodcastEpisodesCubit>().state;
          // An unknown slug comes back as `data: null`, i.e. a success with no
          // channel attached - not a failure state.
          if (episodesState is! PodcastEpisodesSuccess ||
              episodesState.podcast == null) {
            _failLoading(loadingNotifier);
            return false;
          }
          final podcast = episodesState.podcast!;
          final args = {
            'channel': ChannelDetailData(
              id: podcast.id,
              slug: podcast.slug ?? podcastSlug,
              imageUrl: podcast.image ?? '',
              tag: '',
              title: podcast.title ?? '',
              description: podcast.description ?? '',
              listenersCount: PodcastModel.compactCount(podcast.followerCount),
              episodesCount: podcast.episodeCount.toString(),
              authorName: podcast.authorName ?? '',
              authorImageUrl: podcast.authorImage ?? '',
              isFollowed: podcast.isFollowed,
            ),
          };
          if (usePopAndPushForNews) {
            nav.popAndPushNamed(Routes.podcastChannelDetail, arguments: args);
          } else {
            nav.pushNamed(Routes.podcastChannelDetail, arguments: args);
          }
          return true;
        } catch (_) {
          _failLoading(loadingNotifier);
          return false;
        }
    }
  }

  /// Switches the existing dashboard to the reels tab (or defers until it mounts).
  static void openReelsTabOnDashboard() {
    final dash = homeScreenKey?.currentContext
        ?.findAncestorStateOfType<DashBoardState>();
    if (dash != null) {
      dash.openReelsTab();
      return;
    }
    pendingDashboardTab = 'reels';
  }

  static void _completeLoading(ValueNotifier<bool>? loadingNotifier) {
    if (loadingNotifier != null) loadingNotifier.value = false;
  }

  static void _failLoading(ValueNotifier<bool>? loadingNotifier) {
    _completeLoading(loadingNotifier);
  }
}
