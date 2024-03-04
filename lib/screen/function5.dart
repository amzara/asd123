// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:to_csv/to_csv.dart' as exportCSV;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: function5(),
    );
  }
}

class function5 extends StatefulWidget {
  @override
  _Function1State createState() => _Function1State();
}

class _Function1State extends State<function5> {
  TextEditingController extController = TextEditingController();
  TextEditingController domainController = TextEditingController();
  double result = 0.0;
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
    });

    // Generate CSV
    generateCSV(ext, extractedImgUrl);
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

  void generateCSV(String ext, String? imgUrl) {
    List<String> header = ['Extension', 'Image URL'];
    List<List<String>> data = [
      [ext, imgUrl ?? ''] // If imgUrl is null, use an empty string
    ];

    exportCSV.myCSV(header, data, fileName: 'LMAO', fileTimeStamp: "");
  }

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
                fetchData(); // Call the method to perform the GET request
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
