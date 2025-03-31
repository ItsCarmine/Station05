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
  DateTime dueDate;

  @HiveField(5)
  bool isCompleted;

  Task({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
  });
} 