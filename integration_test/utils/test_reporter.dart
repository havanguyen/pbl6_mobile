import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class TestResult {
  final String caseId;
  final String description;
  final String status; // 'PASSED', 'FAILED'
  final String errorMessage;
  final DateTime timestamp;

  TestResult({
    required this.caseId,
    required this.description,
    required this.status,
    this.errorMessage = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TestReporter {
  static final TestReporter _instance = TestReporter._internal();
  final List<TestResult> _results = [];

  factory TestReporter() {
    return _instance;
  }

  TestReporter._internal();

  void addResult({
    required String caseId,
    required String description,
    required String status,
    String errorMessage = '',
  }) {
    _results.add(TestResult(
      caseId: caseId,
      description: description,
      status: status,
      errorMessage: errorMessage,
    ));
    print('Test Result Added: $caseId - $status');
  }

  Future<String> exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['TestResults'];
    
    // Remove default sheet
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Add Header
    List<String> headers = ['Case ID', 'Description', 'Status', 'Error Message', 'Timestamp'];
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // Add Data
    for (var result in _results) {
      sheetObject.appendRow([
        TextCellValue(result.caseId),
        TextCellValue(result.description),
        TextCellValue(result.status),
        TextCellValue(result.errorMessage),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(result.timestamp)),
      ]);
    }

    // Save file
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory(); // For easier access on Android
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Windows/Linux/Mac
        directory = await getApplicationDocumentsDirectory();
      }
      
      // Attempt to mimic the requested path structure inside the doc dir
      final String resultDir = '${directory!.path}/test_result';
      final Directory dir = Directory(resultDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String fileName = 'test_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final String filePath = '$resultDir/$fileName';
      
      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        print('Excel report saved to: $filePath');
        return filePath;
      }
      return '';
    } catch (e) {
      print('Error saving Excel report: $e');
      return '';
    }
  }
  
  void clear() {
    _results.clear();
  }
}
