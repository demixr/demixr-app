import 'package:demixr_app/models/failure/failure.dart';

class SongNotAvailable extends Failure {
  SongNotAvailable() : super(message: 'Song not available');
}
