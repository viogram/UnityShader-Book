using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectsBase
{
    private Material bloomMaterial;

    [Range(0, 4)]
    public int iterations = 3; //迭代次数
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;  //模糊范围
    [Range(1, 8)]
    public int downSample = 2;  //缩放系数
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;   //较亮区域的阈值

    public Shader bloomShader;
    public Material material
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            int rtW = source.width / downSample;
            int rtH = source.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtH, rtW, 0);
            buffer0.filterMode = FilterMode.Bilinear;
            //第一个Pass提取较亮的区域
            Graphics.Blit(source, buffer0, material, 0);
            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                //第二个Pass竖直采样
                Graphics.Blit(buffer0, buffer1, material, 1);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;

                buffer1=RenderTexture.GetTemporary(rtW, rtH, 0);
                //第三个Pass水平采样
                Graphics.Blit(buffer0, buffer1, material, 2);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }
            material.SetTexture("_Bloom", buffer0);
            //第四个Pass进行混合
            Graphics.Blit(source, destination, material, 3);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
