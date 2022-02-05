using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader001UVAnimationVolume : VolumeComponent, IPostProcessComponent
{
    [Tooltip("Strength of the bloom filter.")]
    public MinFloatParameter intensity = new MinFloatParameter(0f, 0f);
    
    public bool IsActive()
    {
        return intensity.value > 0f;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
