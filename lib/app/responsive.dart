import 'dart:math';
import 'package:flutter/material.dart';

/// Responsive layout helper for all phone sizes.
///
/// Provides scaled values based on a 375px (iPhone SE/8) design baseline.
/// Usage:
///   final r = Responsive(context);
///   fontSize: r.sp(16),       // scaled font
///   padding: r.pad(20),       // scaled padding
///   SizedBox(height: r.h(24)) // scaled height
class Responsive {
  final BuildContext context;
  late final double _screenWidth;
  late final double _screenHeight;
  late final double _scaleFactor;
  late final double _textScaleFactor;
  late final EdgeInsets _viewPadding;

  /// Design baseline width (iPhone SE / 8)
  static const double _designWidth = 375.0;

  /// Design baseline height
  static const double _designHeight = 812.0;

  Responsive(this.context) {
    final mq = MediaQuery.of(context);
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;
    _viewPadding = mq.viewPadding;

    // Scale factor clamped between 0.85 (tiny phones) and 1.15 (large phones)
    _scaleFactor = (_screenWidth / _designWidth).clamp(0.85, 1.15);

    // Text scale uses softer scaling to avoid extremes
    _textScaleFactor = (_screenWidth / _designWidth).clamp(0.88, 1.12);
  }

  /// Screen width
  double get width => _screenWidth;

  /// Screen height
  double get height => _screenHeight;

  /// Safe area top padding (status bar)
  double get topPadding => _viewPadding.top;

  /// Safe area bottom padding (nav bar / gesture area)
  double get bottomPadding => _viewPadding.bottom;

  /// True for small phones (width < 360px, e.g. iPhone SE 1st gen, Galaxy S5)
  bool get isSmallPhone => _screenWidth < 360;

  /// True for compact phones (width < 375px)
  bool get isCompact => _screenWidth < 375;

  /// True for large phones (width >= 414px, e.g. iPhone Plus/Max, Pixel XL)
  bool get isLargePhone => _screenWidth >= 414;

  /// True for very short phones (height < 700px)
  bool get isShortPhone => _screenHeight < 700;

  /// Scaled pixel value for spacing/dimensions
  double sp(double size) => size * _scaleFactor;

  /// Scaled padding value
  double pad(double size) => size * _scaleFactor;

  /// Scaled height value
  double h(double size) =>
      size * (_screenHeight / _designHeight).clamp(0.85, 1.15);

  /// Scaled font size — uses softer scaling
  double fontSize(double size) => size * _textScaleFactor;

  /// Adaptive horizontal padding: smaller on small phones, larger on big phones
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 12 : (isLargePhone ? 24 : 16),
      );

  /// Adaptive screen padding (all sides)
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 14 : (isLargePhone ? 28 : 20),
        vertical: isSmallPhone ? 12 : 16,
      );

  /// Adaptive card padding
  EdgeInsets get cardPadding => EdgeInsets.all(isSmallPhone ? 12 : 16);

  /// Adaptive icon size
  double iconSize([double base = 24]) => base * _scaleFactor;

  /// Adaptive border radius
  double radius([double base = 16]) => base * _scaleFactor;

  /// Responsive number of columns for a grid
  int gridColumns({int minColumns = 2, double minItemWidth = 150}) {
    return max(minColumns, (_screenWidth / minItemWidth).floor());
  }
}
