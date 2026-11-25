import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ======================== DARK MODE COLORS ========================
  static const Color darkBackground = Color(0xFF0E1111); // مشکی ذغالی
  static const Color darkSurface = Color(0xFF161A1D); // سرمه‌ای تیره کارت‌ها
  static const Color darkSurfaceLight = Color(0xFF22282C);
  static const Color darkBorder = Color(0xFF262B30);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ======================== LIGHT MODE COLORS =======================
  static const Color lightBackground = Color(0xFFF8F7F4); // سفید کاغذی گرم
  static const Color lightSurface = Color(0xFFFFFFFF); // سفید خالص کارت‌ها
  static const Color lightSurfaceVariant = Color(
    0xFFF1EFEA,
  ); // کرم ملایم برای فیلترها
  static const Color lightBorder = Color(0xFFE5E3DC); // خطوط ظریف دفترچه‌ای
  static const Color lightTextPrimary = Color(0xFF121417); // مشکی جوهری
  static const Color lightTextSecondary = Color(0xFF64748B); // خاکستری ملایم

  // ======================== BRAND & ACCENTS =========================
  // طلایی در دارک‌مود روشن‌تر و در لایت‌مود کمی برنزی‌تر است تا کنتراست حفظ شود
  static const Color goldDarkTheme = Color(0xFFD4AF37);
  static const Color goldLightTheme = Color(0xFFB38728);

  // سبز (واریز) و قرمز (برداشت)
  static const Color emeraldDark = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF059669);

  static const Color crimsonDark = Color(0xFFEF4444);
  static const Color crimsonLight = Color(0xFFDC2626);

  // آبی (انتقال بین حساب‌های خود کاربر)
  static const Color transferDark = Color(0xFF60A5FA);
  static const Color transferLight = Color(0xFF2563EB);

  static Color transfer(Brightness brightness) =>
      brightness == Brightness.dark ? transferDark : transferLight;

  // ======================== GRADIENTS ===============================
  // گرادینت کارت موجودی کل در حالت تیره
  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF2A2415), Color(0xFF161A1D), Color(0xFF0F2922)],
  );

  // گرادینت کارت موجودی کل در حالت روشن (حس کارت بانکی لوکس طلایی-سبز)
  static const LinearGradient lightHeaderGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(
        0xFF1E2923,
      ), // سبز-مشکی بسیار تیره و شیک (برای کنتراست عالی روی زمینه روشن)
      Color(0xFF161A1D),
      Color(0xFF332914), // رگه طلایی تیره
    ],
  );
}
