local brain = require "brains/deerclopsbrain"

local assets =
{
    Asset("ANIM", "anim/deerclops_basic.zip"),
    Asset("ANIM", "anim/deerclops_actions.zip"),
    Asset("ANIM", "anim/deerclops_build.zip"),
    Asset("ANIM", "anim/deerclops_neutral_build.zip"),
    Asset("SOUND", "sound/deerclops.fsb"),
}

local prefabs =
{
    "meat",
    "deerclops_eyeball",
    "icespike_fx_1",
    "icespike_fx_2",
    "icespike_fx_3",
    "icespike_fx_4",
}

local TARGET_DIST = 16
local STRUCTURES_PER_HARASS = 5

local function IsSated(inst)
    return inst.structuresDestroyed >= STRUCTURES_PER_HARASS
end

local function WantsToLeave(inst)
    return not inst.components.combat:HasTarget()
    and inst:IsSated()
    and inst:GetTimeAlive() >= 120
end

local function CalcSanityAura(inst)
    return inst.components.combat.target ~= nil and -TUNING.SANITYAURA_HUGE or -TUNING.SANITYAURA_LARGE
end

local function FindBaseToAttack(inst, target)
    --print("Deerclops finding base to attack")
    local structure = GetClosestInstWithTag("structure", target, 40)
    if structure then
        local targetPos = Vector3(structure.Transform:GetWorldPosition() )
        inst.components.knownlocations:RememberLocation("targetbase", targetPos)
        inst.AnimState:ClearOverrideSymbol("deerclops_head")
    end
end

local function RetargetFn(inst)
    --print("Deerclops retarget", debugstack())
    return FindEntity(inst, TARGET_DIST, function(guy)
        return inst.components.combat:CanTarget(guy)
               and (guy.components.combat.target == inst or (inst:GetPosition():Dist(guy:GetPosition()) <= (inst.Physics:GetRadius() + 8)))
    end, nil, {"prey", "smallcreature"})
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end

local function AfterWorking(inst, data)
    if data.target then
        local recipe = AllRecipes[data.target.prefab]
        if recipe then
            inst.structuresDestroyed = inst.structuresDestroyed + 1
            if inst:IsSated() then
                inst.components.knownlocations:ForgetLocation("targetbase")
                inst.AnimState:OverrideSymbol("deerclops_head", "deerclops_neutral_build", "deerclops_head")
            end
        end
    end
end

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

local function OnEntitySleep(inst)
    if inst:WantsToLeave() then
        inst.structuresDestroyed = 0 -- reset this for the stored version
        TheWorld:PushEvent("storehassler", inst)
        inst:Remove()
    end
end

local function OnStopWinter(inst)
    if inst:IsAsleep() then
        TheWorld:PushEvent("storehassler", inst)
        inst:Remove()
    end
end

local function OnSave(inst, data)
    data.structuresDestroyed = inst.structuresDestroyed
end
        
local function OnLoad(inst, data)
    if data then
        inst.structuresDestroyed = data.structuresDestroyed or inst.structuresDestroyed
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    if data.attacker:HasTag("player") and inst.structuresDestroyed < STRUCTURES_PER_HARASS and inst.components.knownlocations:GetLocation("targetbase") == nil then
        FindBaseToAttack(inst, data.attacker)
    end
end

local function OnHitOther(inst, data)
    local other = data.target
    if other and other.components.freezable then
        other.components.freezable:AddColdness(2)
        other.components.freezable:SpawnShatterFX()
    end
end

local function OnRemove(inst)
    TheWorld:PushEvent("hasslerremoved", inst)
end

local function OnDead(inst)
    TheWorld:PushEvent("hasslerkilled", inst)
end

local function oncollapse(inst, other)
    if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
    end
end

local function oncollide(inst, other)
    if other ~= nil and
        (other:HasTag("tree") or other:HasTag("boulder")) and --HasTag implies IsValid
        Vector3(inst.Physics:GetVelocity()):LengthSq() >= 1 then
        inst:DoTaskInTime(2 * FRAMES, oncollapse, other)
    end
end

local function OnNewTarget(inst, data)
    FindBaseToAttack(inst, data.target or inst)
    if inst.components.knownlocations:GetLocation("targetbase") and data.target:HasTag("player") then
        inst.structuresDestroyed = inst.structuresDestroyed - 1
        inst.components.knownlocations:ForgetLocation("home")
    end
end

local loot = {"meat", "meat", "meat", "meat", "meat", "meat", "meat", "meat", "deerclops_eyeball"}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeGiantCharacterPhysics(inst, 1000, .5)

    local s  = 1.65
    inst.Transform:SetScale(s, s, s)
    inst.DynamicShadow:SetSize(6, 3.5)
    inst.Transform:SetFourFaced()

    inst:AddTag("epic")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("deerclops")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")

    inst.AnimState:SetBank("deerclops")
    inst.AnimState:SetBuild("deerclops_build")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(oncollide)

    inst.structuresDestroyed = 0

    ------------------------------------------

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 3  

    ------------------------------------------
    inst:SetStateGraph("SGdeerclops")

    ------------------------------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    MakeLargeBurnableCharacter(inst, "deerclops_body")
    MakeHugeFreezableCharacter(inst, "deerclops_body")

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DEERCLOPS_HEALTH)

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.DEERCLOPS_DAMAGE)
    inst.components.combat.playerdamagepercent = TUNING.DEERCLOPS_DAMAGE_PLAYER_PERCENT
    inst.components.combat:SetRange(TUNING.DEERCLOPS_ATTACK_RANGE)
    inst.components.combat:SetAreaDamage(TUNING.DEERCLOPS_AOE_RANGE, TUNING.DEERCLOPS_AOE_SCALE)
    inst.components.combat.hiteffectsymbol = "deerclops_body"
    inst.components.combat:SetAttackPeriod(TUNING.DEERCLOPS_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    ------------------------------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()
    ------------------------------------------
    inst:AddComponent("knownlocations")
    inst:SetBrain(brain)

    inst:ListenForEvent("working", AfterWorking)
    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onhitother", OnHitOther)
    inst:ListenForEvent("death", OnDead)
    inst:ListenForEvent("onremove", OnRemove)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst:WatchWorldState("stopwinter", OnStopWinter)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.IsSated = IsSated
    inst.WantsToLeave = WantsToLeave

    return inst
end

return Prefab("deerclops", fn, assets, prefabs)
