import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime dueDate;

  @HiveField(6)
  int totalSecondsFocused;

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

  Task({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.dueDate,
    this.totalSecondsFocused = 0,
    this.isRecurring = false,
    this.recurrenceType = 'none',
    this.recurrenceInterval = 1,
    List<DateTime>? completionDates,
    this.parentId, // Add to constructor
    List<String>? subtaskIds, // Add to constructor
  }) : this.completionDates = completionDates ?? [],
       this.subtaskIds = subtaskIds ?? []; // Initialize subtaskIds

  Task copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    int? totalSecondsFocused,
    bool? isRecurring,
    String? recurrenceType,
    int? recurrenceInterval,
    List<DateTime>? completionDates,
    String? parentId,
    bool clearParentId = false, // Add flag to explicitly clear parentId
    List<String>? subtaskIds,
  }) {
    return Task(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      totalSecondsFocused: totalSecondsFocused ?? this.totalSecondsFocused,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      completionDates: completionDates ?? this.completionDates,
      parentId: clearParentId ? null : parentId ?? this.parentId, // Handle parentId update/clear
      subtaskIds: subtaskIds ?? this.subtaskIds,
    );
  }
} 