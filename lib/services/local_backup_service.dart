import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LocalBackupService {
  // Export data to JSON file
  Future<String?> exportToFile(Map<String, dynamic> data) async {
    try {
      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'expense_tracker_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      // Write data to file
      final file = File(filePath);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  // Import data from JSON file
  Future<Map<String, dynamic>?> importFromFile() async {
    try {
      // Let user pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final filePath = result.files.single.path;
      if (filePath == null) return null;

      // Read file content
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      return data;
    } catch (e) {
      rethrow;
    }
  }

  // Get backup file info
  String getBackupFileName() {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'expense_tracker_backup_$timestamp.json';
  }
}
