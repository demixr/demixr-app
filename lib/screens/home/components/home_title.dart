import 'package:demixr_app/constants.dart';
import 'package:flutter/material.dart';

class HomeTitle extends StatelessWidget {
  const HomeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Demixr', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: const Text(
            'Pull every part of your music into focus.',
            style: TextStyle(
              color: ColorPalette.onSurfaceVariant,
              fontSize: 18,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
