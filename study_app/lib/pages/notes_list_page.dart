import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../models/note.dart';
import 'note_editor_page.dart';
import '../services/note_service.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' show Document;

class NotesListPage extends StatefulWidget {
  final Topic topic;

  const NotesListPage({super.key, required this.topic});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _showNoteMenu(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit"),
                onTap: () {
                  Navigator.pop(context);
                  _openNote(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await noteService.deleteNote(note.id);
                  await _loadNotes();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(
          note: Note()
            ..topicId = widget.topic.id
            ..content = "",
          onSave: (newNote) async {
            await noteService.addNote(newNote.topicId, newNote.content);
            await _loadNotes();
          },
        ),
      ),
    );
  }

  void _openNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(
          note: note,
          onSave: (updated) async {
            await noteService.updateNote(updated);
            await _loadNotes();
          },
        ),
      ),
    );
  }

  String _getNotePreviewLine(Note note) {
    if (note.content.isEmpty) return "(Empty note)";

    try {
      final preview = Document.fromJson(jsonDecode(note.content)).toPlainText().trim();

      if (preview.isEmpty) return "(Empty note)";
      return preview.split('\n').first;
    } catch (_) {
      return "(Invalid note data)";
    }
  }

  String _getNotePreviewParagraph(Note note) {
    try {
      final preview = Document.fromJson(jsonDecode(note.content)).toPlainText().trim();

      if (preview.isEmpty) return "";
      if (preview.length <= 50) return preview;

      return "${preview.substring(0, 50)}...";
    } catch (_) {
      return "";
    }
  }

  Future<void> _loadNotes() async {
    notes = await noteService.getNotesForTopic(widget.topic.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
      body: notes.isEmpty
          ? const Center(child: Text("No notes yet. Add one!"))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];

                return ListTile(
                  leading: const Icon(Icons.note_alt),
                  title: Text(
                    _getNotePreviewLine(note),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  subtitle: Text(
                    _getNotePreviewParagraph(note),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  onTap: () => _openNote(note),
                  onLongPress: () => _showNoteMenu(note),
                );
              },
            ),
    );
  }
}

