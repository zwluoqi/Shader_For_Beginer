using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader_008BlurVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    public IntParameter iteration = new IntParameter(1);
    
    public IntParameter size = new IntParameter(3);
    public IntParameter radius = new IntParameter(2);

    
    public bool IsActive()
    {
        return intensity.overrideState;
        
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
