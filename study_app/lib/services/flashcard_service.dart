import 'package:isar/isar.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard.dart';
import '../main.dart';

class FlashcardService {

  FlashcardService();

  Future<List<FlashcardDeck>> getDecksByTopic(int topicId) async {
    return await isar.flashcardDecks
        .filter()
        .topicIdEqualTo(topicId)
        .findAll();
  }

  Future<int> createDeck(int topicId, String name) async {
    final deck = FlashcardDeck()
      ..topicId = topicId
      ..name = name;
    return await isar.writeTxn(() async {
      return await isar.flashcardDecks.put(deck);
    });
  }

  Future<void> deleteDeck(int deckId) async {
    await isar.writeTxn(() async {
      await isar.flashcards.filter().deckIdEqualTo(deckId).deleteAll();
      await isar.flashcardDecks.delete(deckId);
    });
  }

  Future<List<Flashcard>> getFlashcardsByDeck(int deckId) async {
    return await isar.flashcards
        .filter()
        .deckIdEqualTo(deckId)
        .findAll();
  }

  Future<int> createFlashcard(
    int deckId,
    String front,
    String back, {
    String? imagePath,
    String? audioPath,
    bool imageOnFront = false,
    bool audioOnFront = false,
  }) async {
    final flashcard = Flashcard()
      ..deckId = deckId
      ..front = front
      ..back = back
      ..imagePath = imagePath
      ..audioPath = audioPath
      ..imageOnFront = imageOnFront
      ..audioOnFront = audioOnFront
      ..lastReviewed = 0
      ..dueAt = 0
      ..intervalDays = 0
      ..easeFactor = 2.5
      ..repetitions = 0
      ..lapses = 0;
    return await isar.writeTxn(() async {
      return await isar.flashcards.put(flashcard);
    });
  }

  Future<void> deleteFlashcard(int flashcardId) async {
    await isar.writeTxn(() async {
      await isar.flashcards.delete(flashcardId);
    });
  }

  Future<void> updateFlashcard(
    int flashcardId, {
    String? front,
    String? back,
    String? imagePath,
    String? audioPath,
    bool? imageOnFront,
    bool? audioOnFront,
  }) async {
    final flashcard = await isar.flashcards.get(flashcardId);
    if (flashcard != null) {
      if (front != null) flashcard.front = front;
      if (back != null) flashcard.back = back;
      flashcard.imagePath = imagePath ?? flashcard.imagePath;
      flashcard.audioPath = audioPath ?? flashcard.audioPath;
      if (imageOnFront != null) flashcard.imageOnFront = imageOnFront;
      if (audioOnFront != null) flashcard.audioOnFront = audioOnFront;
      await isar.writeTxn(() async {
        await isar.flashcards.put(flashcard);
      });
    }
  }

  /// Simple SM-2 inspired review scheduler.
  Future<Flashcard?> reviewFlashcard(int flashcardId, int quality) async {
    final card = await isar.flashcards.get(flashcardId);
    if (card == null) return null;

    final now = DateTime.now();
    final clamped = quality.clamp(0, 4);
    final isEasy = clamped == 4;

    if (clamped < 2) {
      // Again / Hard miss: reset interval and ease lightly decreases.
      card.repetitions = 0;
      card.intervalDays = 0;
      card.lapses += 1;
      card.easeFactor = (card.easeFactor - 0.2).clamp(1.3, 2.8);
    } else {
      card.repetitions += 1;
      final efDelta = (clamped == 2)
          ? -0.05 // hard but passed
          : (clamped == 3 ? 0.1 : 0.2); // good/easy
      card.easeFactor = (card.easeFactor + efDelta).clamp(1.3, 2.8);

      if (card.repetitions == 1) {
        card.intervalDays = 1;
      } else if (card.repetitions == 2) {
        card.intervalDays = 3;
      } else {
        var next = (card.intervalDays * card.easeFactor).round();
        if (isEasy) {
          next = (next * 1.2).round();
        }
        card.intervalDays = next;
      }
    }

    card.lastReviewed = now.millisecondsSinceEpoch;
    card.dueAt = now.add(Duration(days: card.intervalDays)).millisecondsSinceEpoch;

    await isar.writeTxn(() async {
      await isar.flashcards.put(card);
    });
    return card;
  }
}

final flashcardService = FlashcardService();
