import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:station5/main.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:station5/task_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProvider extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.createTemp().then((dir) => dir.path);
  }
}

void main() {
  group('Calendar Task Tests', () {
    setUp(() async {
      // Set up mock path provider
      PathProviderPlatform.instance = MockPathProvider();
      
      // Initialize Hive in a temp directory
      final tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);
      
      // Register adapters
      Hive.registerAdapter(TaskAdapter());
      
      // Open boxes
      await Hive.openBox<Task>(taskBoxName);
      await Hive.openBox<String>(categoryBoxName);
    });

    tearDown(() async {
      // Clean up after each test
      await Hive.deleteFromDisk();
    });

    testWidgets('Add task on a different calendar date', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(MaterialApp(home: NoTitle()));
      await tester.pumpAndSettle();

      // Find and tap the calendar icon in the AppBar
      final calendarIcon = find.byIcon(Icons.calendar_today).first;
      await tester.tap(calendarIcon);
      await tester.pumpAndSettle();

      // Select tomorrow's date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final formattedDate = DateFormat('MMM d, y').format(tomorrow);

      // Add a new task
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in task details
      await tester.enterText(find.byType(TextField).first, 'Future Task');
      
      // Save the task
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the task appears on the selected date
      expect(find.text('Future Task'), findsOneWidget);
      expect(find.text(formattedDate), findsOneWidget);
    });
  });
} 