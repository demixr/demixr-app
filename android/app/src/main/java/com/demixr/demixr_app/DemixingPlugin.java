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
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMethodCodec;

public class DemixingPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private static Module module;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventChannel.EventSink progressStream;

    private static final String channelName = "demixing";
    private static final String eventName = "demixing/progress";
    private static final String separateMethod = "separate";

    private static final int numBufferFrame = 2000000;
    private Integer demixingPercentage = 0;

    // cpp resample function
    static {
        System.loadLibrary("wavResampler");
    }
    public native float[] resample(float[] inputBuffer, int numInputFrames, int inputSampleRate, int channelCount);

    private final int MONO = 1;
    private final int STEREO = 2;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        BinaryMessenger messenger = binding.getBinaryMessenger();
        BinaryMessenger.TaskQueue taskQueue =
                messenger.makeBackgroundTaskQueue();
        methodChannel =
                new MethodChannel(
                        messenger,
                        channelName,
                        StandardMethodCodec.INSTANCE,
                        taskQueue);
        methodChannel.setMethodCallHandler(this);

        eventChannel = new EventChannel(messenger, eventName);
        eventChannel.setStreamHandler(this);
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
        methodChannel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
    }

    @java.lang.Override
    public void onListen(java.lang.Object arguments, EventChannel.EventSink events) {
        progressStream = events;
    }

    @java.lang.Override
    public void onCancel(java.lang.Object arguments) {
        progressStream = null;
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

    // Close the wav files (input and outputs)
    private void closeWavFiles(WavFile inputWav, Map<String, WavFile> stemFiles, String[] stemNames) throws IOException {
        inputWav.close();
        for (String stemName : stemNames) {
            Objects.requireNonNull(stemFiles.get(stemName)).close();
        }
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

    private void monoToStereo(float[] buffer, FloatBuffer flatAudio, int framesRead) {
        for (int i = 0; i < 2; i++) {
            for (int j = 0; j < framesRead; j++) {
                flatAudio.put(buffer[j]);
            }
        }
    }

    private Tensor preprocessWavChunk(float[] buffer, int framesRead, int numChannels) {
        FloatBuffer flatAudio = Tensor.allocateFloatBuffer(framesRead * STEREO);

        // convert to stereo
        if (numChannels == MONO) {
            monoToStereo(buffer, flatAudio, framesRead);
        }
        else {
            // First channel
            for (int i = 0; i < framesRead; i++) {
                flatAudio.put(buffer[i * 2]);
            }

            // Second channel
            for (int i = 0; i < framesRead; i++) {
                flatAudio.put(buffer[i * 2 + 1]);
            }
        }

        // Create Tensor from flattened array
        return Tensor.fromBlob(flatAudio, new long[]{1, STEREO, framesRead});
    }

    private float[][][] reshapeOutput(float[] prediction, int numStems, int framesRead) {
        float[][][] outputStems = new float[numStems][STEREO][framesRead];

        for (int i = 0; i < numStems; i++) {
            for (int j = 0; j < STEREO; j++) {
                for (int k = 0; k < framesRead; k++) {
                    outputStems[i][j][k] = prediction[i * framesRead * STEREO + j * framesRead + k];
                }
            }
        }

        return outputStems;
    }

    private void writeToWavFile(Map<String, WavFile> stemFiles, String[] stemNames,
                                float[][][] outputStems, int numStems, int numBufferFrame) throws IOException, WavFileException {
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
                                int numStems) throws IOException, WavFileException {
        int numChannels = wavFile.getNumChannels();

        long numFrames = wavFile.getNumFrames();
        int nbChunks = (int) (numFrames / numBufferFrame);

        float[] buffer = new float[numBufferFrame * numChannels];
        int framesRead = wavFile.readFrames(buffer, numBufferFrame);

        int currentChunk = 0;

        while (framesRead != 0) {
            // Resample sound
            if (wavFile.getSampleRate() != 44100) {
                buffer = resample(buffer, framesRead, (int) wavFile.getSampleRate(), numChannels);
                framesRead = buffer.length / numChannels;
            }

            Tensor inTensor = preprocessWavChunk(buffer, framesRead, numChannels);
            float[] prediction = predict(inTensor);
            float[][][] outputStems = reshapeOutput(prediction, numStems, framesRead);

            writeToWavFile(stemFiles, stemNames, outputStems, numStems, framesRead);

            // Get next frames
            buffer = new float[numBufferFrame * numChannels];
            framesRead = wavFile.readFrames(buffer, numBufferFrame);

            // compute current demixing percentage
            currentChunk += 1;
            demixingPercentage = currentChunk / nbChunks * 100;
            progressStream.success(demixingPercentage);
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
        int numBits = 16;
        int sampleRate = 44100;

        String[] stemNames = new String[]{"vocals", "drums", "bass", "other"};
        Map<String, WavFile> stemFiles = createFiles(stemNames,
                outputDir,
                numChannels,
                numFrames,
                numBits,
                sampleRate);

        predictByChunk(wavFile, stemFiles, stemNames, numStems);

        closeWavFiles(wavFile, stemFiles, stemNames);

        // Create new dictionary with stem paths as values
        return stemFiles.entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, el -> el.getValue().getFile().getAbsolutePath()));
    }
}
