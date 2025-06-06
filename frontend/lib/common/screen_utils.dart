import 'package:flutter/material.dart';

// convert pixel ke logical pixel
extension ScreenUtils on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Function untuk responsive scaling 
  // 430.25 dan 932 adalah size di figma
  double scaleWidth(double figmaWidth) {
    return (screenWidth / 430.25) * figmaWidth;
  }

  double scaleHeight(double figmaHeight) {
    return (screenHeight / 932) * figmaHeight;
  }
}