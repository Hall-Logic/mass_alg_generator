import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LogFileUtils {
  static Future<File> initializeLogFile() async {
    Directory? documentsDirectory;
    if (Platform.isAndroid) {
      documentsDirectory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      documentsDirectory = await getApplicationDocumentsDirectory();
    }
    if (documentsDirectory != null) {
      String filePath = '${documentsDirectory.path}/log.csv';
      return File(filePath);
    }
    throw Exception("Error initializing log file.");
  }

  static Future<String> getLogFileSize(File logFile) async {
    if (await logFile.exists()) {
      int fileSizeBytes = await logFile.length();
      double fileSizeInMB = (fileSizeBytes.toDouble() / (1024 * 1024));
      return fileSizeInMB.toStringAsFixed(2) + " MB";
    } else {
      return "0.00 MB";
    }
  }

  static Future<void> clearLogFile(File logFile) async {
    if (await logFile.exists()) {
      await logFile.writeAsString('');
    } else {
      print("log.csv file does not exist");
    }
  }

  static Future<void> shareFile(File logFile) async {
    await Share.shareFiles([logFile.path]);
  }
}
