local assets =
{
    Asset("ANIM", "anim/compass.zip"),
    Asset("ANIM", "anim/swap_compass.zip"),
}

--[[
local dirs =
{
    N=0, S=180,
    NE=45, E=90, SE=135,
    NW=-45, W=-90, SW=-135, 
}

local haunted_dirs =
{
    N=180, S=0,
    NE=-135, E=-90, SE=-45,
    NW=135, W=90, SW=45, 
}

local function GetStatus(inst, viewer)
    local heading = TheCamera:GetHeading()--inst.Transform:GetRotation() 
    local dir, closest_diff = nil, nil

    if inst.components.hauntable and inst.components.hauntable.haunted then
        for k,v in pairs(haunted_dirs) do
            local diff = math.abs(anglediff(heading, v))
            if not dir or diff < closest_diff then
                dir, closest_diff = k, diff
            end
        end
    else
        for k,v in pairs(dirs) do
            local diff = math.abs(anglediff(heading, v))
            if not dir or diff < closest_diff then
                dir, closest_diff = k, diff
            end
        end
    end
    return dir
end
]]

local function onequipfueldelta(inst)
    if inst.components.fueled.currentfuel < inst.components.fueled.maxfuel then
        inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel*.01)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_compass", "swap_compass")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.components.fueled:StartConsuming()

    --take a percent of fuel next frame instead of this one, so we can remove the torch properly if it runs out at that point
	inst:DoTaskInTime(0, onequipfueldelta)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst.components.fueled:StopConsuming()
end

local function ondepleted(inst)
    if inst.components.inventoryitem ~= nil
        and inst.components.inventoryitem.owner ~= nil then
        local data = {
            prefab = inst.prefab,
            equipslot = inst.components.equippable.equipslot,
            announce = "ANNOUNCE_COMPASS_OUT",
        }
        inst.components.inventoryitem.owner:PushEvent("itemranout", data)
    end
    inst:Remove()
end

local function onattack(inst, attacker, target)
    if inst.components.fueled ~= nil then
        inst.components.fueled:DoDelta(inst.components.fueled.maxfuel * TUNING.COMPASS_ATTACK_DECAY_PERCENT)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("compass")
    inst.AnimState:SetBuild("compass")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("compass")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst:AddComponent("inspectable")
    --inst.components.inspectable.noanim = true
    --inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.COMPASS_FUEL)
    inst.components.fueled:SetDepletedFn(ondepleted)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    -- TODO: Make this work on the client
    --inst.spookyoffsettarget = 0
    --inst.spookyoffsetstart = 0
    --inst.spookyoffsetfinish = 0

    MakeHauntableLaunch(inst)
    --AddHauntableCustomReaction(inst, function(inst,haunter)
        --inst.components.hauntable.hauntvalue = TUNING.HAUNT_HUGE
        --inst.spookyoffsettarget = 220
        --inst.spookyoffsetstart = GetTime()
        --inst.spookyoffsetfinish = GetTime() + 30
        --return true
    --end, false, true, true)

    return inst
end

return Prefab("compass", fn, assets)
