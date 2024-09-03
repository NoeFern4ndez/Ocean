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
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("A"), new GUIContent("Amplitude"));
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("B"), new GUIContent("Spectral width"));
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("sigma"), new GUIContent("Wind speed"));
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("omegaPeak"), new GUIContent("Peak frequency"));
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("alpha"), new GUIContent("Peak sharpness"));
            EditorGUILayout.PropertyField(jonswap1.FindPropertyRelative("gamma"), new GUIContent("Peak spreading"));

            EditorGUILayout.LabelField("2nd JONSWAP Parameters", EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("A"), new GUIContent("Amplitude"));
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("B"), new GUIContent("Spectral width"));
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("sigma"), new GUIContent("Wind speed"));
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("omegaPeak"), new GUIContent("Peak frequency"));
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("alpha"), new GUIContent("Peak sharpness"));
            EditorGUILayout.PropertyField(jonswap2.FindPropertyRelative("gamma"), new GUIContent("Peak spreading"));

            EditorGUILayout.LabelField("3rd JONSWAP Parameters", EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("A"), new GUIContent("Amplitude"));
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("B"), new GUIContent("Spectral width"));
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("sigma"), new GUIContent("Wind speed"));
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("omegaPeak"), new GUIContent("Peak frequency"));
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("alpha"), new GUIContent("Peak sharpness"));
            EditorGUILayout.PropertyField(jonswap3.FindPropertyRelative("gamma"), new GUIContent("Peak spreading"));

            EditorGUILayout.LabelField("4th JONSWAP Parameters", EditorStyles.boldLabel);
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("A"), new GUIContent("Amplitude"));
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("B"), new GUIContent("Spectral width"));
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("sigma"), new GUIContent("Wind speed"));
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("omegaPeak"), new GUIContent("Peak frequency"));
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("alpha"), new GUIContent("Peak sharpness"));
            EditorGUILayout.PropertyField(jonswap4.FindPropertyRelative("gamma"), new GUIContent("Peak spreading"));

            serializedParameters.ApplyModifiedProperties();
        }
    }
}
