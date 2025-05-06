import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String category;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime dueDate;

  @HiveField(6)
  bool isRecurring;

  @HiveField(7)
  String recurrenceType;

  @HiveField(8)
  int recurrenceInterval;

  @HiveField(9)
  List<DateTime> completionDates;

  @HiveField(10)
  final String? parentId;

  @HiveField(11)
  List<String> subtaskIds;

  @HiveField(12)
  List<int> recurrenceDaysOfWeek;

  Task({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.dueDate,
    this.isRecurring = false,
    this.recurrenceType = 'none',
    this.recurrenceInterval = 1,
    List<DateTime>? completionDates,
    this.parentId,
    List<String>? subtaskIds,
    List<int>? recurrenceDaysOfWeek,
  }) : completionDates = completionDates ?? [],
       subtaskIds = subtaskIds ?? [],
       recurrenceDaysOfWeek = recurrenceDaysOfWeek ?? [];

  Task copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrenceType,
    int? recurrenceInterval,
    List<DateTime>? completionDates,
    String? parentId,
    bool clearParentId = false,
    List<String>? subtaskIds,
    List<int>? recurrenceDaysOfWeek,
  }) {
    return Task(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      completionDates: completionDates ?? this.completionDates,
      parentId: clearParentId ? null : parentId ?? this.parentId,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek ?? this.recurrenceDaysOfWeek,
    );
  }
} 