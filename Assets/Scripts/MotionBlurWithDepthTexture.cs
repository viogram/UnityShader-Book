using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial=null;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 1.0f)]
    public float blursize = 0.5f;

    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    private Matrix4x4 previousVPM;
    void OnEnabel()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material!=null)
        {
            material.SetFloat("_BlurSize", blursize);
            material.SetMatrix("_PreviousVPM", previousVPM);
            Matrix4x4 currentVPM = camera.projectionMatrix * camera.worldToCameraMatrix;
            Matrix4x4 currentVPIM = currentVPM.inverse;
            material.SetMatrix("_CurrentVPIM", currentVPIM);
            previousVPM= currentVPM;

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
