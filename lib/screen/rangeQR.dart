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
      home: rangeQR(),
    );
  }
}

class rangeQR extends StatefulWidget {
  @override
  _Function2State createState() => _Function2State();
}

class _Function2State extends State<rangeQR> {
  TextEditingController extController1 = TextEditingController();
  TextEditingController extController2 = TextEditingController();
  TextEditingController domainController = TextEditingController();
  List<String> qrCodes = [];
  String apiResponse = '';

  Future<void> fetchData() async {
    int ext1 = int.tryParse(extController1.text) ?? 0; // Handle parsing errors
    int ext2 = int.tryParse(extController2.text) ?? 0; // Handle parsing errors
    String domain = domainController.text;

    // Clear previous data
    setState(() {
      qrCodes.clear();
      apiResponse = '';
    });

    for (int i = ext1; i <= ext2; i++) {
      String url = 'https://10.16.1.213/backend/crp2.php?ext=$i&domain=$domain';
      var response = await http.get(Uri.parse(url));
      setState(() {
        apiResponse = response.body;
        String? extractedImgUrl = newCustomFunction(apiResponse);
        if (extractedImgUrl != null && !qrCodes.contains(extractedImgUrl)) {
          qrCodes.add(extractedImgUrl);
        }
      });
    }

    // Generate PDF after fetching data
    generatePdf();
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
      int? urlEndIndex = html.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html.indexOf('"', urlStartIndex);
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

  Future<void> generatePdf() async {
    try {
      // Create a new PDF document
      PdfDocument document = PdfDocument();

      // Iterate through all QR codes and add them to the PDF
      for (String imageUrl in qrCodes) {
        // Load image data into PDF bitmap object
        var response = await http.get(Uri.parse(imageUrl));
        var data = response.bodyBytes;
        PdfBitmap image = PdfBitmap(data);

        // Draw image on the page graphics
        document.pages.add().graphics.drawImage(
              image,
              Rect.fromLTWH(0, 0, document.pages[0].getClientSize().width,
                  document.pages[0].getClientSize().height),
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
            children: [
              TextFormField(
                controller: extController1,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Start Extension'),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: extController2,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'End Extension'),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: domainController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: 'Domain'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchData,
                child: Text('Generate QR Codes and PDF'),
              ),
              SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: qrCodes.length,
                itemBuilder: (context, index) {
                  int extNumber = int.parse(extController1.text) + index;
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
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          qrCodes[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
