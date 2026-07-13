import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class Instructions extends StatelessWidget {
  final bool compact;

  const Instructions({this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your separation engine',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: ColorPalette.onSurface,
          ),
        ),
        SizedBox(height: compact ? 5 : 8),
        Text(
          'The GPU model is fastest on supported devices. You can change this choice later.',
          style: const TextStyle(
            fontSize: 16,
            height: 1.4,
            color: ColorPalette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
