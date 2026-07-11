import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavBar extends StatelessWidget {
  final List<Widget> extra;

  const NavBar({super.key, this.extra = const []});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            tooltip: 'Back',
            iconSize: 24,
            style: IconButton.styleFrom(
              backgroundColor: ColorPalette.surfaceContainer,
              side: const BorderSide(color: ColorPalette.outline),
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            color: ColorPalette.onSurface,
            onPressed: () => Get.back(),
          ),
          ...extra,
        ],
      ),
    );
  }
}
