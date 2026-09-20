import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/services/astrology_service.dart';
import '../../main_navigation.dart';
import '../../mainwidgets/header.dart';

class LiveTarotScreen extends StatefulWidget {
  const LiveTarotScreen({super.key});

  @override
  State<LiveTarotScreen> createState() => _LiveTarotScreenState();
}

class _LiveTarotScreenState extends State<LiveTarotScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _gold = Color(0xFFD4A017);
  static const _cream = Color(0xFFFFF8E5);
  static const _border = Color(0xFFE7D8B5);
  static const _muted = Color(0xFF6B7280);

  final AstrologyService _service = AstrologyService();
  final TextEditingController _yesNoQuestion = TextEditingController();
  final Map<String, TarotCard?> _selected = {
    'love': null,
    'career': null,
    'finance': null,
  };

  String _mode = 'general';
  String _activeSlot = 'love';
  TarotCard? _yesNoCard;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _reading;
  Map<String, dynamic>? _yesNoReading;
  List<TarotCard> _deckCards =
      _shuffledTarotDeck(_generatedFallbackTarotDeck());

  bool get _canRead => _selected.values.every((card) => card != null);
  bool get _canYesNoRead =>
      _yesNoQuestion.text.trim().isNotEmpty && _yesNoCard != null;

  @override
  void initState() {
    super.initState();
    _loadAvailableDeck();
  }

  @override
  void dispose() {
    _yesNoQuestion.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableDeck() async {
    try {
      final manifestText =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestText);
      final keys = manifest is Map
          ? manifest.keys.map((e) => e.toString())
          : const <String>[];
      final cards = keys
          .where((path) =>
              path.startsWith('$_tarotPath/') &&
              path != tarotBackPath &&
              RegExp(r'/\d{2}-[^/]+\.(jpg|jpeg|png|webp)$').hasMatch(path))
          .map(_tarotCardFromAsset)
          .whereType<TarotCard>()
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      if (!mounted || cards.isEmpty) return;
      setState(() => _deckCards = _shuffledTarotDeck(cards));
    } catch (_) {
      // Keep the bundled fallback deck if the manifest cannot be read.
    }
  }

  Future<void> _run() async {
    if (_mode == 'yes-no') {
      await _runYesNo();
      return;
    }
    if (!_canRead) {
      setState(
          () => _error = 'Select one card each for Love, Career, and Finance.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _reading = null;
    });

    try {
      final response = await _service.tarot({
        'type': 'general',
        'love': _selected['love']!.id,
        'career': _selected['career']!.id,
        'finance': _selected['finance']!.id,
        'la': 'en',
      });
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (response['status'] == 'success') {
          _reading = _asMap(_asMap(response['data'])['reading']);
        } else {
          _error = response['message']?.toString() ??
              'Unable to read the selected cards.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _runYesNo() async {
    if (!_canYesNoRead) {
      setState(() => _error = 'Enter your question and select one card.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _yesNoReading = null;
    });

    try {
      final response = await _service.tarot({
        'type': 'yes-no',
        'question': _yesNoQuestion.text.trim(),
        'card': _yesNoCard!.id,
        'la': 'en',
      });
      if (!mounted) return;
      final data = _asMap(response['data']);
      final reading = _asMap(data['reading']);
      setState(() {
        _loading = false;
        if (response['status'] == 'success' && reading.isNotEmpty) {
          _yesNoReading = reading;
        } else {
          _error = response['message']?.toString() ??
              'Unable to read the selected card.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _toggleCard(TarotCard card) {
    setState(() {
      if (_mode == 'yes-no') {
        _yesNoCard = _yesNoCard?.id == card.id ? null : card;
        _yesNoReading = null;
        _error = null;
        final pinnedCardIds = {
          card.id,
          if (_yesNoCard != null) _yesNoCard!.id,
        };
        _deckCards = _shuffleDeckWithPinnedCards(_deckCards, pinnedCardIds);
        return;
      }

      final currentSlot = _selectedSlotFor(card.id);

      if (currentSlot != null) {
        _selected[currentSlot] = null;
        _activeSlot = currentSlot;
      } else {
        _selected[_activeSlot] = card;
        _advanceActiveSlot();
      }
      _reading = null;
      _error = null;
      final pinnedCardIds = {
        card.id,
        ..._selected.values.whereType<TarotCard>().map((item) => item.id),
      };
      _deckCards = _shuffleDeckWithPinnedCards(_deckCards, pinnedCardIds);
    });
  }

  void _advanceActiveSlot() {
    for (final slot in const ['love', 'career', 'finance']) {
      if (_selected[slot] == null) {
        _activeSlot = slot;
        return;
      }
    }
  }

  void _goBack() {
    MainNavigationState.returnHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  _topBar(),
                  const SizedBox(height: 10),
                  _modeSelector(),
                  const SizedBox(height: 10),
                  if (_mode == 'general')
                    _slotSelector()
                  else
                    _yesNoQuestionField(),
                  const SizedBox(height: 16),
                  if (_mode == 'general')
                    _selectedCards()
                  else
                    _yesNoSelectedCard(),
                  const SizedBox(height: 16),
                  _deck(),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _run,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_loading
                          ? 'Reading Cards...'
                          : _mode == 'general'
                              ? 'Reveal Tarot Reading'
                              : 'Reveal Yes/No Answer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _navy,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _errorCard()
                  else if (_mode == 'yes-no' && _yesNoReading != null)
                    _yesNoPanel()
                  else if (_mode == 'general' && _reading != null)
                    _readingPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _modeButton('general', 'General Reading'),
          _modeButton('yes-no', 'Yes/No Reading'),
        ],
      ),
    );
  }

  Widget _modeButton(String value, String label) {
    final selected = _mode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _mode = value;
          _error = null;
        }),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : _navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_circle_left_rounded),
        ),
        const Expanded(
          child: Text(
            'Tarot Reading',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: _navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _slotSelector() {
    return Row(
      children: const ['love', 'career', 'finance'].map((slot) {
        final active = _activeSlot == slot;
        final filled = _selected[slot] != null;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _activeSlot = slot),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: active
                      ? _navy
                      : filled
                          ? _cream
                          : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: active ? _navy : _border),
                ),
                child: Column(
                  children: [
                    Icon(_slotIcon(slot), color: active ? Colors.white : _gold),
                    const SizedBox(height: 4),
                    Text(
                      _slotTitle(slot),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? Colors.white : _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _yesNoQuestionField() {
    return TextField(
      controller: _yesNoQuestion,
      onChanged: (_) => setState(() {
        _yesNoReading = null;
        _error = null;
      }),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Your yes/no question',
        hintText: 'Example: Will this decision be good for me?',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.4),
        ),
      ),
    );
  }

  Widget _selectedCards() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selected Cards',
              style: TextStyle(color: _navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: const ['love', 'career', 'finance'].map((slot) {
              final card = _selected[slot];
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      Text(_slotTitle(slot),
                          style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        card?.name ?? 'Not selected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _yesNoSelectedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.style_rounded, color: _gold, size: 20),
          const SizedBox(width: 9),
          const Text(
            'Selected Card',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _yesNoCard?.name ?? 'Tap one card from the deck',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deck() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3E4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              _mode == 'general'
                  ? 'Tap a card for ${_slotTitle(_activeSlot)}'
                  : 'Tap one card for your answer',
              style:
                  const TextStyle(color: _navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 108 + ((_deckCards.length - 1).clamp(0, 1000) * 34),
                height: 184,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var index = 0; index < _deckCards.length; index++)
                      _stackedCard(_deckCards[index], index),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_deckCards.length} cards available. New numbered card assets are added to the deck automatically.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _stackedCard(TarotCard card, int index) {
    final selectedSlot = _selectedSlotFor(card.id);
    final selected = selectedSlot != null || _yesNoCard?.id == card.id;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      left: index * 34,
      top: selected ? 16 : 0,
      child: GestureDetector(
        onTap: () => _toggleCard(card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 96,
          height: 164,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? _gold : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _gold : Colors.white,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.22 : 0.1),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              selected ? card.imagePath : tarotBackPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        _error ?? 'Unable to read cards.',
        style: const TextStyle(
            color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _readingPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: const ['love', 'career', 'finance']
            .map((slot) => _readingSection(slot))
            .toList(),
      ),
    );
  }

  Widget _yesNoPanel() {
    final card = _yesNoCard;
    final reading = _yesNoReading ?? const <String, dynamic>{};
    final name = reading['name']?.toString().trim();
    final value = reading['value']?.toString().trim();
    final description = reading['description']?.toString().trim();
    final isPositive = (value ?? '').toLowerCase().contains('yes');
    final badgeColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                card.imagePath,
                width: 82,
                height: 128,
                fit: BoxFit.cover,
              ),
            ),
          if (card != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name == null || name.isEmpty
                            ? card?.name ?? 'Selected Card'
                            : name,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        value == null || value.isEmpty ? '-' : value,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description == null || description.isEmpty
                      ? 'No description returned.'
                      : description,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 13,
                    height: 1.36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingSection(String slot) {
    final card = _selected[slot]!;
    final text = _reading?[slot]?.toString().trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                card.imagePath,
                width: 130,
                height: 202,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_slotTitle(slot),
              style: const TextStyle(
                  color: _gold, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(card.name,
              style: const TextStyle(
                  color: _navy, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            text == null || text.isEmpty ? 'No reading returned.' : text,
            style: const TextStyle(color: Color(0xFF374151), height: 1.42),
          ),
        ],
      ),
    );
  }

  String? _selectedSlotFor(int cardId) {
    for (final entry in _selected.entries) {
      if (entry.value?.id == cardId) return entry.key;
    }
    return null;
  }
}

class TarotCard {
  final int id;
  final String name;
  final String imagePath;

  const TarotCard({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}

const _tarotPath = 'assets/images/tarot/cards';
const tarotBackPath = '$_tarotPath/tarot-back.jpg';

const Map<int, String> _tarotNames = {
  1: 'KING OF WANDS',
  2: 'QUEEN OF WANDS',
  3: 'KNIGHT OF WANDS',
  4: 'PAGE OF WANDS',
  5: 'TEN OF WANDS',
  6: 'NINE OF WANDS',
  7: 'EIGHT OF WANDS',
  8: 'SEVEN OF WANDS',
  9: 'SIX OF WANDS',
  10: 'FIVE OF WANDS',
  11: 'FOUR OF WANDS',
  12: 'THREE OF WANDS',
  13: 'TWO OF WANDS',
  14: 'ACE OF WANDS',
  15: 'KING OF SWORDS',
  16: 'QUEEN OF SWORDS',
  17: 'KNIGHT OF SWORDS',
  18: 'PAGE OF SWORDS',
  19: 'TEN OF SWORDS',
  20: 'NINE OF SWORDS',
  21: 'EIGHT OF SWORDS',
  22: 'SEVEN OF SWORDS',
  23: 'SIX OF SWORDS',
  24: 'FIVE OF SWORDS',
  25: 'FOUR OF SWORDS',
  26: 'THREE OF SWORDS',
  27: 'TWO OF SWORDS',
  28: 'ACE OF SWORDS',
  29: 'KING OF CUPS',
  30: 'QUEEN OF CUPS',
  31: 'KNIGHT OF CUPS',
  32: 'PAGE OF CUPS',
  33: 'TEN OF CUPS',
  34: 'NINE OF CUPS',
  35: 'EIGHT OF CUPS',
  36: 'SEVEN OF CUPS',
  37: 'SIX OF CUPS',
  38: 'FIVE OF CUPS',
  39: 'FOUR OF CUPS',
  40: 'THREE OF CUPS',
  41: 'TWO OF CUPS',
  42: 'ACE OF CUPS',
  43: 'KING OF PENTACLES',
  44: 'QUEEN OF PENTACLES',
  45: 'KNIGHT OF PENTACLES',
  46: 'PAGE OF PENTACLES',
  47: 'TEN OF PENTACLES',
  48: 'NINE OF PENTACLES',
  49: 'EIGHT OF PENTACLES',
  50: 'SEVEN OF PENTACLES',
  51: 'SIX OF PENTACLES',
  52: 'FIVE OF PENTACLES',
  53: 'FOUR OF PENTACLES',
  54: 'THREE OF PENTACLES',
  55: 'TWO OF PENTACLES',
  56: 'ACE OF PENTACLES',
  57: 'THE FOOL',
  58: 'THE MAGICIAN',
  59: 'THE HIGH PRIESTESS',
  60: 'THE EMPRESS',
  61: 'THE EMPEROR',
  62: 'THE HIEROPHANT',
  63: 'THE LOVERS',
  64: 'THE CHARIOT',
  65: 'STRENGTH',
  66: 'THE HERMIT',
  67: 'WHEEL OF FORTUNE',
  68: 'JUSTICE',
  69: 'THE HANGED MAN',
  70: 'DEATH',
  71: 'TEMPERANCE',
  72: 'THE DEVIL',
  73: 'THE TOWER',
  74: 'THE STAR',
  75: 'THE MOON',
  76: 'THE SUN',
  77: 'JUDGEMENT',
  78: 'THE WORLD',
};

TarotCard? _tarotCardFromAsset(String path) {
  final file = path.split('/').last;
  final id = int.tryParse(file.substring(0, 2));
  if (id == null) return null;
  final fallbackName = file
      .replaceFirst(RegExp(r'^\d{2}-'), '')
      .replaceAll(RegExp(r'\.(jpg|jpeg|png|webp)$'), '')
      .replaceAll('-', ' ')
      .toUpperCase();
  return TarotCard(
    id: id,
    name: _tarotNames[id] ?? fallbackName,
    imagePath: path,
  );
}

List<TarotCard> _generatedFallbackTarotDeck() {
  final bundled = {for (final card in _fallbackTarotDeck) card.id: card};
  return _tarotNames.entries.map((entry) {
    final bundledCard = bundled[entry.key];
    if (bundledCard != null) return bundledCard;
    return TarotCard(
      id: entry.key,
      name: entry.value,
      imagePath: _fallbackTarotAssetPath(entry.key, entry.value),
    );
  }).toList();
}

String _fallbackTarotAssetPath(int id, String name) {
  final slug = name.toLowerCase().replaceAll(' ', '-');
  return '$_tarotPath/${id.toString().padLeft(2, '0')}-$slug.jpg';
}

const _fallbackTarotDeck = <TarotCard>[
  TarotCard(
      id: 1,
      name: 'KING OF WANDS',
      imagePath: '$_tarotPath/01-king-of-wands.jpg'),
  TarotCard(
      id: 2,
      name: 'QUEEN OF WANDS',
      imagePath: '$_tarotPath/02-queen-of-wands.jpg'),
  TarotCard(
      id: 3,
      name: 'KNIGHT OF WANDS',
      imagePath: '$_tarotPath/03-knight-of-wands.jpg'),
  TarotCard(
      id: 4,
      name: 'PAGE OF WANDS',
      imagePath: '$_tarotPath/04-page-of-wands.jpg'),
  TarotCard(
      id: 5,
      name: 'TEN OF WANDS',
      imagePath: '$_tarotPath/05-ten-of-wands.jpg'),
  TarotCard(
      id: 6,
      name: 'NINE OF WANDS',
      imagePath: '$_tarotPath/06-nine-of-wands.jpg'),
  TarotCard(
      id: 7,
      name: 'EIGHT OF WANDS',
      imagePath: '$_tarotPath/07-eight-of-wands.jpg'),
  TarotCard(
      id: 8,
      name: 'SEVEN OF WANDS',
      imagePath: '$_tarotPath/08-seven-of-wands.jpg'),
  TarotCard(
      id: 9,
      name: 'SIX OF WANDS',
      imagePath: '$_tarotPath/09-six-of-wands.jpg'),
  TarotCard(
      id: 10,
      name: 'FIVE OF WANDS',
      imagePath: '$_tarotPath/10-five-of-wands.jpg'),
  TarotCard(
      id: 11,
      name: 'FOUR OF WANDS',
      imagePath: '$_tarotPath/11-four-of-wands.jpg'),
  TarotCard(
      id: 12,
      name: 'THREE OF WANDS',
      imagePath: '$_tarotPath/12-three-of-wands.jpg'),
  TarotCard(
      id: 13,
      name: 'TWO OF WANDS',
      imagePath: '$_tarotPath/13-two-of-wands.jpg'),
  TarotCard(
      id: 14,
      name: 'ACE OF WANDS',
      imagePath: '$_tarotPath/14-ace-of-wands.jpg'),
  TarotCard(
      id: 15,
      name: 'KING OF SWORDS',
      imagePath: '$_tarotPath/15-king-of-swords.jpg'),
  TarotCard(
      id: 16,
      name: 'QUEEN OF SWORDS',
      imagePath: '$_tarotPath/16-queen-of-swords.jpg'),
  TarotCard(
      id: 17,
      name: 'KNIGHT OF SWORDS',
      imagePath: '$_tarotPath/17-knight-of-swords.jpg'),
  TarotCard(
      id: 18,
      name: 'PAGE OF SWORDS',
      imagePath: '$_tarotPath/18-page-of-swords.jpg'),
  TarotCard(
      id: 19,
      name: 'TEN OF SWORDS',
      imagePath: '$_tarotPath/19-ten-of-swords.jpg'),
  TarotCard(
      id: 20,
      name: 'NINE OF SWORDS',
      imagePath: '$_tarotPath/20-nine-of-swords.jpg'),
  TarotCard(
      id: 21,
      name: 'EIGHT OF SWORDS',
      imagePath: '$_tarotPath/21-eight-of-swords.jpg'),
  TarotCard(
      id: 22,
      name: 'SEVEN OF SWORDS',
      imagePath: '$_tarotPath/22-seven-of-swords.jpg'),
  TarotCard(
      id: 23,
      name: 'SIX OF SWORDS',
      imagePath: '$_tarotPath/23-six-of-swords.jpg'),
  TarotCard(
      id: 24,
      name: 'FIVE OF SWORDS',
      imagePath: '$_tarotPath/24-five-of-swords.jpg'),
  TarotCard(
      id: 25,
      name: 'FOUR OF SWORDS',
      imagePath: '$_tarotPath/25-four-of-swords.jpg'),
  TarotCard(
      id: 26,
      name: 'THREE OF SWORDS',
      imagePath: '$_tarotPath/26-three-of-swords.jpg'),
  TarotCard(
      id: 27,
      name: 'TWO OF SWORDS',
      imagePath: '$_tarotPath/27-two-of-swords.jpg'),
  TarotCard(
      id: 28,
      name: 'ACE OF SWORDS',
      imagePath: '$_tarotPath/28-ace-of-swords.jpg'),
  TarotCard(
      id: 29,
      name: 'KING OF CUPS',
      imagePath: '$_tarotPath/29-king-of-cups.jpg'),
  TarotCard(
      id: 30,
      name: 'QUEEN OF CUPS',
      imagePath: '$_tarotPath/30-queen-of-cups.jpg'),
  TarotCard(
      id: 31,
      name: 'KNIGHT OF CUPS',
      imagePath: '$_tarotPath/31-knight-of-cups.jpg'),
  TarotCard(
      id: 32,
      name: 'PAGE OF CUPS',
      imagePath: '$_tarotPath/32-page-of-cups.jpg'),
  TarotCard(
      id: 33, name: 'TEN OF CUPS', imagePath: '$_tarotPath/33-ten-of-cups.jpg'),
  TarotCard(
      id: 34,
      name: 'NINE OF CUPS',
      imagePath: '$_tarotPath/34-nine-of-cups.jpg'),
  TarotCard(
      id: 35,
      name: 'EIGHT OF CUPS',
      imagePath: '$_tarotPath/35-eight-of-cups.jpg'),
  TarotCard(
      id: 36,
      name: 'SEVEN OF CUPS',
      imagePath: '$_tarotPath/36-seven-of-cups.jpg'),
  TarotCard(
      id: 37, name: 'SIX OF CUPS', imagePath: '$_tarotPath/37-six-of-cups.jpg'),
];

IconData _slotIcon(String slot) {
  return switch (slot) {
    'love' => Icons.favorite_rounded,
    'career' => Icons.work_rounded,
    'finance' => Icons.account_balance_wallet_rounded,
    _ => Icons.auto_awesome,
  };
}

String _slotTitle(String slot) {
  return switch (slot) {
    'love' => 'Love',
    'career' => 'Career',
    'finance' => 'Finance',
    _ => slot,
  };
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<TarotCard> _shuffledTarotDeck(List<TarotCard> cards) {
  return List<TarotCard>.of(cards)..shuffle(Random());
}

List<TarotCard> _shuffleDeckWithPinnedCards(
  List<TarotCard> cards,
  Set<int> pinnedCardIds,
) {
  final looseCards = cards
      .where((card) => !pinnedCardIds.contains(card.id))
      .toList()
    ..shuffle(Random());
  var looseIndex = 0;

  return cards.map((card) {
    if (pinnedCardIds.contains(card.id)) return card;
    return looseCards[looseIndex++];
  }).toList();
}
