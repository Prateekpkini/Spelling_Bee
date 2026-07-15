import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/models/result.dart';
import 'package:spelling_bee/providers/result_provider.dart';
import 'package:spelling_bee/services/export_service.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _exporting = false;
  final _exportService = ExportService();

  Future<void> _exportExcel(List<Result> results) async {
    setState(() => _exporting = true);
    try {
      await _exportService.exportToExcel(results);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel file exported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf(List<Result> results) async {
    setState(() => _exporting = true);
    try {
      await _exportService.exportToPdf(results);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF file exported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(resultsStreamProvider);

    return ResponsiveScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Leaderboard'),
      ),
      child: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading results: $e')),
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No results yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Results will appear here after students complete the championship.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Export buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exporting ? null : () => _exportExcel(results),
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: const Text('Excel'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exporting ? null : () => _exportPdf(results),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('PDF'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${results.length} Participants',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),

              // Results list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final r = results[index];
                    return _ResultCard(rank: index + 1, result: r);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int rank;
  final Result result;

  const _ResultCard({required this.rank, required this.result});

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = AppColors.textSecondary;
      rankIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 22)
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
          const SizedBox(width: 12),

          // Name & grade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.studentName,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Grade ${result.grade}',
                  style: Theme.of(context).textTheme.bodySmall,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDeep,
                    ),
              ),
              Text(
                '${result.correctAnswers}✓ ${result.wrongAnswers}✗ ${result.accuracy.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
