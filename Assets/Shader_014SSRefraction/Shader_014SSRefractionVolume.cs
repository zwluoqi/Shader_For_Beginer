using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader_014SSRefractionVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    
    public FloatParameter maxDistance    = new FloatParameter(15f);
    public FloatParameter resolution          = new FloatParameter(0.3f);
    public FloatParameter steps     = new FloatParameter(10);
    public FloatParameter thickness      = new FloatParameter(0.5f);
    public FloatParameter roughness      = new FloatParameter(0.5f);

    
    public bool IsActive()
    {
        return intensity.overrideState;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
