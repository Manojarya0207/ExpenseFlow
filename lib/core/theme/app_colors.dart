import 'package:flutter/material.dart';

/// Central palette. A professional deep-blue primary on white surfaces with
/// money-semantic accents (green = income, red = expense) reused across
/// cards, tiles and charts.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color income = Color(0xFF2E9E5B);
  static const Color expense = Color(0xFFE5484D);
  static const Color savings = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);

  /// A stable, reasonably distinct color per index for chart segments.
  static const List<Color> chartPalette = <Color>[
    Color(0xFF1565C0),
    Color(0xFFE5484D),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
    Color(0xFF6366F1),
    Color(0xFFF97316),
  ];

  static Color chartColor(int index) =>
      chartPalette[index % chartPalette.length];
}
