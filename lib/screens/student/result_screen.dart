import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/providers/game_provider.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';

import 'package:spelling_bee/services/api_service.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String studentId;
  const ResultScreen({super.key, required this.studentId});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  String _eventName = 'Everest Spelling Bee Open Challenge';
  bool _isUploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await apiService.getConfig();
      if (mounted) {
        setState(() {
          _eventName = config['event_name'] ?? _eventName;
        });
      }
    } catch (e) {
      debugPrint('Failed to load config: $e');
    }
  }

  Future<void> _uploadResults() async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      // Check connectivity first
      final isOnline = await apiService.checkConnectivity();
      if (!isOnline) {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadError =
                'No internet connection detected. Please turn off Airplane Mode and try again.';
          });
        }
        return;
      }

      // Submit the result
      await ref.read(gameProvider.notifier).submitResultManually();

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = 'Upload failed: $e\n\nPlease try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

    // Determine if we need to show the upload flow
    final needsUpload = gameState.offlineMode && !gameState.resultSubmitted;
    final uploadSuccess = gameState.offlineMode && gameState.resultSubmitted;

    return ResponsiveScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              _eventName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
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

            // ── Offline Upload Section ──────────────────────────────
            if (needsUpload) ...[
              // Airplane mode off instruction
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF9800)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.airplanemode_inactive,
                        color: Color(0xFFFF9800), size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Test Complete! Please turn off Airplane Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your results are saved locally. Turn off Airplane Mode and tap the button below to upload them to the server.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF795548),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error message (if upload failed)
              if (_uploadError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _uploadError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Upload button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadResults,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload, size: 24),
                  label: Text(_isUploading
                      ? 'Uploading...'
                      : 'Upload Results'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],

            // ── Upload Success Section ─────────────────────────────
            if (uploadSuccess) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_done,
                        color: AppColors.success, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Results Uploaded Successfully!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your championship results have been saved to the server. You may now close this window.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // ── Normal (non-offline) completion message ────────────
            if (!gameState.offlineMode) ...[
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
            ],
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
