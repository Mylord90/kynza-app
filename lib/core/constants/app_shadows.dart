import 'package:flutter/material.dart';
import 'app_colors.dart';

/// NO blur, NO BackdropFilter — only plain BoxShadow (perf budget R13).
abstract class AppShadows {
  static const goldGlow = BoxShadow(
    color: AppColors.primaryGlow,
    blurRadius: 24,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );
  static const card = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const elevated = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}
