import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

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

class AddNoteDialog extends StatefulWidget {
  final Function(String, String, PlatformFile?, String?) onAddNote;

  const AddNoteDialog({Key? key, required this.onAddNote}) : super(key: key);

  @override
  __AddNoteDialogState createState() => __AddNoteDialogState();
}

class __AddNoteDialogState extends State<AddNoteDialog> {
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
