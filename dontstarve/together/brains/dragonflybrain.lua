require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/attackwall"
require "behaviours/panic"
require "behaviours/minperiod"

local DragonflyBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function HomePoint(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function ShouldResetFight(inst)
	if inst.reset then 
		return inst.reset 
	end

	local leashLoc = inst.components.knownlocations:GetLocation("spawnpoint")
	local pos = inst:GetPosition()
	local dist = distsq(pos.x, pos.z, leashLoc.x, leashLoc.z)
	inst.reset = dist >= (TUNING.DRAGONFLY_RESET_DIST*TUNING.DRAGONFLY_RESET_DIST)

	if inst.reset then
		inst:Reset()
	end

	return inst.reset
end

local function GoHome(inst)
	return BufferedAction(inst, nil, ACTIONS.GOHOME)
end

local function ShouldSpawnFn(inst)
	return inst.components.rampingspawner:GetCurrentWave() > 0
end

local function FindSpawnTarget(inst)
	local pos = inst.components.knownlocations:GetLocation("spawnpoint")
	local lavae_ponds = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.DRAGONFLY_RESET_DIST, {"lava"})
	return GetRandomItem(lavae_ponds or {})
end

local function LavaeSpawnAction(inst)
	inst.target = FindSpawnTarget(inst)
	if not inst.target then
		inst.target = inst
	end
	return BufferedAction(inst, inst.target, ACTIONS.SPAWN)
end

function DragonflyBrain:OnStart()
	local root =
		PriorityNode(
		{
			WhileNode(function() return ShouldResetFight(self.inst) end, "Reset Fight", DoAction(self.inst, GoHome)),
			WhileNode(function() return ShouldSpawnFn(self.inst) end, "Spawn Lavae", DoAction(self.inst, LavaeSpawnAction)),
            ChaseAndAttack(self.inst),
            Leash(self.inst, function() return HomePoint(self.inst) end, 20, 10),
            Wander(self.inst, function() return HomePoint(self.inst) end, 15)
		}, 1)
	self.bt = BT(self.inst, root)
end

function DragonflyBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("spawnpoint", Point(self.inst.Transform:GetWorldPosition()))
end

return DragonflyBrain