using UnityEngine;

[CreateAssetMenu(fileName = "FFT_Parameters", menuName = "FFT_Ocean/Parameters", order = 1)]
public class FFT_Parameters : ScriptableObject
{
    [System.Serializable]
 
    public class JONSWAP
    {
        public float windSpeed = 10.0f;
        public float windDirection = 0.0f;  
        public float windFetch = 1000.0f;
        public float oceanDepth = 1000.0f;
        
    }

    public JONSWAP jonswap1 = new JONSWAP();
    public JONSWAP jonswap2 = new JONSWAP();
    public JONSWAP jonswap3 = new JONSWAP();
    public JONSWAP jonswap4 = new JONSWAP();

    public int resolution = 256; // Resolution of the JONSWAP spectrum texture / Ocean textures
}
