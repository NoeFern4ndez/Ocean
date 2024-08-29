using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NavierStokes : MonoBehaviour
{
    public GameObject forceObject;
    public NS_Parameters ns;
    public Shader advection, boundaryConditions, divergence, forceApplication, gradientSubstraction, jacobi, render, genVorticity, vorticity;

    public Material renderMaterial;

    private RenderTexture velTexture, pressureTexture, inkTexture, vorticityTexture, swapTexture1, swapTexture2;
    private Material advectionMaterial, boundaryConditionsMaterial, divergenceMaterial, forceApplicationMaterial, gradientSubstractionMaterial, jacobiMaterial, genVorticityMaterial, vorticityMaterial;

    private Vector3 forceObject_oldPosition = Vector3.zero;

    private int rendVel = 0;

    private float texelSize;
    void Start()
    {
        texelSize = 1.0f / (ns.resolution * ns.simulationScale);

        // Initialize the RenderTextures
        velTexture = createRenderTexture(ns.resolution);
        pressureTexture = createRenderTexture(ns.resolution);
        inkTexture = createRenderTexture(ns.resolution);
        vorticityTexture = createRenderTexture(ns.resolution);
        swapTexture1 = createRenderTexture(ns.resolution);
        swapTexture2 = createRenderTexture(ns.resolution);

        ClearRenderTexture(velTexture);
        ClearRenderTexture(pressureTexture);
        ClearRenderTexture(inkTexture);
        ClearRenderTexture(vorticityTexture);
        ClearRenderTexture(swapTexture1);
        ClearRenderTexture(swapTexture2);

        // Create materials from shaders
        advectionMaterial = new Material(advection);
        boundaryConditionsMaterial = new Material(boundaryConditions);
        divergenceMaterial = new Material(divergence);
        forceApplicationMaterial = new Material(forceApplication);
        gradientSubstractionMaterial = new Material(gradientSubstraction);
        jacobiMaterial = new Material(jacobi);
        genVorticityMaterial = new Material(genVorticity);
        vorticityMaterial = new Material(vorticity);
    }

    void ClearRenderTexture(RenderTexture rt)
    {
        RenderTexture.active = rt;
        GL.Clear(true, true, Color.clear);
        RenderTexture.active = null;
    }


    void Update()
    {
        // Pasos de la simulación
        // Advección de la velocidad        
        advectionMaterial.SetFloat("_uTexelSize", texelSize);
        advectionMaterial.SetFloat("_uTimeStep", ns.timestep * Time.deltaTime);
        advectionMaterial.SetFloat("_uDissipation", ns.dissipation);
        advectionMaterial.SetTexture("_uV", velTexture);
        advectionMaterial.SetTexture("_uX", velTexture);
        Graphics.Blit(velTexture, swapTexture1, advectionMaterial); // swapTexture1 = advection(velTexture, velTexture)
        Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1
    
        // Advección de la tinta
        advectionMaterial.SetFloat("_uTexelSize", texelSize);
        advectionMaterial.SetFloat("_uTimeStep", ns.timestep * Time.deltaTime);
        advectionMaterial.SetFloat("_uDissipation", ns.inkDissipation);
        advectionMaterial.SetTexture("_uV", velTexture);
        advectionMaterial.SetTexture("_uX", inkTexture);
        Graphics.Blit(inkTexture, swapTexture1, advectionMaterial); // swapTexture1 = advection(velTexture, inkTexture)
        Graphics.Blit(swapTexture1, inkTexture); // inkTexture = swapTexture1

        // Difusión viscosa de la velocidad
        float alpha = (texelSize * texelSize) / (ns.timestep * Time.deltaTime * ns.velViscosity);
        float beta = alpha + 4.0f;
        jacobiMaterial.SetFloat("_uTexelSize", texelSize);
        jacobiMaterial.SetFloat("_uAlpha", alpha);
        jacobiMaterial.SetFloat("_uBeta", beta);
        jacobiMaterial.SetTexture("_uX", velTexture);
        jacobiMaterial.SetTexture("_uB", velTexture);
        for (int i = 0; i < ns.jacobiIterations; i++)
        {
            Graphics.Blit(velTexture, swapTexture1, jacobiMaterial); // swapTexture1 = jacobi(velTexture, velTexture)
            Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1
        }

        // Difusión viscosa de la tinta   
        alpha = (texelSize * texelSize) / (ns.timestep * ns.inkViscosity * Time.deltaTime);
        beta = alpha + 4.0f;
        jacobiMaterial.SetFloat("_uTexelSize", texelSize);
        jacobiMaterial.SetFloat("_uAlpha", alpha);
        jacobiMaterial.SetFloat("_uBeta", beta);
        jacobiMaterial.SetTexture("_uX", inkTexture);
        jacobiMaterial.SetTexture("_uB", inkTexture);     
        for(int i = 0; i < ns.jacobiIterations; i++)
        {
            Graphics.Blit(inkTexture, swapTexture1, jacobiMaterial); // swapTexture1 = jacobi(inkTexture, inkTexture)
            Graphics.Blit(swapTexture1, inkTexture); // inkTexture = swapTexture1
        }

        // Aplicación de fuerzas a la velocidad
        Vector3 Force = (forceObject_oldPosition - forceObject.transform.localPosition) / Time.deltaTime;
        Vector3 ParentScale = forceObject.transform.parent.localScale;
        Vector3 ForcePosition = new Vector3((-forceObject.transform.localPosition.x + 10 / ParentScale.x) / 20 * ParentScale.x, (-forceObject.transform.localPosition.z + 10 / ParentScale.z) / 20 * ParentScale.z, forceObject.transform.localPosition.y); 
        forceObject_oldPosition = forceObject.transform.localPosition;

        forceApplicationMaterial.SetFloat("_uTexelSize", texelSize);
        forceApplicationMaterial.SetTexture("_uC", velTexture);
        forceApplicationMaterial.SetFloat("_uTimestep", ns.timestep * Time.deltaTime);
        forceApplicationMaterial.SetVector("_uForce", new Vector3(Force.x, Force.z, 0.0f));
        forceApplicationMaterial.SetVector("_uForceLocation", ForcePosition);
        forceApplicationMaterial.SetFloat("_uRadius", ns.forceRadius * texelSize);
        Graphics.Blit(velTexture, swapTexture1, forceApplicationMaterial); // swapTexture1 = forceApplication(velTexture)
        Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1

        // Aplicación de fuerzas a la tinta
        forceApplicationMaterial.SetFloat("_uTexelSize", texelSize);
        forceApplicationMaterial.SetTexture("_uC", inkTexture);
        forceApplicationMaterial.SetFloat("_uTimestep", ns.timestep * Time.deltaTime);
        forceApplicationMaterial.SetVector("_uForce", new Vector3(ns.inkColor.r, ns.inkColor.g, ns.inkColor.b));
        forceApplicationMaterial.SetVector("_uForceLocation", ForcePosition);
        forceApplicationMaterial.SetFloat("_uRadius", ns.forceRadius * texelSize);
        Graphics.Blit(inkTexture, swapTexture1, forceApplicationMaterial); // swapTexture1 = forceApplication(inkTexture)
        Graphics.Blit(swapTexture1, inkTexture); // inkTexture = swapTexture1

        if(ns.applyVorticity)
        {
            // Generación de la voriticidad
            genVorticityMaterial.SetFloat("_uTexelSize", texelSize);
            genVorticityMaterial.SetTexture("_uW", velTexture);
            Graphics.Blit(velTexture, vorticityTexture, genVorticityMaterial); // vorticityTexture = genVorticity(velTexture)

            // Voriticidad  
            vorticityMaterial.SetFloat("_uTexelSize", texelSize);
            vorticityMaterial.SetFloat("_uVFactor", ns.vorticityFactor);
            vorticityMaterial.SetFloat("_uTimeStep", ns.timestep * Time.deltaTime);
            vorticityMaterial.SetTexture("_uV", velTexture);
            vorticityMaterial.SetTexture("_uVorticity", vorticityTexture);
            Graphics.Blit(velTexture, swapTexture1, vorticityMaterial); // swapTexture1 = vorticity(velTexture, vorticityTexture)
            Graphics.Blit(swapTexture1, velTexture); // velTexture = swapTexture1
        }

        // Proyección de la Divergencia
        divergenceMaterial.SetFloat("_uTexelSize", texelSize);
        divergenceMaterial.SetTexture("_uW", velTexture);
        Graphics.Blit(velTexture, swapTexture1, divergenceMaterial); // swapTexture1 = divergence(velTexture)

        // Iteración de Jacobi para la presión
        alpha = -(texelSize * texelSize);
        beta = alpha + 4.0f;
        jacobiMaterial.SetFloat("_uTexelSize", texelSize);
        jacobiMaterial.SetFloat("_uAlpha", alpha);
        jacobiMaterial.SetFloat("_uBeta", beta);
        jacobiMaterial.SetTexture("_uX", pressureTexture);
        jacobiMaterial.SetTexture("_uB", swapTexture1);

        for(int i = 0; i < ns.jacobiIterations * 2; i++)
        {
            Graphics.Blit(pressureTexture, swapTexture2, jacobiMaterial); // swapTexture2 = jacobi(pressureTexture, swapTexture1)
            Graphics.Blit(swapTexture2, pressureTexture); // pressureTexture = swapTexture2
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
        if (rendVel == 0)
        {
            renderMaterial.SetTexture("_uC", inkTexture);
        }
        else
        {
            renderMaterial.SetTexture("_uC", velTexture);
        }

        // swap renderVel if space is pressed
        if (Input.GetKeyDown(KeyCode.Space))
        {
            rendVel += 1;
            rendVel = rendVel % 2;
        }

        Graphics.Blit(null, null, renderMaterial);
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
