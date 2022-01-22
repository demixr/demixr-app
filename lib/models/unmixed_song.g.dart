// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unmixed_song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnmixedSongAdapter extends TypeAdapter<UnmixedSong> {
  @override
  final int typeId = 0;

  @override
  UnmixedSong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnmixedSong(
      title: fields[0] as String,
      artists: (fields[1] as List).cast<String>(),
      duration: fields[3] as Duration,
      mixture: fields[4] as String,
      vocals: fields[5] as String,
      bass: fields[6] as String,
      drums: fields[7] as String,
      other: fields[8] as String,
      coverPath: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UnmixedSong obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.artists)
      ..writeByte(2)
      ..write(obj.coverPath)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.mixture)
      ..writeByte(5)
      ..write(obj.vocals)
      ..writeByte(6)
      ..write(obj.bass)
      ..writeByte(7)
      ..write(obj.drums)
      ..writeByte(8)
      ..write(obj.other);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnmixedSongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
