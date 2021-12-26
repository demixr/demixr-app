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
      mixture: fields[0] as Song,
      vocals: fields[1] as Song,
      bass: fields[2] as Song,
      drums: fields[3] as Song,
      other: fields[4] as Song,
    );
  }

  @override
  void write(BinaryWriter writer, UnmixedSong obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.mixture)
      ..writeByte(1)
      ..write(obj.vocals)
      ..writeByte(2)
      ..write(obj.bass)
      ..writeByte(3)
      ..write(obj.drums)
      ..writeByte(4)
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
