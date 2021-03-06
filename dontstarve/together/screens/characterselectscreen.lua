local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Button = require "widgets/button"
local ImageButton = require "widgets/imagebutton"
local CharacterSelect = require "widgets/characterselect"
local WardrobePopupScreen = require "screens/wardrobepopup"
local Menu = require "widgets/menu"
local TEMPLATES = require "widgets/templates"

local CharacterSelectScreen = Class(Screen, function(self, profile, character)
	Screen._ctor(self, "CharacterSelectScreen")

	
	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	
    
	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    --self.proot:SetPosition(-13,12,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.root = self.proot:AddChild(Widget("root"))
    self.root:SetPosition(-RESOLUTION_X/2, -RESOLUTION_Y/2, 0)


    self.panel = self.root:AddChild(TEMPLATES.CurlyWindow(75, 500, .75, .9, 60, -36))
    self.panel:SetPosition(RESOLUTION_X/2,RESOLUTION_Y/2-10)

    self.panel_bg = self.panel:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
	self.panel_bg:SetScale(.54, .74)
	self.panel_bg:SetPosition(7, 12)

	self.character_list = self.proot:AddChild(CharacterSelect(self, character))

	self.title = self.panel:AddChild(Text(BUTTONFONT, 36, STRINGS.UI.SKINSSCREEN.PICK, BLACK))
	self.title:SetPosition(10, 245)

    local button_w = 160
    local buttons = {}
    
    if not TheInput:ControllerAttached() then 
		table.insert(buttons, {text=STRINGS.UI.SKINSSCREEN.BACK, cb=function() self:Close() end })
	end
	
	table.insert(buttons, {text=STRINGS.UI.SKINSSCREEN.SELECT, cb=function() 
						self:Close() 
						TheFrontEnd:PushScreen(WardrobePopupScreen(nil, profile, self.character_list.herocharacter or character, true)) end
						})
    
	self.menu = self.proot:AddChild(Menu(buttons, button_w, true))
	self.menu:SetPosition(10-(button_w*(#buttons-1))/2, -285, 0) 
	for i,v in pairs(self.menu.items) do
		v:SetScale(.7)
	end

    if JapaneseOnPS4() then
		self.menu:SetTextSize(30)
	end

	TheInputProxy:SetCursorVisible(true)
	self.default_focus = self.menu

end)

function CharacterSelectScreen:Close()
	
	TheFrontEnd:PopScreen(self)
end


function CharacterSelectScreen:OnControl(control, down)
    
    if CharacterSelectScreen._base.OnControl(self, control, down) then return true end

    if not self.no_cancel and
    	not down and control == CONTROL_CANCEL then 
		self:Close()
		return true 
    end

    -- Use d-pad buttons for cycling players list
    -- Add trigger buttons to switch tabs
   	if not down then 
	 	if control == CONTROL_PREVVALUE then  -- r-stick left
	    	self.character_list:Scroll(-1)
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true 
		elseif control == CONTROL_NEXTVALUE then -- r-stick right
			self.character_list:Scroll(1)
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true
	    end
	end
end

function CharacterSelectScreen:GetHelpText()
	local controller_id = TheInput:GetControllerID()
    local t = {}
    
    if not self.no_cancel then
    	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
    end
 
 	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PREVVALUE) .. "/" .. TheInput:GetLocalizedControl(controller_id, CONTROL_NEXTVALUE) .." " .. STRINGS.UI.HELP.CHANGECHARACTER)
   
   	return table.concat(t, "  ")
end

return CharacterSelectScreen