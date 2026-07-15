import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/providers/game_provider.dart';
import 'package:spelling_bee/services/tts_service.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String studentId;
  const GameScreen({super.key, required this.studentId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
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
      builder: (ctx) => AlertDialog(
        title: const Text('Surrender?'),
        content: const Text(
          'Are you sure you want to end the championship? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continue Playing'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).surrender();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Surrender'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    // Start the game on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startIfNeeded();
    });

    // Navigate to results when game ends
    if (gameState.status == GameStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/play/result/${widget.studentId}');
      });
    }

    return ResponsiveScaffold(
      child: Stack(
        children: [
          Column(
            children: [
              // ─── HUD Bar ───────────────────────────────────────
              _buildHud(gameState),

              // ─── Main content ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Word card
                      _buildWordCard(gameState),
                      const SizedBox(height: 20),

                      // Answer input
                      _buildAnswerInput(gameState),
                      const SizedBox(height: 20),

                      // Action buttons
                      _buildActionButtons(gameState),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ─── Feedback overlay ────────────────────────────────
          if (gameState.feedback != null) _buildFeedbackOverlay(gameState),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HUD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHud(GameState state) {
    final minutes = state.minutes;
    final seconds = state.seconds;
    final timerColor = minutes < 2
        ? AppColors.error
        : minutes < 5
            ? AppColors.warning
            : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Timer row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: timerColor, size: 22),
                const SizedBox(width: 6),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HudStat(label: 'Score', value: '${state.score}', color: AppColors.gold),
                _HudStat(label: 'Correct', value: '${state.correctCount}', color: AppColors.success),
                _HudStat(label: 'Wrong', value: '${state.wrongCount}', color: AppColors.error),
              ],
            ),
            const SizedBox(height: 8),

            // Shields & Passes row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shields as hearts
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        i < state.shields ? Icons.favorite : Icons.favorite_border,
                        color: i < state.shields
                            ? const Color(0xFFFF4D6D)
                            : Colors.white24,
                        size: 20,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 20),
                // Passes
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.skip_next, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${state.passes}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Word Card
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWordCard(GameState state) {
    final word = state.currentWord;
    if (word == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pronounce button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _ttsService.speak(word.spellingBritish),
              icon: const Icon(Icons.volume_up, size: 28),
              label: const Text(
                'Pronounce Word',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.primaryDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Part of speech
          _InfoLabel(
            icon: Icons.category,
            label: 'Part of Speech',
            value: word.partOfSpeech,
          ),
          const SizedBox(height: 12),

          // Meaning
          _InfoLabel(
            icon: Icons.menu_book,
            label: 'Meaning',
            value: word.meaning,
          ),
          const SizedBox(height: 12),

          // Jumbled letters
          _InfoLabel(
            icon: Icons.shuffle,
            label: 'Jumbled Letters',
            value: word.jumbledLetters,
            highlight: true,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Answer Input
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAnswerInput(GameState state) {
    final isPlaying = state.status == GameStatus.playing;

    return TextField(
      controller: _answerController,
      focusNode: _answerFocus,
      autofocus: true,
      enabled: isPlaying,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submitAnswer(),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 2),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryDeep, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 2.5),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Action Buttons
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildActionButtons(GameState state) {
    final isPlaying = state.status == GameStatus.playing;

    return Column(
      children: [
        // Submit button (full width, primary)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isPlaying ? _submitAnswer : null,
            icon: const Icon(Icons.check_circle),
            label: const Text('Submit Answer'),
          ),
        ),
        const SizedBox(height: 10),

        // Pass & Surrender row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isPlaying && state.passes > 0 ? _passWord : null,
                  icon: const Icon(Icons.skip_next, size: 20),
                  label: Text('Pass (${state.passes})'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isPlaying ? _showSurrenderDialog : null,
                  icon: const Icon(Icons.flag, size: 20),
                  label: const Text('Surrender'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: Size.zero,
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
  // Feedback Overlay
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildFeedbackOverlay(GameState state) {
    final feedback = state.feedback!;

    Color bgColor;
    Color accentColor;
    IconData icon;

    switch (feedback.type) {
      case FeedbackType.correct:
      case FeedbackType.reward:
        bgColor = AppColors.successLight;
        accentColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case FeedbackType.wrong:
        bgColor = AppColors.errorLight;
        accentColor = AppColors.error;
        icon = Icons.cancel;
        break;
      case FeedbackType.passed:
        bgColor = AppColors.warningLight;
        accentColor = AppColors.warning;
        icon = Icons.skip_next;
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
        color: Colors.black26,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accentColor, size: 56),
                const SizedBox(height: 12),
                Text(
                  feedback.message,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                if (feedback.rewards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...feedback.rewards.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🎁 $r',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDeep,
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
                    color: accentColor.withValues(alpha: 0.7),
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

class _HudStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HudStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoLabel({
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
        color: highlight ? AppColors.gold.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 15,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: highlight ? 3 : 0,
            ),
          ),
        ],
      ),
    );
  }
}
