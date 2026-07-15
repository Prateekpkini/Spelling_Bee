import 'package:flutter/material.dart';
import 'package:spelling_bee/app/theme.dart';

/// A responsive scaffold that wraps content in a bounded container on
/// desktop/tablet viewports, while rendering full-bleed on mobile.
///
/// - Mobile (<= 600px): Full-bleed, no decoration
/// - Desktop/Tablet (> 600px): Centered 500px-wide card with shadow on
///   a themed gradient background
class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 600;

        if (isMobile) {
          return Scaffold(
            appBar: appBar,
            body: SafeArea(child: child),
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar,
          );
        }

        // Desktop/tablet: themed background with centered bounded container
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgGradientStart,
                  AppColors.bgGradientEnd,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 500,
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Scaffold(
                  appBar: appBar,
                  body: SafeArea(child: child),
                  floatingActionButton: floatingActionButton,
                  bottomNavigationBar: bottomNavigationBar,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
