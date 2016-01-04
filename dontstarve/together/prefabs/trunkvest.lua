local assets =
{
    Asset("ANIM", "anim/armor_trunkvest_summer.zip"),
    Asset("ANIM", "anim/armor_trunkvest_winter.zip"),
}

local function onequip_summer(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_body", "armor_trunkvest_summer", "swap_body")
    inst.components.fueled:StartConsuming()
end

local function onequip_winter(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_trunkvest_winter", "swap_body")
    inst.components.fueled:StartConsuming()
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst.components.fueled:StopConsuming()
end

local function create_common(bankandbuild)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bankandbuild)
    inst.AnimState:SetBuild(bankandbuild)
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/trunksuit"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL

    inst.components.equippable:SetOnUnequip( onunequip )

    inst:AddComponent("insulator")

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.TRUNKVEST_PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    MakeHauntableLaunch(inst)

    return inst
end

local function create_summer()
    local inst = create_common("armor_trunkvest_summer")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable:SetOnEquip(onequip_summer)

    inst.components.insulator:SetInsulation( TUNING.INSULATION_SMALL )
    
    return inst
end

local function create_winter()
    local inst = create_common("armor_trunkvest_winter")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable:SetOnEquip(onequip_winter)

    inst.components.insulator:SetInsulation( TUNING.INSULATION_LARGE )

    return inst
end

return Prefab("trunkvest_summer", create_summer, assets),
    Prefab("trunkvest_winter", create_winter, assets)