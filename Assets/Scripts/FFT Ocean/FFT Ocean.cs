using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFT_Ocean : MonoBehaviour
{
    public FFT_Parameters param;
    public Shader genJONSWAP, renderOcean, advanceOcean;
    public ComputeShader computeFFT;

    public Material renderMaterial;

    private RenderTexture[] jonswapTextures;
    private RenderTexture[] timeSpecTextures;
    private RenderTexture oceanTex;
    private RenderTexture[] fftTextures;
    private RenderTexture[] fftDerivTextures;

    private RenderTexture fftPrecomputeBuffer;
    private RenderTexture fftPingPongBuffer0;
    private RenderTexture fftPingPongBuffer1;

    private Material[] jonswapMaterials;
    private Material[] timeSpecMaterials;
    private Material renderOceanMat;
    private Material[] fftMaterials;
    private Material[] fftDerivMaterials;

    private int size;

    void Start()
    {
        size = param.resolution;

        // Initialize arrays
        jonswapTextures = new RenderTexture[4];
        timeSpecTextures = new RenderTexture[4];
        fftTextures = new RenderTexture[4];
        fftDerivTextures = new RenderTexture[4];
        jonswapMaterials = new Material[4];
        timeSpecMaterials = new Material[4];
        fftMaterials = new Material[4];
        fftDerivMaterials = new Material[4];

        fftPrecomputeBuffer = createRenderTexture(size);
        fftPingPongBuffer0 = createRenderTexture(size);
        fftPingPongBuffer1 = createRenderTexture(size);

        // Initialize the RenderTextures and Materials
        for (int i = 0; i < 4; i++)
        {
            jonswapTextures[i] = createRenderTexture(size);
            timeSpecTextures[i] = createRenderTexture(size);
            fftTextures[i] = createRenderTexture(size);
            fftDerivTextures[i] = createRenderTexture(size);

            ClearRenderTexture(jonswapTextures[i]);
            ClearRenderTexture(timeSpecTextures[i]);
            ClearRenderTexture(fftTextures[i]);
            ClearRenderTexture(fftDerivTextures[i]);

            jonswapMaterials[i] = new Material(genJONSWAP);
            timeSpecMaterials[i] = new Material(advanceOcean);
        }

        oceanTex = createRenderTexture(size);
        ClearRenderTexture(oceanTex);
        renderOceanMat = new Material(renderOcean);

        // Set the parameters for the JONSWAP spectrum
        SetJONSWAPParameters(jonswapMaterials[0], param, param.jonswap1);
        SetJONSWAPParameters(jonswapMaterials[1], param, param.jonswap2);
        SetJONSWAPParameters(jonswapMaterials[2], param, param.jonswap3);
        SetJONSWAPParameters(jonswapMaterials[3], param, param.jonswap4);

        // Render the JONSWAP spectrum to the texture
        Graphics.Blit(null, jonswapTextures[0], jonswapMaterials[0]);
        Graphics.Blit(null, jonswapTextures[1], jonswapMaterials[1]);
        Graphics.Blit(null, jonswapTextures[2], jonswapMaterials[2]);
        Graphics.Blit(null, jonswapTextures[3], jonswapMaterials[3]);

        // render jonsawp to check
        GetComponent<Renderer>().material.mainTexture = jonswapTextures[0];
        

    }

    void Update()
    {
        // // Perform time stepping on the ocean textures
        // for (int i = 0; i < 4; i++)
        // {
        //     timeSpecMaterials[i].SetTexture("_h0", jonswapTextures[i]);
        //     timeSpecMaterials[i].SetFloat("_FrameTime", Time.deltaTime);
        //     timeSpecMaterials[i].SetFloat("_N", size);
        //     //timeSpecMaterials[i].SetTexture("_Ocean", oceanTex);
        //     Graphics.Blit(null, timeSpecTextures[i], timeSpecMaterials[i]);
        // }

        // // Perform FFT on the spectrum textures
        // for (int i = 0; i < 4; i++)
        // {
        //     PerformFFT(timeSpecTextures[i], fftTextures[i]);
        // }

        // GetComponent<Renderer>().material.mainTexture = fftTextures[0];

        // for (int i = 0; i < 4; i++)
        // {
        //     PerformFFT(fftTextures[i], fftDerivTextures[i]);
        // }

        // GetComponent<Renderer>().material.mainTexture = timeSpecTextures[0];

        // // Set the render texture for the ocean shader
        // setRenderTexture();

        // // Set the object's material to the ocean material
        // GetComponent<Renderer>().material = renderOceanMat;
    }

    void ClearRenderTexture(RenderTexture rt)
    {
        RenderTexture.active = rt;
        GL.Clear(true, true, Color.clear);
        RenderTexture.active = null;
    }

    RenderTexture createRenderTexture(int resolution)
    {
        RenderTexture renderTexture = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGBHalf);
        renderTexture.enableRandomWrite = true; 
        renderTexture.filterMode = FilterMode.Bilinear;
        renderTexture.wrapMode = TextureWrapMode.Repeat;
        renderTexture.Create();
        return renderTexture;
    }

    void PerformFFT(RenderTexture input, RenderTexture output)
    {
        int precomputeKernel = computeFFT.FindKernel("PrecomputeTwiddleFactorsAndInputIndices");
        int horizontalStepKernel = computeFFT.FindKernel("HorizontalStepFFT");
        int verticalStepKernel = computeFFT.FindKernel("VerticalStepFFT");
        int scaleKernel = computeFFT.FindKernel("Scale");

        // Precompute twiddle factors and indices
        computeFFT.SetTexture(precomputeKernel, "PrecomputeBuffer", fftPrecomputeBuffer);
        computeFFT.SetInt("Size", size);
        computeFFT.Dispatch(precomputeKernel, size / 8, size / 8, 1);

        // Horizontal FFT step
        computeFFT.SetTexture(horizontalStepKernel, "PrecomputedData", fftPrecomputeBuffer);
        computeFFT.SetTexture(horizontalStepKernel, "Buffer0", input);
        computeFFT.SetTexture(horizontalStepKernel, "Buffer1", fftPingPongBuffer1);
        computeFFT.SetBool("PingPong", true);

        for (int step = 0; step < Mathf.Log(size, 2); step++)
        {
            computeFFT.SetInt("Step", step);
            computeFFT.Dispatch(horizontalStepKernel, size / 8, size / 8, 1);
            // Swap buffers
            SwapBuffers();
        }

        // Vertical FFT step
        computeFFT.SetTexture(verticalStepKernel, "PrecomputedData", fftPrecomputeBuffer);
        computeFFT.SetTexture(verticalStepKernel, "Buffer0", fftPingPongBuffer1);
        computeFFT.SetTexture(verticalStepKernel, "Buffer1", output);
        computeFFT.SetBool("PingPong", true);

        for (int step = 0; step < Mathf.Log(size, 2); step++)
        {
            computeFFT.SetInt("Step", step);
            computeFFT.Dispatch(verticalStepKernel, size / 8, size / 8, 1);
            // Swap buffers
            SwapBuffers();
        }

        // Scale the output
        computeFFT.SetTexture(scaleKernel, "Buffer0", output);
        computeFFT.Dispatch(scaleKernel, size / 8, size / 8, 1);
    }

    void SwapBuffers()
    {
        // Swap the ping pong buffers
        var temp = fftPingPongBuffer0;
        fftPingPongBuffer0 = fftPingPongBuffer1;
        fftPingPongBuffer1 = temp;
    }

    void SetJONSWAPParameters(Material mat, FFT_Parameters p, FFT_Parameters.JONSWAP jonswap)
    {
        mat.SetInt("_N", size);
        mat.SetInt("_L", p.patchSize);
        mat.SetFloat("_gamma", 3.3f);
        mat.SetFloat("_g", 9.81f);
        mat.SetFloat("_wp", calcJONSWAPwp(jonswap.windSpeed, jonswap.windFetch));
        mat.SetFloat("_alpha", calcJONSWAPalpha(jonswap.windSpeed, jonswap.windFetch));
        mat.SetFloat("_anlge", jonswap.windDirection);
        mat.SetInt("_seed", Random.Range(0, 100));
        mat.SetFloat("_oceanDepth", jonswap.oceanDepth);
    }

    float calcJONSWAPwp(float U10, float F)
    {
        return 22 * Mathf.Pow(9.81f / (U10 * F), 1.0f / 3.0f);
    }

    float calcJONSWAPalpha(float U10, float F)
    {
        return 0.076f * Mathf.Pow(U10 / (F * 9.81f), 0.22f);
    }

    void setRenderTexture()
    {
        renderOceanMat.SetTexture("_fftTexture1", fftTextures[0]);
        renderOceanMat.SetTexture("_fftTexture2", fftTextures[1]);
        renderOceanMat.SetTexture("_fftTexture3", fftTextures[2]);
        renderOceanMat.SetTexture("_fftTexture4", fftTextures[3]);

        renderOceanMat.SetTexture("_fftDerivative1", fftDerivTextures[0]);
        renderOceanMat.SetTexture("_fftDerivative2", fftDerivTextures[1]);
        renderOceanMat.SetTexture("_fftDerivative3", fftDerivTextures[2]);
        renderOceanMat.SetTexture("_fftDerivative4", fftDerivTextures[3]);
    }
}
