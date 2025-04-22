// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      category: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      isCompleted: fields[4] as bool,
      dueDate: fields[5] as DateTime,
      totalSecondsFocused: fields[6] as int,
      isRecurring: fields[7] as bool,
      recurrenceType: fields[8] as String,
      recurrenceInterval: fields[9] as int,
      completionDates: (fields[10] as List?)?.cast<DateTime>(),
      parentId: fields[11] as String?,
      subtaskIds: (fields[12] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.totalSecondsFocused)
      ..writeByte(7)
      ..write(obj.isRecurring)
      ..writeByte(8)
      ..write(obj.recurrenceType)
      ..writeByte(9)
      ..write(obj.recurrenceInterval)
      ..writeByte(10)
      ..write(obj.completionDates)
      ..writeByte(11)
      ..write(obj.parentId)
      ..writeByte(12)
      ..write(obj.subtaskIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
