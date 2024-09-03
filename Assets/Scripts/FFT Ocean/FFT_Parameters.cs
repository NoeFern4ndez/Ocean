using UnityEngine;

[CreateAssetMenu(fileName = "FFT_Parameters", menuName = "FFT_Ocean/Parameters", order = 1)]
public class FFT_Parameters : ScriptableObject
{
    [System.Serializable]
    public class JONSWAP
    {
        public float A; // Amplitude
        public float B; // Spectral width
        public float g; // Gravity
        public float sigma; // Wind speed
        public float omegaPeak; // Peak frequency
        public float alpha; // Peak sharpness
        public float gamma; // Peak spreading
    }

    public JONSWAP jonswap1 = new JONSWAP();
    public JONSWAP jonswap2 = new JONSWAP();
    public JONSWAP jonswap3 = new JONSWAP();
    public JONSWAP jonswap4 = new JONSWAP();

    public int resolution = 256; // Resolution of the JONSWAP spectrum texture / Ocean textures
}
