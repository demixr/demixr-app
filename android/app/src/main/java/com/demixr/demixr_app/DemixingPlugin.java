package com.demixr.demixr_app;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import org.pytorch.IValue;
import org.pytorch.LiteModuleLoader;
import org.pytorch.Module;
import org.pytorch.Tensor;

import java.io.File;
import java.io.IOException;
import java.nio.FloatBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import androidx.annotation.NonNull;

import androidx.annotation.RequiresApi;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMethodCodec;

public class DemixingPlugin implements FlutterPlugin, MethodCallHandler {
    private static Module module;
    private MethodChannel channel;

    private static final String channelName = "demixing";
    private static final String separateMethod = "separate";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        BinaryMessenger messenger = binding.getBinaryMessenger();
        BinaryMessenger.TaskQueue taskQueue =
                messenger.makeBackgroundTaskQueue();
        channel =
                new MethodChannel(
                        messenger,
                        channelName,
                        StandardMethodCodec.INSTANCE,
                        taskQueue);
        channel.setMethodCallHandler(this);
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals(separateMethod)) {
            try {
                final String audioPath = call.argument("songPath");
                final String modelPath = call.argument("modelPath");
                final String outputPath = call.argument("outputPath");

                Map<String, String> stems = separate(audioPath, modelPath, outputPath);

                new Handler(Looper.getMainLooper()).post(() -> result.success(stems));
            } catch (Exception e) {
                new Handler(Looper.getMainLooper()).post(() ->
                        result.error("DemixingError", e.getMessage(), null));
            }
        } else {
            new Handler(Looper.getMainLooper()).post(result::notImplemented);
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
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
        Map<String, WavFile> stemFiles = new HashMap<>();

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
            Objects.requireNonNull(stemFiles.get(stemName)).close();
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
        return Tensor.fromBlob(flatAudio, new long[]{1, 2, framesRead});
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

    private void writeToWavFile(Map<String, WavFile> stemFiles, String[] stemNames,
                                double[][][] outputStems, int numStems, int numBufferFrame) throws IOException, WavFileException {
        for (int i = 0; i < numStems; i++) {
            Objects.requireNonNull(stemFiles.get(stemNames[i])).writeFrames(outputStems[i], numBufferFrame);
        }
    }

    // Model inference
    private float[] predict(Tensor inTensor) {
        IValue result = module.forward(IValue.from(inTensor));
        Tensor resultTensor = result.toTensor();
        return resultTensor.getDataAsFloatArray();
    }

    private void predictByChunk(WavFile wavFile, Map<String, WavFile> stemFiles, String[] stemNames,
                                                int numBufferFrame, int numStems) throws IOException, WavFileException {
        int numChannels = wavFile.getNumChannels();

        double[] buffer = new double[numBufferFrame * numChannels];
        int framesRead = wavFile.readFrames(buffer, numBufferFrame);

        while (framesRead != 0) {
            Tensor inTensor = preprocessWavChunk(buffer, framesRead);
            float[] prediction = predict(inTensor);
            double[][][] outputStems = reshapeOutput(prediction, numBufferFrame, numStems, numChannels, framesRead);

            writeToWavFile(stemFiles, stemNames, outputStems, numStems, numBufferFrame);

            // Get next frames
            framesRead = wavFile.readFrames(buffer, numBufferFrame);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
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

        String[] stemNames = new String[]{"vocals", "drums", "bass", "other"};
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
                .collect(Collectors.toMap(Map.Entry::getKey, el -> el.getValue().getFile().getAbsolutePath()));
    }
}
