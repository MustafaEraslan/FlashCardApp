import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../providers/deck_provider.dart';
import '../services/admob_service.dart';

class StudyScreen extends StatefulWidget {
  final Deck deck;
  const StudyScreen({super.key, required this.deck});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  List<Flashcard> _dueCards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _loading = true;
  bool _sessionDone = false;

  late AnimationController _flipController;
  late Animation<double> _frontRotation;
  late Animation<double> _backRotation;

  final AdMobService _adService = AdMobService();
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _frontRotation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.5).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
      TweenSequenceItem(tween: ConstantTween(-0.5), weight: 50),
    ]).animate(_flipController);
    _backRotation = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
    ]).animate(_flipController);

    _loadDueCards();
    if (!Platform.isWindows) {
      _adService.loadBanner(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _adService.disposeBanner();
    super.dispose();
  }

  Future<void> _loadDueCards() async {
    final cards = await context.read<DeckProvider>().getDueCards(widget.deck.id);
    setState(() {
      _dueCards = cards..shuffle();
      _loading = false;
      _sessionDone = cards.isEmpty;
    });
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _rate(ReviewRating rating) async {
    final card = _dueCards[_currentIndex];
    await context.read<DeckProvider>().reviewCard(card, rating);
    _reviewedCount++;

    setState(() {
      _isFlipped = false;
      _flipController.reset();
      if (_currentIndex + 1 >= _dueCards.length) {
        _sessionDone = true;
      } else {
        _currentIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        bottom: _loading || _sessionDone
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _currentIndex / _dueCards.length,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessionDone
              ? _buildSessionDone()
              : Column(
                  children: [
                    Expanded(child: _buildCard()),
                    if (_isFlipped) _buildRatingButtons(),
                    if (_adService.isBannerLoaded && _adService.bannerAd != null)
                      SizedBox(
                        height: _adService.bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _adService.bannerAd!),
                      ),
                  ],
                ),
    );
  }

  Widget _buildCard() {
    if (_dueCards.isEmpty) return const SizedBox();
    final card = _dueCards[_currentIndex];

    return GestureDetector(
      onTap: _flipCard,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            // Front
            AnimatedBuilder(
              animation: _frontRotation,
              builder: (_, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(_frontRotation.value * 3.1416),
                child: _frontRotation.value <= -0.25 ? const SizedBox() : child,
              ),
              child: _CardFace(
                text: card.front,
                label: 'KELIME',
                color: Theme.of(context).colorScheme.primaryContainer,
                hint: 'Kartı çevirmek için dokun',
              ),
            ),
            // Back
            AnimatedBuilder(
              animation: _backRotation,
              builder: (_, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(_backRotation.value * 3.1416),
                child: _backRotation.value >= 0.25 ? const SizedBox() : child,
              ),
              child: _CardFace(
                text: card.back,
                label: 'ANLAM',
                color: Theme.of(context).colorScheme.secondaryContainer,
                subtitle: card.example,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _RatingButton(label: 'Tekrar', color: Colors.red, onTap: () => _rate(ReviewRating.again)),
          const SizedBox(width: 8),
          _RatingButton(label: 'Zor', color: Colors.orange, onTap: () => _rate(ReviewRating.hard)),
          const SizedBox(width: 8),
          _RatingButton(label: 'İyi', color: Colors.green, onTap: () => _rate(ReviewRating.good)),
          const SizedBox(width: 8),
          _RatingButton(label: 'Kolay', color: Colors.blue, onTap: () => _rate(ReviewRating.easy)),
        ],
      ),
    );
  }

  Widget _buildSessionDone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Oturum Tamamlandı!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$_reviewedCount kart tekrar edildi', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String label;
  final Color color;
  final String? hint;
  final String? subtitle;

  const _CardFace({required this.text, required this.label, required this.color, this.hint, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54)),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: 32),
            Text(hint!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
