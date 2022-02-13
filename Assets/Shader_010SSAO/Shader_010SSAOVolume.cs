using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader_010SSAOVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    
    public FloatParameter radius    = new FloatParameter(0.05f);
    public FloatParameter bias          = new FloatParameter(0.01f);
    public FloatParameter magnitude     = new FloatParameter(1.5f);
    public FloatParameter contrast      = new FloatParameter(1.5f);
    
    public bool IsActive()
    {
        return intensity.overrideState;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
