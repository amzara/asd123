import 'package:flutter/material.dart';
import 'package:to_csv/to_csv.dart' as exportCSV;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV Export Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: csvPractice(),
    );
  }
}

class csvPractice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CSV Export'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _exportToCSV(context);
          },
          child: Text('Export to CSV'),
        ),
      ),
    );
  }

  void _exportToCSV(BuildContext context) {
    List<String> header = ['No.', 'User Name', 'Mobile', 'ID Number'];
    List<List<String>> listOfLists = [
      ['1', 'Bilal Saeed', '1374934', '912839812'],
      ['2', 'Ahmar', '21341234', '192834821']
    ];

    try {
      exportCSV.myCSV(header, listOfLists);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV file exported successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting CSV file: $e'),
        ),
      );
    }
  }
}
