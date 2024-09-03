using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class GoodRay : PostEffectsBase
{
    private Material godRayMaterial;

    public Shader godRayShader;
    public Material material
    {
        get
        {
            godRayMaterial = CheckShaderAndCreateMaterial(godRayShader, godRayMaterial);
            return godRayMaterial;
        }
    }

    // 高亮部分提取阈值
    public Color colorThreshold = Color.gray;
    // 光颜色
    public Color lightColor = Color.white;
    // 光强度
    [Range(0.0f, 20.0f)]
    public float lightFactor = 0.5f;
    // 径向模糊uv采样偏移值
    [Range(0.0f, 10.0f)]
    public float samplerScale = 1;
    // 迭代次数
    [Range(1, 5)]
    public int blurIteration = 2;
    // 分辨率缩放系数
    [Range(1, 5)]
    public int downSample = 1;
    // 光源位置
    public Transform lightTransform;
    // 光源范围
    [Range(0.0f, 5.0f)]
    public float lightRadius = 2.0f;
    // 提取高亮结果Pow系数，用于适当降低颜色过亮的情况
    [Range(1.0f, 4.0f)]
    public float lightPowFactor = 3.0f;


    private Camera targetCamera = null;
    void Awake()
    {
        targetCamera = GetComponent<Camera>();
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null && targetCamera != null)
        {
            //计算光源位置从世界空间转化到视口空间
            Vector3 viewPortLightPos = lightTransform == null ? new Vector3(.5f, .5f, 0) : targetCamera.WorldToViewportPoint(lightTransform.position);
            material.SetVector("_ColorThreshold", colorThreshold);
            material.SetVector("_ViewPortLightPos", new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0));
            material.SetFloat("_LightRadius", lightRadius);
            material.SetFloat("_PowFactor", lightPowFactor);

            int rtW = source.width / downSample;
            int rtH = source.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtH, rtW, 0, source.format);
            //第一个Pass提取较亮的区域
            Graphics.Blit(source, buffer0, material, 0);
            //计算径向偏移的uv值
            float samplerOffset= samplerScale/source.width;

            for (int i = 0; i < blurIteration; i++)
            {
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
                float offset = samplerOffset * (i * 2 + 1);
                material.SetVector("_offsets", new Vector4(offset, offset, 0, 0));
                Graphics.Blit(buffer0, buffer1, material, 1);

                offset = samplerOffset * (i * 2 + 2);
                material.SetVector("_offsets", new Vector4(offset, offset, 0, 0));
                Graphics.Blit(buffer1, buffer0, material, 1);
                RenderTexture.ReleaseTemporary(buffer1);
            }
            //将完成模糊的结果传递给材质中的属性

            material.SetTexture("_BlurTex", buffer0);
            material.SetVector("_LightColor", lightColor);
            material.SetFloat("_LightFactor", lightFactor);

            // 将径向模糊结果与原图进行混合
            Graphics.Blit(source, destination, material, 2);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
