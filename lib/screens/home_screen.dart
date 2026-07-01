import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';
import '../models/deck.dart';
import 'deck_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeckProvider>().loadDecks();
    });
  }

  void _showAddDeckDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Deste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Deste adı'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              context.read<DeckProvider>().addDeck(name, descCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Deck deck) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desteyi Sil'),
        content: Text('"${deck.name}" destesi ve tüm kartları silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<DeckProvider>().deleteDeck(deck.id);
              Navigator.pop(ctx);
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
        title: const Text('Flashcard'),
        centerTitle: true,
      ),
      body: Consumer<DeckProvider>(
        builder: (context, provider, _) {
          final decks = provider.decks;
          if (decks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz deste yok', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Sağ alttaki + ile yeni deste oluştur', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              final cardCount = deck.cards.length;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      deck.name.isNotEmpty ? deck.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    deck.description.isNotEmpty ? deck.description : '$cardCount kart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(label: Text('$cardCount')),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, deck),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeckScreen(deck: deck)),
                    );
                    if (context.mounted) {
                      context.read<DeckProvider>().loadDecks();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'Geliştirici: 3727tech',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeckDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Deste'),
      ),
    );
  }
}
