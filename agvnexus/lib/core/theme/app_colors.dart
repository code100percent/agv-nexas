import 'package:flutter/material.dart';

/// Cosmic Latte Editorial Design System - Color Palette for AGV Nexus.
///
/// Editorial luxury meets industrial digital craftsmanship:
/// - Cosmic Latte (#B7A89A): Muted taupe, secondary surfaces, supporting backgrounds
/// - Mocha Cream (#E8DCC6): Primary warm background, editorial surfaces
/// - Deep Burgundy (#722E37): Primary brand accent, selected states, emphasis
/// - Warm Cream (#F7F1E7): Main light canvas, clean reading surfaces
/// - Dark Espresso (#30231F): Primary text, headlines, high-contrast elements
/// - Muted Text (#766B63): Secondary text, captions, supporting information
/// - Soft Border (#D6C7B5): Subtle separators, input outlines, card boundaries
/// - Pure White (#FFFFFF): Image backgrounds, clean content surfaces
class AppColors {
  // --- Exact Editorial Palette Tokens ---
  static const Color cosmicLatte = Color(0xFFB7A89A);
  static const Color mochaCream = Color(0xFFE8DCC6);
  static const Color deepBurgundy = Color(0xFF722E37);
  static const Color warmCream = Color(0xFFF7F1E7);
  static const Color darkEspresso = Color(0xFF30231F);
  static const Color mutedText = Color(0xFF766B63);
  static const Color softBorder = Color(0xFFD6C7B5);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // --- Base Canvas & Layered Editorial Surfaces ---
  static const Color background = warmCream;
  static const Color surface = pureWhite;
  static const Color surfaceRaised = Color(0xFFF2ECE1);
  static const Color surfaceOverlay = Color(0xFFEBE2D2);
  static const Color surfaceHighlight = mochaCream;
  static const Color surfaceDark = darkEspresso;

  // --- Borders & Separators ---
  static const Color borderSubtle = softBorder;
  static const Color borderMedium = Color(0xFFC5B5A1);
  static const Color borderBright = Color(0xFF9E8E7C);

  // --- Primary Brand Accent & Interactive ---
  static const Color primary = deepBurgundy;
  static const Color primaryDim = Color(0xFF562128);
  static const Color primaryGlow = Color(0x24722E37);
  static const Color secondary = Color(0xFF8B3A44);
  static const Color accentTaupe = cosmicLatte;

  // --- Functional & Semantic Status (Harmonious Editorial Tones) ---
  static const Color success = Color(0xFF2E6347);
  static const Color successDim = Color(0xFFEAF2ED);
  static const Color warning = Color(0xFFB06500);
  static const Color warningDim = Color(0xFFFBF4EB);
  static const Color error = Color(0xFF9E2A2B);
  static const Color errorDim = Color(0xFFFCEBEB);
  static const Color info = Color(0xFF456B7D);
  static const Color infoDim = Color(0xFFEDF3F7);

  // --- Text & Typography Hierarchies ---
  static const Color textPrimary = darkEspresso;
  static const Color textSecondary = Color(0xFF52443F);
  static const Color textMuted = mutedText;
  static const Color textDisabled = Color(0xFFA89E96);
  static const Color textOnPrimary = pureWhite;

  // --- Industrial Status Accents ---
  static const Color statusIdle = Color(0xFF766B63);
  static const Color statusNavigating = deepBurgundy;
  static const Color statusCharging = Color(0xFF2E6347);
  static const Color statusPaused = Color(0xFFB06500);
  static const Color statusFault = Color(0xFF9E2A2B);
  static const Color statusEstop = deepBurgundy;

  // --- 2D Occupancy Grid / Blueprint Canvas Elements ---
  static const Color mapGridBackground = Color(0xFFECE4D6);
  static const Color mapGridMajor = Color(0xFFD6C8B4);
  static const Color mapGridMinor = Color(0xFFE4DACB);
  static const Color mapObstacleOccupied = Color(0xFF8B2635);
  static const Color mapObstacleFree = Color(0xFFFAF6EE);
  static const Color mapTrajectory = deepBurgundy;
  static const Color mapLidarBeam = Color(0x28722E37);
}
