using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ConfigPlane : MonoBehaviour
{
    public int size = 10;
    public int resolution = 10;

    [ContextMenu("Modify Plane")]
    void ModifyPlane()
    {
        // Acceder al MeshFilter del objeto
        MeshFilter meshFilter = GetComponent<MeshFilter>();
        if (meshFilter == null)
        {
            Debug.LogError("El objeto no tiene un MeshFilter.");
            return;
        }

        // Crear un nuevo mesh si no existe, o usar el existente
        Mesh mesh = meshFilter.sharedMesh;
        if (mesh == null)
        {
            mesh = new Mesh();
            meshFilter.sharedMesh = mesh;
        }
        else
        {
            mesh.Clear();
        }

        // Crear los arrays para los vértices y los triángulos
        Vector3[] vertices = new Vector3[(resolution + 1) * (resolution + 1)];
        int[] triangles = new int[resolution * resolution * 6];

        // Ajustar para que el plano se mantenga centrado en su posición actual
        float halfSize = size / 2f;

        // Crear los vértices centrados
        for (int i = 0, y = 0; y <= resolution; y++)
        {
            for (int x = 0; x <= resolution; x++, i++)
            {
                float xPos = ((float)x / resolution * size) - halfSize;
                float zPos = ((float)y / resolution * size) - halfSize;
                vertices[i] = new Vector3(xPos, 0, zPos);
            }
        }

        // Crear los triángulos
        for (int ti = 0, vi = 0, y = 0; y < resolution; y++, vi++)
        {
            for (int x = 0; x < resolution; x++, ti += 6, vi++)
            {
                triangles[ti] = vi;
                triangles[ti + 1] = vi + resolution + 1;
                triangles[ti + 2] = vi + 1;
                triangles[ti + 3] = vi + 1;
                triangles[ti + 4] = vi + resolution + 1;
                triangles[ti + 5] = vi + resolution + 2;
            }
        }

        // Asignar los vértices y triángulos al mesh
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();

        // Asignar el mesh al MeshFilter
        meshFilter.sharedMesh = mesh;
    }
}
