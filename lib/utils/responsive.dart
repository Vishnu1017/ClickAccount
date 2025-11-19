import 'package:flutter/widgets.dart';

/// A global responsive helper using raw pixel values from MediaQuery.
/// Call Responsive.init(context) once (in main.dart) to use it everywhere.
class Responsive {
  static late MediaQueryData _mq;
  static late double width; // Total width in px
  static late double height; // Total height in px
  static late double pixelRatio; // Device pixel ratio
  static late double safeWidth; // Width excluding left/right padding
  static late double safeHeight; // Height excluding top/bottom padding

  /// Call only once (in main.dart)
  static void init(BuildContext context) {
    _mq = MediaQuery.of(context);

    width = _mq.size.width;
    height = _mq.size.height;
    pixelRatio = _mq.devicePixelRatio;

    safeWidth = width - (_mq.padding.left + _mq.padding.right);
    safeHeight = height - (_mq.padding.top + _mq.padding.bottom);
  }

  /// Scaling helpers (PX based)
  static double pxW(double value) => (value / 375) * width; // 375 = base width
  static double pxH(double value) =>
      (value / 812) * height; // 812 = base height

  /// Font scaling
  static double font(double size) => size * (width / 375);
}
