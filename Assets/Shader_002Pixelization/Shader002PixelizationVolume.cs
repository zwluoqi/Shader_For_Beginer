using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader002PixelizationVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    
    public bool IsActive()
    {
        return intensity.value > 0f;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
