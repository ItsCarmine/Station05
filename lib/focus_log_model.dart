import 'package:hive/hive.dart';

part 'focus_log_model.g.dart'; // Will be generated

@HiveType(typeId: 3) // Ensure this typeId is unique (Task=0, Goal=2)
class FocusSessionLog extends HiveObject {
  @HiveField(0)
  String id; // Unique ID for the log entry

  @HiveField(1)
  String categoryName; // Category the focus was for

  @HiveField(2)
  DateTime startTime; // When the session started

  @HiveField(3)
  int durationSeconds; // How long the session lasted

  // Optional: Link back to the specific task? Might be useful later.
  // @HiveField(4)
  // String? taskId; 

  FocusSessionLog({
    required this.id,
    required this.categoryName,
    required this.startTime,
    required this.durationSeconds,
    // this.taskId,
  });
} 