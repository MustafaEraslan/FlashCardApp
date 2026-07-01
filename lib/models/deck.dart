import 'package:isar/isar.dart';
import 'flashcard.dart';

part 'deck.g.dart';

@Collection()
class Deck {
  Id id = Isar.autoIncrement;

  late String name;
  String description = '';
  late DateTime createdAt;

  @Backlink(to: 'deck')
  final cards = IsarLinks<Flashcard>();

  int get totalCards => cards.length;
}
