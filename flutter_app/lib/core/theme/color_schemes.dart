import 'package:flutter/material.dart';
import 'design_tokens.dart';

enum GreenShade { emerald, forest, mint, lime }

class AppColorSchemes {
  AppColorSchemes._();

  static Color getSeed(GreenShade shade) {
    switch (shade) {
      case GreenShade.emerald:
        return DesignTokens.colorEmerald;
      case GreenShade.forest:
        return DesignTokens.colorForest;
      case GreenShade.mint:
        return DesignTokens.colorMint;
      case GreenShade.lime:
        return DesignTokens.colorLime;
    }
  }

  static ColorScheme lightScheme([GreenShade shade = GreenShade.emerald]) {
    final seed = getSeed(shade);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return base.copyWith(
      surface: DesignTokens.surfaceLight,
      surfaceContainer: DesignTokens.surfaceLightContainer,
      surfaceContainerHigh: const Color(0xFFF0F5F0),
      surfaceContainerHighest: const Color(0xFFE3EAE3),
      surfaceTint: seed,
      onSurface: const Color(0xFF131D13),
      onSurfaceVariant: const Color(0xFF4A554A),
      outline: const Color(0xFF707A70),
      outlineVariant: const Color(0xFFD8E2D8),
    );
  }

  static ColorScheme darkScheme([GreenShade shade = GreenShade.emerald]) {
    final seed = getSeed(shade);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      surface: DesignTokens.surfaceDark,
      surfaceContainer: DesignTokens.surfaceDarkContainer,
      surfaceContainerHigh: const Color(0xFF2C3E2C),
      surfaceContainerHighest: const Color(0xFF354A35),
      surfaceTint: seed,
      onSurface: const Color(0xFFE2EBE2),
      onSurfaceVariant: const Color(0xFFC0CCC0),
      outline: const Color(0xFF8A958A),
      outlineVariant: const Color(0xFF3F4A3F),
    );
  }

  static const Map<String, Color> priorityColors = {
    'low': DesignTokens.priorityLow,
    'medium': DesignTokens.priorityMedium,
    'high': DesignTokens.priorityHigh,
    'urgent': DesignTokens.priorityUrgent,
  };

  static const Map<String, IconData> priorityIcons = {
    'low': Icons.arrow_downward,
    'medium': Icons.remove,
    'high': Icons.arrow_upward,
    'urgent': Icons.priority_high,
  };

  static const Map<String, Color> statusColors = {
    'Active': DesignTokens.statusActive,
    'Done': DesignTokens.statusDone,
    'Cancelled': DesignTokens.statusCancelled,
    'Past': DesignTokens.statusPast,
    'Draft': DesignTokens.statusDraft,
    'Sent': DesignTokens.statusSent,
    'Pending': DesignTokens.statusPending,
    'Approved': DesignTokens.statusApproved,
    'Declined': DesignTokens.statusDeclined,
    'Given': DesignTokens.statusGiven,
  };

  static const Map<String, IconData> statusIcons = {
    'Active': Icons.play_circle_outline,
    'Done': Icons.check_circle_outline,
    'Cancelled': Icons.cancel_outlined,
    'Past': Icons.history,
    'Draft': Icons.edit_note,
    'Sent': Icons.send_outlined,
    'Pending': Icons.hourglass_empty,
    'Approved': Icons.thumb_up_outlined,
    'Declined': Icons.thumb_down_outlined,
    'Given': Icons.card_giftcard,
  };

  static Color getPriorityColor(String? priority) {
    if (priority == null) return DesignTokens.priorityMedium;
    return priorityColors[priority.toLowerCase()] ?? DesignTokens.priorityMedium;
  }

  static IconData getPriorityIcon(String? priority) {
    if (priority == null) return Icons.remove;
    return priorityIcons[priority.toLowerCase()] ?? Icons.remove;
  }

  static Color getStatusColor(String? status) {
    if (status == null) return DesignTokens.statusActive;
    return statusColors[status] ?? DesignTokens.statusActive;
  }

  static IconData getStatusIcon(String? status) {
    if (status == null) return Icons.info_outline;
    return statusIcons[status] ?? Icons.info_outline;
  }
}
