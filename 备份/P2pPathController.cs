using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using GameEditor.Config;
using Sirenix.OdinInspector;
using TCFramework;
using TransformUtils;
using UnityEngine;
using System.IO;
using Sirenix.Utilities;
using Input = UnityEngine.Input;
using GameModel = GameEditor.GameModel;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.ShaderKeywordFilter;
using MapPutEditorEd;
using Event = MapPutEditorEd.Event;

namespace MapPutEditor
{
    public class P2pPathController : MonoBehaviour
    {
        private Dictionary<int, ConfigP2p_Path> _cfgList;
        private Dictionary<int, ConfigP2p_Path_Model_Group> _modelGroups;

        private Dictionary<int, ConfigNpc_Base> _npcBases;

        private Transform _pointRoot; // 路点节点

        private Transform _extraBehaviorRoot; // 额外行为节点

        private Transform _modelRoot; // npc模型节点


        [HideInInspector] public ConfigP2p_Path cfg;

        private readonly Queue<TranslationGizmo> m_GameHandlePools = new Queue<TranslationGizmo>();
    
        [LabelText("唯一标识ID"), ReadOnly] public int id;

        [LabelText("线路颜色"), HideLabel, VerticalGroup("Color")]
        public Color[] lineColor = { Color.green, Color.yellow, Color.magenta };

        [Button("更新颜色"), VerticalGroup("Color")]
        private void colorRefresh()
        {
            RefreshPointDrawLine();
        }

        [LabelText("注释")] public string annotation;

        [LabelText("baseId"), HorizontalGroup("baseInfo")]
        public int baseId;

        [LabelText("所在场景id"), HorizontalGroup("baseInfo")]
        public int mapId;

        [LabelText("最大容量"), HorizontalGroup("instInfo")]
        public int volume;

        [LabelText("间隔时间随机区间"), HorizontalGroup("instInfo")]
        public Vector2 intervalTime;

        #region -- 循环模式 --

        [LabelText("是否循环"), HideLabel, HorizontalGroup("loop")]
        public bool isLoop;

        [Title("循环类型"), EnumToggleButtons, HideLabel, ShowIf("isLoop"), HorizontalGroup("loop")]
        public LoopType _LoopType;

        [Title("动作播放状态"), EnumToggleButtons, HideLabel, HorizontalGroup("loop")]
        public AnimationLayer _animationLayer;

        #endregion


        [Button("编辑路点"), VerticalGroup("listInfo"), ShowIf("@isEditorList == 0")]
        private void EditorListInfo()
        {
            isEditorList = 1;
            StartEditorListInfo();
        }

        [LabelText("路径路点"), VerticalGroup("listInfo"), OnValueChanged("settingList")]
        public List<P2pPathPoint> list;

        private int tempListCount = 0; // 临时变量 用来判断是否通过操作editor对列表数据进行增删

        private void settingList()
        {
            // 只处理增加或者删除
            if (tempListCount == list.Count)
            {
                return;
            }

            Debug.Log("触发了长度改变");
            var off = Math.Abs(tempListCount - list.Count);
            RefreshPointList(tempListCount < list.Count, off);
        }


        private int isEditorList = 0;


        [Button("退出路点编辑"), VerticalGroup("listInfo"), ShowIf("@isEditorList == 1")]
        private void QuitEditorListInfo()
        {
            isEditorList = 0;
            EndEditorListInfo();
        }

        [LabelText("模型形象实例"), OnValueChanged("instGroupValueChanged")]
        public List<ModelGroup> instGroupList;

        private int tempGroupListCount = 0;

        private void instGroupValueChanged()
        {
            // 只处理增删
            if (tempGroupListCount == instGroupList.Count)
            {
                return;
            }

            RefreshInstGroupList(tempGroupListCount < instGroupList.Count);
        }


        [LabelText("额外行为"), OnValueChanged("extraBehaviorsChanged")]
        public List<ExtraBehavior> ExtraBehaviors;

        private int tempExtraBehaviorsCount = 0;

        private void extraBehaviorsChanged()
        {
            if (tempExtraBehaviorsCount == ExtraBehaviors.Count)
            {
                return;
            }

            var off = Math.Abs(tempExtraBehaviorsCount - ExtraBehaviors.Count);

            RefreshExtraBehavior(tempExtraBehaviorsCount < ExtraBehaviors.Count, off);
        }


        [LabelText("修改Id"), HorizontalGroup("idEdit")]
        public int editId;

        [Button("保存"), HorizontalGroup("idEdit")]
        private void ApplyIdEdit()
        {
            if (editId == _lastId) return;
            // 检测编辑的id是否能从数据中心获取
            if (_cfgList.ContainsKey(editId))
            {
                Debug.LogError($" 配置表中已存在id :  {editId}");
                return;
            }

            cfg.id = editId;
            EditorConfigID(editId);
        }

        private void Awake()
        {
            MapPutMessageManager.instance.Regist(Event.Editor_Quit_P2pPathSet, () =>
            {
                isEditorList = 0;
                EndEditorListInfo();
            });

            var _g1 = new GameObject("PointRoot");
            _g1.transform.SetParent(transform);
            _g1.transform.localPosition = Vector3.zero;
            _pointRoot = _g1.transform;

            var _g2 = new GameObject("ExtraBehaviorRoot");
            _g2.transform.SetParent(transform);
            _g2.transform.localPosition = Vector3.zero;
            _extraBehaviorRoot = _g2.transform;

            var _g3 = new GameObject("ModelRoot");
            _g3.transform.SetParent(transform);
            _g3.transform.localPosition = Vector3.zero;
            _modelRoot = _g3.transform;

            InitMaterial();
        }

        private int _lastId;

        // 修改配置id
        public void EditorConfigID(int _id)
        {
            gameObject.name = _id.ToString();

            for (var i = 0; i < _pointGoList.Count; i++)
            {
                _pointGoList[i].name = $"{_id}_{i}";
            }

            id = _id;
        }

        public void InitController(ConfigP2p_Path _cfg, int _id, Dictionary<int, ConfigP2p_Path> cfgList,
            Dictionary<int, ConfigP2p_Path_Model_Group> modelGroups, Dictionary<int, ConfigNpc_Base> npcBases)
        {
            cfg = _cfg ?? (cfgList.TryGetValue(_id, out var value) ? value : new ConfigP2p_Path() { id = _id });
            _cfgList = cfgList;
            _modelGroups = modelGroups;
            _npcBases = npcBases;

            if (cfg != null)
            {
                id = cfg.id;
                _lastId = id;
                editId = id;
                annotation = cfg.annotation;
                baseId = cfg.base_id;
                mapId = cfg.map_id;
                volume = cfg.volume;

                if (cfg.is_loop != null)
                {
                    isLoop = cfg.is_loop[0] == "1";
                    _LoopType = cfg.is_loop.Length >= 2 && cfg.is_loop[1] == "1"   ? LoopType.逆向相连 : LoopType.首尾相连;
                    _animationLayer = cfg.is_loop.Length >= 3 && cfg.is_loop[2] == "1"  
                        ? AnimationLayer.整齐
                        : AnimationLayer.默认;
                }
                else
                {
                    isLoop = false;
                    _LoopType = LoopType.首尾相连;
                    _animationLayer = AnimationLayer.默认;
                }

                _pointGoList = new List<GameObject>();
                _behaviorList = new List<GameObject>();

                if (!string.IsNullOrEmpty(cfg.list))
                {
                    list = new List<P2pPathPoint>();

                    var ss = cfg.list.Split('|');
                    foreach (var s in ss)
                    {
                        if (string.IsNullOrEmpty(s))
                        {
                            continue;
                        }

                        var info = new P2pPathPoint(s, list.Count);
                        var go = GetPointObj();
                        go.name = $"{id}_{list.Count}";
                        go.transform.position = info.pos;
                        go.transform.SetParent(_pointRoot);
                        info.pointObj = go;
                        _pointGoList.Add(go);
                        // 为了反之初始化是调用到editor方法先自加
                        tempListCount = list.Count + 1;
                        list.Add(info);
                    }

                    RefreshPointDrawLine();
                }

                if (cfg.inst_group_list is { Length: > 0 })
                {
                    instGroupList = new List<ModelGroup>();
                    var index = 0;
                    foreach (var i in cfg.inst_group_list)
                    {
                        if (!_modelGroups.TryGetValue(i, out var groupCfg)) continue;
                        var modelGroup = new ModelGroup(groupCfg, _npcBases, index, CreateNpcShow, list,GetExtraBehavior);
                        tempGroupListCount++;
                        instGroupList.Add(modelGroup);
                        index++;
                    }
                }
                
                if (!string.IsNullOrEmpty(cfg.extra_behavior))
                {
                    ExtraBehaviors = new List<ExtraBehavior>();
                    tempExtraBehaviorsCount = 0;
                    var tempExtra = cfg.extra_behavior.Split('|');
                    foreach (var e in tempExtra)
                    {
                        if (string.IsNullOrEmpty(e))
                        {
                            continue;
                        }

                        var info = new ExtraBehavior(e, tempExtraBehaviorsCount, _npcBases, GetModelGroup, GetAnimationName,
                            GetPosThePointBubble2Index, RemovePointBubble2Index, RefreshPointDrawLine,GetAtNpcModels);
                        var go = info.type == 0 ? GetPointObj(Color.cyan) : GetPointObj(Color.gray);
                        go.name = $"behavior_{ExtraBehaviors.Count}";

                        switch (info.type)
                        {
                            case 0:
                                // 动作 先设定位置 ，在绑定父物体
                                go.transform.position = info.pos;
                                go.transform.SetParent(_extraBehaviorRoot);
                                break;
                            case 1:
                                go.transform.SetParent(_extraBehaviorRoot);
                                go.transform.localPosition = GetPosThePointBubble2Index(info.index - 1);
                                break;
                        }

                        SetBehaviorChileNode(go);
                        info.pointObj = go;
                        _behaviorList.Add(go);
                        tempExtraBehaviorsCount = ExtraBehaviors.Count + 1;
                        ExtraBehaviors.Add(info);
                    }

                    RefreshPointDrawLine();
                }
                
                if (cfg.intervalTime_timer is { Length: > 0 })
                {
                    var x = cfg.intervalTime_timer.Length >= 1 && int.TryParse(cfg.intervalTime_timer[0], out var start)
                        ? start
                        : 1;

                    var y = cfg.intervalTime_timer.Length >= 2 && int.TryParse(cfg.intervalTime_timer[1], out var end)
                        ? end
                        : 4;

                    intervalTime = new Vector2(x, y);
                }
                else
                {
                    intervalTime = new Vector2(1, 4);
                }
            }
            else
            {
                id = _id;
                editId = _id;
                _lastId = _id;
            }
        }

        public ConfigP2p_Path GetConfig()
        {
            cfg ??= new ConfigP2p_Path();
            cfg.id = id;
            cfg.annotation = annotation;
            var tempList = list.Aggregate("",
                (current, point) => current + $"{point.pos.x}:{point.pos.y}:{point.pos.z}:{point.actionType}|");
            cfg.list = tempList.TrimEnd('|');
            cfg.base_id = baseId;
            cfg.map_id = mapId;


            var loop1 = isLoop ? "1" : "0";
            var loopType = _LoopType == LoopType.首尾相连 ? "0" : "1";
            var animationLayer = _animationLayer == AnimationLayer.默认 ? "0" : "1";

            cfg.is_loop = new[] { loop1, loopType, animationLayer };

            cfg.volume = volume;
            cfg.intervalTime_timer = new[] { $"{intervalTime.x}", $"{intervalTime.y}" };
            var tempExtra = ExtraBehaviors.Aggregate("", (c, e) => c + e.GetValue() + "|");
            cfg.extra_behavior = tempExtra;
            var tempGroupList = new List<int>();
            foreach (var group in instGroupList)
            {
                group.GetValue(out var groupId);
                tempGroupList.Add(groupId);
            }

            cfg.inst_group_list = tempGroupList.ToArray();
            return cfg;
        }

        public Dictionary<int, ConfigP2p_Path_Model_Group> GetModelGroups()
        {
            var _tempPathModelGroups = new Dictionary<int, ConfigP2p_Path_Model_Group>();
            foreach (var group in instGroupList)
            {
                var groupCfg = group.GetValue(out var groupId);
                _tempPathModelGroups.Add(groupId,groupCfg);
            }
            return _tempPathModelGroups;
        }
        
        

        #region [[生成节点GameObject]]

        private GameObject _mouseGo;

        private List<GameObject> _pointGoList;

        private List<GameObject> _behaviorList;

        // 当前选中的point
        private PointBase _atSelectPoint;

        private void StartEditorListInfo()
        {
            _mouseGo = GetPointObj();
            _pointGoList ??= new List<GameObject>();
            _behaviorList ??= new List<GameObject>();
            MapPutMessageManager.instance.Send(Event.Editor_On_P2pPathSet);
        }

        private void EndEditorListInfo()
        {
            Destroy(_mouseGo);
        }

        private int roleMask;

        private void Start()
        {
            roleMask = LayerMask.GetMask("Role", "Ignore Raycast");
        }

        private void Update()
        {
            if (isEditorList == 0 || _mouseGo == null)
            {
                return;
            }

            if (Input.GetKey(KeyCode.LeftControl) && Input.GetKey(KeyCode.LeftAlt))
            {
                return;
            }


            UpdateCreatePoint();
            UpdateCreateExtraBehaviorPoint();
            UpdateMovePoint();
            UpdatePointPos();
        }

        /// <summary>
        ///  通过点击生成item
        /// </summary>
        private void UpdateCreatePoint()
        {
            if (Input.GetKey(KeyCode.LeftControl))
            {
                // 对象跟随鼠标移动
                SetMouseGoColor(Color.blue);
                _mouseGo.gameObject.SetActive(true);
                if (Camera.main != null)
                {
                    var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
                    if (Physics.Raycast(ray, out var hit, int.MaxValue, ~roleMask))
                    {
                        _mouseGo.transform.position = hit.point;
                    }
                }

                if (Input.GetMouseButtonDown(0))
                {
                    // 生成标记点实体
                    var go = GetPointObj();
                    var position = _mouseGo.transform.position;
                    go.transform.position = position;
                    go.transform.SetParent(_pointRoot);
                    // 将位置数据记录到list中
                    var index = list.Count;
                    go.name = $"{id}_{index}";
                    _pointGoList.Add(go);
                    var point = new P2pPathPoint(position, 2, index)
                    {
                        pointObj = go
                    };
                    tempListCount = list.Count + 1;
                    list.Add(point);
                    RefreshPointDrawLine();
                }
            }

            if (Input.GetKeyUp(KeyCode.LeftControl))
            {
                _mouseGo.gameObject.SetActive(false);
            }
        }

        /// <summary>
        /// 操作item移动更改数据
        /// </summary>
        private void UpdateMovePoint()
        {
            if (!Input.GetMouseButtonDown(0) || Input.GetKey(KeyCode.LeftControl) ||
                Input.GetKey(KeyCode.LeftAlt)) return;
            if (Camera.main == null) return;
            var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (!Physics.Raycast(ray, out var hit, int.MaxValue, roleMask)) return;
            // 获取选中的 GameObject
            var point = GetPointBaseInfo2Go(hit.transform.gameObject);
            if (point != null)
            {
                EnterPointMove(point);
            }
        }

        /// <summary>
        /// 生成附加行为操作点
        /// </summary>
        private void UpdateCreateExtraBehaviorPoint()
        {
            if (Input.GetKey(KeyCode.LeftAlt))
            {
                SetMouseGoColor(Color.cyan);
                _mouseGo.gameObject.SetActive(true);
                if (Camera.main != null)
                {
                    var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
                    if (Physics.Raycast(ray, out var hit, int.MaxValue, ~roleMask))
                    {
                        _mouseGo.transform.position = hit.point;
                    }
                }

                if (Input.GetMouseButtonDown(0))
                {
                    // 生成标记点实体
                    var go = GetPointObj(Color.cyan);
                    var position = _mouseGo.transform.position;
                    go.transform.position = position;
                    go.transform.SetParent(_extraBehaviorRoot);
                    go.name = $"behavior_{ExtraBehaviors.Count}";
                    // 将位置记录到配置中
                    var index = GetPointIndex2Pos(position) + 1; // 存储到lua配置中加一
                    var behavior = new ExtraBehavior(position, index, tempExtraBehaviorsCount, _npcBases, GetModelGroup,
                        GetAnimationName, GetPosThePointBubble2Index, RemovePointBubble2Index, RefreshPointDrawLine,GetAtNpcModels);
                    tempExtraBehaviorsCount = ExtraBehaviors.Count + 1;
                    _behaviorList.Add(go);
                    SetBehaviorChileNode(go);
                    behavior.pointObj = go;
                    ExtraBehaviors.Add(behavior);
                    RefreshPointDrawLine();
                }
            }

            if (Input.GetKeyUp(KeyCode.LeftAlt))
            {
                _mouseGo.gameObject.SetActive(false);
            }
        }

        private PointBase GetPointBaseInfo2Go(GameObject go)
        {
            var point = GetInfo2Go(go);
            var behavior = GetInfo2BehaviorGo(go);

            if (point != null)
            {
                return point;
            }
            else if (behavior != null)
            {
                return behavior;
            }

            return null;
        }

        // 通过go获取数据
        private P2pPathPoint GetInfo2Go(GameObject go)
        {
            var index = -1;
            for (var i = 0; i < _pointGoList.Count; i++)
            {
                if (go != _pointGoList[i]) continue;
                index = i;
                break;
            }

            Debug.Log("获取到的index是：" + index);
            if (index == -1) return null;
            var info = list[index];
            return info;
        }

        // 通过go获取行为数据
        private ExtraBehavior GetInfo2BehaviorGo(GameObject go)
        {
            var index = -1;
            for (var i = 0; i < _behaviorList.Count; i++)
            {
                if (go != _behaviorList[i]) continue;
                index = i;
                break;
            }

            Debug.Log("获取到的行为节点为:" + index);
            if (index == -1) return null;
            var info = ExtraBehaviors[index];
            return info;
        }


        // 进入调试模式
        private void EnterPointMove(PointBase point)
        {
            if (_atSelectPoint != null)
            {
                // 清楚原有的选择
                AddGameHandlesPool(_atSelectPoint.gameHandles);
                _atSelectPoint.gameHandles = null;
            }

            Debug.Log("点击到了路点！！！！！" + point.pointObj.name);
            point.gameHandles = PoolGameHandlesGet();
            GameHandles.ReplaceAttachTranslation(point.gameHandles.transform, point.pointObj.transform);
            point.gameHandles.gameObject.SetActive(true);

            EditorGUIUtility.PingObject(point.pointObj.transform);
            Selection.activeObject = point.pointObj;
            var position = point.pointObj.transform.position; // 当前路点的位置
            var matrix4x4 = Matrix4x4.TRS(position, point.pointObj.transform.rotation,
                Vector3.zero);
            point.matrix4x4 = matrix4x4;
            _lastPos = position;
            _atSelectPoint = point;
        }


        // 从对象池中获取游戏柄
        private TranslationGizmo PoolGameHandlesGet()
        {
            return m_GameHandlePools.Count > 0 ? m_GameHandlePools.Dequeue() : GameHandles.CreateTranslation();
        }

        // 选中目标更新时调用 ，及时响应
        private void AddGameHandlesPool(TranslationGizmo translationGizmo)
        {
            translationGizmo.gameObject.SetActive(false);
            m_GameHandlePools.Enqueue(translationGizmo);
        }

        private Vector3 _lastPos; // 记录改变前的位置

        /// <summary>
        /// 更新当前选中的路点位置
        /// </summary>
        private void UpdatePointPos()
        {
            if (_atSelectPoint == null)
            {
                return;
            }

            if (_lastPos != _atSelectPoint.pointObj.transform.position)
            {
                // 更新配置
                var position = _atSelectPoint.pointObj.transform.position;
                _atSelectPoint.pos = position;
                // 刷新射线
                RefreshPointDrawLine();
                // 更新位置
                _lastPos = position;
            }
        }

        /// <summary>
        /// 列表长度变更刷新
        /// </summary>
        private void RefreshPointList(bool isAdd, int off)
        {
            if (isAdd)
            {
                // 增加或者插入            
                for (var i = 0; i < off; i++)
                {
                    var go = GetPointObj();
                    go.transform.SetParent(_pointRoot);
                    _pointGoList.Add(go);
                }
            }
            else
            {
                Debug.Log($"准备删除的数据长度 ： {off} ");
                // 删除
                for (var i = 0; i < off; i++)
                {
                    var go = _pointGoList[i];
                    _pointGoList.Remove(go);
                    Destroy(go);
                }

                if (_atSelectPoint != null)
                {
                    AddGameHandlesPool(_atSelectPoint.gameHandles);
                    _atSelectPoint = null;
                }
                
                Debug.Log($"删除后的数据长度 ： {_pointGoList.Count} ");
                
            }

            Debug.Log($"数据长度: {list.Count} ---- {_pointGoList.Count}");
            // 数据对齐
            for (var i = 0; i < list.Count; i++)
            {
                Debug.Log($"i---------------: {i}");
                _pointGoList[i].name = $"{id}_{i}";
                _pointGoList[i].transform.position = list[i].pos;
                list[i].pointObj = _pointGoList[i];
                list[i].index = i;
            }

            tempListCount = list.Count;
        }


        private const string _materialFilePath = "Assets/Editor/TempMaterial/default_material.mat";

        private Material ma;

        private void InitMaterial()
        {
            ma = AssetDatabase.LoadAssetAtPath<Material>(_materialFilePath);
        }

        /// <summary>
        /// 创建连线
        /// </summary>
        private void RefreshPointDrawLine()
        {
            if (_pointGoList.Count < 1)
            {
                return;
            }

            for (var i = 0; i < _pointGoList.Count - 1; i++)
            {
                var lien = _pointGoList[i].AddMissingComponent<LineRenderer>();
                lien.startWidth = 0.3f;
                lien.endWidth = 0.3f;
                lien.material = ma;
                lien.material.color = lineColor[0];
                lien.SetPosition(0, _pointGoList[i].transform.position);
                lien.SetPosition(1, _pointGoList[i + 1].transform.position);
            }

            for (var i = 0; i < _behaviorList.Count; i++)
            {
                var behaviorInfo = ExtraBehaviors[i];
                var startGo = _behaviorList[i].transform.GetChild(0);
                var endGo = _behaviorList[i].transform.GetChild(1);
                if (behaviorInfo.type == 1)
                {
                    startGo.gameObject.SetActive(false);
                    endGo.gameObject.SetActive(false);
                    continue; // 如果是仅气泡的则不进行处理
                }

                startGo.gameObject.SetActive(true);
                endGo.gameObject.SetActive(true);
                var startIndex = behaviorInfo.index - 1;
                var endIndex = startIndex + 1;

                var startLine = startGo.gameObject.AddMissingComponent<LineRenderer>();
                startLine.startWidth = 0.2f;
                startLine.endWidth = 0.2f;
                startLine.material = ma;
                startLine.material.color = lineColor[1];
                startLine.SetPosition(0, _behaviorList[i].transform.GetChild(0).position);
                startLine.SetPosition(1, _pointGoList[startIndex].transform.position);

                var endLine = endGo.gameObject.AddMissingComponent<LineRenderer>();
                endLine.startWidth = 0.2f;
                endLine.endWidth = 0.2f;
                endLine.material = ma;
                endLine.material.color = lineColor[2];
                endLine.SetPosition(0, _behaviorList[i].transform.GetChild(1).position);
                endLine.SetPosition(1, _pointGoList[endIndex].transform.position);
            }
        }

        /// <summary>
        /// 通过位置获取相对最近的路点作为父节点
        /// </summary>
        /// <returns></returns>
        private int GetPointIndex2Pos(Vector3 atPos)
        {
            var nearestIndex = -1;
            var nearestDistance = Mathf.Infinity;
            for (var i = 0; i < list.Count; i++)
            {
                var _pos = list[i].pos;
                var distance = Vector3.Distance(atPos, _pos);
                if (!(distance < nearestDistance)) continue;
                nearestIndex = i;
                nearestDistance = distance;
            }

            return nearestIndex;
        }

        // 设置行为节点子物体
        private void SetBehaviorChileNode(GameObject go)
        {
            var startGo = new GameObject("startNode");
            startGo.transform.SetParent(go.transform);
            startGo.transform.localPosition = Vector3.zero;

            var endGo = new GameObject("endNode");
            endGo.transform.SetParent(go.transform);
            endGo.transform.localPosition = Vector3.zero;
        }


        // 设置鼠标预生成go的颜色
        private void SetMouseGoColor(Color c)
        {
            if (_mouseGo == null)
            {
                return;
            }

            var re = _mouseGo.GetComponent<Renderer>();
            re.material.color = c;
        }


        private GameObject GetPointObj()
        {
            return GetPointObj(Color.blue);
        }

        // 获取go
        private GameObject GetPointObj(Color c)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.SetLayer(20);
            var re = go.GetComponent<Renderer>();
            re.material = ma;
            re.material.color = c;
            return go;
        }

        private GameObject GetTempNpcModel()
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            go.SetLayer(20);
            var re = go.GetComponent<Renderer>();
            re.material = ma;
            re.material.color = Color.blue;
            return go;
        }

        #endregion

        #region [[npc列表刷新]]

        /// <summary>
        /// npc列表长度改变
        /// </summary>
        /// <param name="isAdd"></param>
        private void RefreshInstGroupList(bool isAdd)
        {
            if (!isAdd) return;
            // 移除临时数据
            instGroupList.Remove(instGroupList[^1]);
            var tempId = id * 1000 + instGroupList.Count;
            ModelGroup group;
            if (_modelGroups.TryGetValue(tempId, out var g))
            {
                group = new ModelGroup(g, _npcBases, instGroupList.Count, CreateNpcShow, list,GetExtraBehavior);
            }
            else
            {
                var tempGroupCfg = new ConfigP2p_Path_Model_Group
                {
                    id = tempId,
                    annotation = "新增配置",
                    alignment_type = 0,
                    constraint_type = new[] { "0", "1" },
                    spacing = new[] { "0", "0" },
                };
                group = new ModelGroup(tempGroupCfg, _npcBases, instGroupList.Count, CreateNpcShow, list,GetExtraBehavior);
            }

            instGroupList.Add(group);
        }

        private readonly List<GameObject> gos = new();

        // 生成npc模型显示
        private List<GameObject> CreateNpcShow(IEnumerable<NpcBaseInfo> infos)
        {
            foreach (var go in gos)
            {
                Destroy(go);
            }

            gos.Clear();
            foreach (var npc in infos.Where(npc => npc.cfgState != 0))
            {
                var go = CreateNpcModel(npc.model, out var isLoadEnd);
                if (!isLoadEnd)
                {
                    Debug.LogError($"模型加载失败 {npc.id} , 使用胶囊体替代！");
                }

                gos.Add(go);
            }

            return gos;
        }

        private GameObject CreateNpcModel(string model, out bool isLoadEnd)
        {
            var obj = GetTempNpcModel();


            if (string.IsNullOrEmpty(model))
            {
                isLoadEnd = false;
                return obj;
            }

            if (!MapPutEditor.instance.configModels.TryGetValue(model, out var config))
            {
                isLoadEnd = false;
                return obj;
            }

            if (config.model == "empty")
            {
                isLoadEnd = false;
                return obj;
            }

            var path = string.Format(GameModel.ModelPath, config.path, config.model);

            try
            {
                var tempObj = Instantiate(AssetDatabase.LoadAssetAtPath<GameObject>(path));
                Destroy(obj);
                obj = tempObj;
            }
            catch (Exception)
            {
                Debug.LogError($"加载模型{path}失败");
                isLoadEnd = false;
                return obj;
            }

            // 加载模型挂件
            try
            {
                if (config.parts is { Length: > 1 } && config.parts[0].Length > 0)
                {
                    foreach (var t in config.parts)
                    {
                        if (!MapPutEditor.instance.configModelParts.TryGetValue(t, out var configModelPart))
                        {
                            Debug.LogError($"model.cfg id = {config.id}中 part = {t}字段在modelPart.cfg中查找不到");
                            continue;
                        }

                        var partPath = string.Format(GameModel.ModelPath, configModelPart.path, t);
                        var part = Instantiate(AssetDatabase.LoadAssetAtPath<GameObject>(partPath), obj.transform,
                            true);
                        part.name = configModelPart.id;
                    }

                    foreach (var part in config.parts)
                    {
                        var partGo = obj.transform.Find(part)?.gameObject;
                        if (partGo)
                        {
                            partGo.GetComponent<UnitBoneRevert>()?.GetBoneLayer();
                        }
                    }
                }
            }
            catch (Exception)
            {
                Debug.LogError($"model.cfg id = {model}中的 part加载失败");
            }

            obj.transform.localScale = config.scale;
            obj.transform.SetParent(_modelRoot); //设置在第一个父物体上
            obj.transform.localPosition = Vector3.zero;
            obj.transform.LookAt(list[1].pointObj.transform); // 设置 朝向第二个路点

            isLoadEnd = true;
            return obj;
        }

        private List<GameObject> GetAtNpcModels()
        {
            return gos;
        }

        private List<ExtraBehavior> GetExtraBehavior()
        {
            return ExtraBehaviors;
        }
        
        #endregion

        #region [[附加行为列表]]

        // 附加行为列表长度变更
        private void RefreshExtraBehavior(bool isAdd, int off)
        {
            if (isAdd)
            {
                // 增加插入
                for (var i = 0; i < off; i++)
                {
                    var go = GetPointObj(Color.cyan);
                    SetBehaviorChileNode(go);
                    go.transform.SetParent(_extraBehaviorRoot);
                    _behaviorList.Add(go);
                }
            }
            else
            {
                // 删除
                for (var i = 0; i < off; i++)
                {
                    var go = _behaviorList[i];
                    _behaviorList.Remove(go);
                    Destroy(go);
                }

                if (_atSelectPoint != null)
                {
                    AddGameHandlesPool(_atSelectPoint.gameHandles);
                    _atSelectPoint = null;
                }
            }

            // 数据对齐
            for (var i = 0; i < _behaviorList.Count; i++)
            {
                _behaviorList[i].name = $"behavior_{i}";
                _behaviorList[i].transform.position = ExtraBehaviors[i].pos;
                ExtraBehaviors[i].pointObj = _behaviorList[i];
                ExtraBehaviors[i].index = ExtraBehaviors[i].index == 0
                    ? GetPointIndex2Pos(_behaviorList[i].transform.position)
                    : ExtraBehaviors[i].index;
            }
            
            tempExtraBehaviorsCount = ExtraBehaviors.Count;
        }

        // 获取npc模型的相关动作
        private Dictionary<string, bool> GetAnimationName(out Dictionary<string, List<int>> animation2NpcBaseId,
            out List<int> npcBaseList)
        {
            // 获取当前所有的npcBaseId
            var npcIdList = new Dictionary<int, string>();
            if (instGroupList == null || instGroupList.Count == 0)
            {
                animation2NpcBaseId = new Dictionary<string, List<int>>();
                npcBaseList = new List<int>();
                return new Dictionary<string, bool>();
            }

            foreach (var baseInfo in from @group in instGroupList
                     from baseInfo in @group.npcList
                     where !npcIdList.ContainsKey(baseInfo.id)
                     select baseInfo)
            {
                npcIdList.Add(baseInfo.id, baseInfo.model);
            }

            npcBaseList = npcIdList.Keys.ToList();

            animation2NpcBaseId = new Dictionary<string, List<int>>();

            foreach (var l in npcIdList)
            {
                var dic = GetAnimation2BaseId(l.Value);

                foreach (var s in dic.Select(k2v => $"{k2v.Key}：{k2v.Value}"))
                {
                    if (animation2NpcBaseId.TryGetValue(s, out var baseNpcIds))
                    {
                        baseNpcIds.Add(l.Key);
                    }
                    else
                    {
                        var baseNpcId = new List<int> { l.Key };
                        animation2NpcBaseId.Add(s, baseNpcId);
                    }
                }
            }

            var animation2NpcLocal = new Dictionary<string, bool>();
            // 判断动作是否是所有npc支持
            foreach (var npcIds in animation2NpcBaseId)
            {
                var isMax = npcIdList.Keys.Count <= npcIds.Value.Count;
                animation2NpcLocal.Add(npcIds.Key, isMax);
            }

            return animation2NpcLocal;
        }

        private const string animationRootPath = "Assets/Res/Model/Animation/Npc/";

        // 根据模型获取动作
        private Dictionary<string, string> GetAnimation2BaseId(string modelName)
        {
            var modelCfg = CfgUtil.GetObjects<ConfigModel>();
            var anim = "";
            foreach (var item in modelCfg.Where(item => modelName == item.id))
            {
                anim = item.animation;
                break;
            }

            var animations = CfgUtil.GetObjects<ConfigCommon_Animation>();
            var animationList = new Dictionary<string, string>();
            var filePath = animationRootPath + anim;

            if (!Directory.Exists(filePath)) return animationList;
            var files = Directory.GetFiles(filePath, "*anim", SearchOption.TopDirectoryOnly);
            foreach (var file in files)
            {
                // 记录名字
                var animName = file.Replace("\\", "/").Replace(filePath + "/", "").Replace(".anim", "");
                foreach (var a in animations.Where(a => a.name == animName))
                {
                    animationList.Add(a.desc, animName);
                }
            }

            return animationList;
        }

        private Dictionary<int, int> _pointBubbleNumberDic;

        private ModelGroup GetModelGroup(int groupId)
        {
            var data = instGroupList.FirstOrDefault(g => g.id == groupId);
            return data;
        }

        // 当附加行为从动作变换为仅气泡
        private Vector3 GetPosThePointBubble2Index(int index)
        {
            index = index < 0 ? 0 : index;
            _pointBubbleNumberDic ??= new Dictionary<int, int>();
            if (!_pointBubbleNumberDic.TryGetValue(index, out var number))
            {
                _pointBubbleNumberDic.Add(index, 1);
                number = 0;
            }

            number++;
            var tempPos = list[index].pointObj.transform.localPosition;
            var y = tempPos.y + (number * 1.1f);
            var v3 = new Vector3(tempPos.x, y, tempPos.z);
            return v3;
        }

        // 当附加行为从仅气泡变换为动作
        private void RemovePointBubble2Index(int index)
        {
            index = index < 0 ? 0 : index;
            _pointBubbleNumberDic ??= new Dictionary<int, int>();
            if (!_pointBubbleNumberDic.ContainsKey(index)) return;
            _pointBubbleNumberDic[index]--;
            RefreshPointDrawLine();
        }

        #endregion

        private void OnEnable()
        {
            if (_atSelectPoint != null)
            {
                AddGameHandlesPool(_atSelectPoint.gameHandles);
                _atSelectPoint = null;
            }
        }

        private void OnDestroy()
        {
            if (_atSelectPoint != null)
            {
                AddGameHandlesPool(_atSelectPoint.gameHandles);
                _atSelectPoint = null;
            }

            _pointGoList.Clear();
            _pointGoList = null;

            _behaviorList.Clear();
            _behaviorList = null;
        }
    }


    public class PointBase
    {
        [LabelText("坐标"), ReadOnly] public Vector3 pos;

        [HideInInspector] public TranslationGizmo gameHandles; // 移动坐标系

        [HideInInspector] public GameObject pointObj;

        [HideInInspector] public Matrix4x4 matrix4x4;
    }

    [Serializable]
    // 路径标记点
    public class P2pPathPoint : PointBase
    {
        private static string[] actionTypeArray = new[] { "1：小跑", "2：走路", "3：疾跑" };

        [LabelText("速度动作"), HorizontalGroup("type2index"), OnValueChanged("actionTypeChanged"),
         ValueDropdown("actionTypeArray")]
        public string actionTypeStr;

        private void actionTypeChanged()
        {
            for (var i = 0; i < actionTypeArray.Length; i++)
            {
                if (actionTypeStr == actionTypeArray[i])
                {
                    actionType = i + 1;
                }
            }
        }

        [HideInInspector] public int actionType;

        [LabelText("路点下标"), HorizontalGroup("type2index")]
        public int index;

        private P2pPathPoint()
        {
        }

        public P2pPathPoint(string v, int index)
        {
            var ss = v.Split(':');
            var x = ss.Length >= 1 ? Float2Vec(ss[0]) : 0;
            var y = ss.Length >= 2 ? Float2Vec(ss[1]) : 0;
            var z = ss.Length >= 3 ? Float2Vec(ss[2]) : 0;
            var type = ss.Length >= 4 ? int.Parse(ss[3]) : 2;
            this.index = index;

            pos = new Vector3(x, y, z);
            actionType = type;
            actionTypeStr = actionTypeArray[type - 1];
        }

        public P2pPathPoint(Vector3 pos, int type, int index)
        {
            this.pos = pos;
            actionType = type;
            actionTypeStr = actionTypeArray[type - 1];
            this.index = index;
        }


        public static float Float2Vec(string v)
        {
            return float.TryParse(v, out var value) ? value : 0f;
        }
    }

    /// <summary>
    /// 额外行为
    /// </summary>
    [Serializable]
    public class ExtraBehavior : PointBase
    {
        private Dictionary<int, ConfigNpc_Base> _npcBases;

        public delegate Dictionary<string, bool> getAnimations(out Dictionary<string, List<int>> animation2NpcBase,
            out List<int> npcBaseList); // 模型动作更新回调
        
        public delegate ModelGroup getModelGroup(int id); // 模型动作更新回调

        private getAnimations _getAnimations; // 获取模型动作回调实例
        private getModelGroup _getModelGroup;

        public Func<List<GameObject>> _getNpcModelObjs;
        private readonly List<ModelGroup> _groupList;

        public delegate Vector3 getPointPos2Index(int index); // 获取相近路点回调

        private getPointPos2Index _getPointPos2Index; // 获取相近路点委托实例

        private Action<int> _removeBubble2Index; // 移除泡泡路点更新

        private Action _refreshLine; // 射线刷新


        private static string[] extraType = new[] { "0:分支播放动作", "1:仅气泡" };

        private static string[] weightType = new[] { "0:低", "1:中", "2:高" };

        [HideInInspector] public int type;
        [HideInInspector] public int weight;
        [HideInInspector] public string param;

        [LabelText("行为索引"), Readonly] public int thisIndex;

        [LabelText("路径路点索引"), OnValueChanged("indexChanged")]
        public int index;

        private void indexChanged()
        {
            if (!_isInit) return;
            Update2Type(type);
            _refreshLine?.Invoke();
        }


        [LabelText("行为类型"), ValueDropdown("extraType"), OnValueChanged("extraChanged")]
        public string typeStr;

        [LabelText("权重值"), ValueDropdown("weightType"), OnValueChanged("weightChanged")]
        public string weightStr;

        [LabelText("等待时间"), ShowIf("@type == 0"), OnValueChanged("refreshParam")]
        public int paramAwaitTimer;

        [LabelText("等待朝向"), ShowIf("@type == 0"), OnValueChanged("paramAwaitLookAtChanged")]
        public int paramAwaitLookAt;

        private void paramAwaitLookAtChanged()
        {
            var gos = _getNpcModelObjs?.Invoke();
            if (gos is { Count: 1 })
            {
                gos[0].transform.eulerAngles = new Vector3(0f, paramAwaitLookAt, 0f);
            }
            refreshParam();
        }
        
        

        private List<string> awaitAnimations;

        [LabelText("等待动作"), ShowIf("@type == 0"), ValueDropdown("awaitAnimations"),
         OnValueChanged("paramAwaitAnimationChanged"),InfoBox("该动作不能兼容所有模型或动作配置异常，请做剔除检测",InfoMessageType.Error,"isOnly")]
        public string paramAwaitAnimation;

        private bool isOnly()
        {
            if (type == 1)
            {
                return false;
            }
            if (string.IsNullOrEmpty(paramAwaitAnimation))
            {
                return true;
            }
            if (!_npcBase2ModelNameDic.TryGetValue(paramAwaitAnimation, out var isMx)) return !isExFilter;
            if (isMx)
            {
                return false;
            }
            return !isExFilter;
        }
        

        [LabelText("操作过滤列表")] public bool isExFilter;

        [LabelText("过滤形象列表"), ShowIf("isExFilter")]
        public List<ModelInfo> filter;

        [LabelText("独立额外行为组"), OnValueChanged("extraModelGroupChanged")]
        public List<ExtraModelGroup> extraModelGroupList;
        
        private int tempextraModelGroupCount = 0;
        private void extraModelGroupChanged()
        {
            if (tempextraModelGroupCount >= extraModelGroupList.Count)
            {
                tempextraModelGroupCount = extraModelGroupList.Count();
                return;
            }
            // 当有数据增加
            extraModelGroupList.Remove(extraModelGroupList[^1]);
            var info = new ExtraModelGroup(_npcBases, _getNpcModelObjs, _getAnimations, _getModelGroup, awaitAnimations, _npcBase2ModelNameDic, null);
            extraModelGroupList.Add(info);
            tempextraModelGroupCount = extraModelGroupList.Count;
        }
        
        private string _filterStr;

        private bool _isInit;

        private void paramAwaitAnimationChanged()
        {
            if (!_isInit) return;

            if (paramAwaitAnimation == "nil")
            {
                paramAwaitAnimation = "";
                isAnimationNameLocalAll = 1;
            }
            else
            {
                var animName = paramAwaitAnimation.Split('[')[0];
                paramAwaitAnimation = animName;
                if (_npcBase2ModelNameDic.TryGetValue(animName, out var ism))
                {
                    isAnimationNameLocalAll = ism ? 1 : 0;
                }
                else
                {
                    isAnimationNameLocalAll = 0;
                }
            }

            refreshParam();

            foreach (var n in filter)
            {
                n.RefreshAnimName();
            }
        }

        private int isAnimationNameLocalAll = 1;

        [Button("检查动作"), ShowIf("@isAnimationNameLocalAll == 0")]
        private void ExNpcModel2Animation()
        {
            if (_animation2NpcBase.TryGetValue(paramAwaitAnimation, out var list))
            {
                var diff = _npcBaseList.Except(list);

                var logStr = diff.Aggregate("当前不满足的id为：", (current, i) => current + (i + "  "));
                logStr += "请对其添加过滤配置";
                Debug.LogError(logStr);
            }
            else
            {
                Debug.LogError("数据异常");
            }
        }

        [Button("刷新动作级形象列表")]
        private void RefreshNpcModel()
        {
            InitAnimations();

            var f = _filterStr.Split('$');
            filter = new List<ModelInfo>();

            foreach (var npcBaseId in _npcBaseList)
            {
                var fInfo = new ModelInfo(0, npcBaseId, _npcBases,isAnim2NpcId);
                foreach (var i in f)
                {
                    if (!i.Contains($"{npcBaseId}")) continue;
                    var sp = i.Split('#');
                    var state = int.Parse(sp[1]);
                    fInfo.eliminateState = (EliminateEnum)state;
                }

                filter.Add(fInfo);
            }
        }

        [LabelText("气泡id"), OnValueChanged("refreshParam")]
        public string paramBubbleId;

        private Dictionary<string, bool> _npcBase2ModelNameDic;
        private Dictionary<string, List<int>> _animation2NpcBase;
        private List<int> _npcBaseList;
        public ExtraBehavior(string value, int selfIndex, Dictionary<int, ConfigNpc_Base> npcBases, getModelGroup modelGroup,
            getAnimations getAnimations, getPointPos2Index getPointPos2Index, Action<int> removeBubble2Index,
            Action refreshLine, Func<List<GameObject>> getNpcModelObjs)
        {
            _npcBases = npcBases;
            _getModelGroup = modelGroup;
            _getAnimations = getAnimations;
            _getPointPos2Index = getPointPos2Index;
            _removeBubble2Index = removeBubble2Index;
            _getNpcModelObjs = getNpcModelObjs;
            _refreshLine = refreshLine;
            var ss = value.Split(':');
            var tempIndex = ss.Length >= 1 && int.TryParse(ss[0], out var i) ? i : 0;
            var tempType = ss.Length >= 2 && int.TryParse(ss[1], out var v) ? v : 0;
            var tempWeight = ss.Length >= 3 && int.TryParse(ss[2], out var w) ? w : 1;
            var tempParam = ss.Length >= 4 ? ss[3] : "";
            var tempFilter = ss.Length >= 5 ? ss[4] : "";

            var posX = ss.Length >= 6 && float.TryParse(ss[5], out var x) ? x : 0;
            var posY = ss.Length >= 7 && float.TryParse(ss[6], out var y) ? y : 0;
            var posZ = ss.Length >= 8 && float.TryParse(ss[7], out var z) ? z : 0;
            var _pos = new Vector3(posX, posY, posZ);
            Init(tempIndex, tempType, tempWeight, tempParam, tempFilter, _pos, selfIndex);
            //  独立额外行为组
            if (ss.Length >= 9 && int.TryParse(ss[8], out var n))
            {
                var info = new ExtraModelGroup(_npcBases, _getNpcModelObjs, _getAnimations, _getModelGroup,
                    awaitAnimations, _npcBase2ModelNameDic, ss);
                extraModelGroupList.Add(info);
            }
        }

        public ExtraBehavior(Vector3 _pos, int _index, int selfIndex, Dictionary<int, ConfigNpc_Base> npcBases, getModelGroup modelGroup,
            getAnimations getAnimations, getPointPos2Index getPointPos2Index, Action<int> removeBubble2Index,
            Action refreshLine,Func<List<GameObject>> getNpcModelObjs)
        {
            _npcBases = npcBases;
            _getAnimations = getAnimations;
            _getPointPos2Index = getPointPos2Index;
            _removeBubble2Index = removeBubble2Index;
            _refreshLine = refreshLine;
            _getNpcModelObjs = getNpcModelObjs;
            _getModelGroup = modelGroup;
            Init(_index, 0, 1, "", "", _pos, selfIndex);
        }

        private void Init(int _index, int _type, int _weight, string _param, string _filter,
            Vector3 _pos, int selfIndex)
        {
            _isInit = false;
            index = _index;
            type = _type;
            typeStr = extraType[type];
            weight = _weight;
            weightStr = weightType[weight - 1];
            param = _param;
            pos = _pos;
            thisIndex = selfIndex;
            _filterStr = _filter;
            switch (type)
            {
                case 0:
                {
                    var s = param.Split('$');
                    paramAwaitTimer = s.Length >= 1 && !string.IsNullOrEmpty(s[0]) ? int.Parse(s[0]) : 0;
                    paramAwaitAnimation = s.Length >= 2 && !string.IsNullOrEmpty(s[1]) ? s[1] : "";
                    paramAwaitLookAt = s.Length >= 3 && int.TryParse(s[2], out var v) ? v : 0;
                    paramBubbleId = s.Length >= 4 ? s[3] : "";
                    break;
                }
                case 1:
                    paramBubbleId = param;
                    break;
            }

            InitAnimations();


            var f = _filterStr.Split('$').ToArray();
            filter = new List<ModelInfo>();
            foreach (var npcBaseId in _npcBaseList)
            {
                var fInfo = new ModelInfo(0, npcBaseId, _npcBases,isAnim2NpcId);
                foreach (var i in f)
                {
                    if (!i.Contains($"{npcBaseId}")) continue;
                    var sp = i.Split('#');
                    var state = int.Parse(sp[1]);
                    fInfo.eliminateState = (EliminateEnum)state;
                }
                fInfo.RefreshAnimName();
                filter.Add(fInfo);
            }

            // 将npc的单独列表显示出来, 手动添加
            extraModelGroupList = new List<ExtraModelGroup>();
            // if (extraGroup != null)
            // {
            //     var info = new ExtraModelGroup(_npcBases, _getNpcModelObjs, _getAnimations, _getModelGroup, awaitAnimations, _npcBase2ModelNameDic);
            //     extraModelGroupList.Add(info);
            //     tempextraModelGroupCount = extraModelGroupList.Count;
            // }

            isExFilter = !string.IsNullOrEmpty(_filterStr);
            _isInit = true;
        }


        public bool isAnim2NpcId(int id)
        {
            if (type == 1)
            {
                return true;
            }
            
            if (string.IsNullOrEmpty(paramAwaitAnimation))
            {
                return false;
            }
            return _animation2NpcBase.TryGetValue(paramAwaitAnimation, out var ids) && ids.Any(i => i == id);
        }
        
        private void InitAnimations()
        {
            _npcBase2ModelNameDic = _getAnimations?.Invoke(out _animation2NpcBase, out _npcBaseList);
            awaitAnimations = new List<string>();
            if (_npcBase2ModelNameDic != null)
            {
                foreach (var b in _npcBase2ModelNameDic)
                {
                    awaitAnimations.Add(b.Value ? b.Key : $"{b.Key}[仅部分]");
                }
            }
            else
            {
                awaitAnimations.Add("nil");
            }
        }

        private void extraChanged()
        {
            if (!_isInit) return;

            for (var i = 0; i < extraType.Length; i++)
            {
                if (typeStr != extraType[i]) continue;
                if (type != i)
                {
                    // 类型变更
                    param = string.Empty;
                    Update2Type(i);
                    _refreshLine?.Invoke();
                    foreach (var n in filter)
                    {
                        n.RefreshAnimName();
                    }
                }

                type = i;
                break;
            }
        }

        private void Update2Type(int tempType)
        {
            type = tempType;
            switch (tempType)
            {
                case 0:
                    // 从气泡变换为动作
                    _removeBubble2Index?.Invoke(index - 1);
                    var rm1 = pointObj.GetComponent<Renderer>();
                    rm1.material.color = Color.cyan;
                    break;
                case 1:
                    // 从动作变换为气泡
                    var tempPos = _getPointPos2Index?.Invoke(index - 1);
                    if (tempPos != null)
                    {
                        pos = tempPos.GetValueOrDefault();
                        pointObj.transform.localPosition = this.pos;
                        var rm2 = pointObj.GetComponent<Renderer>();
                        rm2.material.color = Color.gray;
                    }

                    break;
            }
        }

        private void weightChanged()
        {
            if (!_isInit) return;

            for (var i = 0; i < weightType.Length; i++)
            {
                if (weightStr != weightType[i]) continue;
                weight = i + 1;
                break;
            }
        }

        private void refreshParam()
        {
            if (!_isInit) return;

            param = type switch
            {
                0 => $"{paramAwaitTimer}${paramAwaitAnimation}${paramAwaitLookAt}${paramBubbleId}",
                1 => paramBubbleId,
                _ => param
            };
        }

        public string GetValue()
        {
            return $"{index}:{type}:{weight}:{param}:{GetFilterValue()}:{pos.x}:{pos.y}:{pos.z}:{GetExtraModelGroupValue()}";
        }

        private string GetExtraModelGroupValue()
        {
            var str = extraModelGroupList.Where(info => info.cfgState == 1)
                .Aggregate("", (current, info) => current + $"{info.GetValue()}$"); 
            str = str.TrimEnd('$');
            return str;
        }
        private string GetFilterValue()
        {
            var str = filter.Where(baseInfo => baseInfo.cfgState == 1 && baseInfo.eliminateState != EliminateEnum.None)
                .Aggregate("", (current, baseInfo) => current + $"{baseInfo.id}#{(int)baseInfo.eliminateState}$");
            str.TrimEnd('$');
            return str;
        }
    }

    /// <summary>
    /// 显示模型
    /// </summary>
    [Serializable]
    public class ModelGroup
    {
        [HideInInspector] public ConfigP2p_Path_Model_Group cfg;

        public Dictionary<int, ConfigNpc_Base> npcBaseCfg;

        public delegate List<GameObject> createNpcModel(List<NpcBaseInfo> infos);

        private createNpcModel _createNpcModel;

        private Func<List<ExtraBehavior>> _getExtraBehavior;

        [LabelText("id"), HorizontalGroup("id2Index")]
        public int id; // 唯一标识

        [LabelText("index"), ReadOnly, HorizontalGroup("id2Index")]
        public int index; // 索引下标

        [LabelText("注释")] public string ann; // 注释

        private string[] alignmentTypeStr = new[] { "0:靠前", "1:居中", "2:靠后" };

        private string[] constraion = new[] { "0：竖", "1：横" };

        [LabelText("对齐方式"), HorizontalGroup("types"), ValueDropdown("alignmentTypeStr"),
         OnValueChanged("alignmentChanged")]
        public string alignment_typeStr; // 对齐方式

        [LabelText("排列方式"), HorizontalGroup("types"), ValueDropdown("constraion"), OnValueChanged("constraionChanged")]
        public string constraion_typeStr;

        [LabelText("排列数量"), HorizontalGroup("types"), OnValueChanged("constraionNumberChanged")]
        public int constraion_number;

        private List<P2pPathPoint> _contrast; // 模型朝向的点

        private List<ExtraBehavior> _extraBehaviors; // 额外行为点儿

        private void constraionNumberChanged()
        {
            RefreshNpcModelLayer();
        }


        [LabelText("间距"), OnValueChanged("spacingChanged")]
        public Vector2 spacing;

        private void spacingChanged()
        {
            RefreshNpcModelLayer();
        }

        [LabelText("模型队列"), OnValueChanged("npcListChanged")]
        public List<NpcBaseInfo> npcList;

        private int tempNpcListCount;

        private void npcListChanged()
        {
            if (tempNpcListCount >= npcList.Count)
            {
                tempNpcListCount = npcList.Count();
                return;
            }
            // 当有数据增加
            npcList.Remove(npcList[^1]);
            var info = new NpcBaseInfo(1000, npcBaseCfg);
            npcList.Add(info);
            _isNpcModelCountBOne = tempNpcListCount == 1;
            tempNpcListCount = npcList.Count();
        }

        private List<GameObject> _npcModelGos;

        [Button("显示模型"),HorizontalGroup("showNpcModel")]
        private void ShowModel()
        {
            _npcModelGos = _createNpcModel?.Invoke(npcList);
            RefreshNpcModelLayer();
        }

        private bool _isNpcModelCountBOne = false;
        
        [HideLabel,ShowIf("_isNpcModelCountBOne"),HorizontalGroup("showNpcModel"),OnValueChanged("showIndex2PointChanged")]
        public int _showIndex2Point;

        private void showIndex2PointChanged()
        {
            RefreshNpcModelLayer();
        }

        private int alignment_type;
        private int constraion_type;
        private Vector3 modelParentPos;

        private void alignmentChanged()
        {
            for (var i = 0; i < alignmentTypeStr.Length; i++)
            {
                if (alignment_typeStr != alignmentTypeStr[i]) continue;
                alignment_type = i;
                break;
            }

            RefreshNpcModelLayer();
        }

        private void constraionChanged()
        {
            for (var i = 0; i < constraion.Length; i++)
            {
                if (constraion_typeStr != constraion[i]) continue;
                constraion_type = i;
                break;
            }

            RefreshNpcModelLayer();
        }

        public ModelGroup(ConfigP2p_Path_Model_Group cfg, Dictionary<int, ConfigNpc_Base> npcBase, int index,
            createNpcModel createNpcModel, List<P2pPathPoint> contrast , Func<List<ExtraBehavior>> extraBehaviors)
        {
            this.cfg = cfg;
            _createNpcModel = createNpcModel;
            npcBaseCfg = npcBase;
            _contrast = contrast;
            _getExtraBehavior = extraBehaviors;

            this.index = index;
            id = cfg.id;
            ann = cfg.annotation;
            alignment_type = cfg.alignment_type;
            alignment_typeStr = alignmentTypeStr[alignment_type];

            var tempNpcList = cfg.npc_list != null ? SetNpcListValue(cfg.npc_list) : new List<NpcBaseInfo>();
            tempNpcListCount = tempNpcList.Count;
            _isNpcModelCountBOne = tempNpcListCount == 1;
            npcList = tempNpcList;

            constraion_type = cfg.constraint_type.Length >= 1 ? int.Parse(cfg.constraint_type[0]) : 0;
            constraion_number = cfg.constraint_type.Length >= 2 ? int.Parse(cfg.constraint_type[1]) : 1;
            constraion_typeStr = constraion[constraion_type];

            spacing = new Vector2
            {
                x = this.cfg.spacing.Length >= 1 ? P2pPathPoint.Float2Vec(cfg.spacing[0]) : 0,
                y = this.cfg.spacing.Length >= 2 ? P2pPathPoint.Float2Vec(cfg.spacing[1]) : 0
            };
        }


        private List<NpcBaseInfo> SetNpcListValue(string param)
        {
            var list = new List<NpcBaseInfo>();
            var lpInfo = param.Split('|');
            foreach (var p in lpInfo)
            {
                var sInfo = p.Split(':');
                var npcBaseID = sInfo.Length >= 1 && int.TryParse(sInfo[0], out var npcId) ? npcId : 1000;
                var isShowName = sInfo.Length >= 2 && int.TryParse(sInfo[1], out var isShow) ? isShow : 0;
                var showName = sInfo.Length >= 3 ? sInfo[2] : "";
                if (!npcBaseCfg.TryGetValue(npcBaseID, out var npcCfg)) continue;
                var npcInfo = new NpcBaseInfo(npcCfg, npcBaseCfg, isShowName, showName);
                list.Add(npcInfo);
            }

            return list;
        }


        public ConfigP2p_Path_Model_Group GetValue(out int modelGroupId)
        {
            modelGroupId = cfg.id;
            cfg.annotation = ann;
            cfg.alignment_type = alignment_type;
            cfg.spacing = new[]
                { spacing.x.ToString(CultureInfo.InvariantCulture), spacing.y.ToString(CultureInfo.InvariantCulture) };
            cfg.constraint_type = new[] { constraion_type.ToString(), constraion_number.ToString() };
            cfg.npc_list = GetNpcListValue();
            return cfg;
        }

        // 获取npc列表数据
        private string GetNpcListValue()
        {
            var str = npcList.Aggregate("", (current, info) => current + $"{info.GetValue()}|");
            str = str.TrimEnd('|');
            return str;
        }
        
        #region [模型展示排版逻辑优化]

        // 刷新模板排列
        private void RefreshNpcModelLayer()
        {
            if (_npcModelGos == null)
            {
                return;
            }

            if (_npcModelGos.Count == 1)
            {
                if (_showIndex2Point > 0)
                {
                    // 路点上显示
                    if (_showIndex2Point >= _contrast.Count)
                    {
                        return;
                    }
                    
                    var pos = _contrast[_showIndex2Point].pointObj.transform.localPosition;
                    _npcModelGos[0].transform.localPosition = pos;
                }
                else
                {
                    // 额外行为上显示
                    var i = Math.Abs(_showIndex2Point);
                    _extraBehaviors = _getExtraBehavior?.Invoke();
                    if (_extraBehaviors == null || i >= _extraBehaviors.Count)
                    {
                        return;
                    }
                    var pos = _extraBehaviors[i].pointObj.transform.localPosition;
                    _npcModelGos[0].transform.localPosition = pos;
                }
                return;
            }

            modelParentPos = _npcModelGos[0].transform.parent.parent.position;
            for (var i = 0; i < _npcModelGos.Count; i++)
            {
                var pos = CalculateChildPosition(i);
                Debug.Log(pos);
                _npcModelGos[i].transform.localPosition = pos;
            }
        }

        private Vector3 CalculateChildPosition(int i)
        {
            var v3 = new Vector3();
            var startPos = _contrast[0].pos;
            var endPos = _contrast[1].pos;
            
            if (constraion_type == 0) // 根据斜率计算竖排队列
            {
               
                
                // 计算两点直接的距离
                var dis = Vector3.Distance(modelParentPos, endPos);
                var rat = spacing.y / dis; // 比例系数
                var cIndex = 0f; // 起点下标
                var isCo = false; // 居中，且长度为偶数
                switch (alignment_type)
                {
                    case 0: // 靠前
                        cIndex = 0;
                        break;
                    case 1: // 居中
                        cIndex = _npcModelGos.Count / 2f;
                        var isDecimal = cIndex % 1 != 0; // 计算是否是小数
                        isCo = !isDecimal;
                        if (isDecimal)
                        {
                            cIndex -= 0.5f;
                        }

                        break;
                    case 2: // 靠后
                        cIndex = _npcModelGos.Count - 1;
                        break;
                }

                if (cIndex > i)
                {
                    // 向后
                    var offs = Math.Abs(cIndex - i);
                    var t = rat * offs;
                    t = isCo ? t - (rat / 2f) : t;
                    v3 = ExtendPointOnLine(modelParentPos, endPos, -t);
                }
                else if (Math.Abs(cIndex - i) < 0.001f)
                {
                    // 居中
                    if (isCo)
                    {
                        var t = rat / 2;
                        v3 = ExtendPointOnLine(modelParentPos, endPos, t);
                    }
                    else
                    {
                        v3 = modelParentPos;
                    }
                }
                else if (cIndex < i)
                {
                    // 向前
                    var offs = Math.Abs(cIndex - i);
                    var t = rat * offs;
                    t = isCo ? t + (rat / 2f) : t;
                    v3 = ExtendPointOnLine(modelParentPos, endPos, t);
                }

                v3 = _npcModelGos[0].transform.parent.InverseTransformPoint(v3);
            }
            else
            {
                var count = _npcModelGos.Count();
                var line = (endPos - startPos).normalized;
                var perpendicularDirection  =  new Vector3(-line.z, 0, line.x);

                var offset = alignment_type switch
                {
                    0 => 0,
                    1 => (count-1)*0.5f,
                    2 => count-1,
                    _ => 0f
                };

                var pos = startPos + perpendicularDirection * (spacing.x * (i - offset));
                v3 = _npcModelGos[0].transform.parent.InverseTransformPoint(pos);
            }

            return v3;
        }

        private Vector3 ExtendPointOnLine(Vector3 start, Vector3 end, float extendFactor)
        {
            // 如果延长系数为-1，则返回起点的反方向
            if (Math.Abs(extendFactor - (-1)) < 0.01f)
            {
                return start - (end - start);
            }

            if (extendFactor < 0)
            {
                return start + (start - end) * Mathf.Abs(extendFactor);
            }

            // 计算延长点的位置
            var extendedPoint = start + (end - start) * extendFactor;

            return extendedPoint;
        }

        #endregion
    }

    [Serializable]
    public class NpcBaseInfo
    {
        private Dictionary<int, ConfigNpc_Base> _npcBases;

        [LabelText("id"), OnValueChanged("idChanged")]
        public int id;

        [LabelText("名字"), ReadOnly, ShowIf("@cfgState == 1")]
        public string name;

        [LabelText("是否显示名字"), HorizontalGroup("showName"), OnValueChanged("isShowNameChanged")]
        public bool isShowName;

        private int _isShowName = 0;

        private void isShowNameChanged()
        {
            _isShowName = isShowName ? 1 : 0;
            if (string.IsNullOrEmpty(showName))
            {
                showName = name;
            }
        }

        [LabelText("游戏内显示的名字"), HorizontalGroup("showName"), ShowIf("@_isShowName == 1")]
        public string showName;

        [LabelText("模型名字"), ReadOnly, ShowIf("@cfgState == 1")]
        public string model;

        [LabelText("未查找到相关配置"), ShowIf("@cfgState == 0")]
        public string ann;

        [HideInInspector] public int cfgState = 0; // 获取到cfg的状态 ，0 未获取 1获取到


        private void idChanged()
        {
            if (_npcBases.TryGetValue(id, out var cfg))
            {
                name = cfg.name;
                model = cfg.body;
                cfgState = 1;
            }
            else
            {
                cfgState = 0;
            }
        }


        public NpcBaseInfo(ConfigNpc_Base cfg, Dictionary<int, ConfigNpc_Base> npcBases, int _isShowName,
            string showName)
        {
            id = cfg.id;
            _npcBases = npcBases;
            name = cfg.name;
            model = cfg.body;
            cfgState = 1;
            this._isShowName = _isShowName;
            isShowName = _isShowName == 1;
            this.showName = showName;
        }

        public NpcBaseInfo(int id, Dictionary<int, ConfigNpc_Base> npcBases)
        {
            this.id = id;
            _npcBases = npcBases;
            cfgState = 0;
            _isShowName = 0;
            isShowName = false;
        }

        public string GetValue()
        {
            return $"{id}:{_isShowName}:{showName}";
        }
    }


    [Serializable]
    public class ModelInfo
    {
        [Readonly, HorizontalGroup("info"), HideLabel]
        public int id;

        [Readonly, HorizontalGroup("info"), HideLabel]
        public string name;

        [Title("剔除状态"), EnumToggleButtons, HideLabel,OnValueChanged("refreshState")]
        public EliminateEnum eliminateState;

        private void refreshState()
        {
            if (isOnly)
            {
                return;
            }

            if (eliminateState is EliminateEnum.None or EliminateEnum.必定)
            {
                eliminateState = EliminateEnum.剔除;
            }
        }

        [HideInInspector] public int cfgState;

        public delegate bool refreshAnim(int id);

        private refreshAnim _refreshAnimFun;
        
        public ModelInfo(int state, int id, Dictionary<int, ConfigNpc_Base> npcBases , refreshAnim refreshAnimFun)
        {
            this.id = id;
            if (npcBases.TryGetValue(id, out var cfg))
            {
                name = cfg.name;
                cfgState = 1;
            }
            else
            {
                name = "为查找到相关配置";
                cfgState = 0;
            }

            _refreshAnimFun = refreshAnimFun;
            eliminateState = (EliminateEnum)state;
        }

        private bool isOnly = false;
        public void RefreshAnimName()
        {
            var _isOnly = _refreshAnimFun?.Invoke(id);
            if (_isOnly != null) isOnly = _isOnly.Value;
            if (isOnly)
            {
                eliminateState = eliminateState == EliminateEnum.必定 ? EliminateEnum.必定 : EliminateEnum.None;
            }
            else
            {
                eliminateState = EliminateEnum.剔除;    
            }
        }
        
    }

    // 额外行为组
    [Serializable]
    public class ExtraModelGroup
    {
        private List<int> _npcs;
        private Dictionary<int, ConfigNpc_Base> _npcBases;
        private ModelGroup _group;
        
        [LabelText("对应形象实例"), OnValueChanged("idChanged")]
        public int id;
        
        [LabelText("朝向目标"), ShowIf("@cfgState == 1"), OnValueChanged("isLookTarget")]
        public bool isLookAt;
        
        [LabelText("朝向目标的id"), ShowIf("isLookAt"), OnValueChanged("lookTargetChanged"), InfoBox(("队列中未含有该NPC,请配置"), InfoMessageType.Error, "hasLookNpc")]
        public int lookId = 0;
        
        [LabelText("额外行为队列"), OnValueChanged("extraModelChanged")]
        public List<ExtraModelInfo> extraModelList;
        
        [LabelText("未查找到相关配置"), ShowIf("@cfgState == 0"), InfoBox("请配置相应的组别,同形象实例ID",InfoMessageType.Error, "hasGroup")]
        public string ann;

        [HideInInspector] public int cfgState = 0; // 获取到cfg的状态 ，0 未获取 1获取到
        private readonly ExtraBehavior.getModelGroup _getModelGroup;
        private readonly ExtraBehavior.getAnimations _getAnimations;
        private readonly Func<List<GameObject>> _getNpcModelObjs;
        private readonly List<string> _awaitAnimations;
        private readonly Dictionary<string, bool> _npcBase2ModelNameDic;
        private readonly string[] _str;

        // 朝向npc是否配置正确
        private bool hasLookNpc()
        {
            return !_npcs.Exists(npc => npc == lookId);
        }
        private void isLookTarget()
        {
            foreach (var n in extraModelList)
            {
                n.RefreshLookTarget(isLookAt);
            }
        }
        
        private bool hasGroup()
        {
            return cfgState == 0;
        }
        private void lookTargetChanged()
        {
            //  视角发生变化
        }
        
        private void extraModelChanged()
        {
            // 额外模型队列修改，由实例修改触发最佳。
        }
        private void idChanged()
        {
            ModelGroup group = _getModelGroup(id);
            if (group != null)
            {
                extraModelList.Clear();
                _group = group;
                isLookAt = group.npcList.Count > 1;
                foreach (var npc in _group.npcList)
                {
                    if (!_npcBases.TryGetValue(npc.id, out var npcCfg)) continue;
                    _npcs.Add(npc.id);
                    lookId = npc.id;
                    var extra = new ExtraModelInfo(npcCfg, _npcBases, isLookAt, _getNpcModelObjs, _awaitAnimations, _npcBase2ModelNameDic, null);
                    extraModelList.Add(extra);
                }
                cfgState = 1;
            }
            else
            {
                extraModelList.Clear();
                cfgState = 0;
            }
        }
        
        // public delegate Dictionary<string, bool> getAnimations(out Dictionary<string, List<int>> animation2NpcBase,
        //     out List<int> npcBaseList); // 模型动作更新回调
        //手动创建
        public ExtraModelGroup(Dictionary<int, ConfigNpc_Base> npcBases, Func<List<GameObject>> getNpcModelObjs, 
            ExtraBehavior.getAnimations getAnimations, ExtraBehavior.getModelGroup getModelGroup,  List<string> awaitAnimations, Dictionary<string,bool> npcBase2ModelNameDic, string[] str)
        {
            _str = str;
            _getModelGroup = getModelGroup;
            _npcBases = npcBases;
            _getAnimations = getAnimations;
            _getNpcModelObjs = getNpcModelObjs;
            _awaitAnimations = awaitAnimations;
            _npcBase2ModelNameDic = npcBase2ModelNameDic;
            cfgState = 0;
            // 添加额外行为
            extraModelList = new List<ExtraModelInfo>();
            _npcs = new List<int>();
            if (!str.IsNullOrEmpty())
            {
                AddExtraModelInfo(str);
            }
            
        }

        private void AddExtraModelInfo(string [] str)
        {
            id = str.Length >= 9 && int.TryParse(str[8], out var a) ? a : 0;
            isLookAt = str.Length >= 10 && bool.TryParse(str[9], out var b) && b;
            lookId = str.Length >= 11 && int.TryParse(str[10], out var c) ? c : 0;
            var s = str.Length >=12 ? str[11] : "";
            
            ModelGroup group = _getModelGroup(id);
            if (group != null)
            {
                extraModelList.Clear();
                _group = group;
                foreach (var npc in _group.npcList)
                {
                    if (!_npcBases.TryGetValue(npc.id, out var npcCfg)) continue;
                    _npcs.Add(npc.id);
                    var extra = new ExtraModelInfo(npcCfg, _npcBases, isLookAt, _getNpcModelObjs, _awaitAnimations, _npcBase2ModelNameDic, s);
                    extraModelList.Add(extra);
                }
                cfgState = 1;
            }
            else
            {
                extraModelList.Clear();
                cfgState = 0;
            }
        }
        
        // 将数据存放至相应的配置文件
        public string GetValue()
        {
            return $"{id}:{isLookAt}:{lookId}:{GetExtraModelValue()}";
        }
        private string GetExtraModelValue()
        {
            var str = extraModelList.Aggregate("", (current, info) => $"{current}{info.GetValue()}#");
            str = str.TrimEnd('#');
            return str;
        }
        
    }
    // 额外行为配置
    [Serializable]
    public class ExtraModelInfo
    {
        private bool isLook = false;
        private Func<List<GameObject>> _getNpcModelObjs;
        
        [HideInInspector] public int type; // 行为
        [HideInInspector] public int cfgState = 0; // 获取到cfg的状态 ，0 未获取 1获取到
        [LabelText("未查找到相关配置"), ShowIf("@cfgState == 0")]
        public string ann;

        private Dictionary<int, ConfigNpc_Base> _npcBases;

        [LabelText("id"), Readonly, ShowIf("@cfgState == 1")]
        public int id;

        [LabelText("名字"), ReadOnly, ShowIf("@cfgState == 1")]
        public string name;

        [LabelText("模型名字"), ReadOnly, ShowIf("@cfgState == 1")]
        public string model;
        
        private static string[] behaviorType = new[] { "0:分支播放动作", "1:仅气泡" };
        [LabelText("行为类型"), ValueDropdown("behaviorType"), OnValueChanged("behaviorChanged")]
        public string typeStr;

        [LabelText("等待朝向"), OnValueChanged("extraAwaitLookAtChanged"), ShowIf("isLook")]
        public int paramAwaitLookAt;

        [LabelText("等待时间"), OnValueChanged("refreshParam")]
        public int paramAwaitTimer;
        
        private List<string> awaitAnimations;
        [LabelText("等待动作"), ShowIf("@type == 0"), ValueDropdown("awaitAnimations"),
         OnValueChanged("paramAwaitAnimationChanged"),InfoBox("该动作不能兼容模型或动作配置异常，请检测",InfoMessageType.Error,"isOnly")]
        public string paramAwaitAnimation;
        
        [LabelText("气泡id"), OnValueChanged("refreshParam")]
        public string paramBubbleId;

        private readonly List<string> _awaitAnimations;
        private readonly Dictionary<string, bool> _npcBase2ModelNameDic;

        private void paramAwaitAnimationChanged()
        {
            // 动画变更记录
        }
        private bool isOnly()
        {
            if (type == 1)
            {
                return false;
            }
            if (string.IsNullOrEmpty(paramAwaitAnimation))
            {
                return true;
            }
            if (!_npcBase2ModelNameDic.TryGetValue(paramAwaitAnimation, out var isMx)) return true;
            if (isMx)
            {
                return false;
            }
            return true;
        }
        
        public ExtraModelInfo(ConfigNpc_Base cfg, Dictionary<int, ConfigNpc_Base> npcBases, bool look,
            Func<List<GameObject>> getNpcModelObjs,  List<string> awaitAnimations,  Dictionary<string,bool> npcBase2ModelNameDic, string str)
        {
            id = cfg.id;
            _getNpcModelObjs = getNpcModelObjs;
            _npcBases = npcBases;
            name = cfg.name;
            model = cfg.body;
            cfgState = 1;
            this.awaitAnimations = awaitAnimations;
            _npcBase2ModelNameDic = npcBase2ModelNameDic;
            Init(0, 0, !look, str);
        }
        
          private void Init(int t, int waitLookAt,bool look, string value)
          {
              type = t; 
              typeStr = behaviorType[t];
              paramAwaitLookAt = waitLookAt; 
              isLook = look;

              if (!value.IsNullOrWhitespace())
              {
                  var arr = value.Split('#');
                  foreach (var s in arr)
                  {
                      int temp;
                      var ss = s.Split('$');
                      var tid = ss.Length >= 1 && int.TryParse(ss[0], out temp) ? temp : 0;
                      if (tid != id) continue;
                      type = ss.Length >= 2 && int.TryParse(ss[1], out temp) ? temp : 0;
                      typeStr = behaviorType[type];
                      paramAwaitLookAt = ss.Length >= 3 && int.TryParse(ss[2], out temp) ? temp : 0;
                      paramAwaitTimer = ss.Length >= 4 && int.TryParse(ss[3], out temp) ? temp : 0;
                      paramAwaitAnimation = ss.Length >= 5 ? ss[4] : "";
                      paramBubbleId = ss.Length >= 6 ? ss[5] : "";
                      
                  }
              }
          }

        public ExtraModelInfo(int id, Dictionary<int, ConfigNpc_Base> npcBases)
        {
            this.id = id;
            _npcBases = npcBases;
            cfgState = 0;
        }
        
        private void behaviorChanged()
        {
            // 行为变更
            for (var i = 0; i < behaviorType.Length; i++)
            {
                if (typeStr != behaviorType[i]) continue;
                // if (type != i)
                // {
                //     // 类型变更
                //     param = string.Empty;
                //     Update2Type(i);
                // }

                type = i;
                break;
            }
        }
        private void extraAwaitLookAtChanged()
        {
            var gos = _getNpcModelObjs?.Invoke();
            if (gos is { Count: 1 })
            {
                gos[0].transform.eulerAngles = new Vector3(0f, paramAwaitLookAt, 0f);
            }
            // 更新数据
            // refreshExtraParam();
        }

        private void refreshExtraParam()
        {
            
        }

        private void SetLookAt(bool lookAt)
        {
            isLook = lookAt;
        }

        public void RefreshLookTarget(bool lookAt)
        {
            SetLookAt(!lookAt);
        }
        
        private void refreshParam()
        {
            // 更新 等待时间, 等待朝向等数据
        }
        public string GetValue()
        {
            return $"{id}${type}${paramAwaitLookAt}${paramAwaitTimer}${paramAwaitAnimation}${paramBubbleId}";
        }
    }
    
    public enum EliminateEnum
    {
        None = 0,
        剔除 = 1,
        必定 = 2,
    }

    public enum LoopType
    {
        首尾相连,
        逆向相连,
    }

    public enum AnimationLayer
    {
        默认,
        整齐,
    }
}
#endif