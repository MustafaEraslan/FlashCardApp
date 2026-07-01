import '../models/flashcard.dart';

/// SM-2 Spaced Repetition Algorithm
class SM2Service {
  static void applyReview(Flashcard card, ReviewRating rating) {
    final q = _ratingToQuality(rating);

    if (q < 3) {
      // Failed — reset repetitions
      card.repetitions = 0;
      card.interval = 1;
    } else {
      if (card.repetitions == 0) {
        card.interval = 1;
      } else if (card.repetitions == 1) {
        card.interval = 6;
      } else {
        card.interval = (card.interval * card.easeFactor).round();
      }
      card.repetitions++;
    }

    // Update ease factor
    card.easeFactor = card.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (card.easeFactor < 1.3) card.easeFactor = 1.3;

    card.lastReview = DateTime.now();
    card.nextReview = DateTime.now().add(Duration(days: card.interval));
  }

  static int _ratingToQuality(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.again:
        return 0;
      case ReviewRating.hard:
        return 3;
      case ReviewRating.good:
        return 4;
      case ReviewRating.easy:
        return 5;
    }
  }
}
