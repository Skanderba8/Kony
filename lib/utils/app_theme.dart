import 'package:flutter/material.dart';

// Centralized theme utility to maintain consistent styling across the app
class AppTheme {
  // Primary app color - blue theme
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.blue;
  static const Color accentColor = Colors.blueAccent;

  // Button styles
  static ButtonStyle primaryButtonStyle({bool isSmall = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 16,
        vertical: isSmall ? 8 : 10,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static ButtonStyle outlineButtonStyle({bool isSmall = false}) {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 16,
        vertical: isSmall ? 8 : 10,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // Create the app theme
  static ThemeData getTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        accentColor: accentColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonTheme.of(
        ThemeData.light().copyWith(
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: primaryButtonStyle(),
              ),
            )
            as BuildContext,
      ),
      outlinedButtonTheme: OutlinedButtonTheme.of(
        ThemeData.light().copyWith(
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: outlineButtonStyle(),
              ),
            )
            as BuildContext,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }
}
