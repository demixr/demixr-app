package com.demixr.demixr_app;

import androidx.annotation.NonNull;
import android.content.Context;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.loader.FlutterLoader;

import org.pytorch.IValue;
import org.pytorch.Module;
import org.pytorch.Tensor;
import org.pytorch.LiteModuleLoader;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.FloatBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

public class MainActivity extends FlutterActivity {
  private static Module module;
  private static final String CHANNEL = "demixing";

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler(
            (call, result) -> {
              switch (call.method) {
                case "separate":
                  try {
                    final String audioPath = call.argument("songPath");
                    final String modelPath = call.argument("modelPath");
                    final String outputPath = call.argument("outputPath");

                    result.success(separate(audioPath, modelPath, outputPath));
                  } catch (Exception e) {
                    e.printStackTrace();
                    result.error("DEMIXING_ERROR", e.getMessage(), null);
                  }
                  break;
                default:
                  result.notImplemented();
              }
            });
  }

  private void loadModel(String modelPath) {
    if (module == null) {
      module = LiteModuleLoader.load(modelPath);
    }
  }

  private WavFile openWavFile(String audioPath) throws IOException, WavFileException {
    File toSeparate = new File(audioPath);
    return WavFile.openWavFile(toSeparate);
  }

  private Map<String, WavFile> createFiles(String[] stemNames, String outputDir, int numChannels, int numFrames,
      int numBits, int sampleRate) throws IOException, WavFileException {
    Map<String, WavFile> stemFiles = new HashMap<String, WavFile>();

    for (String stemName : stemNames) {
      File stemFile = new File(outputDir, stemName + ".wav");
      stemFile.createNewFile();
      stemFiles.put(stemName, WavFile.newWavFile(stemFile, numChannels, numFrames, numBits, sampleRate));
    }
    return stemFiles;
  }

  // Close the wav files (input and outputs)
  private void closeWavFiles(WavFile inputWav, Map<String, WavFile> stemFiles, String[] stemNames) throws IOException {
    inputWav.close();
    for (String stemName : stemNames) {
      stemFiles.get(stemName).close();
    }
  }

  private Tensor preprocessWavChunk(double[] buffer, int framesRead) {
    FloatBuffer flatAudio = Tensor.allocateFloatBuffer(framesRead * 2);

    // First channel
    for (int i = 0; i < framesRead; i++) {
      flatAudio.put((float) buffer[i * 2]);
    }

    // Second channel
    for (int i = 0; i < framesRead; i++) {
      flatAudio.put((float) buffer[i * 2 + 1]);
    }

    // Create Tensor from flattened array
    return Tensor.fromBlob(flatAudio, new long[] { 1, 2, framesRead });
  }

  private double[][][] reshapeOutput(float[] prediction, int numBufferFrame, int numStems, int numChannels,
      int framesRead) {
    double[][][] outputStems = new double[numStems][numChannels][numBufferFrame];

    for (int i = 0; i < numStems; i++) {
      for (int j = 0; j < numChannels; j++) {
        for (int k = 0; k < framesRead; k++) {
          outputStems[i][j][k] = prediction[i * framesRead * numChannels + j * framesRead + k];
        }
      }
    }

    return outputStems;
  }

  private Map<String, WavFile> writeToWavFile(Map<String, WavFile> stemFiles, String[] stemNames,
      double[][][] outputStems, int numStems, int numBufferFrame) {
    try {
      for (int i = 0; i < numStems; i++) {
        stemFiles.get(stemNames[i]).writeFrames(outputStems[i], numBufferFrame);
      }
    } catch (Exception e) {
      System.err.println(e);
    }
    return stemFiles;
  }

  // Model inference
  private float[] predict(Tensor inTensor) {
    IValue result = module.forward(IValue.from(inTensor));
    Tensor resultTensor = result.toTensor();
    return resultTensor.getDataAsFloatArray();
  }

  private Map<String, WavFile> predictByChunk(WavFile wavFile, Map<String, WavFile> stemFiles, String[] stemNames,
      int numBufferFrame, int numStems) throws IOException, WavFileException {
    int numChannels = wavFile.getNumChannels();

    double[] buffer = new double[numBufferFrame * numChannels];
    int framesRead = wavFile.readFrames(buffer, numBufferFrame);

    while (framesRead != 0) {
      Tensor inTensor = preprocessWavChunk(buffer, framesRead);
      float[] prediction = predict(inTensor);
      double[][][] outputStems = reshapeOutput(prediction, numBufferFrame, numStems, numChannels, framesRead);

      stemFiles = writeToWavFile(stemFiles, stemNames, outputStems, numStems, numBufferFrame);

      // Get next frames
      framesRead = wavFile.readFrames(buffer, numBufferFrame);
    }
    return stemFiles;
  }

  private Map<String, String> separate(String audioPath, String modelPath, String outputDir)
      throws IOException, WavFileException {
    loadModel(modelPath);

    WavFile wavFile = openWavFile(audioPath);

    int numChannels = wavFile.getNumChannels();
    int numFrames = (int) wavFile.getNumFrames();
    int numStems = 4;
    int numBufferFrame = 1000000;
    int numBits = 16;
    int sampleRate = 44100;

    String[] stemNames = new String[] { "vocals", "drums", "bass", "other" };
    Map<String, WavFile> stemFiles = createFiles(stemNames,
        outputDir,
        numChannels,
        numFrames,
        numBits,
        sampleRate);

    predictByChunk(wavFile, stemFiles, stemNames, numBufferFrame, numStems);

    closeWavFiles(wavFile, stemFiles, stemNames);

    // Create new dictionary with stem paths as values
    return stemFiles.entrySet().stream()
        .collect(Collectors.toMap(el -> el.getKey(), el -> el.getValue().getFile().getAbsolutePath()));
  }
}
