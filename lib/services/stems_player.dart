import 'package:audioplayers/audioplayers.dart';
import 'package:demixr_app/models/unmixed_song.dart';

import '../constants.dart';

enum StemState { mute, unmute }

class StemsPlayer {
  Map<Stem, AudioPlayer> players = {};
  Map<Stem, StemState> stemStates = {};
  bool mixtureOn = false;
  int duration = 0;

  /// All stems play simultaneously, so the players must NOT request exclusive
  /// audio focus (the default) — otherwise each one steals focus from the
  /// others and they all get paused. `none` on Android and `mixWithOthers` on
  /// iOS let the 5 players mix together.
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
    players = {
      Stem.mixture: AudioPlayer()..mute(),
      Stem.vocals: AudioPlayer(),
      Stem.drums: AudioPlayer(),
      Stem.bass: AudioPlayer(),
      Stem.other: AudioPlayer(),
    };

    stemStates = {
      Stem.vocals: StemState.unmute,
      Stem.drums: StemState.unmute,
      Stem.bass: StemState.unmute,
      Stem.other: StemState.unmute,
    };

    for (final player in players.values) {
      player.setAudioContext(_audioContext);
    }

    toggleStem(Stem.vocals);
  }

  AudioPlayer get aPlayer => players[Stem.vocals]!;

  Stream<Duration> get onAudioPositionChanged => aPlayer.onPositionChanged;

  Stream<void> get onPlayerCompletion => aPlayer.onPlayerStateChanged.where(
    (state) => state == PlayerState.completed,
  );

  StemState getStemState(Stem stem) => stemStates[stem] ?? StemState.mute;

  bool get allStemsUnmute {
    return stemStates.values.every((element) => element == StemState.unmute);
  }

  void setUrls(UnmixedSong song) {
    players.forEach((stem, player) {
      player.setSource(DeviceFileSource(song.getStem(stem)));
    });
  }

  void pause() {
    players.forEach((stem, player) => player.pause());
  }

  void resume() {
    players.forEach((stem, player) => player.resume());
  }

  void stop() {
    players.forEach((stem, player) => player.stop());
  }

  void seek(Duration position) {
    players.forEach((stem, player) => player.seek(position));
  }

  void mute(AudioPlayer player) {}

  void muteAll() {
    players.forEach((stem, player) => player.mute());
  }

  void unmuteAll() {
    players.forEach((stem, player) => player.unMute());
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
