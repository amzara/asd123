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
      home: function7(),
    );
  }
}

class function7 extends StatefulWidget {
  @override
  _Function3State createState() => _Function3State();
}

class _Function3State extends State<function7> {
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

  void addExtension() {
    int extension = int.tryParse(extController.text) ?? 0;
    if (extension != 0) {
      setState(() {
        selectedExtensions.add(extension);
      });
      extController.clear();
    }
  }

  void generateCSV() async {
    // Wait for all fetch operations to complete
    await Future.wait(selectedExtensions
        .map((extension) => fetchData(extension, domainController.text)));

    List<String> header = ['Extension', 'Image URL'];
    List<List<String>> data = [];

    // Generate CSV data using fetched QR codes
    for (int extension in selectedExtensions) {
      String qrCode = qrCodes[selectedExtensions.indexOf(extension)];
      data.add(['$extension', qrCode]);
    }

    exportCSV.myCSV(header, data, fileName: 'QR_Codes', fileTimeStamp: "");

    // Reset all variables after generating CSV
    setState(() {
      selectedExtensions.clear();
      qrCodes.clear();
      apiResponse = '';
      extController.clear();
      domainController.clear();
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
                onPressed: generateCSV,
                child: Text('Generate QR Codes CSV'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
