// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusSessionLogAdapter extends TypeAdapter<FocusSessionLog> {
  @override
  final int typeId = 3;

  @override
  FocusSessionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusSessionLog(
      id: fields[0] as String,
      categoryName: fields[1] as String,
      startTime: fields[2] as DateTime,
      durationSeconds: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FocusSessionLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryName)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
