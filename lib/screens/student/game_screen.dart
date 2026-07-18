import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/providers/game_provider.dart';
import 'package:spelling_bee/providers/theme_provider.dart';
import 'package:spelling_bee/services/tts_service.dart';

// ═══════════════════════════════════════════════════════════════════════
// Premium Gamified Color System
// ═══════════════════════════════════════════════════════════════════════
class _GC {
  _GC._();

  // Glass
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
  static const Color shieldPink = Color(0xFFFF4D6D);
  static const Color pass = Color(0xFF64B5F6);          // Soft blue
  static const Color passGlow = Color(0x4064B5F6);
}

// ═══════════════════════════════════════════════════════════════════════
// GlassContainer – reusable frosted glass panel
// ═══════════════════════════════════════════════════════════════════════
class _GlassContainer extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillOverride ?? theme.glassFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderOverride ?? theme.glassBorder,
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
  final ThemeState theme;
  const _AnimatedGradientBg({required this.theme, required this.child});

  @override
  State<_AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<_AnimatedGradientBg>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _colorCtrl;
  late List<Color> _currentColors;
  late List<Color> _targetColors;

  @override
  void initState() {
    super.initState();
    _currentColors = widget.theme.backgroundColors;
    _targetColors = widget.theme.backgroundColors;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _colorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant _AnimatedGradientBg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != oldWidget.theme) {
      _currentColors = [
        Color.lerp(_currentColors[0], _targetColors[0], _colorCtrl.value)!,
        Color.lerp(_currentColors[1], _targetColors[1], _colorCtrl.value)!,
        Color.lerp(_currentColors[2], _targetColors[2], _colorCtrl.value)!,
      ];
      _targetColors = widget.theme.backgroundColors;
      _colorCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final ct = _colorCtrl.value;

        final colors = [
          Color.lerp(_currentColors[0], _targetColors[0], ct)!,
          Color.lerp(_currentColors[1], _targetColors[1], ct)!,
          Color.lerp(_currentColors[2], _targetColors[2], ct)!,
        ];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.5 + 0.5 * math.sin(t * math.pi), 1.0),
              colors: colors,
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
    final theme = ref.read(themeProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          backgroundColor: theme.backgroundColors.last,
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
    final theme = ref.watch(themeProvider);

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
        theme: theme,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Mobile-first bounded canvas
              final maxW = constraints.maxWidth > 800 ? 500.0 : constraints.maxWidth;
              final isCompact = MediaQuery.of(context).size.height < 700;
              
              return Center(
                child: SizedBox(
                  width: maxW,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // ─── HUD ────────────────────────────────
                          _buildHud(gameState, theme, isCompact),

                          // ─── Main content ───────────────────────
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(14, isCompact ? 4 : 8, 14, isCompact ? 6 : 12),
                              child: Column(
                                children: [
                                  _buildWordCard(gameState, theme, isCompact),
                                  SizedBox(height: isCompact ? 6 : 10),
                                  _buildAnswerInput(gameState, theme, isCompact),
                                  SizedBox(height: isCompact ? 6 : 10),
                                  _buildActionButtons(gameState, theme, isCompact),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ─── Feedback overlay ────────────────────
                      if (gameState.feedback != null) _FeedbackOverlay(state: gameState, answerFocus: _answerFocus),
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
  Widget _buildHud(GameState state, ThemeState theme, bool isCompact) {
    final minutes = state.minutes;
    final seconds = state.seconds;
    final timerColor = minutes < 2
        ? _GC.wrong
        : minutes < 5
            ? _GC.gold
            : _GC.correct;

    return _GlassContainer(
      margin: EdgeInsets.fromLTRB(14, isCompact ? 2 : 4, 14, 0),
      padding: EdgeInsets.fromLTRB(14, isCompact ? 4 : 8, 14, isCompact ? 4 : 8),
      borderRadius: 16,
      child: Column(
        children: [
          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: timerColor, size: isCompact ? 18 : 22),
              const SizedBox(width: 6),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: timerColor,
                  fontSize: isCompact ? 24 : 30,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: timerColor.withOpacity(0.5), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 10),

          // Score / Correct / Wrong
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _GlowStat(label: 'Score', value: '${state.score}', color: _GC.gold, isCompact: isCompact),
              _GlowStat(label: 'Correct', value: '${state.correctCount}', color: _GC.correct, isCompact: isCompact),
              _GlowStat(label: 'Wrong', value: '${state.wrongCount}', color: _GC.wrong, isCompact: isCompact),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 10),

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
                      size: isCompact ? 16 : 20,
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
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: isCompact ? 2 : 4),
                decoration: BoxDecoration(
                  color: _GC.glassHighlight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.glassBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.skip_next, color: _GC.pass, size: isCompact ? 14 : 16),
                    const SizedBox(width: 4),
                    Text(
                      '${state.passes}',
                      style: TextStyle(
                        color: _GC.pass,
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 12 : 14,
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
  Widget _buildWordCard(GameState state, ThemeState theme, bool isCompact) {
    final word = state.currentWord;
    if (word == null) return const SizedBox.shrink();

    return _GlassContainer(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
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
              height: isCompact ? 38 : 46,
              child: ElevatedButton.icon(
                onPressed: () => _ttsService.speak(word.spellingBritish),
                icon: Icon(Icons.volume_up_rounded, size: isCompact ? 22 : 28),
                label: Text('Pronounce Word', style: TextStyle(fontSize: isCompact ? 16 : 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _GC.gold,
                  foregroundColor: theme.backgroundColors[0],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 12 : 20),

          // Part of speech
          _GlassInfoLabel(
            icon: Icons.category_rounded,
            label: 'Part of Speech',
            value: word.partOfSpeech,
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 6 : 10),

          // Meaning
          _GlassInfoLabel(
            icon: Icons.menu_book_rounded,
            label: 'Meaning',
            value: word.meaning,
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 6 : 10),

          // Jumbled letters – highlighted
          _GlassInfoLabel(
            icon: Icons.shuffle_rounded,
            label: 'Jumbled Letters',
            value: word.jumbledLetters,
            highlight: true,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Answer Input – Glassmorphism
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAnswerInput(GameState state, ThemeState theme, bool isCompact) {
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
        style: TextStyle(
          fontSize: isCompact ? 18 : 22,
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
            fontSize: isCompact ? 15 : 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 8 : 12),
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
  Widget _buildActionButtons(GameState state, ThemeState theme, bool isCompact) {
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
            height: isCompact ? 40 : 48,
            child: ElevatedButton.icon(
              onPressed: isPlaying ? _submitAnswer : null,
              icon: Icon(Icons.check_circle_rounded, size: isCompact ? 20 : 24),
              label: Text('Submit Answer', style: TextStyle(fontSize: isCompact ? 14 : 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _GC.correct,
                foregroundColor: theme.backgroundColors[0],
                disabledBackgroundColor: theme.glassFill,
                disabledForegroundColor: _GC.textDim,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        SizedBox(height: isCompact ? 6 : 10),

        // Pass & Surrender row
        Row(
          children: [
            Expanded(
              child: _GlassContainer(
                borderRadius: 14,
                child: SizedBox(
                  height: isCompact ? 36 : 42,
                  child: TextButton.icon(
                    onPressed: isPlaying && state.passes > 0 ? _passWord : null,
                    icon: Icon(Icons.skip_next_rounded,
                        size: isCompact ? 16 : 20, color: isPlaying && state.passes > 0 ? _GC.pass : _GC.textDim),
                    label: Text(
                      'Pass (${state.passes})',
                      style: TextStyle(
                        color: isPlaying && state.passes > 0 ? _GC.pass : _GC.textDim,
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 13 : 14,
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
                  height: isCompact ? 36 : 42,
                  child: TextButton.icon(
                    onPressed: isPlaying ? _showSurrenderDialog : null,
                    icon: Icon(Icons.flag_rounded,
                        size: isCompact ? 16 : 20, color: isPlaying ? _GC.wrong : _GC.textDim),
                    label: Text(
                      'Surrender',
                      style: TextStyle(
                        color: isPlaying ? _GC.wrong : _GC.textDim,
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 13 : 14,
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
  // Feedback Overlay – Glass + Glow + 5-second auto-next timer
  // ═══════════════════════════════════════════════════════════════════
}

class _FeedbackOverlay extends ConsumerStatefulWidget {
  final GameState state;
  final FocusNode answerFocus;

  const _FeedbackOverlay({required this.state, required this.answerFocus});

  @override
  ConsumerState<_FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends ConsumerState<_FeedbackOverlay> {
  Timer? _timer;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _timer?.cancel();
          _proceed();
        }
      });
    });
  }

  void _proceed() {
    if (widget.state.status != GameStatus.ended) {
      ref.read(gameProvider.notifier).nextWord();
      widget.answerFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.state.feedback!;

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
        _timer?.cancel();
        _proceed();
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
                  'Continuing in $_countdown...',
                  style: const TextStyle(
                    color: _GC.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to continue immediately',
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
  final bool isCompact;

  const _GlowStat({required this.label, required this.value, required this.color, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isCompact ? 18 : 22,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: _GC.textDim, fontSize: isCompact ? 10 : 11),
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
  final bool isCompact;

  const _GlassInfoLabel({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 6 : 8),
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
              Icon(icon, size: isCompact ? 12 : 14, color: _GC.textDim),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: _GC.textDim,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? (isCompact ? 16 : 20) : (isCompact ? 14 : 15),
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? _GC.gold : _GC.textBright,
              letterSpacing: highlight ? (isCompact ? 2 : 4) : 0,
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
