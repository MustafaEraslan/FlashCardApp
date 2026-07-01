import 'package:isar/isar.dart';
import 'deck.dart';

part 'flashcard.g.dart';

enum ReviewRating { again, hard, good, easy }

@Collection()
class Flashcard {
  Id id = Isar.autoIncrement;

  late String front;
  late String back;
  String? example;

  // Spaced repetition fields (SM-2 algorithm)
  double easeFactor = 2.5;
  int interval = 1; // days
  int repetitions = 0;
  DateTime? nextReview;
  DateTime? lastReview;

  final deck = IsarLink<Deck>();

  bool get isDue {
    if (nextReview == null) return true;
    return nextReview!.isBefore(DateTime.now());
  }
}
