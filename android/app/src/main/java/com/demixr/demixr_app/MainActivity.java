package com.demixr.demixr_app;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import org.pytorch.IValue;
import org.pytorch.LiteModuleLoader;
import org.pytorch.Module;
import org.pytorch.Tensor;
import com.demixr.demixr_app.WavFile;
import com.demixr.demixr_app.WavFileException;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;

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
                  final String audioPath = call.argument("songPath");
                  final String modelPath = call.argument("modelPath");

                  result.success(fakeSeparate(audioPath, modelPath, ""));
                  break;
                default:
                  result.notImplemented();
              }
            });
  }

  int fakeSeparate(String audioPath, String modelPath, String outputDir) {
    return 0;
  }

  void separate(String audioPath, String modelPath, String outputDir) throws IOException, WavFileException {
    if (module == null) {
      module = LiteModuleLoader.load(modelPath);
    }

    File toSeparate = new File(audioPath);

    // Open the wav file specified as the first argument
    WavFile wavFile = WavFile.openWavFile(toSeparate);

    // Get the number of audio channels in the wav file
    int numChannels = wavFile.getNumChannels();
    int numFrames = (int) wavFile.getNumFrames();
    int numStems = 4;

    // Create a buffer of 1 000 000 frames
    int nbBufferFrame = 1000000;
    double[] buffer = new double[nbBufferFrame * numChannels];

    // Read frames into buffer
    int framesRead = wavFile.readFrames(buffer, nbBufferFrame);

    double[][][] outputStems = new double[numStems][numChannels][nbBufferFrame];

    String[] stemNames = new String[]{"vocals", "drums", "bass", "other"};
    Map<String, WavFile> stemFiles = new HashMap<String, WavFile>();

    for (String stemName : stemNames) {
      File stemFile = new File(directory, stemName + ".wav");
      stemFile.createNewFile();
      stemFiles.put(stemName, WavFile.newWavFile(stemFile, 2, numFrames, 16, sampleRate));
    }

    while (framesRead != 0) {
      FloatBuffer flatAudio = Tensor.allocateFloatBuffer(framesRead * 2);

      // first channel
      for (int i = 0; i < framesRead; i++) {
        flatAudio.put((float) buffer[i * 2]);
      }

      // second channel
      for (int i = 0; i < framesRead; i++) {
        flatAudio.put((float) buffer[i * 2 + 1]);
      }

      // Create Tensor from flattened array
      Tensor inTensor = Tensor.fromBlob(flatAudio, new long[]{1, 2, framesRead});
      System.out.println("yo wassup " + framesRead);

      // Model inference
      IValue result = module.forward(IValue.from(inTensor));
      Tensor resultTensor = result.toTensor();
      float[] prediction = resultTensor.getDataAsFloatArray();

      for (int i = 0; i < numStems; i++) {
        for (int j = 0; j < numChannels; j++) {
          for (int k = 0; k < framesRead; k++) {
            outputStems[i][j][k] = prediction[i * framesRead * numChannels + j * framesRead + k];
          }
        }
      }

      try {
        for (int i = 0; i < numStems; i++) {
          stemFiles.get(stemNames[i]).writeFrames(outputStems[i], nbBufferFrame);
        }
      }
      catch (Exception e) {
          System.err.println(e);
      }

      // Get next frames
      framesRead = wavFile.readFrames(buffer, nbBufferFrame);
    }

    // Close the wav files (input and outputs)
    wavFile.close();
    for (String stemName : stemNames) {
      stemFiles.get(stemName).close();
    }

    return stemFiles.entrySet().stream()
      .collect(Collectors.toMap(el -> el.getKey(), el -> el.getValue().getFile().getAbsolutePath()));
  }
}
