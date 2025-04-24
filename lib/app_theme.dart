import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final Color _seedColor = Colors.blueAccent.shade700;

  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData(brightness: Brightness.dark);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    final textTheme = _buildTextTheme(baseTheme.textTheme, colorScheme);

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        elevation: 0, // Modern flat look
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainer,
      ),
      cardColor: colorScheme.surfaceContainer,
      canvasColor: colorScheme.surfaceContainerLowest,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle:
              GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle:
              GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle:
              GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
          foregroundColor: colorScheme.primary,
        ),
      ),
      sliderTheme: SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.onSurface.withOpacity(0.2),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Fill the background
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          menuStyle: MenuStyle(
            backgroundColor:
                MaterialStatePropertyAll(colorScheme.surfaceContainerHighest),
            surfaceTintColor: MaterialStatePropertyAll(colorScheme.surfaceTint),
          )),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: GoogleFonts.lato(fontSize: 13, color: colorScheme.onPrimary),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 500),
      ),
      extensions: <ThemeExtension<dynamic>>{
        CardThemes(
          filled: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            color: colorScheme.surfaceContainerHighest,
          ),
          outlined: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            color: colorScheme.surface,
          ),
        )
      },
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, ColorScheme colorScheme) {
    return GoogleFonts.latoTextTheme(base)
        .copyWith(
          // Display Styles (Orbitron)
          displayLarge: GoogleFonts.orbitron(
              textStyle: base.displayLarge?.copyWith(
                  fontSize: 57, fontWeight: FontWeight.bold)), // M3 Sizes
          displayMedium: GoogleFonts.orbitron(
              textStyle: base.displayMedium
                  ?.copyWith(fontSize: 45, fontWeight: FontWeight.w600)),
          displaySmall: GoogleFonts.orbitron(
              textStyle: base.displaySmall?.copyWith(fontSize: 36)),

          // Headline Styles (Orbitron)
          headlineLarge: GoogleFonts.orbitron(
              textStyle:
                  base.headlineLarge?.copyWith(fontSize: 32)), // M3 Sizes
          headlineMedium: GoogleFonts.orbitron(
              textStyle: base.headlineMedium?.copyWith(fontSize: 28)),
          headlineSmall: GoogleFonts.orbitron(
              textStyle: base.headlineSmall?.copyWith(fontSize: 24)),

          // Title Styles (Lato - Bolder)
          titleLarge: GoogleFonts.lato(
              textStyle: base.titleLarge?.copyWith(
                  fontSize: 22, fontWeight: FontWeight.w600)), // M3 Sizes
          titleMedium: GoogleFonts.lato(
              textStyle: base.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15)),
          titleSmall: GoogleFonts.lato(
              textStyle: base.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1)),

          // Body Styles (Lato - Regular)
          bodyLarge: GoogleFonts.lato(
              textStyle: base.bodyLarge
                  ?.copyWith(fontSize: 16, letterSpacing: 0.5)), // M3 Sizes
          bodyMedium: GoogleFonts.lato(
              textStyle:
                  base.bodyMedium?.copyWith(fontSize: 14, letterSpacing: 0.25)),
          bodySmall: GoogleFonts.lato(
              textStyle: base.bodySmall?.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  color: colorScheme
                      .onSurfaceVariant)), // Use variant color for less emphasis

          // Label Styles (Lato - Bold/Medium)
          labelLarge: GoogleFonts.lato(
              textStyle: base.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1)), // M3 Sizes
          labelMedium: GoogleFonts.lato(
              textStyle: base.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          labelSmall: GoogleFonts.lato(
              textStyle: base.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
        )
        .apply(
          // Apply base colors from the color scheme
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
          // Decoration colors are usually derived or set specifically
        );
  }
}

// Helper extension to access themed card styles easily
@immutable
class CardThemes extends ThemeExtension<CardThemes> {
  const CardThemes({
    required this.filled,
    required this.outlined,
  });

  final CardTheme? filled;
  final CardTheme? outlined;

  @override
  CardThemes copyWith({CardTheme? filled, CardTheme? outlined}) {
    return CardThemes(
      filled: filled ?? this.filled,
      outlined: outlined ?? this.outlined,
    );
  }

  @override
  CardThemes lerp(ThemeExtension<CardThemes>? other, double t) {
    if (other is! CardThemes) {
      return this;
    }
    // Basic lerp, might need refinement for complex properties
    return CardThemes(
      filled: CardTheme.lerp(filled, other.filled, t),
      outlined: CardTheme.lerp(outlined, other.outlined, t),
    );
  }
}
