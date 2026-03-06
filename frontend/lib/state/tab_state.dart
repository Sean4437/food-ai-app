import 'package:flutter/material.dart';

class TabState extends ChangeNotifier {
  int index = 2;

  void setIndex(int value) {
    if (index == value) return;
    index = value;
    notifyListeners();
  }
}

class TabScope extends InheritedNotifier<TabState> {
  const TabScope({
    super.key,
    required TabState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static TabState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TabScope>();
    return scope!.notifier!;
  }
}

