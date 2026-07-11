import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Image.asset("assets/images/error.png")),
                  const SizedBox(height: 24),
                  Text(
                    'Something went off track',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'We could not open that screen. Your library and files are safe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorPalette.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: ColorPalette.primary,
                      foregroundColor: ColorPalette.onPrimary,
                      minimumSize: const Size(150, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Go back',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
