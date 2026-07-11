import 'package:flutter/material.dart';

class SetupTitle extends StatelessWidget {
  const SetupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Demixr',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 14),
        const Text(
          'Separate vocals, drums, bass, and instruments directly on your device.',
          style: TextStyle(fontSize: 18, height: 1.45),
        ),
      ],
    );
  }
}
