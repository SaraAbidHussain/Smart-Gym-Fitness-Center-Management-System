import 'package:flutter/material.dart';

/// Royal Gold - Luxury Gym Design System
/// Premium, Exclusive, High-End Aesthetic
class AppColors {
  // Primary - Royal Gold
  static const primary = Color(0xFFD4AF37);         // Classic Gold
  static const primaryLight = Color(0xFFE6C86E);    // Light Gold
  static const primaryDark = Color(0xFFB8942A);     // Dark Gold
  
  // Accent - Deep Navy/Slate
  static const accent = Color(0xFF1E293B);          // Deep Slate
  static const accentLight = Color(0xFF334155);     // Lighter Slate
  static const accentDark = Color(0xFF0F172A);      // Almost Black Navy
  
  // Bronze/Copper (secondary accent)
  static const bronze = Color(0xFFCD7F32);          // Bronze
  static const copper = Color(0xFFB87333);          // Copper
  
  // Backgrounds - Dark Luxury
  static const bgPrimary = Color(0xFF0A0A0A);       // Rich Black
  static const bgSecondary = Color(0xFF141414);     // Dark Grey
  static const bgTertiary = Color(0xFF1F1F1F);      // Card Background
  static const bgElevated = Color(0xFF2A2A2A);      // Elevated Cards
  
  // Glass Effect (Luxury)
  static const glass = Color(0x15D4AF37);           // 8% Gold tint
  static const glassBorder = Color(0x40D4AF37);     // 25% Gold border
  
  // Text Colors
  static const textPrimary = Color(0xFFFAFAFA);     // Almost White
  static const textSecondary = Color(0xFFD1D5DB);   // Light Grey
  static const textTertiary = Color(0xFF9CA3AF);    // Medium Grey
  static const textMuted = Color(0xFF6B7280);       // Muted Grey
  
  // Status Colors (Luxurious versions)
  static const success = Color(0xFF10B981);         // Emerald
  static const warning = Color(0xFFF59E0B);         // Amber
  static const error = Color(0xFFEF4444);           // Red
  static const info = Color(0xFF3B82F6);            // Blue
  
  // Membership Tier Colors
  static const tierBasic = Color(0xFF6B7280);       // Grey
  static const tierPremium = Color(0xFFD4AF37);     // Gold
  static const tierVIP = Color(0xFFB8860B);         // Dark Golden Rod
  
  // Gradients
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFB8942A), Color(0xFF8B6914)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const navyGoldGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const darkGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF1F1F1F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Shimmer colors for skeleton loading
  static const shimmerBase = Color(0xFF1F1F1F);
  static const shimmerHighlight = Color(0xFF2A2A2A);
}

/// Typography System
class AppTypography {
  static const String fontFamily = 'Poppins';
  
  // Headings
  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  
  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  
  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );
  
  static const h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const h5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body text
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );
  
  // Labels
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );
  
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );
  
  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
  );
}

/// Spacing System
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Border Radius
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 999.0;
}

/// Shadows
class AppShadows {
  static const small = BoxShadow(
    color: Color(0x10000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  
  static const medium = BoxShadow(
    color: Color(0x15000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
  
  static const large = BoxShadow(
    color: Color(0x20000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  
  // Gold glow effect
  static const goldGlow = BoxShadow(
    color: Color(0x40D4AF37),
    blurRadius: 20,
    spreadRadius: 0,
  );
}