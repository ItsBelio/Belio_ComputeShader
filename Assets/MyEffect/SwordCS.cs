using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SwordCS : MonoBehaviour
{
    public struct Data
    {
        public Matrix4x4 TRS;
        public float RotSpeed;
        public float YMoveSpeed;
        public float fadeSet;

    }
    public GameObject[] Perfabs;
    public ComputeShader SwordComputeShader;
    public float Scale;
    public float maxRotatoSpeed = 5;
    public float maxMoveSpeed=3;
    public float maxFadeSpeed=1;
    public int[] DrawCount;
    public int allInstance = 0;
    private Material[] MeshMeterials;
    private Data[][] instances;
    private Mesh[] meshs;
    private Bounds[] meshBounds;
    private Camera MainCamera;
    public Vector3Int instanceExtents;
    public Vector3 instanceCenter;
    private Bounds MainBounds;
    private ComputeBuffer[] NOCS_Input;
    private ComputeBuffer[] CS_Input;
    private ComputeBuffer[] argsBuffers;
    private uint[][] argsArrs;
    private MaterialPropertyBlock[] mpbs;
    private int Kernel;
    // Start is called before the first frame update
    void Start()
    {
        if (SwordComputeShader != null)
            Kernel = SwordComputeShader.FindKernel("CSMain");
        argsArrs = new uint[Perfabs.Length][];
        mpbs = new MaterialPropertyBlock[Perfabs.Length];
        NOCS_Input = new ComputeBuffer[Perfabs.Length];
        CS_Input = new ComputeBuffer[Perfabs.Length];
        instances = new Data[Perfabs.Length][];
        MainBounds = new Bounds(instanceCenter, instanceExtents);
        MainCamera = Camera.main;
        MeshMeterials = new Material[Perfabs.Length];
        meshs = new Mesh[Perfabs.Length];
        meshBounds = new Bounds[Perfabs.Length];
        argsBuffers = new ComputeBuffer[Perfabs.Length];
        for (int i = 0; i < Perfabs.Length; i++)
        {
            var mr = Perfabs[i].transform.GetComponent<MeshRenderer>();
            var mf = Perfabs[i].transform.GetComponent<MeshFilter>();
            MeshMeterials[i] = mr.sharedMaterial;
            meshs[i] = mf.sharedMesh;
            meshBounds[i] = meshs[i].bounds;
            argsArrs[i] = new uint[5] { 0, 0, 0, 0, 0 };
            argsArrs[i][0] = meshs[i].GetIndexCount(0);
            argsArrs[i][1] = (uint)DrawCount[i];
            argsArrs[i][2] = meshs[i].GetIndexStart(0);
            argsArrs[i][3] = meshs[i].GetBaseVertex(0);
            argsArrs[i][4] = 0;
            argsBuffers[i] = new ComputeBuffer(5, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
            argsBuffers[i].SetData(argsArrs[i]);
        }
        foreach (var item in DrawCount)
        {
            allInstance += item;
        }
        if (SwordComputeShader == null)
        {
            for (int i = 0; i < 5; i++)
            {
                instances[i] = new Data[DrawCount[i]];
                instances[i] = RandomGenerateInstance(DrawCount[i], instanceExtents);
                NOCS_Input[i] = new ComputeBuffer(DrawCount[i], sizeof(float) * 19);
                NOCS_Input[i].SetData(instances[i]);
                mpbs[i] = new MaterialPropertyBlock();
                mpbs[i].SetBuffer("input", NOCS_Input[i]);
            }
        }
        else
        {
            for (int i = 0; i < 5; i++)
            {
                instances[i] = new Data[DrawCount[i]];
                instances[i] = RandomGenerateInstance(DrawCount[i], instanceExtents);
                NOCS_Input[i] = new ComputeBuffer(DrawCount[i], sizeof(float) * 19);
                NOCS_Input[i].SetData(instances[i]);
                CS_Input[i] = new ComputeBuffer(DrawCount[i], sizeof(float) * 19, ComputeBufferType.Append);
                mpbs[i] = new MaterialPropertyBlock();
                mpbs[i].SetBuffer("input", CS_Input[i]);
            }
        }

    }

    private Data[] RandomGenerateInstance(int instanceCount, Vector3Int instanceExtents)
    {
        var instance = new Data[instanceCount];
        var cameraPos = MainCamera.transform.position;
        for (int i = 0; i < instanceCount; i++)
        {
            var pos = new Vector3(
                cameraPos.x + Random.Range(-instanceExtents.x, instanceExtents.x),
                cameraPos.y + Random.Range(-instanceExtents.y, instanceExtents.y),
                cameraPos.z + Random.Range(-instanceExtents.z, instanceExtents.z));
            var r = Quaternion.Euler(90, 0, Random.Range(0, 180));
            var s = Vector3.one * Scale;
            instance[i].TRS = Matrix4x4.TRS(pos, r, s);//构建旋转矩阵
            instance[i].RotSpeed = Random.Range(-maxRotatoSpeed, maxRotatoSpeed);
            instance[i].YMoveSpeed=Random.Range(-maxMoveSpeed,maxMoveSpeed);
            instance[i].fadeSet=Random.Range(-maxFadeSpeed,maxFadeSpeed);;
        }
        return instance;
    }

    // Update is called once per frame
    void Update()
    {
        if (SwordComputeShader != null)
        {
            for (int i = 0; i < 5; i++)
            {
                SwordComputeShader.SetBuffer(Kernel, "data", NOCS_Input[i]);
                CS_Input[i].SetCounterValue(0);
                SwordComputeShader.SetBuffer(Kernel, "Res", CS_Input[i]);
                SwordComputeShader.SetInt("Count",DrawCount[i]);
                SwordComputeShader.SetVectorArray("plane", PlaneTool.Camera_Plane(MainCamera));
                int groupThread=DrawCount[i]/256;
                if(DrawCount[i]%256!=0) ++groupThread;
                SwordComputeShader.Dispatch(Kernel, groupThread, 1, 1);
                ComputeBuffer.CopyCount(CS_Input[i], argsBuffers[i], sizeof(uint));
                Graphics.DrawMeshInstancedIndirect(
                                meshs[i],
                                0,
                                MeshMeterials[i],
                                MainBounds,
                                argsBuffers[i],
                                0,
                                mpbs[i]);
            }
        }
        else
        {
            Graphics.DrawMeshInstancedIndirect(
                                meshs[0],
                                0,
                                MeshMeterials[0],
                                MainBounds,
                                argsBuffers[0],
                                0,
                                mpbs[0]);
            Graphics.DrawMeshInstancedIndirect(
                meshs[1],
                0,
                MeshMeterials[1],
                MainBounds,
                argsBuffers[1],
                0,
                mpbs[1]);
            Graphics.DrawMeshInstancedIndirect(
                meshs[2],
                0,
                MeshMeterials[2],
                MainBounds,
                argsBuffers[2],
                0,
                mpbs[2]);
            Graphics.DrawMeshInstancedIndirect(
                meshs[3],
                0,
                MeshMeterials[3],
                MainBounds,
                argsBuffers[3],
                0,
                mpbs[3]);
            Graphics.DrawMeshInstancedIndirect(
                meshs[4],
                0,
                MeshMeterials[4],
                MainBounds,
                argsBuffers[4],
                0,
                mpbs[4]);
        }
    }
    private void OnDisable()
    {
        for (int i = 0; i < 5; i++)
        {
            NOCS_Input[i]?.Release();
            argsBuffers[i]?.Release();
            CS_Input[i]?.Release();
        }
    }
}
