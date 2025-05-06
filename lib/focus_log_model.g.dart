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
    
    // Handle the case where status might be null in existing data
    FocusSessionStatus status = FocusSessionStatus.completed; // Default value
    if (fields.containsKey(4) && fields[4] != null) {
      try {
        status = fields[4] as FocusSessionStatus;
      } catch (e) {
        print("Error reading status field: $e");
        // Keep the default value
      }
    }
    
    return FocusSessionLog(
      id: fields[0] as String,
      categoryName: fields[1] as String,
      startTime: fields[2] as DateTime,
      durationSeconds: fields[3] as int,
      status: status, // Use our safe status value
    );
  }

  @override
  void write(BinaryWriter writer, FocusSessionLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryName)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.status);
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

class FocusSessionStatusAdapter extends TypeAdapter<FocusSessionStatus> {
  @override
  final int typeId = 4;

  @override
  FocusSessionStatus read(BinaryReader reader) {
    try {
      final value = reader.readByte();
      switch (value) {
        case 0:
          return FocusSessionStatus.completed;
        case 1:
          return FocusSessionStatus.failed;
        case 2:
          return FocusSessionStatus.inProgress;
        case 3:
          return FocusSessionStatus.skipped;
        default:
          print("Unknown status value: $value, defaulting to completed");
          return FocusSessionStatus.completed;
      }
    } catch (e) {
      print("Error reading FocusSessionStatus: $e");
      // If any error occurs, return a default value
      return FocusSessionStatus.completed;
    }
  }

  @override
  void write(BinaryWriter writer, FocusSessionStatus obj) {
    try {
      switch (obj) {
        case FocusSessionStatus.completed:
          writer.writeByte(0);
          break;
        case FocusSessionStatus.failed:
          writer.writeByte(1);
          break;
        case FocusSessionStatus.inProgress:
          writer.writeByte(2);
          break;
        case FocusSessionStatus.skipped:
          writer.writeByte(3);
          break;
      }
    } catch (e) {
      print("Error writing FocusSessionStatus: $e");
      // Write completed as a fallback
      writer.writeByte(0);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
