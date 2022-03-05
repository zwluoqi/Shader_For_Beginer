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
    
    // public Vector4Parameter shader009BloomSize = new Vector4Parameter(new Vector4(5.0f,3.0f,0.4f,1.0f));
    
    //这些参数控制外观和感觉。x决定了效果的模糊程度。y将模糊的画面展开。z控制哪些片段被照亮。w控制输出多少bloom。           
    public FloatParameter size = new FloatParameter(3);
    public FloatParameter seperate = new FloatParameter(3);
    public FloatParameter threshold   = new FloatParameter(0.4f);
    public FloatParameter amount  = new FloatParameter(1);
    
    public bool IsActive()
    {
        return intensity.overrideState;
        
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
