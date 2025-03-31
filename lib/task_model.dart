import 'package:flutter/material.dart';

class Task {
  final String id;
  final String category;
  String title;
  String description;
  DateTime dueDate;
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