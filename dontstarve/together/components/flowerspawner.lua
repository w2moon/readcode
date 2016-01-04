--------------------------------------------------------------------------
--[[ FlowerSpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "FlowerSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local _activeplayers = {}
local _scheduledtasks = {}
local _worldstate = TheWorld.state
local _updating = false
local _prefab = "flower"
local _minDist = 35
local _maxDist = 50
local _spawnInterval = TUNING.FLOWER_SPAWN_TIME
local _spawnIntervalVariation = TUNING.FLOWER_SPAWN_TIME_VARIATION
local _flowers = {}

local _validTileTypes = {GROUND.SAVANNA,GROUND.GRASS,GROUND.FOREST,GROUND.DECIDUOUS}

local function CheckTileCompatibility(tile)
	for k,v in pairs(_validTileTypes) do
		if v == tile then
			return true
		end
	end
end

local function GetSpawnPoint(player)
	local pt = Vector3(player.Transform:GetWorldPosition())
    local theta = math.random() * 2 * PI
    local radius = math.random(_minDist, _maxDist)
    local steps = 40
    local ground = TheWorld
    local validpos = {}
    for i = 1, steps do
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
        local try_pos = pt + offset
        local tile = ground.Map:GetTileAtPoint(try_pos.x, try_pos.y, try_pos.z)
        if not (ground.Map and tile == GROUND.IMPASSABLE or tile > GROUND.UNDERGROUND ) and
        CheckTileCompatibility(tile) and 
		#TheSim:FindEntities(try_pos.x, try_pos.y, try_pos.z, 1) <= 0 then
			table.insert(validpos, try_pos)
        end
        theta = theta - (2 * PI / steps)
    end
    if #validpos > 0 then
    	local num = math.random(#validpos)
    	return validpos[num]
    else
    	return nil
    end
end

local function SpawnFlowerForPlayer(player, reschedule)
    local pt = player:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 64, { "flower" })
    if #TheSim:FindEntities(pt.x, pt.y, pt.z , 50, {"flower"}) < TUNING.MAX_FLOWERS_PER_AREA then
    	local pt = GetSpawnPoint(player)

    	if pt then
    		local flower = SpawnPrefab(_prefab)
			flower.Transform:SetPosition(pt:Get())
    	end
    end
    _scheduledtasks[player] = nil
    reschedule(player)
end

local function ScheduleSpawn(player, initialspawn)
    if _scheduledtasks[player] == nil then
        local time = _spawnInterval + math.random() * _spawnIntervalVariation
        _scheduledtasks[player] = player:DoTaskInTime(time, SpawnFlowerForPlayer, ScheduleSpawn)
    end
end

local function CancelSpawn(player)
    if _scheduledtasks[player] ~= nil then
        _scheduledtasks[player]:Cancel()
        _scheduledtasks[player] = nil
    end
end

local function ToggleUpdate(force)
    if _spawnInterval > 0 and _worldstate.israining then
        if not _updating then
            _updating = true
            for i, v in ipairs(_activeplayers) do
                ScheduleSpawn(v, true)
            end
        elseif force then
            for i, v in ipairs(_activeplayers) do
                CancelSpawn(v)
                ScheduleSpawn(v, true)
            end
        end
    elseif _updating then
        _updating = false
        for i, v in ipairs(_activeplayers) do
            CancelSpawn(v)
        end
    end
end


--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------


local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
    if _updating then
        ScheduleSpawn(player, true)
    end
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            CancelSpawn(player)
            table.remove(_activeplayers, i)
            return
        end
    end
end


--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

self.inst:WatchWorldState("israining", ToggleUpdate)
self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

ToggleUpdate(true)


--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------


function self:GetDebugString()
	return "FlowerSpawner: "
end

function self:OnSave()
    local data = {}
        data.timetospawn = _spawnInterval
        data.timetospawn_variation = _spawnIntervalVariation
        data.updating = _updating
    return data
end

function self:OnLoad(data)
    if data then
        _spawnInterval = data.timetospawn or TUNING.FLOWER_SPAWN_TIME
        _spawnIntervalVariation = data.timetospawn_variation or TUNING.FLOWER_SPAWN_TIME_VARIATION
        _updating = data.updating or false
    end

    -- Must do this because FlowerSpawner:OnLoad gets called before WorldState:OnLoad, 
    -- and WorldState:OnLoad doesn't trigger the state watchers.
    self.inst:DoTaskInTime(0, ToggleUpdate, true)
end

function self:SpawnModeNever()
    _spawnInterval = -1
    _spawnIntervalVariation = -1
    ToggleUpdate()
end

function self:SpawnModeHeavy()
    _spawnIntervalVariation = 5
    _spawnInterval = 10
    ToggleUpdate(true)
end

function self:SpawnModeMed()
    _spawnIntervalVariation = 10
    _spawnInterval = 20
    ToggleUpdate(true)
end

function self:SpawnModeLight()
    _spawnIntervalVariation = 15
    _spawnInterval = 60
    ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)