import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/app_colors.dart';

/// Centralized Liquid Glass design tokens, presets, and ambient backdrop
/// tailored for Siaheh's obsidian-gold-emerald (dark) and warm-ivory-champagne
/// (light) financial identity.
class SiahehGlass {
  SiahehGlass._();

  /// Extra bottom scroll clearance so scrollable content passes smoothly behind
  /// the floating [GlassTabBar.bottom] dock while keeping the final item
  /// completely reachable above it.
  static const double floatingNavBottomInset = 116.0;

  /// App-wide [GlassThemeData] passed to [LiquidGlassWidgets.wrap].
  static final GlassThemeData themeData = GlassThemeData(
    style: GlassStyle.ios27,
    dark: GlassThemeVariant(
      settings: GlassThemeSettings.ios27Dark.copyWith(
        glassColor: const Color(0x281B2226),
        saturation: 1.35,
      ),
      glowColors: const GlassGlowColors(
        primary: AppColors.goldDarkTheme,
        secondary: AppColors.emeraldDark,
        success: AppColors.emeraldDark,
        danger: AppColors.crimsonDark,
        info: AppColors.transferDark,
        pressLight: Color(0xFFEBD07A),
      ),
    ),
    light: GlassThemeVariant(
      settings: GlassThemeSettings.ios27Light.copyWith(
        glassColor: const Color(0x9EFFFFFF),
        saturation: 1.55,
      ),
      glowColors: const GlassGlowColors(
        primary: AppColors.goldLightTheme,
        secondary: AppColors.emeraldLight,
        success: AppColors.emeraldLight,
        danger: AppColors.crimsonLight,
        info: AppColors.transferLight,
        pressLight: Color(0xFFF3E2B3),
      ),
    ),
  );

  /// Refractive settings for the primary [BalanceHeaderCard] hero surface.
  static LiquidGlassSettings heroCardSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0x5A14211D),
        blur: 14,
        thickness: 26,
        refractiveIndex: 1.24,
        saturation: 1.4,
        lightIntensity: 0.34,
        ambientStrength: 0.14,
        fresnelStrength: 0.35,
        rimLight: 0.72,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xCC16241F),
      blur: 16,
      thickness: 26,
      refractiveIndex: 1.22,
      saturation: 1.3,
      lightIntensity: 0.32,
      ambientStrength: 0.12,
      fresnelStrength: 0.30,
      rimLight: 0.65,
    );
  }

  /// Balanced Liquid Glass settings for medium hero cards (account cards,
  /// expense donut card, and loading halo).
  static LiquidGlassSettings cardSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0x301B2226),
        blur: 10,
        thickness: 22,
        refractiveIndex: 1.2,
        saturation: 1.3,
        lightIntensity: 0.25,
        ambientStrength: 0.08,
        rimLight: 0.55,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xA6FFFFFF),
      blur: 12,
      thickness: 22,
      refractiveIndex: 1.2,
      saturation: 1.45,
      lightIntensity: 0.22,
      ambientStrength: 0.08,
      rimLight: 0.85,
    );
  }

  /// High-legibility frosted glass settings for modal [GlassSheet] surfaces.
  static LiquidGlassSettings sheetSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0xD4141A1D),
        blur: 22,
        thickness: 28,
        refractiveIndex: 1.18,
        saturation: 1.25,
        lightIntensity: 0.24,
        rimLight: 0.65,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xE0F9F8F5),
      blur: 22,
      thickness: 28,
      refractiveIndex: 1.18,
      saturation: 1.35,
      lightIntensity: 0.22,
      rimLight: 0.9,
    );
  }

  /// Floating dock settings for [GlassTabBar.bottom].
  static LiquidGlassSettings tabBarSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0x4A151B1F),
        blur: 16,
        thickness: 30,
        refractiveIndex: 1.24,
        saturation: 1.4,
        rimLight: 0.85,
        bodyShade: 0.24,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xB8FFFFFF),
      blur: 16,
      thickness: 30,
      refractiveIndex: 1.24,
      saturation: 1.65,
      rimLight: 1.0,
    );
  }

  /// Lightweight 60fps frosted glass-matched surface decoration for long
  /// scrollable lists (`TransactionTile`, `_BankMessageCard`, `_SenderTile`).
  ///
  /// Avoids per-row GPU shader layers while matching the translucency and
  /// specular hairline borders of neighboring [GlassContainer] hero surfaces.
  static BoxDecoration frostedRowDecoration(
    BuildContext context, {
    double radius = 20,
    Color? borderColor,
    Color? tintColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: tintColor != null
              ? [
                  tintColor.withValues(alpha: 0.16),
                  const Color(0xB3151B1E),
                ]
              : const [
                  Color(0xC21D2428),
                  Color(0xA614191C),
                ],
        ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: tintColor != null
            ? [
                tintColor.withValues(alpha: 0.14),
                const Color(0xD9FFFFFF),
              ]
            : const [
                Color(0xE0FFFFFF),
                Color(0xC4F7F5F0),
              ],
      ),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.90),
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D121417),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}

/// Static ambient luxury backdrop painted once behind scaffolds so Liquid Glass
/// surfaces have real emerald and gold luminance to refract at 60fps.
class SiahehAmbientBackground extends StatelessWidget {
  const SiahehAmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ColoredBox(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Top-right warm gold aura (behind BalanceHeaderCard & header)
                Positioned(
                  top: -90,
                  right: -70,
                  child: _AmbientOrb(
                    size: 320,
                    color: isDark
                        ? AppColors.goldDarkTheme.withValues(alpha: 0.20)
                        : const Color(0xFFE7C776).withValues(alpha: 0.34),
                  ),
                ),
                // Mid-left deep emerald aura (behind accounts & expense donut)
                Positioned(
                  top: 210,
                  left: -100,
                  child: _AmbientOrb(
                    size: 340,
                    color: isDark
                        ? AppColors.emeraldDark.withValues(alpha: 0.17)
                        : const Color(0xFF6EE7B7).withValues(alpha: 0.24),
                  ),
                ),
                // Bottom-right soft champagne-teal aura (refracted by bottom dock)
                Positioned(
                  bottom: -110,
                  right: -60,
                  child: _AmbientOrb(
                    size: 320,
                    color: isDark
                        ? const Color(0xFF1E5B4C).withValues(alpha: 0.24)
                        : const Color(0xFFD9C28B).withValues(alpha: 0.26),
                  ),
                ),
                // Subtle bottom-left gold kiss for dock symmetry
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: _AmbientOrb(
                    size: 240,
                    color: isDark
                        ? AppColors.goldDarkTheme.withValues(alpha: 0.12)
                        : const Color(0xFFA7F3D0).withValues(alpha: 0.22),
                  ),
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: color.a * 0.35),
                color.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
