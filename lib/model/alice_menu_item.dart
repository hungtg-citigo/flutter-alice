import 'package:flutter/material.dart';

class AliceMenuItem {
  final String title;
  final IconData? iconData;

  AliceMenuItem({required this.title, this.iconData});
}

class AliceSwitchItem extends AliceMenuItem {
  final String title;
  final bool enable;

  AliceSwitchItem({
    required this.title,
    required this.enable,
  }) : super(title: title);
}
