using UnityEngine;
using UnityEditor;

public class FFT_Interface : EditorWindow
{
    private FFT_Parameters parameters;
    private SerializedObject serializedParameters;

    [MenuItem("Window/FFT Ocean Parameters")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(FFT_Interface));
    }

    void OnGUI()
    {
        parameters = (FFT_Parameters)EditorGUILayout.ObjectField("Parameters", parameters, typeof(FFT_Parameters), false);

        if (parameters != null)
        {
            if (serializedParameters == null || serializedParameters.targetObject != parameters)
            {
                serializedParameters = new SerializedObject(parameters);
            }

            serializedParameters.Update();

            EditorGUILayout.LabelField("General Settings", EditorStyles.boldLabel);

            EditorGUILayout.PropertyField(serializedParameters.FindProperty("resolution"));

            EditorGUILayout.LabelField("4 Frequency Bands", EditorStyles.boldLabel);

            // JONSWAP Parameters
            SerializedProperty jonswap1 = serializedParameters.FindProperty("jonswap1");
            SerializedProperty jonswap2 = serializedParameters.FindProperty("jonswap2");
            SerializedProperty jonswap3 = serializedParameters.FindProperty("jonswap3");
            SerializedProperty jonswap4 = serializedParameters.FindProperty("jonswap4");


            EditorGUILayout.LabelField("1st JONSWAP Parameters", EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("windSpeed"), new GUIContent("Wind Speed"));
            EditorGUILayout.Slider(jonswap1.FindPropertyRelative("windDirection"), 0.0f, 360.0f, new GUIContent("Wind Direction"));
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("windFetch"), new GUIContent("Wind Fetch"));
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("oceanDepth"), new GUIContent("Ocean Depth"));

            EditorGUILayout.LabelField("2nd JONSWAP Parameters", EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("windSpeed"), new GUIContent("Wind Speed"));
            EditorGUILayout.Slider(jonswap2.FindPropertyRelative("windDirection"), 0.0f, 360.0f, new GUIContent("Wind Direction"));
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("windFetch"), new GUIContent("Wind Fetch"));
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("oceanDepth"), new GUIContent("Ocean Depth"));

            EditorGUILayout.LabelField("3rd JONSWAP Parameters", EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("windSpeed"), new GUIContent("Wind Speed"));
            EditorGUILayout.Slider(jonswap3.FindPropertyRelative("windDirection"), 0.0f, 360.0f, new GUIContent("Wind Direction"));
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("windFetch"), new GUIContent("Wind Fetch"));
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("oceanDepth"), new GUIContent("Ocean Depth"));

            EditorGUILayout.LabelField("4th JONSWAP Parameters", EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("windSpeed"), new GUIContent("Wind Speed"));
            EditorGUILayout.Slider(jonswap4.FindPropertyRelative("windDirection"), 0.0f, 360.0f, new GUIContent("Wind Direction"));
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("windFetch"), new GUIContent("Wind Fetch"));
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("oceanDepth"), new GUIContent("Ocean Depth"));

            serializedParameters.ApplyModifiedProperties();
        }
    }
}
