import 'package:audioplayers/audioplayers.dart';
import 'package:demixr_app/models/unmixed_song.dart';

import '../constants.dart';

class StemsPlayer {
  Map<Stems, AudioPlayer> players = {};

  StemsPlayer() {
    players = {
      Stems.vocals: AudioPlayer(),
      Stems.drums: AudioPlayer(),
      Stems.bass: AudioPlayer(),
      Stems.other: AudioPlayer(),
    };
  }

  AudioPlayer get aPlayer => players[Stems.vocals]!;

  Stream<Duration> get onAudioPositionChanged => aPlayer.onAudioPositionChanged;

  Future<int> getDuration() => aPlayer.getDuration();

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
}
