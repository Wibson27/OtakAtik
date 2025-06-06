import 'package:flutter/material.dart';
import 'package:frontend/common/app_color.dart';

class AppInfo {
  static success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.hijauSuccess,
      ),
    );
  }

  static error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.merahError,
      ),
    );
  }
}
