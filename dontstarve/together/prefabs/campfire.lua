require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/campfire.zip"),
}

local prefabs =
{
    "campfirefire",
}

local function onextinguish(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local status_table =
{
    "EMBERS",
    "LOW",
    "NORMAL",
    "HIGH"
}
local function getstatus(inst)
    local sec = inst.components.fueled:GetCurrentSection()
    return (sec == 0 and "OUT")
        or (sec <= #status_table and status_table[sec])
        or nil
end

local function OnHaunt(inst)
    if inst.components.fueled ~= nil and
        inst.components.fueled.accepting and
        math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        inst.components.fueled:DoDelta(TUNING.TINY_FUEL)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("campfire")
    inst.AnimState:SetBuild("campfire")
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("campfire")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    inst:AddComponent("propagator")
    -----------------------

    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("campfirefire", Vector3())
    inst:ListenForEvent("onextinguish", onextinguish)

    -------------------------
    inst:AddComponent("cooker")
    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = TUNING.CAMPFIRE_FUEL_MAX
    inst.components.fueled.accepting = true

    inst.components.fueled:SetSections(4)

    inst.components.fueled.ontakefuelfn = function() inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") end
    inst.components.fueled:SetUpdateFn(function()
        if inst.components.burnable and inst.components.fueled then
            if TheWorld.state.israining then
                inst.components.fueled.rate = 1 + TUNING.CAMPFIRE_RAIN_RATE * TheWorld.state.precipitationrate
            else
                inst.components.fueled.rate = 1
            end

            inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
        end
    end)

    inst.components.fueled:SetSectionCallback(
        function(section)
            if section == 0 then
                inst.components.burnable:Extinguish()
                inst.AnimState:PlayAnimation("dead")
                RemovePhysicsColliders(inst)

                local ash = SpawnPrefab("ash")
                ash.Transform:SetPosition(inst.Transform:GetWorldPosition())

                inst.components.fueled.accepting = false
                inst:RemoveComponent("cooker")
                inst:RemoveComponent("propagator")
                inst.persists = false
                inst:DoTaskInTime(1, ErodeAway)
            else
                inst.AnimState:PlayAnimation("idle")
                inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent())
                inst.components.fueled.rate = 1

                local ranges = { 1, 2, 3, 4 }
                local output = { 2, 5, 5, 10 }
                inst.components.propagator.propagaterange = ranges[section]
                inst.components.propagator.heatoutput = output[section]
            end
        end)

    inst.components.fueled:InitializeFuelLevel(TUNING.CAMPFIRE_FUEL_START)

    -----------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    --------------------

    inst.components.burnable:Ignite()
    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    return inst
end

return Prefab("campfire", fn, assets, prefabs),
    MakePlacer("campfire_placer", "campfire", "campfire", "preview")
