import 'package:isar/isar.dart';

part 'flashcard_deck.g.dart';

@collection
class FlashcardDeck {
  Id id = Isar.autoIncrement;

  late int topicId;   // Link to topic

  @Index(caseSensitive: false)
  late String name;
}