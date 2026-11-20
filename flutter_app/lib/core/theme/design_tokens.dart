import 'package:flutter/material.dart';

/// Dart constants mirroring shared/design_tokens.json
class DesignTokens {
  DesignTokens._();

  // Colors - Seeds & Variants
  static const Color seedColor = Color(0xFF2E7D32);
  static const Color colorEmerald = Color(0xFF2E7D32);
  static const Color colorForest = Color(0xFF1B5E20);
  static const Color colorMint = Color(0xFF00C853);
  static const Color colorLime = Color(0xFF64DD17);

  // Surfaces (Clean, crisp, modern SaaS aesthetic)
  static const Color surfaceLight = Color(0xFFF8FAF8);
  static const Color surfaceDark = Color(0xFF141D14);
  static const Color surfaceLightContainer = Color(0xFFFFFFFF);
  static const Color surfaceDarkContainer = Color(0xFF1E2A1E);

  // Priority Colors
  static const Color priorityLow = Color(0xFF66BB6A);
  static const Color priorityMedium = Color(0xFFFFA726);
  static const Color priorityHigh = Color(0xFFEF5350);
  static const Color priorityUrgent = Color(0xFFD50000);

  // Status Colors
  static const Color statusActive = Color(0xFF2196F3);
  static const Color statusDone = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFF9E9E9E);
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusApproved = Color(0xFF00C853);
  static const Color statusDeclined = Color(0xFFF44336);
  static const Color statusGiven = Color(0xFF7C4DFF);
  static const Color statusDraft = Color(0xFF78909C);
  static const Color statusSent = Color(0xFF29B6F6);
  static const Color statusPast = Color(0xFFBDBDBD);

  // Escalation
  static const Color escalationSafe = Color(0xFF66BB6A);
  static const Color escalationWarning = Color(0xFFFFA726);
  static const Color escalationDanger = Color(0xFFEF5350);

  // 8pt Spacing Grid
  static const double spaceXxs = 2.0;
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;
  static const double spaceXxxl = 48.0;

  // Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // Breakpoints
  static const double breakpointCompact = 600.0;
  static const double breakpointMedium = 1024.0;
  static const double breakpointExpanded = 1440.0;

  // Animations (ms)
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);

  // Elevations
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // Touch Target
  static const double minTouchTarget = 44.0;

  // Export Dimensions
  static const double exportCanvasWidth = 1080.0;
  static const double exportPixelRatio = 3.0;
  static const double exportMaxPageHeight = 4000.0;
}
