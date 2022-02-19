using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader_012ChromaticAberrationVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    
    public FloatParameter redOffset = new FloatParameter(0.009f);
    public FloatParameter greenOffset = new FloatParameter(0.006f);
    public FloatParameter blueOffset = new FloatParameter(-0.006f);

    
    public bool IsActive()
    {
        return intensity.overrideState;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
