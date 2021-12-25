import 'package:demixr_app/models/failure/failure.dart';

class SongLoadFailure extends Failure {
  SongLoadFailure() : super(message: 'Failure to load the selected song');
}
