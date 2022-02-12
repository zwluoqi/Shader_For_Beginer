using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader_011MotionBlurVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    
    public Vector2Parameter _blurSize = new Vector2Parameter(new Vector2(1.0f,2.0f));

    
    public bool IsActive()
    {
        return intensity.overrideState;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
