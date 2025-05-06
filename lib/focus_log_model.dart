import 'package:hive/hive.dart';

part 'focus_log_model.g.dart';

@HiveType(typeId: 4) // Make sure this is a unique typeId
enum FocusSessionStatus {
  @HiveField(0)
  completed,
  
  @HiveField(1)
  failed,
  
  @HiveField(2)
  inProgress,
  
  @HiveField(3)
  skipped
}

@HiveType(typeId: 3)
class FocusSessionLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryName;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  int durationSeconds;
  
  // Add this new field
  @HiveField(4)
  FocusSessionStatus status;

  FocusSessionLog({
    required this.id,
    required this.categoryName,
    required this.startTime,
    required this.durationSeconds,
    this.status = FocusSessionStatus.completed, // Default to completed
  });
}