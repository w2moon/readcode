local assets =
{
	--Asset("ANIM", "anim/fire_large_character.zip"),
	Asset("ANIM", "anim/campfire_fire.zip"),
	Asset("SOUND", "sound/common.fsb"),
}

local firelevels =
{
    {anim="level1", sound="dontstarve/common/nightlight", radius=2, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=.1},
    {anim="level2", sound="dontstarve/common/nightlight", radius=3, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=.3},
    {anim="level3", sound="dontstarve/common/nightlight", radius=4, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=.6},
    {anim="level4", sound="dontstarve/common/nightlight", radius=5, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=1},
}

local function fn()

	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetBank("campfire_fire")
    inst.AnimState:SetBuild("campfire_fire")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(0, 0, 0, .6)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst:AddComponent("firefx")
    inst.components.firefx.levels = firelevels

    inst.AnimState:SetFinalOffset(-1)
    return inst
end

return Prefab("nightlight_flame", fn, assets)