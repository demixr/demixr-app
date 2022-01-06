package com.demixr.demixr_app;

import io.flutter.embedding.android.FlutterActivity;

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

  void recognize(String audioPath, String modelPath, String outputDir) throws IOException, WavFileException {
    if (module == null) {
      module = LiteModuleLoader.load(audioPath);
    }

    File toSeparate = new File(modelPath);

    // Open the wav file specified as the first argument
    WavFile wavFile = WavFile.openWavFile(toSeparate);

    // Get the number of audio channels in the wav file
    int numChannels = wavFile.getNumChannels();
    int numFrames = (int) wavFile.getNumFrames();

    // Create a buffer
    double[] buffer = new double[numFrames * numChannels];

    int framesRead;

    do
    {
      // Read frames into buffer
      framesRead = wavFile.readFrames(buffer, numFrames);
    }
    while (framesRead != 0);

    // Close the wavFile
    wavFile.close();

    double[][] audio = new double[2][(int) wavFile.getNumFrames()];

    for (int i = 0; i < wavFile.getNumFrames(); i++) {
      audio[0][i] = buffer[i * 2];
      audio[1][i] = buffer[i * 2 + 1];
    }

    double[] flatArray = Arrays.stream(audio)
            .flatMapToDouble(Arrays::stream)
            .toArray();

    float[] floatArray = new float[flatArray.length];
    for (int i = 0 ; i < flatArray.length; i++)
    {
      floatArray[i] = (float) flatArray[i];
    }

    Tensor inTensor = Tensor.fromBlob(floatArray, new long[]{1, 2, numFrames});
    IValue result = module.forward(IValue.from(inTensor));
    Tensor newTensor = result.toTensor();
    float[] newWav = newTensor.getDataAsFloatArray();

    int numStems = 4;
    double[][][] reshaped = new double[numStems][numChannels][numFrames];

    for (int i = 0; i < numStems; i++) {
      for (int j = 0; j < numChannels; j++) {
        for (int k = 0; k < numFrames; k++) {
          reshaped[i][j][k] = newWav[i * numFrames * numChannels + j * numFrames + k];
        }
      }
    }

    // create files for separated output
    try
    {
      int sampleRate = 44100;    // Samples per second

      for (int i = 0; i < numStems; i++) {
        File out = new File(outputDir, "stem_" + i + ".wav");
        out.createNewFile();
        WavFile sepFile = WavFile.newWavFile(out, 2, numFrames, 16, sampleRate);

        sepFile.writeFrames(reshaped[i], numFrames);

        // Close the wavFile
        sepFile.close();
      }
    }
    catch (Exception e)
    {
      System.err.println(e);
    }
  }
}
