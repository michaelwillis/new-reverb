module dsp.effects;

import dplug.core.nogc;
import dplug.dsp.delayline;
import dplug.dsp.iir;

enum : int
{
    noEffect,
    earlyEffect,
    plateEffect,
    roomEffect,
    hallEffect,
    effectCount
}

immutable string[] effectAlgorithmNames = [
  "Off",
  "Early",
  "Plate",
  "Room",
  "Hall",
];

interface Effect
{
public:
nothrow:
@nogc:
    void processAudio(float[] leftIn, float[] rightIn,
                      float[] leftOut, float[] rightOut,
                      int frames);
    void mute();
    void reset(double sampleRate, int maxFrames);
}

class NoEffect : Effect
{
public:
nothrow:
@nogc:

    this()
    {
    }

    void processAudio(float[] leftIn, float[] rightIn,
                      float[] leftOut, float[] rightOut,
                      int frames)
    {
        leftOut[0..frames] = 0.0;
        rightOut[0..frames] = 0.0;
    }

    void mute() { }
    void reset(double sampleRate, int maxFrames) { }
}
