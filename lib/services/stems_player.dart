import 'package:audioplayers/audioplayers.dart';
import 'package:demixr_app/models/unmixed_song.dart';

import '../constants.dart';

enum StemState {
  mute,
  unmute,
}

extension StemStateToggle on StemState {
  StemState toggle() {
    return this == StemState.mute ? StemState.unmute : StemState.mute;
  }
}

class StemsPlayer {
  Map<Stem, AudioPlayer> players = {};
  Map<Stem, StemState> stemStates = {};

  StemsPlayer() {
    players = {
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

    toggleStem(Stem.vocals);
  }

  AudioPlayer get aPlayer => players[Stem.vocals]!;

  Stream<Duration> get onAudioPositionChanged => aPlayer.onAudioPositionChanged;

  Future<int> getDuration() => aPlayer.getDuration();

  StemState getStemState(Stem stem) => stemStates[stem] ?? StemState.mute;

  void setUrls(UnmixedSong song) {
    players.forEach((stem, player) =>
        player.setUrl(song.getStem(stem).path, isLocal: true));
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

  void toggleStem(Stem stem) {
    final state = getStemState(stem);
    players[stem]?.setVolume(state == StemState.mute ? 1 : 0);
    stemStates[stem] = state.toggle();
  }
}
