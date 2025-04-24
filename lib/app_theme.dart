import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final Color _seedColor = Colors.blueAccent;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    textTheme: _buildTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).surfaceContainerHighest,
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).onSurface,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    sliderTheme: SliderThemeData(
      showValueIndicator: ShowValueIndicator.always,
      activeTrackColor: _seedColor.withOpacity(0.8),
      inactiveTrackColor: Colors.white.withOpacity(0.2),
      thumbColor: _seedColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 14,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 14,
      ),
    )),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: GoogleFonts.lato(fontSize: 13, color: Colors.black),
      decoration: BoxDecoration(
        color: _seedColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.latoTextTheme(base)
        .copyWith(
          displayLarge: GoogleFonts.orbitron(
              textStyle: base.displayLarge?.copyWith(fontSize: 60)),
          displayMedium: GoogleFonts.orbitron(
              textStyle: base.displayMedium?.copyWith(fontSize: 48)),
          displaySmall: GoogleFonts.orbitron(
              textStyle: base.displaySmall?.copyWith(fontSize: 36)),
          headlineLarge: GoogleFonts.orbitron(
              textStyle: base.headlineLarge?.copyWith(fontSize: 34)),
          headlineMedium: GoogleFonts.orbitron(
              textStyle: base.headlineMedium?.copyWith(fontSize: 26)),
          headlineSmall: GoogleFonts.orbitron(
              textStyle: base.headlineSmall?.copyWith(fontSize: 22)),
          titleLarge: GoogleFonts.lato(
              textStyle: base.titleLarge
                  ?.copyWith(fontSize: 24, fontWeight: FontWeight.w600)),
          titleMedium: GoogleFonts.lato(
              textStyle: base.titleMedium
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
          titleSmall: GoogleFonts.lato(
              textStyle: base.titleSmall
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
          bodyLarge: GoogleFonts.lato(
              textStyle: base.bodyLarge?.copyWith(fontSize: 17)),
          bodyMedium: GoogleFonts.lato(
              textStyle: base.bodyMedium?.copyWith(fontSize: 15)),
          bodySmall: GoogleFonts.lato(
              textStyle: base.bodySmall
                  ?.copyWith(fontSize: 13, color: Colors.white70)),
          labelLarge: GoogleFonts.lato(
              textStyle: base.labelLarge
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          labelMedium: GoogleFonts.lato(
              textStyle: base.labelMedium?.copyWith(fontSize: 13)),
          labelSmall: GoogleFonts.lato(
              textStyle: base.labelSmall?.copyWith(fontSize: 12)),
        )
        .apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        );
  }
}
