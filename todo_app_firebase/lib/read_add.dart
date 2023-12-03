import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editNote.dart';
import 'add.dart';

class FirestorePage extends StatefulWidget {
  @override
  _FirestorePageState createState() => _FirestorePageState();
}

class _FirestorePageState extends State<FirestorePage> {
  final storage = FirebaseStorage.instance;
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('notes');

  // A map to store the selected state of each note
  Map<String, bool> selectedNotes = {};
  List<QueryDocumentSnapshot> documents = [];

  @override
  void initState() {
    super.initState();
    // Load the initial set of documents when the widget is first created
    _loadDocuments();
  }

  // Function to load the documents from Firestore
  Future<void> _loadDocuments() async {
    // Get the current user's email
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    // Check if the user is logged in
    if (userEmail != null) {
      // Use a query to filter notes based on the user's email
      QuerySnapshot querySnapshot =
          await notes.where('userEmail', isEqualTo: userEmail).get();

      setState(() {
        documents = querySnapshot.docs;
      });
    }
  }

  Future<void> _deleteImage(String imagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref(imagePath);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = documents[index];
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;

                return NoteTile(
                  title: data['title'],
                  content: data['content'],
                  imageUrl: data['imageUrl'],
                  isSelected: selectedNotes.containsKey(document.id)
                      ? selectedNotes[document.id]!
                      : false,
                  onChanged: (bool? value) {
                    setState(() {
                      selectedNotes[document.id] = value ?? false;
                    });
                  },
                  onEdit: () {
                    _showEditNoteDialog(document.id, data['title'],
                        data['content'], data['imageUrl']);
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Delete selected notes
              for (var entry in selectedNotes.entries) {
                if (entry.value) {
                  // Delete the image from Firebase Storage
                  final data = (documents
                      .firstWhere((doc) => doc.id == entry.key)
                      ?.data() as Map<String, dynamic>?);
                  final imagePath = data?['imagePath'];

                  if (imagePath != null) {
                    await _deleteImage(imagePath);
                  }

                  // Delete the note from Firestore
                  await notes.doc(entry.key).delete();
                }
              }

              // Clear the selected notes map
              selectedNotes.clear();

              // Update the list of documents
              _loadDocuments();
            },
            child: Text('Delete Selected Notes'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show a dialog to enter details for the new note
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddNoteDialog(
                onAddNote: (String title, String content,
                    PlatformFile? selectedFile, String? userEmail) async {
                  try {
                    if (selectedFile != null) {
                      // Upload the file to Firebase Storage
                      final path = 'notes/${selectedFile.name}';
                      final ref = FirebaseStorage.instance.ref().child(path);
                      final uploadTask = ref.putData(selectedFile.bytes!);
                      final imageUrl =
                          await uploadTask.snapshot.ref.getDownloadURL();

                      // Add the new note to the database with the image URL and user email
                      await notes.add({
                        'title': title,
                        'content': content,
                        'imageUrl': imageUrl,
                        'userEmail': userEmail,
                      });
                    } else {
                      // Add the new note to the database without an image
                      await notes.add({
                        'title': title,
                        'content': content,
                        'userEmail': userEmail,
                      });
                    }

                    // Update the list of documents
                    _loadDocuments();
                  } catch (e) {
                    // Handle errors when adding notes
                    return 'Error adding note: $e';
                  }
                  return null;
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showEditNoteDialog(String documentId, String currentTitle,
      String currentContent, String? currentImageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditNoteDialog(
          initialTitle: currentTitle,
          initialContent: currentContent,
          initialImageUrl: currentImageUrl,
          onEditNote:
              (String newTitle, String newContent, String? newImageUrl) async {
            try {
              // Update the note in the database
              await notes.doc(documentId).update({
                'title': newTitle,
                'content': newContent,
                'imageUrl':
                    newImageUrl, // Assuming 'imageUrl' is the field for the image URL
              });

              // Update the list of documents
              _loadDocuments();
            } catch (e) {
              // Handle errors when editing the note
              return 'Error editing note: $e';
            }
            return null;
          },
        );
      },
    );
  }
}
