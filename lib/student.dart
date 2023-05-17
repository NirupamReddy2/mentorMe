import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'login.dart';

class Student extends StatefulWidget {
  const Student({Key? key}) : super(key: key);

  @override
  State<Student> createState() => _StudentState();
}

class _StudentState extends State<Student> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _resumeController = TextEditingController();
  TextEditingController _sopController = TextEditingController();

  Set<String> appliedGigIds = {};

  Future<void> _applyToGig(String gigId) async {
    String name = _nameController.text;
    String email = _emailController.text;
    String resumePath = _resumeController.text;
    String sopPath = _sopController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        resumePath.isEmpty ||
        sopPath.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill in all the fields.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Upload resume and sop files to Firebase Storage
    File resumeFile = File(resumePath);
    File sopFile = File(sopPath);
    String resumeUrl = await _uploadFile(resumeFile);
    String sopUrl = await _uploadFile(sopFile);

    // Add application to Firestore
    CollectionReference applicationsCollection =
        FirebaseFirestore.instance.collection('applications');
    DocumentReference applicationDocument = await applicationsCollection.add({
      'gigId': gigId,
      'name': name,
      'email': email,
      'resumeUrl': resumeUrl,
      'sopUrl': sopUrl,
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Application submitted successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _nameController.clear();
                _emailController.clear();
                _resumeController.clear();
                _sopController.clear();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _uploadFile(File file) async {
    String fileName = file.path.split('/').last;
    Reference ref = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 10,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "MentorMe (Student)",
            style: TextStyle(
              fontSize: 25,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 5, 10, 0),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.account_circle_sharp,
                size: 35,
              ),
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('gigs').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          List<QueryDocumentSnapshot> gigs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: gigs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot gig = gigs[index];
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gig['title'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        gig['information'],
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Deadline: ${gig['deadline'].toDate().toString()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // Background color
                          ),
                          onPressed: appliedGigIds.contains(gig.id)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ApplyPage(gigId: gig.id),
                                    ),
                                  ).then((applied) {
                                    if (applied) {
                                      setState(() {
                                        appliedGigIds.add(gig.id);
                                      });
                                    }
                                  });
                                },
                          child: Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ApplyPage extends StatefulWidget {
  final String gigId;

  ApplyPage({required this.gigId});

  @override
  _ApplyPageState createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  File? _resumeFile;
  File? _sopFile;

  Future<void> _pickResumeFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickSOPFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _sopFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadDataToFirebase() async {
    String gigId = widget.gigId;
    String name = _nameController.text;
    String email = _emailController.text;

    if (_resumeFile == null ||
        _sopFile == null ||
        name.isEmpty ||
        email.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'Please fill in all the fields and select both resume and SOP PDF files.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }


    // Upload resume and SOP files to Firebase Storage
    try {
      Reference resumeRef = FirebaseStorage.instance.ref().child(
          'resumes/${gigId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await resumeRef.putFile(_resumeFile!);

      Reference sopRef = FirebaseStorage.instance
          .ref()
          .child('sop/${gigId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await sopRef.putFile(_sopFile!);

      String resumeUrl = await resumeRef.getDownloadURL();
      String sopUrl = await sopRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('gigs')
          .doc(gigId)
          .collection('applications')
          .add({
        'name': name,
        'email': email,
        'resumeUrl': resumeUrl,
        'sopUrl': sopUrl,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Application submitted successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
                'An error occurred while uploading the files. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Email:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Resume (PDF):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: _resumeFile != null
                          ? _resumeFile!.path
                          : 'No file chosen',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _pickResumeFile,
                  icon: Icon(Icons.folder_open),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'SOP (PDF):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText:
                          _sopFile != null ? _sopFile!.path : 'No file chosen',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _pickSOPFile,
                  icon: Icon(Icons.folder_open),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadDataToFirebase,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
