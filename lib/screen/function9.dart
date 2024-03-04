import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:to_csv/to_csv.dart' as exportCSV;
import 'package:image_gallery_saver/image_gallery_saver.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: function9(),
    );
  }
}

class function9 extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<function9> {
  TextEditingController extController = TextEditingController();
  TextEditingController domainController = TextEditingController();
  String apiResponse = '';
  String? extractedImgUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Flutter App'),
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
                fetchData();
              },
              child: Text('Fetch Data from API'),
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
                extractedImgUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (extractedImgUrl != null) {
                  _saveNetworkImage(extractedImgUrl!);
                }
              },
              child: Text('Download Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                generateCSV(extController.text, extractedImgUrl);
              },
              child: Text('Export to CSV and Download'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchData() async {
    String ext = extController.text;
    String domain = domainController.text;
    String url = 'https://10.16.1.213/backend/crp2.php?ext=$ext&domain=$domain';

    var response = await http.get(Uri.parse(url));
    setState(() {
      apiResponse = response.body;
      extractedImgUrl = newCustomFunction(apiResponse);
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
        return "https://10.16.1.213/backend/$imageUrl";
      }
    }
    return null;
  }

  Future<void> _saveNetworkImage(String imageUrl) async {
    var response = await http.get(Uri.parse(imageUrl));
    final result = await ImageGallerySaver.saveImage(
      Uint8List.fromList(response.bodyBytes),
      quality: 60,
      name: "hello",
    );
    print(result);
  }

  void generateCSV(String ext, String? imgUrl) {
    List<String> header = ['Extension', 'Image URL'];
    List<List<String>> data = [
      [ext, imgUrl ?? '']
    ];
    exportCSV.myCSV(header, data, fileName: 'LMAO', fileTimeStamp: "");
  }
}
