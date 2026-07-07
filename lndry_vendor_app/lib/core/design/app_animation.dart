import 'package:flutter/material.dart';

/// LNDRY Design Token: Animation Timings & Curves
abstract final class AppDurations {
  AppDurations._();

  static const Duration instant    = Duration(milliseconds: 0);
  static const Duration fastest    = Duration(milliseconds: 100);
  static const Duration fast       = Duration(milliseconds: 150);
  static const Duration normal     = Duration(milliseconds: 250);
  static const Duration slow       = Duration(milliseconds: 400);
  static const Duration slower     = Duration(milliseconds: 600);
  static const Duration slowest    = Duration(milliseconds: 800);
  static const Duration splash     = Duration(milliseconds: 2200);
  static const Duration shimmer    = Duration(milliseconds: 1200);
  static const Duration pageRoute  = Duration(milliseconds: 300);
  static const Duration snackbar   = Duration(seconds: 3);
  static const Duration otpResend  = Duration(seconds: 30);
}

abstract final class AppCurves {
  AppCurves._();

  static const Curve standard      = Curves.easeInOut;
  static const Curve decelerate    = Curves.decelerate;
  static const Curve accelerate    = Curves.easeIn;
  static const Curve sharp         = Curves.easeInOutCubic;
  static const Curve bounce        = Curves.elasticOut;
  static const Curve spring        = Curves.easeOutBack;
  static const Curve enter         = Curves.easeOutCubic;
  static const Curve exit          = Curves.easeInCubic;
  static const Curve emphasized    = Curves.easeInOutCubicEmphasized;
}
