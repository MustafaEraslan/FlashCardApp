import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get db async {
    _isar ??= await _open();
    return _isar!;
  }

  static Future<Isar> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [DeckSchema, FlashcardSchema],
      directory: dir.path,
    );
  }

  // Deck operations
  static Future<List<Deck>> getAllDecks() async {
    final isar = await db;
    return isar.decks.where().findAll();
  }

  static Future<Id> saveDeck(Deck deck) async {
    final isar = await db;
    return isar.writeTxn(() async {
      return isar.decks.put(deck);
    });
  }

  static Future<void> deleteDeck(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      // Delete all cards in deck first
      final deck = await isar.decks.get(id);
      if (deck != null) {
        await deck.cards.load();
        final cardIds = deck.cards.map((c) => c.id).toList();
        await isar.flashcards.deleteAll(cardIds);
      }
      await isar.decks.delete(id);
    });
  }

  // Flashcard operations
  static Future<List<Flashcard>> getCardsForDeck(Id deckId) async {
    final isar = await db;
    return isar.flashcards.filter().deck((d) => d.idEqualTo(deckId)).findAll();
  }

  static Future<List<Flashcard>> getDueCardsForDeck(Id deckId) async {
    final isar = await db;
    
    final cards = await isar.flashcards
        .filter()
        .deck((d) => d.idEqualTo(deckId))
        .findAll();
    return cards.where((c) => c.isDue).toList();
  }

  static Future<Id> saveCard(Flashcard card, Id deckId) async {
    final isar = await db;
    return isar.writeTxn(() async {
      final id = await isar.flashcards.put(card);
      final deck = await isar.decks.get(deckId);
      if (deck != null) {
        await deck.cards.load();
        deck.cards.add(card);
        await deck.cards.save();
      }
      return id;
    });
  }

  static Future<void> updateCard(Flashcard card) async {
    final isar = await db;
    await isar.writeTxn(() => isar.flashcards.put(card));
  }

  static Future<void> deleteCard(Id id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.flashcards.delete(id));
  }
}
