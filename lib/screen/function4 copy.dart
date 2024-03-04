import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: function4(),
    );
  }
}

class function4 extends StatefulWidget {
  @override
  _Function4State createState() => _Function4State();
}

class _Function4State extends State<function4> {
  TextEditingController domainController =
      TextEditingController(text: 'fsdev.uc.dotdashtech.com');
  List<Map<String, String>> qrCodes = [];
  String apiResponse = '';
  File? _selectedFile;

  Future<void> fetchData(int extension, String domain) async {
    String url =
        'https://10.16.1.213/backend/crp2.php?ext=$extension&domain=$domain';
    var response = await http.get(Uri.parse(url));
    setState(() {
      apiResponse = response.body;
      String? extractedImgUrl = newCustomFunction(apiResponse);
      if (extractedImgUrl != null) {
        qrCodes.add({
          'url': extractedImgUrl,
          'label': 'QR Code for Extension $extension', // Label for the QR code
        });
      }
    });
  }

  String? newCustomFunction(String? html) {
    // Modify code only below this line

    // Find the index of 'src' attribute
    int? srcIndex = html!.indexOf('src=');

    // If 'src' attribute is found
    if (srcIndex != null && srcIndex != -1) {
      // Move the index to the start of the URL
      int urlStartIndex = srcIndex + 5; // 5 is the length of 'src='

      // Find the closing quote of the URL
      int? urlEndIndex = html?.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html?.indexOf('"', urlStartIndex);
      }

      // Extract the URL if urlEndIndex is not null
      if (urlEndIndex != null && urlEndIndex != -1) {
        String imageUrl = html.substring(urlStartIndex, urlEndIndex);
        // Append the base URL
        return "https://10.16.1.213/backend/$imageUrl";
      }
    }

    // If 'src' attribute is not found or URL extraction fails, return null
    return null;

    // Modify code only above this line
  }

  void generateQRCodes() async {
    String domain = domainController.text;

    if (_selectedFile != null) {
      List<List<dynamic>> csvData = await readAsLines(_selectedFile!);

      for (var row in csvData.skip(1)) {
        int extension = row[0]; // Assuming extension is in the first column
        await fetchData(extension, domain);
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No file selected'),
          content: Text('Please select a CSV file.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<List<List<dynamic>>> readAsLines(File file) async {
    String contents = await file.readAsString();
    return CsvToListConverter().convert(contents);
  }

  Future<void> _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    } else {
      // User canceled the picker
    }
  }

  Future<void> copyImageToClipboard(String extractedImgUrl) async {
    final bytes = await _readImageBytes(extractedImgUrl);
    if (bytes != null) {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem(suggestedName: 'QRCode.png');
        item.add(Formats.png(bytes));
        await clipboard.write([item]);
        print('Image copied to clipboard');
      } else {
        print('Clipboard is not available on this platform');
      }
    } else {
      print('Failed to read image');
    }
  }

  Future<Uint8List?> _readImageBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to fetch image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error reading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Generator'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: domainController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: 'Domain'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openFilePicker,
                child: Text('Select CSV File'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: generateQRCodes,
                child: Text('Generate QR Codes'),
              ),
              SizedBox(height: 20),
              if (qrCodes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: qrCodes.map((qrCode) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qrCode['label'] ?? '', // Display label
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            qrCode['url'] ?? '',
                            fit: BoxFit.cover,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            copyImageToClipboard(qrCode['url'] ?? '');
                          },
                          child: Text('Copy Image to Clipboard'),
                        ),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
