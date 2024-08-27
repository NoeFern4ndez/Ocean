using UnityEngine;
using UnityEditor;

public class NS_Interface : EditorWindow
{
    private NS_Parameters parameters;
    private SerializedObject serializedParameters;

    [MenuItem("Window/Navier Stokes Parameters")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(NS_Interface));
    }

    void OnGUI()
    {
        parameters = (NS_Parameters)EditorGUILayout.ObjectField("Parameters", parameters, typeof(NS_Parameters), false);

        if (parameters != null)
        {
            if (serializedParameters == null || serializedParameters.targetObject != parameters)
            {
                serializedParameters = new SerializedObject(parameters);
            }

            serializedParameters.Update();

            EditorGUILayout.PropertyField(serializedParameters.FindProperty("timestep"));
            EditorGUILayout.PropertyField(serializedParameters.FindProperty("resolution"));
            EditorGUILayout.Slider(serializedParameters.FindProperty("dissipation"), 0.0f, 1.0f);
            EditorGUILayout.Slider(serializedParameters.FindProperty("inkDissipation"), 0.0f, 1.0f);
            EditorGUILayout.PropertyField(serializedParameters.FindProperty("inkColor"));
            EditorGUILayout.PropertyField(serializedParameters.FindProperty("forceRadius"));
            EditorGUILayout.PropertyField(serializedParameters.FindProperty("boundaryConditions"));

            SerializedProperty vorticityGroup = serializedParameters.FindProperty("applyVorticity");
            vorticityGroup.boolValue = EditorGUILayout.BeginToggleGroup("Vorticity", vorticityGroup.boolValue);
            if (vorticityGroup.boolValue)
            {
                EditorGUILayout.PropertyField(serializedParameters.FindProperty("vorticityFactor"));
            }
            EditorGUILayout.EndToggleGroup();

            serializedParameters.ApplyModifiedProperties();
        }
    }
}
