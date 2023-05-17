import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_applicants.dart';
import 'login.dart';

class Teacher extends StatefulWidget {
  const Teacher({Key? key}) : super(key: key);

  @override
  State<Teacher> createState() => _TeacherState();
}

class _TeacherState extends State<Teacher> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _infoController = TextEditingController();
  TextEditingController _deadlineController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _uploadGig() async {
    String title = _titleController.text;
    String information = _infoController.text;
    DateTime deadline = _selectedDate;

    if (title.isEmpty || information.isEmpty) {
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

    // Upload the gig information to Firestore
    CollectionReference gigsCollection =
        FirebaseFirestore.instance.collection('gigs');
    DocumentReference document = await gigsCollection.add({
      'title': title,
      'information': information,
      'deadline': deadline,
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Gig uploaded successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _titleController.clear();
                _infoController.clear();
                _deadlineController.clear();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _deadlineController.text = pickedDate.toString();
      });
    }
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

  Future<void> _viewApplicants(String gigId) async {
    DocumentSnapshot gigSnapshot =
        await FirebaseFirestore.instance.collection('gigs').doc(gigId).get();

    if (gigSnapshot.exists) {
      //applicants = gigSnapshot.data()!['applicants'] as List<dynamic>?;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewApplicantsPage(
            context: context,
            //applicants: applicants,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Gig not found.'),
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
        backgroundColor: Colors.black,
        elevation: 10,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "MentorMe (Recruiter)",
            style: TextStyle(
              fontSize: 22,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('gigs').snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('No gigs available');
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final gig = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>?;
                      final gigId = snapshot.data!.docs[index].id;

                      if (gig == null) {
                        return SizedBox
                            .shrink(); // Return an empty widget if gig data is null
                      }

                      final title = gig['title'] ?? '';
                      final information = gig['information'] ?? '';
                      final deadline =
                          gig['deadline']?.toDate().toString() ?? '';

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
                              IconButton(
                                icon: Icon(Icons.people),
                                onPressed: () {
                                  _viewApplicants(gigId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Upload Gig'),
                content: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                      ),
                    ),
                    TextField(
                      controller: _infoController,
                      decoration: InputDecoration(
                        labelText: 'Information',
                      ),
                    ),
                    TextField(
                      controller: _deadlineController,
                      decoration: InputDecoration(
                        labelText: 'Deadline',
                      ),
                      onTap: () {
                        _selectDate(context);
                      },
                      readOnly: true,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _uploadGig();
                    },
                    child: Text('Upload'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class UploadGigPage extends StatefulWidget {
  @override
  _UploadGigPageState createState() => _UploadGigPageState();
}

class _UploadGigPageState extends State<UploadGigPage> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _infoController = TextEditingController();
  TextEditingController _deadlineController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _uploadGig() async {
    String title = _titleController.text;
    String information = _infoController.text;
    DateTime deadline = _selectedDate;
    if (title.isEmpty || information.isEmpty) {
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

// Upload the gig information to Firestore
    CollectionReference gigsCollection =
        FirebaseFirestore.instance.collection('gigs');
    DocumentReference document = await gigsCollection.add({
      'title': title,
      'information': information,
      'deadline': deadline,
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Gig uploaded successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                _titleController.clear();
                _infoController.clear();
                _deadlineController.clear();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _deadlineController.text = pickedDate.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Gig'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextFormField(
              controller: _infoController,
              decoration: InputDecoration(labelText: 'Information'),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: IgnorePointer(
                child: TextFormField(
                  controller: _deadlineController,
                  decoration: InputDecoration(
                    labelText: 'Deadline',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _uploadGig,
              child: Text('Upload Gig'),
            ),
          ],
        ),
      ),
    );
  }
}
