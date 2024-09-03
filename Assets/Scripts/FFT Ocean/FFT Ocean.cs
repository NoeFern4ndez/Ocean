using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFT_Ocean : MonoBehaviour
{
    public FFT_Parameters param;
    public Shader genJONSWAP, renderOcean;
    public ComputeShader computeFFT;

    public Material renderMaterial;

    private RenderTexture[] jonswapTextures;
    private RenderTexture oceanTex;
    private RenderTexture[] fftTextures;
    private RenderTexture[] fftDerivTextures;

    private Material[] jonswapMaterials;
    private Material renderOceanMat;
    private Material[] fftMaterials;
    private Material[] fftDerivMaterials;

    void Start()
    {
        // Initialize arrays
        jonswapTextures = new RenderTexture[4];
        fftTextures = new RenderTexture[4];
        fftDerivTextures = new RenderTexture[4];
        jonswapMaterials = new Material[4];
        fftMaterials = new Material[4];
        fftDerivMaterials = new Material[4];

        // Initialize the RenderTextures and Materials
        for (int i = 0; i < 4; i++)
        {
            jonswapTextures[i] = createRenderTexture(param.resolution);
            fftTextures[i] = createRenderTexture(param.resolution);
            fftDerivTextures[i] = createRenderTexture(param.resolution);

            ClearRenderTexture(jonswapTextures[i]);
            ClearRenderTexture(fftTextures[i]);
            ClearRenderTexture(fftDerivTextures[i]);

            jonswapMaterials[i] = new Material(genJONSWAP);
            // fftMaterials[i] = new Material(computeFFT);
            // fftDerivMaterials[i] = new Material(computeFFT);
        }

        oceanTex = createRenderTexture(param.resolution);
        ClearRenderTexture(oceanTex);
        renderOceanMat = new Material(renderOcean);

        // Set the parameters for the JONSWAP spectrum
        SetJONSWAPParameters(jonswapMaterials[0], param, param.jonswap1);
        SetJONSWAPParameters(jonswapMaterials[1], param, param.jonswap2);
        SetJONSWAPParameters(jonswapMaterials[2], param, param.jonswap3);
        SetJONSWAPParameters(jonswapMaterials[3], param, param.jonswap4);
    }

    void ClearRenderTexture(RenderTexture rt)
    {
        RenderTexture.active = rt;
        GL.Clear(true, true, Color.clear);
        RenderTexture.active = null;
    }

    void Update()
    {

    }

    RenderTexture createRenderTexture(int resolution)
    {
        RenderTexture renderTexture = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGBFloat);
        renderTexture.filterMode = FilterMode.Bilinear;
        renderTexture.wrapMode = TextureWrapMode.Clamp;
        renderTexture.Create();
        return renderTexture;
    }

    /*
        JONSWAP SHADER:
            -Spectrum texture: h0 = 1 / sqrt(2) * (Xr + iXi) * sqrt(S(w))
            -Xr, Xi: Gaussian random numbers
            -S(w): JONSWAP spectrum

            Output: texture where R channel is the real part and G channel is the imaginary part
            -Distance from the center of the texture is the frequency
            -Value of the R and G channels is the amplitude of the wave
            -Direction of the wave is the angle of the pixel to the center of the texture
    */
    void SetJONSWAPParameters(Material mat, FFT_Parameters p, FFT_Parameters.JONSWAP jonswap)
    {
        mat.SetFloat("_A", jonswap.A);
        mat.SetFloat("_B", jonswap.B);
        mat.SetFloat("_g", jonswap.g);
        mat.SetFloat("_sigma", jonswap.sigma);
        mat.SetFloat("_omegaPeak", jonswap.omegaPeak);
        mat.SetFloat("_alpha", jonswap.alpha);
        mat.SetFloat("_gamma", jonswap.gamma);
        mat.SetFloat("_Xir", generateGaussianRandomNumber());
        mat.SetFloat("_Xii", generateGaussianRandomNumber());
    }

    float generateGaussianRandomNumber(float mean = 0, float stand_deviation = 1)
    {
        float u1 = Random.value;
        float u2 = Random.value;
        float rand_std_normal = Mathf.Sqrt(-2.0f * Mathf.Log(u1)) * Mathf.Sin(2.0f * Mathf.PI * u2);
        return mean + stand_deviation * rand_std_normal;
    }
}
