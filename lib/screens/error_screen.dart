import 'package:flutter/material.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';

class ErrorScreen extends StatelessWidget {
  final String? message;
  const ErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      child: Center(
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
                'Something Went Wrong',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message ?? 'An unexpected error occurred. Please contact the examiner.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
