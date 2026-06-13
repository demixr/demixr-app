import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final url = 'https://github.com/demixr/openunmix-torchscript/releases/download/v1.2/umxhq.ptl';
  final outputPath = '/tmp/test_download.ptl';

  final dio = Dio(BaseOptions(
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(minutes: 5),
  ));

  try {
    print('Starting download from: $url');
    print('Output path: $outputPath');
    print('');

    await dio.download(
      url,
      outputPath,
      onReceiveProgress: (received, total) {
        final percent = total > 0 ? (received / total * 100).toStringAsFixed(1) : '?';
        final mb = received ~/ (1024 * 1024);
        print('  Progress: $mb MB ($percent%)');
      },
    );

    final file = File(outputPath);
    final size = await file.length();
    print('\nDownload complete!');
    print('File size: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB');
    print('Path: $outputPath');
  } on DioException catch (e) {
    print('\nDioError: ${e.type}');
    print('Message: ${e.message}');
    print('Response: ${e.response?.statusCode}');
    print('Response headers: ${e.response?.headers}');
  } catch (e) {
    print('\nError: $e');
  }
}
