import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/app_colors.dart';

/// Centralized Liquid Glass design tokens, presets, reusable glass primitives,
/// and ambient backdrop tailored for Siaheh's obsidian-gold-emerald (dark) and
/// luminous ivory-champagne (light) financial identity at smooth 60/120fps.
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
        glassColor: const Color(0x2E1B2226),
        blur: 8,
        frost: 0,
        saturation: 1.3,
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
        glassColor: const Color(0xA8FFFFFF),
        blur: 8,
        frost: 0,
        saturation: 1.4,
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
        glassColor: Color(0x5214211D),
        blur: 6,
        frost: 0,
        thickness: 22,
        refractiveIndex: 1.22,
        saturation: 1.32,
        lightIntensity: 0.30,
        ambientStrength: 0.12,
        fresnelStrength: 0.30,
        rimLight: 0.70,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xB8FFFFFF),
      blur: 6,
      frost: 0,
      thickness: 22,
      refractiveIndex: 1.20,
      saturation: 1.35,
      lightIntensity: 0.24,
      ambientStrength: 0.10,
      fresnelStrength: 0.25,
      rimLight: 0.90,
    );
  }

  /// Real Liquid Glass shader settings for scrollable cards (`AccountCard`,
  /// `ExpenseDonut` card, `TransactionTile`, `_BankMessageCard`, `_SenderTile`).
  ///
  /// Uses `blur: 0, frost: 0` on `GlassQuality.standard` so `LightweightLiquidGlass`
  /// runs the real SDF specular rim + Fresnel + glass body tint shader directly
  /// on the canvas without pushing a per-row `BackdropFilterLayer` flush.
  static LiquidGlassSettings scrollCardSettings(
    Brightness brightness, {
    Color? tintColor,
  }) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return LiquidGlassSettings(
        glassColor: tintColor != null
            ? tintColor.withValues(alpha: 0.16)
            : const Color(0x9C1A2126),
        blur: 0,
        frost: 0,
        thickness: 18,
        refractiveIndex: 1.18,
        saturation: 1.22,
        lightIntensity: 0.32,
        ambientStrength: 0.10,
        fresnelStrength: 0.28,
        rimLight: 0.62,
      );
    }
    return LiquidGlassSettings(
      glassColor: tintColor != null
          ? tintColor.withValues(alpha: 0.14)
          : const Color(0xCCFFFFFF),
      blur: 0,
      frost: 0,
      thickness: 18,
      refractiveIndex: 1.18,
      saturation: 1.30,
      lightIntensity: 0.26,
      ambientStrength: 0.10,
      fresnelStrength: 0.24,
      rimLight: 0.92,
    );
  }

  /// Balanced Liquid Glass settings for chips inside [GlassBackdropGroup].
  static LiquidGlassSettings chipSettings(
    Brightness brightness, {
    bool selected = false,
    Color? accent,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final Color effectiveAccent =
        accent ?? (isDark ? AppColors.goldDarkTheme : AppColors.goldLightTheme);
    if (isDark) {
      return LiquidGlassSettings(
        glassColor: selected
            ? effectiveAccent.withValues(alpha: 0.34)
            : const Color(0x301E262B),
        blur: 4,
        frost: 0,
        thickness: 16,
        refractiveIndex: 1.18,
        saturation: 1.25,
        lightIntensity: 0.24,
        rimLight: selected ? 0.78 : 0.48,
      );
    }
    return LiquidGlassSettings(
      glassColor: selected
          ? effectiveAccent.withValues(alpha: 0.22)
          : const Color(0xB8FFFFFF),
      blur: 4,
      frost: 0,
      thickness: 16,
      refractiveIndex: 1.18,
      saturation: 1.35,
      lightIntensity: 0.20,
      rimLight: selected ? 0.92 : 0.80,
    );
  }

  /// Liquid Glass settings for [GlassSearchBar] and [GlassTextField].
  static LiquidGlassSettings inputSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0x45182024),
        blur: 6,
        frost: 0,
        thickness: 18,
        refractiveIndex: 1.18,
        saturation: 1.25,
        lightIntensity: 0.24,
        rimLight: 0.60,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xC8FFFFFF),
      blur: 6,
      frost: 0,
      thickness: 18,
      refractiveIndex: 1.18,
      saturation: 1.35,
      lightIntensity: 0.22,
      rimLight: 0.88,
    );
  }

  /// Balanced Liquid Glass settings for small grouped surfaces.
  static LiquidGlassSettings cardSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0x301B2226),
        blur: 6,
        frost: 0,
        thickness: 20,
        refractiveIndex: 1.18,
        saturation: 1.25,
        lightIntensity: 0.24,
        ambientStrength: 0.08,
        rimLight: 0.55,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xA6FFFFFF),
      blur: 6,
      frost: 0,
      thickness: 20,
      refractiveIndex: 1.18,
      saturation: 1.35,
      lightIntensity: 0.20,
      ambientStrength: 0.08,
      rimLight: 0.85,
    );
  }

  /// High-legibility frosted glass settings for modal [GlassSheet] & [GlassDialog].
  static LiquidGlassSettings sheetSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0xD8141A1D),
        blur: 14,
        frost: 0,
        thickness: 24,
        refractiveIndex: 1.16,
        saturation: 1.22,
        lightIntensity: 0.22,
        rimLight: 0.65,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xE6F9F8F5),
      blur: 14,
      frost: 0,
      thickness: 24,
      refractiveIndex: 1.16,
      saturation: 1.30,
      lightIntensity: 0.20,
      rimLight: 0.90,
    );
  }

  /// Floating dock settings for [GlassTabBar.bottom].
  static LiquidGlassSettings tabBarSettings(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    if (isDark) {
      return const LiquidGlassSettings(
        glassColor: Color(0x52151B1F),
        blur: 10,
        frost: 0,
        thickness: 26,
        refractiveIndex: 1.22,
        saturation: 1.35,
        rimLight: 0.85,
        bodyShade: 0.20,
      );
    }
    return const LiquidGlassSettings(
      glassColor: Color(0xC2FFFFFF),
      blur: 10,
      frost: 0,
      thickness: 26,
      refractiveIndex: 1.22,
      saturation: 1.50,
      rimLight: 1.0,
    );
  }
}

/// Real Liquid Glass card container running the lightweight SDF specular shader
/// at 60/120fps without per-row `BackdropFilter` stalls.
class SiahehGlassCard extends StatelessWidget {
  const SiahehGlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderColor,
    this.tintColor,
    this.shape,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? tintColor;
  final LiquidShape? shape;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final LiquidShape effectiveShape =
        shape ?? LiquidRoundedSuperellipse(borderRadius: radius);

    final Widget card = RepaintBoundary(
      child: GlassContainer(
        useOwnLayer: true,
        quality: GlassQuality.standard,
        width: width,
        height: height,
        shape: effectiveShape,
        settings: SiahehGlass.scrollCardSettings(
          brightness,
          tintColor: tintColor,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape is LiquidOval
                ? null
                : BorderRadius.circular(radius),
            shape: shape is LiquidOval ? BoxShape.circle : BoxShape.rectangle,
            border: Border.all(
              color: borderColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.11)
                      : Colors.white.withValues(alpha: 0.88)),
              width: 1,
            ),
          ),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: card);
    }
    return card;
  }
}

/// Primary Liquid Glass CTA button replacing Material [FilledButton] across
/// Siaheh with consistent gold-tinted glass physics and high contrast.
class SiahehPrimaryGlassButton extends StatelessWidget {
  const SiahehPrimaryGlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.height = 50,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final double height;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final Widget button = GlassButton.custom(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      width: fullWidth ? double.infinity : null,
      height: height,
      stretch: 0.14,
      enabled: enabled,
      label: label,
      shape: const LiquidRoundedSuperellipse(borderRadius: 18),
      tintColor: scheme.primary.withValues(alpha: isDark ? 0.30 : 0.22),
      glowColor: scheme.primary.withValues(alpha: 0.32),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 19,
                color: isDark ? scheme.primary : AppColors.lightTextPrimary,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? scheme.primary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return GlassInteractionSilence(child: button);
  }
}

/// Shared translucent Liquid Glass filter/selection chip with guaranteed contrast
/// in both Dark and Light themes (avoids opaque [GlassChip.selectedColor]
/// fills that would hide the label).
class SiahehGlassChip extends StatelessWidget {
  const SiahehGlassChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.onDeleted,
    this.icon,
    this.deleteIcon,
    this.accentColor,
    this.labelColor,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final Widget? icon;
  final Widget? deleteIcon;
  final Color? accentColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = accentColor ?? scheme.primary;

    final Color resolvedTextColor = labelColor ??
        (selected
            ? (isDark
                ? Color.lerp(accent, Colors.white, 0.35)!
                : AppColors.lightTextPrimary)
            : scheme.onSurface.withValues(alpha: 0.86));

    return GlassChip(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      settings: SiahehGlass.chipSettings(
        theme.brightness,
        selected: selected,
        accent: accent,
      ),
      icon: icon,
      iconSize: 16,
      iconColor: isDark ? Color.lerp(accent, Colors.white, 0.25) : accent,
      label: label,
      selected: selected,
      selectedColor: Colors.transparent,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: resolvedTextColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      stretch: 0.15,
      onTap: onTap,
      onDeleted: onDeleted,
      deleteIcon: deleteIcon ??
          Icon(
            Icons.close_rounded,
            size: 15,
            color: isDark ? Color.lerp(accent, Colors.white, 0.35) : accent,
          ),
    );
  }
}

/// Static ambient luxury backdrop painted once behind scaffolds so Liquid Glass
/// surfaces have real emerald and gold luminance to refract at 60/120fps.
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
                        ? AppColors.goldDarkTheme.withValues(alpha: 0.22)
                        : const Color(0xFFE7C776).withValues(alpha: 0.36),
                  ),
                ),
                // Mid-left deep emerald aura (behind accounts & expense donut)
                Positioned(
                  top: 210,
                  left: -100,
                  child: _AmbientOrb(
                    size: 340,
                    color: isDark
                        ? AppColors.emeraldDark.withValues(alpha: 0.18)
                        : const Color(0xFF6EE7B7).withValues(alpha: 0.26),
                  ),
                ),
                // Bottom-right soft champagne-teal aura (refracted by bottom dock)
                Positioned(
                  bottom: -110,
                  right: -60,
                  child: _AmbientOrb(
                    size: 320,
                    color: isDark
                        ? const Color(0xFF1E5B4C).withValues(alpha: 0.25)
                        : const Color(0xFFD9C28B).withValues(alpha: 0.28),
                  ),
                ),
                // Subtle bottom-left gold kiss for dock symmetry
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: _AmbientOrb(
                    size: 240,
                    color: isDark
                        ? AppColors.goldDarkTheme.withValues(alpha: 0.14)
                        : const Color(0xFFA7F3D0).withValues(alpha: 0.24),
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
