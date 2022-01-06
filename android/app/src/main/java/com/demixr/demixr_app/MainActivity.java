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

        // Create a buffer of 500 000 frames
        int nbBufferFrame = 500000;
        double[] buffer = new double[nbBufferFrame * numChannels];

        // Read frames into buffer
        int framesRead = wavFile.readFrames(buffer, nbBufferFrame);

        double[][][] finalStems = new double[numStems][numChannels][numFrames];
        int chunkCount = 0;

        while (framesRead != 0) {
            double[][] audio = new double[2][framesRead];

            for (int i = 0; i < framesRead; i++) {
                audio[0][i] = buffer[i * 2];
                audio[1][i] = buffer[i * 2 + 1];
            }

            // Flatten array
            double[] doubleFlatArray = Arrays.stream(audio)
                    .flatMapToDouble(Arrays::stream)
                    .toArray();

            // Convert double array to float array
            float[] floatFlatArray = new float[doubleFlatArray.length];
            for (int i = 0 ; i < doubleFlatArray.length; i++) {
                floatFlatArray[i] = (float) doubleFlatArray[i];
            }

            // Create Tensor from flattened array
            Tensor inTensor = Tensor.fromBlob(floatFlatArray, new long[]{1, 2, framesRead});

            // Model inference
            IValue result = module.forward(IValue.from(inTensor));
            Tensor resultTensor = result.toTensor();
            float[] resultStems = resultTensor.getDataAsFloatArray();

            for (int i = 0; i < numStems; i++) {
                for (int j = 0; j < numChannels; j++) {
                    for (int k = 0; k < framesRead; k++) {
                        finalStems[i][j][k + chunkCount * nbBufferFrame] = resultStems[i * framesRead * numChannels + j * framesRead + k];
                    }
                }
            }
            framesRead = wavFile.readFrames(buffer, nbBufferFrame);
            chunkCount++;
        }

        // Close the wavFile
        wavFile.close();

        // create files for separated output
        try
        {
            int sampleRate = 44100;    // Samples per second

            for (int i = 0; i < numStems; i++) {
                File out = new File(outputDir, "stem_" + i + ".wav");
                out.createNewFile();
                WavFile sepFile = WavFile.newWavFile(out, 2, numFrames, 16, sampleRate);

                sepFile.writeFrames(finalStems[i], numFrames);

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
