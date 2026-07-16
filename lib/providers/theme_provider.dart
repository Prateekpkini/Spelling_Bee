import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spelling_bee/providers/game_provider.dart';

enum GameStage {
  baseCamp,
  icefall,
  clouds,
  summit,
}

class ThemeState {
  final GameStage stage;
  final List<Color> backgroundColors;
  final Color accentColor;
  final Color glassFill;
  final Color glassBorder;

  const ThemeState({
    required this.stage,
    required this.backgroundColors,
    required this.accentColor,
    required this.glassFill,
    required this.glassBorder,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeState &&
        other.stage == stage &&
        other.accentColor == accentColor &&
        other.glassFill == glassFill &&
        other.glassBorder == glassBorder;
  }

  @override
  int get hashCode {
    return stage.hashCode ^
        accentColor.hashCode ^
        glassFill.hashCode ^
        glassBorder.hashCode;
  }
}

final themeProvider = Provider<ThemeState>((ref) {
  final gameState = ref.watch(gameProvider);
  final correctAnswers = gameState.correctCount;

  int stageIndex = correctAnswers ~/ 3;
  if (stageIndex > 3) stageIndex = 3;

  final stage = GameStage.values[stageIndex];

  switch (stage) {
    case GameStage.baseCamp:
      return ThemeState(
        stage: stage,
        backgroundColors: const [
          Color(0xFF0A0E27),
          Color(0xFF141852),
          Color(0xFF1A0A3E)
        ], // Midnight blue
        accentColor: const Color(0xFF81D4FA), // Cool misty blue
        glassFill: const Color(0x18FFFFFF),
        glassBorder: const Color(0x30FFFFFF),
      );
    case GameStage.icefall:
      return ThemeState(
        stage: stage,
        backgroundColors: const [
          Color(0xFF003049),
          Color(0xFF00509d),
          Color(0xFF00296b)
        ], // Deep ice
        accentColor: const Color(0xFF48CAE4), // Ice blue
        glassFill: const Color(0x20FFFFFF),
        glassBorder: const Color(0x40FFFFFF),
      );
    case GameStage.clouds:
      return ThemeState(
        stage: stage,
        backgroundColors: const [
          Color(0xFF240046),
          Color(0xFF3C096C),
          Color(0xFF5A189A)
        ], // Purple clouds
        accentColor: const Color(0xFFE0AAFF), // Soft purple/pink
        glassFill: const Color(0x25FFFFFF),
        glassBorder: const Color(0x45FFFFFF),
      );
    case GameStage.summit:
      return ThemeState(
        stage: stage,
        backgroundColors: const [
          Color(0xFF0A0E27),
          Color(0xFF1B263B),
          Color(0xFF1A1A3E)
        ], // Navy
        accentColor: const Color(0xFFFFD54F), // Deep rich gold
        glassFill: const Color(0x25FFD54F), // Gold-tinted glass
        glassBorder: const Color(0x60FFD54F),
      );
  }
});
