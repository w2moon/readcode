local easing = require("easing")

local Highlight = Class(function(self, inst)
    self.inst = inst
    --[[
    self.highlit = nil
	self.base_add_colour_red = 0
    self.base_add_colour_green = 0
    self.base_add_colour_blue = 0
	self.highlight_add_colour_red = 0
    self.highlight_add_colour_green = 0
    self.highlight_add_colour_blue = 0
    --]]
end)

function Highlight:SetAddColour(col)
	self.base_add_colour_red = col.x
    self.base_add_colour_green = col.y
    self.base_add_colour_blue = col.z
	self:ApplyColour()
end

function Highlight:Flash(toadd, timein, timeout)
    self.flashadd = toadd
    self.flashtimein = timein
    self.flashtimeout = timeout
    self.t = 0
    self.flashing = true
    self.goingin = true
    
    self.inst:StartUpdatingComponent(self)
end

function Highlight:OnUpdate(dt)

    if not self.inst:IsValid() then
		self.inst:StopUpdatingComponent(self)
		self.flashing = false
		if not self.highlit then
			self.inst:RemoveComponent("highlight")
		end
		return
    end
    
    self.t = self.t + dt
    if self.flashing then
        
        local val = 0
        if self.goingin then
            if self.t > self.flashtimein then
                self.goingin = false
                self.t = 0
            end
            val = easing.outCubic( self.t, 0, self.flashadd, self.flashtimein)             
        end
    
        if not self.goingin then
            if self.t > self.flashtimeout then
                self.flashing = false
            end
            val = easing.outCubic( self.t, self.flashadd, 0, self.flashtimeout)                     
        end
        
        if self.highlit then
            val = val + .2
        end
        
        self.highlight_add_colour_red = val
        self.highlight_add_colour_green = val
        self.highlight_add_colour_blue = val
    end


    if not self.flashing then
        self.inst:StopUpdatingComponent(self)
        local val = 0
        
        if self.highlit then
            val = .2
        end
        
        self.highlight_add_colour_red = val
        self.highlight_add_colour_green = val
        self.highlight_add_colour_blue = val
    end

	self:ApplyColour()
end

function Highlight:ApplyColour()
    if self.inst.AnimState then
		self.inst.AnimState:SetHighlightColour((self.highlight_add_colour_red or 0) + (self.base_add_colour_red or 0), (self.highlight_add_colour_green or 0) + (self.base_add_colour_green or 0), (self.highlight_add_colour_blue or 0) + (self.base_add_colour_blue or 0), 0)
	end
end

function Highlight:Highlight(r,g,b)
    self.highlit = true
    
    if self.inst:IsValid() and self.inst:HasTag("player") or CanEntitySeeTarget(ThePlayer, self.inst) then
        local m = .2
		self.highlight_add_colour_red = r or m
        self.highlight_add_colour_green = g or m
        self.highlight_add_colour_blue = b or m
    end

	self:ApplyColour()    
end

function Highlight:UnHighlight()
    self.highlit = nil
	self.highlight_add_colour_red = nil
    self.highlight_add_colour_green = nil
    self.highlight_add_colour_blue = nil
	self:ApplyColour()   
	if not self.flashing then
		self.inst:RemoveComponent("highlight")
	end
end

function Highlight:OnRemoveFromEntity()
    if self.inst:IsValid() and self.inst.AnimState ~= nil then
        self.inst.AnimState:SetHighlightColour()
    end
end

return Highlight