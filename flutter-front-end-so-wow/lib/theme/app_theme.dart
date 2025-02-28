import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors - Enhanced for premium look
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan
  static const Color accentColor = Color(0xFFF472B6); // Pink
  
  // Background colors - Richer dark theme
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color surfaceColor = Color(0xFF1E293B); // Slate 800
  static const Color cardColor = Color(0xFF334155); // Slate 700
  
  // Text colors - Improved contrast and readability
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFFCBD5E1); // Slate 300
  
  // Status colors - More vibrant and consistent
  static const Color successColor = Color(0xFF10B981); // Emerald 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color infoColor = Color(0xFF3B82F6); // Blue 500
  
  // Additional UI colors for premium feel
  static const Color highlightColor = Color(0xFF8B5CF6); // Violet 500
  static const Color subtleAccent = Color(0xFF475569); // Slate 600
  static const Color gradientStart = Color(0xFF6366F1); // Indigo 500
  static const Color gradientEnd = Color(0xFF8B5CF6); // Violet 500

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: darkBackground,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: textPrimary,
      onSecondary: textPrimary,
      onTertiary: textPrimary,
      onBackground: textPrimary,
      onSurface: textPrimary,
      onError: textPrimary,
      surfaceVariant: subtleAccent,
      outline: Color(0xFF64748B), // Slate 500
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: cardColor,
    dividerColor: Colors.white12,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme.copyWith(
        displayLarge: const TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: const TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
    ),
    // Note: cardTheme updated below
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return primaryColor.withOpacity(0.5);
          }
          return primaryColor;
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          return textPrimary;
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return Colors.white.withOpacity(0.2);
          }
          return Colors.transparent;
        }),
        elevation: MaterialStateProperty.resolveWith<double>((states) {
          if (states.contains(MaterialState.pressed)) {
            return 0;
          }
          if (states.contains(MaterialState.hovered)) {
            return 2;
          }
          return 0;
        }),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        shape: MaterialStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        animationDuration: const Duration(milliseconds: 200),
        shadowColor: MaterialStateProperty.all<Color>(
          primaryColor.withOpacity(0.5),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return primaryColor.withOpacity(0.5);
          }
          return primaryColor;
        }),
        side: MaterialStateProperty.resolveWith<BorderSide>((states) {
          if (states.contains(MaterialState.disabled)) {
            return BorderSide(color: primaryColor.withOpacity(0.5));
          }
          if (states.contains(MaterialState.pressed)) {
            return const BorderSide(color: highlightColor, width: 2);
          }
          if (states.contains(MaterialState.hovered)) {
            return const BorderSide(color: secondaryColor, width: 1.5);
          }
          return const BorderSide(color: primaryColor);
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.hovered)) {
            return primaryColor.withOpacity(0.05);
          }
          return Colors.transparent;
        }),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        shape: MaterialStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return primaryColor.withOpacity(0.5);
          }
          if (states.contains(MaterialState.pressed)) {
            return highlightColor;
          }
          if (states.contains(MaterialState.hovered)) {
            return secondaryColor;
          }
          return primaryColor;
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textStyle: MaterialStateProperty.all<TextStyle>(
          const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      hoverColor: surfaceColor.withOpacity(0.8),
      floatingLabelStyle: const TextStyle(
        color: secondaryColor,
        fontWeight: FontWeight.w600,
      ),
      labelStyle: TextStyle(
        color: textSecondary.withOpacity(0.8),
        fontWeight: FontWeight.normal,
      ),
      hintStyle: TextStyle(
        color: textSecondary.withOpacity(0.5),
      ),
      helperStyle: TextStyle(
        color: textSecondary.withOpacity(0.7),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: subtleAccent.withOpacity(0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.focused)) {
          return primaryColor;
        }
        if (states.contains(MaterialState.error)) {
          return errorColor;
        }
        return textSecondary;
      }),
      suffixIconColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.focused)) {
          return primaryColor;
        }
        if (states.contains(MaterialState.error)) {
          return errorColor;
        }
        return textSecondary;
      }),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
      ),
      toolbarHeight: 64,
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkBackground,
      selectedIconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
        opacity: 1.0,
      ),
      unselectedIconTheme: IconThemeData(
        color: textSecondary.withOpacity(0.7),
        size: 24,
        opacity: 0.8,
      ),
      selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
        color: primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
        color: textSecondary.withOpacity(0.7),
        fontSize: 14,
      ),
      useIndicator: true,
      indicatorColor: primaryColor.withOpacity(0.15),
      minWidth: 84,
      minExtendedWidth: 220,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: primaryColor.withOpacity(0.15),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: -0.1,
          );
        }
        return GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: textSecondary.withOpacity(0.8),
          letterSpacing: -0.1,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(
            color: primaryColor,
            size: 24,
            opacity: 1.0,
          );
        }
        return IconThemeData(
          color: textSecondary.withOpacity(0.8),
          size: 24,
          opacity: 0.8,
        );
      }),
      height: 72,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      disabledColor: surfaceColor.withOpacity(0.5),
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: secondaryColor.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: subtleAccent.withOpacity(0.3), width: 1),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(
        color: secondaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondary,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        letterSpacing: -0.1,
      ),
      dividerColor: Colors.transparent,
      overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.pressed)) {
          return primaryColor.withOpacity(0.1);
        }
        if (states.contains(MaterialState.hovered)) {
          return primaryColor.withOpacity(0.05);
        }
        return Colors.transparent;
      }),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: subtleAccent.withOpacity(0.1),
          width: 1,
        ),
      ),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
      ),
      contentTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: textPrimary.withOpacity(0.9),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardColor,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        color: textPrimary,
        fontSize: 14,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: subtleAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(16),
      actionTextColor: secondaryColor,
      closeIconColor: textSecondary,
      actionOverflowThreshold: 1.0,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: subtleAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      textStyle: GoogleFonts.plusJakartaSans(
        color: textPrimary,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      preferBelow: true,
      triggerMode: TooltipTriggerMode.longPress,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      elevation: 8,
      modalElevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      modalBackgroundColor: surfaceColor,
      modalBarrierColor: Colors.black.withOpacity(0.5),
      clipBehavior: Clip.hardEdge,
      dragHandleSize: const Size(40, 4),
      dragHandleColor: subtleAccent,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey.shade400;
        }
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return Colors.grey.shade100;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return Colors.grey.shade600;
        }
        if (states.contains(MaterialState.selected)) {
          return primaryColor;
        }
        return subtleAccent;
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return primaryColor.withOpacity(0.2);
        }
        return Colors.transparent;
      }),
    ),
    // Add card theme with better elevation and borders
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: subtleAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
    ),
    // Add divider theme for consistent styling
    dividerTheme: DividerThemeData(
      color: subtleAccent.withOpacity(0.2),
      space: 1,
      thickness: 1,
      indent: 0,
      endIndent: 0,
    ),
  );
}

