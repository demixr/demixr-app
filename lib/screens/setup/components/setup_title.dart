import 'package:flutter/material.dart';

class SetupTitle extends StatelessWidget {
  final bool compact;

  const SetupTitle({this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Demixr',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: compact ? 44 : 56,
            height: 1.02,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          'Separate vocals, drums, bass, and instruments directly on your device.',
          style: TextStyle(fontSize: compact ? 16 : 18, height: 1.4),
        ),
      ],
    );
  }
}
