import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../pages/flashcard_review_page.dart';
import '../services/flashcard_service.dart';


class FlashcardsEditorPage extends StatefulWidget {
  final FlashcardDeck deck;

  const FlashcardsEditorPage({super.key, required this.deck});

  @override
  State<FlashcardsEditorPage> createState() => _FlashcardsEditorPageState();
}

class _FlashcardsEditorPageState extends State<FlashcardsEditorPage> {
  List<Flashcard> cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    cards = await flashcardService.getFlashcardsByDeck(widget.deck.id);
    setState(() {});
  }

  Future<String?> _pickFile({required FileType type}) async {
    final result = await FilePicker.platform.pickFiles(type: type);
    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }
    return null;
  }

  Future<void> _openCardEditor({Flashcard? card}) async {
    final isEdit = card != null;
    final front = TextEditingController(text: card?.front ?? "");
    final back = TextEditingController(text: card?.back ?? "");
    String? imagePath = card?.imagePath;
    String? audioPath = card?.audioPath;
    bool imageOnFront = card?.imageOnFront ?? false;
    bool audioOnFront = card?.audioOnFront ?? false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) {
          return AlertDialog(
            title: Text(isEdit ? "Edit Flashcard" : "New Flashcard"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: front,
                    decoration: const InputDecoration(labelText: "Front"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: back,
                    decoration: const InputDecoration(labelText: "Back"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final path = await _pickFile(type: FileType.image);
                          if (path != null) setSheet(() => imagePath = path);
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: const Text("Image"),
                      ),
                      const SizedBox(width: 8),
                      if (imagePath != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                File(imagePath!).uri.pathSegments.last,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const Text("Side: "),
                                  DropdownButton<bool>(
                                    value: imageOnFront,
                                    items: const [
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text("Back"),
                                      ),
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text("Front"),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setSheet(() => imageOnFront = val);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final path = await _pickFile(type: FileType.audio);
                          if (path != null) setSheet(() => audioPath = path);
                        },
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text("Audio"),
                      ),
                      const SizedBox(width: 8),
                      if (audioPath != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                File(audioPath!).uri.pathSegments.last,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const Text("Side: "),
                                  DropdownButton<bool>(
                                    value: audioOnFront,
                                    items: const [
                                      DropdownMenuItem(
                                        value: false,
                                        child: Text("Back"),
                                      ),
                                      DropdownMenuItem(
                                        value: true,
                                        child: Text("Front"),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setSheet(() => audioOnFront = val);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(
                child: Text(isEdit ? "Save" : "Add"),
                onPressed: () async {
                    if (isEdit) {
                      await flashcardService.updateFlashcard(
                        card!.id,
                        front: front.text,
                        back: back.text,
                        imagePath: imagePath,
                        audioPath: audioPath,
                        imageOnFront: imageOnFront,
                        audioOnFront: audioOnFront,
                      );
                    } else {
                      await flashcardService.createFlashcard(
                        widget.deck.id,
                        front.text,
                        back.text,
                        imagePath: imagePath,
                        audioPath: audioPath,
                        imageOnFront: imageOnFront,
                        audioOnFront: audioOnFront,
                      );
                    }
                  await _load();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openCardEditor()),
        ],
      ),
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final card = cards[i];
          return ListTile(
            title: Text(card.front),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.back),
                if (card.imagePath != null)
                  Text(
                    "Image: ${File(card.imagePath!).uri.pathSegments.last}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (card.audioPath != null)
                  Text(
                    "Audio: ${File(card.audioPath!).uri.pathSegments.last}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  tooltip: "Review from here",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardReviewPage(deck: widget.deck, startIndex: i),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await flashcardService.deleteFlashcard(card.id);
                    await _load();
                  },
                ),
              ],
            ),
            onTap: () => _openCardEditor(card: card),
          );
        },
      ),
    );
  }
}
