using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader_009BloomVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    
    public Vector4Parameter shader009BloomSize = new Vector4Parameter(new Vector4(5.0f,3.0f,0.4f,1.0f));
    
    public bool IsActive()
    {
        return intensity.overrideState && intensity.value > 0f;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
