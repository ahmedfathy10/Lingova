import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../data/models/vocabulary_word.dart';
import '../../data/services/content_management_api_service.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  static const _favoritesKey = 'favorite_vocabulary_words';
  final _contentService = ContentManagementApiService();
  final _speechChannel = const MethodChannel('lingova/speech');
  final _searchController = TextEditingController();
  final Set<String> _favoriteIds = {};
  int _selectedView = 0;
  int _flashcardIndex = 0;
  bool _showFlashcardAnswer = false;
  String _query = '';
  late Future<List<VocabularyWord>> _wordsFuture;

  @override
  void initState() {
    super.initState();
    _wordsFuture = _loadWords();
    _loadFavorites();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favoriteIds
        ..clear()
        ..addAll(prefs.getStringList(_favoritesKey) ?? const <String>[]);
    });
  }

  Future<List<VocabularyWord>> _loadWords() async {
    try {
      final words = await _contentService.getVocabulary();
      return words.isEmpty ? _vocabulary : words;
    } catch (_) {
      return _vocabulary;
    }
  }

  Future<void> _toggleFavorite(VocabularyWord word) async {
    setState(() {
      if (_favoriteIds.contains(word.id)) {
        _favoriteIds.remove(word.id);
      } else {
        _favoriteIds.add(word.id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.toList()..sort());
  }

  Future<void> _speak(VocabularyWord word) async {
    try {
      await _speechChannel.invokeMethod<void>('speak', {
        'text': word.word,
        'language': word.languageCode,
      });
    } on MissingPluginException {
      _showMessage('النطق غير متاح على هذا الجهاز حالياً.');
    } catch (_) {
      _showMessage('تعذر تشغيل النطق. حاول مرة أخرى.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message, textAlign: TextAlign.right)));
  }

  List<VocabularyWord> _dailyWords(List<VocabularyWord> words) {
    final now = DateTime.now();
    final daySeed = DateTime(now.year, now.month, now.day)
        .difference(DateTime(now.year))
        .inDays;
    return List.generate(5, (index) {
      return words[(daySeed + index * 3) % words.length];
    });
  }

  List<VocabularyWord> _visibleWords(List<VocabularyWord> words) {
    final dailyWords = _dailyWords(words);
    final source = switch (_selectedView) {
      0 => dailyWords,
      1 => words.where((word) => _favoriteIds.contains(word.id)).toList(),
      _ => words,
    };

    if (_query.isEmpty) {
      return source;
    }
    return source.where((word) {
      return word.word.toLowerCase().contains(_query) ||
          word.meaning.contains(_query) ||
          word.example.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: FutureBuilder<List<VocabularyWord>>(
            future: _wordsFuture,
            builder: (context, snapshot) {
              final words = snapshot.data ?? _vocabulary;
              final visibleWords = _visibleWords(words);
              final dailyWords = _dailyWords(words);
              final flashcards = _favoriteIds.isEmpty
                  ? dailyWords
                  : words
                        .where((word) => _favoriteIds.contains(word.id))
                        .toList();
              if (_flashcardIndex >= flashcards.length) {
                _flashcardIndex = 0;
              }
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Vocabulary',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'كلمات يومية مع النطق والمراجعة بالكروت.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  _VocabularyHero(
                    dailyCount: dailyWords.length,
                    favoritesCount: _favoriteIds.length,
                  ),
                  const SizedBox(height: 18),
                  _ViewSwitcher(
                    selectedIndex: _selectedView,
                    onChanged: (index) {
                      setState(() {
                        _selectedView = index;
                        _showFlashcardAnswer = false;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_selectedView == 2)
                    _FlashcardReview(
                      word: flashcards[_flashcardIndex],
                      current: _flashcardIndex + 1,
                      total: flashcards.length,
                      isFavorite: _favoriteIds.contains(
                        flashcards[_flashcardIndex].id,
                      ),
                      showAnswer: _showFlashcardAnswer,
                      onFlip: () => setState(
                        () => _showFlashcardAnswer = !_showFlashcardAnswer,
                      ),
                      onNext: () => setState(() {
                        _flashcardIndex =
                            (_flashcardIndex + 1) % flashcards.length;
                        _showFlashcardAnswer = false;
                      }),
                      onPrevious: () => setState(() {
                        _flashcardIndex =
                            (_flashcardIndex - 1 + flashcards.length) %
                            flashcards.length;
                        _showFlashcardAnswer = false;
                      }),
                      onFavorite: () =>
                          _toggleFavorite(flashcards[_flashcardIndex]),
                      onSpeak: () => _speak(flashcards[_flashcardIndex]),
                    )
                  else ...[
                    TextField(
                      controller: _searchController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن كلمة أو معنى',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (visibleWords.isEmpty)
                      _EmptyVocabularyState(isFavorites: _selectedView == 1)
                    else
                      ...visibleWords.map(
                        (word) => VocabularyWordCard(
                          word: word,
                          isFavorite: _favoriteIds.contains(word.id),
                          onFavorite: () => _toggleFavorite(word),
                          onSpeak: () => _speak(word),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VocabularyHero extends StatelessWidget {
  final int dailyCount;
  final int favoritesCount;

  const _VocabularyHero({
    required this.dailyCount,
    required this.favoritesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.orange.withValues(alpha: .22)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.orange.withValues(alpha: .20),
            AppColors.surface,
            AppColors.surfaceHigh.withValues(alpha: .65),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFB15D), AppColors.orange],
              ),
            ),
            child: const Icon(
              Icons.translate_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'كلمات جديدة كل يوم',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '$dailyCount كلمات اليوم | $favoritesCount محفوظة',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ViewSwitcher({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (title: 'اليوم', icon: Icons.calendar_today_rounded),
      (title: 'المحفوظة', icon: Icons.favorite_rounded),
      (title: 'Flashcards', icon: Icons.style_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 16,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class VocabularyWordCard extends StatelessWidget {
  final VocabularyWord word;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onSpeak;

  const VocabularyWordCard({
    super.key,
    required this.word,
    required this.isFavorite,
    required this.onFavorite,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.redAccent : AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: onSpeak,
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        word.word,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        word.pronunciation,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                word.meaning,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh.withValues(alpha: .68),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  word.example,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlashcardReview extends StatelessWidget {
  final VocabularyWord word;
  final int current;
  final int total;
  final bool isFavorite;
  final bool showAnswer;
  final VoidCallback onFlip;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onFavorite;
  final VoidCallback onSpeak;

  const _FlashcardReview({
    required this.word,
    required this.current,
    required this.total,
    required this.isFavorite,
    required this.showAnswer,
    required this.onFlip,
    required this.onNext,
    required this.onPrevious,
    required this.onFavorite,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: .94, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: InkWell(
            key: ValueKey('${word.id}-$showAnswer'),
            onTap: onFlip,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: .28),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.surface,
                    AppColors.orange.withValues(alpha: .14),
                    AppColors.surfaceHigh,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$current / $total',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    showAnswer ? word.meaning : word.word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    showAnswer ? word.example : word.pronunciation,
                    textDirection:
                        showAnswer ? TextDirection.ltr : TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    showAnswer ? 'اضغط لإظهار الكلمة' : 'اضغط لإظهار المعنى',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onFavorite,
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.redAccent : null,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('التالي'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyVocabularyState extends StatelessWidget {
  final bool isFavorites;

  const _EmptyVocabularyState({required this.isFavorites});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            isFavorites
                ? Icons.favorite_border_rounded
                : Icons.search_off_rounded,
            color: AppColors.orange,
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            isFavorites ? 'لسه مفيش كلمات محفوظة' : 'مفيش نتائج للبحث',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            isFavorites
                ? 'اضغط على القلب بجانب أي كلمة عشان تظهر هنا.'
                : 'جرّب تبحث بكلمة مختلفة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

const _vocabulary = <VocabularyWord>[
  VocabularyWord(
    id: 'achieve',
    word: 'Achieve',
    meaning: 'يحقق / ينجز',
    pronunciation: '/əˈtʃiːv/',
    example: 'You can achieve your goal with daily practice.',
  ),
  VocabularyWord(
    id: 'improve',
    word: 'Improve',
    meaning: 'يحسّن / يتطور',
    pronunciation: '/ɪmˈpruːv/',
    example: 'I want to improve my speaking skills.',
  ),
  VocabularyWord(
    id: 'confident',
    word: 'Confident',
    meaning: 'واثق',
    pronunciation: '/ˈkɒnfɪdənt/',
    example: 'She feels confident when she speaks English.',
  ),
  VocabularyWord(
    id: 'schedule',
    word: 'Schedule',
    meaning: 'جدول / يرتب موعد',
    pronunciation: '/ˈʃedjuːl/',
    example: 'I study vocabulary according to my schedule.',
  ),
  VocabularyWord(
    id: 'conversation',
    word: 'Conversation',
    meaning: 'محادثة',
    pronunciation: '/ˌkɒnvəˈseɪʃn/',
    example: 'This conversation is useful for beginners.',
  ),
  VocabularyWord(
    id: 'pronounce',
    word: 'Pronounce',
    meaning: 'ينطق',
    pronunciation: '/prəˈnaʊns/',
    example: 'Can you pronounce this word clearly?',
  ),
  VocabularyWord(
    id: 'remember',
    word: 'Remember',
    meaning: 'يتذكر',
    pronunciation: '/rɪˈmembə/',
    example: 'I remember new words by using flashcards.',
  ),
  VocabularyWord(
    id: 'forget',
    word: 'Forget',
    meaning: 'ينسى',
    pronunciation: '/fəˈɡet/',
    example: 'Do not forget to review yesterday’s words.',
  ),
  VocabularyWord(
    id: 'explain',
    word: 'Explain',
    meaning: 'يشرح',
    pronunciation: '/ɪkˈspleɪn/',
    example: 'The teacher will explain the lesson again.',
  ),
  VocabularyWord(
    id: 'practice',
    word: 'Practice',
    meaning: 'يتدرب / تدريب',
    pronunciation: '/ˈpræktɪs/',
    example: 'Practice makes your pronunciation better.',
  ),
  VocabularyWord(
    id: 'useful',
    word: 'Useful',
    meaning: 'مفيد',
    pronunciation: '/ˈjuːsfəl/',
    example: 'This example is useful for daily conversation.',
  ),
  VocabularyWord(
    id: 'available',
    word: 'Available',
    meaning: 'متاح',
    pronunciation: '/əˈveɪləbl/',
    example: 'The course is available on the app.',
  ),
  VocabularyWord(
    id: 'appointment',
    word: 'Appointment',
    meaning: 'موعد',
    pronunciation: '/əˈpɔɪntmənt/',
    example: 'I have an appointment at five o’clock.',
  ),
  VocabularyWord(
    id: 'decision',
    word: 'Decision',
    meaning: 'قرار',
    pronunciation: '/dɪˈsɪʒn/',
    example: 'Learning a language is a great decision.',
  ),
  VocabularyWord(
    id: 'journey',
    word: 'Journey',
    meaning: 'رحلة',
    pronunciation: '/ˈdʒɜːni/',
    example: 'Your language journey starts with one word.',
  ),
  VocabularyWord(
    id: 'danke',
    word: 'Danke',
    meaning: 'شكراً',
    pronunciation: '/ˈdaŋkə/',
    example: 'Danke für deine Hilfe.',
    languageCode: 'de',
  ),
  VocabularyWord(
    id: 'bitte',
    word: 'Bitte',
    meaning: 'من فضلك / عفواً',
    pronunciation: '/ˈbɪtə/',
    example: 'Bitte sprechen Sie langsam.',
    languageCode: 'de',
  ),
];

