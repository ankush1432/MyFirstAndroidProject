// The audio engine: one app-wide `just_audio` player with lock-screen controls.
// Position ticks go through [positionDataStream], never through bloc state.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/features/podcast/models/playable_audio.dart';
import 'package:starke_app/features/podcast/repositories/podcast_repository.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PositionData {
  final Duration position;
  final Duration duration;

  const PositionData({
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
}

abstract class PodcastPlayerState {}

class PodcastPlayerInitial extends PodcastPlayerState {}

class PodcastPlayerLoading extends PodcastPlayerState {
  final PlayableAudio audio;
  PodcastPlayerLoading(this.audio);
}

class PodcastPlayerReady extends PodcastPlayerState {
  final PlayableAudio audio;
  final bool playing;
  final ProcessingState processingState;

  PodcastPlayerReady({
    required this.audio,
    required this.playing,
    required this.processingState,
  });
}

class PodcastPlayerFailure extends PodcastPlayerState {
  final PlayableAudio? audio;
  final String errorMessage;
  PodcastPlayerFailure({this.audio, required this.errorMessage});
}

class PodcastPlayerCubit extends Cubit<PodcastPlayerState> {
  final PodcastRepository _repository;
  final AudioPlayer _player = AudioPlayer();

  final YoutubeExplode _yt = YoutubeExplode();

  static const int _saveIntervalSeconds = 5;
  static const Duration _skipStep = Duration(seconds: 10);

  PlayableAudio? _current;

  List<PlayableAudio> _queue = const [];

  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final StreamController<PositionData> _positionDataController =
      StreamController<PositionData>.broadcast();

  final List<StreamSubscription> _subs = [];

  PodcastPlayerCubit(this._repository) : super(PodcastPlayerInitial()) {
    _bindPlayerStreams();
  }

  Stream<PositionData> get positionDataStream => _positionDataController.stream;

  PositionData get currentPositionData =>
      PositionData(position: _position, duration: _duration);

  PlayableAudio? get currentAudio => _current;

  bool isCurrent(PlayableAudio audio) {
    final current = _current;
    return current != null && _isSameAudio(audio, current);
  }

  static bool _isSameAudio(PlayableAudio a, PlayableAudio b) {
    if (a.id.isNotEmpty && b.id.isNotEmpty) return a.id == b.id;
    return a.url.isNotEmpty && a.url == b.url;
  }

  void setQueue(List<PlayableAudio> queue) =>
      _queue = List<PlayableAudio>.unmodifiable(queue);

  Future<void> play(PlayableAudio audio) async {
    try {
      // Claimed before the first await so no listener sees the outgoing episode.
      final resolved = _repository.resolvePlaybackSource(audio);
      _current = resolved;
      _resetPositionData();
      emit(PodcastPlayerLoading(resolved));

      await _repository.ensureNotificationPermission();

      final mediaItem = MediaItem(
        id: resolved.id.isEmpty ? resolved.playbackSource : resolved.id,
        title: resolved.title,
        artist: resolved.artist,
        album: resolved.album,
        artUri: (resolved.artUri != null && resolved.artUri!.isNotEmpty)
            ? Uri.tryParse(resolved.artUri!)
            : null,
      );

      final AudioSource source;
      if (resolved.hasLocalFile) {
        source = AudioSource.file(resolved.playbackSource, tag: mediaItem);
      } else if (resolved.isYoutubeSource) {
        final streamUrl = await _youtubeAudioStreamUrl(resolved.url);
        source = AudioSource.uri(Uri.parse(streamUrl), tag: mediaItem);
      } else {
        source = AudioSource.uri(
          Uri.parse(resolved.playbackSource),
          tag: mediaItem,
          headers: Api.headers,
        );
      }

      await _player.setAudioSource(source);

      final resumeMs = _repository.getResumePositionMs(resolved.id);
      if (resumeMs > 0) {
        await _player.seek(Duration(milliseconds: resumeMs));
      }

      await _player.play();
    } catch (e) {
      emit(PodcastPlayerFailure(audio: audio, errorMessage: e.toString()));
    }
  }

  Future<String> _youtubeAudioStreamUrl(String url) async {
    final manifest = await _yt.videos.streamsClient.getManifest(
      url,
      ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.ios],
    );
    final audio = manifest.audioOnly.withHighestBitrate();
    return audio.url.toString();
  }

  Future<void> togglePlayPause() => _player.playing ? pause() : _player.play();

  Future<void> pause() async {
    await _player.pause();
    _saveProgress(force: true);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipForward([Duration by = _skipStep]) {
    final target = _player.position + by;
    final max = _player.duration ?? target;
    return _player.seek(target > max ? max : target);
  }

  Future<void> skipBackward([Duration by = _skipStep]) {
    final target = _player.position - by;
    return _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> stop() async {
    _saveProgress(force: true);
    await _player.stop();
    _current = null;
    _queue = const [];
    _resetPositionData();
    emit(PodcastPlayerInitial());
  }

  void _bindPlayerStreams() {
    _subs.add(_player.playerStateStream.listen((_) => _emitReady()));

    _subs.add(_player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) _onEpisodeCompleted();
    }));

    _subs.add(_player.positionStream.listen((p) {
      _position = p;
      _pushPositionData();
      _saveProgress();
    }));
    _subs.add(_player.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      _pushPositionData();
    }));
  }

  void _onEpisodeCompleted() {
    _saveProgress(force: true);
    final next = _nextInQueue();
    if (next != null) play(next);
  }

  PlayableAudio? _nextInQueue() {
    final current = _current;
    if (current == null || _queue.isEmpty) return null;
    final index = _queue.indexWhere((audio) => _isSameAudio(audio, current));
    if (index < 0 || index + 1 >= _queue.length) return null;
    return _queue[index + 1];
  }

  void _emitReady() {
    final audio = _current;
    if (audio == null) return;
    emit(PodcastPlayerReady(
      audio: audio,
      playing: _player.playing,
      processingState: _player.processingState,
    ));
  }

  void _pushPositionData() {
    if (_positionDataController.isClosed) return;
    _positionDataController.add(PositionData(
      position: _position,
      duration: _duration,
    ));
  }

  void _resetPositionData() {
    _position = Duration.zero;
    _duration = Duration.zero;
    _pushPositionData();
  }

  void _saveProgress({bool force = false}) {
    final audio = _current;
    if (audio == null) return;
    final duration = _player.duration ?? Duration.zero;
    if (duration <= Duration.zero) return;

    final now = DateTime.now();
    if (!force && now.difference(_lastSave).inSeconds < _saveIntervalSeconds) {
      return;
    }
    _lastSave = now;

    _repository.saveProgress(
      audio: audio,
      positionMs: _player.position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      immediate: force,
    );
  }

  @override
  Future<void> close() async {
    _saveProgress(force: true);
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _positionDataController.close();
    await _player.dispose();
    _yt.close();
    return super.close();
  }
}
