local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local MoistureMeter = Class(Widget, function(self, owner)
    Widget._ctor(self, "MoistureMeter")
    self.owner = owner

    self:SetPosition(0, 0, 0)

    self.moisture = 0
    self.moisturedelta = 0
    self.active = false

    self.anim = self:AddChild(UIAnim())
    self.anim:GetAnimState():SetBank("wet")
    self.anim:GetAnimState():SetBuild("wet_meter_player")
    self.anim:SetClickable(true)

    self.arrowdir = "neutral"
    self.arrow = self.anim:AddChild(UIAnim())
    self.arrow:GetAnimState():SetBank("sanity_arrow")
    self.arrow:GetAnimState():SetBuild("sanity_arrow")
    self.arrow:GetAnimState():PlayAnimation(self.arrowdir)
    self.arrow:SetClickable(false)

    self.num = self:AddChild(Text(BODYTEXTFONT, 33))
    self.num:SetHAlign(ANCHOR_MIDDLE)
    self.num:SetPosition(5, 0, 0)
    self.num:SetClickable(false)
    self.num:Hide()
end)

function MoistureMeter:Activate()
    self.anim:GetAnimState():PlayAnimation("open")
    TheFrontEnd:GetSound():PlaySound("dontstarve_DLC001/common/HUD_wet_open")
end

function MoistureMeter:Deactivate()
    self.anim:GetAnimState():PlayAnimation("close")
    TheFrontEnd:GetSound():PlaySound("dontstarve_DLC001/common/HUD_wet_close")
end

function MoistureMeter:OnGainFocus()
    MoistureMeter._base:OnGainFocus(self)
    self.num:Show()
end

function MoistureMeter:OnLoseFocus()
    MoistureMeter._base:OnLoseFocus(self)
    self.num:Hide()
end

local RATE_SCALE_ANIM =
{
    [RATE_SCALE.INCREASE_HIGH] = "arrow_loop_increase_most",
    [RATE_SCALE.INCREASE_MED] = "arrow_loop_increase_more",
    [RATE_SCALE.INCREASE_LOW] = "arrow_loop_increase",
    [RATE_SCALE.DECREASE_HIGH] = "arrow_loop_decrease_most",
    [RATE_SCALE.DECREASE_MED] = "arrow_loop_decrease_more",
    [RATE_SCALE.DECREASE_LOW] = "arrow_loop_decrease",
}

function MoistureMeter:SetValue(moisture, max, ratescale)
    if moisture > 0 then
        if not self.active then
            self.active = true
            self:Activate()
        end
        self.anim:GetAnimState():SetPercent("anim", moisture / max)
        self.num:SetString(tostring(math.ceil(moisture)))
    elseif self.active then
        self.active = false
        self:Deactivate()
    end

    -- Update arrow
    local anim = "neutral"
    if ratescale == RATE_SCALE.INCREASE_LOW or
        ratescale == RATE_SCALE.INCREASE_MED or
        ratescale == RATE_SCALE.INCREASE_HIGH then
        if moisture < max then
            anim = RATE_SCALE_ANIM[ratescale]
        end
    elseif ratescale == RATE_SCALE.DECREASE_LOW or
        ratescale == RATE_SCALE.DECREASE_MED or
        ratescale == RATE_SCALE.DECREASE_HIGH then
        if moisture > 0 then
            anim = RATE_SCALE_ANIM[ratescale]
        end
    end
    if self.arrowdir ~= anim then
        self.arrowdir = anim
        self.arrow:GetAnimState():PlayAnimation(anim, true)
    end
end

return MoistureMeter