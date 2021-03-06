local prefabs =
{
    "babybeefalo",
}

local function InMood(inst)
    if inst.components.periodicspawner ~= nil then
        inst.components.periodicspawner:Start()
    end
    if inst.components.herd ~= nil then
        for k, v in pairs(inst.components.herd.members) do
            k:PushEvent("entermood")
        end
    end
end

local function LeaveMood(inst)
    if inst.components.periodicspawner ~= nil then
        inst.components.periodicspawner:Stop()
    end
    if inst.components.herd ~= nil then
        for k, v in pairs(inst.components.herd.members) do
            k:PushEvent("leavemood")
        end
    end
    inst.components.mood:CheckForMoodChange()
end

local function AddMember(inst, member)
    if inst.components.mood ~= nil then
        member:PushEvent(inst.components.mood:IsInMood() and "entermood" or "leavemood")
        end
end

local function CanSpawn(inst)
    -- Note that there are other conditions inside periodic spawner governing this as well.

    if inst.components.herd == nil or inst.components.herd:IsFull() then
        return false
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    return #TheSim:FindEntities(x, y, z, inst.components.herd.gatherrange, { "herdmember", inst.components.herd.membertag }) < TUNING.BEEFALOHERD_MAX_IN_RANGE
end

local function OnSpawned(inst, newent)
    if inst.components.herd ~= nil then
        inst.components.herd:AddMember(newent)
    end
end

--local function OnFull(inst)
    --TODO: mark some beefalo for death
--end

local function OnInit(inst)
    inst.components.mood:ValidateMood()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("herd")
    --V2C: Don't use CLASSIFIED because herds use FindEntities on "herd" tag
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    inst:AddComponent("herd")
    inst.components.herd:SetMemberTag("beefalo")
    inst.components.herd:SetGatherRange(TUNING.BEEFALOHERD_RANGE)
    inst.components.herd:SetUpdateRange(20)
    inst.components.herd:SetOnEmptyFn(inst.Remove)
    --inst.components.herd:SetOnFullFn(OnFull)
    inst.components.herd:SetAddMemberFn(AddMember)

    inst:AddComponent("mood")
    inst.components.mood:SetMoodTimeInDays(TUNING.BEEFALO_MATING_SEASON_LENGTH, TUNING.BEEFALO_MATING_SEASON_WAIT)
    inst.components.mood:SetMoodSeason(SEASONS.SPRING)
    inst.components.mood:SetInMoodFn(InMood)
    inst.components.mood:SetLeaveMoodFn(LeaveMood)
    inst.components.mood:CheckForMoodChange()
    inst:DoTaskInTime(0, OnInit)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetRandomTimes(TUNING.BEEFALO_MATING_SEASON_BABYDELAY, TUNING.BEEFALO_MATING_SEASON_BABYDELAY_VARIANCE)
    inst.components.periodicspawner:SetPrefab("babybeefalo")
    inst.components.periodicspawner:SetOnSpawnFn(OnSpawned)
    inst.components.periodicspawner:SetSpawnTestFn(CanSpawn)
    inst.components.periodicspawner:SetDensityInRange(20, 6)
    inst.components.periodicspawner:SetOnlySpawnOffscreen(true)

    return inst
end

return Prefab("beefaloherd", fn, nil, prefabs)
