import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:study_app/services/note_service.dart';
import '../models/note.dart';
import 'package:flutter_quill/flutter_quill.dart';


class NoteEditorPage extends StatefulWidget {
  final Note note;
  final Future<void> Function(Note) onSave;

  const NoteEditorPage({super.key, required this.note, required this.onSave});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    final doc = widget.note.content.isEmpty
        ? Document()
        : Document.fromJson(jsonDecode(widget.note.content));
    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _save() async {
    widget.note.content = jsonEncode(_controller.document.toDelta().toJson());
    await noteService.updateNote(widget.note);
    await widget.onSave(widget.note);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Note"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            QuillSimpleToolbar(controller: _controller),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: QuillEditor.basic(
                  controller: _controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
