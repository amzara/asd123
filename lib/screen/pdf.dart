import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      home: pdf(),
    );
  }
}

class pdf extends StatefulWidget {
  @override
  _Function3State createState() => _Function3State();
}

class _Function3State extends State<pdf> {
  TextEditingController extController = TextEditingController();
  TextEditingController domainController = TextEditingController();
  List<int> selectedExtensions = [];
  List<String> qrCodes = [];
  String apiResponse = '';

  Future<void> fetchData(int extension, String domain) async {
    String url =
        'https://10.16.1.213/backend/crp2.php?ext=$extension&domain=$domain';
    var response = await http.get(Uri.parse(url));
    setState(() {
      apiResponse = response.body;
      String? extractedImgUrl = newCustomFunction(apiResponse);
      if (extractedImgUrl != null) {
        qrCodes.add(extractedImgUrl);
      }
    });
  }

  String? newCustomFunction(String? html) {
    /// MODIFY CODE ONLY BELOW THIS LINE

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

    /// MODIFY CODE ONLY ABOVE THIS LINE
  }

  void addExtension() {
    int extension = int.tryParse(extController.text) ?? 0;
    if (extension != 0) {
      setState(() {
        selectedExtensions.add(extension);
      });
      extController.clear();
    }
  }

  void generateQRCodesAndPDF() async {
    String domain = domainController.text;

    // Fetch QR codes for selected extensions
    for (int extension in selectedExtensions) {
      await fetchData(extension, domain);
    }

    // Generate PDF after fetching QR codes
    generatePdf();
  }

  Future<void> generatePdf() async {
    try {
      // Create a new PDF document
      PdfDocument document = PdfDocument();

      final double qrCodeWidth = 500;
      final double qrCodeHeight = 500;

      // Iterate through all QR codes and add them to the PDF
      for (int i = 0; i < qrCodes.length; i++) {
        String imageUrl = qrCodes[i];

        // Load image data into PDF bitmap object
        var response = await http.get(Uri.parse(imageUrl));
        var data = response.bodyBytes;
        PdfBitmap image = PdfBitmap(data);

        // Draw image on the page graphics
        document.pages.add().graphics.drawImage(
              image,
              Rect.fromLTWH(0, 0, qrCodeWidth, qrCodeHeight),
            );

        // Add text label indicating the extension number
        document.pages[i].graphics.drawString(
          'Extension: ${selectedExtensions[i]}',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(
              10, 10, 500, 20), // Adjust position and size as needed
        );
      }

      // Save the document
      final List<int> bytes = await document.save();
      // Dispose the document
      document.dispose();

      // Get the directory for saving PDF
      final directory = await getTemporaryDirectory();
      final String tempPath = directory.path;

      // Write PDF bytes to a temporary file
      final tempFile = File('$tempPath/output.pdf');
      await tempFile.writeAsBytes(bytes, flush: true);

      // Get permission to access the downloads directory
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // Move the file to the downloads directory
      final downloadsDirectory = await getDownloadsDirectory();
      final String downloadsPath = downloadsDirectory!.path;
      final String newPath = '$downloadsPath/output.pdf';
      await tempFile.copy(newPath);

      print('PDF generated successfully at: $newPath');

      // Open the PDF file
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
                controller: extController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Extension'),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: domainController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: 'Domain'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addExtension,
                child: Text('Add Extension'),
              ),
              SizedBox(height: 20),
              if (selectedExtensions.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Extensions:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: selectedExtensions.map((extension) {
                        return Chip(
                          label: Text('$extension'),
                          onDeleted: () {
                            setState(() {
                              selectedExtensions.remove(extension);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ElevatedButton(
                onPressed: generateQRCodesAndPDF,
                child: Text('Generate QR Codes and PDF'),
              ),
              SizedBox(height: 20),
              if (qrCodes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: qrCodes.map((qrCode) {
                    int extNumber = selectedExtensions[qrCodes.indexOf(qrCode)];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Code for Extension $extNumber:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Image.network(
                            qrCode,
                            fit: BoxFit.cover,
                          ),
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
