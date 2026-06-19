import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path/path.dart' as p;

import '../../models/exceptions/demixing_exception.dart';

/// Decodes the audio file at [inputPath] to deinterleaved 32-bit float PCM,
/// resampled to [sampleRate] and forced to [channels] channels.
///
/// Returns one [Float32List] per channel, samples in `[-1.0, 1.0]`. Uses
/// FFmpeg (already a dependency) so any container/codec it supports works and
/// mono inputs are up-mixed to stereo. Replaces the old native C++ resampler.
Future<List<Float32List>> decodeToFloatPcm(
  String inputPath, {
  int sampleRate = 44100,
  int channels = 2,
}) async {
  final rawPath = '${p.withoutExtension(inputPath)}.f32le.pcm';
  final rawFile = File(rawPath);
  if (await rawFile.exists()) await rawFile.delete();

  // `-f f32le` writes raw little-endian float samples with no header, which we
  // can map straight into a Float32List on every (little-endian) target.
  try {
    final session = await FFmpegKit.execute(
      '-y -i "$inputPath" -ac $channels -ar $sampleRate '
      '-f f32le -acodec pcm_f32le "$rawPath"',
    );
    if (!ReturnCode.isSuccess(await session.getReturnCode())) {
      throw DemixingException('Failed to decode audio for demixing');
    }

    final bytes = await rawFile.readAsBytes();

    // Interleaved [c0, c1, c0, c1, ...] -> one buffer per channel.
    final interleaved = bytes.buffer.asFloat32List(
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 4,
    );
    final frames = interleaved.length ~/ channels;
    final out = List.generate(channels, (_) => Float32List(frames));
    for (var i = 0; i < frames; i++) {
      final base = i * channels;
      for (var c = 0; c < channels; c++) {
        out[c][i] = interleaved[base + c];
      }
    }
    return out;
  } finally {
    // Always remove the (possibly partial) raw PCM, even on decode failure.
    if (await rawFile.exists()) await rawFile.delete();
  }
}

/// Streaming writer for 16-bit PCM WAV files.
///
/// The total frame count must be known up front (it is — we decode the whole
/// mixture before inference) so the 44-byte header can be written immediately
/// and stem samples streamed to disk as the overlap-add finalizes them. This
/// keeps peak memory bounded to roughly one segment instead of the whole song.
class WavWriter {
  final IOSink _sink;
  final int channels;

  WavWriter._(this._sink, this.channels);

  static Future<WavWriter> create(
    String path, {
    required int sampleRate,
    required int channels,
    required int totalFrames,
  }) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    final sink = file.openWrite();
    sink.add(
      _header(
        sampleRate: sampleRate,
        channels: channels,
        totalFrames: totalFrames,
      ),
    );
    return WavWriter._(sink, channels);
  }

  /// Appends [count] frames starting at [start] from the per-channel float
  /// buffers in [chans], clamped and quantized to 16-bit PCM.
  void addFrames(List<Float32List> chans, int start, int count) {
    final out = Uint8List(count * channels * 2);
    final view = ByteData.view(out.buffer);
    var pos = 0;
    for (var i = 0; i < count; i++) {
      for (var c = 0; c < channels; c++) {
        var s = chans[c][start + i];
        if (s > 1.0) s = 1.0;
        if (s < -1.0) s = -1.0;
        view.setInt16(pos, (s * 32767.0).round(), Endian.little);
        pos += 2;
      }
    }
    _sink.add(out);
  }

  Future<void> close() => _sink.close();

  static Uint8List _header({
    required int sampleRate,
    required int channels,
    required int totalFrames,
  }) {
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = totalFrames * blockAlign;

    final header = ByteData(44);
    void writeTag(int offset, String tag) {
      for (var i = 0; i < tag.length; i++) {
        header.setUint8(offset + i, tag.codeUnitAt(i));
      }
    }

    writeTag(0, 'RIFF');
    header.setUint32(4, 36 + dataSize, Endian.little);
    writeTag(8, 'WAVE');
    writeTag(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // PCM fmt chunk size
    header.setUint16(20, 1, Endian.little); // audio format = PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeTag(36, 'data');
    header.setUint32(40, dataSize, Endian.little);
    return header.buffer.asUint8List();
  }
}
