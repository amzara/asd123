import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: mergeRange(),
    );
  }
}

class mergeRange extends StatefulWidget {
  @override
  _MergeRangeState createState() => _MergeRangeState();
}

class _MergeRangeState extends State<mergeRange> {
  TextEditingController extController1 = TextEditingController();
  TextEditingController extController2 = TextEditingController();
  TextEditingController domainController =
      TextEditingController(text: 'trp.uc.dotdashtech.com');
  List<String> qrCodes = [];
  List<int> successfulExtensions = [];
  String apiResponse = '';
  bool qrCodesGenerated = false;
  bool displayQR = false;

  Future<void> generateQRCode() async {
    int ext1 = int.tryParse(extController1.text) ?? 0;
    int ext2 = int.tryParse(extController2.text) ?? 0;
    String domain = domainController.text;

    setState(() {
      qrCodes.clear();
      successfulExtensions.clear();
      apiResponse = '';
    });

    for (int i = ext1; i <= ext2; i++) {
      String url = 'http://10.16.1.22/crp2.php?ext=$i&domain=$domain';
      var response = await http.get(Uri.parse(url));
      setState(() {
        apiResponse = response.body;
        String? extractedImgUrl = newCustomFunction(apiResponse);
        if (extractedImgUrl != null) {
          qrCodes.add(extractedImgUrl);
          successfulExtensions.add(i);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Extension number $i is not found'),
            ),
          );
        }
      });
    }
    setState(() {
      qrCodesGenerated = true;
    });
    displayQR = true;
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

  Future<void> exportAsPDF() async {
    if (!qrCodesGenerated) {
      await generateQRCode();
    }

    try {
      PdfDocument document = PdfDocument();
      for (String imageUrl in qrCodes) {
        var response = await http.get(Uri.parse(imageUrl));
        var data = response.bodyBytes;

        PdfBitmap image = PdfBitmap(data);
        document.pages.add().graphics.drawImage(
              image,
              Rect.fromLTWH(
                0,
                0,
                document.pages[0].getClientSize().width,
                document.pages[0].getClientSize().height,
              ),
            );
      }
      final List<int> bytes = await document.save();
      document.dispose();

      final html.Blob blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "output.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error generating PDF: $e');
    }
    displayQR = false;
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

  Future<void> copyImageToClipboard(String imageUrl, int extension) async {
    try {
      final Uint8List? data = await _readImageBytes(imageUrl);
      if (data != null) {
        final clipboard = SystemClipboard.instance;
        if (clipboard != null) {
          final item = DataWriterItem(suggestedName: 'QR_Code.png');
          item.add(Formats.png(data));
          await clipboard.write([item]);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'QR code for extension "$extension" is copied to clipboard'),
            ),
          );
        } else {
          print('Clipboard is not available on this platform');
        }
      } else {
        print('Failed to read image');
      }
    } catch (e) {
      print('Error copying image to clipboard: $e');
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

  Future<void> generatePdf() async {
    try {
      if (qrCodes.isEmpty) {
        await generateQRCode();
      }

      if (qrCodes.isNotEmpty) {
        // Create a new PDF document
        PdfDocument document = PdfDocument();

        final double qrCodeWidth = 300;
        final double qrCodeHeight = 300;
        final double labelOffset = 20; // Adjust the offset as needed

        // Iterate through all QR codes and add them to the PDF
        for (int i = 0; i < qrCodes.length; i++) {
          // Load image data into PDF bitmap object
          var response = await http.get(Uri.parse(qrCodes[i]));
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
            'Extension: ${successfulExtensions[i]}',
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

        // Convert bytes to Uint8List
        Uint8List pdfBytes = Uint8List.fromList(bytes);

        // Create Blob from Uint8List
        final html.Blob blob = html.Blob([pdfBytes]);

        // Create object URL from Blob
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Create anchor element to trigger download
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "output.pdf") // Set filename
          ..click();

        // Revoke the object URL
        html.Url.revokeObjectUrl(url);
      } else {
        print('No QR codes available to generate PDF.');
      }
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Range of Number QR Generation'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await generateQRCode();
                    },
                    child: Text('Generate QR Codes'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      generatePdf();
                    },
                    child: Text('Generate PDF'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (displayQR == true) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        3, // Adjust the number of QR codes per row here
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                  ),
                  itemCount: qrCodes.length,
                  itemBuilder: (context, index) {
                    int extNumber = successfulExtensions[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Extension $extNumber:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Image.network(
                          qrCodes[index],
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                downloadImage(qrCodes[index], extNumber);
                              },
                              icon: Icon(Icons.file_download),
                              tooltip: 'Download Image',
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              onPressed: () {
                                copyImageToClipboard(qrCodes[index], extNumber);
                              },
                              icon: Icon(Icons.content_copy),
                              tooltip: 'Copy Image to Clipboard',
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
