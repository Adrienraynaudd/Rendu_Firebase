import 'package:flutter/material.dart';

class EditNoteDialog extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final String? initialImageUrl; // Add this line
  final Function(String, String, String?) onEditNote; // Update this line

  const EditNoteDialog({
    Key? key,
    required this.initialTitle,
    required this.initialContent,
    required this.onEditNote,
    this.initialImageUrl, // Add this line
  }) : super(key: key);

  @override
  __EditNoteDialogState createState() => __EditNoteDialogState();
}

class __EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController; // Add this line
  String? _editNoteError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _imageUrlController =
        TextEditingController(text: widget.initialImageUrl); // Add this line
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Note'),
      content: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Enter the title of the note',
            ),
          ),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              hintText: 'Enter the content of the note',
            ),
          ),
          TextField(
            // Add this section
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              hintText: 'Enter the URL of the image',
            ),
          ),
          if (_editNoteError != null)
            Text(
              _editNoteError!,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final newTitle = _titleController.text.trim();
            final newContent = _contentController.text.trim();
            final newImageUrl =
                _imageUrlController.text.trim(); // Add this line

            if (newTitle.isEmpty) {
              setState(() {
                _editNoteError = 'Title cannot be empty';
              });
            } else {
              // Call the onEditNote function provided by the parent with the image URL
              final error =
                  await widget.onEditNote(newTitle, newContent, newImageUrl);

              if (error != null) {
                // If there is an error, display it
                setState(() {
                  _editNoteError = error;
                });
              } else {
                // If there is no error, reset the error and close the dialog
                setState(() {
                  _editNoteError = null;
                });
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
