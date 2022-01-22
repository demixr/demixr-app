import 'package:hive/hive.dart';

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final typeId = 1;

  @override
  void write(BinaryWriter writer, Duration obj) =>
      writer.writeInt(obj.inMilliseconds);

  @override
  Duration read(BinaryReader reader) =>
      Duration(milliseconds: reader.readInt());
}
