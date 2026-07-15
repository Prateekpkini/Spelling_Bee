import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/providers/game_provider.dart';
import 'package:spelling_bee/services/tts_service.dart';

// ═══════════════════════════════════════════════════════════════════════
// Premium Gamified Color System
// ═══════════════════════════════════════════════════════════════════════
class _GC {
  _GC._();
  // Background gradient
  static const Color bgStart = Color(0xFF0A0E27);      // Midnight blue
  static const Color bgMid = Color(0xFF141852);         // Deep indigo
  static const Color bgEnd = Color(0xFF1A0A3E);         // Deep violet

  // Glass
  static const Color glassFill = Color(0x18FFFFFF);     // ~9% white
  static const Color glassBorder = Color(0x30FFFFFF);   // ~19% white
  static const Color glassHighlight = Color(0x10FFFFFF); // ~6% white

  // Text
  static const Color textBright = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xB3FFFFFF);     // ~70% white
  static const Color textDim = Color(0x80FFFFFF);       // ~50% white

  // Accent – vivid game states
  static const Color correct = Color(0xFF00E676);       // Neon green
  static const Color correctGlow = Color(0x4000E676);
  static const Color wrong = Color(0xFFFF1744);         // Vivid red
  static const Color wrongGlow = Color(0x40FF1744);
  static const Color gold = Color(0xFFFFD54F);          // Amber gold
  static const Color goldDim = Color(0xCCFFD54F);
  static const Color shieldPink = Color(0xFFFF4D6D);
  static const Color pass = Color(0xFF64B5F6);          // Soft blue
  static const Color passGlow = Color(0x4064B5F6);
}

// ═══════════════════════════════════════════════════════════════════════
// GlassContainer – reusable frosted glass panel
// ═══════════════════════════════════════════════════════════════════════
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? fillOverride;
  final Color? borderOverride;

  const _GlassContainer({
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.fillOverride,
    this.borderOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillOverride ?? _GC.glassFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderOverride ?? _GC.glassBorder,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Animated Mesh Gradient Background
// ═══════════════════════════════════════════════════════════════════════
class _AnimatedGradientBg extends StatefulWidget {
  final Widget child;
  const _AnimatedGradientBg({required this.child});

  @override
  State<_AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<_AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.5 + 0.5 * math.sin(t * math.pi), 1.0),
              colors: const [_GC.bgStart, _GC.bgMid, _GC.bgEnd],
              stops: [0, 0.4 + 0.1 * t, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GAME SCREEN
// ═══════════════════════════════════════════════════════════════════════
class GameScreen extends ConsumerStatefulWidget {
  final String studentId;
  const GameScreen({super.key, required this.studentId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  final _answerController = TextEditingController();
  final _answerFocus = FocusNode();
  final _ttsService = TtsService();
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  void _startIfNeeded() {
    if (!_gameStarted) {
      _gameStarted = true;
      ref.read(gameProvider.notifier).startGame();
    }
  }

  void _submitAnswer() {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;
    ref.read(gameProvider.notifier).submitAnswer(answer);
    _answerController.clear();
  }

  void _passWord() {
    ref.read(gameProvider.notifier).passWord();
    _answerController.clear();
  }

  void _showSurrenderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A3E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Surrender?', style: TextStyle(color: _GC.textBright)),
          content: const Text(
            'Are you sure you want to end the championship? This action cannot be undone.',
            style: TextStyle(color: _GC.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continue', style: TextStyle(color: _GC.gold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(gameProvider.notifier).surrender();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _GC.wrong),
              child: const Text('Surrender', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIfNeeded();
    });

    if (gameState.status == GameStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/play/result/${widget.studentId}');
      });
    }

    return Scaffold(
      body: _AnimatedGradientBg(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Mobile-first bounded canvas
              final maxW = constraints.maxWidth > 520 ? 500.0 : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: maxW,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // ─── HUD ────────────────────────────────
                          _buildHud(gameState),

                          // ─── Main content ───────────────────────
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                              child: Column(
                                children: [
                                  _buildWordCard(gameState),
                                  const SizedBox(height: 16),
                                  _buildAnswerInput(gameState),
                                  const SizedBox(height: 16),
                                  _buildActionButtons(gameState),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ─── Feedback overlay ────────────────────
                      if (gameState.feedback != null) _buildFeedbackOverlay(gameState),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HUD – Glassmorphism top bar
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHud(GameState state) {
    final minutes = state.minutes;
    final seconds = state.seconds;
    final timerColor = minutes < 2
        ? _GC.wrong
        : minutes < 5
            ? _GC.gold
            : _GC.correct;

    return _GlassContainer(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderRadius: 18,
      child: Column(
        children: [
          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: timerColor, size: 22),
              const SizedBox(width: 6),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: timerColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: timerColor.withOpacity(0.5), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Score / Correct / Wrong
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _GlowStat(label: 'Score', value: '${state.score}', color: _GC.gold),
              _GlowStat(label: 'Correct', value: '${state.correctCount}', color: _GC.correct),
              _GlowStat(label: 'Wrong', value: '${state.wrongCount}', color: _GC.wrong),
            ],
          ),
          const SizedBox(height: 10),

          // Shields & Passes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shields as glowing hearts
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final active = i < state.shields;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      active ? Icons.favorite : Icons.favorite_border,
                      color: active ? _GC.shieldPink : _GC.textDim,
                      size: 20,
                      shadows: active
                          ? [Shadow(color: _GC.shieldPink.withOpacity(0.6), blurRadius: 6)]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              // Passes chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _GC.glassHighlight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _GC.glassBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.skip_next, color: _GC.pass, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${state.passes}',
                      style: const TextStyle(
                        color: _GC.pass,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Word Card – Glassmorphism
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildWordCard(GameState state) {
    final word = state.currentWord;
    if (word == null) return const SizedBox.shrink();

    return _GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Pronounce button with glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _GC.gold.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _ttsService.speak(word.spellingBritish),
                icon: const Icon(Icons.volume_up_rounded, size: 28),
                label: const Text('Pronounce Word', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _GC.gold,
                  foregroundColor: _GC.bgStart,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Part of speech
          _GlassInfoLabel(
            icon: Icons.category_rounded,
            label: 'Part of Speech',
            value: word.partOfSpeech,
          ),
          const SizedBox(height: 10),

          // Meaning
          _GlassInfoLabel(
            icon: Icons.menu_book_rounded,
            label: 'Meaning',
            value: word.meaning,
          ),
          const SizedBox(height: 10),

          // Jumbled letters – highlighted
          _GlassInfoLabel(
            icon: Icons.shuffle_rounded,
            label: 'Jumbled Letters',
            value: word.jumbledLetters,
            highlight: true,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Answer Input – Glassmorphism
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAnswerInput(GameState state) {
    final isPlaying = state.status == GameStatus.playing;

    return _GlassContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: 16,
      child: TextField(
        controller: _answerController,
        focusNode: _answerFocus,
        autofocus: true,
        enabled: isPlaying,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submitAnswer(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
          color: _GC.textBright,
        ),
        textAlign: TextAlign.center,
        cursorColor: _GC.gold,
        decoration: InputDecoration(
          hintText: 'Type your answer...',
          hintStyle: TextStyle(
            color: _GC.textDim,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _GC.gold, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Action Buttons – Glass-wrapped
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildActionButtons(GameState state) {
    final isPlaying = state.status == GameStatus.playing;

    return Column(
      children: [
        // Submit – prominent with glow
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _GC.correct.withOpacity(0.25),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isPlaying ? _submitAnswer : null,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Submit Answer', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _GC.correct,
                foregroundColor: _GC.bgStart,
                disabledBackgroundColor: _GC.glassFill,
                disabledForegroundColor: _GC.textDim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Pass & Surrender row
        Row(
          children: [
            Expanded(
              child: _GlassContainer(
                borderRadius: 14,
                child: SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: isPlaying && state.passes > 0 ? _passWord : null,
                    icon: Icon(Icons.skip_next_rounded,
                        size: 20, color: isPlaying && state.passes > 0 ? _GC.pass : _GC.textDim),
                    label: Text(
                      'Pass (${state.passes})',
                      style: TextStyle(
                        color: isPlaying && state.passes > 0 ? _GC.pass : _GC.textDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassContainer(
                borderRadius: 14,
                borderOverride: _GC.wrong.withOpacity(0.3),
                child: SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: isPlaying ? _showSurrenderDialog : null,
                    icon: Icon(Icons.flag_rounded,
                        size: 20, color: isPlaying ? _GC.wrong : _GC.textDim),
                    label: Text(
                      'Surrender',
                      style: TextStyle(
                        color: isPlaying ? _GC.wrong : _GC.textDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Feedback Overlay – Glass + Glow
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFeedbackOverlay(GameState state) {
    final feedback = state.feedback!;

    Color accentColor;
    Color glowColor;
    IconData icon;

    switch (feedback.type) {
      case FeedbackType.correct:
      case FeedbackType.reward:
        accentColor = _GC.correct;
        glowColor = _GC.correctGlow;
        icon = Icons.check_circle_rounded;
        break;
      case FeedbackType.wrong:
        accentColor = _GC.wrong;
        glowColor = _GC.wrongGlow;
        icon = Icons.cancel_rounded;
        break;
      case FeedbackType.passed:
        accentColor = _GC.pass;
        glowColor = _GC.passGlow;
        icon = Icons.skip_next_rounded;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (state.status != GameStatus.ended) {
          ref.read(gameProvider.notifier).nextWord();
          _answerFocus.requestFocus();
        }
      },
      child: Container(
        color: Colors.black45,
        child: Center(
          child: _GlassContainer(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(28),
            fillOverride: const Color(0x30FFFFFF),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glowColor,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: accentColor, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  feedback.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    shadows: [
                      Shadow(color: accentColor.withOpacity(0.5), blurRadius: 8),
                    ],
                  ),
                ),
                if (feedback.rewards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...feedback.rewards.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _GC.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _GC.gold.withOpacity(0.3)),
                        ),
                        child: Text(
                          '🎁 $r',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _GC.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Tap to continue',
                  style: TextStyle(
                    color: _GC.textDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════════

class _GlowStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _GlowStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: _GC.textDim, fontSize: 11),
        ),
      ],
    );
  }
}

class _GlassInfoLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _GlassInfoLabel({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? _GC.gold.withOpacity(0.08) : _GC.glassHighlight,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: _GC.gold.withOpacity(0.25))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _GC.textDim),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _GC.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 20 : 15,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? _GC.gold : _GC.textBright,
              letterSpacing: highlight ? 4 : 0,
              shadows: highlight
                  ? [Shadow(color: _GC.gold.withOpacity(0.4), blurRadius: 6)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
