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
      home: function6(),
    );
  }
}

class function6 extends StatefulWidget {
  @override
  _Function6State createState() => _Function6State();
}

class _Function6State extends State<function6> {
  TextEditingController extController1 = TextEditingController();
  TextEditingController extController2 = TextEditingController();
  TextEditingController domainController = TextEditingController();
  List<String> qrCodes = [];
  String apiResponse = '';

  Future<void> fetchData() async {
    int ext1 = int.parse(extController1.text);
    int ext2 = int.parse(extController2.text);
    String domain = domainController.text;

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

    // Generate CSV after fetching all data and removing duplicates
    generateCSV();

    // Reset all variables after generating CSV
    extController1.clear();
    extController2.clear();
    domainController.clear();
    qrCodes.clear();
    apiResponse = '';
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

  void generateCSV() {
    List<String> header = ['Extension', 'Image URL'];
    List<List<String>> data = qrCodes
        .map((url) =>
            ['${qrCodes.indexOf(url) + int.parse(extController1.text)}', url])
        .toList();

    exportCSV.myCSV(header, data, fileName: 'QR_Codes', fileTimeStamp: "");

    // Reset all variables after generating CSV
    setState(() {
      extController1.clear();
      extController2.clear();
      domainController.clear();
      qrCodes.clear();
      apiResponse = '';
    });
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
            ],
          ),
        ),
      ),
    );
  }
}
