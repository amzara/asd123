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
  _PdfGeneratorState createState() => _PdfGeneratorState();
}

class _PdfGeneratorState extends State<pdf> {
  TextEditingController extController = TextEditingController();
  TextEditingController domainController = TextEditingController();
  String apiResponse = '';
  String? extractedImgUrl;

  Future<void> fetchData() async {
    String ext = extController.text;
    String domain = domainController.text;

    // Construct the URL with ext and domain entered by the user
    String url = 'https://10.16.1.213/backend/crp2.php?ext=$ext&domain=$domain';

    // Perform GET request
    var response = await http.get(Uri.parse(url));
    setState(() {
      // Set the response text to apiResponse variable
      apiResponse = response.body;

      // Extract img URL from the response
      extractedImgUrl = newCustomFunction(apiResponse);

      if (extractedImgUrl != null) {
        // Generate PDF if extractedImgUrl is not null
        generatePdf(extractedImgUrl!);
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

  Future<void> generatePdf(String imageUrl) async {
    try {
      // Create a new PDF document
      PdfDocument document = PdfDocument();

      // Load image data into PDF bitmap object
      var response = await http.get(Uri.parse(imageUrl));
      var data = response.bodyBytes;
      PdfBitmap image = PdfBitmap(data);

      // Get the dimensions of the image
      int imageWidth = image.width;
      int imageHeight = image.height;

      // Calculate the aspect ratio to maintain the original proportions
      double aspectRatio = imageWidth / imageHeight;

      // Calculate the width and height of the image in PDF units (points)
      double maxWidth = 500; // Maximum width for the image
      double maxHeight =
          500 / aspectRatio; // Calculate height based on aspect ratio

      // Draw image on the page graphics, setting width and height dynamically
      document.pages.add().graphics.drawImage(
            image,
            Rect.fromLTWH(0, 0, maxWidth, maxHeight),
          );

      // Save the document
      final List<int> bytes = await document.save(); // Await here
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
        title: Text('PDF Generator'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: extController,
              keyboardType: TextInputType.text,
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
              onPressed: () {
                fetchData(); // Call the method to fetch data from API and generate PDF
              },
              child: Text('Fetch Data and Generate PDF'),
            ),
            SizedBox(height: 20),
            Text(
              'API Response: $apiResponse',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            if (extractedImgUrl != null)
              Image.network(
                extractedImgUrl!, // Use extractedImgUrl as the image URL
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }
}
