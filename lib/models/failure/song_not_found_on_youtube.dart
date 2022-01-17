import 'failure.dart';

class SongNotFoundOnYoutube extends Failure {
  SongNotFoundOnYoutube()
      : super(message: 'The song could not be found on Youtube');
}
