import 'package:flutter/material.dart';

abstract class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double button = 12;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 9999;

  static final xs_ = BorderRadius.circular(xs);
  static final sm_ = BorderRadius.circular(sm);
  static final md_ = BorderRadius.circular(md);
  static final lg_ = BorderRadius.circular(lg);
  static final xl_ = BorderRadius.circular(xl);
  static final button_ = BorderRadius.circular(button);
  static final card_ = BorderRadius.circular(card);
  static final sheet_ = BorderRadius.circular(sheet);
  static final pill_ = BorderRadius.circular(pill);
}
