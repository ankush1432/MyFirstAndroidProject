import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/features/reels/models/reel_model.dart';
import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/configs/app_config.dart';
import 'package:starke_app/core/constants/strings.dart';

abstract class VideoShortsState {}

class VideoShortsInitial extends VideoShortsState {}

class VideoShortsFetchInProgress extends VideoShortsState {}

class VideoShortsFetchSuccess extends VideoShortsState {
  final List<ReelModel> videoShorts;
  final int totalCount;

  VideoShortsFetchSuccess({
    required this.videoShorts,
    required this.totalCount,
  });
}

class VideoShortsFetchFailure extends VideoShortsState {
  final String errorMessage;

  VideoShortsFetchFailure(this.errorMessage);
}

class VideoShortsCubit extends Cubit<VideoShortsState> {
  VideoShortsCubit() : super(VideoShortsInitial());

  int _offset = 0;
  final int _limit = 10;

  bool _isLoading = false;
  int _totalCount = 0;

  final List<ReelModel> _videos = [];

  List<ReelModel> _parseVideoShortsList(dynamic raw) {
    if (raw == null) return [];

    List<dynamic> items = [];
    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map[DATA] is List) {
        items = map[DATA] as List;
      } else if (map[DATA] is Map) {
        final inner = Map<String, dynamic>.from(map[DATA]);
        if (inner[DATA] is List) {
          items = inner[DATA] as List;
        } else if (inner[NEWS] is List) {
          items = inner[NEWS] as List;
        }
      } else if (map[NEWS] is List) {
        items = map[NEWS] as List;
      }
    }

    return items
        .whereType<Map>()
        .map((e) => ReelModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  int _parseTotal(dynamic raw, int fallback) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map[TOTAL] != null) {
        return int.tryParse(map[TOTAL].toString()) ?? fallback;
      }
      if (map[DATA] is Map) {
        final inner = Map<String, dynamic>.from(map[DATA]);
        if (inner[TOTAL] != null) {
          return int.tryParse(inner[TOTAL].toString()) ?? fallback;
        }
      }
    }
    return fallback;
  }

  Future<void> getVideoShorts({
    required String langCode,
    String? slug,
    bool loadMore = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      if (!loadMore) {
        _offset = 0;
        _videos.clear();
        emit(VideoShortsFetchInProgress());
      }

      final body = <String, dynamic>{
        LANGUAGE_CODE: langCode,
        LIMIT: _limit.toString(),
        OFFSET: _offset.toString(),
      };

      if (slug != null && slug != 'null' && slug.trim().isNotEmpty) {
        body[SLUG] = slug.split('slug=').last.split('&').first;
      }

      final result = await Api.sendApiRequest(
        body: body,
        url: Api.getVideoShortsApi,
      );

      if (result[ERROR] == true) {
        emit(VideoShortsFetchFailure(result[MESSAGE]?.toString() ?? ""));
        return;
      }

      final newVideos = _parseVideoShortsList(result[DATA]);

      _totalCount = _parseTotal(result[DATA], newVideos.length);

      _videos.addAll(newVideos);

      _offset += newVideos.length;

      emit(
        VideoShortsFetchSuccess(
          videoShorts: List.from(_videos),
          totalCount: _totalCount,
        ),
      );
    } on ApiException catch (e) {
      emit(VideoShortsFetchFailure(e.errorMessage));
    } catch (e) {
      emit(VideoShortsFetchFailure(e.toString()));
    } finally {
      _isLoading = false;
    }
  }

  void loadNextBatch(String langCode, {String? slug}) {
    if (_offset >= _totalCount) {
      _offset = 0;
    }

    getVideoShorts(
      langCode: langCode,
      slug: slug,
      loadMore: true,
    );
  }

  /// Loads the default reels feed and appends items not already shown (e.g. after a slug deeplink).
  Future<void> loadVideoShortsQueue({required String langCode}) async {
    if (state is! VideoShortsFetchSuccess) return;

    final current = state as VideoShortsFetchSuccess;
    final existingIds =
        current.videoShorts.map((e) => e.id).whereType<String>().toSet();

    try {
      final body = <String, dynamic>{
        LANGUAGE_CODE: langCode,
        LIMIT: limitOfAPIData.toString(),
        // OFFSET: "0"
      };

      final result = await Api.sendApiRequest(
        body: body,
        url: Api.getVideoShortsApi,
      );

      if (result[ERROR] == true) return;

      final more = _parseVideoShortsList(result[DATA])
          .where((e) => e.id == null || !existingIds.contains(e.id))
          .toList();
      if (more.isEmpty) return;

      emit(VideoShortsFetchSuccess(
        videoShorts: [...current.videoShorts, ...more],
        totalCount: _parseTotal(
          result[DATA],
          current.videoShorts.length + more.length,
        ),
      ));
    } catch (_) {}
  }

  void updateVideoShortLike({
    required String videoShortsId,
    required bool isLiked,
  }) {
    if (state is! VideoShortsFetchSuccess) return;

    final current = state as VideoShortsFetchSuccess;
    for (final item in current.videoShorts) {
      if (item.id == videoShortsId) {
        item.isLiked = isLiked;
        if (isLiked) item.isDisliked = false;
        break;
      }
    }

    emit(VideoShortsFetchSuccess(
      videoShorts: current.videoShorts,
      totalCount: current.totalCount,
    ));
  }

  void updateVideoShortCommentsCount({
    required String videoShortsId,
    required int commentsCount,
  }) {
    if (state is! VideoShortsFetchSuccess) return;

    final current = state as VideoShortsFetchSuccess;
    for (final item in current.videoShorts) {
      if (item.id == videoShortsId) {
        item.commentsCount = commentsCount;
        break;
      }
    }

    emit(VideoShortsFetchSuccess(
      videoShorts: current.videoShorts,
      totalCount: current.totalCount,
    ));
  }
}
