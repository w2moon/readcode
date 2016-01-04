local assets =
{
    Asset("ANIM", "anim/bone_shards.zip")
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bone_shards")
    inst.AnimState:SetBuild("bone_shards")
    inst.AnimState:PlayAnimation("idle", false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"

    inst:AddComponent("stackable")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("boneshard", fn, assets)