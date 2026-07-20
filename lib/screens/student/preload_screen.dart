import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/models/student.dart';
import 'package:spelling_bee/models/word.dart';
import 'package:spelling_bee/providers/game_provider.dart';
import 'package:spelling_bee/services/api_service.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';

/// Preload screen: downloads all game data, then shows airplane mode gate.
class PreloadScreen extends ConsumerStatefulWidget {
  final String token;
  const PreloadScreen({super.key, required this.token});

  @override
  ConsumerState<PreloadScreen> createState() => _PreloadScreenState();
}

enum _PreloadPhase { downloading, ready, error }

class _PreloadScreenState extends ConsumerState<PreloadScreen>
    with SingleTickerProviderStateMixin {
  _PreloadPhase _phase = _PreloadPhase.downloading;
  String _errorMessage = '';
  String _statusText = 'Connecting to server...';
  double _progress = 0.0;

  // Cached data from preload
  late Student _student;
  late List<Word> _words;
  late Map<String, dynamic> _settings;
  late String _eventName;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _preloadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _preloadData() async {
    try {
      setState(() {
        _statusText = 'Downloading question bank...';
        _progress = 0.2;
      });

      final response = await apiService.preloadGameData(widget.token);

      if (!mounted) return;

      setState(() {
        _statusText = 'Processing questions...';
        _progress = 0.6;
      });

      // Parse the response
      _student = Student.fromJson(response['student']);

      final wordsData = response['words'] as List<dynamic>;
      _words = wordsData.map((e) => Word.fromJson(e)).toList();

      _settings = response['settings'];
      _eventName = response['event_name'] ?? 'Everest Spelling Bee Open Challenge';

      if (_words.isEmpty) {
        setState(() {
          _phase = _PreloadPhase.error;
          _errorMessage = 'No words found for Grade ${_student.grade}. Please contact your examiner.';
        });
        return;
      }

      setState(() {
        _statusText = 'Preparing game engine...';
        _progress = 0.9;
      });

      // Brief delay for visual smoothness
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _phase = _PreloadPhase.ready;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _PreloadPhase.error;
          _errorMessage = 'Failed to download game data. Please check your internet connection and try again.\n\nError: $e';
        });
      }
    }
  }

  void _startChampionship() {
    // Initialize game with pre-loaded data in offline mode
    ref.read(gameProvider.notifier).initGame(
      wordBank: _words,
      studentId: _student.id,
      studentName: _student.name,
      grade: _student.grade,
      timerSeconds: _settings['timer_seconds'] ?? 1800,
      initialShields: _settings['initial_shields'] ?? 5,
      initialPasses: _settings['initial_passes'] ?? 5,
      offlineMode: true,
      gameToken: widget.token,
    );

    // Navigate to game
    context.go('/play/game/${_student.id}');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _phase == _PreloadPhase.downloading
              ? _buildDownloading()
              : _phase == _PreloadPhase.ready
                  ? _buildReady()
                  : _buildError(),
        ),
      ),
    );
  }

  Widget _buildDownloading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated download icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.1),
              child: child,
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryDeep.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.cloud_download_outlined,
              color: AppColors.primaryDeep,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Preparing Your Test',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _statusText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Progress bar
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.primaryDeep.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeep),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${(_progress * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildReady() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 50,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'All Data Downloaded!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.success,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${_words.length} questions loaded for Grade ${_student.grade}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Airplane mode instruction card
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
              const Icon(Icons.airplanemode_active, color: Color(0xFFFF9800), size: 36),
              const SizedBox(height: 12),
              Text(
                'You can now safely activate Airplane Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The test will run entirely offline. No internet connection is needed during the championship.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF795548),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Student info summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Column(
            children: [
              Text(
                _eventName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.gold,
                      letterSpacing: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              _InfoRow('Student', _student.name),
              _InfoRow('Grade', _student.grade),
              if (_student.schoolName.isNotEmpty) _InfoRow('School', _student.schoolName),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Start button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _startChampionship,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('Start Championship'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.primaryDeep,
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You may activate airplane mode before or after pressing Start.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.cloud_off, color: AppColors.error, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Download Failed',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _phase = _PreloadPhase.downloading;
                _progress = 0.0;
              });
              _preloadData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
