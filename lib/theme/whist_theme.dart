import 'package:flutter/material.dart';

/// Bright card-table accents on a deep navy background.
abstract final class WhistPalette {
  static const background = Color(0xFF111827);
  static const surface = Color(0xFF202C40);
  static const surfaceRaised = Color(0xFF2B3A52);
  static const accent = Color(0xFFB78BFF);
  static const accentMuted = Color(0xFF54E8D3);
  static const gold = Color(0xFFFFD166);
  static const text = Color(0xFFF8FAFF);
  static const textMuted = Color(0xFFD1DBE9);
  static const outline = Color(0xFF63748E);
  static const danger = Color(0xFFFF6675);
}

ThemeData buildWhistTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: WhistPalette.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: WhistPalette.accent,
    onPrimary: WhistPalette.background,
    primaryContainer: WhistPalette.surfaceRaised,
    onPrimaryContainer: WhistPalette.text,
    secondary: WhistPalette.accentMuted,
    onSecondary: WhistPalette.background,
    tertiary: WhistPalette.gold,
    onTertiary: WhistPalette.background,
    surface: WhistPalette.background,
    onSurface: WhistPalette.text,
    onSurfaceVariant: WhistPalette.textMuted,
    outline: WhistPalette.outline,
    error: WhistPalette.danger,
    onError: WhistPalette.background,
    errorContainer: const Color(0xFF6D2539),
    onErrorContainer: WhistPalette.text,
  );
  const radius = BorderRadius.all(Radius.circular(12));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colors,
    scaffoldBackgroundColor: WhistPalette.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: WhistPalette.background,
      foregroundColor: WhistPalette.text,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: WhistPalette.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: WhistPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: WhistPalette.outline, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WhistPalette.accent,
        foregroundColor: WhistPalette.background,
        disabledBackgroundColor: WhistPalette.surfaceRaised,
        disabledForegroundColor: WhistPalette.textMuted,
        minimumSize: const Size(0, 48),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WhistPalette.text,
        side: const BorderSide(color: WhistPalette.outline),
        minimumSize: const Size(0, 48),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: WhistPalette.accent),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: WhistPalette.surface,
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: WhistPalette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: WhistPalette.accent, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: WhistPalette.surfaceRaised,
      labelStyle: const TextStyle(color: WhistPalette.accentMuted),
      side: const BorderSide(color: WhistPalette.outline),
      shape: const RoundedRectangleBorder(borderRadius: radius),
    ),
    dividerTheme: const DividerThemeData(color: WhistPalette.outline),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(WhistPalette.surfaceRaised),
      dataRowColor: const WidgetStatePropertyAll(WhistPalette.surface),
      dividerThickness: 0.6,
      headingTextStyle: const TextStyle(
        color: WhistPalette.accentMuted,
        fontWeight: FontWeight.w700,
      ),
      dataTextStyle: const TextStyle(color: WhistPalette.text),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: WhistPalette.accent,
      thumbColor: WhistPalette.accent,
      inactiveTrackColor: WhistPalette.outline,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: WhistPalette.text,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        color: WhistPalette.text,
        fontSize: 23,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: WhistPalette.text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: WhistPalette.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: WhistPalette.textMuted, fontSize: 16),
      bodyMedium: TextStyle(color: WhistPalette.textMuted, fontSize: 14),
      labelLarge: TextStyle(
        color: WhistPalette.accentMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}
