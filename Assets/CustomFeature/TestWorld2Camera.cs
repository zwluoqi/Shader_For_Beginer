using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class TestWorld2Camera : MonoBehaviour
{
    public Camera _ca;
    public Vector3 cameraPos;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        cameraPos = _ca.worldToCameraMatrix * new Vector4(this.transform.position.x,this.transform.position.y,this.transform.position.z,1);
    }
}
