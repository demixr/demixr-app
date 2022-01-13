#include <jni.h>
#include <memory>

#include <android/asset_manager_jni.h>

#include "resampler/MultiChannelResampler.h"

extern "C" {

JNIEXPORT jdoubleArray JNICALL
Java_com_demixr_demixr_1app_DemixingPlugin_resample(JNIEnv *env, jobject jobj, jdoubleArray inputBuffer, jint numInputFrames, jint inputSampleRate)
{
    int channelCount = 2;
    std::vector<double> input(numInputFrames * channelCount);
    env->GetDoubleArrayRegion(inputBuffer, 0, numInputFrames * channelCount, &input[0]);


    float *floatInput = new float[numInputFrames * channelCount];
    for (int i = 0; i < numInputFrames * channelCount; i++) {
        floatInput[i] = input[i];
    }

    long outputSize = ((std::size_t) numInputFrames * 44100 / inputSampleRate + 1) * channelCount;

    float *outputBuffer = new float[outputSize];    // multi-channel buffer to be filled
    double *doubleOutputBuffer = new double[outputSize];    // multi-channel buffer to be filled

    float *start = outputBuffer;
    int numOutputFrames = 0;

    resampler::MultiChannelResampler *res = resampler::MultiChannelResampler::make(
            channelCount,
            inputSampleRate,
            44100,
            resampler::MultiChannelResampler::Quality::Best);

    int inputFramesLeft = numInputFrames;
    while (inputFramesLeft > 0) {
        if(res->isWriteNeeded()) {
            res->writeNextFrame(floatInput);
            floatInput += channelCount;
            inputFramesLeft--;
        } else {
            res->readNextFrame(outputBuffer);
            outputBuffer += channelCount;
            numOutputFrames++;
        }
    }

    for (int i = 0; i < numOutputFrames * channelCount; i++) {
        doubleOutputBuffer[i] = start[i];
    }

    jdoubleArray out = env->NewDoubleArray(numOutputFrames * channelCount);
    env->SetDoubleArrayRegion(out, 0, numOutputFrames * channelCount, doubleOutputBuffer);

    delete res;

    return out;
}

}