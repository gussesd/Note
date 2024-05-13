USE_NEW_UNIT_ACTION = false
USE_NEW_UNIT_ACTION_LOG = false
ACTION_BASE_FRAME = 0.3

SkillUtils = require "GamePlay/Unit/Skill/SkillUtils"
UnitBase = require "GamePlay/Unit/UnitBase"
UnitRole = require "GamePlay/Unit/UnitRole"
UnitMonster = require "GamePlay/Unit/UnitMonster"
UnitTrap = require "GamePlay/Unit/UnitTrap"
UnitNPC = require "GamePlay/Unit/UnitNPC"
UnitPlayer = require "GamePlay/Unit/UnitPlayer"
UnitHero = require "GamePlay/Unit/UnitHero"
UnitPlantom = require "GamePlay/Unit/UnitPlantom"
UnitGhostShadow = require "GamePlay/Unit/UnitGhostShadow"
UnitSimpleRole = require "GamePlay/Unit/UnitSimpleRole"
UnitDropItem = require "GamePlay/Unit/UnitDropItem"
UnitUIModel = require "GamePlay/Unit/UnitUIModel"
UnitTempModel = require "GamePlay/Unit/UnitTempModel"
require "GamePlay/Unit/Head/HUDEnum"
HUDText = require "GamePlay/Unit/Head/HUDText"
RoleHeadBase = require "GamePlay/Unit/Head/RoleHeadBase"
RoleHeadSimple = require "GamePlay/Unit/Head/RoleHeadSimple"
RoleHeadNormal = require "GamePlay/Unit/Head/RoleHeadNormal"
RoleHeadShield = require "GamePlay/Unit/Head/RoleHeadShield"
RoleHeadSlider = require "GamePlay/Unit/Head/RoleHeadSlider"
CollectionHeadInteraction = require "GamePlay/Unit/Head/CollectionHeadInteraction"
RoleHeadDyingBar = require "GamePlay/Unit/Head/RoleHeadDyingBar"
HUDAimLock = require "GamePlay/Unit/Head/HUDAimLock"
HUDEyes = require "GamePlay/Unit/Head/HUDEyes"
HUDBubbleLabel = require "GamePlay/Unit/Head/HUDBubbleLabel"
HUDHeadNpcName = require "GamePlay/Unit/Head/HUDHeadNpcName"
UnitTransfer = require "GamePlay/Unit/UnitTransfer"
UnitViewManager = require "GamePlay/Unit/UnitView/UnitViewManager"
UnitArticle = require "GamePlay/Unit/UnitArticle"
UnitCollection = require "GamePlay/Unit/UnitCollection"
UnitLocalCollection = require "GamePlay/Unit/UnitLocalCollection"
UnitSelfCollection = require "GamePlay/Unit/UnitSelfCollection"
UnitMotor = require "GamePlay/Unit/UnitMotor"
UnitHeroMotor = require "GamePlay/Unit/UnitHeroMotor" 
UnitAnchorPoint = require "GamePlay/Unit/UnitAnchorPoint"
UnitEffect = require "GamePlay/Unit/UnitEffect"
UnitArchitecture = require "GamePlay/Unit/UnitArchitecture"
UnitAnimationInteraction = require "GamePlay/Unit/UnitAnimationInteraction"
UnitJiGuan = require "GamePlay/Unit/UnitJiGuan"
UnitJiGuan_SlabStone = require "GamePlay/Unit/JiGuan/UnitJiGuan_SlabStone"
UnitJiGuan_Mirror = require "GamePlay/Unit/JiGuan/UnitJiGuan_Mirror"
UnitJiGuan_FanRing = require "GamePlay/Unit/JiGuan/UnitJiGuan_FanRing"
UnitJiGuan_Tortoise = require "GamePlay/Unit/JiGuan/UnitJiGuan_Tortoise"
UnitSpirit = require "GamePlay/Unit/UnitSpirit"
UnitAnimal = require "GamePlay/Unit/UnitAnimal"
UnitMissile = require "GamePlay/Unit/UnitMissile"
UnitClone = require "GamePlay/Unit/UnitClone"
UnitChron = require "GamePlay/Unit/UnitChron"
UnitMinorNpc = require "GamePlay/Unit/UnitMinorNpc"
LookAtController = require "GamePlay/Unit/IK/LookAtController"
require "GamePlay/Unit/UnitAction/UnitActionEnum"
UnitFakeUnit = require "GamePlay/Unit/UnitFakeUnit"
GrounderIKComponent = require "GamePlay/Unit/IK/GrounderIKComponent"
UnitLoadManager = require "GamePlay/Unit/UnitLoadManager"
local UnitManager = {}
local this = UnitManager

--npc起始id,防止和角色怪物id重复
NPCID_Start = 1000000000
TRANSFERID_Start = 1100000000
TEMPMODEL_Start = 1200000000
ANCHORPOINT_Start = 1300000000
MISSILE_Start = 1400000000
DECORATION_Start = 1500000000
CLONE_Start = 1600000000
PHANTOM_Start = 1700000000
function UnitManager.Init()
    this.root = CS.UnityEngine.GameObject("UnitManager").transform
    CS.UnityEngine.Object.DontDestroyOnLoad(this.root)

    this.InitFactory()
    UnitViewManager.Init()
    this.eventContainer = EventContainer(EventManager)

    --阴影设置
    CS.CustomPipeline.DL.CharacterShadowManager.maxShadowDistanceToTarget = 10
    CS.CustomPipeline.DL.CharacterShadowManager.maxShadowDistanceToCamera = 10

    this.hideMask = UNIT_LOCAL_MASK.NONE
end

function UnitManager.InitFactory()
    this.unitFactory = {}

    this.RegNewUnit("role", this.CreateRole, this.DestroyRole, 1)
    this.RegNewUnit("decoration", this.CreateDecoration, this.DestroyDecoration)
    this.RegNewUnit("transfer", this.CreateTransfer, this.DestroyTransfer)
    this.RegNewUnit("npc", this.CreateNPC, this.DestroyNPC,3)
    this.RegNewUnit("monster", this.CreateMonster, this.DestroyMonster,2)
    this.RegNewUnit("trap", this.CreateTrap, this.DestroyTrap)
    this.RegNewUnit("uimodel", this.CreateUIModel, this.DestroyUIModel)
    this.RegNewUnit("tempmodel", this.CreateTempModel, this.DestroyTempModel)
    this.RegNewUnit("dropitem", this.CreateDropItem, this.DestroyDropItem)
    this.RegNewUnit("collection", this.CreateCollection, this.DestroyCollection)
    this.RegNewUnit("localcollection", this.CreateLocalCollection, this.DestroyLocalCollection,4)
    this.RegNewUnit("selfCollection", this.CreateSelfCollection, this.DestroySelfCollection,5)
    this.RegNewUnit("article", this.CreateArticle, this.DestroyArticle,6)
    this.RegNewUnit("plantom", this.CreatePlantom, this.DestroyPlantom)
    this.RegNewUnit("anchorpoint", this.CreateAnchorPoint, this.DestroyAnchorPoint)
    this.RegNewUnit("ghostshadow", this.CreateGhostShadow, this.DestroyGhostShadow)
    this.RegNewUnit("effect", this.CreateEffect, this.DestroyEffect)
    this.RegNewUnit("architecture",this.CreateArchitecture,this.DestroyArchitecture)
    this.RegNewUnit("jiguan",this.CreateJiGuan,this.DestroyJiGuan,7)
    this.RegNewUnit("missile",this.CreateMissile,this.DestroyMissile)
    this.RegNewUnit("fakeunit",this.CreateFakeUnit,this.DestroyFakeUnit)
    this.RegNewUnit("animal",this.CreateAnimal,this.DestroyAnimal, 8)
    this.RegNewUnit("animation_interaction",this.CreateInteraction,this.DestroyInteraction)
    this.RegNewUnit("chron",this.CreateChron,this.DestroyChron)
    this.RegNewUnit("minor_npc",this.CreateMinorNpc,this.DestroyMinorNpc)

    this.RegNewUnit("spirit",this.CreateSpirit,this.DestroySpirit)
    this.RegNewUnit("clone",this.CreateClone,this.DestroyClone)

    this.delayAddUnit = List.new()
    --统一删除目标接口
    this.delayRemoveUnit = {}
    --缓存延时删除
    this.cacheRemoveUnit = {}
    this.phyColliderList = {}
end

function UnitManager.RegNewUnit(typename, createfun, destroyfun, priority)
    this[typename .. "s"] = {}
    this.unitFactory[typename] = { createfun, destroyfun, this[typename .. "s"] ,priority}
end

function UnitManager.OnEnterGame()
    this.RegistEvents()
    this.RegistMessages()
end
----------------------------------------------------------------------------
--role

function UnitManager.CreateHero(msg)
    local data = {
        id = LocalData.hero.id,
        job = LocalData.hero.data.job,
        localtype = UNIT_LOCAL_TYPE.HERO,
        wing_order = WaiFuSoulBoneManager.wfSoulBoneData:GetOrder_lv()
    }
    LocalData.hero:SetData(msg)
    this.AddUnit("role", data)
    EventManager.Dispatch(Event.Game_Role_Create)
end

function UnitManager.LoadNpcsAndArticle()
    UnitViewManager.Load("npc")
    UnitViewManager.Load("dropitem")
    UnitViewManager.Load("selfCollection")
    UnitViewManager.Load("anchorpoint")
    UnitViewManager.Load("architecture")
    UnitViewManager.Load("animation_interaction")
    UnitViewManager.Load("localcollection")
    UnitViewManager.Load("chron")
    if JiGuanManager.rwdMap and JiGuanManager.signMap then
        UnitViewManager.Load("jiguan")
        UnitViewManager.Load("farjiguan")
    end
    UnitViewManager.Load("animal")
    UnitViewManager.Load("minor_npc")
    --UnitViewManager.LoadArticle()
end

-- function UnitManager.LoadNpc(v)
--     local data =
--     {
--         id = NPCID_Start + v.id,
--         localtype = UNIT_LOCAL_TYPE.NPC,
--         cfg = v,
--     }
--     this.AddUnit("npc", data, true)
-- end

-- function UnitManager.RemoveNpc(id)
--     this.DestroyUnit("npc", NPCID_Start + id)
-- end

-- function UnitManager.LoadArticle(v)
--     local data =
--     {
--         id = v.id,
--         localtype = UNIT_LOCAL_TYPE.ARTICLE,
--         cfg = v,
--     }
--     this.AddUnit("article", data, true)
-- end

-- function UnitManager.RemoveArticle(id)
--     this.DestroyUnit("article", id)
-- end

--function UnitManager.LoadTransfers()
--    local doors = ConfigManager.GetConfigTable(ConfigName.MapDoor)
--    for k, v in ipairs(doors) do
--        if v.map == Scene.sceneID then
--            this.LoadTransfer(v)
--        end
--    end
--end
--
--function UnitManager.LoadTransfer(v)
--    local data = {
--        id = TRANSFERID_Start + v.id,
--        localtype = UNIT_LOCAL_TYPE.TRANSFER,
--        cfg = v,
--    }
--    this.CreateUnit("transfer", data)
--end

function UnitManager.Update()
    this.doUpdate = true
    for _, v in pairs(this.unitFactory) do
        --Profiler.BeginSample(_ .. " Update")
        for _, unit in pairs(v[3]) do
            if unit and unit.Update then
                unit:Update()
            end
        end
        --Profiler.EndSample()
    end
    this.doUpdate = false
    this.UpdatedelayRemove()
    this.UpdateUnitView()
    UnitViewManager.Update()
    this.UpdatedelayLoad()
    this.UpdateInput()
end

local Input = CS.UnityEngine.Input
local PhysicsEx = CS.TCFramework.PhysicsEx
local KeyCode = CS.UnityEngine.KeyCode
local _value = 150
function UnitManager.UpdateInput()
    if Input.GetMouseButtonDown(0) and not MainCamera.IsClickUI() then
        --logError(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
        local go, x, y, z = PhysicsEx.MouseRaycast(MainCamera.camera, LAYER_MASK.Role)
        if go then
            --logError("hit", go.name, go.transform.parent.name)
            local unit = this.GetColliderUnit(go:GetInstanceID())
            if unit and unit.isHero then
                if unit.OnClicked then
                    unit:OnClicked()
                end
            end
        end
    end
    if Input.GetKeyDown(KeyCode.K) then
       --HunliPKManager.CM_ATTACK_PK_ACT(4,1)
       --UnitManager.MagicaClothSetting(60,1)
        --EventManager.Dispatch(Event.UI_Game_Show_PopUp, PopUpEnum.Course,{1})
    end
    -- if Input.GetKeyDown(KeyCode.J) then  --爵位按键临时
    --     local msg = {order = 2,index = 4,record = 3,value = 3000 }
    --     BloodAwakeMananger.SM_BLOOD_AWAKE_INFO(msg)
    -- end
    --if Input.GetKeyDown(KeyCode.H) then
    --    local unit = this.hero
    --    --测试冒血数字
    --    --unit.Head:CreateHUDNumber(Font_Label_Type.HealLabel, 100)
    --    --unit.Head:CreateHUDNumber(Font_Label_Type.DotLabel)
    --    --unit.Head:CreateHUDNumber(Font_Label_Type.CritLabel, 123, 0, unit.buffState)
    --    --unit.Head:CreateHUDNumber(Font_Label_Type.DamageLabel, 321, 0, unit.buffState)
    --
    --    Scene.OnTerrainLoadComplete(Vector3(0,0,0), Vector3(8000,8000,8000))
    --end
end

--延时加载
function UnitManager.UpdatedelayLoad()
    --3帧1个
    local count = 0
    if Scene.loaded then
        --先处理delayAdd
        --列表没法删除中间对象，所以删除是采用置空的操作，这里要循环判定，直到找到一个不为空的值
        while not List.empty(this.delayAddUnit) do
            local args = List.popFront(this.delayAddUnit)
            if args then
                this.CreateUnit(table.unpack(args))
                count = count + 1
                if count > 1 then
                    break
                end
            end
        end
    end
end

function UnitManager.UpdatedelayRemove()
    if Scene.loaded then
        --再处理cacheRemove
        for k, v in pairs(this.cacheRemoveUnit) do
            k:Update()
            if k:CanRemove() then
                k:Destroy()
                this.cacheRemoveUnit[k] = nil
            end
        end

        --最后处理DelayRemove
        for k, v in pairs(this.delayRemoveUnit) do
            for k2, v2 in pairs(v) do
                k[v2] = nil
                v[k2] = nil
            end
        end
    end
end

--处理视野
function UnitManager.UpdateUnitView()
    --每秒1次
    --TODO 逻辑待优化
    if this.checkViewTime and Time.unscaledTime - this.checkViewTime < 0.5 then
        return
    end
    this.checkViewTime = Time.unscaledTime

    --主角在剧情模式下，不再处理这个函数
    if not this.hero or not this.hero:InView() then
        return
    end
    --处理npc和传送门的视野
    for _, v in pairs(this.npcs) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.transfers) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.articles) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.collections) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.localcollections) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.dropitems) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.monsters) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.selfCollections) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.architectures) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.jiguans) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.animals) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for _, v in pairs(this.animation_interactions) do
        if v then
            v:CheckView(this.hero)
        end
    end
    for i, v in pairs(this.chrons) do
        if v then
            v:CheckView(this.hero)
        end
    end

    for i, v in pairs(this.minor_npcs) do
        if v then
            v:CheckView(this.hero)
        end
    end

    for _, v in pairs(this.roles) do
        if v.isPlayer then
            v:CheckDyingAndCanCure(this.hero)
        end
        if v.isPlayer or v.isHero then
            v:UpdateElementVisionState()
        end
    end
    UnitAnchorPoint.CheckAllState()
end

function UnitManager.LateUpdate()
    for _, v in pairs(this.unitFactory) do
        for _, unit in pairs(v[3]) do
            if unit and unit.LateUpdate then
                unit:LateUpdate()
            end
        end
    end

    --计算当前目标与主角位置
    if this.hero ~= nil and MyTarget.GetMyTarget() ~= nil then
        local target = MyTarget.GetMyTarget()
        local targetPos = target.pos
        local heroPos = this.hero.pos
        if mathEx.GetSqrDistance(targetPos.x, targetPos.z, heroPos.x, heroPos.z) >= 400 then
            --TODO 当大于20距离时 目标丢失
            MyTarget.ClearTarget()
        end
    end
end

function UnitManager.CreateUnit(typename, data)
    if this.unitFactory[typename] then
        local unit = this.unitFactory[typename][1](data)
        --logError(typename, unit and unit.id or "未创建", unit and unit.state.model or "")
        if this.unitFactory[typename][4] and unit and unit.state.model == UNIT_MODEL_STATE.CanLoad then
            --有加载优先级设置,且单位创建成功，且单位处于可加载情况（不然代表原业务控制时机加载创建）
            unit.state.model = UNIT_MODEL_STATE.None
            UnitLoadManager.Load(unit, this.unitFactory[typename][4])
        end
        if unit and unit.isMonster then
            unit:SetFighting(data.inBattle)
        end
        if unit and unit.isHero then
            if UnitManager.heroInBattle then
                unit:SetFighting(UnitManager.heroInBattle[unit.id])
            end
            
        end
        return unit
    end
end

function UnitManager.DestroyUnit(typename, id)
    if this.unitFactory[typename] then
        this.unitFactory[typename][2](id)
    end
end

function UnitManager.DestroyUnits(isDestroyHero)
    --销毁所有unit
    for k, v in pairs(this.unitFactory) do
        for k2, unit in pairs(v[3]) do
            if not unit.isHero or isDestroyHero then
                if unit and unit.Destroy  then
                    unit:Destroy()
                end
                v[3][k2] = nil
            end
        end
    end

    if isDestroyHero then
        this.hero = nil
    else
        --hero的重置逻辑
        if this.hero then
            this.hero:ResetWhenChangeScene()
        end
    end
    
    List.clear(this.delayAddUnit)
    for k, v in pairs(this.cacheRemoveUnit) do
        if k and k.Destroy then
            k:Destroy()
        end
        this.cacheRemoveUnit[k] = nil
    end
  
    UnitViewManager.Init()
end

function UnitManager.GetUnitByServerHandle(target)
    if not target or target.id == 0 then
        return
    end

    return this.GetUnitByServerHandle2(target.type, target.id)
end

function UnitManager.GetUnitByServerHandle2(type, id)
    if type == UnitType.UT_MONSTER then
        return this.GetUnit("monster", id)
    elseif type == UnitType.UT_PLAYER then
        return this.GetUnit("role", id)
    elseif type == UnitType.UT_COLLECTION then
        return this.GetUnit("collection", id)
    elseif not type then
        return this.GetUnit(nil, id)
    end
end

function UnitManager.GetUnitDigState(dig_cid)
    local cid = LocalData.hero.data.cid
    for _, v in ipairs(dig_cid) do
        if v == cid then
            return true
        end
    end
    return false
end

function UnitManager.AddUnit(type, msg, delay)
    if not Scene.loaded or delay then
        List.pushBack(this.delayAddUnit, { type, msg })
    else
        this.CreateUnit(type, msg)
    end
end

function UnitManager.RemoveDelayUnit(id)
    List.walk(this.delayAddUnit, this.WalkDelayList, id)
end

function UnitManager.WalkDelayList(index, value, id)
    if value and value[2].id == id then
        this.delayAddUnit[index] = nil
        return true
    end
end

--检测指定Unit是否合法
function UnitManager.IsUnitAlive(unit, checkDead)
    if unit and not IsObjectNil(unit.gameObject) and not unit.bDestroy and unit.model then
        if checkDead == false then
            return true
        elseif not unit.IsDead or not unit:IsDead() then
            return true
        end
    end
    return false
end

--尝试删除unit
function UnitManager.TryRemoveUnit(t, id)
    if this.doUpdate then
        if not this.delayRemoveUnit[t] then
            this.delayRemoveUnit[t] = {}
        end
        table.insert(this.delayRemoveUnit[t], id)
    else
        t[id] = nil
    end
end

--检测指定Role是否合法
function UnitManager.IsRoleAlive(role, checkDead)
    --这里默认传入的都是UnitRole,不再检测类型是否正确了
    if this.IsUnitAlive(role, checkDead) then
        --todo 检测血量是否大于0
        return true
    end

    return false
end

function UnitManager.CreateRole(data)
    assert(this.roles[data.id] == nil, "CreateRole id=" .. data.id .. " localtype=" .. data.localtype)
    local role
    if data.localtype == UNIT_LOCAL_TYPE.HERO then
        role = UnitHero(data)
    elseif data.localtype == UNIT_LOCAL_TYPE.PLAYER then
        role = UnitPlayer(data)
    elseif data.localtype == UNIT_LOCAL_TYPE.SIMPLEROLE then
        role = UnitSimpleRole(data)
    else
        return
    end

    this.roles[role.id] = role
    if role.isHero then
        this.hero = role
        if this.hideMask & UNIT_LOCAL_MASK.HERO > 0 then
            role:SetTypeVisible(false)
        end
    else
        if this.hideMask & UNIT_LOCAL_MASK.PLAYER > 0 then
            role:SetTypeVisible(false)
        end
    end

    return role
end

function UnitManager.DestroyRole(id)
    local role = this.roles[id]
    if role then
        this.TryRemoveUnit(this.roles, id)
        role:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end
function UnitManager.GetRole(id)
    local role = this.roles[id]
    if role ~= nil then
        return role
    end
    if id == -1 then
        return this.hero
    end
    return
end

--function UnitManager.CreateTransfer(data)
--    assert(this.transfers[data.id] == nil, "CreateTransfer id=" .. data.id)
--    local t = UnitTransfer(data)
--
--    this.transfers[data.id] = t
--    return t
--end
--
--function UnitManager.DestroyTransfer(id)
--    local t = this.transfers[id]
--    if t then
--        this.TryRemoveUnit(this.transfers, id)
--        t:Destroy()
--    else
--        --清理delay里添加的
--        UnitManager.RemoveDelayUnit(id)
--    end
--end
--function UnitManager.GetTransfer(id)
--    local r = this.transfers[id]
--    if r ~= nil then
--        return r
--    end
--    return
--end

--region Npc

function UnitManager.CreateNPC(data)
    if this.npcs[data.id] ~= nil then
        return
    end

    local t = UnitNPC(data)

    if this.hideMask & UNIT_LOCAL_MASK.NPC > 0 then
        t:SetTypeVisible(false)
    end

    this.npcs[data.id] = t
    for id, funcs in pairs(this.createNpcCallBackList) do
        if t:GetRealID() == id then
            for _, v in pairs(funcs) do
               v.func()
            end
            this.createNpcCallBackList[id] = {}
        end
    end

    return t
end

---@ 添加一个当npc生成后的回调
function UnitManager.SetCreateNpcCallback(realId , callback , className)
    if not this.createNpcCallBackList then
        this.createNpcCallBackList = {}
    end
    if not this.createNpcCallBackList[realId] then
        this.createNpcCallBackList[realId] = {}
    else

        for i, v in pairs(this.createNpcCallBackList[realId]) do
            if v.className == className then
                return
            end
        end
    end
    table.insert(this.createNpcCallBackList[realId] ,{className = className , func = callback})
end


function UnitManager.DestroyNPC(id)
    local t = this.npcs[id]
    if t then
        this.TryRemoveUnit(this.npcs, id)
        t:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetNPC(id)
    local r = this.npcs[id]
    if r ~= nil then
        return r
    end
    return
end
---@获取npc模型
function UnitManager.GetNPCByRealID(id)
    for k, v in pairs(this.npcs) do
        if v:GetRealID() == id then
            return v
        end
    end
end

---@ 重置npc位置
function UnitManager.InitNPCPosition()
    for k, v in pairs(this.npcs) do
        v:InitPosition()
    end
end

---@ 停止当前场景中npc的行为树
function UnitManager.StopUnitTree()
    if not this.npcs then
        return
    end

    LPrint.log(ColorCode.Red,"停止行为树")
    for _, unit in pairs(this.npcs) do
        if unit.p2pTree then
            BehaviourTreeMgr.UnloadTree(nil,true,unit:GetName()) --暂停行为树
        end
        unit:ResetPosition()
        unit:ResetToDefaultDir()
    end
    this.npcTreeIsPause = false
end

---@ 重置当前场景中npc的行为树
function UnitManager.ResetUnitTree()
    this.npcTreeIsPause = false
    if not this.npcs then
        return
    end

    LPrint.log(ColorCode.Red , "重置行为树")
    for _, unit in pairs(this.npcs) do
        unit:StartMoveFindIng()
    end
end

---@ 暂停当前行为树
function UnitManager.PauseUnitTree()

    this.npcTreeIsPause = true

    if not this.npcs then
        return
    end

    LPrint.log(ColorCode.Yellow , "npc行为树 暂停")

    for _, unit in pairs(this.npcs) do
        if unit.p2pTree then
            BehaviourTreeMgr.Pause(unit:GetName())
        end
    end
end

---@ 行为树从暂停中恢复
function UnitManager.ResumeUnitTree()

    this.npcTreeIsPause = false

    if not this.npcs then
        return
    end

    LPrint.log(ColorCode.Yellow , "npc行为树 恢复")

    for _, unit in pairs(this.npcs) do
        if unit.p2pTree then
            BehaviourTreeMgr.Resume(nil, unit:GetName())
        end
    end

end


--endregion

--region -- minorNpc --

function UnitManager.CreateMinorNpc(data)

    if this.minor_npcs[data.groupId] ~= nil then
        return
    end

    local t = UnitMinorNpc(data)

    if this.hideMask & UNIT_LOCAL_MASK.NPC > 0 then
        t:SetTypeVisible(false)
    end

    this.minor_npcs[data.groupId] = t

    return t
end

function UnitManager.GetMinorNpc(id)
    return this.minor_npcs[id]
end

function UnitManager.GetMinorNpcGroup(id)
    -- 粗略可以搞 id / 10 匹配
    local o = this.minor_npcs[id]
    local t = {}
    for i, v in pairs(this.minor_npcs) do
        if v.data.originalGroup == o.data.originalGroup then
            table.insert(t, v)
        end
    end
    return t
end

function UnitManager.DestroyMinorNpc(id)
    local t = this.minor_npcs[id]

    if t then
        this.TryRemoveUnit(this.minor_npcs,id)
        t:Destroy()
    else
        -- 清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end


--endregion


-----------------------------------------------------------
--monster
function UnitManager.CreateMonster(data)
    assert(this.monsters[data.id] == nil, "CreateMonster id=" .. data.id)

    --根据类型区分是怪物还是幻影
    local t
    local monsterData = LocalData.GetPlayer(data.id)
    if monsterData and monsterData.data and monsterData.data.owner_id > 0 then
        --先找到归属者
        local owner = this.GetUnitByServerHandle2(monsterData.data.owner_type, monsterData.data.owner_id)
        if owner then
            data.owner = owner
            local cfg = ConfigManager.GetConfig(ConfigName.Monster, monsterData.data.monster_id, "id")
            if cfg and cfg.model == "monster_ghost" then
                t = UnitPlantom(data)
            end

            -- check cloneunit
        else
            --找不到归属者就不创建了
            return
        end
    end
    if data.digcid and #data.digcid > 0 then
        local cfg = ConfigManager.GetConfig(ConfigName.Monster, data.monsterid, "id")
        --挖过尸体的不创建
        if cfg and cfg.corpse_cost > 0 and this.GetUnitDigState(data.digcid) then 
            return
        end
    end
    if not t then
        t = UnitMonster(data)
    end

    if this.hideMask & UNIT_LOCAL_MASK.MONSTER > 0 then
        t:SetTypeVisible(false)
    end

    this.monsters[data.id] = t
    return t
end

function UnitManager.DestroyMonster(id)
    local t = this.monsters[id]
    if t then
        this.TryRemoveUnit(this.monsters, id)
        --logError(t.hp)
        if t:NeedCacheRemove() then
            this.AddCacheRemove(t)
        else
            t:Destroy()
        end
    else
        --清理delay里添加的
        this.RemoveDelayUnit(id)
    end
end

function UnitManager.GetMonster(id)
    local r = this.monsters[id]
    if r ~= nil then
        return r
    end
    return
end

--根据地图怪物id来获取怪物
function UnitManager.GetMonsterByMapMonsterID(id)
    for k, v in pairs(this.monsters) do
        if v.roleData.map_monster_id == id then
            return v
        end
    end
end
-----------------------------------------------------------
--cacheremove
function UnitManager.AddCacheRemove(unit)
    this.cacheRemoveUnit[unit] = true
end

-----------------------------------------------------------
--trap
function UnitManager.CreateTrap(data)
    assert(this.traps[data.id] == nil, "CreateTrap id=" .. data.id)
    local t = UnitTrap(data)

    if this.hideMask & UNIT_LOCAL_MASK.TRAP > 0 then
        t:SetTypeVisible(false)
    end

    this.traps[data.id] = t
    return t
end

function UnitManager.DestroyTrap(id)
    local t = this.traps[id]
    if t then
        this.TryRemoveUnit(this.traps, id)
        t:Destroy()
    else
        --清理delay里添加的
        this.RemoveDelayUnit(id)
    end
end

function UnitManager.GetTrap(id)
    local r = this.traps[id]
    if r ~= nil then
        return r
    end
    return
end

-----------------------------------------------------------
--tempModel
function UnitManager.CreateTempModel(data)
    assert(this.tempmodels[data.id] == nil, "CreateTempModel id=" .. data.id)
    local t = UnitTempModel(data)

    this.tempmodels[data.id] = t
    return t
end

function UnitManager.DestroyTempModel(id)
    local t = this.tempmodels[id]
    if t then
        this.TryRemoveUnit(this.tempmodels, id)
        t:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetTempModel(id)
    local r = this.tempmodels[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllTempModel()
    for k, v in pairs(this.tempmodels) do
        v:Destroy()
        this.tempmodels[k] = nil
    end
end

-----------------------------------------------------------
--dropitem
function UnitManager.CreateDropItem(data)
    assert(this.dropitems[data.id] == nil, "CreateDropItem id=" .. data.id)
    local t = UnitDropItem(data)

    this.dropitems[data.id] = t
    return t
end

function UnitManager.DestroyDropItem(id)
    local t = this.dropitems[id]
    if t then
        this.TryRemoveUnit(this.dropitems, id)
        t:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetDropItem(id)
    local r = this.dropitems[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllDropItem()
    for k, v in pairs(this.dropitems) do
        v:Destroy()
        this.dropitems[k] = nil
    end
end

-----------------------------------------------------------
--collection
function UnitManager.CreateCollection(data)
    assert(this.collections[data.id] == nil, "CreateCollection id=" .. data.id)
    local t = UnitCollection(data)

    this.collections[data.id] = t
    return t
end

function UnitManager.DestroyCollection(id)
    local t = this.collections[id]
    if t then
        this.TryRemoveUnit(this.collections, id)
        t:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetCollection(id)
    local r = this.collections[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllCollection()
    for k, v in pairs(this.collections) do
        v:Destroy()
        this.collections[k] = nil
    end
end

-----------------------------------------------------------
--localcollection
function UnitManager.CreateLocalCollection(data)
    assert(this.localcollections[data.id] == nil, "CreateLocalCollection id=" .. data.id)
    local t = UnitLocalCollection(data)

    this.localcollections[data.id] = t
    return t
end

function UnitManager.DestroyLocalCollection(id)
    local t = this.localcollections[id]
    if t then
        this.TryRemoveUnit(this.localcollections, id)
        t:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetLocalCollection(id)
    local r = this.localcollections[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllLocalCollection()
    for k, v in pairs(this.localcollections) do
        v:Destroy()
        this.localcollections[k] = nil
    end
end

-----------------------------------------------------------
--uimodel
function UnitManager.CreateUIModel(data)
    assert(this.uimodels[data.id] == nil, "CreateUIModel id=" .. data.id)
    local t = UnitUIModel(data)

    this.uimodels[data.id] = t
    return t
end

function UnitManager.DestroyUIModel(id)
    local t = this.uimodels[id]
    if t then
        this.TryRemoveUnit(this.uimodels, id)
        t:Destroy()
    end
end
-----------------------------------------------------------
--fakeunit
function UnitManager.CreateFakeUnit(data)
    LPrint.log(ColorCode.Yellow,data)
    assert(this.fakeunits[data.id] == nil, "CreateFakeUnit id=" .. data.id)
    local t = UnitFakeUnit(data)

    this.fakeunits[data.id] = t
    return t
end

function UnitManager.DestroyFakeUnit(id)
    local t = this.fakeunits[id]
    if t then
        this.TryRemoveUnit(this.fakeunits, id)
        t:Destroy()
    end
end
function UnitManager.InitPosition()
    for k, v in pairs(this.roles) do
        v:InitPosition()
    end
end

function UnitManager.RefreshHeight(minPos, maxPos)
    for k, v in pairs(this.roles) do
        v:RefreshHeight(minPos, maxPos)
    end
    for k, v in pairs(this.monsters) do
        v:RefreshHeight(minPos, maxPos)
    end
    for k, v in pairs(this.traps) do
        v:RefreshHeight(minPos, maxPos)
    end
    for k, v in pairs(this.npcs) do
        v:RefreshHeight(minPos, maxPos)
    end
    for k, v in pairs(this.transfers) do
        v:RefreshHeight(minPos, maxPos)
    end
    for k, v in pairs(this.collections) do
        v:RefreshHeight(minPos, maxPos)
    end
    for k, v in pairs(this.localcollections) do
        v:RefreshHeight(minPos, maxPos)
    end
    for k, v in pairs(this.dropitems) do
        v:RefreshHeight(minPos, maxPos)
    end
    for _, v in pairs(this.selfCollections) do
        v:RefreshHeight(minPos, maxPos)
    end
    for _, v in pairs(this.jiguans) do
        v:RefreshHeight(minPos, maxPos)
    end
    for _, v in pairs(this.animals) do
        v:RefreshHeight(minPos, maxPos)
    end
end

function UnitManager.SetLocalScale(id, x, y, z)
    local role = this.GetRole(id)
    if role == nil then
        return
    end
    role:SetLocalScale(x, y, z)
end

function UnitManager.SetLocalPosition(id, x, y, z)
    local role = this.GetRole(id)
    if role == nil then
        return
    end
    role:SetLocalPosition(x, y, z)
end
-----------------------------------------------------------
--article
function UnitManager.CreateArticle(data)
    assert(this.articles[data.id] == nil, "CreatArticle id=" .. data.id)
    local t = UnitArticle(data)
    this.articles[data.id] = t
    return t
end

function UnitManager.DestroyArticle(id)
    local t = this.articles[id]
    if t then
        this.TryRemoveUnit(this.articles, id)
        t:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetArticle(id)
    local r = this.articles[id]
    if r ~= nil then
        return r
    end
end

function UnitManager.ClearAllArticle()
    for k, v in pairs(this.articles) do
        v:Destroy()
        this.articles[k] = nil
    end
end

-----------------------------------------------------------
--幻影
local curPhantomID = 0
function UnitManager.CreatePlantom(data)
    curPhantomID = curPhantomID + 1
    data.index = PHANTOM_Start + curPhantomID
    assert(this.plantoms[data.id] == nil, "CreatPlantom id=" .. data.id)
    local t = UnitPlantom(data)
    this.plantoms[data.index] = t
    return t
end

function UnitManager.DestroyPlantom(id)
    local t = this.plantoms[id]
    if t then
        this.TryRemoveUnit(this.plantoms, id)
        t:Destroy()
    else
        --清理delay里添加的
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetPlantom(id)
    local r = this.plantoms[id]
    if r ~= nil then
        return r
    end
end

function UnitManager.ClearAllPlantom()
    for k, v in pairs(this.plantoms) do
        v:Destroy()
        this.plantoms[k] = nil
    end
end

-----------------------------------------------------------
--残影
function UnitManager.CreateGhostShadow(data)
    assert(this.ghostshadows[data.id] == nil, "CreatGhostShadow id=" .. data.id)
    local t = UnitGhostShadow(data)
    this.ghostshadows[data.id] = t
    return t
end

function UnitManager.DestroyGhostShadow(id)
    local t = this.ghostshadows[id]
    if t then
        this.TryRemoveUnit(this.ghostshadows, id)
        t:Destroy()
    end
end

function UnitManager.GetGhostShadow(id)
    local r = this.ghostshadows[id]
    if r ~= nil then
        return r
    end
end

function UnitManager.ClearAllGhostShadow()
    for k, v in pairs(this.ghostshadows) do
        v:Destroy()
        this.ghostshadows[k] = nil
    end
end

--------------------------------------------------------------------------------
--地图挂点
function UnitManager.CreateAnchorPoint(data)
    local id = data.id + ANCHORPOINT_Start
    assert(this.anchorpoints[id] == nil, "CreatAnchorPoint id=" .. data.id)
    local t = UnitAnchorPoint(data)
    this.anchorpoints[id] = t
    return t
end

function UnitManager.DestroyAnchorPoint(id)
    local id = id + ANCHORPOINT_Start
    local t = this.anchorpoints[id]
    if t then
        this.TryRemoveUnit(this.anchorpoints, id)
        t:Destroy()
    end
end

function UnitManager.GetAnchorPoint(id)
    local id = id + ANCHORPOINT_Start
    local r = this.anchorpoints[id]
    if r ~= nil then
        return r
    end
end

function UnitManager.ClearAllAnchorPoint()
    for k, v in pairs(this.anchorpoints) do
        v:Destroy()
        this.anchorpoints[k] = nil
    end
end

--------------------------------------------------------------------------------
-- events
function UnitManager.RegistEvents()
    --[[
        @desc:
        author:{author}
        time:2022-07-28 19:33:28
        @return:
    ]] 
    --this.eventContainer:Regist(Event.Game_SceneLoaded, this.RefreshHeight)
    this.eventContainer:Regist(Event.Game_Role_Move_From, this.RoleMoveFrom)
    this.eventContainer:Regist(Event.Game_Role_Move_To, this.RoleMoveTo)
    this.eventContainer:Regist(Event.Game_Role_Tran_To, this.RoleTranTo)
    this.eventContainer:Regist(Event.Game_Role_Move_Path, this.RoleMovePath)
    this.eventContainer:Regist(Event.Game_Role_Move_Stop, this.RoleMoveStop)
    --this.eventContainer:Regist(Event.Game_Role_Move_Mode, this.RoleMoveMode)
    this.eventContainer:Regist(Event.Game_Role_Open_Wings, this.RoleOpenWings)
    this.eventContainer:Regist(Event.Game_Role_Instant, this.RolePullBack)
    this.eventContainer:Regist(Event.Game_Role_JumpStart, this.RoleJumpStart)
    this.eventContainer:Regist(Event.Game_Role_JumpEnd, this.RoleJumpEnd)
    this.eventContainer:Regist(Event.Game_Role_FallGround, this.RoleFallGround)
    this.eventContainer:Regist(Event.GamePlay_HeroRoleLoadFinish, this.NpcLookAtTargetBind)
    this.eventContainer:Regist(Event.GamePlay_SyncMCPositionByVC, this.SyncMCPositionByVC)
    this.eventContainer:Regist(Event.UI_Open_SkillSpell,this.BreakInAnimation)
    this.eventContainer:Regist(Event.Game_Hero_Resurgence,this.AwaitResurgence)
    local handleList = {
        Event.Game_Role_UpdateEquip,
        Event.Game_Role_Update_Dress,
        Event.Game_Role_Update_AttrSpeed,
        Event.Game_Role_Update_HP,
        Event.Game_Trap_Update_Time,
        Event.Game_Trap_Update_Side,
        --Event.Game_Role_Update_BuffShow,
        Event.Game_Collection_Update,
        Event.Game_LocalCollection_Update,
        Event.Game_Monster_PlayAnim,
        Event.Game_Role_Buff,
        Event.Game_Role_Buff_Special,
        Event.Game_AddElementBall,
        Event.Game_Player_Fast_Move,
        Event.Game_Role_GrowUp,
        Event.Game_Hero_Init_HunHuan,
        Event.GamePlay_MapLoadFinish,
        Event.Game_Monster_Lost_KeyDecoration,
        Event.Game_Collection_Update_KeyDecoration,
        Event.Game_Monster_Update_KeyDecoration,
        Event.Game_Role_Update_Wing,
        Event.Game_Unit_Host_Change,
        Event.Game_Unit_Net_Play_Action,
        Event.Game_Unit_Net_Update_Pos,
        Event.Game_Player_ChangeForce,
        Event.Game_HunliPK_OtherView,
        Event.Game_Unit_Set_Dir,
        Event.Game_Monster_Start_Dig,
        Event.Game_Monster_Finish_Dig,
        Event.Game_Monster_EventNotify,
        Event.GamePlay_TELEPORTMap,
        Event.Game_Role_Buff_Element,
        Event.Game_RefreshBasicSet,
    }
    for _, v in ipairs(handleList) do
        this.eventContainer:Regist(v, this.EventHandle)
    end
end

function UnitManager.EventHandle(event,arg_1,arg_2,arg_3,arg_4)
    --local args = { ... }
    if event == Event.Game_Role_UpdateEquip then
        local role = this.GetRole(arg_1)
        if role then
            role:UpdateEquip()
        end
    elseif event == Event.Game_Role_Update_Dress then
        local role = this.GetUnit(nil, arg_1)
        if role then
            ---更新时装
            role:UpdateModelPart(MODEL_PART_TYPE.Dress)
        end
    elseif event == Event.Game_Role_Update_AttrSpeed then
        local role = this.GetUnit(nil, arg_1)
        if role then
            role:UpdateAttrSpeed(arg_2)
        end
    elseif event == Event.Game_Role_Update_HP then
        local role = this.GetUnit(nil, arg_1)
        if role then
            role:UpdateHp(arg_2)
        end
    -- elseif event == Event.Game_Role_Update_BuffShow then
    --     local role = this.GetUnit(nil, args[1])
    --     if role then
    --         role:UpdateBuffState(args[2])
    --     end
    elseif event == Event.Game_Trap_Update_Time then
        local role = this.GetUnit("trap", arg_1)
        if role then
            role:UpdateTime(arg_2,arg_3,arg_4)
        end
    elseif event == Event.Game_Trap_Update_Side then
        local role = this.GetUnit("trap", arg_1)
        if role then
            role:UpdateSide(arg_2,arg_3)
        end
    elseif event == Event.Game_Collection_Update then
        local collection = this.GetCollection(arg_1.entity_id)
        if collection then
            collection:UpdateState(arg_1.state)
        end
    elseif event == Event.Game_LocalCollection_Update then
        local collection = this.GetLocalCollection(arg_1.bid)
        if collection then
            collection:UpdateInfo(arg_1)
        end
    elseif event == Event.Game_Monster_PlayAnim then
        local monster = this.GetMonster(arg_1)
        if monster then
            if monster.initActionMgr then
                monster:RunNetAction(arg_2)
            else
                monster:PlayNetAction(arg_2, arg_4, arg_3)
            end
            
            
        end
    elseif event == Event.Game_Role_Buff then
        local role = this.GetUnit(nil, arg_1)
        if role then
            role:UpdateBuff()
        end
    elseif event == Event.Game_Role_Buff_Special then
        local role = this.GetUnit(nil, arg_1)
        if role then
            role:UpdateBuffSpecial(arg_2, arg_3)
        end

    elseif event == Event.Game_AddElementBall then
        local role = this.GetUnit(nil, arg_1)
        if role and role.AddNewElement then
            role:AddNewElement(arg_2)
        end
    elseif event == Event.Game_Player_Fast_Move then
        local role = this.GetUnit("role", arg_1)
        if role then
            role:SetFastMove(arg_2)
        end
    elseif event == Event.Game_Role_GrowUp then
        local role = this.GetUnit("role", arg_1)
        if role then
            role:ReloadModel()
        end
    elseif event == Event.Game_Unit_Host_Change then
        local role = this.GetUnit(nil, arg_1)
        if role then
            role:HostChange()
        end
    elseif event == Event.Game_Unit_Net_Play_Action then
        local unit = this.GetUnit(nil, arg_1)
        if unit then
            unit:RunNetAction(arg_2)
        end
    elseif event == Event.Game_Unit_Net_Update_Pos then
        local unit = this.GetUnit(nil, arg_1)
        if unit then
            unit:UpdateNetPos(arg_2, arg_3)
        end
    elseif event == Event.Game_Hero_Init_HunHuan then

    elseif event == Event.GamePlay_MapLoadFinish then
        SkillTable.CleanCacheOrder()
        --判定是否需要添加模拟怪物
        -- local mapid, monster_info, hunhuan = HunHuanInfoManager.GetNextUnLockInfo()
        -- if mapid and monster_info then
        --     if mapid == Scene.sceneID then
        --         --写死特殊流程
        --         local digMonsterID = 99999999
        --         if not this.monsters[digMonsterID] then
        --             --获取真实的怪物模型
        --             local cfg = ConfigManager.GetConfig(ConfigName.Map_Monster, monster_info[1])
        --             if cfg then
        --                 this.CreateMonster({id = digMonsterID, monster_id = cfg.monster, initPos = Vector3(monster_info[2],monster_info[3],monster_info[4]), hunhuan = hunhuan, hp = 0})
        --             end
        --         end
        --     end
        -- end
    elseif event == Event.Game_Monster_Lost_KeyDecoration then
        if arg_2 then
            --遍历所有本地宝箱
            local bFind = false
            for k, v in pairs(this.localcollections) do
                if v:AddKeyEffect(arg_1, arg_2) then
                    bFind = true
                    break
                end
            end
            if not bFind then
                arg_2:Destroy()
            end
        end
    elseif event == Event.Game_Monster_Update_KeyDecoration then
        --遍历怪物，发通知
        for k, v in pairs(arg_1) do
            for k2, v2 in pairs(this.monsters) do
                if v2.roleData.map_monster_id == k then
                    v2:UpdateKeyEffect()
                end
            end
        end
    elseif event == Event.Game_Collection_Update_KeyDecoration then
        --遍历宝箱，发通知
        for k, v in pairs(arg_1) do
            for k2, v2 in pairs(this.localcollections) do
                if v2.id == k then
                    v2:UpdateKeyEffect()
                    break
                end
            end
        end
    elseif event == Event.Game_Role_Update_Wing then --更新玩家翅膀
        local role = this.GetUnit("role", arg_1)
        if role then
            role:UpdateWing(arg_2)
        end
    elseif event == Event.Game_Player_ChangeForce then --玩家阵营改变
        local role = this.GetUnit("role", arg_1)
        if role then
            if role.isHero then --玩家阵营改变需要改变别的玩家和怪物的血条显示
                for k, v in pairs(this.roles) do
                    if not v.isHero then
                        v:ChangeHpBg()
                    end
                end
                for k, v in pairs(this.monsters) do
                    v:ChangeHpBg()
                end
                for k, v in pairs(this.traps) do
                    v:ChangeHpBg()
                end
            else
                role:ChangeHpBg()
            end
        end
    elseif event == Event.Game_HunliPK_OtherView then
        local playerid_1 = HunliPKManager.FindRoleUnitIdByCid(arg_1.cid)
        local playerid_2 = HunliPKManager.FindRoleUnitIdByCid(arg_1.pk_cid)
        local role1 = this.GetUnit("role", playerid_1)
        local role2 = this.GetUnit("role", playerid_2)
        if role1 and role2 then
            if arg_1.win ~= 0 then
                if arg_1.win == arg_1.cid then
                    role1.actionCtrl:PlayExternAction(105)
                    role2.actionCtrl:PlayExternAction(104)
                else
                    role1.actionCtrl:PlayExternAction(104)
                    role2.actionCtrl:PlayExternAction(105)
                end
                role1:LookAtTarget()
                role2:LookAtTarget()
                role1:DestoryHunliEffct()
                role2:DestoryHunliEffct()
            else
                role1:LookAtTarget(role2)
                role2:LookAtTarget(role1)
                role1.actionCtrl:PlayExternAction(150)
                role2.actionCtrl:PlayExternAction(150)
                local effectPos = arg_1.cur_atk/(arg_1.cur_atk + arg_1.pk_cur_atk)
                role1:DoHunliEffct(30000001,effectPos,role1,role2)
                role2:DoHunliEffct(30000002,effectPos,role1,role2)
            end
           
        end
    elseif event == Event.Game_Unit_Set_Dir then --设置朝向
        local msg = arg_1
        local monster = this.GetUnit("monster", msg.entity_id)
        if monster then
            if msg.stop_move then
                -- check moveToPos instead of current pos
                monster.moveCtrl:NetMoveStop({pos = monster.pos, speed = monster:GetMoveSpeed()})
            end
            local duration = msg.duration * 0.001
            if msg.target_id > 0 then
                local target = this.GetUnit(nil, msg.target_id)
                if target then
                    monster:LookAtTarget(target)
                else
                    monster:LookAtTarget()
                end
            else
                monster:LookAtTarget()
              
                monster.rotateCtrl:StartRotate(msg.dir, nil, duration)
              
            end
                
            -- LogAction(1, monster.id, "Game_Unit_Set_Dir", monster.unitID, monster.dir, monster.rotateCtrl.targetDir)
        end
    elseif event == Event.Game_Role_Dying then --设置重伤

    elseif event == Event.Game_Monster_Start_Dig then --开始挖尸
        local monster = this.GetUnit("monster", arg_1.monster_id)
        if monster then
            monster:StartDigMonster(arg_1.index)
        end
    elseif event == Event.Game_Monster_Finish_Dig then  --结束挖尸
        local monster = this.GetUnit("monster",  arg_1.monster_id)
        if monster then
            monster:EndDigMonster()
        end
    elseif event == Event.Game_Monster_EventNotify then
        local msg = arg_1
        local monster = this.GetUnit("monster", msg.entity_id)
        if monster then
            if msg.event == 1  then
                monster:StartWarning(msg)
            elseif msg.event == 2 then
                monster:SetFighting(true)
                if monster.Head then
                    if monster.warningSfx then
                        monster.warningSfx:Hide()    
                    end     
                end    
            elseif msg.event == 3 then --怪物脱战
                -- monster:FightingShowHead(false)
                monster:SetFighting(false)
            end
            
        end
    elseif event == Event.GamePlay_TELEPORTMap then
        --刷新摄像机朝向
        MainCamera.AlignCamera(true, true)
    elseif event == Event.Game_Role_Buff_Element then
        local role = this.GetUnit("monster", arg_1) --暂时只有怪物
        if role then
            role:UpdateElementBuff(arg_2)
            role:CheckInElementVision()
        end
    elseif event == Event.Game_RefreshBasicSet then --设置更新
        local param = arg_1
        if param == SettingType.SetId25 then --显示玩家血条
            for _, v in pairs(this.roles) do
                if v.isPlayer then
                    v:RefreshSetting()
                end
            end
            if this.hero then
                this.hero:RefreshSetting()
            end
        elseif param == SettingType.SetId29 then --显示其他玩家姓名
            for _, v in pairs(this.roles) do
                if v.isPlayer then
                    v:RefreshSetting()
                end
            end
        elseif param == SettingType.SetId30 then --显示自己姓名
            if this.hero then
                this.hero:RefreshSetting()
            end
        end
    end  
end

--------------------------------------------------------------------------------
-- messages
function UnitManager.RegistMessages()
end

--------------------------------------------------------------------------------
-- action
function UnitManager.GetUnit(unittype, id)
    local idtype = type(id)
    if idtype == "number" then
        if type(unittype) == "string" then
            if this.unitFactory[unittype] then
                return this.unitFactory[unittype][3][id]
            end
        elseif type(unittype) == "table" then
            for k, v in pairs(unittype) do
                if this.unitFactory[v] and this.unitFactory[v][3][id] then
                    return this.unitFactory[v][3][id]
                end
            end
        else
            --如果不知道类型，则一次遍历role,monster和npc
            if id == -1 or (this.hero and id == this.hero.id) then
                return this.hero
            end
            if this.roles[id] then
                return this.roles[id]
            end
            if this.monsters[id] then
                return this.monsters[id]
            end
            if this.traps[id] then
                return this.traps[id]
            end
            if this.npcs[id] then
                return this.npcs[id]
            end
            if this.tempmodels[id] then
                return this.tempmodels[id]
            end
            if this.jiguans[id] then
                return this.jiguans[id]
            end
        end
    elseif idtype == "string" then
        return this.GetUnitByName(unittype, id)
    end
end

function UnitManager.GetUnitByName(unittype, name)
    if not unittype then
        --根据名字获取一个
        if string.contains(name, "Hero") or string.contains(name, "Role") then
            unittype = "role"
        elseif string.contains(name, "NPC") then
            unittype = "npc"
        elseif string.contains(name, "Monster") then
            unittype = "monster"
        elseif string.contains(name, "TempModel") then
            unittype = "tempmodel"
        else
            return
        end
    end
    --TODO
    --待优化
    for k, v in pairs(this[unittype .. "s"]) do
        if v and v:GetName() == name then
            return v
        end
    end
end

function UnitManager.UnitGetGameObject(unittype, id)
    local unit = this.GetUnit(unittype, id)
    return unit and unit.gameObject
end

function UnitManager.UnitPlayAnimation(unittype, id, name, speed, fadeLength, normalizedTime, bImmediately)
    local unit = this.GetUnit(unittype, id)
    if unit and unit.PlayAnimation then
        unit:PlayAnimation(name, speed, fadeLength, normalizedTime, bImmediately)
    end
end

function UnitManager.UnitStopPlayAnimation(unittype, id, name)
    local unit = this.GetUnit(unittype, id)
    if unit and unit.PlayAnimation then
        unit:StopAnimation(name)
    end
end

function UnitManager.UnitBlendAnimation(unittype, id, name, targetWeight, fadeLength)
    local unit = this.GetUnit(unittype, id)
    if unit and unit.PlayAnimation then
        unit:BlendAnimation(name, targetWeight, fadeLength)
    end
end

function UnitManager.UnitRewindAnimation(unittype, id, name)
    local unit = this.GetUnit(unittype, id)
    if unit and unit.PlayAnimation then
        unit:RewindAnimation(name)
    end
end

function UnitManager.UnitSampleAnimation(unittype, id, name, time)
    local unit = this.GetUnit(unittype, id)
    if unit and unit.PlayAnimation then
        unit:SampleAnimation(name, time)
    end
end

function UnitManager.UnitPlayAnimationBroken(unittype, id, name)
    local unit = this.GetUnit(unittype, id)
    if unit and unit.PlayAnimation then
        unit:PlayAnimationBroken(name)
    end
end

function UnitManager.OnChangeScene()
    --logError("UnitManager.OnChangeScene")
    this.DestroyUnits()
end

function UnitManager.OnLeaveGame()
    if UnitManager.hero then
        UnitManager.hero:SetFighting(false)
        UnitManager.heroInBattle = nil
    end
   
    this.eventContainer:UnRegistAll()
    this.DestroyUnits(true)
end


function UnitManager.GetRangeUnits(callfun, setfun)
    if not callfun then
        return nil
    end
    local list = {}
    if not setfun or setfun("roles") then
        for _, v in pairs(this.roles) do
            if callfun(v) then
                table.insert(list, v)
            end
        end
    end

    if not setfun or setfun("monsters") then
        for _, v in pairs(this.monsters) do
            if callfun(v) then
                table.insert(list, v)
            end
        end
    end

    if not setfun or setfun("collections") then
        for _, v in pairs(this.collections) do
            if callfun(v) then
                table.insert(list, v)
            end
        end
    end

    if not setfun or setfun("localcollections") then
        for _, v in pairs(this.localcollections) do
            if callfun(v) then
                table.insert(list, v)
            end
        end
    end

    if not setfun or setfun("selfCollections") then
        for _, v in pairs(this.selfCollections) do
            if callfun(v) then
                table.insert(list, v)
            end
        end
    end

    if not setfun or setfun("jiguans") then
        for _, v in pairs(this.jiguans) do
            if callfun(v) then
                table.insert(list, v)
            end
        end
    end

    if not setfun or setfun("animals") then
        for _, v in pairs(this.animals) do
            if callfun(v) then
                table.insert(list, v)
            end
        end
    end
    return list
end

------------------------------------------------------------
--eventhandle
function UnitManager.RoleMoveFrom(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        role.moveCtrl:NetMoveFrom(msg)
    end
end

function UnitManager.RoleMoveTo(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        role.moveCtrl:NetMoveTo(msg)
    else
        --进这里说明数据存在，但对象还没创建，那么缓存下来坐标
        local data = LocalData.GetPlayerData(msg.entity_id)
        if data and data.unit_info then
            data.unit_info.entity_info.pos = msg.end_pos
        end
    end
end

function UnitManager.RoleMovePath(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        role.moveCtrl:NetMovePath(msg)
    else
        --进这里说明数据存在，但对象还没创建，那么缓存下来坐标
        local data = LocalData.GetPlayerData(msg.entity_id)
        if data and data.unit_info then
            data.unit_info.entity_info.pos = msg.poses[#msg.poses]
        end
    end
end

function UnitManager.RoleTranTo(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        local listCfg = ConfigManager.GetConfig(ConfigName.P2pTree_List, msg.way_id)
        if not listCfg then return end
        --移动信息已过期，不用管，正常显示
        if msg.end_time <= Time.GetServerTime() then return end

        local posList = {}
        for i = 1,#listCfg.list do
            local p2pCfg = ConfigManager.GetConfig(ConfigName.P2pTree, listCfg.list[i])
            table.insert(posList,Vector3(p2pCfg.param[1], p2pCfg.param[2], p2pCfg.param[3]))
        end

        if msg.reverse then
            array.reverse(posList)
        end

        local reach_time = msg.end_time
        local tar_idx = 1
        for i = #posList,2,-1 do
            local dist = Vector3.Distance(posList[i], posList[i - 1])
            reach_time = reach_time - dist / 1.0 * 1000         --抵达上一个点的时间
            if reach_time < Time.GetServerTime() then
                tar_idx = i
                break
            end
        end
        Timer.Start(Vector3.Distance(role.pos, posList[tar_idx]) / 5.0, function()
            UnitManager.TranNext(role, posList, tar_idx + 1)
        end)
        role.moveCtrl:NetMoveTo({action = 1026, start_pos = role.pos, end_pos = posList[tar_idx],
        speed = 5.0, force = true
        })
    end
end

function UnitManager.TranNext(role, posList, idx)
    if #posList >= idx then
        Timer.Start(Vector3.Distance(role.pos, posList[idx]) / 5.0, function()
            UnitManager.TranNext(role, posList, idx + 1)
        end)
        role.moveCtrl:NetMoveTo({action = 1026, start_pos = role.pos, end_pos = posList[idx],
        speed = 5.0, force = true
        })
    end
end

function UnitManager.RoleMoveStop(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        role.moveCtrl:NetMoveStop(msg)
    else
        --进这里说明数据存在，但对象还没创建，那么缓存下来坐标
        local data = LocalData.GetPlayerData(msg.entity_id)
        if data and data.unit_info then
            data.unit_info.entity_info.pos = msg.pos
        end
    end
end

function UnitManager.RoleJumpStart(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        role.moveCtrl:NetJumpStart(msg)
    else
        --进这里说明数据存在，但对象还没创建，那么缓存下来坐标
        local data = LocalData.GetPlayerData(msg.entity_id)
        if data then
            data.unit_info.entity_info.pos = msg.start_pos
        end
    end
end

function UnitManager.RoleJumpEnd(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        role.moveCtrl:NetJumpEnd(msg)
    else
        --进这里说明数据存在，但对象还没创建，那么缓存下来坐标
        local data = LocalData.GetPlayerData(msg.entity_id)
        if data then
            data.unit_info.entity_info.pos = msg.end_pos
        end
    end
end

function UnitManager.RoleFallGround(msgid, msg)
    local role = this.GetUnit(nil, -1)
    if role then
        --role.moveCtrl:NetFallGround(msg)
        role.moveCtrl:FallGround()
    end
end

-- function UnitManager.RoleMoveMode(msgid, msg)
--     local role = this.GetUnit(nil, msg.unit_id)
--     if role then
--         role:ChangeMoveMode(msg.mode, false, msg.pos)
--     end
-- end

function UnitManager.RoleOpenWings(msgid, msg)
    local role = this.GetUnitByServerHandle2(msg.entity_type, msg.entity_id)
    if role then
        role:OpenWings(msg.open)
    end
end

function UnitManager.RolePullBack(msgid, msg)
    local role = this.GetUnit(nil, msg.entity_id)
    if role then
        if role.mainActionMgr then
            role.mainActionMgr:NetPullBack(msg)
        else
            role.moveCtrl:NetPullBack(msg)
        end
    else
        --进这里说明数据存在，但对象还没创建，那么缓存下来坐标
        local data = LocalData.GetPlayerData(msg.entity_id)
        if data then
            data.unit_info.entity_info.pos = msg.pos
        end
    end
end

--Npc LookAt目标绑定
function UnitManager.NpcLookAtTargetBind(msgid, msg)
    for _, v in pairs(this.npcs) do
        if v and v.LookAtCom then
            v:NPCIKLookAtSetTarget()
        end
    end
end

---@ 玩家动作打断
function UnitManager.BreakInAnimation()
    for i, v in pairs(this.selfCollections) do
        if v and v.isExecute then
            v:BreakInCallBack()
        end
    end

    for _, v in pairs(this.animation_interactions) do
        if v and v.isExecute then
            v:BreakInCallBack()
        end
    end

end

--同步摄像机参数为虚拟相机
function UnitManager.SyncMCPositionByVC()
    MainCamera.SyncMCPositionByVC()
end
----------------------------------------------------------------
--phycollider
function UnitManager.SetPhyColliderGameObject(id, unit)
    this.phyColliderList[id] = unit
end

function UnitManager.GetColliderUnit(id)
    return this.phyColliderList[id]
end

--------------------------------------------------------------------
--decoration
function UnitManager.AddDecoration(id, deco)
    if this.decorations then
        this.decorations[id] = deco
    end
end

function UnitManager.RemoveDecoration(id)
    if this.decorations then
        this.TryRemoveUnit(this.decorations, id)
    end
end
function UnitManager.DestroyDecoration(id)
    if this.decorations and this.decorations[id] then
        this.decorations[id]:Destroy();
    end
end
function UnitManager.GetDecoRotation(id)
    if this.decorations and this.decorations[id] then
        return this.decorations[id].model.transform:GetEulerAngles()
    end
    return 0, 0, 0
end

function UnitManager.CanLoadModel(type)
    --test 检测每个数量不能大于10
    if type == UNIT_LOCAL_TYPE.PLAYER then
        return table.count(this.roles) < 10
    elseif type == UNIT_LOCAL_TYPE.MONSTER then
        --怪必须都显示
        return true
 
    end
    return true
end

function UnitManager.IsHeroLoaded()
    if this.hero and this.hero.state.playAble then
        return true
    end
end

--region selfCollection

function UnitManager.CreateSelfCollection(data)
    assert(this.selfCollections[data.id] == nil, "CreateSelfCollection id=" .. data.id)
    local t = UnitSelfCollection(data)

    this.selfCollections[data.id] = t
    return t

end

function UnitManager.DestroySelfCollection(id)
    local t = this.selfCollections[id]
    if t then
        this.TryRemoveUnit(this.selfCollections, id)
        t:Destroy()
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetSelfCollection(id)
    local r = this.selfCollections[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllSelfCollection()
    for i, v in pairs(this.selfCollections) do
        v:Destroy()
        this.selfCollections[i] = nil
    end
end

--endregion

--region  effect

function UnitManager.CreateEffect(data)
    assert(this.effects[data.id] == nil, "CreateEffect id = " .. data.id)
    local t = UnitEffect(data)
    this.effects[data.id] = t
    return t
end

function UnitManager.DestroyEffect(id)
    local t = this.effects[id]
    if t then
        this.TryRemoveUnit(this.effects, id)
        t:Destroy()
    else
        UnitManager.RemoveDelayUnit(id)
    end
end


--endregion

--region architecture

function UnitManager.CreateArchitecture(data)
    assert(this.architectures[data.id] == nil , "CreateArchitecture id="..data.id)
    local t = UnitArchitecture(data)

    this.architectures[data.id] = t
    return t
end

function UnitManager.DestroyArchitecture(id)
    local t = this.architectures[id]
    if t then
        this.TryRemoveUnit(this.architectures, id)
        t:Destroy()
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetArchitecture(id)
    local r = this.architectures[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllArchitecture()
    for i, v in pairs(this.architectures) do
        v:Destroy()
        this.architectures[i] = nil
    end
end

---@ 等待复活协议
function UnitManager.AwaitResurgence()
    if Scene.sceneID ~= 1000 then
        return
    end
    this.isAwaitResurgence = true
end


--endregion

--region jiguan

function UnitManager.CreateJiGuan(data)
    assert(this.jiguans[data.id] == nil , "CreateJiGuan id="..data.id)
    local cls = UnitJiGuan
    local baseCfg = ConfigManager.GetConfig(ConfigName.JiGuan, data.base_id)
    if baseCfg.subclass >= 1 and baseCfg.subclass <= 6 then
        --连线石板
        cls = UnitJiGuan_SlabStone
    elseif baseCfg.subclass >= 7 and baseCfg.subclass <= 10 then
        cls = UnitJiGuan_Mirror
    elseif baseCfg.subclass == 11 then
        cls = UnitJiGuan_Tortoise
    elseif baseCfg.subclass >= 12 and baseCfg.subclass <= 13 then
        cls = UnitJiGuan_FanRing
    end
    local t = cls(data)

    this.jiguans[data.id] = t
    return t
end

function UnitManager.DestroyJiGuan(id)
    local t = this.jiguans[id]
    if t then
        this.TryRemoveUnit(this.jiguans, id)
        if t:NeedCacheRemove() then
            this.AddCacheRemove(t)
            t:SetFrameEvent(AniamtionFrameEvent.Msg_Trap_Die)
        else
            t:Destroy()
        end
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

--通过唯一key获取机关，私有机关为-instId,公有机关用的是服务端给的entity_id
function UnitManager.GetJiGuan(id)
    local r = this.jiguans[id]
    if r ~= nil then
        return r
    end
    return
end

--通过配置里的机关实例id获取唯一机关，此方法无法获取批量刷新复用机关实例id的公有机关
function UnitManager.GetUniqueJiGuan(instId)
    if not LocalData.jiguanIdMap[instId] then
        return
    end
    local r = this.jiguans[LocalData.jiguanIdMap[instId]]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllJiGuan()
    for i, v in pairs(this.jiguans) do
        v:Destroy()
        this.jiguans[i] = nil
    end
end

--endregion

--region elf 跟随人物的赞助精灵
function UnitManager.CreateSpirit(data)
    assert(this.spirits[data.id] == nil , "CreateSpirit id="..data.id)
    local t = UnitSpirit(data)

    this.spirits[data.id] = t
    return t
end

function UnitManager.DestroySpirit(id)
    local t = this.spirits[id]
    if t then
        this.TryRemoveUnit(this.spirits, id)
        if t:NeedCacheRemove() then
            this.AddCacheRemove(t)
        else
            t:Destroy()
        end
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetSpirit(id)
    local r = this.spirits[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllSpirit()
    for i, v in pairs(this.spirits) do
        v:Destroy()
        this.spirits[i] = nil
    end
end
--endregion

local curCloneID = 0
--region elf 技能克隆体
function UnitManager.CreateClone(data)
    curCloneID = curCloneID + 1
    data.id = CLONE_Start + curCloneID
    assert(this.clones[data.id] == nil , "CreateClone id="..data.id)
    local t = UnitClone(data)

    this.clones[data.id] = t
    return t
end

function UnitManager.DestroyClone(id)
    local t = this.clones[id]
    if t then
        this.TryRemoveUnit(this.clones, id)
        if t:NeedCacheRemove() then
            this.AddCacheRemove(t)
        else
            t:Destroy()
        end
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetClone(id)
    local r = this.clones[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllClone()
    for i, v in pairs(this.clones) do
        v:Destroy()
        this.clones[i] = nil
    end
end
--endregion

--region animal

function UnitManager.CreateAnimal(data)
    assert(this.animals[data.id] == nil , "CreateAnimal id="..data.id)
    local t = UnitAnimal(data)

    this.animals[data.id] = t
    return t
end

function UnitManager.DestroyAnimal(id)
    local t = this.animals[id]
    if t then
        this.TryRemoveUnit(this.animals, id)
        if t:NeedCacheRemove() then
            this.AddCacheRemove(t)
        else
            t:Destroy()
        end
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetAnimal(id)
    local r = this.animals[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllAnimal()
    for i, v in pairs(this.animals) do
        v:Destroy()
        this.animals[i] = nil
    end
end

--endregion

--region missile

function UnitManager.CreateMissile(data)
    --生成本地唯一id
    if not data.id then
        data.id = MISSILE_Start + StaticTool.GetNewID()
    end
    assert(this.missiles[data.id] == nil , "CreateMissile id="..data.id)
    local t = UnitMissile(data)

    this.missiles[data.id] = t
    return t
end

function UnitManager.DestroyMissile(id)
    local t = this.missiles[id]
    if t then
        this.TryRemoveUnit(this.missiles, id)
        t:Destroy()
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetMissile(id)
    local r = this.missiles[id]
    if r ~= nil then
        return r
    end
    return
end

function UnitManager.ClearAllMissile()
    for i, v in pairs(this.missiles) do
        v:Destroy()
        this.missiles[i] = nil
    end
end

local index = 0
function UnitManager.GetUnitIndex()
    index = index + 1
    return index
end
--endregion


--region -- animation_interaction --

function UnitManager.CreateInteraction(data)
    -- 防止为空的报错提示
    assert(this.animation_interactions[data.id] == nil , "CreateInteraction id="..data.id)
    local t = UnitAnimationInteraction(data)

    this.animation_interactions[data.id] = t
    return
end

function UnitManager.DestroyInteraction(id)
    local t = this.animation_interactions[id]
    if t then
        this.TryRemoveUnit(this.animation_interactions , id)
        t:Destroy()
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetInteraction(id)
    return this.animation_interactions[id] and this.animation_interactions[id] or nil
end

function UnitManager.ClearAllInteraction()
    for _, v in pairs(this.animation_interactions) do
        v:Destroy()
    end
    this.animation_interactions = {}
end

--endregion

--region

function UnitManager.CreateChron(data)
    assert(this.chrons[data.id] == nil, "CreateChron id=" .. data.id)
    local t = UnitChron(data)
    this.chrons[data.id] = t
    return this.chrons[data.id]
end

function UnitManager.DestroyChron(id)
    local t = this.chrons[id]
    if t then
        this.TryRemoveUnit(this.chrons,id)
        t:Destroy()
    else
        UnitManager.RemoveDelayUnit(id)
    end
end

function UnitManager.GetChron(id)
    return this.chrons[id] and this.chrons[id] or nil
end

--endregion


--隐藏所有Unit
function UnitManager.HideAllUnit(mask)
    this.hideMask = mask or UNIT_LOCAL_MASK.NONE
    --依次遍历
    local bShow = this.hideMask & UNIT_LOCAL_MASK.MONSTER == 0
    for k, v in pairs(this.monsters) do
        v:SetTypeVisible(bShow)
    end
    bShow = this.hideMask & UNIT_LOCAL_MASK.TRAP == 0
    for k, v in pairs(this.traps) do
        v:SetTypeVisible(bShow)
    end

    bShow = this.hideMask & UNIT_LOCAL_MASK.NPC == 0
    for k, v in pairs(this.npcs) do
        v:SetTypeVisible(bShow)
    end

    bShow = this.hideMask & UNIT_LOCAL_MASK.PLAYER == 0
    for k, v in pairs(this.roles) do
        if not v.isHero then
            v:SetTypeVisible(bShow)
        else
            v:SetTypeVisible(this.hideMask & UNIT_LOCAL_MASK.HERO == 0)
        end
    end
    bShow = this.hideMask & UNIT_LOCAL_MASK.JIGUAN == 0
    for k, v in pairs(this.jiguans) do
        v:SetTypeVisible(bShow)
    end
    bShow = this.hideMask & UNIT_LOCAL_MASK.ACHITECTURE == 0
    for k, v in pairs(this.architectures) do
        v:SetTypeVisible(bShow)
    end
    bShow = this.hideMask & UNIT_LOCAL_MASK.ARTICLE == 0
    for k, v in pairs(this.articles) do
        v:SetTypeVisible(bShow)
    end

    bShow = this.hideMask & UNIT_LOCAL_MASK.SPIRITS == 0
    for k, v in pairs(this.spirits) do
        v:SetTypeVisible(bShow)
    end
    bShow = this.hideMask & UNIT_LOCAL_MASK.MINORNPC == 0
    for k, v in pairs(this.minor_npcs) do
        v:SetTypeVisible(bShow)
    end
    for k, v in pairs(this.cacheRemoveUnit) do
        k:Hide()
    end
end

function UnitManager.GetUnit2UnitType(type , id)
    local listName = MapUnitType.List[type]
    if not this[listName] then
        return
    end

    for _, v in pairs(this[listName]) do

        if v:GetRealID() == id then
            return v
        end

    end

end


--[[
    @desc: 一个查询指定类型对象的接口
    author:{author}
    time:2023-02-08 11:20:10
    --@types: 需要查询的unit类型，如果是表，则遍历多个集合
	--@checkFun: 条件检测函数，返回真表示当前搜索结束
    @return:
]]
function UnitManager.GetUnitByCondition(types, checkFun)
    if type(types) == "table" then
        for k, v in pairs(types) do
            for k2, v2 in pairs(this[v]) do
                if checkFun(v2) then
                    return v2
                end
            end
        end
    elseif type(types) == "string" then
        for k2, v2 in pairs(this[types]) do
            if checkFun(v2) then
                return v2
            end
        end
    end
end

function UnitManager.Reset()
    this.createNpcCallBackList = {}
end

--控制降低所有布料模拟频率（性能）
function UnitManager.MagicaClothSetting_PerformancePriority()
   local magicaSetting=  this.root.gameObject:AddMissingComponent(typeof(CS.MagicaCloth2.MagicaSettings))
   magicaSetting:PerformancePriority()
end
--控制所有布料模拟频率
function UnitManager.MagicaClothSetting(simulationFre, Frame)
    local magicaSetting=  this.root.gameObject:AddMissingComponent(typeof(CS.MagicaCloth2.MagicaSettings))
    magicaSetting:Setting(simulationFre,Frame)
 end
UnitManager.Init()

return UnitManager