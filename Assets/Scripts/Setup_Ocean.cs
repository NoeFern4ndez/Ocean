using System;
using System.Collections;
using System.Collections.Generic;
using static System.Runtime.InteropServices.Marshal;
using UnityEngine;
using UnityEngine.Rendering;

public class Setup_Ocean : MonoBehaviour
{
    public Material ocean_material;
    public Shader ocean_shader; 

    public int subWaves = 32;

    private struct wave 
    {
        public float frequency;
        public float amplitude;
        public float phase;
        public Vector2 direction;
    }

    private wave[] waves = new wave[4 * 32];

    // Start is called before the first frame update
    void Start()
    {
        waves = new wave[4 * subWaves];
        for(int i = 0; i < 4 * subWaves; i++)
        {
            waves[i].frequency = 0;
            waves[i].amplitude = 0;
            waves[i].phase = 0;
            waves[i].direction = new Vector2(0, 0);
        }
        generate_waves();
    }

    // Update is called once per frame
    void Update()
    {
        //pass_waves_to_shader();
    }

    void generate_waves()
    {
        for(int i = 0; i < 4; i++)
        {
            waves[i].frequency = ocean_material.GetFloat("_waveFrequency" + i);
            waves[i].amplitude = ocean_material.GetFloat("_WaveAmplitude" + i);
            waves[i].phase = ocean_material.GetFloat("_wavePhase" + i);
            waves[i].direction = ocean_material.GetVector("_WaveDirection" + i);

            float freq_mult = 1;
            float amp_mult = 1;

            for(int j = 4; j < subWaves + 4; i++)
            {
                waves[j].frequency = waves[i].frequency * freq_mult;
                waves[j].amplitude = waves[i].amplitude * amp_mult;
                waves[j].phase = waves[i].phase;
                waves[j].direction = new Vector2(UnityEngine.Random.Range(-1.0f, 1.0f), UnityEngine.Random.Range(-1.0f, 1.0f));

                freq_mult *= 1.18f;
                amp_mult *= 0.82f;
            }
        }

        for(int i = 0; i < 4 * subWaves; i++)
        {
            ocean_material.SetFloat("_waveFrequency" + i, waves[i].frequency);
            ocean_material.SetFloat("_WaveAmplitude" + i, waves[i].amplitude);
            ocean_material.SetFloat("_wavePhase" + i, waves[i].phase);
            ocean_material.SetVector("_WaveDirection" + i, waves[i].direction);
        }
    }

    void pass_waves_to_shader()
    {
        for(int i = 0; i < 4 * subWaves; i++)
        {
            ocean_material.SetFloat("_waveFrequency" + i, waves[i].frequency);
            ocean_material.SetFloat("_WaveAmplitude" + i, waves[i].amplitude);
            ocean_material.SetFloat("_wavePhase" + i, waves[i].phase);
            ocean_material.SetVector("_WaveDirection" + i, waves[i].direction);
        }
    }
}
