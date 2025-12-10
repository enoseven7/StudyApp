import 'package:flutter/material.dart';

import '../models/flashcard_deck.dart';
import '../models/subject.dart';
import '../models/topic.dart';

import '../pages/flashcard_editor_page.dart';
import '../pages/flashcard_review_page.dart';
import '../pages/subjects_panel.dart';
import '../pages/topics_panel.dart';

import '../services/flashcard_service.dart';
import '../services/subject_services.dart';
import '../services/topic_service.dart';

class FlashcardHomePage extends StatefulWidget {
  const FlashcardHomePage({super.key});

  @override
  State<FlashcardHomePage> createState() => _FlashcardHomePageState();
}

class _FlashcardHomePageState extends State<FlashcardHomePage> {
  List<Subject> subjects = [];
  List<Topic> topics = [];
  List<FlashcardDeck> decks = [];

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
      decks = [];
      selectedSubject = 0;
      selectedTopic = 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadTopics(int subjectId) async {
    topics = await topicService.getTopicsForSubject(subjectId);
    if (topics.isNotEmpty) {
      selectedTopic = 0;
      await _loadDecks(topics[0].id);
    } else {
      selectedTopic = 0;
      decks = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadDecks(int topicId) async {
    if (topicId == 0) {
      decks = [];
    } else {
      decks = await flashcardService.getDecksByTopic(topicId);
    }
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

  Future<void> _addDeck() async {
    if (topics.isEmpty || selectedTopic >= topics.length) return;

    final controller = TextEditingController();
    final topicId = topics[selectedTopic].id;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Deck"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter deck name"),
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
                final newDeckId = await flashcardService.createDeck(topicId, name);
                await _loadDecks(topicId);
                final newDeck = decks.firstWhere(
                  (d) => d.id == newDeckId,
                  orElse: () => FlashcardDeck()
                    ..id = newDeckId
                    ..topicId = topicId
                    ..name = name,
                );
                if (!mounted) return;
                Navigator.pop(context);
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlashcardsEditorPage(deck: newDeck),
                  ),
                );
                await _loadDecks(topicId);
                return;
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

  Future<void> _deleteDeck(FlashcardDeck deck) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete deck?"),
        content: Text(
          "All cards in \"${deck.name}\" will be removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      await flashcardService.deleteDeck(deck.id);
      await _loadDecks(deck.topicId);
    }
  }

  Widget _buildDecksList(int currentTopicId) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (currentTopicId == 0) {
      return const Center(child: Text("Select a topic to see its decks."));
    }

    if (decks.isEmpty) {
      return const Center(child: Text("No decks yet. Add one to start."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: decks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final deck = decks[i];
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.onSurface.withOpacity(0.08)),
          ),
          child: ListTile(
            title: Text(
              deck.name,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              "Deck ID: ${deck.id}",
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Review",
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardReviewPage(deck: deck),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Edit",
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardsEditorPage(deck: deck),
                    ),
                  ).then((_) => _loadDecks(deck.topicId)),
                ),
                IconButton(
                  tooltip: "Delete",
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteDeck(deck),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardsEditorPage(deck: deck),
              ),
            ).then((_) => _loadDecks(deck.topicId)),
          ),
        );
      },
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

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  decks = [];
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
              onSelect: (i) async {
                if (i >= topics.length) return;
                setState(() {
                  selectedTopic = i;
                  decks = [];
                });
                await _loadDecks(topics[i].id);
              },
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.onSurface.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        "Decks",
                        style: textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: currentTopicId == 0 ? null : _addDeck,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("New Deck"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildDecksList(currentTopicId)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
