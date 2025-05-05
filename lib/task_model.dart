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

  @HiveField(7)
  bool isRecurring;

  @HiveField(8)
  String recurrenceType;

  @HiveField(9)
  int recurrenceInterval;

  @HiveField(10)
  List<DateTime> completionDates;

  // --- New fields for subtasks ---
  @HiveField(11)
  final String? parentId; // Null if it's a top-level task

  @HiveField(12)
  List<String> subtaskIds; // IDs of direct children tasks
  // ------------------------------

  // --- New field for weekly recurrence days ---
  @HiveField(13)
  List<int> recurrenceDaysOfWeek; // Stores 1-7 for Mon-Sun, used if type is weekly
  // ------------------------------------------

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
    this.parentId, // Add to constructor
    List<String>? subtaskIds, // Add to constructor
    List<int>? recurrenceDaysOfWeek, // Add to constructor
  }) : completionDates = completionDates ?? [],
       subtaskIds = subtaskIds ?? [], // Initialize subtaskIds
       recurrenceDaysOfWeek = recurrenceDaysOfWeek ?? []; // Initialize days of week

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
    bool clearParentId = false, // Add flag to explicitly clear parentId
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
      parentId: clearParentId ? null : parentId ?? this.parentId, // Handle parentId update/clear
      subtaskIds: subtaskIds ?? this.subtaskIds,
      recurrenceDaysOfWeek: recurrenceDaysOfWeek ?? this.recurrenceDaysOfWeek,
    );
  }
} 