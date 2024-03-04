import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'dart:html' as html;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: mergeTarget(),
    );
  }
}

class mergeTarget extends StatefulWidget {
  @override
  _MergeTargetState createState() => _MergeTargetState();
}

class _MergeTargetState extends State<mergeTarget> {
  TextEditingController extController = TextEditingController();
  TextEditingController domainController =
      TextEditingController(text: 'trp.uc.dotdashtech.com');
  List<int> selectedExtensions = [];
  List<String> qrCodes = [];
  List<int> successfulExtensions = [];
  List<int> invalidExtensions = [];
  List<int> qrCodeLabels = [];
  String apiResponse = '';
  bool displayQR = false;

  Future<void> fetchData(int extension, String domain) async {
    String url = 'http://10.16.1.22/crp2.php?ext=$extension&domain=$domain';
    var response = await http.get(Uri.parse(url));
    setState(() {
      apiResponse = response.body;
      String? extractedImgUrl = newCustomFunction(apiResponse);
      if (extractedImgUrl != null) {
        qrCodes.add(extractedImgUrl);
        successfulExtensions.add(extension);
        qrCodeLabels.add(extension);
      } else {
        invalidExtensions.add(extension);
      }
    });
  }

  String? newCustomFunction(String? html) {
    int? srcIndex = html!.indexOf('src=');

    if (srcIndex != null && srcIndex != -1) {
      int urlStartIndex = srcIndex + 5;

      int? urlEndIndex = html.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html.indexOf('"', urlStartIndex);
      }

      if (urlEndIndex != null && urlEndIndex != -1) {
        String imageUrl = html.substring(urlStartIndex, urlEndIndex);
        return "http://10.16.1.22/$imageUrl";
      }
    }

    return null;
  }

  void addExtension() {
    int extension = int.tryParse(extController.text) ?? 0;
    if (extension != 0) {
      setState(() {
        selectedExtensions.add(extension);
        successfulExtensions.add(extension);
        qrCodeLabels.add(extension);
      });
      extController.clear();
    }
  }

  Future<void> generateQRCodes() async {
    String domain = domainController.text;

    setState(() {
      qrCodes.clear();
      successfulExtensions.clear();
      invalidExtensions.clear();
      qrCodeLabels.clear();
    });

    for (int extension in selectedExtensions) {
      await fetchData(extension, domain);
    }

    displayQR = true;

    if (invalidExtensions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to retrieve QR code for ${invalidExtensions.length} extension(s).'),
        ),
      );
    }
  }

  Future<void> downloadPdf(Uint8List bytes) async {
    try {
      final html.Blob blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "output.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }

  Future<void> generatePdf() async {
    try {
      if (qrCodes.isEmpty) {
        // If QR codes haven't been generated yet, generate them implicitly
        await generateQRCodes();
      }

      if (qrCodes.isNotEmpty) {
        // Create a new PDF document
        PdfDocument document = PdfDocument();

        final double qrCodeWidth = 300;
        final double qrCodeHeight = 300;
        final double labelOffset = 20; // Adjust the offset as needed

        // Iterate through all QR codes and add them to the PDF
        for (int i = 0; i < qrCodes.length; i++) {
          // Use qrCodes.length as limit
          String imageUrl = qrCodes[i];

          // Load image data into PDF bitmap object
          var response = await http.get(Uri.parse(imageUrl));
          var data = response.bodyBytes;
          PdfBitmap image = PdfBitmap(data);

          // Add new page for each QR code
          PdfPage page = document.pages.add();

          // Calculate position for centering the QR code and text label
          double centerX = (page.getClientSize().width - qrCodeWidth) / 2;
          double centerY = (page.getClientSize().height - qrCodeHeight) / 2;

          // Draw image on the page graphics centered
          page.graphics.drawImage(
            image,
            Rect.fromLTWH(centerX, centerY, qrCodeWidth, qrCodeHeight),
          );

          // Calculate position for centering the text label below the QR code
          double labelX = centerX;
          double labelY = centerY + qrCodeHeight + labelOffset;

          // Add text label indicating the extension number
          page.graphics.drawString(
            'Extension: ${qrCodeLabels[i]}',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            bounds: Rect.fromLTWH(
              labelX,
              labelY,
              qrCodeWidth,
              20,
            ), // Adjust position and size as needed
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }

        // Save the document
        final List<int> bytes = await document.save();
        // Dispose the document
        document.dispose();

        // Download the PDF
        downloadPdf(Uint8List.fromList(bytes));
      } else {
        print('No QR codes available to generate PDF.');
      }
    } catch (e) {
      print('Error generating PDF: $e');
    }
    displayQR == false;
  }

  Future<void> copyImageToClipboard(String imageUrl) async {
    final bytes = await _readImageBytes(imageUrl);
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
      // Perform a GET request to fetch the image data
      final response = await http.get(Uri.parse(imageUrl));

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        // Convert the response body (image data) to bytes
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

  Future<void> downloadImage(String imageUrl, int extension) async {
    try {
      final Uint8List? data = await _readImageBytes(imageUrl);
      final html.Blob blob = html.Blob([data]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
            "download", "qr_code_$extension.png") // Set filename dynamically
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error downloading image: $e');
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
              Column(
                children: [
                  TextFormField(
                    controller: extController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Extension'),
                  ),
                  SizedBox(height: 10),
                  IconButton(
                    onPressed: addExtension,
                    icon: Icon(Icons.add),
                    tooltip: 'Add Extension',
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: domainController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: 'Domain'),
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
                      children: successfulExtensions.map((extension) {
                        return Chip(
                          label: Text('$extension'),
                          onDeleted: () {
                            setState(() {
                              int index =
                                  successfulExtensions.indexOf(extension);
                              selectedExtensions.remove(extension);
                              successfulExtensions.removeAt(index);
                              qrCodeLabels.removeAt(index);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ElevatedButton(
                onPressed: generateQRCodes,
                child: Text('Generate QR Codes'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: generatePdf,
                child: Text('Generate PDF'),
              ),
              SizedBox(height: 20),
              if (displayQR == true)
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 20.0,
                  crossAxisSpacing: 20.0,
                  children: qrCodes.map((qrCode) {
                    int extNumber = qrCodeLabels[qrCodes.indexOf(qrCode)];
                    return Column(
                      children: [
                        Text(
                          'Extension: $extNumber',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          children: [
                            Image.network(
                              qrCode,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    copyImageToClipboard(qrCode);
                                  },
                                  icon: Icon(Icons.content_copy),
                                  tooltip: 'Copy to Clipboard',
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.file_download),
                                  tooltip: 'Download Image',
                                  onPressed: () {
                                    downloadImage(qrCode, extNumber);
                                  },
                                ),
                              ],
                            ),
                          ],
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
