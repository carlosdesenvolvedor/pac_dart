// Stub de COMPILAÇÃO do UnityEngine (Unity 6) para validar exercícios do PAC·C#.
// Só assinaturas (corpos vazios/valores padrão) — nada aqui roda um jogo.
// Regra: só entra membro que existe de verdade na Scripting API do Unity 6
// (docs.unity3d.com/6000.0/Documentation/ScriptReference), com a mesma assinatura.
// APIs renomeadas no Unity 6 ficam [Obsolete] (o validador trata aviso como erro):
// Rigidbody.velocity → linearVelocity, drag → linearDamping, angularDrag → angularDamping,
// Object.FindObjectOfType → FindFirstObjectByType / FindAnyObjectByType.
#pragma warning disable CS0067, CS0649, CS0414, CS1998, CS0660, CS0661
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Threading;

namespace UnityEngine
{
    public enum FindObjectsSortMode { None, InstanceID }
    public enum FindObjectsInactive { Exclude, Include }
    public enum Space { World, Self }
    public enum SendMessageOptions { RequireReceiver, DontRequireReceiver }
    public enum PrimitiveType { Sphere, Capsule, Cylinder, Cube, Plane, Quad }

    public class Object
    {
        public string name { get; set; }
        public HideFlags hideFlags { get; set; }
        [Obsolete("GetInstanceID is deprecated (Unity 6.4+). Use GetEntityId instead.")]
        public int GetInstanceID() => 0;
        public override string ToString() => name;
        public static implicit operator bool(Object exists) => !ReferenceEquals(exists, null);
        public static bool operator ==(Object x, Object y) => ReferenceEquals(x, y);
        public static bool operator !=(Object x, Object y) => !ReferenceEquals(x, y);
        public override bool Equals(object other) => ReferenceEquals(this, other);
        public override int GetHashCode() => 0;

        public static void Destroy(Object obj) { }
        public static void Destroy(Object obj, float t) { }
        public static Object Instantiate(Object original, Transform parent, bool instantiateInWorldSpace) => original;
        public static void DestroyImmediate(Object obj) { }
        public static void DontDestroyOnLoad(Object target) { }

        public static Object Instantiate(Object original) => original;
        public static Object Instantiate(Object original, Transform parent) => original;
        public static Object Instantiate(Object original, Vector3 position, Quaternion rotation) => original;
        public static Object Instantiate(Object original, Vector3 position, Quaternion rotation, Transform parent) => original;
        public static T Instantiate<T>(T original) where T : Object => original;
        public static T Instantiate<T>(T original, Transform parent) where T : Object => original;
        public static T Instantiate<T>(T original, Transform parent, bool worldPositionStays) where T : Object => original;
        public static T Instantiate<T>(T original, Vector3 position, Quaternion rotation) where T : Object => original;
        public static T Instantiate<T>(T original, Vector3 position, Quaternion rotation, Transform parent) where T : Object => original;

        [Obsolete("Object.FindObjectOfType has been deprecated. Use Object.FindAnyObjectByType instead.")]
        public static T FindObjectOfType<T>() where T : Object => default;
        [Obsolete("Object.FindObjectsOfType has been deprecated. Use Object.FindObjectsByType instead which lets you decide whether you need the results sorted or not.")]
        public static T[] FindObjectsOfType<T>() where T : Object => Array.Empty<T>();
        [Obsolete("FindFirstObjectByType is deprecated (Unity 6.4+). Use FindAnyObjectByType instead.")]
        public static T FindFirstObjectByType<T>() where T : Object => default;
        public static T FindAnyObjectByType<T>() where T : Object => default;
        public static T FindAnyObjectByType<T>(FindObjectsInactive findObjectsInactive) where T : Object => default;
        public static T[] FindObjectsByType<T>(FindObjectsSortMode sortMode) where T : Object => Array.Empty<T>();
        public static T[] FindObjectsByType<T>(FindObjectsInactive findObjectsInactive, FindObjectsSortMode sortMode) where T : Object => Array.Empty<T>();
    }

    [Flags] public enum HideFlags { None = 0, HideInHierarchy = 1, HideInInspector = 2, DontSave = 52, HideAndDontSave = 61 }

    public class Component : Object
    {
        public GameObject gameObject => null;
        public Transform transform => null;
        public string tag { get; set; }
        public T GetComponent<T>() => default;
        public Component GetComponent(Type type) => null;
        public bool TryGetComponent<T>(out T component) { component = default; return false; }
        public T GetComponentInChildren<T>() => default;
        public T GetComponentInChildren<T>(bool includeInactive) => default;
        public T GetComponentInParent<T>() => default;
        public T[] GetComponents<T>() => Array.Empty<T>();
        public T[] GetComponentsInChildren<T>() => Array.Empty<T>();
        public T[] GetComponentsInChildren<T>(bool includeInactive) => Array.Empty<T>();
        public bool CompareTag(string tag) => false;
        public void SendMessage(string methodName) { }
        public void SendMessage(string methodName, object value) { }
        public void SendMessage(string methodName, object value, SendMessageOptions options) { }
        public void BroadcastMessage(string methodName) { }
    }

    public class Behaviour : Component
    {
        public bool enabled { get; set; }
        public bool isActiveAndEnabled => false;
    }

    public class MonoBehaviour : Behaviour
    {
        public CancellationToken destroyCancellationToken => default;
        public bool didAwake => false;
        public bool didStart => false;
        public bool useGUILayout { get; set; }
        public Coroutine StartCoroutine(IEnumerator routine) => null;
        public Coroutine StartCoroutine(string methodName) => null;
        public Coroutine StartCoroutine(string methodName, object value) => null;
        public void StopCoroutine(IEnumerator routine) { }
        public void StopCoroutine(Coroutine routine) { }
        public void StopCoroutine(string methodName) { }
        public void StopAllCoroutines() { }
        public void Invoke(string methodName, float time) { }
        public void InvokeRepeating(string methodName, float time, float repeatRate) { }
        public void CancelInvoke() { }
        public void CancelInvoke(string methodName) { }
        public bool IsInvoking(string methodName) => false;
        public static void print(object message) { }
    }

    public class ScriptableObject : Object
    {
        public static T CreateInstance<T>() where T : ScriptableObject => default;
        public static ScriptableObject CreateInstance(Type type) => null;
    }

    public sealed class GameObject : Object
    {
        public GameObject() { }
        public GameObject(string name) { }
        public GameObject(string name, params Type[] components) { }
        public Transform transform => null;
        public GameObject gameObject => this;
        public bool activeSelf => false;
        public bool activeInHierarchy => false;
        public bool isStatic { get; set; }
        public int layer { get; set; }
        public string tag { get; set; }
        public void SetActive(bool value) { }
        public bool CompareTag(string tag) => false;
        public T GetComponent<T>() => default;
        public Component GetComponent(Type type) => null;
        public bool TryGetComponent<T>(out T component) { component = default; return false; }
        public T GetComponentInChildren<T>() => default;
        public T GetComponentInParent<T>() => default;
        public T[] GetComponents<T>() => Array.Empty<T>();
        public T[] GetComponentsInChildren<T>() => Array.Empty<T>();
        public T AddComponent<T>() where T : Component => default;
        public Component AddComponent(Type componentType) => null;
        public void SendMessage(string methodName) { }
        public void SendMessage(string methodName, object value) { }
        public static GameObject Find(string name) => null;
        public static GameObject FindWithTag(string tag) => null;
        public static GameObject FindGameObjectWithTag(string tag) => null;
        public static GameObject[] FindGameObjectsWithTag(string tag) => Array.Empty<GameObject>();
        public static GameObject CreatePrimitive(PrimitiveType type) => null;
    }

    public class Transform : Component, IEnumerable
    {
        public Vector3 position { get; set; }
        public Vector3 localPosition { get; set; }
        public Quaternion rotation { get; set; }
        public Quaternion localRotation { get; set; }
        public Vector3 eulerAngles { get; set; }
        public Vector3 localEulerAngles { get; set; }
        public Vector3 localScale { get; set; }
        public Vector3 lossyScale => default;
        public Vector3 forward { get; set; }
        public Vector3 right { get; set; }
        public Vector3 up { get; set; }
        public Transform parent { get; set; }
        public Transform root => null;
        public int childCount => 0;
        public Transform GetChild(int index) => null;
        public int GetSiblingIndex() => 0;
        public void SetSiblingIndex(int index) { }
        public void SetParent(Transform parent) { }
        public void SetParent(Transform parent, bool worldPositionStays) { }
        public void SetPositionAndRotation(Vector3 position, Quaternion rotation) { }
        public void Translate(Vector3 translation) { }
        public void Translate(Vector3 translation, Space relativeTo) { }
        public void Translate(float x, float y, float z) { }
        public void Translate(float x, float y, float z, Space relativeTo) { }
        public void Rotate(Vector3 eulers) { }
        public void Rotate(Vector3 eulers, Space relativeTo) { }
        public void Rotate(float xAngle, float yAngle, float zAngle) { }
        public void Rotate(float xAngle, float yAngle, float zAngle, Space relativeTo) { }
        public void Rotate(Vector3 axis, float angle) { }
        public void Rotate(Vector3 axis, float angle, Space relativeTo) { }
        public void RotateAround(Vector3 point, Vector3 axis, float angle) { }
        public void LookAt(Transform target) { }
        public void LookAt(Transform target, Vector3 worldUp) { }
        public void LookAt(Vector3 worldPosition) { }
        public void LookAt(Vector3 worldPosition, Vector3 worldUp) { }
        public Vector3 TransformPoint(Vector3 position) => position;
        public Vector3 InverseTransformPoint(Vector3 position) => position;
        public Vector3 TransformDirection(Vector3 direction) => direction;
        public Vector3 InverseTransformDirection(Vector3 direction) => direction;
        public Transform Find(string n) => null;
        public void DetachChildren() { }
        public bool IsChildOf(Transform parent) => false;
        public IEnumerator GetEnumerator() { yield break; }
    }

    public class RectTransform : Transform
    {
        public Vector2 anchoredPosition { get; set; }
        public Vector2 sizeDelta { get; set; }
        public Vector2 anchorMin { get; set; }
        public Vector2 anchorMax { get; set; }
        public Vector2 pivot { get; set; }
    }

    public struct Vector2 : IEquatable<Vector2>
    {
        public float x;
        public float y;
        public Vector2(float x, float y) { this.x = x; this.y = y; }
        public float this[int index] { get => index == 0 ? x : y; set { if (index == 0) x = value; else y = value; } }
        public static Vector2 zero => new Vector2(0, 0);
        public static Vector2 one => new Vector2(1, 1);
        public static Vector2 up => new Vector2(0, 1);
        public static Vector2 down => new Vector2(0, -1);
        public static Vector2 left => new Vector2(-1, 0);
        public static Vector2 right => new Vector2(1, 0);
        public float magnitude => (float)Math.Sqrt(x * x + y * y);
        public float sqrMagnitude => x * x + y * y;
        public Vector2 normalized => magnitude > 1e-5f ? this / magnitude : zero;
        public void Normalize() { this = normalized; }
        public void Set(float newX, float newY) { x = newX; y = newY; }
        public static float Distance(Vector2 a, Vector2 b) => (a - b).magnitude;
        public static float Dot(Vector2 lhs, Vector2 rhs) => lhs.x * rhs.x + lhs.y * rhs.y;
        public static float Angle(Vector2 from, Vector2 to) => 0f;
        public static float SignedAngle(Vector2 from, Vector2 to) => 0f;
        public static Vector2 Lerp(Vector2 a, Vector2 b, float t) => a + (b - a) * Math.Clamp(t, 0f, 1f);
        public static Vector2 LerpUnclamped(Vector2 a, Vector2 b, float t) => a + (b - a) * t;
        public static Vector2 MoveTowards(Vector2 current, Vector2 target, float maxDistanceDelta) => target;
        public static Vector2 ClampMagnitude(Vector2 vector, float maxLength) => vector;
        public static Vector2 Perpendicular(Vector2 inDirection) => new Vector2(-inDirection.y, inDirection.x);
        public static Vector2 Reflect(Vector2 inDirection, Vector2 inNormal) => inDirection;
        public static Vector2 Scale(Vector2 a, Vector2 b) => new Vector2(a.x * b.x, a.y * b.y);
        public static Vector2 Min(Vector2 lhs, Vector2 rhs) => lhs;
        public static Vector2 Max(Vector2 lhs, Vector2 rhs) => lhs;
        public static Vector2 operator +(Vector2 a, Vector2 b) => new Vector2(a.x + b.x, a.y + b.y);
        public static Vector2 operator -(Vector2 a, Vector2 b) => new Vector2(a.x - b.x, a.y - b.y);
        public static Vector2 operator -(Vector2 a) => new Vector2(-a.x, -a.y);
        public static Vector2 operator *(Vector2 a, float d) => new Vector2(a.x * d, a.y * d);
        public static Vector2 operator *(float d, Vector2 a) => new Vector2(a.x * d, a.y * d);
        public static Vector2 operator *(Vector2 a, Vector2 b) => new Vector2(a.x * b.x, a.y * b.y);
        public static Vector2 operator /(Vector2 a, float d) => new Vector2(a.x / d, a.y / d);
        public static bool operator ==(Vector2 lhs, Vector2 rhs) => (lhs - rhs).sqrMagnitude < 1e-10f;
        public static bool operator !=(Vector2 lhs, Vector2 rhs) => !(lhs == rhs);
        public static implicit operator Vector2(Vector3 v) => new Vector2(v.x, v.y);
        public static implicit operator Vector3(Vector2 v) => new Vector3(v.x, v.y, 0);
        public bool Equals(Vector2 other) => x == other.x && y == other.y;
        public override bool Equals(object other) => other is Vector2 v && Equals(v);
        public override int GetHashCode() => 0;
        public override string ToString() => $"({x:F2}, {y:F2})";
    }

    public struct Vector3 : IEquatable<Vector3>
    {
        public float x;
        public float y;
        public float z;
        public Vector3(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
        public Vector3(float x, float y) { this.x = x; this.y = y; z = 0; }
        public float this[int index] { get => index == 0 ? x : index == 1 ? y : z; set { } }
        public static Vector3 zero => new Vector3(0, 0, 0);
        public static Vector3 one => new Vector3(1, 1, 1);
        public static Vector3 up => new Vector3(0, 1, 0);
        public static Vector3 down => new Vector3(0, -1, 0);
        public static Vector3 left => new Vector3(-1, 0, 0);
        public static Vector3 right => new Vector3(1, 0, 0);
        public static Vector3 forward => new Vector3(0, 0, 1);
        public static Vector3 back => new Vector3(0, 0, -1);
        public static Vector3 positiveInfinity => new Vector3(float.PositiveInfinity, float.PositiveInfinity, float.PositiveInfinity);
        public float magnitude => (float)Math.Sqrt(x * x + y * y + z * z);
        public float sqrMagnitude => x * x + y * y + z * z;
        public Vector3 normalized => magnitude > 1e-5f ? this / magnitude : zero;
        public void Normalize() { this = normalized; }
        public void Set(float newX, float newY, float newZ) { x = newX; y = newY; z = newZ; }
        public static float Distance(Vector3 a, Vector3 b) => (a - b).magnitude;
        public static float Dot(Vector3 lhs, Vector3 rhs) => lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z;
        public static Vector3 Cross(Vector3 lhs, Vector3 rhs) => zero;
        public static float Angle(Vector3 from, Vector3 to) => 0f;
        public static float SignedAngle(Vector3 from, Vector3 to, Vector3 axis) => 0f;
        public static Vector3 Lerp(Vector3 a, Vector3 b, float t) => a + (b - a) * Math.Clamp(t, 0f, 1f);
        public static Vector3 LerpUnclamped(Vector3 a, Vector3 b, float t) => a + (b - a) * t;
        public static Vector3 Slerp(Vector3 a, Vector3 b, float t) => a;
        public static Vector3 MoveTowards(Vector3 current, Vector3 target, float maxDistanceDelta) => target;
        public static Vector3 RotateTowards(Vector3 current, Vector3 target, float maxRadiansDelta, float maxMagnitudeDelta) => target;
        public static Vector3 SmoothDamp(Vector3 current, Vector3 target, ref Vector3 currentVelocity, float smoothTime) => target;
        public static Vector3 SmoothDamp(Vector3 current, Vector3 target, ref Vector3 currentVelocity, float smoothTime, float maxSpeed) => target;
        public static Vector3 ClampMagnitude(Vector3 vector, float maxLength) => vector;
        public static Vector3 Project(Vector3 vector, Vector3 onNormal) => vector;
        public static Vector3 ProjectOnPlane(Vector3 vector, Vector3 planeNormal) => vector;
        public static Vector3 Reflect(Vector3 inDirection, Vector3 inNormal) => inDirection;
        public static Vector3 Scale(Vector3 a, Vector3 b) => new Vector3(a.x * b.x, a.y * b.y, a.z * b.z);
        public static Vector3 Min(Vector3 lhs, Vector3 rhs) => lhs;
        public static Vector3 Max(Vector3 lhs, Vector3 rhs) => lhs;
        public static Vector3 operator +(Vector3 a, Vector3 b) => new Vector3(a.x + b.x, a.y + b.y, a.z + b.z);
        public static Vector3 operator -(Vector3 a, Vector3 b) => new Vector3(a.x - b.x, a.y - b.y, a.z - b.z);
        public static Vector3 operator -(Vector3 a) => new Vector3(-a.x, -a.y, -a.z);
        public static Vector3 operator *(Vector3 a, float d) => new Vector3(a.x * d, a.y * d, a.z * d);
        public static Vector3 operator *(float d, Vector3 a) => new Vector3(a.x * d, a.y * d, a.z * d);
        public static Vector3 operator /(Vector3 a, float d) => new Vector3(a.x / d, a.y / d, a.z / d);
        public static bool operator ==(Vector3 lhs, Vector3 rhs) => (lhs - rhs).sqrMagnitude < 1e-10f;
        public static bool operator !=(Vector3 lhs, Vector3 rhs) => !(lhs == rhs);
        public bool Equals(Vector3 other) => x == other.x && y == other.y && z == other.z;
        public override bool Equals(object other) => other is Vector3 v && Equals(v);
        public override int GetHashCode() => 0;
        public override string ToString() => $"({x:F2}, {y:F2}, {z:F2})";
    }

    public struct Vector2Int : IEquatable<Vector2Int>
    {
        public int x { get; set; }
        public int y { get; set; }
        public Vector2Int(int x, int y) { this.x = x; this.y = y; }
        public static Vector2Int zero => new Vector2Int(0, 0);
        public static Vector2Int one => new Vector2Int(1, 1);
        public static Vector2Int up => new Vector2Int(0, 1);
        public static Vector2Int down => new Vector2Int(0, -1);
        public static Vector2Int left => new Vector2Int(-1, 0);
        public static Vector2Int right => new Vector2Int(1, 0);
        public float magnitude => (float)Math.Sqrt(x * x + y * y);
        public int sqrMagnitude => x * x + y * y;
        public static float Distance(Vector2Int a, Vector2Int b) => (a - b).magnitude;
        public static Vector2Int operator +(Vector2Int a, Vector2Int b) => new Vector2Int(a.x + b.x, a.y + b.y);
        public static Vector2Int operator -(Vector2Int a, Vector2Int b) => new Vector2Int(a.x - b.x, a.y - b.y);
        public static Vector2Int operator *(Vector2Int a, int b) => new Vector2Int(a.x * b, a.y * b);
        public static bool operator ==(Vector2Int a, Vector2Int b) => a.x == b.x && a.y == b.y;
        public static bool operator !=(Vector2Int a, Vector2Int b) => !(a == b);
        public static implicit operator Vector2(Vector2Int v) => new Vector2(v.x, v.y);
        public bool Equals(Vector2Int other) => this == other;
        public override bool Equals(object other) => other is Vector2Int v && this == v;
        public override int GetHashCode() => x * 31 + y;
        public override string ToString() => $"({x}, {y})";
    }

    public struct Vector3Int : IEquatable<Vector3Int>
    {
        public int x { get; set; }
        public int y { get; set; }
        public int z { get; set; }
        public Vector3Int(int x, int y, int z) { this.x = x; this.y = y; this.z = z; }
        public static Vector3Int zero => new Vector3Int(0, 0, 0);
        public static Vector3Int one => new Vector3Int(1, 1, 1);
        public static Vector3Int operator +(Vector3Int a, Vector3Int b) => new Vector3Int(a.x + b.x, a.y + b.y, a.z + b.z);
        public static Vector3Int operator -(Vector3Int a, Vector3Int b) => new Vector3Int(a.x - b.x, a.y - b.y, a.z - b.z);
        public static bool operator ==(Vector3Int a, Vector3Int b) => a.x == b.x && a.y == b.y && a.z == b.z;
        public static bool operator !=(Vector3Int a, Vector3Int b) => !(a == b);
        public static implicit operator Vector3(Vector3Int v) => new Vector3(v.x, v.y, v.z);
        public bool Equals(Vector3Int other) => this == other;
        public override bool Equals(object other) => other is Vector3Int v && this == v;
        public override int GetHashCode() => (x * 31 + y) * 31 + z;
        public override string ToString() => $"({x}, {y}, {z})";
    }

    public struct Vector4
    {
        public float x, y, z, w;
        public Vector4(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
    }

    public struct Quaternion : IEquatable<Quaternion>
    {
        public float x, y, z, w;
        public Quaternion(float x, float y, float z, float w) { this.x = x; this.y = y; this.z = z; this.w = w; }
        public static Quaternion identity => new Quaternion(0, 0, 0, 1);
        public Vector3 eulerAngles { get => default; set { } }
        public Quaternion normalized => this;
        public static Quaternion Euler(float x, float y, float z) => identity;
        public static Quaternion Euler(Vector3 euler) => identity;
        public static Quaternion AngleAxis(float angle, Vector3 axis) => identity;
        public static Quaternion LookRotation(Vector3 forward) => identity;
        public static Quaternion LookRotation(Vector3 forward, Vector3 upwards) => identity;
        public static Quaternion FromToRotation(Vector3 fromDirection, Vector3 toDirection) => identity;
        public static Quaternion Slerp(Quaternion a, Quaternion b, float t) => b;
        public static Quaternion Lerp(Quaternion a, Quaternion b, float t) => b;
        public static Quaternion RotateTowards(Quaternion from, Quaternion to, float maxDegreesDelta) => to;
        public static Quaternion Inverse(Quaternion rotation) => rotation;
        public static float Angle(Quaternion a, Quaternion b) => 0f;
        public static float Dot(Quaternion a, Quaternion b) => 1f;
        public static Quaternion operator *(Quaternion lhs, Quaternion rhs) => lhs;
        public static Vector3 operator *(Quaternion rotation, Vector3 point) => point;
        public static bool operator ==(Quaternion lhs, Quaternion rhs) => lhs.Equals(rhs);
        public static bool operator !=(Quaternion lhs, Quaternion rhs) => !lhs.Equals(rhs);
        public bool Equals(Quaternion other) => x == other.x && y == other.y && z == other.z && w == other.w;
        public override bool Equals(object other) => other is Quaternion q && Equals(q);
        public override int GetHashCode() => 0;
    }

    public struct Color : IEquatable<Color>
    {
        public float r, g, b, a;
        public Color(float r, float g, float b) { this.r = r; this.g = g; this.b = b; a = 1f; }
        public Color(float r, float g, float b, float a) { this.r = r; this.g = g; this.b = b; this.a = a; }
        public static Color red => new Color(1, 0, 0);
        public static Color green => new Color(0, 1, 0);
        public static Color blue => new Color(0, 0, 1);
        public static Color white => new Color(1, 1, 1);
        public static Color black => new Color(0, 0, 0);
        public static Color yellow => new Color(1, 0.92f, 0.016f);
        public static Color cyan => new Color(0, 1, 1);
        public static Color magenta => new Color(1, 0, 1);
        public static Color gray => new Color(0.5f, 0.5f, 0.5f);
        public static Color grey => gray;
        public static Color clear => new Color(0, 0, 0, 0);
        public static Color Lerp(Color a, Color b, float t) => b;
        public static Color operator *(Color a, float b) => a;
        public static Color operator +(Color a, Color b) => a;
        public static bool operator ==(Color lhs, Color rhs) => lhs.Equals(rhs);
        public static bool operator !=(Color lhs, Color rhs) => !lhs.Equals(rhs);
        public bool Equals(Color other) => r == other.r && g == other.g && b == other.b && a == other.a;
        public override bool Equals(object other) => other is Color c && Equals(c);
        public override int GetHashCode() => 0;
    }

    public struct Color32
    {
        public byte r, g, b, a;
        public Color32(byte r, byte g, byte b, byte a) { this.r = r; this.g = g; this.b = b; this.a = a; }
        public static implicit operator Color(Color32 c) => new Color(c.r / 255f, c.g / 255f, c.b / 255f, c.a / 255f);
    }

    public struct Rect
    {
        public float x { get; set; }
        public float y { get; set; }
        public float width { get; set; }
        public float height { get; set; }
        public Rect(float x, float y, float width, float height) { this.x = x; this.y = y; this.width = width; this.height = height; }
        public Vector2 center => default;
        public Vector2 position => default;
        public Vector2 size => default;
        public float xMin => x;
        public float xMax => x + width;
        public float yMin => y;
        public float yMax => y + height;
        public bool Contains(Vector2 point) => false;
        public bool Contains(Vector3 point) => false;
        public bool Overlaps(Rect other) => false;
    }

    public struct Bounds
    {
        public Bounds(Vector3 center, Vector3 size) { this.center = center; this.size = size; }
        public Vector3 center { get; set; }
        public Vector3 size { get; set; }
        public Vector3 extents { get; set; }
        public Vector3 min { get; set; }
        public Vector3 max { get; set; }
        public bool Contains(Vector3 point) => false;
        public bool Intersects(Bounds bounds) => false;
        public void Encapsulate(Vector3 point) { }
        public Vector3 ClosestPoint(Vector3 point) => point;
    }

    public struct Ray
    {
        public Ray(Vector3 origin, Vector3 direction) { this.origin = origin; this.direction = direction; }
        public Vector3 origin { get; set; }
        public Vector3 direction { get; set; }
        public Vector3 GetPoint(float distance) => origin + direction * distance;
    }

    public struct Ray2D
    {
        public Ray2D(Vector2 origin, Vector2 direction) { this.origin = origin; this.direction = direction; }
        public Vector2 origin { get; set; }
        public Vector2 direction { get; set; }
    }

    public struct LayerMask
    {
        public int value { get; set; }
        public static int GetMask(params string[] layerNames) => 0;
        public static int NameToLayer(string layerName) => 0;
        public static string LayerToName(int layer) => "";
        public static implicit operator int(LayerMask mask) => mask.value;
        public static implicit operator LayerMask(int intVal) => new LayerMask { value = intVal };
    }

    public static class Time
    {
        public static float deltaTime => 0.016f;
        public static float fixedDeltaTime { get; set; } = 0.02f;
        public static float time => 0f;
        public static double timeAsDouble => 0;
        public static float timeScale { get; set; } = 1f;
        public static float unscaledDeltaTime => 0.016f;
        public static float unscaledTime => 0f;
        public static float timeSinceLevelLoad => 0f;
        public static float realtimeSinceStartup => 0f;
        public static float fixedTime => 0f;
        public static float smoothDeltaTime => 0.016f;
        public static int frameCount => 0;
    }

    public enum KeyCode
    {
        None = 0, Backspace = 8, Tab = 9, Return = 13, Escape = 27, Space = 32,
        Alpha0 = 48, Alpha1, Alpha2, Alpha3, Alpha4, Alpha5, Alpha6, Alpha7, Alpha8, Alpha9,
        A = 97, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
        Delete = 127, UpArrow = 273, DownArrow = 274, RightArrow = 275, LeftArrow = 276,
        F1 = 282, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
        RightShift = 303, LeftShift = 304, RightControl = 305, LeftControl = 306, RightAlt = 307, LeftAlt = 308,
        Mouse0 = 323, Mouse1 = 324, Mouse2 = 325,
    }

    public enum TouchPhase { Began, Moved, Stationary, Ended, Canceled }

    public struct Touch
    {
        public int fingerId { get; set; }
        public Vector2 position { get; set; }
        public Vector2 deltaPosition { get; set; }
        public TouchPhase phase { get; set; }
        public int tapCount { get; set; }
    }

    public static class Input
    {
        public static bool GetKey(KeyCode key) => false;
        public static bool GetKey(string name) => false;
        public static bool GetKeyDown(KeyCode key) => false;
        public static bool GetKeyDown(string name) => false;
        public static bool GetKeyUp(KeyCode key) => false;
        public static bool GetKeyUp(string name) => false;
        public static bool GetButton(string buttonName) => false;
        public static bool GetButtonDown(string buttonName) => false;
        public static bool GetButtonUp(string buttonName) => false;
        public static float GetAxis(string axisName) => 0f;
        public static float GetAxisRaw(string axisName) => 0f;
        public static bool GetMouseButton(int button) => false;
        public static bool GetMouseButtonDown(int button) => false;
        public static bool GetMouseButtonUp(int button) => false;
        public static Vector3 mousePosition => default;
        public static Vector2 mouseScrollDelta => default;
        public static bool anyKey => false;
        public static bool anyKeyDown => false;
        public static int touchCount => 0;
        public static Touch GetTouch(int index) => default;
        public static string inputString => "";
    }

    public static class Debug
    {
        public static void Log(object message) { }
        public static void Log(object message, Object context) { }
        public static void LogWarning(object message) { }
        public static void LogWarning(object message, Object context) { }
        public static void LogError(object message) { }
        public static void LogError(object message, Object context) { }
        public static void LogException(Exception exception) { }
        public static void LogFormat(string format, params object[] args) { }
        public static void LogWarningFormat(string format, params object[] args) { }
        public static void LogErrorFormat(string format, params object[] args) { }
        public static void DrawLine(Vector3 start, Vector3 end) { }
        public static void DrawLine(Vector3 start, Vector3 end, Color color) { }
        public static void DrawLine(Vector3 start, Vector3 end, Color color, float duration) { }
        public static void DrawRay(Vector3 start, Vector3 dir) { }
        public static void DrawRay(Vector3 start, Vector3 dir, Color color) { }
        public static void DrawRay(Vector3 start, Vector3 dir, Color color, float duration) { }
        public static void Assert(bool condition) { }
        public static void Assert(bool condition, object message) { }
        public static void Break() { }
    }

    public static class Mathf
    {
        public const float PI = 3.14159274f;
        public const float Infinity = float.PositiveInfinity;
        public const float NegativeInfinity = float.NegativeInfinity;
        public const float Deg2Rad = PI * 2f / 360f;
        public const float Rad2Deg = 1f / Deg2Rad;
        public static readonly float Epsilon = float.Epsilon;
        public static float Abs(float f) => Math.Abs(f);
        public static int Abs(int value) => Math.Abs(value);
        public static float Clamp(float value, float min, float max) => value < min ? min : value > max ? max : value;
        public static int Clamp(int value, int min, int max) => value < min ? min : value > max ? max : value;
        public static float Clamp01(float value) => Clamp(value, 0f, 1f);
        public static float Lerp(float a, float b, float t) => a + (b - a) * Clamp01(t);
        public static float LerpUnclamped(float a, float b, float t) => a + (b - a) * t;
        public static float LerpAngle(float a, float b, float t) => b;
        public static float InverseLerp(float a, float b, float value) => a == b ? 0f : Clamp01((value - a) / (b - a));
        public static float MoveTowards(float current, float target, float maxDelta) => Abs(target - current) <= maxDelta ? target : current + Math.Sign(target - current) * maxDelta;
        public static float MoveTowardsAngle(float current, float target, float maxDelta) => target;
        public static float SmoothDamp(float current, float target, ref float currentVelocity, float smoothTime) => target;
        public static float SmoothDamp(float current, float target, ref float currentVelocity, float smoothTime, float maxSpeed) => target;
        public static float SmoothStep(float from, float to, float t) => to;
        public static float Min(float a, float b) => a < b ? a : b;
        public static float Min(params float[] values) => values.Length == 0 ? 0 : System.Linq.Enumerable.Min(values);
        public static int Min(int a, int b) => a < b ? a : b;
        public static int Min(params int[] values) => values.Length == 0 ? 0 : System.Linq.Enumerable.Min(values);
        public static float Max(float a, float b) => a > b ? a : b;
        public static float Max(params float[] values) => values.Length == 0 ? 0 : System.Linq.Enumerable.Max(values);
        public static int Max(int a, int b) => a > b ? a : b;
        public static int Max(params int[] values) => values.Length == 0 ? 0 : System.Linq.Enumerable.Max(values);
        public static float Sqrt(float f) => (float)Math.Sqrt(f);
        public static float Pow(float f, float p) => (float)Math.Pow(f, p);
        public static float Exp(float power) => (float)Math.Exp(power);
        public static float Log(float f) => (float)Math.Log(f);
        public static float Log(float f, float p) => (float)Math.Log(f, p);
        public static float Log10(float f) => (float)Math.Log10(f);
        public static float Sin(float f) => (float)Math.Sin(f);
        public static float Cos(float f) => (float)Math.Cos(f);
        public static float Tan(float f) => (float)Math.Tan(f);
        public static float Asin(float f) => (float)Math.Asin(f);
        public static float Acos(float f) => (float)Math.Acos(f);
        public static float Atan(float f) => (float)Math.Atan(f);
        public static float Atan2(float y, float x) => (float)Math.Atan2(y, x);
        public static float Floor(float f) => (float)Math.Floor(f);
        public static float Ceil(float f) => (float)Math.Ceiling(f);
        public static float Round(float f) => (float)Math.Round(f);
        public static int FloorToInt(float f) => (int)Math.Floor(f);
        public static int CeilToInt(float f) => (int)Math.Ceiling(f);
        public static int RoundToInt(float f) => (int)Math.Round(f);
        public static float Sign(float f) => f >= 0f ? 1f : -1f;
        public static bool Approximately(float a, float b) => Abs(b - a) < 1e-6f;
        public static float Repeat(float t, float length) => t - Floor(t / length) * length;
        public static float PingPong(float t, float length) => length - Abs(Repeat(t, length * 2f) - length);
        public static float DeltaAngle(float current, float target) => target - current;
        public static float PerlinNoise(float x, float y) => 0.5f;
        public static bool IsPowerOfTwo(int value) => (value & (value - 1)) == 0;
        public static int NextPowerOfTwo(int value) => value;
    }

    public static class Random
    {
        public static float Range(float minInclusive, float maxInclusive) => minInclusive;
        public static int Range(int minInclusive, int maxExclusive) => minInclusive;
        public static float value => 0.5f;
        public static Vector2 insideUnitCircle => default;
        public static Vector3 insideUnitSphere => default;
        public static Vector3 onUnitSphere => Vector3.up;
        public static Quaternion rotation => Quaternion.identity;
        public static void InitState(int seed) { }
        public static Color ColorHSV() => Color.white;
    }

    public enum ForceMode { Force = 0, Acceleration = 5, Impulse = 1, VelocityChange = 2 }
    public enum ForceMode2D { Force = 0, Impulse = 1 }
    public enum RigidbodyType2D { Dynamic = 0, Kinematic = 1, Static = 2 }
    public enum RigidbodyInterpolation { None, Interpolate, Extrapolate }
    public enum CollisionDetectionMode { Discrete, Continuous, ContinuousDynamic, ContinuousSpeculative }
    [Flags]
    public enum RigidbodyConstraints
    {
        None = 0, FreezePositionX = 2, FreezePositionY = 4, FreezePositionZ = 8,
        FreezeRotationX = 16, FreezeRotationY = 32, FreezeRotationZ = 64,
        FreezePosition = 14, FreezeRotation = 112, FreezeAll = 126,
    }
    [Flags]
    public enum RigidbodyConstraints2D { None = 0, FreezePositionX = 1, FreezePositionY = 2, FreezeRotation = 4, FreezePosition = 3, FreezeAll = 7 }

    public class Rigidbody : Component
    {
        public Vector3 linearVelocity { get; set; }
        [Obsolete("velocity has been renamed to linearVelocity. (UnityUpgradable) -> linearVelocity")]
        public Vector3 velocity { get; set; }
        public Vector3 angularVelocity { get; set; }
        public float linearDamping { get; set; }
        [Obsolete("drag has been renamed to linearDamping. (UnityUpgradable) -> linearDamping")]
        public float drag { get; set; }
        public float angularDamping { get; set; }
        [Obsolete("angularDrag has been renamed to angularDamping. (UnityUpgradable) -> angularDamping")]
        public float angularDrag { get; set; }
        public float mass { get; set; }
        public bool useGravity { get; set; }
        public bool isKinematic { get; set; }
        public bool freezeRotation { get; set; }
        public RigidbodyConstraints constraints { get; set; }
        public RigidbodyInterpolation interpolation { get; set; }
        public CollisionDetectionMode collisionDetectionMode { get; set; }
        public Vector3 position { get; set; }
        public Quaternion rotation { get; set; }
        public Vector3 centerOfMass { get; set; }
        public float maxAngularVelocity { get; set; }
        public void AddForce(Vector3 force) { }
        public void AddForce(Vector3 force, ForceMode mode) { }
        public void AddForce(float x, float y, float z) { }
        public void AddForce(float x, float y, float z, ForceMode mode) { }
        public void AddRelativeForce(Vector3 force) { }
        public void AddRelativeForce(Vector3 force, ForceMode mode) { }
        public void AddTorque(Vector3 torque) { }
        public void AddTorque(Vector3 torque, ForceMode mode) { }
        public void AddRelativeTorque(Vector3 torque) { }
        public void AddExplosionForce(float explosionForce, Vector3 explosionPosition, float explosionRadius) { }
        public void AddExplosionForce(float explosionForce, Vector3 explosionPosition, float explosionRadius, float upwardsModifier) { }
        public void AddForceAtPosition(Vector3 force, Vector3 position) { }
        public void MovePosition(Vector3 position) { }
        public void MoveRotation(Quaternion rot) { }
        public void Sleep() { }
        public void WakeUp() { }
        public bool IsSleeping() => false;
    }

    public class Rigidbody2D : Component
    {
        public Vector2 linearVelocity { get; set; }
        [Obsolete("velocity has been renamed to linearVelocity. (UnityUpgradable) -> linearVelocity")]
        public Vector2 velocity { get; set; }
        public float linearVelocityX { get; set; }
        public float linearVelocityY { get; set; }
        public float angularVelocity { get; set; }
        public float linearDamping { get; set; }
        [Obsolete("drag has been renamed to linearDamping. (UnityUpgradable) -> linearDamping")]
        public float drag { get; set; }
        public float angularDamping { get; set; }
        public float gravityScale { get; set; }
        public float mass { get; set; }
        public bool freezeRotation { get; set; }
        public RigidbodyType2D bodyType { get; set; }
        public RigidbodyConstraints2D constraints { get; set; }
        public Vector2 position { get; set; }
        public float rotation { get; set; }
        [Obsolete("isKinematic has been deprecated. Please use bodyType.")]
        public bool isKinematic { get; set; }
        public void AddForce(Vector2 force) { }
        public void AddForce(Vector2 force, ForceMode2D mode) { }
        public void AddForceX(float force) { }
        public void AddForceY(float force) { }
        public void AddRelativeForce(Vector2 relativeForce) { }
        public void AddTorque(float torque) { }
        public void AddTorque(float torque, ForceMode2D mode) { }
        public void MovePosition(Vector2 position) { }
        public void MoveRotation(float angle) { }
        public bool IsTouching(Collider2D collider) => false;
        public bool IsTouchingLayers(int layerMask) => false;
    }

    public class Collider : Component
    {
        public bool enabled { get; set; }
        public bool isTrigger { get; set; }
        public Bounds bounds => default;
        public Rigidbody attachedRigidbody => null;
        public Vector3 ClosestPoint(Vector3 position) => position;
        public bool Raycast(Ray ray, out RaycastHit hitInfo, float maxDistance) { hitInfo = default; return false; }
    }
    public class BoxCollider : Collider { public Vector3 size { get; set; } public Vector3 center { get; set; } }
    public class SphereCollider : Collider { public float radius { get; set; } public Vector3 center { get; set; } }
    public class CapsuleCollider : Collider { public float radius { get; set; } public float height { get; set; } }
    public class MeshCollider : Collider { public bool convex { get; set; } }

    public enum CollisionFlags { None = 0, Sides = 1, Above = 2, Below = 4 }

    public class CharacterController : Collider
    {
        public CollisionFlags Move(Vector3 motion) => CollisionFlags.None;
        public bool SimpleMove(Vector3 speed) => false;
        public bool isGrounded => false;
        public Vector3 velocity => default;
        public float height { get; set; }
        public float radius { get; set; }
        public float slopeLimit { get; set; }
        public float stepOffset { get; set; }
        public Vector3 center { get; set; }
        public CollisionFlags collisionFlags => CollisionFlags.None;
    }

    public class Collider2D : Behaviour
    {
        public bool isTrigger { get; set; }
        public Bounds bounds => default;
        public Rigidbody2D attachedRigidbody => null;
        public Vector2 offset { get; set; }
        public bool IsTouching(Collider2D collider) => false;
        public bool IsTouchingLayers(int layerMask) => false;
        public bool OverlapPoint(Vector2 point) => false;
    }
    public class BoxCollider2D : Collider2D { public Vector2 size { get; set; } }
    public class CircleCollider2D : Collider2D { public float radius { get; set; } }
    public class CapsuleCollider2D : Collider2D { public Vector2 size { get; set; } }
    public class PolygonCollider2D : Collider2D { }

    public struct ContactPoint
    {
        public Vector3 point => default;
        public Vector3 normal => default;
        public float separation => 0f;
        public Collider thisCollider => null;
        public Collider otherCollider => null;
    }

    public struct ContactPoint2D
    {
        public Vector2 point => default;
        public Vector2 normal => default;
        public float separation => 0f;
        public Collider2D collider => null;
        public Collider2D otherCollider => null;
    }

    public class Collision
    {
        public GameObject gameObject => null;
        public Collider collider => null;
        public Transform transform => null;
        public Rigidbody rigidbody => null;
        public Vector3 relativeVelocity => default;
        public Vector3 impulse => default;
        public int contactCount => 0;
        public ContactPoint[] contacts => Array.Empty<ContactPoint>();
        public ContactPoint GetContact(int index) => default;
    }

    public class Collision2D
    {
        public GameObject gameObject => null;
        public Collider2D collider => null;
        public Collider2D otherCollider => null;
        public Transform transform => null;
        public Rigidbody2D rigidbody => null;
        public Vector2 relativeVelocity => default;
        public int contactCount => 0;
        public ContactPoint2D[] contacts => Array.Empty<ContactPoint2D>();
        public ContactPoint2D GetContact(int index) => default;
    }

    public struct RaycastHit
    {
        public Vector3 point { get; set; }
        public Vector3 normal { get; set; }
        public float distance { get; set; }
        public Collider collider => null;
        public Transform transform => null;
        public Rigidbody rigidbody => null;
    }

    public struct RaycastHit2D
    {
        public Vector2 point { get; set; }
        public Vector2 normal { get; set; }
        public float distance { get; set; }
        public float fraction { get; set; }
        public Collider2D collider => null;
        public Transform transform => null;
        public Rigidbody2D rigidbody => null;
        public static implicit operator bool(RaycastHit2D hit) => hit.collider != null;
    }

    public enum QueryTriggerInteraction { UseGlobal, Ignore, Collide }

    public static class Physics
    {
        public static Vector3 gravity { get; set; } = new Vector3(0, -9.81f, 0);
        public const int DefaultRaycastLayers = -5;
        public const int AllLayers = -1;
        public static bool Raycast(Vector3 origin, Vector3 direction) => false;
        public static bool Raycast(Vector3 origin, Vector3 direction, float maxDistance) => false;
        public static bool Raycast(Vector3 origin, Vector3 direction, float maxDistance, int layerMask) => false;
        public static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hitInfo) { hitInfo = default; return false; }
        public static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hitInfo, float maxDistance) { hitInfo = default; return false; }
        public static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hitInfo, float maxDistance, int layerMask) { hitInfo = default; return false; }
        public static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hitInfo, float maxDistance, int layerMask, QueryTriggerInteraction queryTriggerInteraction) { hitInfo = default; return false; }
        public static bool Raycast(Ray ray) => false;
        public static bool Raycast(Ray ray, float maxDistance) => false;
        public static bool Raycast(Ray ray, out RaycastHit hitInfo) { hitInfo = default; return false; }
        public static bool Raycast(Ray ray, out RaycastHit hitInfo, float maxDistance) { hitInfo = default; return false; }
        public static bool Raycast(Ray ray, out RaycastHit hitInfo, float maxDistance, int layerMask) { hitInfo = default; return false; }
        public static RaycastHit[] RaycastAll(Vector3 origin, Vector3 direction, float maxDistance) => Array.Empty<RaycastHit>();
        public static RaycastHit[] RaycastAll(Ray ray, float maxDistance) => Array.Empty<RaycastHit>();
        public static bool SphereCast(Vector3 origin, float radius, Vector3 direction, out RaycastHit hitInfo, float maxDistance) { hitInfo = default; return false; }
        public static bool Linecast(Vector3 start, Vector3 end) => false;
        public static bool CheckSphere(Vector3 position, float radius) => false;
        public static bool CheckSphere(Vector3 position, float radius, int layerMask) => false;
        public static Collider[] OverlapSphere(Vector3 position, float radius) => Array.Empty<Collider>();
        public static Collider[] OverlapSphere(Vector3 position, float radius, int layerMask) => Array.Empty<Collider>();
        public static int OverlapSphereNonAlloc(Vector3 position, float radius, Collider[] results) => 0;
        public static int OverlapSphereNonAlloc(Vector3 position, float radius, Collider[] results, int layerMask) => 0;
        public static Collider[] OverlapBox(Vector3 center, Vector3 halfExtents) => Array.Empty<Collider>();
        public static void IgnoreCollision(Collider collider1, Collider collider2) { }
        public static void IgnoreCollision(Collider collider1, Collider collider2, bool ignore) { }
        public static void IgnoreLayerCollision(int layer1, int layer2, bool ignore) { }
    }

    public static class Physics2D
    {
        public static Vector2 gravity { get; set; } = new Vector2(0, -9.81f);
        public static RaycastHit2D Raycast(Vector2 origin, Vector2 direction) => default;
        public static RaycastHit2D Raycast(Vector2 origin, Vector2 direction, float distance) => default;
        public static RaycastHit2D Raycast(Vector2 origin, Vector2 direction, float distance, int layerMask) => default;
        public static RaycastHit2D[] RaycastAll(Vector2 origin, Vector2 direction, float distance) => Array.Empty<RaycastHit2D>();
        public static RaycastHit2D CircleCast(Vector2 origin, float radius, Vector2 direction, float distance) => default;
        public static RaycastHit2D BoxCast(Vector2 origin, Vector2 size, float angle, Vector2 direction, float distance) => default;
        public static RaycastHit2D Linecast(Vector2 start, Vector2 end) => default;
        public static Collider2D OverlapCircle(Vector2 point, float radius) => null;
        public static Collider2D OverlapCircle(Vector2 point, float radius, int layerMask) => null;
        public static Collider2D[] OverlapCircleAll(Vector2 point, float radius) => Array.Empty<Collider2D>();
        public static Collider2D[] OverlapCircleAll(Vector2 point, float radius, int layerMask) => Array.Empty<Collider2D>();
        public static Collider2D OverlapBox(Vector2 point, Vector2 size, float angle) => null;
        public static Collider2D OverlapPoint(Vector2 point) => null;
        public static void IgnoreCollision(Collider2D collider1, Collider2D collider2) { }
    }

    public class Renderer : Component
    {
        public bool enabled { get; set; }
        public Material material { get; set; }
        public Material sharedMaterial { get; set; }
        public Material[] materials { get; set; }
        public Bounds bounds => default;
        public bool isVisible => false;
        public int sortingOrder { get; set; }
        public string sortingLayerName { get; set; }
    }
    public class MeshRenderer : Renderer { }
    public class LineRenderer : Renderer
    {
        public int positionCount { get; set; }
        public float startWidth { get; set; }
        public float endWidth { get; set; }
        public Color startColor { get; set; }
        public Color endColor { get; set; }
        public void SetPosition(int index, Vector3 position) { }
        public Vector3 GetPosition(int index) => default;
    }
    public class TrailRenderer : Renderer { public float time { get; set; } public void Clear() { } }

    public sealed class SpriteRenderer : Renderer
    {
        public Sprite sprite { get; set; }
        public Color color { get; set; }
        public bool flipX { get; set; }
        public bool flipY { get; set; }
    }

    public sealed class Sprite : Object
    {
        public Rect rect => default;
        public Texture2D texture => null;
        public Bounds bounds => default;
        public static Sprite Create(Texture2D texture, Rect rect, Vector2 pivot) => null;
    }

    public class Texture : Object { public int width { get; set; } public int height { get; set; } }
    public sealed class Texture2D : Texture
    {
        public Texture2D(int width, int height) { }
        public void SetPixel(int x, int y, Color color) { }
        public Color GetPixel(int x, int y) => default;
        public void Apply() { }
    }

    public class Shader : Object
    {
        public static Shader Find(string name) => null;
        public static int PropertyToID(string name) => 0;
    }

    public class Material : Object
    {
        public Material(Shader shader) { }
        public Material(Material source) { }
        public Color color { get; set; }
        public Texture mainTexture { get; set; }
        public Shader shader { get; set; }
        public void SetColor(string name, Color value) { }
        public void SetColor(int nameID, Color value) { }
        public void SetFloat(string name, float value) { }
        public void SetFloat(int nameID, float value) { }
        public void SetInt(string name, int value) { }
        public void SetTexture(string name, Texture value) { }
        public Color GetColor(string name) => default;
        public float GetFloat(string name) => 0f;
        public void EnableKeyword(string keyword) { }
    }

    public class Mesh : Object
    {
        public Vector3[] vertices { get; set; }
        public int[] triangles { get; set; }
        public Vector2[] uv { get; set; }
        public void RecalculateNormals() { }
        public void RecalculateBounds() { }
        public void Clear() { }
    }
    public sealed class MeshFilter : Component { public Mesh mesh { get; set; } public Mesh sharedMesh { get; set; } }

    public enum CameraClearFlags { Skybox = 1, SolidColor = 2, Depth = 3, Nothing = 4 }

    public sealed class Camera : Behaviour
    {
        public static Camera main => null;
        public float fieldOfView { get; set; }
        public float orthographicSize { get; set; }
        public bool orthographic { get; set; }
        public float nearClipPlane { get; set; }
        public float farClipPlane { get; set; }
        public float aspect { get; set; }
        public Color backgroundColor { get; set; }
        public CameraClearFlags clearFlags { get; set; }
        public int cullingMask { get; set; }
        public Vector3 ScreenToWorldPoint(Vector3 position) => position;
        public Vector3 WorldToScreenPoint(Vector3 position) => position;
        public Vector3 WorldToViewportPoint(Vector3 position) => position;
        public Vector3 ViewportToWorldPoint(Vector3 position) => position;
        public Ray ScreenPointToRay(Vector3 pos) => default;
        public Ray ViewportPointToRay(Vector3 pos) => default;
    }

    public enum LightType { Spot = 0, Directional = 1, Point = 2 }
    public sealed class Light : Behaviour
    {
        public Color color { get; set; }
        public float intensity { get; set; }
        public float range { get; set; }
        public LightType type { get; set; }
    }

    public class YieldInstruction { }
    public sealed class Coroutine : YieldInstruction { }
    public sealed class WaitForSeconds : YieldInstruction { public WaitForSeconds(float seconds) { } }
    public sealed class WaitForEndOfFrame : YieldInstruction { }
    public sealed class WaitForFixedUpdate : YieldInstruction { }
    public abstract class CustomYieldInstruction : IEnumerator
    {
        public abstract bool keepWaiting { get; }
        public object Current => null;
        public bool MoveNext() => keepWaiting;
        public virtual void Reset() { }
    }
    public class WaitForSecondsRealtime : CustomYieldInstruction
    {
        public WaitForSecondsRealtime(float time) { }
        public float waitTime { get; set; }
        public override bool keepWaiting => false;
    }
    public sealed class WaitUntil : CustomYieldInstruction
    {
        public WaitUntil(Func<bool> predicate) { }
        public override bool keepWaiting => false;
    }
    public sealed class WaitWhile : CustomYieldInstruction
    {
        public WaitWhile(Func<bool> predicate) { }
        public override bool keepWaiting => false;
    }

    public class AsyncOperation : YieldInstruction
    {
        public bool isDone => true;
        public float progress => 1f;
        public bool allowSceneActivation { get; set; }
        public int priority { get; set; }
        public event Action<AsyncOperation> completed;
    }

    // Awaitable (Unity 2023.1+ / Unity 6): async/await no loop do Unity.
    // Pode ser usado com "yield return" numa corrotina (Awaitable implementa IEnumerator).
    [AsyncMethodBuilder(typeof(Awaitable.AwaitableAsyncMethodBuilder))]
    public class Awaitable : IEnumerator
    {
        public static Awaitable NextFrameAsync(CancellationToken cancellationToken = default) => new Awaitable();
        public static Awaitable WaitForSecondsAsync(float seconds, CancellationToken cancellationToken = default) => new Awaitable();
        public static Awaitable FixedUpdateAsync(CancellationToken cancellationToken = default) => new Awaitable();
        public static Awaitable EndOfFrameAsync(CancellationToken cancellationToken = default) => new Awaitable();
        public static Awaitable FromAsyncOperation(AsyncOperation op, CancellationToken cancellationToken = default) => new Awaitable();
        public static MainThreadAwaitable MainThreadAsync() => default;
        public static BackgroundThreadAwaitable BackgroundThreadAsync() => default;
        public bool IsCompleted => true;
        public void Cancel() { }
        public Awaiter GetAwaiter() => new Awaiter();
        object IEnumerator.Current => null;
        bool IEnumerator.MoveNext() => false;
        void IEnumerator.Reset() { }

        public struct Awaiter : INotifyCompletion
        {
            public bool IsCompleted => true;
            public void OnCompleted(Action continuation) => continuation();
            public void GetResult() { }
        }

        public struct AwaitableAsyncMethodBuilder
        {
            public static AwaitableAsyncMethodBuilder Create() => default;
            public Awaitable Task => new Awaitable();
            public void Start<TStateMachine>(ref TStateMachine stateMachine) where TStateMachine : IAsyncStateMachine => stateMachine.MoveNext();
            public void SetStateMachine(IAsyncStateMachine stateMachine) { }
            public void SetException(Exception exception) { }
            public void SetResult() { }
            public void AwaitOnCompleted<TAwaiter, TStateMachine>(ref TAwaiter awaiter, ref TStateMachine stateMachine)
                where TAwaiter : INotifyCompletion where TStateMachine : IAsyncStateMachine { }
            public void AwaitUnsafeOnCompleted<TAwaiter, TStateMachine>(ref TAwaiter awaiter, ref TStateMachine stateMachine)
                where TAwaiter : ICriticalNotifyCompletion where TStateMachine : IAsyncStateMachine { }
        }

        public struct AwaitableAsyncMethodBuilder<T>
        {
            public static AwaitableAsyncMethodBuilder<T> Create() => default;
            public Awaitable<T> Task => new Awaitable<T>();
            public void Start<TStateMachine>(ref TStateMachine stateMachine) where TStateMachine : IAsyncStateMachine => stateMachine.MoveNext();
            public void SetStateMachine(IAsyncStateMachine stateMachine) { }
            public void SetException(Exception exception) { }
            public void SetResult(T result) { }
            public void AwaitOnCompleted<TAwaiter, TStateMachine>(ref TAwaiter awaiter, ref TStateMachine stateMachine)
                where TAwaiter : INotifyCompletion where TStateMachine : IAsyncStateMachine { }
            public void AwaitUnsafeOnCompleted<TAwaiter, TStateMachine>(ref TAwaiter awaiter, ref TStateMachine stateMachine)
                where TAwaiter : ICriticalNotifyCompletion where TStateMachine : IAsyncStateMachine { }
        }
    }

    [AsyncMethodBuilder(typeof(Awaitable.AwaitableAsyncMethodBuilder<>))]
    public class Awaitable<T>
    {
        public bool IsCompleted => true;
        public void Cancel() { }
        public Awaiter GetAwaiter() => new Awaiter();

        public struct Awaiter : INotifyCompletion
        {
            public bool IsCompleted => true;
            public void OnCompleted(Action continuation) => continuation();
            public T GetResult() => default;
        }
    }

    public struct MainThreadAwaitable : INotifyCompletion
    {
        public MainThreadAwaitable GetAwaiter() => this;
        public bool IsCompleted => true;
        public void OnCompleted(Action continuation) => continuation();
        public void GetResult() { }
    }

    public struct BackgroundThreadAwaitable : INotifyCompletion
    {
        public BackgroundThreadAwaitable GetAwaiter() => this;
        public bool IsCompleted => true;
        public void OnCompleted(Action continuation) => continuation();
        public void GetResult() { }
    }

    public static class AsyncOperationAwaitableExtensions
    {
        public static Awaitable.Awaiter GetAwaiter(this AsyncOperation op) => new Awaitable.Awaiter();
    }

    public sealed class Animator : Behaviour
    {
        public float speed { get; set; }
        public bool applyRootMotion { get; set; }
        public RuntimeAnimatorController runtimeAnimatorController { get; set; }
        public void SetTrigger(string name) { }
        public void SetTrigger(int id) { }
        public void ResetTrigger(string name) { }
        public void ResetTrigger(int id) { }
        public void SetBool(string name, bool value) { }
        public void SetBool(int id, bool value) { }
        public bool GetBool(string name) => false;
        public bool GetBool(int id) => false;
        public void SetFloat(string name, float value) { }
        public void SetFloat(int id, float value) { }
        public void SetFloat(string name, float value, float dampTime, float deltaTime) { }
        public float GetFloat(string name) => 0f;
        public float GetFloat(int id) => 0f;
        public void SetInteger(string name, int value) { }
        public void SetInteger(int id, int value) { }
        public int GetInteger(string name) => 0;
        public void Play(string stateName) { }
        public void Play(string stateName, int layer) { }
        public void CrossFade(string stateName, float normalizedTransitionDuration) { }
        public AnimatorStateInfo GetCurrentAnimatorStateInfo(int layerIndex) => default;
        public static int StringToHash(string name) => name?.GetHashCode() ?? 0;
    }
    public class RuntimeAnimatorController : Object { }
    public struct AnimatorStateInfo
    {
        public bool IsName(string name) => false;
        public float normalizedTime => 0f;
        public float length => 0f;
    }

    public sealed class AudioClip : Object
    {
        public float length => 0f;
        public int samples => 0;
        public int channels => 0;
        public int frequency => 0;
    }

    public sealed class AudioSource : Behaviour
    {
        public AudioClip clip { get; set; }
        public float volume { get; set; }
        public float pitch { get; set; }
        public bool loop { get; set; }
        public bool mute { get; set; }
        public bool playOnAwake { get; set; }
        public float spatialBlend { get; set; }
        public float time { get; set; }
        public bool isPlaying => false;
        public void Play() { }
        public void PlayDelayed(float delay) { }
        public void Stop() { }
        public void Pause() { }
        public void UnPause() { }
        public void PlayOneShot(AudioClip clip) { }
        public void PlayOneShot(AudioClip clip, float volumeScale) { }
        public static void PlayClipAtPoint(AudioClip clip, Vector3 position) { }
        public static void PlayClipAtPoint(AudioClip clip, Vector3 position, float volume) { }
    }
    public sealed class AudioListener : Behaviour { public static float volume { get; set; } public static bool pause { get; set; } }

    public sealed class ParticleSystem : Component
    {
        public bool isPlaying => false;
        public void Play() { }
        public void Stop() { }
        public void Emit(int count) { }
        public void Clear() { }
    }

    public static class PlayerPrefs
    {
        public static void SetInt(string key, int value) { }
        public static int GetInt(string key) => 0;
        public static int GetInt(string key, int defaultValue) => defaultValue;
        public static void SetFloat(string key, float value) { }
        public static float GetFloat(string key) => 0f;
        public static float GetFloat(string key, float defaultValue) => defaultValue;
        public static void SetString(string key, string value) { }
        public static string GetString(string key) => "";
        public static string GetString(string key, string defaultValue) => defaultValue;
        public static bool HasKey(string key) => false;
        public static void DeleteKey(string key) { }
        public static void DeleteAll() { }
        public static void Save() { }
    }

    public static class JsonUtility
    {
        public static string ToJson(object obj) => "{}";
        public static string ToJson(object obj, bool prettyPrint) => "{}";
        public static T FromJson<T>(string json) => default;
        public static object FromJson(string json, Type type) => null;
        public static void FromJsonOverwrite(string json, object objectToOverwrite) { }
    }

    public enum RuntimePlatform { OSXEditor = 0, OSXPlayer = 1, WindowsPlayer = 2, WindowsEditor = 7, IPhonePlayer = 8, Android = 11, LinuxPlayer = 13, WebGLPlayer = 17 }

    public static class Application
    {
        public static int targetFrameRate { get; set; }
        public static bool isPlaying => false;
        public static bool isEditor => false;
        public static bool isFocused => false;
        public static bool runInBackground { get; set; }
        public static RuntimePlatform platform => RuntimePlatform.WindowsPlayer;
        public static string persistentDataPath => "";
        public static string dataPath => "";
        public static string version => "1.0";
        public static string productName => "";
        public static void Quit() { }
        public static void Quit(int exitCode) { }
        public static void OpenURL(string url) { }
    }

    public static class Screen
    {
        public static int width => 1920;
        public static int height => 1080;
        public static bool fullScreen { get; set; }
        public static float dpi => 96f;
        public static void SetResolution(int width, int height, bool fullscreen) { }
    }

    public enum CursorLockMode { None, Locked, Confined }
    public static class Cursor
    {
        public static CursorLockMode lockState { get; set; }
        public static bool visible { get; set; }
    }

    public static class Gizmos
    {
        public static Color color { get; set; }
        public static void DrawLine(Vector3 from, Vector3 to) { }
        public static void DrawRay(Vector3 from, Vector3 direction) { }
        public static void DrawSphere(Vector3 center, float radius) { }
        public static void DrawWireSphere(Vector3 center, float radius) { }
        public static void DrawCube(Vector3 center, Vector3 size) { }
        public static void DrawWireCube(Vector3 center, Vector3 size) { }
    }

    public static class Resources
    {
        public static T Load<T>(string path) where T : Object => default;
        public static Object Load(string path) => null;
        public static T[] LoadAll<T>(string path) where T : Object => Array.Empty<T>();
        public static AsyncOperation UnloadUnusedAssets() => null;
    }

    // ---------- atributos do Inspector ----------
    public abstract class PropertyAttribute : Attribute { public int order { get; set; } }

    [AttributeUsage(AttributeTargets.Field)]
    public sealed class SerializeField : Attribute { }
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
    public sealed class SerializeReference : Attribute { }
    [AttributeUsage(AttributeTargets.Field)]
    public sealed class HideInInspector : Attribute { }
    [AttributeUsage(AttributeTargets.Field, Inherited = true, AllowMultiple = true)]
    public class HeaderAttribute : PropertyAttribute { public readonly string header; public HeaderAttribute(string header) { this.header = header; } }
    [AttributeUsage(AttributeTargets.Field, Inherited = true, AllowMultiple = false)]
    public sealed class RangeAttribute : PropertyAttribute { public readonly float min; public readonly float max; public RangeAttribute(float min, float max) { this.min = min; this.max = max; } }
    [AttributeUsage(AttributeTargets.Field, Inherited = true, AllowMultiple = false)]
    public sealed class MinAttribute : PropertyAttribute { public readonly float min; public MinAttribute(float min) { this.min = min; } }
    [AttributeUsage(AttributeTargets.Field, Inherited = true, AllowMultiple = false)]
    public class TooltipAttribute : PropertyAttribute { public readonly string tooltip; public TooltipAttribute(string tooltip) { this.tooltip = tooltip; } }
    [AttributeUsage(AttributeTargets.Field, Inherited = true, AllowMultiple = true)]
    public class SpaceAttribute : PropertyAttribute { public readonly float height; public SpaceAttribute() { height = 8; } public SpaceAttribute(float height) { this.height = height; } }
    [AttributeUsage(AttributeTargets.Field, Inherited = true, AllowMultiple = false)]
    public class TextAreaAttribute : PropertyAttribute { public TextAreaAttribute() { } public TextAreaAttribute(int minLines, int maxLines) { } }
    [AttributeUsage(AttributeTargets.Field, Inherited = true, AllowMultiple = false)]
    public sealed class MultilineAttribute : PropertyAttribute { public MultilineAttribute() { } public MultilineAttribute(int lines) { } }
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = true)]
    public sealed class RequireComponent : Attribute
    {
        public RequireComponent(Type requiredComponent) { }
        public RequireComponent(Type requiredComponent, Type requiredComponent2) { }
        public RequireComponent(Type requiredComponent, Type requiredComponent2, Type requiredComponent3) { }
    }
    [AttributeUsage(AttributeTargets.Class, Inherited = false, AllowMultiple = false)]
    public sealed class DisallowMultipleComponent : Attribute { }
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class ExecuteAlways : Attribute { }
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class ExecuteInEditMode : Attribute { }
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class AddComponentMenu : Attribute { public AddComponentMenu(string menuName) { } public AddComponentMenu(string menuName, int order) { } }
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class CreateAssetMenuAttribute : Attribute
    {
        public string menuName { get; set; }
        public string fileName { get; set; }
        public int order { get; set; }
    }
    [AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
    public sealed class ContextMenu : Attribute { public ContextMenu(string itemName) { } }
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class DefaultExecutionOrder : Attribute { public DefaultExecutionOrder(int order) { } }
    public enum RuntimeInitializeLoadType { AfterSceneLoad, BeforeSceneLoad, AfterAssembliesLoaded, BeforeSplashScreen, SubsystemRegistration }
    [AttributeUsage(AttributeTargets.Method)]
    public class RuntimeInitializeOnLoadMethodAttribute : Attribute
    {
        public RuntimeInitializeOnLoadMethodAttribute() { }
        public RuntimeInitializeOnLoadMethodAttribute(RuntimeInitializeLoadType loadType) { }
    }
}

namespace UnityEngine.SceneManagement
{
    public enum LoadSceneMode { Single = 0, Additive = 1 }

    public struct Scene
    {
        public string name => "";
        public int buildIndex => 0;
        public bool isLoaded => true;
        public string path => "";
        public bool IsValid() => true;
        public UnityEngine.GameObject[] GetRootGameObjects() => System.Array.Empty<UnityEngine.GameObject>();
    }

    public static class SceneManager
    {
        public static int sceneCount => 1;
        public static int sceneCountInBuildSettings => 1;
        public static Scene GetActiveScene() => default;
        public static bool SetActiveScene(Scene scene) => true;
        public static Scene GetSceneByName(string name) => default;
        public static void LoadScene(string sceneName) { }
        public static void LoadScene(int sceneBuildIndex) { }
        public static void LoadScene(string sceneName, LoadSceneMode mode) { }
        public static void LoadScene(int sceneBuildIndex, LoadSceneMode mode) { }
        public static UnityEngine.AsyncOperation LoadSceneAsync(string sceneName) => null;
        public static UnityEngine.AsyncOperation LoadSceneAsync(int sceneBuildIndex) => null;
        public static UnityEngine.AsyncOperation LoadSceneAsync(string sceneName, LoadSceneMode mode) => null;
        public static UnityEngine.AsyncOperation UnloadSceneAsync(string sceneName) => null;
        public static event System.Action<Scene, LoadSceneMode> sceneLoaded;
        public static event System.Action<Scene> sceneUnloaded;
    }
}

namespace UnityEngine.Events
{
    public delegate void UnityAction();
    public delegate void UnityAction<T0>(T0 arg0);
    public delegate void UnityAction<T0, T1>(T0 arg0, T1 arg1);
    public delegate void UnityAction<T0, T1, T2>(T0 arg0, T1 arg1, T2 arg2);

    public abstract class UnityEventBase
    {
        public void RemoveAllListeners() { }
        public int GetPersistentEventCount() => 0;
    }

    [System.Serializable]
    public class UnityEvent : UnityEventBase
    {
        public void AddListener(UnityAction call) { }
        public void RemoveListener(UnityAction call) { }
        public void Invoke() { }
    }

    [System.Serializable]
    public class UnityEvent<T0> : UnityEventBase
    {
        public void AddListener(UnityAction<T0> call) { }
        public void RemoveListener(UnityAction<T0> call) { }
        public void Invoke(T0 arg0) { }
    }

    [System.Serializable]
    public class UnityEvent<T0, T1> : UnityEventBase
    {
        public void AddListener(UnityAction<T0, T1> call) { }
        public void RemoveListener(UnityAction<T0, T1> call) { }
        public void Invoke(T0 arg0, T1 arg1) { }
    }
}

namespace UnityEngine
{
    public static class UnityEventAwaitableExtensions
    {
        public static Awaitable.Awaiter GetAwaiter(this UnityEngine.Events.UnityEvent ev) => new Awaitable.Awaiter();
    }
}

namespace UnityEngine.Pool
{
    public interface IObjectPool<T> where T : class
    {
        int CountInactive { get; }
        T Get();
        PooledObject<T> Get(out T v);
        void Release(T element);
        void Clear();
    }

    public struct PooledObject<T> : System.IDisposable where T : class
    {
        public void Dispose() { }
    }

    public class ObjectPool<T> : System.IDisposable, IObjectPool<T> where T : class
    {
        public ObjectPool(System.Func<T> createFunc, System.Action<T> actionOnGet = null, System.Action<T> actionOnRelease = null,
            System.Action<T> actionOnDestroy = null, bool collectionCheck = true, int defaultCapacity = 10, int maxSize = 10000) { }
        public int CountAll => 0;
        public int CountActive => 0;
        public int CountInactive => 0;
        public T Get() => default;
        public PooledObject<T> Get(out T v) { v = default; return default; }
        public void Release(T element) { }
        public void Clear() { }
        public void Dispose() { }
    }
}

namespace UnityEngine.Serialization
{
    [System.AttributeUsage(System.AttributeTargets.Field, AllowMultiple = true)]
    public class FormerlySerializedAsAttribute : System.Attribute
    {
        public FormerlySerializedAsAttribute(string oldName) { }
        public string oldName => "";
    }
}

namespace UnityEngine.EventSystems
{
    public class UIBehaviour : UnityEngine.MonoBehaviour { }
    public class PointerEventData { public UnityEngine.Vector2 position { get; set; } public int clickCount { get; set; } }
    public interface IEventSystemHandler { }
    public interface IPointerClickHandler : IEventSystemHandler { void OnPointerClick(PointerEventData eventData); }
    public interface IPointerEnterHandler : IEventSystemHandler { void OnPointerEnter(PointerEventData eventData); }
    public interface IPointerExitHandler : IEventSystemHandler { void OnPointerExit(PointerEventData eventData); }
    public interface IPointerDownHandler : IEventSystemHandler { void OnPointerDown(PointerEventData eventData); }
    public interface IPointerUpHandler : IEventSystemHandler { void OnPointerUp(PointerEventData eventData); }
    public interface IDragHandler : IEventSystemHandler { void OnDrag(PointerEventData eventData); }
    public class EventSystem : UIBehaviour { public static EventSystem current { get; set; } public bool IsPointerOverGameObject() => false; }
}

namespace UnityEngine.UI
{
    public class Graphic : UnityEngine.EventSystems.UIBehaviour
    {
        public UnityEngine.Color color { get; set; }
        public bool raycastTarget { get; set; }
        public UnityEngine.RectTransform rectTransform => null;
    }
    public class MaskableGraphic : Graphic { }
    public class Text : MaskableGraphic { public string text { get; set; } public int fontSize { get; set; } }
    public enum ImageType { Simple, Sliced, Tiled, Filled }
    public class Image : MaskableGraphic
    {
        public UnityEngine.Sprite sprite { get; set; }
        public float fillAmount { get; set; }
        public bool preserveAspect { get; set; }
        public Type type { get; set; }
        public enum Type { Simple, Sliced, Tiled, Filled }
    }
    public class Selectable : UnityEngine.EventSystems.UIBehaviour { public bool interactable { get; set; } public void Select() { } }
    public class Button : Selectable
    {
        public ButtonClickedEvent onClick { get; set; } = new ButtonClickedEvent();
        [System.Serializable] public class ButtonClickedEvent : UnityEngine.Events.UnityEvent { }
    }
    public class Slider : Selectable
    {
        public float value { get; set; }
        public float minValue { get; set; }
        public float maxValue { get; set; }
        public bool wholeNumbers { get; set; }
        public SliderEvent onValueChanged { get; set; } = new SliderEvent();
        [System.Serializable] public class SliderEvent : UnityEngine.Events.UnityEvent<float> { }
    }
    public class Toggle : Selectable
    {
        public bool isOn { get; set; }
        public ToggleEvent onValueChanged { get; set; } = new ToggleEvent();
        [System.Serializable] public class ToggleEvent : UnityEngine.Events.UnityEvent<bool> { }
    }
}

namespace UnityEngine.AI
{
    public class NavMeshAgent : UnityEngine.Behaviour
    {
        public UnityEngine.Vector3 destination { get; set; }
        public float speed { get; set; }
        public float acceleration { get; set; }
        public float angularSpeed { get; set; }
        public float stoppingDistance { get; set; }
        public float remainingDistance => 0f;
        public bool isStopped { get; set; }
        public bool hasPath => false;
        public bool pathPending => false;
        public UnityEngine.Vector3 velocity { get; set; }
        public bool SetDestination(UnityEngine.Vector3 target) => true;
        public void ResetPath() { }
        public bool Warp(UnityEngine.Vector3 newPosition) => true;
    }
}

namespace TMPro
{
    public class TMP_Text : UnityEngine.UI.MaskableGraphic
    {
        public string text { get; set; }
        public float fontSize { get; set; }
        public bool enableAutoSizing { get; set; }
        public void SetText(string sourceText) { }
        public void SetText(string sourceText, float arg0) { }
        public void SetText(string sourceText, float arg0, float arg1) { }
    }
    public class TextMeshProUGUI : TMP_Text { }
    public class TextMeshPro : TMP_Text { }
    public class TMP_InputField : UnityEngine.UI.Selectable
    {
        public string text { get; set; }
        public UnityEngine.Events.UnityEvent<string> onEndEdit { get; set; } = new UnityEngine.Events.UnityEvent<string>();
        public UnityEngine.Events.UnityEvent<string> onValueChanged { get; set; } = new UnityEngine.Events.UnityEvent<string>();
    }
}

namespace UnityEngine.InputSystem
{
    using UnityEngine.InputSystem.Controls;

    public abstract class InputControl { public string name => ""; }
    public abstract class InputControl<TValue> : InputControl where TValue : struct { public TValue ReadValue() => default; }
    public abstract class InputDevice : InputControl { }

    public class Keyboard : InputDevice
    {
        public static Keyboard current => null;
        public KeyControl this[Key key] => null;
        public KeyControl anyKey => null;
        public KeyControl spaceKey => null;
        public KeyControl enterKey => null;
        public KeyControl escapeKey => null;
        public KeyControl tabKey => null;
        public KeyControl backspaceKey => null;
        public KeyControl leftShiftKey => null;
        public KeyControl rightShiftKey => null;
        public KeyControl leftCtrlKey => null;
        public KeyControl upArrowKey => null;
        public KeyControl downArrowKey => null;
        public KeyControl leftArrowKey => null;
        public KeyControl rightArrowKey => null;
        public KeyControl aKey => null; public KeyControl bKey => null; public KeyControl cKey => null; public KeyControl dKey => null;
        public KeyControl eKey => null; public KeyControl fKey => null; public KeyControl gKey => null; public KeyControl hKey => null;
        public KeyControl iKey => null; public KeyControl jKey => null; public KeyControl kKey => null; public KeyControl lKey => null;
        public KeyControl mKey => null; public KeyControl nKey => null; public KeyControl oKey => null; public KeyControl pKey => null;
        public KeyControl qKey => null; public KeyControl rKey => null; public KeyControl sKey => null; public KeyControl tKey => null;
        public KeyControl uKey => null; public KeyControl vKey => null; public KeyControl wKey => null; public KeyControl xKey => null;
        public KeyControl yKey => null; public KeyControl zKey => null;
        public KeyControl digit1Key => null; public KeyControl digit2Key => null; public KeyControl digit3Key => null;
    }

    public enum Key { None, Space, Enter, Tab, Escape, LeftArrow, RightArrow, UpArrow, DownArrow, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z }

    public class Mouse : InputDevice
    {
        public static Mouse current => null;
        public ButtonControl leftButton => null;
        public ButtonControl rightButton => null;
        public ButtonControl middleButton => null;
        public Vector2Control position => null;
        public Vector2Control delta => null;
        public Vector2Control scroll => null;
    }

    public class Gamepad : InputDevice
    {
        public static Gamepad current => null;
        public StickControl leftStick => null;
        public StickControl rightStick => null;
        public ButtonControl buttonSouth => null;
        public ButtonControl buttonNorth => null;
        public ButtonControl buttonEast => null;
        public ButtonControl buttonWest => null;
        public ButtonControl startButton => null;
        public ButtonControl leftTrigger => null;
        public ButtonControl rightTrigger => null;
        public void SetMotorSpeeds(float lowFrequency, float highFrequency) { }
    }

    public enum InputActionPhase { Disabled, Waiting, Started, Performed, Canceled }
    public enum InputActionType { Value, Button, PassThrough }

    public sealed class InputAction
    {
        public InputAction(string name = null, InputActionType type = default, string binding = null, string interactions = null, string processors = null, string expectedControlType = null) { }
        public string name => "";
        public bool enabled => false;
        public InputActionPhase phase => InputActionPhase.Waiting;
        public event System.Action<CallbackContext> started;
        public event System.Action<CallbackContext> performed;
        public event System.Action<CallbackContext> canceled;
        public void Enable() { }
        public void Disable() { }
        public TValue ReadValue<TValue>() where TValue : struct => default;
        public bool IsPressed() => false;
        public bool WasPressedThisFrame() => false;
        public bool WasReleasedThisFrame() => false;
        public bool WasPerformedThisFrame() => false;
        public InputActionSetupExtensions.BindingSyntax AddBinding(string path, string interactions = null, string processors = null, string groups = null) => default;

        public struct CallbackContext
        {
            public InputAction action => null;
            public InputActionPhase phase => InputActionPhase.Performed;
            public bool started => false;
            public bool performed => false;
            public bool canceled => false;
            public TValue ReadValue<TValue>() where TValue : struct => default;
            public bool ReadValueAsButton() => false;
        }
    }

    public static class InputActionSetupExtensions
    {
        public struct BindingSyntax { }
    }

    public sealed class InputActionReference : UnityEngine.ScriptableObject { public InputAction action => null; }

    public sealed class InputActionAsset : UnityEngine.ScriptableObject
    {
        public InputAction FindAction(string actionNameOrId, bool throwIfNotFound = false) => null;
        public void Enable() { }
        public void Disable() { }
    }

    public class InputValue
    {
        public TValue Get<TValue>() where TValue : struct => default;
        public object Get() => null;
        public bool isPressed => false;
    }

    public class PlayerInput : UnityEngine.MonoBehaviour
    {
        public InputActionAsset actions { get; set; }
        public string currentControlScheme => "";
        public void SwitchCurrentActionMap(string mapNameOrId) { }
    }
}

namespace UnityEngine.InputSystem.Controls
{
    public class ButtonControl : UnityEngine.InputSystem.InputControl<float>
    {
        public bool isPressed => false;
        public bool wasPressedThisFrame => false;
        public bool wasReleasedThisFrame => false;
    }
    public class KeyControl : ButtonControl { public UnityEngine.InputSystem.Key keyCode => default; }
    public class Vector2Control : UnityEngine.InputSystem.InputControl<UnityEngine.Vector2>
    {
        public UnityEngine.InputSystem.Controls.AxisControl x => null;
        public UnityEngine.InputSystem.Controls.AxisControl y => null;
    }
    public class StickControl : Vector2Control
    {
        public ButtonControl up => null;
        public ButtonControl down => null;
        public ButtonControl left => null;
        public ButtonControl right => null;
    }
    public class AxisControl : UnityEngine.InputSystem.InputControl<float> { }
}
