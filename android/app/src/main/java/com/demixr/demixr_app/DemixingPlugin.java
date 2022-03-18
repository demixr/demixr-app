package com.demixr.demixr_app;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import org.pytorch.IValue;
import org.pytorch.LiteModuleLoader;
import org.pytorch.Module;
import org.pytorch.Tensor;
import org.pytorch.Device;

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

/**
 * Implements demixing logic for Android devices. It implements FlutterPluggin
 * so it can be called directly in dart.
 */
public class DemixingPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private static Module module; /* Store the PyTorch model for the prediction */
    private MethodChannel methodChannel; /* Platform method channel to communicate with Flutter */
    private EventChannel eventChannel; /* Platform event channel to communicate with Flutter */
    private EventChannel.EventSink progressStream; /* Stream to communicate with FLutter the demixing progress */

    private static final String channelName = "demixing";
    private static final String eventName = "demixing/progress";
    private static final String separateMethod = "separate";

    private static final int numBufferFrame = 250000; /* The number of frames we will use at each iteration */

    private final int MONO = 1; /* Macro like to define mono songs */
    private final int STEREO = 2; /* Macro like to define stereo songs */

    // cpp resample function
    static {
        System.loadLibrary("wavResampler");
    }

    /**
     * This method is implemented in cpp. It resamples the sound if it is not in 44100 Hz.
     * @param inputBuffer This is the array with all the current frames we read.
     * @param numInputFrames The number of frames read in inputBuffer.
     * @param inputSampleRate The sample rate of the song before resampling.
     * @param channelCount Indicates if the song is in mono (1) or stereo (2).
     * @return float[] The new frames with a 44100 Hz sample rate.
     */
    public native float[] resample(float[] inputBuffer, int numInputFrames, int inputSampleRate, int channelCount);


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        BinaryMessenger messenger = binding.getBinaryMessenger();
        BinaryMessenger.TaskQueue taskQueue = messenger.makeBackgroundTaskQueue();
        methodChannel = new MethodChannel(
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
                new Handler(Looper.getMainLooper()).post(() -> result.error("DemixingError", e.getMessage(), null));
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

    /**
     * Load the PyTorch torchscript model
     * @param modelPath The path to the model file
     */
    private void loadModel(String modelPath) {
        if (module == null) {
            module = LiteModuleLoader.load(modelPath, null, Device.VULKAN);
        }
    }

    /**
     * Open the wav file to separate.
     * @param audioPath The path to the wav file.
     * @return WavFile Class used to manage the wav file.
     * @throws IOException
     * @throws WavFileException
     */
    private WavFile openWavFile(String audioPath) throws IOException, WavFileException {
        File toSeparate = new File(audioPath);
        return WavFile.openWavFile(toSeparate);
    }

    /**
     * Close the wav files (input and outputs)
     * @param inputWav The input wav file.
     * @param stemFiles A map with all the output wav files (for vocals, bass, drums, other).
     * @param stemNames Array with all the stems (vocals, bass, drums, other).
     * @throws IOException
     */
    private void closeWavFiles(WavFile inputWav, Map<String, WavFile> stemFiles, String[] stemNames)
            throws IOException {
        inputWav.close();
        for (String stemName : stemNames) {
            Objects.requireNonNull(stemFiles.get(stemName)).close();
        }
    }

    /**
     * Create all the output wav files.
     * @param stemNames Array with all the stems (vocals, bass, drums, other)
     * @param outputDir Path to the output directory where we will save all the output wav files.
     * @param numChannels The number of channel for the wav files (1 for mono and 2 for stereo).
     * @param numFrames The number of frames we will have in the different files.
     * @param numBits The number of bits used for the output songs.
     * @param sampleRate The sample rate used for the output songs.
     * @return Map A map that links a stem name to its wav file.
     * @throws IOException
     * @throws WavFileException
     */
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

    /**
     * Convert a mono song to stereo.
     * @param buffer Input buffer were the song is in mono.
     * @param flatAudio The buffer were we will write the song in stereo.
     * @param framesRead The number of frames read from the mono song.
     */
    private void monoToStereo(float[] buffer, FloatBuffer flatAudio, int framesRead) {
        for (int i = 0; i < 2; i++) {
            for (int j = 0; j < framesRead; j++) {
                flatAudio.put(buffer[j]);
            }
        }
    }

    /**
     * Convert a chunk of the song in Tensor for PyTorch model.
     * @param buffer Input buffer with the frames read.
     * @param framesRead The number of frames read.
     * @param numChannels The number of channels in the song (1 for mono and 2 for stereo).
     * @return Tensor The tensor ready to be predicted by the model.
     */
    private Tensor preprocessWavChunk(float[] buffer, int framesRead, int numChannels) {
        FloatBuffer flatAudio = Tensor.allocateFloatBuffer(framesRead * STEREO);

        // convert to stereo
        if (numChannels == MONO) {
            monoToStereo(buffer, flatAudio, framesRead);
        } else {
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
        return Tensor.fromBlob(flatAudio, new long[] { 1, STEREO, framesRead });
    }

    /**
     * Reshape the prediction so we can save it in the output wavfiles.
     * @param prediction One dimensional array with the prediction.
     * @param numStems The number of stems from the prediction.
     * @param framesRead The number of frames read in this chunk.
     * @return float[][][] The prediction with the stem number in first dimension, the number of
     *                     channel in second dimension and the frames in third dimension.
     */
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

    /**
     * Write the prediction in the output wav files.
     * @param stemFiles The map linking all the stem names to their wav files.
     * @param stemNames The names of the different stems (vocals, bass, drums, other).
     * @param outputStems The three dimension array with all the predictions.
     * @param numStems The number of stems we predicted.
     * @param numBufferFrame The number of frames in the buffer to write.
     * @throws IOException
     * @throws WavFileException
     */
    private void writeToWavFile(Map<String, WavFile> stemFiles, String[] stemNames,
            float[][][] outputStems, int numStems, int numBufferFrame) throws IOException, WavFileException {
        for (int i = 0; i < numStems; i++) {
            Objects.requireNonNull(stemFiles.get(stemNames[i])).writeFrames(outputStems[i], numBufferFrame);
        }
    }

    // Model inference

    /**
     * Model inference, predict the outputs.
     * @param inTensor The input tensor with the frames read in this chunk.
     * @return float[] Array with all the predictions.
     */
    private float[] predict(Tensor inTensor) {
        IValue result = module.forward(IValue.from(inTensor));
        Tensor resultTensor = result.toTensor();
        return resultTensor.getDataAsFloatArray();
    }

    /**
     * Cut the entire song in multiple chunks to avoid RAM overflow and predict the output from it.
     * @param wavFile The input wav file.
     * @param stemFiles The map with all the output wav files.
     * @param stemNames The names of the different stems (vocals, bass, drums, other).
     * @param numStems The number of stems we use.
     * @throws IOException
     * @throws WavFileException
     */
    private void predictByChunk(WavFile wavFile, Map<String, WavFile> stemFiles, String[] stemNames,
            int numStems) throws IOException, WavFileException {
        int numChannels = wavFile.getNumChannels();

        long numFrames = wavFile.getNumFrames();
        int nbChunks = (int) (numFrames / numBufferFrame) + 1;

        float[] buffer = new float[numBufferFrame * numChannels];
        int framesRead = wavFile.readFrames(buffer, numBufferFrame);

        double currentChunk = 0.0;

        // While we have frame to read, we continue the prediction
        while (framesRead != 0) {
            // Resample sound
            if (wavFile.getSampleRate() != 44100) {
                buffer = resample(buffer, framesRead, (int) wavFile.getSampleRate(), numChannels);
                framesRead = buffer.length / numChannels;
            }

            // Prepare input tensor
            Tensor inTensor = preprocessWavChunk(buffer, framesRead, numChannels);

            // Predict with the PyTorch model
            float[] prediction = predict(inTensor);

            // Reshape output so we can write it in output wav files.
            float[][][] outputStems = reshapeOutput(prediction, numStems, framesRead);

            writeToWavFile(stemFiles, stemNames, outputStems, numStems, framesRead);

            // Get next frames
            buffer = new float[numBufferFrame * numChannels];
            framesRead = wavFile.readFrames(buffer, numBufferFrame);

            // compute current demixing percentage
            currentChunk += 1;
            Double demixingPercentage = currentChunk / nbChunks;

            // If the user exit the prediction, we leave the loop
            if (progressStream == null) break;
            new Handler(Looper.getMainLooper()).post(() -> progressStream.success(demixingPercentage));
        }
    }

    /**
     * Separate a input wav file into multiple output wav files with the vocals, bass, drums and
     * other.
     * @param audioPath Path to the input wav file.
     * @param modelPath Path to the PyTorch model.
     * @param outputDir Path to the output directory.
     * @return Map The map where we link a stem name and its output file.
     * @throws IOException
     * @throws WavFileException
     */
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

        String[] stemNames = new String[] { "vocals", "drums", "bass", "other" };
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
