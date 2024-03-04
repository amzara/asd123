import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: function2(),
    );
  }
}

class function2 extends StatefulWidget {
  @override
  _Function2State createState() => _Function2State();
}

class _Function2State extends State<function2> {
  TextEditingController extController1 = TextEditingController();
  TextEditingController extController2 = TextEditingController();
  TextEditingController domainController = TextEditingController();
  List<String> qrCodes = [];
  String apiResponse = '';

  Future<void> fetchData() async {
    int ext1 = int.tryParse(extController1.text) ?? 0;
    int ext2 = int.tryParse(extController2.text) ?? 0;
    String domain = domainController.text;

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
                child: Text('Generate QR Codes'),
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
                      ElevatedButton(
                        onPressed: () {
                          copyImageToClipboard(qrCodes[index]);
                        },
                        child: Text('Copy Image to Clipboard'),
                      ),
                      SizedBox(height: 10),
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
