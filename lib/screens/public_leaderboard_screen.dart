import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:spelling_bee/providers/result_provider.dart';
import 'package:spelling_bee/services/api_service.dart';

/// Public leaderboard screen accessible without login.
/// Supports optional ?grade= query parameter and auto-refreshes every 30 seconds.
class PublicLeaderboardScreen extends ConsumerStatefulWidget {
  final String? initialGrade;

  const PublicLeaderboardScreen({super.key, this.initialGrade});

  @override
  ConsumerState<PublicLeaderboardScreen> createState() => _PublicLeaderboardScreenState();
}

class _PublicLeaderboardScreenState extends ConsumerState<PublicLeaderboardScreen> {
  String? _selectedGrade;
  String _eventName = 'Everest Spelling Bee Open Challenge';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialGrade;
    _loadConfig();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(publicResultsProvider(_selectedGrade));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(publicResultsProvider(_selectedGrade));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1128),
            Color(0xFF102B6E),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Grade filter
                  _buildGradeFilter(),
                  const SizedBox(height: 20),

                  // Live indicator
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE • Auto-refreshes every 30s',
                        style: TextStyle(
                          color: Colors.greenAccent.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      resultsAsync.when(
                        data: (r) => Text(
                          '${r.length} Participants',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Results list
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: resultsAsync.when(
                        data: (results) {
                          if (results.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.emoji_events_outlined,
                                      size: 64, color: Colors.white.withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedGrade != null
                                        ? 'No results for Grade $_selectedGrade yet'
                                        : 'No results yet',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Results will appear here as students complete the championship.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final r = results[index];
                              return _LeaderboardEntry(rank: index + 1, result: r);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                        ),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                              const SizedBox(height: 12),
                              Text('Error loading leaderboard',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7))),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => ref.invalidate(publicResultsProvider(_selectedGrade)),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: const Color(0xFF0A1128),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFD700).withOpacity(0.15),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 2),
          ),
          child: const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _eventName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                'LEADERBOARD',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(publicResultsProvider(_selectedGrade)),
        ),
      ],
    );
  }

  Widget _buildGradeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _GradeChip(
            label: 'All Grades',
            isSelected: _selectedGrade == null,
            onTap: () => setState(() => _selectedGrade = null),
          ),
          ...List.generate(10, (i) {
            final grade = (i + 1).toString();
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _GradeChip(
                label: 'Grade $grade',
                isSelected: _selectedGrade == grade,
                onTap: () => setState(() => _selectedGrade = grade),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0A1128) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardEntry extends StatelessWidget {
  final int rank;
  final Result result;

  const _LeaderboardEntry({required this.rank, required this.result});

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    bool isTop3 = rank <= 3;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.white54;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop3 ? rankColor.withOpacity(0.08) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3 ? rankColor.withOpacity(0.3) : Colors.white.withOpacity(0.06),
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow: isTop3
            ? [BoxShadow(color: rankColor.withOpacity(0.1), blurRadius: 8)]
            : [],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: isTop3
                  ? Icon(Icons.emoji_events, color: rankColor, size: 22)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Name & grade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Grade ${result.grade}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.finalScore} pts',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${result.correctAnswers}✓ ${result.wrongAnswers}✗ ${result.accuracy.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Time: ${result.timeTakenSeconds}s',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
