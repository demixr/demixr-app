import 'package:demixr_app/components/buttons.dart';
import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CancelButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      'Cancel',
      icon: const Icon(Icons.close_rounded, color: ColorPalette.onError),
      color: ColorPalette.errorContainer.withValues(alpha: 0.55),
      textColor: ColorPalette.onError,
      textSize: 16,
      onPressed: onPressed,
    );
  }
}
