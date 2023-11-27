import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editNote.dart';

class FirestorePage extends StatefulWidget {
  @override
  _FirestorePageState createState() => _FirestorePageState();
}

class _FirestorePageState extends State<FirestorePage> {
  final storage = FirebaseStorage.instance;
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('notes');
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

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
                    _showEditNoteDialog(
                        document.id, data['title'], data['content']);
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
              return _AddNoteDialog(
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

  void _showEditNoteDialog(
      String documentId, String currentTitle, String currentContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditNoteDialog(
          initialTitle: currentTitle,
          initialContent: currentContent,
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

class NoteTile extends StatelessWidget {
  final String title;
  final String content;
  final String? imageUrl;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;

  const NoteTile({
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.isSelected,
    required this.onChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(content),
      leading: imageUrl != null
          ? Image.network(imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: onChanged,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final Function(String, String, PlatformFile?, String?) onAddNote;

  const _AddNoteDialog({Key? key, required this.onAddNote}) : super(key: key);

  @override
  __AddNoteDialogState createState() => __AddNoteDialogState();
}

class __AddNoteDialogState extends State<_AddNoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _addNoteError;
  PlatformFile? selectedFile;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add a new note'),
      content: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'Enter the title of the note',
            ),
          ),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: 'Content',
              hintText: 'Enter the content of the note',
            ),
          ),
          ElevatedButton(
            onPressed: selectFile,
            child: Text('Select Image'),
          ),
          if (selectedFile != null)
            Expanded(
              child: Container(
                child: Image.memory(
                  selectedFile!.bytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (_addNoteError != null)
            Text(
              _addNoteError!,
              style: TextStyle(color: Colors.red),
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
          onPressed: () async {
            final title = _titleController.text.trim();
            final content = _contentController.text.trim();

            if (title.isEmpty) {
              setState(() {
                _addNoteError = 'Title cannot be empty';
              });
            } else if (selectedFile == null) {
              setState(() {
                _addNoteError = 'Please select an image';
              });
            } else {
              // Upload the file to Firebase Storage
              final path = 'notes/${selectedFile!.name}';
              final ref = FirebaseStorage.instance.ref().child(path);
              final uploadTask = ref.putData(selectedFile!.bytes!);

              // Wait for the upload to complete
              await uploadTask.whenComplete(() async {
                // Get the download URL of the uploaded file
                final imageUrl = await ref.getDownloadURL();

                // Call the onAddNote function provided by the parent
                final user = FirebaseAuth.instance.currentUser;
                final userEmail = user?.email;
                final error = await widget.onAddNote(
                    title, content, selectedFile, userEmail);

                if (error != null) {
                  // If there is an error, display it
                  setState(() {
                    _addNoteError = error;
                  });
                } else {
                  // If there is no error, reset the error and close the dialog
                  setState(() {
                    _addNoteError = null;
                  });
                  Navigator.of(context).pop();
                }
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;
    setState(() {
      selectedFile = result.files.first;
    });
  }
}
