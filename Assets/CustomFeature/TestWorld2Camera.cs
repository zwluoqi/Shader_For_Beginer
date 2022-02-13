using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class TestWorld2Camera : MonoBehaviour
{
    public Camera _ca;
    public Vector3 cameraPos;

    public Matrix4x4 worldToCameraMatrix;
    public Matrix4x4 cameraToWorldMatrix;
    public Matrix4x4 projectionMatrix;
    public Matrix4x4 invprojectionMatrix;
    
    public Matrix4x4 invVPMatrix;
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        worldToCameraMatrix = _ca.worldToCameraMatrix;
        cameraToWorldMatrix = _ca.cameraToWorldMatrix;
        projectionMatrix = GL.GetGPUProjectionMatrix(_ca.projectionMatrix,true);
        invprojectionMatrix = projectionMatrix.inverse;
        invVPMatrix = cameraToWorldMatrix * invprojectionMatrix ;
        cameraPos = _ca.worldToCameraMatrix * new Vector4(this.transform.position.x,this.transform.position.y,this.transform.position.z,1);
    }
}
