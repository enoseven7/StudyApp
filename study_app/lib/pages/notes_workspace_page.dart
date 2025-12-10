import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../models/topic.dart';

import '../pages/subjects_panel.dart';
import '../pages/topics_panel.dart';
import '../pages/note_editor_area.dart';

import '../services/subject_services.dart';
import '../services/topic_service.dart';

class NotesWorkspacePage extends StatefulWidget {
  const NotesWorkspacePage({super.key});

  @override
  State<NotesWorkspacePage> createState() => _NotesWorkspacePageState();
}

class _NotesWorkspacePageState extends State<NotesWorkspacePage> {
  List<Subject> subjects = [];
  List<Topic> topics = [];

  int selectedSubject = 0;
  int selectedTopic = 0;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    subjects = await subjectService.getSubjects();
    if (subjects.isNotEmpty) {
      selectedSubject = 0;
      await _loadTopics(subjects[0].id);
    } else {
      topics = [];
      selectedSubject = 0;
      selectedTopic = 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTopics(int subjectId) async {
    topics = await topicService.getTopicsForSubject(subjectId);
    selectedTopic = 0;
    if (mounted) setState(() {});
  }

  Future<void> _addSubject() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Subject"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter subject name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await subjectService.addSubject(name);
                await _loadSubjects();
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _addTopic() async {
    if (subjects.isEmpty) return;

    final controller = TextEditingController();
    final subjectId = subjects[selectedSubject].id;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Topic"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter topic name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await topicService.addTopic(subjectId, name);
                await _loadTopics(subjectId);
              }
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSubjectId = (subjects.isNotEmpty && selectedSubject < subjects.length)
        ? subjects[selectedSubject].id
        : 0;
    final currentTopicId = (topics.isNotEmpty && selectedTopic < topics.length)
        ? topics[selectedTopic].id
        : 0;

    return Row(
      children: [
        SizedBox(
          width: 150,
          child: SubjectsPanel(
            subjects: subjects,
            selectedIndex: selectedSubject,
            addSubject: _addSubject,
            onSelect: (i) async {
              setState(() {
                selectedSubject = i;
                selectedTopic = 0;
                topics = [];
              });
              await _loadTopics(subjects[i].id);
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: TopicsPanel(
            topics: topics,
            subjectId: currentSubjectId,
            selectedIndex: selectedTopic,
            addTopic: _addTopic,
            onSelect: (i) {
              if (i >= topics.length) return;
              setState(() {
                selectedTopic = i;
              });
            },
          ),
        ),
        Expanded(
          child: NoteEditorArea(
            subjectId: currentSubjectId,
            topicId: currentTopicId,
          ),
        )
      ],
    );
  }
}
