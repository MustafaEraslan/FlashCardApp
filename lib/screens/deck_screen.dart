import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../providers/deck_provider.dart';
import 'study_screen.dart';

class DeckScreen extends StatefulWidget {
  final Deck deck;
  const DeckScreen({super.key, required this.deck});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  List<Flashcard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await context.read<DeckProvider>().getCardsForDeck(widget.deck.id);
    if (mounted) setState(() { _cards = cards; _loading = false; });
  }

  void _showAddCardDialog() {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    final exampleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Kart'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontCtrl,
                decoration: const InputDecoration(labelText: 'Ön yüz (kelime)'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: backCtrl,
                decoration: const InputDecoration(labelText: 'Arka yüz (anlam/çeviri)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: exampleCtrl,
                decoration: const InputDecoration(labelText: 'Örnek cümle (opsiyonel)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              final front = frontCtrl.text.trim();
              final back = backCtrl.text.trim();
              if (front.isEmpty || back.isEmpty) return;
              await context.read<DeckProvider>().addCard(
                widget.deck.id, front, back,
                exampleCtrl.text.trim().isEmpty ? null : exampleCtrl.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadCards();
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCard(Flashcard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kartı Sil'),
        content: Text('"${card.front}" kartı silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<DeckProvider>().deleteCard(card.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadCards();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          if (_cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudyScreen(deck: widget.deck)),
                ).then((_) => _loadCards()),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Çalış'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Henüz kart yok', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(card.front, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.back),
                            if (card.example != null)
                              Text(card.example!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (card.nextReview != null)
                              Chip(
                                label: Text(
                                  card.isDue ? 'Tekrar zamanı' : '${card.interval}g',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: card.isDue ? Colors.orange.shade100 : null,
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteCard(card),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

