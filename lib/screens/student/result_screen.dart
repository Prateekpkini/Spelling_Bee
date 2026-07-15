import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/providers/game_provider.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';

class ResultScreen extends ConsumerWidget {
  final String studentId;
  const ResultScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    String endMessage;
    IconData endIcon;
    Color endColor;

    switch (gameState.endReason) {
      case EndReason.timerExpired:
        endMessage = 'Time\'s up!';
        endIcon = Icons.timer_off;
        endColor = AppColors.warning;
        break;
      case EndReason.shieldsLost:
        endMessage = 'All shields lost!';
        endIcon = Icons.shield;
        endColor = AppColors.error;
        break;
      case EndReason.surrendered:
        endMessage = 'Championship surrendered';
        endIcon = Icons.flag;
        endColor = AppColors.textSecondary;
        break;
      case EndReason.allWordsCleared:
        endMessage = 'All words completed! 🎉';
        endIcon = Icons.emoji_events;
        endColor = AppColors.gold;
        break;
      default:
        endMessage = 'Championship ended';
        endIcon = Icons.done_all;
        endColor = AppColors.primaryDeep;
    }

    return ResponsiveScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // End reason badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: endColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(endIcon, color: endColor, size: 40),
            ),
            const SizedBox(height: 16),
            Text(endMessage, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              gameState.studentName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 28),

            // Score hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDeep, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'FINAL SCORE',
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${gameState.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats grid
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Correct',
                          value: '${gameState.correctCount}',
                          icon: Icons.check_circle,
                          color: AppColors.success,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: 'Wrong',
                          value: '${gameState.wrongCount}',
                          icon: Icons.cancel,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Accuracy',
                          value: '${gameState.accuracy.toStringAsFixed(1)}%',
                          icon: Icons.gps_fixed,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: 'Passes Used',
                          value: '${gameState.passesUsed}',
                          icon: Icons.skip_next,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Time Left',
                          value: '${gameState.minutes}:${gameState.seconds.toString().padLeft(2, '0')}',
                          icon: Icons.timer,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: 'Shields Left',
                          value: '${gameState.shields}',
                          icon: Icons.shield,
                          color: const Color(0xFFFF4D6D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Completion message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDeep.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your results have been saved. You may now close this window.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
