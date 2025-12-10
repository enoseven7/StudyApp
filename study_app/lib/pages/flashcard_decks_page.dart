import 'package:flutter/material.dart';
import '../models/flashcard_deck.dart';
import '../models/topic.dart';
import '../services/flashcard_service.dart';
import '../pages/flashcard_editor_page.dart';

class FlashcardDecksPage extends StatefulWidget {
  final Topic topic;

  const FlashcardDecksPage({super.key, required this.topic});

  @override
  State<FlashcardDecksPage> createState() => _FlashcardDecksPageState();
}

class _FlashcardDecksPageState extends State<FlashcardDecksPage> {
  List<FlashcardDeck> decks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    decks = await flashcardService.getDecksByTopic(widget.topic.id);
    setState(() {});
  }

  void _addDeck() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("New Deck"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            child: Text("Add"),
            onPressed: () async {
              if (c.text.isNotEmpty) {
                await flashcardService.createDeck(widget.topic.id, c.text);
                await _load();
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flashcards – ${widget.topic.name}"),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _addDeck),
        ],
      ),
      body: ListView.builder(
        itemCount: decks.length,
        itemBuilder: (_, i) {
          final deck = decks[i];
          return ListTile(
            title: Text(deck.name),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardsEditorPage(deck: deck),
              ),
            ),
          );
        },
      ),
    );
  }
}
