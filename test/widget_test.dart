import 'package:demixr_app/providers/model_provider.dart';
import 'package:demixr_app/screens/setup/setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Future<void> pumpSetupAtSize(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ModelProvider(),
        child: const MaterialApp(home: SetupScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('setup screen fits a phone viewport without overflow', (
    tester,
  ) async {
    await pumpSetupAtSize(tester, const Size(390, 844));

    expect(find.text('Welcome to Demixr'), findsOneWidget);
    expect(find.text('Choose your separation engine'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup screen adapts to a desktop viewport without overflow', (
    tester,
  ) async {
    await pumpSetupAtSize(tester, const Size(1200, 800));

    expect(find.text('Welcome to Demixr'), findsOneWidget);
    expect(find.text('Demucs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
