import 'package:audioplayers/audioplayers.dart';
import 'package:demixr_app/models/unmixed_song.dart';

import '../constants.dart';

enum StemState { mute, unmute }

class StemsPlayer {
  /// Players, created lazily per stem and reused across songs so the
  /// position/completion streams stay stable. [setUrls] picks which ones are
  /// active for the current song.
  final Map<Stem, AudioPlayer> players = {};

  /// The stems present in the current song (excludes the mixture).
  List<Stem> activeStems = const [];
  Map<Stem, StemState> stemStates = {};
  bool mixtureOn = false;
  int duration = 0;

  /// All stems play simultaneously, so the players must NOT request exclusive
  /// audio focus (the default) — otherwise each one steals focus from the
  /// others and they all get paused. `none` on Android and `mixWithOthers` on
  /// iOS let the players mix together.
  static final AudioContext _audioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  StemsPlayer() {
    _player(Stem.mixture).mute();
  }

  /// Returns the [AudioPlayer] for [stem], creating and configuring it on
  /// first use. Lazy creation keeps the player robust to the set of stems a
  /// song actually has (4 or 6) without pre-allocating every possible player.
  AudioPlayer _player(Stem stem) => players.putIfAbsent(
    stem,
    () => AudioPlayer()..setAudioContext(_audioContext),
  );

  AudioPlayer get aPlayer => _player(Stem.vocals);

  Stream<Duration> get onAudioPositionChanged => aPlayer.onPositionChanged;

  Stream<void> get onPlayerCompletion => aPlayer.onPlayerStateChanged.where(
    (state) => state == PlayerState.completed,
  );

  StemState getStemState(Stem stem) => stemStates[stem] ?? StemState.mute;

  /// The players in use for the current song: the active stems plus mixture.
  Iterable<AudioPlayer> get _activePlayers =>
      [Stem.mixture, ...activeStems].map(_player);

  bool get allStemsUnmute {
    return activeStems.every((stem) => getStemState(stem) == StemState.unmute);
  }

  void setUrls(UnmixedSong song) {
    activeStems = song.stems;
    stemStates = {for (final stem in activeStems) stem: StemState.unmute};
    mixtureOn = false;

    _player(Stem.mixture)
      ..setSource(DeviceFileSource(song.mixture))
      ..mute();
    for (final stem in activeStems) {
      _player(stem)
        ..setSource(DeviceFileSource(song.getStem(stem)))
        ..unMute();
    }

    // Preserve the historical default of starting with vocals muted.
    toggleStem(Stem.vocals);
  }

  void pause() {
    for (final player in _activePlayers) {
      player.pause();
    }
  }

  void resume() {
    for (final player in _activePlayers) {
      player.resume();
    }
  }

  void stop() {
    for (final player in _activePlayers) {
      player.stop();
    }
  }

  void seek(Duration position) {
    for (final player in _activePlayers) {
      player.seek(position);
    }
  }

  void muteAll() {
    for (final stem in activeStems) {
      _player(stem).mute();
    }
  }

  void unmuteAll() {
    for (final stem in activeStems) {
      _player(stem).unMute();
    }
  }

  void toggleStem(Stem stem) {
    if (mixtureOn) {
      mixtureOn = false;
      unmuteAll();
      players[Stem.mixture]?.mute();
    }

    final state = getStemState(stem);
    players[stem]?.muteToggle(state);

    stemStates[stem] = state.toggle();

    if (allStemsUnmute) {
      mixtureOn = true;
      muteAll();
      players[Stem.mixture]?.unMute();
    }
  }
}

extension StemStateToggle on StemState {
  StemState toggle() {
    return this == StemState.mute ? StemState.unmute : StemState.mute;
  }
}

extension AudioPlayerMute on AudioPlayer {
  void mute() {
    setVolume(0);
  }

  void unMute() {
    setVolume(1);
  }

  void muteToggle(StemState currentState) {
    currentState == StemState.mute ? unMute() : mute();
  }
}
