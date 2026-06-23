import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTypography {
  static const _ui = 'PlusJakartaSans';
  static const _mono = 'JetBrainsMono';

  static const displayLarge = TextStyle(
    fontFamily: _ui,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
  );
  static const h1 = TextStyle(
    fontFamily: _ui,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontFamily: _ui,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontFamily: _ui,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.65,
    color: AppColors.textSecondary,
  );
  static const bodySmall = TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const button = TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
  );
  static const label = TextStyle(
    fontFamily: _ui,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );
  static const amount = TextStyle(
    fontFamily: _mono,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
  static const amountMd = TextStyle(
    fontFamily: _mono,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
  static const amountSm = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const mono = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
}
