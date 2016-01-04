
local function DoSingleShed(inst)

	local x, y, z = inst.Transform:GetWorldPosition()
	local item = nil

	if inst.components.shedder.shedItemPrefab then 
		item = SpawnPrefab(inst.components.shedder.shedItemPrefab)
	end

	if item then 
		local x_offset = math.random() + .5
		local z_offset = math.random() + .5
		item.Transform:SetPosition(x + x_offset, inst.components.shedder.shedHeight, z + z_offset)
	end

	return item
end


local Shedder = Class(function(self, inst)
    self.inst = inst
    self.shedItemPrefab = nil
    self.shedHeight = 6.5 -- this height is for Bearger
end,
nil,
{
    
})

function Shedder:StartShedding(interval)

	if not interval then 
		interval = 60
	end

	if self.shedTask then 
		self.shedTask:Cancel()
		self.shedTask = nil
	end

	self.shedTask = self.inst:DoPeriodicTask(interval, DoSingleShed)
end

function Shedder:StopShedding()
	if self.shedTask then 
		self.shedTask:Cancel()
		self.shedTask = nil
	end
end

function Shedder:DoMultiShed(max, random)

	local num = max
	if random then 
		num = math.random(1, max)
	end
	local speed = 4
	local item = nil
	for i = 1, num do 
		item = DoSingleShed(self.inst)
		if item and item.Physics then 
			-- move it
			local angle = math.random() * 360 * DEGREES 
			item.Physics:SetVel(math.cos(angle) * speed, 0, math.sin(angle) * speed)
		end
	end
end


return Shedder