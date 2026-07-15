import 'dart:io';

import 'package:archive/archive.dart';
import 'package:demixr_app/providers/model_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Core ML archive installation ignores macOS metadata', () async {
    final root = await Directory.systemTemp.createTemp('demixr-coreml-test-');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          '__MACOSX/scnet_coreml.mlmodelc/._metadata.json',
          'metadata',
        ),
      )
      ..addFile(
        ArchiveFile.string('scnet_coreml.mlmodelc/model.mil', 'compiled model'),
      )
      ..addFile(
        ArchiveFile.string(
          'scnet_coreml.mlmodelc/weights/weight.bin',
          'weights',
        ),
      );
    final archivePath = p.join(root.path, 'download.mlmodelc.zip');
    await File(archivePath).writeAsBytes(ZipEncoder().encode(archive));
    final destination = Directory(p.join(root.path, 'scnet_coreml.mlmodelc'));

    await installCoreMlArchive(
      archivePath: archivePath,
      destination: destination,
    );

    expect(
      File(p.join(destination.path, 'model.mil')).readAsString(),
      completion('compiled model'),
    );
    expect(
      File(p.join(destination.path, 'weights', 'weight.bin')).exists(),
      completion(isTrue),
    );
    expect(File(archivePath).exists(), completion(isFalse));
    expect(
      Directory(p.join(root.path, '__MACOSX')).exists(),
      completion(isFalse),
    );
  });
}
