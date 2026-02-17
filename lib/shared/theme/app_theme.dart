import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand colours
  static const Color _primaryColor = Color(0xFF6C63FF);   // violet
  static const Color _accentColor = Color(0xFF00D4AA);    // teal
  static const Color _surfaceColor = Color(0xFF1E1E2E);   // dark surface
  static const Color _bgColor = Color(0xFF12121E);        // near-black bg
  static const Color _userBubble = Color(0xFF6C63FF);
  static const Color _assistantBubble = Color(0xFF2A2A40);
  static const Color _textPrimary = Color(0xFFF0F0F8);
  static const Color _textSecondary = Color(0xFF9090B0);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: _surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _textPrimary,
      ),
      scaffoldBackgroundColor: _bgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceColor,
        hintStyle: const TextStyle(color: _textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: _surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      extensions: const [
        VeroColors(
          userBubble: _userBubble,
          assistantBubble: _assistantBubble,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          accent: _accentColor,
        ),
      ],
    );
  }
}

/// Custom theme extension for Vero-specific colours.
@immutable
class VeroColors extends ThemeExtension<VeroColors> {
  final Color userBubble;
  final Color assistantBubble;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const VeroColors({
    required this.userBubble,
    required this.assistantBubble,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  VeroColors copyWith({
    Color? userBubble,
    Color? assistantBubble,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
  }) {
    return VeroColors(
      userBubble: userBubble ?? this.userBubble,
      assistantBubble: assistantBubble ?? this.assistantBubble,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
    );
  }

  @override
  VeroColors lerp(VeroColors? other, double t) {
    if (other is! VeroColors) return this;
    return VeroColors(
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
      assistantBubble: Color.lerp(assistantBubble, other.assistantBubble, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
