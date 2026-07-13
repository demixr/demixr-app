import 'package:demixr_app/providers/model_provider.dart';
import 'package:demixr_app/screens/demixing/components/selection_screen.dart';
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

  testWidgets('setup screen fits a short desktop window without overflow', (
    tester,
  ) async {
    await pumpSetupAtSize(tester, const Size(1200, 500));

    expect(find.text('HTDEMUCS'), findsOneWidget);
    expect(find.text('HTDEMUCS_ONNX'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new separation renders at fullscreen desktop size', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SelectionScreen())),
    );
    await tester.pump();

    expect(find.text('New separation'), findsOneWidget);
    expect(find.text('Choose a song'), findsOneWidget);
    expect(find.text('Unmix'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
