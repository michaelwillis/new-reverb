module main;

import std.math;
import std.algorithm;
import std.stdio;

import dplug.core,
       dplug.client;

import gui;

import dsp.effects;
import dsp.early;
import dsp.plate;
import dsp.room;
import dsp.hall;

mixin(pluginEntryPoints!DragonflyReverbClient);

enum : int {
    paramMix,

    paramEffect1Gain,
    paramEffect1Send,
    paramEffect1Algorithm,
    paramEffect1EarlyReflectionPattern,
    paramEffect1Size,
    paramEffect1Width,
    paramEffect1Predelay,
    paramEffect1Decay,
    paramEffect1Diffuse,
    paramEffect1Modulation,
    paramEffect1Spin,
    paramEffect1Wander,
    paramEffect1HighCross,
    paramEffect1HighMult,
    paramEffect1HighCut,
    paramEffect1HighCutHard,
    paramEffect1LowCross,
    paramEffect1LowMult,
    paramEffect1LowCut,
    paramEffect1LowCutHard,

    paramEffect2Gain,
    paramEffect2Algorithm,
    paramEffect2EarlyReflectionPattern,
    paramEffect2Size,
    paramEffect2Width,
    paramEffect2Predelay,
    paramEffect2Decay,
    paramEffect2Diffuse,
    paramEffect2Modulation,
    paramEffect2Spin,
    paramEffect2Wander,
    paramEffect2HighCross,
    paramEffect2HighMult,
    paramEffect2HighCut,
    paramEffect2HighCutHard,
    paramEffect2LowCross,
    paramEffect2LowMult,
    paramEffect2LowCut,
    paramEffect2LowCutHard,
}

final class DragonflyReverbClient : dplug.client.Client
{
public:
nothrow:
@nogc:

    this() {
      noEffect = mallocNew!NoEffect();
      earlyEffect1 = mallocNew!EarlyEffect();
      earlyEffect2 = mallocNew!EarlyEffect();
      plateEffect1 = mallocNew!PlateEffect();
      plateEffect2 = mallocNew!PlateEffect();
      hallEffect1 = mallocNew!HallEffect();
      hallEffect2 = mallocNew!HallEffect();
      roomEffect1 = mallocNew!RoomEffect();
      roomEffect2 = mallocNew!RoomEffect();

      // These must have the same order as the enum
      effects1 = [noEffect, earlyEffect1, plateEffect1, roomEffect1, hallEffect1];
      effects2 = [noEffect, earlyEffect2, plateEffect2, roomEffect2, hallEffect2];
    }

    override PluginInfo buildPluginInfo() {
        static immutable PluginInfo pluginInfo = parsePluginInfo(import("plugin.json"));
        return pluginInfo;
    }

    // This is an optional overload, default is zero parameter.
    // Caution when adding parameters: always add the indices
    // in the same order as the parameter enum.
    override Parameter[] buildParameters() {
        auto params = makeVec!Parameter();

        params ~= mallocNew!LinearFloatParameter(paramMix, "Wet/Dry Mix", "%", 0.0f, 100.0f, 100.0f) ;

        params ~= mallocNew!GainParameter(paramEffect1Gain, "Effect 1 Gain", 10.0f, 0.0f);
        params ~= mallocNew!GainParameter(paramEffect1Send, "Effect 1 Send", 10.0f, 0.0f);
        params ~= mallocNew!EnumParameter(paramEffect1Algorithm, "Effect 1 Algorithm", effectAlgorithmNames, 1);
        params ~= mallocNew!EnumParameter(paramEffect1EarlyReflectionPattern,
            "Effect 1 Early Reflection Pattern", earlyReflectionPatternNames, 2);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Size, "Effect 1 Size", "m", 10.0f, 60.0f, 20.0);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Width, "Effect 1 Width", "%", 0.0f, 100.0f, 100.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Predelay, "Effect 1 Predelay", "ms", 0, 100, 4);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Decay, "Effect 1 Decay Time", "s", 0.1f, 10.0f, 0.5f);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Diffuse, "Effect 1 Diffuse", "%", 0.0f, 100.0f, 80.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Modulation, "Effect 1 Mod", "%", 0.0f, 100.0f, 20.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Spin, "Effect 1 Spin", "Hz", 0.0f, 10.0f, 1.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect1Wander, "Effect 1 Wander", "%", 0.0f, 100.0f, 20.0f);
        params ~= mallocNew!LogFloatParameter(paramEffect1HighCross, "Effect 1 High Cross", "Hz", 20, 20000, 6000);
        params ~= mallocNew!LinearFloatParameter(paramEffect1HighMult, "Effect 1 High Mult", "x", 0.1f, 2.5f, 0.5f);
        params ~= mallocNew!LogFloatParameter(paramEffect1HighCut, "Effect 1 High Cut", "Hz", 20, 20000, 12000);
        params ~= mallocNew!BoolParameter(paramEffect1HighCutHard, "Effect 1 High Cut Hard", false);
        params ~= mallocNew!LogFloatParameter(paramEffect1LowCross, "Effect 1 Low Cross", "Hz", 20, 20000, 1000);
        params ~= mallocNew!LinearFloatParameter(paramEffect1LowMult, "Effect 1 Low Mult", "x", 0.1f, 2.5f, 1.5f);
        params ~= mallocNew!LogFloatParameter(paramEffect1LowCut, "Effect 1 Low Cut", "Hz", 20, 20000, 400);
        params ~= mallocNew!BoolParameter(paramEffect1LowCutHard, "Effect 1 Low Cut Hard", false);

        params ~= mallocNew!GainParameter(paramEffect2Gain, "Effect 2 Gain", 10.0f, 0.0f);
        params ~= mallocNew!EnumParameter(paramEffect2Algorithm, "Effect 2 Algorithm", effectAlgorithmNames, 2);
        params ~= mallocNew!EnumParameter(paramEffect2EarlyReflectionPattern,
            "Effect 2 Early Reflection Pattern", earlyReflectionPatternNames, 2);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Size, "Effect 2 Size", "m", 10.0f, 60.0f, 20.0);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Width, "Effect 2 Width", "%", 0.0f, 100.0f, 100.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Predelay, "Effect 2 Predelay", "ms", 0, 100, 4);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Decay, "Effect 2 Decay Time", "s", 0.1f, 10.0f, 0.5f);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Diffuse, "Effect 2 Diffuse", "%", 0.0f, 100.0f, 80.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Modulation, "Effect 2 Mod", "%", 0.0f, 100.0f, 20.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Spin, "Effect 2 Spin", "Hz", 0.0f, 10.0f, 1.0f);
        params ~= mallocNew!LinearFloatParameter(paramEffect2Wander, "Effect 2 Wander", "%", 0.0f, 100.0f, 20.0f);
        params ~= mallocNew!LogFloatParameter(paramEffect2HighCross, "Effect 2 High Cross", "Hz", 20, 20000, 6000);
        params ~= mallocNew!LinearFloatParameter(paramEffect2HighMult, "Effect 2 High Mult", "x", 0.1f, 2.5f, 0.5f);
        params ~= mallocNew!LogFloatParameter(paramEffect2HighCut, "Effect 2 High Cut", "Hz", 20, 20000, 12000);
        params ~= mallocNew!BoolParameter(paramEffect2HighCutHard, "Effect 2 High Cut Hard", false);
        params ~= mallocNew!LogFloatParameter(paramEffect2LowCross, "Effect 2 Low Cross", "Hz", 20, 20000, 1000);
        params ~= mallocNew!LinearFloatParameter(paramEffect2LowMult, "Effect 2 Low Mult", "x", 0.1f, 2.5f, 1.5f);
        params ~= mallocNew!LogFloatParameter(paramEffect2LowCut, "Effect 2 Low Cut", "Hz", 20, 20000, 400);
        params ~= mallocNew!BoolParameter(paramEffect2LowCutHard, "Effect 2 Low Cut Hard", false);

        return params.releaseData();
    }

    override LegalIO[] buildLegalIO()
    {
        auto io = makeVec!LegalIO();
        io ~= LegalIO(2, 2);
        return io.releaseData();
    }

    // This override is also optional. It allows to split audio buffers in order to never
    // exceed some amount of frames at once.
    // This can be useful as a cheap chunking for parameter smoothing.
    // Buffer splitting also allows to allocate statically or on the stack with less worries.
    override int maxFramesInProcess() const //nothrow @nogc
    {
        return 512;
    }

    override void reset(double sampleRate, int maxFrames, int numInputs, int numOutputs) nothrow @nogc {
        // Clear here any state and delay buffers you might have.

        assert(maxFrames <= 512); // guaranteed by audio buffer splitting

        for (int effect = 0; effect < effectCount; effect++) {
          effects1[effect].reset(sampleRate, maxFrames);
          effects2[effect].reset(sampleRate, maxFrames);          
        }
    }

    override void processAudio(const(float*)[] inputs, float*[]outputs, int frames,
                               TimeInfo info) nothrow @nogc
    {
        assert(frames <= 512); // guaranteed by audio buffer splitting

        immutable float mix = readParam!float(paramMix) / 100.0f;

        immutable int effect1Algorithm = readParam!int(paramEffect1Algorithm);
        if (this.effect1Algorithm != effect1Algorithm) {
            // Mute previous algorithm, then switch
            effects1[this.effect1Algorithm].mute();
            this.effect1Algorithm = effect1Algorithm; 
        }

        immutable int effect2Algorithm = readParam!int(paramEffect2Algorithm);
        if (this.effect2Algorithm != effect2Algorithm) {
            // Mute previous algorithm, then switch
            effects2[this.effect2Algorithm].mute();
            this.effect2Algorithm = effect2Algorithm; 
        }

        immutable float effect1Gain = pow(10, readParam!float(paramEffect1Gain) / 20); // dB to mult
        immutable float effect2Gain = pow(10, readParam!float(paramEffect2Gain) / 20); // dB to mult
        immutable float effect1SendToEffect2 = pow(10, readParam!float(paramEffect1Send) / 20); // dB to mult

        immutable int effect1EarlyReflectionPattern = readParam!int(paramEffect1EarlyReflectionPattern);
        if (effect1EarlyReflectionPattern != earlyEffect1.getReflectionPattern()) {
          earlyEffect1.setReflectionPattern(effect1EarlyReflectionPattern);
        }

        immutable int effect2EarlyReflectionPattern = readParam!int(paramEffect2EarlyReflectionPattern);
        if (effect2EarlyReflectionPattern != earlyEffect2.getReflectionPattern()) {
          earlyEffect2.setReflectionPattern(effect2EarlyReflectionPattern);
        }

        immutable float effect1Predelay = readParam!float(paramEffect1Predelay);
        earlyEffect1.setPredelaySeconds(effect1Predelay / 1000.0);
        plateEffect1.setPredelaySeconds(effect1Predelay / 1000.0);
        roomEffect1.setPredelaySeconds(effect1Predelay / 1000.0);
        // TODO: Hall predelay

        immutable float effect2Predelay = readParam!float(paramEffect2Predelay);
        earlyEffect2.setPredelaySeconds(effect2Predelay / 1000.0);
        plateEffect2.setPredelaySeconds(effect2Predelay / 1000.0);
        roomEffect2.setPredelaySeconds(effect2Predelay / 1000.0);
        // TODO: Hall predelay

        immutable float effect1Decay = readParam!float(paramEffect1Decay);
        if (effect1Decay != this.effect1Decay) {
            this.effect1Decay = effect1Decay;
            plateEffect1.setDecaySeconds(effect1Decay);
            roomEffect1.setDecaySeconds(effect1Decay);
            // TODO: Hall
        }

        immutable float effect2Decay = readParam!float(paramEffect2Decay);
        if (effect2Decay != this.effect2Decay) {
            this.effect2Decay = effect2Decay;
            plateEffect2.setDecaySeconds(effect2Decay);
            roomEffect2.setDecaySeconds(effect2Decay);
            // TODO: Hall
        }

        immutable float effect1Size = readParam!float(paramEffect1Size);
        if (effect1Size != this.effect1Size) {
            this.effect1Size = effect1Size;
            earlyEffect1.setSize(effect1Size / 10.0);
            roomEffect1.setSize(effect1Size / 10.0);
            // TODO: Hall Size
        }

        immutable float effect2Size = readParam!float(paramEffect2Size);
        if (effect2Size != this.effect2Size) {
            this.effect2Size = effect2Size;
            earlyEffect2.setSize(effect2Size / 10.0);
            roomEffect2.setSize(effect2Size / 10.0);
            // TODO: Hall Size
        }

        immutable float effect1Width = readParam!float(paramEffect1Width) / 100.0;
        earlyEffect1.setWidth(effect1Width);
        plateEffect1.setWidth(effect1Width);
        roomEffect1.setWidth(effect1Width);
        // TODO: Width for Hall

        immutable float effect2Width = readParam!float(paramEffect2Width) / 100.0;
        earlyEffect2.setWidth(effect2Width);
        plateEffect2.setWidth(effect2Width);
        roomEffect2.setWidth(effect2Width);
        // TODO: Width for Hall

        immutable float effect1Diffuse = readParam!float(paramEffect1Diffuse);
        roomEffect1.setDiffusion(effect1Diffuse / 120.0);
        // TODO: hallEffect1.setDiffusion(effect1Diffuse / 140.0);

        immutable float effect2Diffuse = readParam!float(paramEffect2Diffuse);
        roomEffect2.setDiffusion(effect1Diffuse / 120.0);
        // TODO: hallEffect1.setDiffusion(effect1Diffuse / 140.0);

        immutable float effect1Modulation = readParam!float(paramEffect1Modulation);
        roomEffect1.setMod(effect1Modulation / 100.0);
        // TODO: hallEffect1.setMod(effect1Modulation / 100.0);

        immutable float effect2Modulation = readParam!float(paramEffect2Modulation);
        roomEffect2.setMod(effect2Modulation / 100.0);
        // TODO: hallEffect2.setMod(effect2Modulation / 100.0);

        immutable float effect1Spin = readParam!float(paramEffect1Spin);
        roomEffect1.setSpinFreq(effect1Spin);
        // TODO: hallEffect1.setSpinFreq(effect1Spin);

        immutable float effect2Spin = readParam!float(paramEffect2Spin);
        roomEffect2.setSpinFreq(effect2Spin);
        // TODO: hallEffect2.setSpinFreq(effect2Spin);

        immutable float effect1Wander = readParam!float(paramEffect1Wander);
        roomEffect1.setWander(effect1Wander);
        // TODO: hallEffect1.setWander(effect1Wander);

        immutable float effect2Wander = readParam!float(paramEffect2Wander);
        roomEffect2.setWander(effect2Wander);
        // TODO: hallEffect2.setWander(effect2Wander);

        immutable float effect1HighCut = readParam!float(paramEffect1HighCut);
        earlyEffect1.setHighCut(effect1HighCut);
        plateEffect1.setHighCut(effect1HighCut);
        roomEffect1.setHighCut(effect1HighCut);
        // TODO: High Cut for Hall   

        immutable float effect2HighCut = readParam!float(paramEffect2HighCut);
        earlyEffect2.setHighCut(effect2HighCut);
        plateEffect2.setHighCut(effect2HighCut);
        roomEffect2.setHighCut(effect2HighCut);
        // TODO: High Cut for Hall   

        immutable float effect1LowCut = readParam!float(paramEffect1LowCut);
        earlyEffect1.setLowCut(effect1LowCut);
        plateEffect1.setLowCut(effect1LowCut);
        roomEffect1.setLowCut(effect1LowCut);
        // TODO: Low Cut for Hall   

        immutable float effect2LowCut = readParam!float(paramEffect2LowCut);
        earlyEffect2.setLowCut(effect2LowCut);
        plateEffect2.setLowCut(effect2LowCut);
        roomEffect2.setLowCut(effect2LowCut);
        // TODO: Low Cut for Hall   

        for (int f = 0; f < frames; ++f) {
            effect1InL[f] = inputs[0][f];
            effect1InR[f] = inputs[1][f];
        }

        effects1[effect1Algorithm].processAudio(effect1InL, effect1InR, effect1OutL, effect1OutR, frames);

        for (int f = 0; f < frames; ++f) {
            effect2InL[f] = inputs[0][f] + effect1OutL[f] * effect1SendToEffect2;
            effect2InR[f] = inputs[1][f] + effect1OutR[f] * effect1SendToEffect2;
        }

        effects2[effect2Algorithm].processAudio(effect2InL, effect2InR, effect2OutL, effect2OutR, frames);

        for (int f = 0; f < frames; ++f) {
            float effectsLeft = (effect1OutL[f] * effect1Gain + effect2OutL[f] * effect2Gain);
            float effectsRight = (effect1OutR[f] * effect1Gain + effect2OutR[f] * effect2Gain);

            outputs[0][f] = (effectsLeft * mix) + (inputs[0][f] * (1.0 - mix));
            outputs[1][f] = (effectsRight * mix) + (inputs[1][f] * (1.0 - mix));            
        }

        if (DragonflyReverbGUI gui = cast(DragonflyReverbGUI) graphicsAcquire()) {
            // TODO: Populate the spectrogram
            graphicsRelease();
        }
    }

    override IGraphics createGraphics()
    {
        return mallocNew!DragonflyReverbGUI(this);
    }

private:
    int effect1Algorithm = earlyEffect;
    int effect2Algorithm = 0;

    // Cache old values to avoid setting them if they haven't changed.
    // Setting the decay and size parameters requires a bit more expensive
    // computation than just changing a numeric value like most of the params.
    float effect1Decay, effect2Decay, effect1Size, effect2Size;

    NoEffect noEffect;
    EarlyEffect earlyEffect1, earlyEffect2;
    HallEffect hallEffect1, hallEffect2;
    PlateEffect plateEffect1, plateEffect2;
    RoomEffect roomEffect1, roomEffect2;

    Effect[effectCount] effects1;
    Effect[effectCount] effects2;

    float[512] effect1InL;
    float[512] effect1InR;
    float[512] effect1OutL;
    float[512] effect1OutR;

    float[512] effect2InL;
    float[512] effect2InR;
    float[512] effect2OutL;
    float[512] effect2OutR;
}

