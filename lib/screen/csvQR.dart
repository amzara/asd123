import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: csvQR(),
    );
  }
}

class csvQR extends StatefulWidget {
  @override
  _QRCodeGeneratorState createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<csvQR> {
  TextEditingController domainController =
      TextEditingController(text: 'fsdev.uc.dotdashtech.com');
  List<String> qrCodes = [];
  File? _selectedFile;

  Future<void> fetchData(int extension, String domain) async {
    String url =
        'https://10.16.1.213/backend/crp2.php?ext=$extension&domain=$domain';
    var response = await http.get(Uri.parse(url));
    setState(() {
      String? extractedImgUrl = newCustomFunction(response.body);
      if (extractedImgUrl != null) {
        qrCodes.add(extractedImgUrl);
      }
    });
  }

  String? newCustomFunction(String? html) {
    int? srcIndex = html!.indexOf('src=');
    if (srcIndex != null && srcIndex != -1) {
      int urlStartIndex = srcIndex + 5;
      int? urlEndIndex = html?.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html?.indexOf('"', urlStartIndex);
      }
      if (urlEndIndex != null && urlEndIndex != -1) {
        String imageUrl = html.substring(urlStartIndex, urlEndIndex);
        return "https://10.16.1.213/backend/$imageUrl";
      }
    }
    return null;
  }

  void generateQRCodesAndPDF() async {
    qrCodes.clear(); // Clear existing QR codes
    String domain = domainController.text;

    if (_selectedFile != null) {
      List<List<dynamic>> csvData = await readAsLines(_selectedFile!);

      for (var row in csvData.skip(1)) {
        int extension = row[0]; // Assuming extension is in the first column
        await fetchData(extension, domain);
      }

      // Generate PDF after fetching all QR codes
      generatePdf();
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

  Future<void> generatePdf() async {
    try {
      PdfDocument document = PdfDocument();

      final double qrCodeWidth = 500;
      final double qrCodeHeight = 500;

      for (int i = 0; i < qrCodes.length; i++) {
        String imageUrl = qrCodes[i];
        var response = await http.get(Uri.parse(imageUrl));
        var data = response.bodyBytes;
        PdfBitmap image = PdfBitmap(data);

        document.pages.add().graphics.drawImage(
              image,
              Rect.fromLTWH(0, 0, qrCodeWidth, qrCodeHeight),
            );

        document.pages[i].graphics.drawString(
          'Extension: ${i + 1}',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(10, 10, 500, 20),
        );
      }

      final List<int> bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final String tempPath = directory.path;

      final tempFile = File('$tempPath/output.pdf');
      await tempFile.writeAsBytes(bytes, flush: true);

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final downloadsDirectory = await getDownloadsDirectory();
      final String downloadsPath = downloadsDirectory!.path;
      final String newPath = '$downloadsPath/output.pdf';
      await tempFile.copy(newPath);

      print('PDF generated successfully at: $newPath');

      OpenFile.open(newPath);
    } catch (e) {
      print('Error generating PDF: $e');
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
                onPressed: generateQRCodesAndPDF,
                child: Text('Generate QR Codes and PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
