local assets =
{
    Asset("ANIM", "anim/goosemoose_build.zip"),
    Asset("ANIM", "anim/goosemoose_basic.zip"),
    Asset("ANIM", "anim/goosemoose_actions.zip"),
    --Asset("SOUND", "sound/moose.fsb"),
}

local prefabs =
{
    "mooseegg",
    "moose_nesting_ground",
    "mossling",
    "goose_feather",
    "drumstick",
}

local brain = require("brains/moosebrain")

local MOOSE_SCALE = 1.55

SetSharedLootTable( 'moose',
{
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    {'meat',             1.00},
    {'drumstick',        1.00},
    {'drumstick',        1.00},
    {'goose_feather',    1.00},
    {'goose_feather',    1.00},
    {'goose_feather',    1.00},
    {'goose_feather',    0.33},
    {'goose_feather',    0.33},
})

local BASE_TAGS = {"structure"}
local SEE_STRUCTURE_DIST = 20

local TARGET_DIST = 10
local LOSE_TARGET_DIST = 20

local function RetargetFn(inst)
    if inst.sg:HasStateTag("busy") then return end

    local target = nil

    if not target and inst.components.entitytracker:GetEntity("egg") then
        target = FindEntity(inst.components.entitytracker:GetEntity("egg"), TARGET_DIST, function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            nil,
            { "prey", "smallcreature", "mossling", "moose" })
    end

    if not target then
        target =  FindEntity(inst, TARGET_DIST, function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            nil,
            { "prey", "smallcreature", "mossling", "moose" })
    end

    return target
end

local function KeepTargetFn(inst, target)
    local landing = inst.components.knownlocations:GetLocation("landpoint") or inst:GetPosition()

    return inst.components.combat:CanTarget(target) 
    and inst:GetPosition():Dist(target:GetPosition()) <= LOSE_TARGET_DIST 
    and target:GetPosition():Dist(landing) <= LOSE_TARGET_DIST

end

local function OnEntitySleep(inst)
    if inst.shouldGoAway then
        inst:Remove()
    end
end

local function OnSpringChange(inst, isSpring)
    inst.shouldGoAway = not isSpring or TheWorld:HasTag("cave")
    if inst:IsAsleep() then
        OnEntitySleep(inst)
    end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function OnCollide(inst, other)
    --Destroy?
end

local function OnSave(inst, data)
    data.WantsToLayEgg = inst.WantsToLayEgg
    data.CanDisarm = inst.CanDisarm
    data.shouldGoAway = inst.shouldGoAway
end

local function OnLoad(inst, data)
    if data.WantsToLayEgg then
        inst.WantsToLayEgg = data.WantsToLayEgg
    end
    if data.CanDisarm then
        inst.CanDisarm = data.CanDisarm
    end
    inst.shouldGoAway = data.shouldGoAway or false
end

local function ontimerdone(inst, data)
    if data.name == "WantsToLayEgg" then
        inst.WantsToLayEgg = true
    end

    if data.name == "DisarmCooldown" then
        inst.CanDisarm = true
    end
end

local function rename(inst)
    inst.components.named:PickNewName()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    local s = MOOSE_SCALE
    inst.Transform:SetScale(s,s,s)
    inst.Transform:SetFourFaced()

    inst.DynamicShadow:SetSize(6, 2.75)

    MakeGiantCharacterPhysics(inst, 5000, 1)

    inst.Physics:SetCollisionCallback(OnCollide)

    inst.AnimState:SetBank("goosemoose")
    inst.AnimState:SetBuild("goosemoose_build")
    inst.AnimState:PlayAnimation("idle", true)

    ------------------------------------------

    inst:AddTag("moose")
    inst:AddTag("epic")
    inst:AddTag("animal")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    ------------------

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(10, 15)

    ------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.MOOSE_HEALTH)
    inst.components.health.destroytime = 3

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.MOOSE_DAMAGE)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(TUNING.MOOSE_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "goosemoose_body"
    inst.components.combat:SetAttackPeriod(TUNING.MOOSE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/moose/hurt")
    ------------------------------------------

    inst:AddComponent("sleeper")
    inst.shouldGoAway = false

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('moose')

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("named")
    inst.components.named.possiblenames = {STRINGS.NAMES["MOOSE1"], STRINGS.NAMES["MOOSE2"]}
    inst.components.named:PickNewName()
    inst:DoPeriodicTask(5, rename)

    ------------------------------------------

    inst:AddComponent("knownlocations")
    inst:AddComponent("inventory")
    inst:AddComponent("entitytracker")
    inst:AddComponent("timer")

    ------------------------------------------

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.MOOSE }, { FOODGROUP.MOOSE })
    inst.components.eater.eatwholestack = true

    ------------------------------------------

    inst:WatchWorldState("isspring", OnSpringChange)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("entitysleep", OnEntitySleep)

    ------------------------------------------

    MakeLargeBurnableCharacter(inst, "swap_fire")
    MakeHugeFreezableCharacter(inst, "goosemoose_body")

    inst:ListenForEvent("timerdone", ontimerdone)
    inst:ListenForEvent("EggHatch", ontimerdone)

    inst.WantsToLayEgg = false
    inst.CanDisarm = false

    ------------------------------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.MOOSE_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.MOOSE_RUN_SPEED

    inst:SetStateGraph("SGmoose")
    inst:SetBrain(brain)

    return inst
end

return Prefab("moose", fn, assets, prefabs)