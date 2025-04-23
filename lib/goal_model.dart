import 'package:hive/hive.dart';

part 'goal_model.g.dart'; // Will be generated

@HiveType(typeId: 2) // Ensure this typeId is unique (Task is 0, assuming nothing is 1 yet)
class Goal extends HiveObject {
  @HiveField(0)
  String id; // Using category name as ID might be simpler if one goal per category
             // Or generate a unique ID if multiple goals per category are possible.
             // Let's use categoryName as ID for now, assuming one goal per category.

  @HiveField(1)
  String categoryName;

  @HiveField(2)
  int weeklyTargetSeconds; // Store goal in seconds for consistency

  Goal({
    required this.id, 
    required this.categoryName,
    required this.weeklyTargetSeconds,
  });

  // Helper to get hours for display
  double get weeklyTargetHours => weeklyTargetSeconds / 3600.0;
} 