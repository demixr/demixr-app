#include <jni.h>
#include <memory>

#include <android/asset_manager_jni.h>

#include "resampler/MultiChannelResampler.h"

extern "C" {

/**
 * Resample sound to 44100 Hz using oboe.
 * @param env Java environment.
 * @param jobj Instance of the java class (here DemixingPlugin).
 * @param inputBuffer The input buffer with the chunk of the input file to resample.
 * @param numInputFrames The number of frames read in the chunk.
 * @param inputSampleRate The sample rate of the input file.
 * @param channelCount The number of channel in the song (1 for mono and 2 for stereo).
 * @return jfloatArray Java float array with the frames read in 44100 Hz.
 */
JNIEXPORT jfloatArray JNICALL
Java_com_demixr_demixr_1app_DemixingPlugin_resample(JNIEnv *env, jobject jobj,
                                                    jfloatArray inputBuffer,
                                                    jint numInputFrames,
                                                    jint inputSampleRate,
                                                    jint channelCount)
{
    int numOutputFrames = 0;
    int outputSampleRate = 44100;

    float *floatInput = new float[numInputFrames * channelCount];
    floatInput = env->GetFloatArrayElements(inputBuffer, 0);

    long outputSize = ((std::size_t) numInputFrames * outputSampleRate / inputSampleRate + 1) * channelCount;
    float *outputBuffer = new float[outputSize];    // multi-channel buffer to be filled

    resampler::MultiChannelResampler *res = resampler::MultiChannelResampler::make(
            channelCount,
            inputSampleRate,
            outputSampleRate,
            resampler::MultiChannelResampler::Quality::Best);

    int inputFramesLeft = numInputFrames;
    while (inputFramesLeft > 0) {
        if(res->isWriteNeeded()) {
            res->writeNextFrame(floatInput);
            floatInput += channelCount;
            inputFramesLeft--;
        } else {
            res->readNextFrame(outputBuffer + numOutputFrames * channelCount);
            numOutputFrames++;
        }
    }

    jfloatArray out = env->NewFloatArray(numOutputFrames * channelCount);
    env->SetFloatArrayRegion(out, 0, numOutputFrames * channelCount, outputBuffer);

    delete res;

    return out;
}

}