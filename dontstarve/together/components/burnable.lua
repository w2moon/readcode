require("standardcomponents")

local SMOLDER_TICK_TIME = 2

local function oncanlight(self)
    if not self.burning and self.canlight then
        self.inst:AddTag("canlight")
        self.inst:RemoveTag("nolight")
    else
        self.inst:RemoveTag("canlight")
        self.inst:AddTag("nolight")
    end
end

local function onburning(self, burning)
    if burning then
        self.inst:AddTag("fire")
    else
        self.inst:RemoveTag("fire")
    end
    oncanlight(self)
end

local function onsmoldering(self, smoldering)
    if smoldering then
        self.inst:AddTag("smolder")
    else
        self.inst:RemoveTag("smolder")
    end
end

local Burnable = Class(function(self, inst)
    self.inst = inst

    self.flammability = 1

    self.fxdata = {}
    self.fxlevel = 1
    self.fxchildren = {}
    self.burning = false
    self.burntime = nil
    self.extinguishimmediately = true
    self.smoldertimeremaining = nil
    self.smoldering = false

    self.onignite = nil
    self.onextinguish = nil
    self.onburnt = nil
    self.canlight = true

    self.lightningimmune = false

    self.task = nil
    self.smolder_task = nil
end,
nil,
{
    burning = onburning,
    canlight = oncanlight,
    smoldering = onsmoldering,
})

--- Set the function that will be called when the object starts burning
function Burnable:SetOnIgniteFn(fn)
    self.onignite = fn
end

--- Set the function that will be called when the object has burned completely
function Burnable:SetOnBurntFn(fn)
    self.onburnt = fn
end

--- Set the function that will be called when the object stops burning
function Burnable:SetOnExtinguishFn(fn)
    self.onextinguish = fn
end

--- Set the prefab to use for the burning effect. Overrides the default
function Burnable:SetBurningFX(name)
    self.fxprefab = name
end

function Burnable:SetBurnTime(time)
    self.burntime = time
end

function Burnable:IsBurning()
    return self.burning
end

function Burnable:IsSmoldering()
    return self.smoldering
end

--- Add an effect to be spawned when burning
-- @param prefab The prefab to spawn as the effect
-- @param offset The offset from the burning entity/symbol that the effect should appear at
-- @param followsymbol Optional symbol for the effect to follow
function Burnable:AddBurnFX(prefab, offset, followsymbol)
    table.insert(self.fxdata, { prefab = prefab, x = offset.x, y = offset.y, z = offset.z, follow = followsymbol })
end

--- Set the level of any current or future burning effects
function Burnable:SetFXLevel(level, percent)
    self.fxlevel = level
    for i, v in ipairs(self.fxchildren) do
        if v.components.firefx ~= nil then
            v.components.firefx:SetLevel(level)
            v.components.firefx:SetPercentInLevel(percent or 1)
        end
    end
end

function Burnable:GetLargestLightRadius()
    local largestRadius = nil
    for i, v in ipairs(self.fxchildren) do
        if v.Light ~= nil and v.Light:IsEnabled() then
            local radius = v.Light:GetCalculatedRadius()
            if largestRadius == nil or radius > largestRadius then
                largestRadius = radius
            end
        end
    end
    return largestRadius
end

function Burnable:GetDebugString()
    return (self.smoldering and string.format("SMOLDERING %.2f", self.smoldertimeremaining))
        or (self.burning and "BURNING")
        or "NOT BURNING"
end

function Burnable:OnRemoveEntity()
    self:StopSmoldering()
    self:KillFX()
end

local function SmolderUpdate(inst, self)
    local x, y, z = inst.Transform:GetWorldPosition()
    -- this radius should be larger than the propogation, so that once
    -- there's a lot of blazes in an area, fire starts spreading quickly
    local ents = TheSim:FindEntities(x, y, z, 12)
    local nearbyheat = 0
    for i, v in ipairs(ents) do
        if v.components.propagator ~= nil then
            nearbyheat = nearbyheat + v.components.propagator.currentheat
        end
    end

    if TheWorld.state.israining then
        -- smolder more slowly, or even unsmolder, if we're being rained on.
        if nearbyheat > 0 then
            local rainmod = 1.8 * TheWorld.state.precipitationrate
            self.smoldertimeremaining = self.smoldertimeremaining + SMOLDER_TICK_TIME * rainmod
        else
            -- Un-smolder at a fixed rate when there's no more heat, otherwise it takes foreeeever during gentle rain.
            self.smoldertimeremaining = self.smoldertimeremaining + SMOLDER_TICK_TIME * 3.0
        end
    end

    -- smolder about twice as fast if there's lots of heat nearby
    local heatmod = math.clamp(Remap(nearbyheat, 20, 90, 1, 2.2), 1, 2.2)

    self.smoldertimeremaining = self.smoldertimeremaining - SMOLDER_TICK_TIME * heatmod
    if self.smoldertimeremaining <= 0 then
        self:StopSmoldering() --JUST in case ignite fails...
        self:Ignite()
    elseif self.inst.components.propagator
        and self.inst.components.propagator.flashpoint
        and self.smoldertimeremaining > self.inst.components.propagator.flashpoint * 1.1 -- a small buffer to prevent flickering
        then
        -- extinguished by rain
        self:StopSmoldering()
    end
end

function Burnable:StartWildfire()
    if not (self.burning or self.smoldering or self.inst:HasTag("fireimmune")) then
        self.smoldering = true
        self.smoke = SpawnPrefab("smoke_plant")
        if self.smoke ~= nil then
            if #self.fxdata == 1 and self.fxdata[1].follow then
                local follower = self.smoke.entity:AddFollower()
                follower:FollowSymbol(self.inst.GUID, self.fxdata[1].follow, self.fxdata[1].x, self.fxdata[1].y, self.fxdata[1].z)
            else
                self.inst:AddChild(self.smoke)
            end
            self.smoke.Transform:SetPosition(0, 0, 0)
        end

        self.smoldertimeremaining =
            self.inst.components.propagator ~= nil and
            self.inst.components.propagator.flashpoint or
            math.random(TUNING.MIN_SMOLDER_TIME, TUNING.MAX_SMOLDER_TIME)

        if self.smolder_task ~= nil then
            self.smolder_task:Cancel()
        end
        self.smolder_task = self.inst:DoPeriodicTask(SMOLDER_TICK_TIME, SmolderUpdate, math.random() * SMOLDER_TICK_TIME, self)
    end
end

local function DoneBurning(inst, self)
    RemoveDragonflyBait(inst)

    inst:PushEvent("onburnt")

    if self.onburnt ~= nil then
        self.onburnt(inst)
    end

    if inst.components.explosive ~= nil then
        --explosive explode
        inst.components.explosive:OnBurnt()
    end

    if self.extinguishimmediately then
        self:Extinguish()
    end
end

local function OnKilled(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() and not inst:HasTag("player") then
        inst.AnimState:SetMultColour(.2, .2, .2, 1)
    end
end

function Burnable:Ignite(immediate, source)
    if not (self.burning or self.inst:HasTag("fireimmune")) then
        self:StopSmoldering()

        self.burning = true
        self.inst:ListenForEvent("death", OnKilled)
        self:SpawnFX(immediate)

        self.inst:PushEvent("onignite")
        if self.onignite ~= nil then
            self.onignite(self.inst)
        end

        if self.inst.components.explosive ~= nil then
            --explosive on ignite
            self.inst.components.explosive:OnIgnite()
        end

        if self.inst.components.fueled ~= nil then
            self.inst.components.fueled:StartConsuming()
        end

        if self.inst.components.propagator ~= nil then
            self.inst.components.propagator:StartSpreading(source)
        end

        if self.task ~= nil then
            self.task:Cancel()
        end
        self.task = self.burntime ~= nil and self.inst:DoTaskInTime(self.burntime, DoneBurning, self) or nil
    end
end

function Burnable:LongUpdate(dt)
    --kind of a coarse assumption...
    if self.burning then
        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end
        DoneBurning(self.inst, self)
    end
end

function Burnable:SmotherSmolder(smotherer)
    if smotherer ~= nil then
        if smotherer.components.finiteuses ~= nil then
            smotherer.components.finiteuses:Use()
        elseif smotherer.components.stackable ~= nil then
            smotherer.components.stackable:Get():Remove()
        elseif smotherer.components.health ~= nil and smotherer.components.combat ~= nil then
            smotherer.components.health:DoFireDamage(TUNING.SMOTHER_DAMAGE, nil, true)
            smotherer:PushEvent("burnt")
        end
    end
    self:StopSmoldering(-1) -- After you smother something, it has a bit of forgiveness before it will light again
end

function Burnable:StopSmoldering(heatpct)
    if self.smoldering then
        if self.smoke ~= nil then 
            self.smoke.SoundEmitter:KillSound("smolder")
            self.smoke:Remove() 
        end
        self.smoldering = false
        if self.smolder_task ~= nil then
            self.smolder_task:Cancel()
            self.smolder_task = nil
        end
        self.smoldertimeremaining = nil

        if self.inst.components.propagator ~= nil then
            self.inst.components.propagator:StopSpreading(true, heatpct)
        end
    end
end

function Burnable:Extinguish(resetpropagator, heatpct, smotherer)
    self:StopSmoldering()

    if smotherer ~= nil then
        if smotherer.components.finiteuses ~= nil then
            smotherer.components.finiteuses:Use()
        elseif smotherer.components.stackable ~= nil then
            smotherer.components.stackable:Get():Remove()
        end
    end

    if self.burning then
        if self.task ~= nil then
            self.task:Cancel()
            self.task = nil
        end

        self.inst:RemoveEventCallback("death", OnKilled)

        if self.inst.components.propagator ~= nil then
            if resetpropagator then
                self.inst.components.propagator:StopSpreading(true, heatpct)
            else
                self.inst.components.propagator:StopSpreading()
            end
        end

        self.burning = false
        self:KillFX()
        if self.inst.components.fueled ~= nil then
            self.inst.components.fueled:StopConsuming()
        end
        if self.onextinguish ~= nil then
            self.onextinguish(self.inst)
        end
        self.inst:PushEvent("onextinguish")
    end
end


function Burnable:SpawnFX(immediate)
    self:KillFX()

    if self.fxdata == nil then
        self.fxdata = { x = 0, y = 0, z = 0, level = self:GetDefaultFXLevel() }
    end

    for k, v in pairs(self.fxdata) do
        local fx = SpawnPrefab(v.prefab)
        if fx ~= nil then
            fx.Transform:SetScale(self.inst.Transform:GetScale())
            if v.follow ~= nil then
                local follower = fx.entity:AddFollower()
                follower:FollowSymbol(self.inst.GUID, v.follow, v.x, v.y, v.z)
            else
                self.inst:AddChild(fx)
                fx.Transform:SetPosition(v.x, v.y, v.z)
            end
            fx.persists = false
            table.insert(self.fxchildren, fx)
            if fx.components.firefx ~= nil then
                fx.components.firefx:SetLevel(self.fxlevel, immediate)
            end
        end
    end
end

function Burnable:KillFX()
    for i = #self.fxchildren, 1, -1 do
        local fx = self.fxchildren[i]
        if fx.components.firefx ~= nil and fx.components.firefx:Extinguish() then
            --remove once the pst animation has finished
            --schedule it as well in case it goes asleep
            fx:ListenForEvent("animover", fx.Remove)
            fx:DoTaskInTime(fx.AnimState:GetCurrentAnimationLength() + FRAMES, fx.Remove)
        else
            fx:Remove()
        end
        table.remove(self.fxchildren, i)
    end
end

function Burnable:HasEndothermicHeat()
    for i, v in ipairs(self.fxchildren) do
        if v.components.heater ~= nil and v.components.heater:IsEndothermic() then
            return true
        end
    end
    return false
end

function Burnable:HasExothermicHeat()
    for i, v in ipairs(self.fxchildren) do
        if v.components.heater ~= nil and v.components.heater:IsExothermic() then
            return true
        end
    end
    return false
end

function Burnable:OnRemoveFromEntity()
    --self:StopSmoldering()
    --Extinguish() already calls StopSmoldering()
    self:Extinguish()
    RemoveDragonflyBait(self.inst)
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
    self.inst:RemoveTag("canlight")
    self.inst:RemoveTag("nolight")
end

return Burnable