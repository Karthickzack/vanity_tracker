import 'package:flutter/material.dart';

class AppColors {
  // Primary Luxury Skincare Brand Palette
  static const Color primary = Color(0xFFC07A60); // Warm Terracotta Rose
  static const Color primaryLight = Color(0xFFF3E5E1);
  static const Color primaryDark = Color(0xFF8F4D35);

  static const Color secondary = Color(0xFF4A7C59); // Calming Sage Green
  static const Color secondaryLight = Color(0xFFE2EFE7);
  static const Color secondaryDark = Color(0xFF2D533B);

  static const Color accent = Color(0xFFD4AF37); // Champagne Gold
  static const Color accentLight = Color(0xFFFBF4E4);

  // Expiry Indicator Colors
  static const Color statusGreen = Color(0xFF2E7D32); // Fresh (>30 days)
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color statusGreenBorder = Color(0xFFA5D6A7);

  static const Color statusAmber = Color(0xFFE65100); // Expiring Soon (0-30 days)
  static const Color statusAmberBg = Color(0xFFFFF3E0);
  static const Color statusAmberBorder = Color(0xFFFFCC80);

  static const Color statusRed = Color(0xFFC62828); // Expired (< 0 days)
  static const Color statusRedBg = Color(0xFFFFEBEE);
  static const Color statusRedBorder = Color(0xFFEF9A9A);

  static const Color statusUnopened = Color(0xFF546E7A); // Slate Blue
  static const Color statusUnopenedBg = Color(0xFFECEFF1);
  static const Color statusUnopenedBorder = Color(0xFFCFD8DC);

  static const Color statusFinished = Color(0xFF78909C);
  static const Color statusFinishedBg = Color(0xFFF5F7FA);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFAF8F5); // Soft Warm Linen
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x0F2E282A);

  // Text & Neutrals
  static const Color textPrimary = Color(0xFF1E242B);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textTertiary = Color(0xFF98A2B3);
  static const Color border = Color(0xFFE4E7EC);
  static const Color divider = Color(0xFFF2F4F7);

  // Gradients
  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFFC07A60), Color(0xFFE09F87)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sageGradient = LinearGradient(
    colors: [Color(0xFF4A7C59), Color(0xFF6B9E7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
