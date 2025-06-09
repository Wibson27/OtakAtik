import 'package:flutter/material.dart';
import 'package:frontend/common/app_color.dart';

class ColorUtils {
  static Color getScoreColor(double score) {
    if (score >= 7.0) {
      return AppColor.hijauSuccess;
    } else if (score >= 4.0) {
      return AppColor.kuning;
    } else {
      return AppColor.merahError;
    }
  }
}