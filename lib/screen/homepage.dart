import 'package:flutter/material.dart';
import 'function1.dart'; // Import the function1 page
import 'function2.dart'; // Import the function2 page
import 'function3.dart'; // Import the function3 page
import 'function4.dart'; // Import the function4 page
import 'function5.dart'; // Import the function5 page.
import 'function6.dart'; // Import csvpractice page
import 'function7.dart';
import 'function8.dart';
import 'function9.dart';
import 'pdf.dart';
import 'singleQR.dart';
import 'rangeQR.dart';
import 'targetQR.dart';
import 'csvQR.dart';
import 'mergeSingle.dart';
import 'mergeRange.dart';
import 'mergeTarget.dart';

class homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Generator'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://images.unsplash.com/photo-1508385082359-f38ae991e8f2?q=80&w=1000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTR8fGNvcnBvcmF0ZSUyMGJhY2tncm91bmR8ZW58MHx8MHx8fDA%3D'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DotDash Technologies',
                style: TextStyle(
                  fontSize: 30.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40), // Add space between the text and buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => mergeSingle()),
                          );
                        },
                        child: Text('Single'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => mergeRange()),
                          );
                        },
                        child: Text('Number Range'),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => mergeTarget()),
                          );
                        },
                        child: Text('Multiple'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => function4()),
                          );
                        },
                        child: Text('Generate from CSV'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
