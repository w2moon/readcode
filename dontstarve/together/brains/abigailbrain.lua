require "behaviours/follow"
require "behaviours/wander"


local AbigailBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
	self.mytarget = nil

    self.listenerfunc = function() self.mytarget = nil end
end)

local MIN_FOLLOW = 4
local MAX_FOLLOW = 11
local MED_FOLLOW = 6
local MAX_WANDER_DIST = 10
local MAX_CHASE_TIME = 6


local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

function AbigailBrain:SetTarget(target)
	if target ~= self.target then
		if self.mytarget then
			self.inst:RemoveEventCallback("onremove", self.listenerfunc, self.mytarget)
		end
		if target then
			self.inst:ListenForEvent("onremove", self.listenerfunc, target)
		end
	end
	self.mytarget = target
end

function AbigailBrain:OnStart()
	self:SetTarget(self.inst.spawnedforplayer)

    local root = PriorityNode(
    {
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		Follow(self.inst, function() return self.inst.components.follower.leader end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW, true),
		--FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst, function() if self.mytarget then return Point(self.mytarget.Transform:GetWorldPosition()) end end, MAX_WANDER_DIST)        
    }, .5)
        
    self.bt = BT(self.inst, root)
         
end


return AbigailBrain
