using UnityEngine;

[CreateAssetMenu(fileName = "NS_Parameters", menuName = "NavierStokes/Parameters", order = 1)]
public class NS_Parameters : ScriptableObject
{
    public float timestep = 0.001f;
    public int resolution = 256;
    public int jacobiIterations = 40;
    public float simulationScale = 1.0f;
    public float dissipation = 0.998f;
    public float inkDissipation = 0.99f;
    public float velViscosity = 1.0f;
    public float inkViscosity = 1.0f;
    public Color inkColor = new Color(1.0f, 1.0f, 1.0f);
    public bool applyVorticity = false;
    public bool boundaryConditions = false;
    public float vorticityFactor = 0.2f;
    public float forceRadius = 1.0f;
}
