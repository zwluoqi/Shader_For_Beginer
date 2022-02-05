using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public sealed class Shader007FogVolume : VolumeComponent, IPostProcessComponent
{
    
    [Tooltip("Select Shader.")]
    public IntParameter intensity = new IntParameter(1);
    
    public Vector2Parameter shader007NearFar = new Vector2Parameter(new Vector2(0.1f,10f));
    public ColorParameter shader007FogColor = new ColorParameter(new Color(1.0f,1.0f,1.0f,1.0f));
    
    public bool IsActive()
    {
        return intensity.overrideState && intensity.value > 0f;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
