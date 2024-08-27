using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NavierStokes : MonoBehaviour
{
    public GameObject forceObject;
    public NS_Parameters ns;
    public Shader advection, boundaryConditions, divergence, forceApplication, gradientSubstraction, jacobi, render;

    public Material renderMaterial;

    private RenderTexture velTexture, pressureTexture, inkTexture, vorticityTexture, swapTexture1, swapTexture2;
    private Material advectionMaterial, boundaryConditionsMaterial, divergenceMaterial, forceApplicationMaterial, gradientSubstractionMaterial, jacobiMaterial;

    private Vector3 forceObject_oldPosition = Vector3.zero;

    private bool rendVel = false;
    void Start()
    {
        Renderer renderer = GetComponent<Renderer>();
        renderMaterial = renderer.material;

        changeMaterial(ref renderMaterial, render);

        // Initialize the RenderTextures
        velTexture = createRenderTexture(ns.resolution);
        pressureTexture = createRenderTexture(ns.resolution);
        inkTexture = createRenderTexture(ns.resolution);
        vorticityTexture = createRenderTexture(ns.resolution);
        swapTexture1 = createRenderTexture(ns.resolution);
        swapTexture2 = createRenderTexture(ns.resolution);

        // Create materials from shaders
        advectionMaterial = new Material(advection);
        boundaryConditionsMaterial = new Material(boundaryConditions);
        divergenceMaterial = new Material(divergence);
        forceApplicationMaterial = new Material(forceApplication);
        gradientSubstractionMaterial = new Material(gradientSubstraction);
        jacobiMaterial = new Material(jacobi);
    }

    void Update()
    {
        float texelSize = 1.0f / ns.resolution;
        // Pasos de la simulación
        // Advección de la velocidad
        advectionMaterial.SetFloat("_uTexelSize", texelSize);
        advectionMaterial.SetFloat("_uTimeStep", ns.timestep);
        advectionMaterial.SetFloat("_uDissipation", ns.dissipation);
        advectionMaterial.SetTexture("_uV", velTexture);
        advectionMaterial.SetTexture("_uX", velTexture);
        Graphics.Blit(velTexture, swapTexture1, advectionMaterial); // swapTexture1 = advection(velTexture, velTexture)
        Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1
    
        // Advección de la tinta
        advectionMaterial.SetFloat("_uTexelSize", texelSize);
        advectionMaterial.SetFloat("_uTimeStep", ns.timestep);
        advectionMaterial.SetFloat("_uDissipation", ns.inkDissipation);
        advectionMaterial.SetTexture("_uV", velTexture);
        advectionMaterial.SetTexture("_uX", inkTexture);
        Graphics.Blit(inkTexture, swapTexture1, advectionMaterial); // swapTexture1 = advection(velTexture, inkTexture)
        Graphics.Blit(swapTexture1, inkTexture); // inkTexture = swapTexture1

        // Aplicación de fuerzas a la velocidad
        Vector3 Force = forceObject_oldPosition - forceObject.transform.position;
        Vector3 ForcePosition = new Vector3((-forceObject.transform.position.x + 10) / 20, (-forceObject.transform.position.z + 10) / 20, forceObject.transform.position.y); 
        forceObject_oldPosition = forceObject.transform.position;

        forceApplicationMaterial.SetFloat("_uTexelSize", texelSize);
        forceApplicationMaterial.SetTexture("_uC", velTexture);
        forceApplicationMaterial.SetFloat("_uTimestep", ns.timestep);
        forceApplicationMaterial.SetVector("_uForce", new Vector3(Force.x, Force.z, Force.y));
        forceApplicationMaterial.SetVector("_uForceLocation", ForcePosition);
        forceApplicationMaterial.SetFloat("_uRadius", ns.forceRadius / 1000);
        Graphics.Blit(velTexture, swapTexture1, forceApplicationMaterial); // swapTexture1 = forceApplication(velTexture)
        Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1

        // Aplicación de fuerzas a la tinta
        forceApplicationMaterial.SetFloat("_uTexelSize", texelSize);
        forceApplicationMaterial.SetTexture("_uC", inkTexture);
        forceApplicationMaterial.SetFloat("_uTimestep", ns.timestep);
        forceApplicationMaterial.SetVector("_uForce", new Vector3(ns.inkColor.r, ns.inkColor.g, ns.inkColor.b));
        forceApplicationMaterial.SetVector("_uForceLocation", ForcePosition);
        forceApplicationMaterial.SetFloat("_uRadius", ns.forceRadius / 1000);
        Graphics.Blit(inkTexture, swapTexture1, forceApplicationMaterial); // swapTexture1 = forceApplication(inkTexture)
        Graphics.Blit(swapTexture1, inkTexture); // inkTexture = swapTexture1

        // Difusión viscosa de la velocidad
        float alpha = (texelSize * texelSize) / ns.timestep;
        float beta = alpha + 4.0f;
        for (int i = 0; i < 30; i++)
        {
            jacobiMaterial.SetFloat("_uTexelSize", texelSize);
            jacobiMaterial.SetFloat("_uAlpha", alpha);
            jacobiMaterial.SetFloat("_uBeta", beta);
            jacobiMaterial.SetTexture("_uX", velTexture);
            jacobiMaterial.SetTexture("_uB", velTexture);
            Graphics.Blit(velTexture, swapTexture1, jacobiMaterial); // swapTexture1 = jacobi(velTexture, velTexture)
            Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1
        }

        // Difusión viscosa de la tinta        
        for(int i = 0; i < 30; i++)
        {
            jacobiMaterial.SetFloat("_uTexelSize", texelSize);
            jacobiMaterial.SetFloat("_uAlpha", alpha);
            jacobiMaterial.SetFloat("_uBeta", beta);
            jacobiMaterial.SetTexture("_uX", inkTexture);
            jacobiMaterial.SetTexture("_uB", inkTexture);
            Graphics.Blit(inkTexture, swapTexture1, jacobiMaterial); // swapTexture1 = jacobi(inkTexture, inkTexture)
            Graphics.Blit(swapTexture1, inkTexture); // inkTexture = swapTexture1
        }

        // Proyección de la Divergencia
        divergenceMaterial.SetFloat("_uTexelSize", texelSize);
        divergenceMaterial.SetTexture("_uW", velTexture);
        Graphics.Blit(velTexture, swapTexture1, divergenceMaterial); // swapTexture1 = divergence(velTexture)
        Graphics.Blit(swapTexture1, swapTexture2); // swapTexture2 = swapTexture1

        // Iteración de Jacobi para la presión
        alpha = -(texelSize * texelSize);
        beta = 4.0f;
        for(int i = 0; i < 60; i++)
        {
            jacobiMaterial.SetFloat("_uTexelSize", texelSize);
            jacobiMaterial.SetFloat("_uAlpha", alpha);
            jacobiMaterial.SetFloat("_uBeta", beta);
            jacobiMaterial.SetTexture("_uX", pressureTexture);
            jacobiMaterial.SetTexture("_uB", swapTexture2);
            Graphics.Blit(pressureTexture, swapTexture1, jacobiMaterial); // swapTexture1 = jacobi(pressureTexture, swapTexture1)
            Graphics.Blit(swapTexture1, pressureTexture); // pressureTexture = swapTexture1
        }

        // Resta del Gradiente
        gradientSubstractionMaterial.SetFloat("_uTexelSize", texelSize);
        gradientSubstractionMaterial.SetTexture("_uW", velTexture);
        gradientSubstractionMaterial.SetTexture("_uP", pressureTexture);
        Graphics.Blit(velTexture, swapTexture1, gradientSubstractionMaterial); // swapTexture1 = gradientSubstraction(velTexture, pressureTexture)
        Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1

        // Aplicación de las condiciones de contorno
        if(ns.boundaryConditions)
        {
            boundaryConditionsMaterial.SetFloat("_uTexelSize", texelSize);
            boundaryConditionsMaterial.SetFloat("_uBoundarySize", 1.0f );
            boundaryConditionsMaterial.SetTexture("_uC", velTexture);
            Graphics.Blit(velTexture, swapTexture1, boundaryConditionsMaterial); // swapTexture1 = boundaryConditions(velTexture)
            Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1

            boundaryConditionsMaterial.SetFloat("_uTexelSize", texelSize);
            boundaryConditionsMaterial.SetFloat("_uBoundarySize", 1.0f );
            boundaryConditionsMaterial.SetTexture("_uC", pressureTexture);
            Graphics.Blit(pressureTexture, swapTexture1, boundaryConditionsMaterial); // swapTexture1 = boundaryConditions(pressureTexture)
            Graphics.Blit(swapTexture1, pressureTexture); // pressureTexture = swapTexture1
        }

        // Dibujado final 
        renderMaterial.SetFloat("_uTexelSize", texelSize);
        if (rendVel)
        {
            renderMaterial.SetTexture("_uC", velTexture);
        }
        else
        {
            renderMaterial.SetTexture("_uC", inkTexture);
        }
        

        // swap renderVel if space is pressed
        if (Input.GetKeyDown(KeyCode.Space))
        {
            rendVel = !rendVel;
        }
}

    bool changeMaterial(ref Material material, Shader shader)
    {
        if (material == null || material.shader != shader)
        {
            material = new Material(shader);
            return true;
        }
        return false;
    }

    // Create a RenderTexture to store the simulation data required
    RenderTexture createRenderTexture(int resolution)
    {
        RenderTexture renderTexture = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGBFloat);
        renderTexture.filterMode = FilterMode.Bilinear;
        renderTexture.wrapMode = TextureWrapMode.Clamp;
        renderTexture.Create();
        return renderTexture;
    }
}
