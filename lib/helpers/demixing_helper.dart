import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:executorch_flutter/executorch_flutter.dart';

import '../models/song.dart';
import '../models/unmixed_song.dart';
import '../models/exceptions/demixing_exception.dart';
import '../utils.dart';
import '../constants.dart';

/// Constants for demixing.
const _numStems = 4; // vocals, drums, bass, other
const _stereoChannels = 2;
const _numBufferFrame = 250000; // ~5.7 seconds per chunk (Demucs default)

/// Result of reading a WAV file: (floatData, numChannels, numFrames).
class _WavReadResult {
  const _WavReadResult(this.floatData, this.numChannels, this.numFrames);
  final List<double> floatData;
  final int numChannels;
  final int numFrames;
}

/// Helper handling the source separation.
///
/// Uses [executorch_flutter] (v0.4.1) for cross-platform inference
/// (Android, iOS, macOS, Linux, Windows, Web).
///
/// The chunked processing loop stays in Dart (it's the Demucs algorithm),
/// but tensor creation and inference are handled by 0.4.1's FFI API.
class DemixingHelper {
  /// Separates the given [song] sources into the 4 different stems.
  ///
  /// Uses executorch_flutter (v0.4.1) for cross-platform inference.
  /// The chunked processing loop handles the Demucs overlap-add algorithm.
  Future<UnmixedSong> separate(
      Song song, String modelPath, String modelName) async {
    // Validate model path
    if (modelPath.isEmpty || !File(modelPath).existsSync()) {
      throw DemixingException(
        'Model not found: $modelPath.\n'
        'Please download a model first via Settings → Models.',
      );
    }

    final outputPath = await getAppTemp();
    final outputDir = Directory(outputPath);
    await outputDir.create(recursive: true);

    // Load the model (new API: static factory method)
    final model = await ExecuTorchModel.load(modelPath);
    try {
      // Read the input WAV file
      final wavResult = _readWavFile(song.path);

      // Create output WAV files for each stem
      final stemNames = ['vocals', 'drums', 'bass', 'other'];
      final stemFiles = <String, File>{};
      for (final stemName in stemNames) {
        stemFiles[stemName] = File('${outputDir.path}/${stemName}.wav');
      }

      // Process in chunks (Demucs overlap-add algorithm)
      await _processChunks(
        audioData: wavResult.floatData,
        numChannels: wavResult.numChannels,
        numFrames: wavResult.numFrames,
        stemFiles: stemFiles,
        stemNames: stemNames,
        model: model,
      );

      // Build result
      final separated = <String, String>{};
      for (final stemName in stemNames) {
        separated[stemName] = stemFiles[stemName]!.path;
      }

      checkResult(separated);

      return UnmixedSong.fromSong(
        song,
        vocals: separated[Stem.vocals.value]!,
        bass: separated[Stem.bass.value]!,
        drums: separated[Stem.drums.value]!,
        other: separated[Stem.other.value]!,
        modelName: modelName,
      );
    } finally {
      // Always dispose the model to free native resources
      await model.dispose();
    }
  }

  /// Read a WAV file and return raw float data.
  /// Returns a [_WavReadResult] with floatData, numChannels, and numFrames.
  _WavReadResult _readWavFile(String path) {
    final file = File(path);
    final bytes = file.readAsBytesSync();

    // Parse WAV header (RIFF/WAVE format)
    if (bytes.length < 44) {
      throw DemixingException('File too small to be a WAV file');
    }

    // Check RIFF header
    final riffId = String.fromCharCodes(bytes.sublist(0, 4));
    if (riffId != 'RIFF') {
      throw DemixingException('Not a WAV file (bad RIFF ID)');
    }

    // Check WAV type
    final wavType = String.fromCharCodes(bytes.sublist(8, 12));
    if (wavType != 'WAVE') {
      throw DemixingException('Not a WAV file (bad WAV type)');
    }

    // Parse chunks to find fmt and data
    int offset = 12;
    int numChannels = 0;
    int validBits = 0;
    int dataOffset = 0;
    int dataSize = 0;

    while (offset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = _readUint32LE(bytes, offset + 4);
      if (chunkId == 'fmt ') {
        numChannels = _readUint16LE(bytes, offset + 16);
        validBits = _readUint16LE(bytes, offset + 22);
        offset += 36;
      } else if (chunkId == 'data') {
        dataSize = chunkSize;
        dataOffset = offset + 8;
        break;
      } else {
        offset += 8 + chunkSize;
      }
    }

    if (dataOffset == 0 || dataSize == 0) {
      throw DemixingException('Could not find WAV data chunk');
    }

    // Convert PCM samples to normalized float [-1.0, 1.0]
    final bytesPerSample = validBits ~/ 8;
    final bytesPerFrame = bytesPerSample * numChannels;
    final totalFrames = dataSize ~/ bytesPerFrame;
    final floatData = <double>[];

    for (int frame = 0; frame < totalFrames; frame++) {
      final frameOffset = dataOffset + frame * bytesPerFrame;
      for (int channel = 0; channel < numChannels; channel++) {
        final sampleOffset = frameOffset + channel * bytesPerSample;
        int sample = 0;
        switch (bytesPerSample) {
          case 1: // 8-bit unsigned
            sample = bytes[sampleOffset] - 128;
            break;
          case 2: // 16-bit signed
            sample = _readInt16LE(bytes, sampleOffset);
            break;
          case 3: // 24-bit signed
            sample = _readInt24LE(bytes, sampleOffset);
            break;
          case 4: // 32-bit signed
            sample = _readInt32LE(bytes, sampleOffset);
            break;
          default:
            throw DemixingException('Unsupported bit depth: $validBits');
        }
        final maxVal = math.pow(2, validBits - 1);
        floatData.add(sample / maxVal);
      }
    }

    return _WavReadResult(floatData, numChannels, totalFrames);
  }

  /// Process audio in chunks using the demixing model.
  Future<void> _processChunks({
    required List<double> audioData,
    required int numChannels,
    required int numFrames,
    required Map<String, File> stemFiles,
    required List<String> stemNames,
    required ExecuTorchModel model,
  }) async {
    final nbChunks = (numFrames / _numBufferFrame).ceil();
    final isMono = numChannels == 1;

    for (int chunk = 0; chunk < nbChunks; chunk++) {
      final startFrame = chunk * _numBufferFrame;
      final endFrame = (startFrame + _numBufferFrame).clamp(0, numFrames);
      final framesInChunk = endFrame - startFrame;

      // Extract chunk and convert to stereo
      final chunkData = <double>[];

      for (int frame = 0; frame < framesInChunk; frame++) {
        final globalFrame = startFrame + frame;
        if (isMono) {
          // Mono: duplicate to stereo
          final sample = audioData[globalFrame];
          chunkData.add(sample);
          chunkData.add(sample);
        } else {
          // Stereo: interleave
          chunkData.add(audioData[globalFrame * 2]);
          chunkData.add(audioData[globalFrame * 2 + 1]);
        }
      }

      // --- NEW API: TensorData constructor (requires Uint8List, not List<double>) ---
      // Convert List<double> to Uint8List (float32 bytes)
      final inputBytes = _doubleListToFloat32Bytes(chunkData);

      // Create input tensor: shape [1, 2, framesInChunk]
      final inputTensor = TensorData(
        shape: [1, _stereoChannels, framesInChunk],
        dataType: TensorType.float32,
        data: inputBytes,
        name: 'input',
      );

      // Run inference (cross-platform via FFI)
      final outputs = await model.forward([inputTensor]);

      // --- NEW API: TensorData.data returns Uint8List, convert back to List<double> ---
      final outputData = _float32BytesToDoubleList(outputs[0].data);

      // Write to stem files (overlap-add)
      for (int stem = 0; stem < _numStems; stem++) {
        for (int channel = 0; channel < _stereoChannels; channel++) {
          for (int frame = 0; frame < framesInChunk; frame++) {
            final index = stem * framesInChunk * _stereoChannels +
                channel * framesInChunk +
                frame;
            if (index < outputData.length) {
              final clamped = outputData[index].clamp(-1.0, 1.0);
              stemFiles[stemNames[stem]]!.writeAsBytesSync(
                _writeFloatAsInt16(clamped),
                mode: FileMode.append,
              );
            }
          }
        }
      }
    }
  }

  /// Write a single float sample as 16-bit PCM little-endian.
  Uint8List _writeFloatAsInt16(double sample) {
    final int16 = (sample * 32767).toInt().clamp(-32768, 32767);
    return Uint8List.fromList([int16 & 0xFF, (int16 >> 8) & 0xFF]);
  }

  // --- WAV file parsing helpers ---

  int _readUint16LE(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _readUint32LE(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  int _readInt16LE(Uint8List bytes, int offset) {
    final val = _readUint16LE(bytes, offset);
    return val >= 32768 ? val - 65536 : val;
  }

  int _readInt24LE(Uint8List bytes, int offset) {
    final val = bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16);
    return val >= 8388608 ? val - 16777216 : val;
  }

  int _readInt32LE(Uint8List bytes, int offset) {
    final val = bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
    return val;
  }

  /// Check the [separated] result to make sure all stems are present.
  void checkResult(Map<String, String> separated) {
    final stems = [
      Stem.bass.value,
      Stem.drums.value,
      Stem.other.value,
      Stem.vocals.value,
    ];

    final sortedKeys = separated.keys.toList()..sort();
    final sortedStems = List<String>.from(stems)..sort();
    if (sortedKeys.length != sortedStems.length ||
        sortedKeys.asMap().entries.any((e) => e.value != sortedStems[e.key])) {
      throw DemixingException('Invalid demixing result');
    }
  }
}

// --- NEW API: Conversion helpers for float32 tensor data ---

/// Convert a List<double> (float32 range -1.0 to 1.0) to Uint8List (raw float32 bytes).
/// This is needed because the new executorch_flutter API requires Uint8List for tensor data.
Uint8List _doubleListToFloat32Bytes(List<double> values) {
  final byteData = Uint8List(values.length * 4);
  final float32List = Float32List.view(byteData.buffer);
  for (int i = 0; i < values.length; i++) {
    float32List[i] = values[i];
  }
  return byteData;
}

/// Convert Uint8List (raw float32 bytes from TensorData.data) back to List<double>.
List<double> _float32BytesToDoubleList(Uint8List bytes) {
  final float32List = Float32List.view(bytes.buffer);
  return float32List.toList();
}
