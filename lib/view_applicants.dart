import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ViewApplicantsPage extends StatelessWidget {
  final BuildContext context;

  const ViewApplicantsPage({Key? key, required this.context}) : super(key: key);

  Future<List<String>> getPdfFiles(String folder) async {
    final ListResult result =
        await FirebaseStorage.instance.ref().child(folder).listAll();
    return result.items.map((item) => item.name).toList();
  }

  Future<String> getPdfUrl(String folder, String fileName) async {
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
    return await ref.getDownloadURL();
  }

  void openPDF(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Applicants'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () async {
                List<String> pdfFiles = await getPdfFiles('resumes');
                showDialog(
                  context: this.context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text('Resume'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: pdfFiles.map((pdfFile) {
                          return ListTile(
                            title: Text(pdfFile),
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              String url = await getPdfUrl('resumes', pdfFile);
                              openPDF(url);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
              child: Text('Resume'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                List<String> pdfFiles = await getPdfFiles('sop');
                showDialog(
                  context: this.context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text('SOP'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: pdfFiles.map((pdfFile) {
                          return ListTile(
                            title: Text(pdfFile),
                            onTap: () async {
                              Navigator.pop(dialogContext);
                              String url = await getPdfUrl('sop', pdfFile);
                              openPDF(url);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
              child: Text('SOP'),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage example:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return ViewApplicantsPage(
              context: context,
            );
          },
        ),
      ),
    );
  }
}
