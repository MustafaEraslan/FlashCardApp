import 'package:flutter/foundation.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/isar_service.dart';
import '../services/sm2_service.dart';

class DeckProvider extends ChangeNotifier {
  List<Deck> _decks = [];
  List<Deck> get decks => _decks;

  Future<void> loadDecks() async {
    _decks = await IsarService.getAllDecks();
    for (final deck in _decks) {
      await deck.cards.load();
    }
    notifyListeners();
  }

  Future<void> addDeck(String name, String description) async {
    final deck = Deck()
      ..name = name
      ..description = description
      ..createdAt = DateTime.now();
    await IsarService.saveDeck(deck);
    await loadDecks();
  }

  Future<void> deleteDeck(int id) async {
    await IsarService.deleteDeck(id);
    await loadDecks();
  }

  Future<List<Flashcard>> getCardsForDeck(int deckId) async {
    return IsarService.getCardsForDeck(deckId);
  }

  Future<List<Flashcard>> getDueCards(int deckId) async {
    return IsarService.getDueCardsForDeck(deckId);
  }

  Future<void> addCard(int deckId, String front, String back, String? example) async {
    final card = Flashcard()
      ..front = front
      ..back = back
      ..example = example;
    await IsarService.saveCard(card, deckId);
    await loadDecks();
  }

  Future<void> deleteCard(int cardId) async {
    await IsarService.deleteCard(cardId);
    await loadDecks();
  }

  Future<void> reviewCard(Flashcard card, ReviewRating rating) async {
    SM2Service.applyReview(card, rating);
    await IsarService.updateCard(card);
  }
}
