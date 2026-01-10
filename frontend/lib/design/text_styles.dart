import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle title1(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle title2(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
}
