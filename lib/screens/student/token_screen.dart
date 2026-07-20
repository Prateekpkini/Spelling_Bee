import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/models/student.dart';
import 'package:spelling_bee/services/api_service.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';

/// Token validation + student intro screen.
class TokenScreen extends ConsumerStatefulWidget {
  final String token;
  const TokenScreen({super.key, required this.token});

  @override
  ConsumerState<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends ConsumerState<TokenScreen> {
  late Future<Map<String, dynamic>> _validationFuture;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _validationFuture = apiService.validateToken(widget.token);
  }

  void _startChampionship(Student student) {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    // Navigate to the preload screen which handles data download + airplane mode flow
    context.go('/play/preload?token=${widget.token}');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _validationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Validating your game link...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildError('An error occurred. Please try again.');
          }

          final result = snapshot.data!;
          final status = result['status'];
          final gameSettings = result['settings'] as Map<String, dynamic>? ?? {};

          if (status == 'not_found') {
            return _buildError(
              'Invalid game link. This link does not exist or has been removed.',
            );
          } else if (status == 'used') {
            return _buildUsed();
          } else if (status == 'active') {
            final student = Student.fromJson(result['student']);
            final eventName = result['event_name'] ?? 'Everest Spelling Bee Open Challenge';
            return _buildIntro(student, eventName, gameSettings);
          }
          
          return _buildError('Unknown error.');
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Link Invalid',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_clock, color: AppColors.warning, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Link Already Used',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'This game link has already been used. Each link can only be used once.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(Student student, String eventName, Map<String, dynamic> settings) {
    final timerMinutes = ((settings['timer_seconds'] ?? 1800) as num) ~/ 60;
    final shields = (settings['initial_shields'] ?? 5) as num;
    final passes = (settings['initial_passes'] ?? 5) as num;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Championship branding
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDeep.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              eventName,
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Student details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                children: [
                  Text(
                    'Confirm Your Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow('Name', student.name),
                  _DetailRow('Grade', student.grade),
                  _DetailRow('Section', student.section),
                  _DetailRow('School', student.schoolName),
                  _DetailRow('City', student.city),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rules summary — dynamic from admin settings
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDeep.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Rules', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _RuleLine(Icons.timer, '$timerMinutes minutes to spell as many words as possible'),
                  _RuleLine(Icons.shield, '$shields Shields – wrong answers cost a shield'),
                  _RuleLine(Icons.skip_next, '$passes Passes – skip a word with no penalty'),
                  _RuleLine(Icons.star, 'Earn bonus time, passes & shields for streaks'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isStarting ? null : () => _startChampionship(student),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.primaryDeep,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                child: _isStarting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start Championship'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RuleLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
