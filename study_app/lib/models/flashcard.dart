import 'package:isar/isar.dart';

part 'flashcard.g.dart';

@collection 
class Flashcard {
  Id id = Isar.autoIncrement;

  late int deckId;   // Link to flashcard deck

  @Index(caseSensitive: false)
  late String front;

  @Index(caseSensitive: false)
  late String back;

  /// Timestamp (msSinceEpoch) of last review.
  late int lastReviewed;

  /// Next due date (msSinceEpoch). 0 means new/unseen.
  late int dueAt;

  /// SM-2 style scheduling state.
  late int intervalDays;
  late double easeFactor;
  late int repetitions;
  late int lapses;

  /// Optional attachments (local file paths).
  String? imagePath;
  String? audioPath;
  bool imageOnFront = false;
  bool audioOnFront = false;
}
