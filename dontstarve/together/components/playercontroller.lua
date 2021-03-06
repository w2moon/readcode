local START_DRAG_TIME = (1/30)*8
local BUTTON_REPEAT_COOLDOWN = 0.5

local function OnPlayerActivated(inst)
    inst.components.playercontroller:Activate()
end

local function OnPlayerDeactivated(inst)
    inst.components.playercontroller:Deactivate()
end

local PlayerController = Class(function(self, inst)
    self.inst = inst

    --cache variables
    self.map = TheWorld.Map
    self.ismastersim = TheWorld.ismastersim
    self.locomotor = self.inst.components.locomotor

    --attack control variables
    self.attack_buffer = nil
    self.controller_attack_override = nil

    --remote control variables
    self.remote_vector = Vector3()
    self.remote_controls = {}

    self.dragwalking = false
    self.directwalking = false
    self.predictwalking = false
    self.predictionsent = false
    self.draggingonground = false
    self.startdragtestpos = nil
    self.startdragtime = nil
    self.isclientcontrollerattached = false

    self.mousetimeout = 10
    self.time_direct_walking = 0

    self.controller_target = nil
    self.controller_target_age = math.huge
    self.controller_attack_target = nil
    self.controller_attack_target_ally_cd = nil
    --self.controller_attack_target_age = math.huge

    self.reticule = nil
    self.terraformer = nil
    self.deploy_mode = not TheInput:ControllerAttached()
    self.deployplacer = nil

    self.LMBaction = nil
    self.RMBaction = nil

    self.handler = nil
    self.actionbuttonoverride = nil

    if self.ismastersim then
        self.is_map_enabled = true
        self.can_use_map = true
        self.classified = inst.player_classified
        self.inst:StartUpdatingComponent(self)
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end

    inst:ListenForEvent("playeractivated", OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
end)

--------------------------------------------------------------------------

function PlayerController:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("playeractivated", OnPlayerActivated)
    self.inst:RemoveEventCallback("playerdeactivated", OnPlayerDeactivated)
    self:Deactivate()
    if self.classified ~= nil then
        if self.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

PlayerController.OnRemoveEntity = PlayerController.OnRemoveFromEntity

function PlayerController:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function PlayerController:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------

local function OnBuild(inst)
    inst.components.playercontroller:CancelPlacement()
end

local function OnEquip(inst, data)
    --Reticule targeting items
    if data.eslot == EQUIPSLOTS.HANDS then
        local self = inst.components.playercontroller
        if self.reticule ~= nil then
            self.reticule:DestroyReticule()
        end
        self.reticule = data.item.components.reticule
        if self.reticule ~= nil and self.reticule.reticule == nil and TheInput:ControllerAttached() then
            self.reticule:CreateReticule()
        end
    end
end

local function OnUnequip(inst, data)
    --Reticule targeting items
    if data.eslot == EQUIPSLOTS.HANDS then
        local self = inst.components.playercontroller
        if self.reticule ~= nil then
            local equip = inst.replica.inventory:GetEquippedItem(data.eslot)
            if equip == nil or self.reticule ~= equip.components.reticule then
                self.reticule:DestroyReticule()
                self.reticule = nil
            end
        end
    end
end

local function OnInventoryClosed(inst)
    --Reticule targeting items
    local self = inst.components.playercontroller
    if self.reticule ~= nil then
        self.reticule:DestroyReticule()
        self.reticule = nil
    end
end

local function OnContinueFromPause()
    ThePlayer.components.playercontroller:ToggleController(TheInput:ControllerAttached())
end

local function OnReachDestination(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.components.playercontroller:RemotePredictWalking(x, z)
end

function PlayerController:Activate()
    if self.handler ~= nil then
        if self.inst ~= ThePlayer then
            self:Deactivate()
        end
    elseif self.inst == ThePlayer then
        self.handler = TheInput:AddGeneralControlHandler(function(control, value) self:OnControl(control, value) end)

        --reset the remote controllers just in case there was some old data
        self:ResetRemoteController()
        self.predictionsent = false
        self.isclientcontrollerattached = false

        local item = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if self.reticule ~= nil then
            self.reticule:DestroyReticule()
        end
        self.reticule = item ~= nil and item.components.reticule or nil
        if self.reticule ~= nil and self.reticule.reticule == nil and TheInput:ControllerAttached() then
            self.reticule:CreateReticule()
        end

        self.inst:ListenForEvent("buildstructure", OnBuild)
        self.inst:ListenForEvent("equip", OnEquip)
        self.inst:ListenForEvent("unequip", OnUnequip)
        if not TheWorld.ismastersim then
            --Client only event, because when inventory is closed, we will stop
            --getting "equip" and "unequip" events, but we can also assume that
            --our inventory is emptied.
            self.inst:ListenForEvent("inventoryclosed", OnInventoryClosed)
        end
        self.inst:ListenForEvent("continuefrompause", OnContinueFromPause, TheWorld)
        OnContinueFromPause()

        if not self.ismastersim then
            self.inst:ListenForEvent("onreachdestination", OnReachDestination)
            self.inst:StartUpdatingComponent(self)
        end
    end
end

function PlayerController:Deactivate()
    if self.handler ~= nil then
        self:CancelPlacement()
        self:CancelDeployPlacement()

        if self.terraformer ~= nil then
            self.terraformer:Remove()
            self.terraformer = nil
        end

        if self.reticule ~= nil then
            self.reticule:DestroyReticule()
            self.reticule = nil
        end

        self.handler:Remove()
        self.handler = nil

        --reset the remote controllers just in case there was some old data
        self:ResetRemoteController()
        self.predictionsent = false
        self.isclientcontrollerattached = false

        self.inst:RemoveEventCallback("buildstructure", OnBuild)
        self.inst:RemoveEventCallback("equip", OnEquip)
        self.inst:RemoveEventCallback("unequip", OnUnequip)
        if not TheWorld.ismastersim then
            self.inst:RemoveEventCallback("inventoryclosed", OnInventoryClosed)
        end
        self.inst:RemoveEventCallback("continuefrompause", OnContinueFromPause, TheWorld)

        if not self.ismastersim then
            self.inst:RemoveEventCallback("onreachdestination", OnReachDestination)
            self.inst:StopUpdatingComponent(self)
        end
    end
end

--------------------------------------------------------------------------

function PlayerController:Enable(val)
    if self.ismastersim then
        self.classified.iscontrollerenabled:set(val)
    end
end

function PlayerController:ToggleController(val)
    if self.isclientcontrollerattached ~= val then
        self.isclientcontrollerattached = val
        if not self.ismastersim then
            SendRPCToServer(RPC.ToggleController, val)
        elseif val and self.inst.components.inventory ~= nil then
            self.inst.components.inventory:ReturnActiveItem()
        end
    end
end

function PlayerController:EnableMapControls(val)
    if self.ismastersim then
        self.is_map_enabled = val == true
        self.classified:EnableMapControls(val and self.can_use_map)
    end
end

function PlayerController:SetCanUseMap(val)
    if self.ismastersim then
        self.can_use_map = val == true
        self.classified:EnableMapControls(val and self.is_map_enabled)
    end
end

function PlayerController:IsEnabled()
    if self.classified == nil or not self.classified.iscontrollerenabled:value() then
        return false
    elseif self.inst.HUD ~= nil and self.inst.HUD:HasInputFocus() then
        return false, true
    end
    return true
end

function PlayerController:IsMapControlsEnabled()
    return self.classified ~= nil and
        self.classified.iscontrollerenabled:value() and
        self.classified.ismapcontrolsvisible:value() and
        self.inst.HUD ~= nil
end

function PlayerController:IsControlPressed(control)
    if self.handler ~= nil then
        return TheInput:IsControlPressed(control)
    else
        return self.remote_controls[control] ~= nil
    end
end

function PlayerController:IsAnyOfControlsPressed(...)
    if self.handler ~= nil then
        for i, v in ipairs({...}) do
            if TheInput:IsControlPressed(v) then
                return true
            end
        end
    else
        for i, v in ipairs({...}) do
            if self.remote_controls[v] ~= nil then
                return true
            end
        end
    end
end

function PlayerController:CooldownRemoteController(dt)
    for k, v in pairs(self.remote_controls) do
        self.remote_controls[k] = dt ~= nil and math.max(v - dt, 0) or 0
    end
end

function PlayerController:OnRemoteStopControl(control)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.remote_controls[control] = nil
    end
end

function PlayerController:OnRemoteStopAllControls()
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        if next(self.remote_controls) ~= nil then
            self.remote_controls = {}
        end
    end
end

function PlayerController:RemoteStopControl(control)
    if self.remote_controls[control] ~= nil then
        self.remote_controls[control] = nil
        SendRPCToServer(RPC.StopControl, control)
    end
end

function PlayerController:RemoteStopAllControls()
    if next(self.remote_controls) ~= nil then
        self.remote_controls = {}
        SendRPCToServer(RPC.StopAllControls)
    end
end

function PlayerController:RemotePausePrediction(frames)
    if self.ismastersim then
        self.classified:PushPausePredictionFrames(frames or 0)
    end
end

function PlayerController:OnControl(control, down)
    if not self:IsEnabled() or IsPaused() then
        return
    elseif control == CONTROL_PRIMARY then
        self:OnLeftClick(down)
    elseif control == CONTROL_SECONDARY then
        self:OnRightClick(down)
    elseif not down then
        if not self.ismastersim then
            self:RemoteStopControl(control)
        end
    elseif control == CONTROL_CANCEL then
        self:CancelPlacement()
    elseif control == CONTROL_INSPECT then
        self:DoInspectButton()
    elseif control == CONTROL_ACTION then
        self:DoActionButton()
    elseif control == CONTROL_ATTACK then
        if self.ismastersim then
            self.attack_buffer = CONTROL_ATTACK
        else
            self:DoAttackButton()
        end
    elseif control == CONTROL_CONTROLLER_ALTACTION then
        self:DoControllerAltActionButton()
    elseif control == CONTROL_CONTROLLER_ACTION then
        self:DoControllerActionButton()
    elseif control == CONTROL_CONTROLLER_ATTACK then
        if self.ismastersim then
            self.attack_buffer = CONTROL_CONTROLLER_ATTACK
        else
            self:DoControllerAttackButton()
        end
    elseif self.inst.replica.inventory:IsVisible() then
        local inv_obj = self:GetCursorInventoryObject()
        if inv_obj ~= nil then
            if control == CONTROL_INVENTORY_DROP then
                self:DoControllerDropItemFromInvTile(inv_obj)
            elseif control == CONTROL_INVENTORY_EXAMINE then
                self:DoControllerInspectItemFromInvTile(inv_obj)
            elseif control == CONTROL_INVENTORY_USEONSELF then
                self:DoControllerUseItemOnSelfFromInvTile(inv_obj)
            elseif control == CONTROL_INVENTORY_USEONSCENE then
                self:DoControllerUseItemOnSceneFromInvTile(inv_obj)
            end
        end
    end
end

--------------------------------------------------------------------------

local MOD_CONTROLS =
{
    CONTROL_FORCE_INSPECT,
    CONTROL_FORCE_ATTACK,
    CONTROL_FORCE_TRADE,
    CONTROL_FORCE_STACK,
}

function PlayerController:EncodeControlMods()
    local code = 0
    local bit = 1
    for i, v in ipairs(MOD_CONTROLS) do
        code = code + (TheInput:IsControlPressed(v) and bit or 0)
        bit = bit * 2
    end
    return code ~= 0 and code or nil
end

function PlayerController:DecodeControlMods(code)
    code = code or 0
    local bit = 2 ^ (#MOD_CONTROLS - 1)
    for i = #MOD_CONTROLS, 1, -1 do
        if code >= bit then
            self.remote_controls[MOD_CONTROLS[i]] = 0
            code = code - bit
        else
            self.remote_controls[MOD_CONTROLS[i]] = nil
        end
        bit = bit / 2
    end
end

function PlayerController:ClearControlMods()
    for i, v in ipairs(MOD_CONTROLS) do
        self.remote_controls[v] = nil
    end
end

function PlayerController:CanLocomote()
    return self.ismastersim
        or (self.locomotor ~= nil and
            not (self.inst.sg:HasStateTag("busy") or
                self.inst:HasTag("pausepredict") or
                (self.classified ~= nil and self.classified.pausepredictionframes:value() > 0)) and
            self.inst.entity:CanPredictMovement())
end

function PlayerController:IsBusy()
    if self.ismastersim then
        return self.inst.sg:HasStateTag("busy")
    else
        return self.inst:HasTag("busy")
            or (self.inst.sg ~= nil and self.inst.sg:HasStateTag("busy"))
            or (self.classified ~= nil and self.classified.pausepredictionframes:value() > 0)
    end
end

--------------------------------------------------------------------------

function PlayerController:GetCursorInventoryObject()
    if self.inst.HUD ~= nil then
        local item = self.inst.HUD.controls.inv:GetCursorItem()
        return item ~= nil and item:IsValid() and item or nil
    end
end

function PlayerController:GetCursorInventorySlotAndContainer()
    if self.inst.HUD ~= nil then
        return self.inst.HUD.controls.inv:GetCursorSlot()
    end
end

function PlayerController:DoControllerActionButton()
    if self.placer ~= nil then
        --do the placement
        if self.placer_recipe ~= nil and
            self.placer.components.placer.can_build and
            self.inst.replica.builder ~= nil and
            not self.inst.replica.builder:IsBusy() then
            self.inst.replica.builder:MakeRecipeAtPoint(self.placer_recipe, self.placer:GetPosition(), self.placer:GetRotation(), self.placer_recipe_skin)
            self:CancelPlacement()
        end
        return
    end

    local obj = nil
    local act = nil
    if self.deployplacer ~= nil then
        if self.deployplacer.components.placer.can_build then
            act = self.deployplacer.components.placer:GetDeployAction()
            if act ~= nil then
                obj = act.invobject
                act.distance = 1
            end
        end
    else
        obj = self:GetControllerTarget()
        if obj ~= nil then
            act = self:GetSceneItemControllerAction(obj)
        end
    end

    if act == nil then
        return
    elseif self.ismastersim then
        self.inst.components.combat:SetTarget(nil)
    elseif self.deployplacer ~= nil then
        if self.locomotor == nil then
            self.remote_controls[CONTROL_CONTROLLER_ACTION] = 0
            SendRPCToServer(RPC.ControllerActionButtonDeploy, obj, act.pos.x, act.pos.z)
        elseif self:CanLocomote() then
            act.preview_cb = function()
                self.remote_controls[CONTROL_CONTROLLER_ACTION] = 0
                local isreleased = not TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION)
                SendRPCToServer(RPC.ControllerActionButtonDeploy, obj, act.pos.x, act.pos.z, isreleased)
            end
        end
    elseif self.locomotor == nil then
        self.remote_controls[CONTROL_CONTROLLER_ACTION] = 0
        SendRPCToServer(RPC.ControllerActionButton, act.action.code, obj, nil, act.action.canforce, act.action.mod_name)
    elseif self:CanLocomote() then
        act.preview_cb = function()
            self.remote_controls[CONTROL_CONTROLLER_ACTION] = 0
            local isreleased = not TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION)
            SendRPCToServer(RPC.ControllerActionButton, act.action.code, obj, isreleased, nil, act.action.mod_name)
        end
    end

    self:DoAction(act)
end

function PlayerController:OnRemoteControllerActionButton(actioncode, target, isreleased, noforce, mod_name)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.inst.components.combat:SetTarget(nil)

        self.remote_controls[CONTROL_CONTROLLER_ACTION] = 0
        self:ClearControlMods()
        local lmb, rmb = self:GetSceneItemControllerAction(target)
        if isreleased then
            self.remote_controls[CONTROL_CONTROLLER_ACTION] = nil
        end

        --Possible for lmb action to switch to rmb after autoequip
        lmb =  (lmb ~= nil and
                lmb.action.code == actioncode and
                lmb.action.mod_name == mod_name and
                lmb)
            or (rmb ~= nil and
                rmb.action.code == actioncode and
                rmb.action.mod_name == mod_name and
                rmb)
            or nil

        if lmb ~= nil then
            if lmb.action.canforce and not noforce then
                lmb.pos = self:GetRemotePredictPosition() or self.inst:GetPosition()
                lmb.forced = true
            end
            self:DoAction(lmb)
        --elseif mod_name ~= nil then
            --print("Remote controller action button action failed: "..tostring(ACTION_MOD_IDS[mod_name][actioncode]))
        --else
            --print("Remote controller action button action failed: "..tostring(ACTION_IDS[actioncode]))
        end
    end
end

function PlayerController:OnRemoteControllerActionButtonDeploy(invobject, position, isreleased)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.inst.components.combat:SetTarget(nil)

        self.remote_controls[CONTROL_CONTROLLER_ACTION] = not isreleased and 0 or nil

        if invobject.components.inventoryitem ~= nil and invobject.components.inventoryitem:GetGrandOwner() == self.inst then
            --Must match placer:GetDeployAction(), with an additional distance = 1 parameter
            self:DoAction(BufferedAction(self.inst, nil, ACTIONS.DEPLOY, invobject, position, nil, 1))
        --else
            --print("Remote controller action button deploy failed")
        end
    end
end

function PlayerController:DoControllerAltActionButton()
    if self.placer_recipe ~= nil then
        self:CancelPlacement()
        return
    end

    if self.deployplacer ~= nil then
        self:CancelDeployPlacement()
        return
    end

    local lmb, act = self:GetGroundUseAction()
    local obj = nil
    if act == nil then
        obj = self:GetControllerTarget()
        if obj ~= nil then
            lmb, act = self:GetSceneItemControllerAction(obj)
        end
        if act == nil then
            local rider = self.inst.replica.rider
            if rider ~= nil and rider:IsRiding() then
                obj = self.inst
                act = BufferedAction(obj, obj, ACTIONS.DISMOUNT)
            end
        end
    end

    if act == nil then
        return
    elseif self.ismastersim then
        self.inst.components.combat:SetTarget(nil)
    elseif obj ~= nil then
        if self.locomotor == nil then
            self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = 0
            SendRPCToServer(RPC.ControllerAltActionButton, act.action.code, obj, nil, act.action.canforce, act.action.mod_name)
        elseif self:CanLocomote() then
            act.preview_cb = function()
                self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = 0
                local isreleased = not TheInput:IsControlPressed(CONTROL_CONTROLLER_ALTACTION)
                SendRPCToServer(RPC.ControllerAltActionButton, act.action.code, obj, isreleased, nil, act.action.mod_name)
            end
        end
    elseif self.locomotor == nil then
        self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = 0
        SendRPCToServer(RPC.ControllerAltActionButtonPoint, act.action.code, act.pos.x, act.pos.z, nil, act.action.canforce, act.action.mod_name)
    elseif self:CanLocomote() then
        act.preview_cb = function()
            self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = 0
            local isreleased = not TheInput:IsControlPressed(CONTROL_CONTROLLER_ALTACTION)
            SendRPCToServer(RPC.ControllerAltActionButtonPoint, act.action.code, act.pos.x, act.pos.z, isreleased, nil, act.action.mod_name)
        end
    end

    self:DoAction(act)
end

function PlayerController:OnRemoteControllerAltActionButton(actioncode, target, isreleased, noforce, mod_name)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.inst.components.combat:SetTarget(nil)

        self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = 0
        self:ClearControlMods()
        local lmb, rmb = self:GetSceneItemControllerAction(target)
        if isreleased then
            self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = nil
        end

        --Possible for rmb action to switch to lmb after autoequip
        --Probably not, but fairly inexpensive to be safe =)
        rmb =  (rmb ~= nil and
                rmb.action.code == actioncode and
                rmb.action.mod_name == mod_name and
                rmb)
            or (lmb ~= nil and
                lmb.action.code == actioncode and
                lmb.action.mod_name == mod_name and
                lmb)
            or nil

        if rmb ~= nil then
            if rmb.action.canforce and not noforce then
                rmb.pos = self:GetRemotePredictPosition() or self.inst:GetPosition()
                rmb.forced = true
            end
            self:DoAction(rmb)
        --elseif mod_name ~= nil then
            --print("Remote controller alt action button action failed: "..tostring(ACTION_MOD_IDS[mod_name][actioncode]))
        --else
            --print("Remote controller alt action button action failed: "..tostring(ACTION_IDS[actioncode]))
        end
    end
end

function PlayerController:OnRemoteControllerAltActionButtonPoint(actioncode, position, isreleased, noforce, mod_name)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.inst.components.combat:SetTarget(nil)

        self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = 0
        self:ClearControlMods()
        local lmb, rmb = self:GetGroundUseAction(position)
        if isreleased then
            self.remote_controls[CONTROL_CONTROLLER_ALTACTION] = nil
        end

        --Possible for rmb action to switch to lmb after autoequip
        --Probably not, but fairly inexpensive to be safe =)
        rmb =  (rmb ~= nil and
                rmb.action.code == actioncode and
                rmb.action.mod_name == mod_name and
                rmb)
            or (lmb ~= nil and
                lmb.action.code == actioncode and
                lmb.action.mod_name == mod_name and
                lmb)
            or nil

        if rmb ~= nil then
            if rmb.action.canforce and not noforce then
                rmb.pos = self:GetRemotePredictPosition() or self.inst:GetPosition()
                rmb.forced = true
            end
            self:DoAction(rmb)
        --elseif mod_name ~= nil then
            --print("Remote controller alt action button point action failed: "..tostring(ACTION_MOD_IDS[mod_name][actioncode]))
        --else
            --print("Remote controller alt action button point action failed: "..tostring(ACTION_IDS[actioncode]))
        end
    end
end

function PlayerController:DoControllerAttackButton(target)
    if target ~= nil then
        --Don't want to spam the controller attack button when retargetting
        if not self.ismastersim and (self.remote_controls[CONTROL_CONTROLLER_ATTACK] or 0) > 0 then
            return
        end

        if self.inst.sg ~= nil then
            if self.inst.sg:HasStateTag("attack") then
                return
            end
        elseif self.inst:HasTag("attack") then
            return
        end

        if not self.inst.replica.combat:CanHitTarget(target) or
            target.replica.health == nil or
            target.replica.health:IsDead() or
            not CanEntitySeeTarget(self.inst, target) then
            return
        end
    else
        target = self.controller_attack_target
        if target ~= nil then
            if target == self.inst.replica.combat:GetTarget() then
                --Still need to let the server know our controller attack button is down
                if not self.ismastersim and
                    self.locomotor == nil and
                    self.remote_controls[CONTROL_CONTROLLER_ATTACK] == nil then
                    self.remote_controls[CONTROL_CONTROLLER_ATTACK] = 0
                    SendRPCToServer(RPC.ControllerAttackButton, true)
                end
                return
            elseif not self.inst.replica.combat:CanTarget(target) then
                target = nil
            end
        end
        --V2C: controller attacks still happen even with no valid target
        if target == nil and self.inst:HasTag("playerghost") then
            --Except for player ghosts!
            return
        end
    end

    local act = BufferedAction(self.inst, target, ACTIONS.ATTACK)

    if self.ismastersim then
        self.inst.components.combat:SetTarget(nil)
    elseif self.locomotor == nil then
        self.remote_controls[CONTROL_CONTROLLER_ATTACK] = BUTTON_REPEAT_COOLDOWN
        SendRPCToServer(RPC.ControllerAttackButton, target, nil, act.action.canforce)
    elseif self:CanLocomote() then
        act.preview_cb = function()
            self.remote_controls[CONTROL_CONTROLLER_ATTACK] = BUTTON_REPEAT_COOLDOWN
            local isreleased = not TheInput:IsControlPressed(CONTROL_CONTROLLER_ATTACK)
            SendRPCToServer(RPC.ControllerAttackButton, target, isreleased)
        end
    end

    self:DoAction(act)
end

function PlayerController:OnRemoteControllerAttackButton(target, isreleased, noforce)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        --Check if target is valid, otherwise make
        --it nil so that we still attack and miss.
        if target == true then
            --Special case, just flagging the button as down
            self.remote_controls[CONTROL_CONTROLLER_ATTACK] = 0
        elseif not noforce then
            if self.inst.sg:HasStateTag("attack") then
                self.inst.sg.statemem.chainattack_cb = function()
                    self:OnRemoteControllerAttackButton(target)
                end
            else
                target = self.inst.components.combat:CanTarget(target) and target or nil
                self.attack_buffer = BufferedAction(self.inst, target, ACTIONS.ATTACK, nil, nil, nil, nil, true)
                self.attack_buffer._controller = true
                self.attack_buffer._predictpos = true
            end
        else
            self.remote_controls[CONTROL_CONTROLLER_ATTACK] = 0
            if self.inst.components.combat:CanTarget(target) then
                self.attack_buffer = BufferedAction(self.inst, target, ACTIONS.ATTACK)
                self.attack_buffer._controller = true
            else
                self.attack_buffer = BufferedAction(self.inst, nil, ACTIONS.ATTACK, nil, nil, nil, nil, true)
                self.attack_buffer._controller = true
                self.attack_buffer._predictpos = true
                self.attack_buffer.overridedest = self.inst
            end
        end
    end
end

function PlayerController:DoControllerDropItemFromInvTile(item)
    self.inst.replica.inventory:DropItemFromInvTile(item)
end

function PlayerController:DoControllerInspectItemFromInvTile(item)
    self.inst.replica.inventory:InspectItemFromInvTile(item)
end

function PlayerController:DoControllerUseItemOnSelfFromInvTile(item)
    if not self.deploy_mode and
        item.replica.inventoryitem:IsDeployable() and
        item.replica.inventoryitem:IsGrandOwner(self.inst) then
        self.deploy_mode = true
        return
    end
    self.inst.replica.inventory:ControllerUseItemOnSelfFromInvTile(item)
end

function PlayerController:DoControllerUseItemOnSceneFromInvTile(item)
    if item.replica.inventoryitem ~= nil and not item.replica.inventoryitem:IsGrandOwner(self.inst) then
        local slot, container = self:GetCursorInventorySlotAndContainer()
        if slot ~= nil and container ~= nil then
            container:MoveItemFromAllOfSlot(slot, self.inst)
        end
    else
        self.inst.replica.inventory:ControllerUseItemOnSceneFromInvTile(item)
    end
end

function PlayerController:RotLeft()
    if not TheCamera:CanControl() then
        return
    end
    local rotamount = 45 ---90-- TheWorld:HasTag("cave") and 22.5 or 45
    if not IsPaused() then
        TheCamera:SetHeadingTarget(TheCamera:GetHeadingTarget() - rotamount) 
        --UpdateCameraHeadings() 
    elseif self.inst.HUD ~= nil and self.inst.HUD:IsMapScreenOpen() then
        TheCamera:SetHeadingTarget(TheCamera:GetHeadingTarget() - rotamount) 
        TheCamera:Snap()
    end
end

function PlayerController:RotRight()
    if not TheCamera:CanControl() then
        return
    end
    local rotamount = 45 --90--TheWorld:HasTag("cave") and 22.5 or 45
    if not IsPaused() then
        TheCamera:SetHeadingTarget(TheCamera:GetHeadingTarget() + rotamount) 
        --UpdateCameraHeadings() 
    elseif self.inst.HUD ~= nil and self.inst.HUD:IsMapScreenOpen() then
        TheCamera:SetHeadingTarget(TheCamera:GetHeadingTarget() + rotamount) 
        TheCamera:Snap()
    end
end

function PlayerController:GetHoverTextOverride()
    return self.placer_recipe ~= nil and (STRINGS.UI.HUD.BUILD.." "..(STRINGS.NAMES[string.upper(self.placer_recipe.name)] or STRINGS.UI.HUD.HERE)) or nil
end

function PlayerController:CancelPlacement()
    if self.placer ~= nil then
        self.placer:Remove()
        self.placer = nil
    end
    self.placer_recipe = nil
    self.placer_recipe_skin = nil
end

function PlayerController:CancelDeployPlacement()
    self.deploy_mode = not TheInput:ControllerAttached()
    if self.deployplacer ~= nil then
        self.deployplacer:Remove()
        self.deployplacer = nil
    end
end

function PlayerController:StartBuildPlacementMode(recipe, skin)
    self.placer_recipe = recipe
    self.placer_recipe_skin = skin
    if self.placer then
        self.placer:Remove()
        self.placer = nil
    end

    if skin ~= nil then
        self.placer = SpawnPrefab(recipe.placer, skin, nil, self.inst.userid)
    else
        self.placer = SpawnPrefab(recipe.placer)
    end
    
    self.placer.components.placer:SetBuilder(self.inst, recipe)
    self.placer.components.placer.testfn = function(pt)
        return self.inst.replica.builder ~= nil and
            self.inst.replica.builder:CanBuildAtPoint(pt, recipe)
    end
end

local function ValidateAttackTarget(combat, target, force_attack, x, z, has_weapon, reach)
    if not combat:CanTarget(target) or
        (target.replica.combat ~= nil --no combat if light/extinguish target
        and (combat:IsAlly(target) or
            not (force_attack or
                target:HasTag("hostile") or
                (has_weapon and target:HasTag("monster") and not target:HasTag("player")) or
                combat:IsRecentTarget(target) or
                target.replica.combat:GetTarget() == combat.inst))) then
        return false
    end
    --Now we ensure the target is in range
    --light/extinguish targets may not have physics
    reach = target.Physics ~= nil and reach + target.Physics:GetRadius() or reach
    return target:GetDistanceSqToPoint(x, 0, z) <= reach * reach
end

function PlayerController:GetAttackTarget(force_attack, force_target, isretarget)
    if self.inst:HasTag("playerghost") then
        return
    end

    local combat = self.inst.replica.combat
    if combat == nil then
        return
    end

    --Don't want to spam the attack button before the server actually starts the buffered action
    if not self.ismastersim and (self.remote_controls[CONTROL_ATTACK] or 0) > 0 then
        return
    end

    if self.inst.sg ~= nil then
        if self.inst.sg:HasStateTag("attack") then
            return
        end
    elseif self.inst:HasTag("attack") then
        return
    end

    if isretarget and
        combat:CanHitTarget(force_target) and
        force_target.replica.health ~= nil and
        not force_target.replica.health:IsDead() and
        CanEntitySeeTarget(self.inst, force_target) then
        return force_target
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local rad = combat:GetAttackRangeWithWeapon()
    if not self.directwalking then
        --for autowalking
        rad = rad + 6
    end

    --Beaver teeth counts as having a weapon
    local has_weapon = self.inst:HasTag("beaver")
    if not has_weapon then
        local inventory = self.inst.replica.inventory
        local tool = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
        if tool ~= nil then
            local inventoryitem = tool.replica.inventoryitem
            has_weapon = inventoryitem ~= nil and inventoryitem:IsWeapon()
        end
    end

    local reach = self.inst.Physics:GetRadius() + rad + 0.1

    if force_target ~= nil then
        return ValidateAttackTarget(combat, force_target, force_attack, x, z, has_weapon, reach) and force_target or nil
    end

    --To deal with entity collision boxes we need to pad the radius.
    --Only include combat targets for auto-targetting, not light/extinguish
    --See entityreplica.lua (re: "_combat" tag)
    local nearby_ents = TheSim:FindEntities(x, y, z, rad + 5, { "_combat" })
    for i, v in ipairs(nearby_ents) do
        if ValidateAttackTarget(combat, v, force_attack, x, z, has_weapon, reach) and
            CanEntitySeeTarget(self.inst, v) then
            return v
        end
    end
end

function PlayerController:DoAttackButton(retarget)
    local force_attack = TheInput:IsControlPressed(CONTROL_FORCE_ATTACK)
    local target = self:GetAttackTarget(force_attack, retarget, retarget ~= nil)

    if target == nil then
        --Still need to let the server know our attack button is down
        if not self.ismastersim and
            self.locomotor == nil and
            self.remote_controls[CONTROL_ATTACK] == nil then
            self:RemoteAttackButton()
        end
        return --no target
    end

    if self.ismastersim then
        self.locomotor:PushAction(BufferedAction(self.inst, target, ACTIONS.ATTACK), true)
    elseif self.locomotor == nil then
        self:RemoteAttackButton(target, force_attack)
    elseif self:CanLocomote() then
        local buffaction = BufferedAction(self.inst, target, ACTIONS.ATTACK)
        buffaction.preview_cb = function()
            self:RemoteAttackButton(target, force_attack)
        end
        self.locomotor:PreviewAction(buffaction, true)
    end
end

function PlayerController:OnRemoteAttackButton(target, force_attack, noforce)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        --Check if target is valid, otherwise make
        --it nil so that we still attack and miss.
        if target ~= nil and not noforce then
            if self.inst.sg:HasStateTag("attack") then
                self.inst.sg.statemem.chainattack_cb = function()
                    self:OnRemoteAttackButton(target, force_attack)
                end
            else
                target = self:GetAttackTarget(force_attack, target, target == self.inst.sg.statemem.attacktarget)
                self.attack_buffer = BufferedAction(self.inst, target, ACTIONS.ATTACK, nil, nil, nil, nil, true)
                self.attack_buffer._predictpos = true
            end
        else
            self.remote_controls[CONTROL_ATTACK] = 0
            target = target ~= nil and self:GetAttackTarget(force_attack, target) or nil
            if target ~= nil then
                self.attack_buffer = BufferedAction(self.inst, target, ACTIONS.ATTACK)
            end
        end
    end
end

function PlayerController:RemoteAttackButton(target, force_attack)
    if self.locomotor ~= nil then
        SendRPCToServer(RPC.AttackButton, target, force_attack)
    elseif target ~= nil then
        self.remote_controls[CONTROL_ATTACK] = BUTTON_REPEAT_COOLDOWN
        SendRPCToServer(RPC.AttackButton, target, force_attack, true)
    else
        self.remote_controls[CONTROL_ATTACK] = 0
        SendRPCToServer(RPC.AttackButton)
    end
end

local function ValidateHaunt(target)
    return target:HasActionComponent("hauntable")
end

local function ValidateBugNet(target)
    return not target.replica.health:IsDead()
end

local function GetPickupAction(target, tool)
    if target:HasTag("smolder") then
        return ACTIONS.SMOTHER
    elseif tool ~= nil then
        for k, v in pairs(TOOLACTIONS) do
            if target:HasTag(k.."_workable") then
                if tool:HasTag(k.."_tool") then
                    return ACTIONS[k]
                end
                break
            end
        end
    end
    if target:HasTag("trapsprung") then
        return ACTIONS.CHECKTRAP
    elseif target:HasTag("inactive") then
        return ACTIONS.ACTIVATE
    elseif target.replica.inventoryitem ~= nil and
        target.replica.inventoryitem:CanBePickedUp() and
        not (target:HasTag("catchable") or target:HasTag("fire")) then
        return ACTIONS.PICKUP 
    elseif target:HasTag("pickable") and not target:HasTag("fire") then
        return ACTIONS.PICK 
    elseif target:HasTag("harvestable") then
        return ACTIONS.HARVEST
    elseif target:HasTag("readyforharvest") or
        (target:HasTag("notreadyforharvest") and target:HasTag("withered")) then
        return ACTIONS.HARVEST
    elseif target:HasTag("dried") and not target:HasTag("burnt") then
        return ACTIONS.HARVEST
    elseif target:HasTag("donecooking") and not target:HasTag("burnt") then
        return ACTIONS.HARVEST
    end
    --no action found
end

function PlayerController:IsDoingOrWorking()
    if self.inst.sg == nil then
        return self.inst:HasTag("doing")
            or self.inst:HasTag("working")
    elseif not self.ismastersim and self.inst:HasTag("autopredict") then
        return self.inst.sg:HasStateTag("doing")
            or self.inst.sg:HasStateTag("working")
    end
    return self.inst.sg:HasStateTag("doing")
        or self.inst.sg:HasStateTag("working")
        or self.inst:HasTag("doing")
        or self.inst:HasTag("working")
end

local TARGET_EXCLUDE_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO" }
local PICKUP_TARGET_EXCLUDE_TAGS = { "catchable" }
local HAUNT_TARGET_EXCLUDE_TAGS = { "haunted", "catchable" }
for i, v in ipairs(TARGET_EXCLUDE_TAGS) do
    table.insert(PICKUP_TARGET_EXCLUDE_TAGS, v)
    table.insert(HAUNT_TARGET_EXCLUDE_TAGS, v)
end

function PlayerController:GetActionButtonAction(force_target)
    --Don't want to spam the action button before the server actually starts the buffered action
    --Also check if playercontroller is enabled
    --Also check if force_target is still valid
    if (not self.ismastersim and (self.remote_controls[CONTROL_ACTION] or 0) > 0) or
        not self:IsEnabled() or
        (force_target ~= nil and (not force_target.entity:IsVisible() or force_target:HasTag("INLIMBO") or force_target:HasTag("NOCLICK"))) then
        --"DECOR" should never change, should be safe to skip that check
        return

    elseif self.actionbuttonoverride ~= nil then
        local buffaction, usedefault = self.actionbuttonoverride(self.inst, force_target)
        if not usedefault or buffaction ~= nil then
            return buffaction
        end

    elseif not self:IsDoingOrWorking() then
        local force_target_distsq = force_target ~= nil and self.inst:GetDistanceSqToInst(force_target) or nil

        if self.inst:HasTag("playerghost") then
            --haunt
            if force_target == nil then
                local target = FindEntity(self.inst, self.directwalking and 3 or 6, ValidateHaunt, nil, HAUNT_TARGET_EXCLUDE_TAGS)
                if CanEntitySeeTarget(self.inst, target) then
                    return BufferedAction(self.inst, target, ACTIONS.HAUNT)
                end
            elseif force_target_distsq <= (self.directwalking and 9 or 36) and
                not (force_target:HasTag("haunted") or force_target:HasTag("catchable")) and
                ValidateHaunt(force_target) then
                return BufferedAction(self.inst, force_target, ACTIONS.HAUNT)
            end
            return
        end

        local tool = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        --bug catching (has to go before combat)
        if tool ~= nil and tool:HasTag(ACTIONS.NET.id.."_tool") then
            if force_target == nil then
                local target = FindEntity(self.inst, 5, ValidateBugNet, { "_health", ACTIONS.NET.id.."_workable" }, TARGET_EXCLUDE_TAGS)
                if CanEntitySeeTarget(self.inst, target) then
                    return BufferedAction(self.inst, target, ACTIONS.NET, tool)
                end
            elseif force_target_distsq <= 25 and
                force_target.replica.health ~= nil and
                ValidateBugNet(force_target) and
                force_target:HasTag(ACTIONS.NET.id.."_workable") then
                return BufferedAction(self.inst, force_target, ACTIONS.NET, tool)
            end
        end

        --catching
        if self.inst:HasTag("cancatch") then
            if force_target == nil then
                local target = FindEntity(self.inst, 10, nil, { "catchable" }, TARGET_EXCLUDE_TAGS)
                if CanEntitySeeTarget(self.inst, target) then
                    return BufferedAction(self.inst, target, ACTIONS.CATCH)
                end
            elseif force_target_distsq <= 100 and
                force_target:HasTag("catchable") then
                return BufferedAction(self.inst, force_target, ACTIONS.CATCH)
            end
        end

        --unstick
        if force_target == nil then
            local target = FindEntity(self.inst, self.directwalking and 3 or 6, nil, { "pinned" }, TARGET_EXCLUDE_TAGS)
            if CanEntitySeeTarget(self.inst, target) then
                return BufferedAction(self.inst, target, ACTIONS.UNPIN)
            end
        elseif force_target_distsq <= (self.directwalking and 9 or 36) and
            force_target:HasTag("pinned") then
            return BufferedAction(self.inst, force_target, ACTIONS.UNPIN)
        end

        --misc: pickup, tool work, smother
        if force_target == nil then
            local pickup_tags =
            {
                "_inventoryitem",
                "pickable",
                "donecooking",
                "readyforharvest",
                "notreadyforharvest",
                "harvestable",
                "trapsprung",
                "dried",
                "inactive",
                "smolder",
            }
            if tool ~= nil then
                for k, v in pairs(TOOLACTIONS) do
                    if tool:HasTag(k.."_tool") then
                        table.insert(pickup_tags, k.."_workable")
                    end
                end
            end
            local x, y, z = self.inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, self.directwalking and 3 or 6, nil, PICKUP_TARGET_EXCLUDE_TAGS, pickup_tags)
            for i, v in ipairs(ents) do
                if v ~= self.inst and v.entity:IsVisible() and CanEntitySeeTarget(self.inst, v) then
                    local action = GetPickupAction(v, tool)
                    if action ~= nil then
                        return BufferedAction(self.inst, v, action, action ~= ACTIONS.SMOTHER and tool or nil)
                    end
                end
            end
        elseif force_target_distsq <= (self.directwalking and 9 or 36) then
            local action = GetPickupAction(force_target, tool)
            if action ~= nil then
                return BufferedAction(self.inst, force_target, action, action ~= ACTIONS.SMOTHER and tool or nil)
            end
        end
    end
end

function PlayerController:DoActionButton()
    if self.placer == nil then
        local buffaction = self:GetActionButtonAction()
        if buffaction ~= nil then
            if self.ismastersim then
                self.locomotor:PushAction(buffaction, true)
                return
            elseif self.locomotor == nil then
                self:RemoteActionButton(buffaction)
                return
            elseif self:CanLocomote() then
                if buffaction.action ~= ACTIONS.WALKTO then
                    buffaction.preview_cb = function()
                        self:RemoteActionButton(buffaction, not TheInput:IsControlPressed(CONTROL_ACTION) or nil)
                    end
                end
                self.locomotor:PreviewAction(buffaction, true)
            end
        end
    elseif self.placer.components.placer.can_build and
        self.inst.replica.builder ~= nil and
        not self.inst.replica.builder:IsBusy() then
        --do the placement
        self.inst.replica.builder:MakeRecipeAtPoint(self.placer_recipe, self.placer:GetPosition(), self.placer:GetRotation(), self.placer_recipe_skin)
    end

    --Still need to let the server know our action button is down
    if not self.ismastersim and self.remote_controls[CONTROL_ACTION] == nil then
        self:RemoteActionButton()
    end
end

function PlayerController:OnRemoteActionButton(actioncode, target, isreleased, noforce, mod_name)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.remote_controls[CONTROL_ACTION] = 0
        if actioncode ~= nil then
            local buffaction = self:GetActionButtonAction(target)
            if buffaction ~= nil and buffaction.action.code == actioncode and buffaction.action.mod_name == mod_name then
                if buffaction.action.canforce and not noforce then
                    buffaction.pos = self:GetRemotePredictPosition() or self.inst:GetPosition()
                    buffaction.forced = true
                end
                self.locomotor:PushAction(buffaction, true)
           --else
				--if mod_name ~= nil then
					--print("Remote action button action failed: "..tostring(ACTION_MOD_IDS[mod_name][actioncode]))
                --else
					--print("Remote action button action failed: "..tostring(ACTION_IDS[actioncode]))
				--end
            end
        end
        if isreleased then
            self.remote_controls[CONTROL_ACTION] = nil
        end
    end
end

function PlayerController:RemoteActionButton(action, isreleased)
    local actioncode = action ~= nil and action.action.code or nil
    local action_mod_name = action ~= nil and action.action.mod_name or nil
    local target = action ~= nil and action.target or nil
    local noforce = self.locomotor == nil and action ~= nil and action.action.canforce or nil
    self.remote_controls[CONTROL_ACTION] = action ~= nil and BUTTON_REPEAT_COOLDOWN or 0
    SendRPCToServer(RPC.ActionButton, actioncode, target, isreleased, noforce, action_mod_name)
end

function PlayerController:GetInspectButtonAction(target)
    return target ~= nil and
        target:HasTag("inspectable") and
        (self.inst.CanExamine == nil or self.inst:CanExamine()) and
        (self.inst.sg == nil or self.inst.sg:HasStateTag("moving") or self.inst.sg:HasStateTag("idle")) and
        (self.inst:HasTag("moving") or self.inst:HasTag("idle")) and
        BufferedAction(self.inst, target, ACTIONS.LOOKAT) or
        nil
end

function PlayerController:DoInspectButton()
    if not self:IsEnabled() then
        return
    end
    local buffaction = TheInput:ControllerAttached() and (self:GetInspectButtonAction(self:GetControllerTarget() or TheInput:GetWorldEntityUnderMouse())) or nil
    if buffaction == nil then
        return
    elseif self.ismastersim then
        self.locomotor:PushAction(buffaction, true)
    elseif self.locomotor == nil then
        self:RemoteInspectButton(buffaction)
    elseif self:CanLocomote() then
        buffaction.preview_cb = function()
            self:RemoteInspectButton(buffaction)
        end
        self.locomotor:PreviewAction(buffaction, true)
    end
end

function PlayerController:OnRemoteInspectButton(target)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        local buffaction = self:GetInspectButtonAction(target)
        if buffaction ~= nil then
            self.locomotor:PushAction(buffaction, true)
        --else
            --print("Remote inspect button action failed")
        end
    end
end

function PlayerController:RemoteInspectButton(action)
    SendRPCToServer(RPC.InspectButton, action.target)
end

function PlayerController:GetResurrectButtonAction()
    return self.inst:HasTag("playerghost") and
        (self.inst.sg == nil or self.inst.sg:HasStateTag("moving") or self.inst.sg:HasStateTag("idle")) and
        (self.inst:HasTag("moving") or self.inst:HasTag("idle")) and
        self.inst.components.attuner:HasAttunement("remoteresurrector") and
        BufferedAction(self.inst, nil, ACTIONS.REMOTERESURRECT) or
        nil
end

function PlayerController:DoResurrectButton()
    if not self:IsEnabled() then
        return
    end
    local buffaction = self:GetResurrectButtonAction()
    if buffaction == nil then
        return
    elseif self.ismastersim then
        self.locomotor:PushAction(buffaction, true)
    elseif self.locomotor == nil then
        self:RemoteResurrectButton(buffaction)
    elseif self:CanLocomote() then
        buffaction.preview_cb = function()
            self:RemoteResurrectButton(buffaction)
        end
        self.locomotor:PreviewAction(buffaction, true)
    end
end

function PlayerController:OnRemoteResurrectButton()
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        local buffaction = self:GetResurrectButtonAction()
        if buffaction ~= nil then
            self.locomotor:PushAction(buffaction, true)
        --else
            --print("Remote resurrect button action failed")
        end
    end
end

function PlayerController:RemoteResurrectButton()
    SendRPCToServer(RPC.ResurrectButton)
end

function PlayerController:UsingMouse()
    return not TheInput:ControllerAttached()
end

function PlayerController:OnUpdate(dt)
    self.predictionsent = false

    if self.draggingonground and not (self:IsEnabled() and TheInput:IsControlPressed(CONTROL_PRIMARY)) then
        if self.locomotor ~= nil then
            self.locomotor:Stop()
        end
        self.draggingonground = false
        self.startdragtime = nil
        TheFrontEnd:LockFocus(false)
    end

    --ishudblocking set to true lets us know that the only reason
    --for isenabled returning false is due to HUD blocking input.
    local isenabled, ishudblocking = self:IsEnabled()
    if not isenabled then
        if self.directwalking or self.dragwalking or self.predictwalking then
            if self.locomotor ~= nil then
                self.locomotor:Stop()
                self.locomotor:Clear()
            end
            self.directwalking = false
            self.dragwalking = false
            self.predictwalking = false
            if not self.ismastersim then
                self:RemoteStopWalking()
            end
        elseif not ishudblocking and self.locomotor ~= nil and self.locomotor.bufferedaction ~= nil then
            self.locomotor:Stop()
            self.locomotor:Clear()
        end

        if self.handler ~= nil then
            if self.placer ~= nil then
                self.placer:Remove()
                self.placer = nil
            end

            self:CancelDeployPlacement()

            if self.reticule ~= nil and self.reticule.reticule ~= nil then
                self.reticule.reticule:Hide()
            end

            if self.terraformer ~= nil then
                self.terraformer:Remove()
                self.terraformer = nil
            end

            self.LMBaction, self.RMBaction = nil, nil
            self.controller_target = nil
            self.controller_attack_target = nil
            self.controller_attack_target_ally_cd = nil
            if self.highlight_guy ~= nil and self.highlight_guy:IsValid() and self.highlight_guy.components.highlight ~= nil then
                self.highlight_guy.components.highlight:UnHighlight()
            end
            self.highlight_guy = nil

            if not ishudblocking and self.inst.HUD ~= nil and self.inst.HUD:IsVisible() and not self.inst.HUD:HasInputFocus() then
                self:DoCameraControl()
            end
        end

        if self.ismastersim then
            self:ResetRemoteController()
        else
            self:RemoteStopAllControls()

            --Other than HUD blocking, we would've been enabled otherwise
            if ishudblocking and not self:IsBusy() then
                self:DoPredictWalking(dt)
            end
        end

        self.attack_buffer = nil
        self.controller_attack_override = nil
        return
    end

    --Attack controls are buffered and handled here in the update
    if self.attack_buffer ~= nil then
        if self.attack_buffer == CONTROL_ATTACK then
            self:DoAttackButton()
        elseif self.attack_buffer == CONTROL_CONTROLLER_ATTACK then
            self:DoControllerAttackButton()
        else
            if self.attack_buffer._predictpos then
                self.attack_buffer.pos = self:GetRemotePredictPosition() or self.inst:GetPosition()
            end
            if self.attack_buffer._controller then
                if self.attack_buffer.target == nil then
                    self.controller_attack_override = self:IsControlPressed(CONTROL_CONTROLLER_ATTACK) and self.attack_buffer or nil
                end
                self:DoAction(self.attack_buffer)
            else
                self.locomotor:PushAction(self.attack_buffer, true)
            end
        end
        self.attack_buffer = nil
    end

    if self.handler ~= nil then
        local controller_mode = TheInput:ControllerAttached()
        local new_highlight = nil
        if not self.inst:IsActionsVisible() then
            --Don't highlight when actions are hidden
        elseif controller_mode then
            self.LMBaction, self.RMBaction = nil, nil
            self:UpdateControllerTargets(dt)
            new_highlight = self.controller_target
        else
            self.controller_target = nil
            self.controller_attack_target = nil
            self.controller_attack_target_ally_cd = nil
            self.LMBaction, self.RMBaction = self.inst.components.playeractionpicker:DoGetMouseActions()
            --If an action has a target, highlight the target.
            --If an action has no target and no pos, then it should
            --be an inventory action where doer is ourself and we are
            --targeting ourself, so highlight ourself
            new_highlight =
                (self.LMBaction ~= nil
                and (self.LMBaction.target
                    or (self.LMBaction.pos == nil and
                        self.LMBaction.doer == self.inst and
                        self.inst))) or
                (self.RMBaction ~= nil
                and (self.RMBaction.target
                    or (self.RMBaction.pos == nil and
                        self.RMBaction.doer == self.inst and
                        self.inst))) or
                nil
        end

        if new_highlight ~= self.highlight_guy then
            if self.highlight_guy ~= nil and self.highlight_guy:IsValid() and self.highlight_guy.components.highlight ~= nil then
                self.highlight_guy.components.highlight:UnHighlight()
            end
            self.highlight_guy = new_highlight
        end

        if self.highlight_guy ~= nil and self.highlight_guy:IsValid() then
            if self.highlight_guy.components.highlight == nil then
                self.highlight_guy:AddComponent("highlight")
            end

            if self.highlight_guy.highlight_override ~= nil then
                self.highlight_guy.components.highlight:Highlight(unpack(self.highlight_guy.highlight_override))
            else
                self.highlight_guy.components.highlight:Highlight()
            end
        else
            self.highlight_guy = nil
        end

        self:DoCameraControl()

        if not controller_mode and self.reticule ~= nil then         
            self.reticule:DestroyReticule()
            self.reticule = nil
        end

        if self.placer ~= nil and self.placer_recipe ~= nil and
            not (self.inst.replica.builder ~= nil and self.inst.replica.builder:IsBuildBuffered(self.placer_recipe.name)) then
            self:CancelPlacement()
        end

        local placer_item = controller_mode and self:GetCursorInventoryObject() or self.inst.replica.inventory:GetActiveItem()
        --show deploy placer
        if self.deploy_mode and
            self.placer == nil and
            placer_item ~= nil and
            placer_item.replica.inventoryitem ~= nil and
            placer_item.replica.inventoryitem:IsDeployable() then
            local placer_name = placer_item.replica.inventoryitem:GetDeployPlacerName()
            if self.deployplacer ~= nil and self.deployplacer.prefab ~= placer_name then
                self:CancelDeployPlacement()
            end

            if self.deployplacer == nil then
                self.deployplacer = SpawnPrefab(placer_name)
                if self.deployplacer ~= nil then
                    self.deployplacer.components.placer:SetBuilder(self.inst, nil, placer_item)
                    self.deployplacer.components.placer.testfn = function(pt) 
                        return placer_item:IsValid() and
                            placer_item.replica.inventoryitem ~= nil and
                            placer_item.replica.inventoryitem:CanDeploy(pt, TheInput:GetWorldEntityUnderMouse())
                    end
                    self.deployplacer.components.placer:OnUpdate(0) --so that our position is accurate on the first frame
                end
            end
        else
            self:CancelDeployPlacement()
        end

        local terraform = false
        if controller_mode then
            local lmb, rmb = self:GetGroundUseAction()
            terraform = rmb ~= nil and rmb.action == ACTIONS.TERRAFORM
        else
            local rmb = self:GetRightMouseAction() 
            terraform = rmb ~= nil and rmb.action == ACTIONS.TERRAFORM
        end

        --show right action reticule
        if self.placer == nil and self.deployplacer == nil then
            if terraform then
                if self.terraformer == nil then
                    self.terraformer = SpawnPrefab("gridplacer")
                    if self.terraformer ~= nil then
                        self.terraformer.components.placer:SetBuilder(self.inst)
                        self.terraformer.components.placer:OnUpdate(0)
                    end
                end
            elseif self.terraformer ~= nil then
                self.terraformer:Remove()
                self.terraformer = nil
            end

            if self.reticule ~= nil and self.reticule.reticule ~= nil then
                self.reticule.reticule:Show()
            end
        else
            if self.terraformer ~= nil then
                self.terraformer:Remove()
                self.terraformer = nil
            end

            if self.reticule ~= nil and self.reticule.reticule ~= nil then
                self.reticule.reticule:Hide()
            end
        end

        if not self.draggingonground and self.startdragtime ~= nil and TheInput:IsControlPressed(CONTROL_PRIMARY) then
            local now = GetTime()
            if now - self.startdragtime > START_DRAG_TIME then
                TheFrontEnd:LockFocus(true)
                self.draggingonground = true
            end
        end

        if self.draggingonground and TheFrontEnd:GetFocusWidget() ~= self.inst.HUD then
            self.draggingonground = false
            self.startdragtime = nil
            TheFrontEnd:LockFocus(false)

            if self:CanLocomote() then
                self.locomotor:Stop()
            end
        end
    elseif self.ismastersim and self.inst:HasTag("nopredict") and self.remote_vector.y >= 3 then
        self.remote_vector.y = 0
    end

    if self.controller_attack_override ~= nil and
        not (self.locomotor.bufferedaction == self.controller_attack_override and
            self:IsControlPressed(CONTROL_CONTROLLER_ATTACK)) then
        self.controller_attack_override = nil
    end
    --NOTE: isbusy is used further below as well
    local isbusy = self:IsBusy()
    if not isbusy then
        if not self:DoPredictWalking(dt) then
            if not self:DoDragWalking(dt) then
                self:DoDirectWalking(dt)
            end
        end
    end

    --do automagic control repeats
    if self.handler ~= nil then
        local isidle = self.inst:HasTag("idle")

        if not self.ismastersim then
            --clear cooldowns if we actually did something on the server
            --otherwise just decrease
            --if the server is still "idle", then it hasn't begun processing the action yet
            --when using movement prediction, the RPC is sent AFTER reaching the destination,
            --so we must also check that the server is not still "moving"
            self:CooldownRemoteController((isidle or (self.inst.sg ~= nil and self.inst:HasTag("moving"))) and dt or nil)
        end

        if self.inst.sg ~= nil then
            isidle = self.inst.sg:HasStateTag("idle") or (isidle and self.inst:HasTag("nopredict"))
        end
        if isidle then
            if TheInput:IsControlPressed(CONTROL_ACTION) then
                self:OnControl(CONTROL_ACTION, true)
            elseif TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION)
                and not self:IsDoingOrWorking() then
                self:OnControl(CONTROL_CONTROLLER_ACTION, true)
            end
        end
    end
    if self.ismastersim and self.handler == nil and not self.inst.sg.mem.localchainattack then
        if self.inst.sg.statemem.chainattack_cb ~= nil and not self.inst.sg:HasStateTag("attack") then
            --Handles chain attack commands received at irregular intervals
            local fn = self.inst.sg.statemem.chainattack_cb
            self.inst.sg.statemem.chainattack_cb = nil
            fn()
        end
    elseif (self.ismastersim or self.handler ~= nil) and not (self.directwalking or isbusy) then
        local attack_control = false
        if self.inst.sg ~= nil then
            attack_control = not self.inst.sg:HasStateTag("attack")
        else
            attack_control = not self.inst:HasTag("attack")
        end
        if attack_control then
            attack_control = (self.handler == nil or not IsPaused())
                and ((self:IsControlPressed(CONTROL_ATTACK) and CONTROL_ATTACK) or
                    (self:IsControlPressed(CONTROL_PRIMARY) and CONTROL_PRIMARY) or
                    (self:IsControlPressed(CONTROL_CONTROLLER_ATTACK) and CONTROL_CONTROLLER_ATTACK))
                or nil
            if attack_control ~= nil then
                --Check for chain attacking first
                local retarget = nil
                if self.inst.sg ~= nil then
                    retarget = self.inst.sg.statemem.attacktarget
                elseif self.inst.replica.combat ~= nil then
                    retarget = self.inst.replica.combat:GetTarget()
                end
                if retarget ~= nil then
                    --Handle chain attacking
                    if self.inst.sg ~= nil then
                        if self.handler == nil then
                            retarget = self:GetAttackTarget(false, retarget, true)
                            if retarget ~= nil then
                                self.locomotor:PushAction(BufferedAction(self.inst, retarget, ACTIONS.ATTACK), true)
                            end
                        elseif attack_control ~= CONTROL_CONTROLLER_ATTACK then
                            self:DoAttackButton(retarget)
                        else
                            self:DoControllerAttackButton(retarget)
                        end
                    end
                elseif attack_control ~= CONTROL_PRIMARY and self.handler ~= nil then
                    --Check for starting a new attack
                    local isidle
                    if self.inst.sg ~= nil then
                        isidle = self.inst.sg:HasStateTag("idle") or (self.inst:HasTag("idle") and self.inst:HasTag("nopredict"))
                    else
                        isidle = self.inst:HasTag("idle")
                    end
                    if isidle then
                        self:OnControl(attack_control, true)
                    end
                end
            end
        end
    end
end

local function UpdateControllerAttackTarget(self, dt, x, y, z, dirx, dirz)
    if self.inst:HasTag("playerghost") then
        self.controller_attack_target = nil
        self.controller_attack_target_ally_cd = nil
        return
    end

    local combat = self.inst.replica.combat

    self.controller_attack_target_ally_cd = math.max(0, (self.controller_attack_target_ally_cd or 1) - dt)

    if self.controller_attack_target ~= nil and
        not (combat:CanTarget(self.controller_attack_target) and
            CanEntitySeeTarget(self.inst, self.controller_attack_target)) then
        self.controller_attack_target = nil
        --it went invalid, but we're not resetting the age yet
    end

    --self.controller_attack_target_age = self.controller_attack_target_age + dt
    --if self.controller_attack_target_age < .3 then
        --prevent target flickering
    --    return
    --end

    local min_rad = 4
    local max_rad = math.max(min_rad, combat:GetAttackRangeWithWeapon()) + 3
    local min_rad_sq = min_rad * min_rad
    local max_rad_sq = max_rad * max_rad

    --see entity_replica.lua for "_combat" tag
    local nearby_ents = TheSim:FindEntities(x, y, z, max_rad, { "_combat" }, TARGET_EXCLUDE_TAGS)
    if self.controller_attack_target ~= nil then
        --Note: it may already contain controller_attack_target,
        --      so make sure to handle it only once later
        table.insert(nearby_ents, 1, self.controller_attack_target)
    end

    local target = nil
    local target_score = 0
    local target_isally = true
    local preferred_target =
        TheInput:IsControlPressed(CONTROL_CONTROLLER_ATTACK) and
        self.controller_attack_target or
        combat:GetTarget() or
        nil

    for i, v in ipairs(nearby_ents) do
        if v ~= self.inst and (v ~= self.controller_attack_target or i == 1) then
            local isally = combat:IsAlly(v)
            if not (isally and
                    self.controller_attack_target_ally_cd > 0 and
                    v ~= preferred_target) and
                combat:CanTarget(v) then
                --Check distance including y value
                local x1, y1, z1 = v.Transform:GetWorldPosition()
                local dx, dy, dz = x1 - x, y1 - y, z1 - z
                local dsq = dx * dx + dy * dy + dz * dz

                if dsq < max_rad_sq and CanEntitySeePoint(self.inst, x1, y1, z1) then
                    local dist = dsq > 0 and math.sqrt(dsq) or 0
                    local dot = dist > 0 and dx / dist * dirx + dz / dist * dirz or 0
                    if dot > 0 or dist < min_rad then
                        local score = dot + 1 - .5 * dsq / max_rad_sq

                        if isally then
                            score = score * .25
                        elseif v:HasTag("monster") then
                            score = score * 4
                        end

                        if v.replica.combat:GetTarget() == self.inst then
                            score = score * 6
                        end

                        if v == preferred_target then
                            score = score * 10
                        end

                        if score > target_score then
                            target = v
                            target_score = score
                            target_isally = isally
                        end
                    end
                end
            end
        end
    end

    if target == nil and
        self.controller_target ~= nil and
        self.controller_target:IsValid() and
        self.controller_target:HasTag("wall") and
        self.controller_target.replica.health ~= nil and
        not self.controller_target.replica.health:IsDead() then
        target = self.controller_target
        target_isally = false
    end

    if target ~= self.controller_attack_target then
        self.controller_attack_target = target
        --self.controller_attack_target_age = 0
    end

    if not target_isally then
        --reset ally targeting cooldown
        self.controller_attack_target_ally_cd = nil
    end
end

local function UpdateControllerInteractionTarget(self, dt, x, y, z, dirx, dirz)
    if self.placer ~= nil or (self.deployplacer ~= nil and self.deploy_mode) then
        self.controller_target = nil
        self.controller_target_age = 0
        return
    elseif self.controller_target ~= nil
        and (not self.controller_target:IsValid() or
            self.controller_target:HasTag("INLIMBO") or
            self.controller_target:HasTag("NOCLICK") or
            not CanEntitySeeTarget(self.inst, self.controller_target)) then
        --"FX" and "DECOR" tag should never change, should be safe to skip that check
        self.controller_target = nil
        --it went invalid, but we're not resetting the age yet
    end

    self.controller_target_age = self.controller_target_age + dt
    if self.controller_target_age < .2 then
        --prevent target flickering
        return
    end

    --catching
    if self.inst:HasTag("cancatch") then
        local target = FindEntity(self.inst, 10, nil, { "catchable" }, TARGET_EXCLUDE_TAGS)
        if CanEntitySeeTarget(self.inst, target) then
            if target ~= self.controller_target then
                self.controller_target = target
                self.controller_target_age = 0
            end
            return 
        end
    end

    local min_rad = 1.5
    local max_rad = 6
    local min_rad_sq = min_rad * min_rad
    local max_rad_sq = max_rad * max_rad
    local rad =
            self.controller_target ~= nil and
            math.max(min_rad, math.min(max_rad, math.sqrt(self.inst:GetDistanceSqToInst(self.controller_target)))) or
            max_rad

    local nearby_ents = TheSim:FindEntities(x, y, z, rad, nil, TARGET_EXCLUDE_TAGS)
    if self.controller_target ~= nil then
        --Note: it may already contain controller_target,
        --      so make sure to handle it only once later
        table.insert(nearby_ents, 1, self.controller_target)
    end

    local target = nil
    local target_score = 0
    local canexamine = self.inst.CanExamine == nil or self.inst:CanExamine()

    for i, v in ipairs(nearby_ents) do
        --Only handle controller_target if it's the one we added at the front
        if v ~= self.inst and (v ~= self.controller_target or i == 1) then
            --Check distance including y value
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx, dy, dz = x1 - x, y1 - y, z1 - z
            local dsq = dx * dx + dy * dy + dz * dz

            if (dsq < min_rad_sq
                or (dsq <= max_rad_sq
                    and (v == self.controller_target or
                        v == self.controller_attack_target or
                        dx * dirx + dz * dirz > 0))) and
                CanEntitySeePoint(self.inst, x1, y1, z1) then

                local dist = dsq > 0 and math.sqrt(dsq) or 0
                local dot = dist > 0 and dx / dist * dirx + dz / dist * dirz or 0

                --keep the angle component between [0..1]
                local angle_component = (dot + 1) / 2

                --distance doesn't matter when you're really close, and then attenuates down from 1 as you get farther away
                local dist_component = dsq < min_rad_sq and 1 or min_rad_sq / dsq

                --for stuff that's *really* close - ie, just dropped
                local add = dsq < .0625 --[[.25 * .25]] and 1 or 0

                --just a little hysteresis
                local mult = v == self.controller_target and not v:HasTag("wall") and 1.5 or 1
                
                local score = angle_component * dist_component * mult + add

                --print(v, angle_component, dist_component, mult, add, score)

                if score <= target_score then
                    --skip
                elseif canexamine and v:HasTag("inspectable") then
                    target = v
                    target_score = score
                else
                    --this is kind of expensive, so ideally we don't get here for many objects
                    local lmb, rmb = self:GetSceneItemControllerAction(v)
                    if lmb ~= nil or rmb ~= nil then
                        target = v
                        target_score = score
                    else
                        local inv_obj = self:GetCursorInventoryObject()
                        if inv_obj ~= nil and self:GetItemUseAction(inv_obj, v) ~= nil then
                            target = v
                            target_score = score
                        end
                    end
                end
            end
        end
    end

    if target ~= self.controller_target then
        self.controller_target = target
        self.controller_target_age = 0
    end
end

function PlayerController:UpdateControllerTargets(dt)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local heading_angle = -self.inst.Transform:GetRotation()
    local dirx = math.cos(heading_angle * DEGREES)
    local dirz = math.sin(heading_angle * DEGREES)
    UpdateControllerInteractionTarget(self, dt, x, y, z, dirx, dirz)
    UpdateControllerAttackTarget(self, dt, x, y, z, dirx, dirz)
end

function PlayerController:GetControllerTarget()
    return self.controller_target ~= nil and self.controller_target:IsValid() and self.controller_target or nil
end

function PlayerController:GetControllerAttackTarget()
    return self.controller_attack_target ~= nil and self.controller_attack_target:IsValid() and self.controller_attack_target or nil
end

--------------------------------------------------------------------------
--remote_vector.y is used as a flag for stop/direct/drag walking
--since its value is never actually used in the walking function

function PlayerController:ResetRemoteController()
    self.remote_vector.y = 0
    if next(self.remote_controls) ~= nil then
        self.remote_controls = {}
    end
end

function PlayerController:GetRemoteDirectVector()
    return self.remote_vector.y == 1 and self.remote_vector or nil
end

function PlayerController:GetRemoteDragPosition()
    return self.remote_vector.y == 2 and self.remote_vector or nil
end

function PlayerController:GetRemotePredictPosition()
    return self.remote_vector.y >= 3 and self.remote_vector or nil
end

function PlayerController:OnRemoteDirectWalking(x, z)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.remote_vector.x = x
        self.remote_vector.y = 1
        self.remote_vector.z = z
    end
end

function PlayerController:OnRemoteDragWalking(x, z)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.remote_vector.x = x
        self.remote_vector.y = 2
        self.remote_vector.z = z
    end
end

function PlayerController:OnRemotePredictWalking(x, z, isdirectwalking)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.remote_vector.x = x
        self.remote_vector.y = isdirectwalking and 3 or 4
        self.remote_vector.z = z
    end
end

function PlayerController:OnRemoteStopWalking()
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.remote_vector.y = 0
    end
end

function PlayerController:RemoteDirectWalking(x, z)
    if self.remote_vector.x ~= x or self.remote_vector.z ~= z or self.remote_vector.y ~= 1 then
        SendRPCToServer(RPC.DirectWalking, x, z)
        self.remote_vector.x = x
        self.remote_vector.y = 1
        self.remote_vector.z = z
    end
end

function PlayerController:RemoteDragWalking(x, z)
    if self.remote_vector.x ~= x or self.remote_vector.z ~= z or self.remote_vector.y ~= 2 then
        SendRPCToServer(RPC.DragWalking, x, z)
        self.remote_vector.x = x
        self.remote_vector.y = 2
        self.remote_vector.z = z
    end
end

function PlayerController:RemotePredictWalking(x, z)
    local y = self.directwalking and 3 or 4
    if self.remote_vector.x ~= x or self.remote_vector.z ~= z or (self.remote_vector.y ~= y and self.remote_vector.y ~= 0) then
        SendRPCToServer(RPC.PredictWalking, x, z, self.directwalking)
        self.remote_vector.x = x
        self.remote_vector.y = y
        self.remote_vector.z = z
        self.predictionsent = true
    end
end

function PlayerController:RemoteStopWalking()
    if self.remote_vector.y ~= 0 then
        SendRPCToServer(RPC.StopWalking)
        self.remote_vector.y = 0
    end
end

local function GetWorldControllerVector()
    local xdir = TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_MOVE_LEFT)
    local ydir = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP) - TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
    local deadzone = .3
    if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
        local dir = TheCamera:GetRightVec() * xdir - TheCamera:GetDownVec() * ydir
        return dir:GetNormalized()
    end
end

function PlayerController:DoPredictWalking(dt)
    if self.ismastersim then
        local pt = self:GetRemotePredictPosition()
        if pt ~= nil then
            local x0, y0, z0 = self.inst.Transform:GetWorldPosition()
            local distancetotargetsq = distsq(pt.x, pt.z, x0, z0)
            local stopdistancesq = .05

            if pt.y == 5 and
                (self.locomotor.bufferedaction ~= nil or
                self.inst.bufferedaction ~= nil or
                not (self.inst.sg:HasStateTag("idle") or
                    self.inst.sg:HasStateTag("moving"))) then
                --We're performing an action now, so ignore predict walking
                self.directwalking = false
                self.dragwalking = false
                self.predictwalking = false
                if distancetotargetsq <= stopdistancesq then
                    self.remote_vector.y = 0
                end
                return true
            end

            if pt.y < 5 then
                self.inst:ClearBufferedAction()
            end

            if distancetotargetsq > stopdistancesq then
                self.locomotor:RunInDirection(self.inst:GetAngleToPoint(pt))
            else
                --Destination reached, queued (instead of immediate) stop
                --so that prediction may be resumed before the next frame
                self.inst:FacePoint(pt)
                self.locomotor:Stop({ force_idle_state = true }) --force idle state in case this tiny motion was meant to cancel an action
            end

            --Even though we're predict walking, we want the server to behave
            --according to whether the client thinks he's direct/drag walking
            if pt.y == 3 then
                if self.directwalking then
                    self.time_direct_walking = self.time_direct_walking + dt
                else
                    self.time_direct_walking = dt
                    self.directwalking = true
                    self.dragwalking = false
                    self.predictwalking = false
                end

                if self.time_direct_walking > .2 and not self.inst.sg:HasStateTag("attack") then
                    self.inst.components.combat:SetTarget(nil)
                end
            elseif pt.y == 4 then
                self.directwalking = false
                self.dragwalking = true
                self.predictwalking = false
            else
                self.directwalking = false
                self.dragwalking = false
                self.predictwalking = true
            end

            --Detect stop, teleport, or prediction errors
            --Cancel the cached prediction vector and force resync if necessary
            if distancetotargetsq <= stopdistancesq then
                self.remote_vector.y = 0
            elseif distancetotargetsq > 16 then
                self.remote_vector.y = 0
                self.inst.Physics:Teleport(self.inst.Transform:GetWorldPosition())
            end

            return true
        end
    elseif self:CanLocomote() and self.inst.sg:HasStateTag("moving") then
        local x, y, z = self.inst.Transform:GetPredictionPosition()
        if x ~= nil and y ~= nil and z ~= nil then
            self:RemotePredictWalking(x, z)
        end
    end
end

function PlayerController:DoDragWalking(dt)
    local pt = nil
    if self.locomotor == nil or self:CanLocomote() then
        if self.handler == nil then
            pt = self:GetRemoteDragPosition()
        elseif self.draggingonground then
            pt = TheInput:GetWorldPosition()
        end
    end
    if pt ~= nil then
        local x0, y0, z0 = self.inst.Transform:GetWorldPosition()
        if distsq(pt.x, pt.z, x0, z0) > 1 then
            self.inst:ClearBufferedAction()
            if not self.ismastersim then
                self:CooldownRemoteController()
            end
            if self:CanLocomote() then
                self.locomotor:RunInDirection(self.inst:GetAngleToPoint(pt))
            end
        end
        self.directwalking = false
        self.dragwalking = true
        self.predictwalking = false
        if not self.ismastersim and self.locomotor == nil then
            self:RemoteDragWalking(pt.x, pt.z)
        end
        return true
    end
end

function PlayerController:DoDirectWalking(dt)
    local dir = nil
    if (self.locomotor == nil or self:CanLocomote()) and
        not (self.controller_attack_override ~= nil or
            (self.inst.sg ~= nil and
            self.inst.sg:HasStateTag("attack") and
            self:IsControlPressed(CONTROL_CONTROLLER_ATTACK))) then
        if self.handler == nil then
            dir = self:GetRemoteDirectVector()
        else
            dir = GetWorldControllerVector()
        end
    end
    if dir ~= nil then
        self.inst:ClearBufferedAction()

        if not self.ismastersim then
            self:CooldownRemoteController()
        end

        if self:CanLocomote() then
            self.locomotor:SetBufferedAction(nil)
            self.locomotor:RunInDirection(-math.atan2(dir.z, dir.x) / DEGREES)
        end

        if self.directwalking then
            self.time_direct_walking = self.time_direct_walking + dt
        else
            self.time_direct_walking = dt
            self.directwalking = true
            self.dragwalking = false
            self.predictwalking = false
        end

        if not self.ismastersim then
            if self.locomotor == nil then
                self:RemoteDirectWalking(dir.x, dir.z)
            end
        elseif self.time_direct_walking > .2 and not self.inst.sg:HasStateTag("attack") then
            self.inst.components.combat:SetTarget(nil)
        end
    elseif self.predictwalking then
        if self.locomotor.bufferedaction == nil then
            self.locomotor:Stop()
        end
        self.directwalking = false
        self.dragwalking = false
        self.predictwalking = false
    elseif self.directwalking or self.dragwalking then
        if self:CanLocomote() and self.controller_attack_override == nil then
            self.locomotor:Stop()
        end
        self.directwalking = false
        self.dragwalking = false
        self.predictwalking = false
        if not self.ismastersim then
            self:CooldownRemoteController()
            if self.locomotor == nil then
                self:RemoteStopWalking()
            end
        end
    end
end

--------------------------------------------------------------------------

function PlayerController:DoCameraControl()
    if not TheCamera:CanControl()
        or (self.inst.HUD ~= nil and
            self.inst.HUD:IsCraftingOpen()) then
        --Check crafting again because this time
        --we block even with mouse crafting open
        return
    end

    local ROT_REPEAT = .25
    local ZOOM_REPEAT = .1

    local time = GetTime()

    if self.lastrottime == nil or time - self.lastrottime > ROT_REPEAT then
        if TheInput:IsControlPressed(CONTROL_ROTATE_LEFT) then
            self:RotLeft()
            self.lastrottime = time
        elseif TheInput:IsControlPressed(CONTROL_ROTATE_RIGHT) then
            self:RotRight()
            self.lastrottime = time
        end
    end

    if self.lastzoomtime == nil or time - self.lastzoomtime > ZOOM_REPEAT then
        if TheInput:IsControlPressed(CONTROL_ZOOM_IN) then
            TheCamera:ZoomIn()
            self.lastzoomtime = time
        elseif TheInput:IsControlPressed(CONTROL_ZOOM_OUT) then
            TheCamera:ZoomOut()
            self.lastzoomtime = time
        end
    end
end

local function IsWalkButtonDown()
    return TheInput:IsControlPressed(CONTROL_MOVE_UP) or TheInput:IsControlPressed(CONTROL_MOVE_DOWN) or TheInput:IsControlPressed(CONTROL_MOVE_LEFT) or TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)
end

function PlayerController:OnLeftUp()
    if not self:IsEnabled() then
        return
    end

    if self.draggingonground then
        if self:CanLocomote() and not IsWalkButtonDown() then
            self.locomotor:Stop()
        end
        self.draggingonground = false
        self.startdragtime = nil
        TheFrontEnd:LockFocus(false)
    end
    self.startdragtime = nil

    if not self.ismastersim then
        self:RemoteStopControl(CONTROL_PRIMARY)
    end
end

function PlayerController:DoAction(buffaction)
    --Check if the action is actually valid.
    --Cached LMB/RMB actions can become invalid.
    --Also check if we're busy.
    if buffaction == nil or
        (buffaction.invobject ~= nil and not buffaction.invobject:IsValid()) or
        (buffaction.target ~= nil and not buffaction.target:IsValid()) or
        (buffaction.doer ~= nil and not buffaction.doer:IsValid()) or
        self:IsBusy() then
        return
    end

    --Check for duplicate actions
    local currentbuffaction = self.inst:GetBufferedAction()
    if currentbuffaction ~= nil and
        currentbuffaction.action == buffaction.action and
        currentbuffaction.target == buffaction.target and
        (   (currentbuffaction.pos == nil and buffaction.pos == nil) or
            (currentbuffaction.pos ~= nil and buffaction.pos ~= nil and
            currentbuffaction.pos.x == buffaction.pos.x and
            currentbuffaction.pos.z == buffaction.pos.z)
        ) and
        not (currentbuffaction.ispreviewing and
            self.inst:HasTag("idle") and
            self.inst.sg:HasStateTag("idle")) then
        --The "not" bit is in case we are stuck waiting for server
        --to act but it never does
        return
    end

    if self.handler ~= nil and buffaction.target ~= nil then
        if buffaction.target.components.highlight == nil then
            buffaction.target:AddComponent("highlight")
        end
        buffaction.target.components.highlight:Flash(.2, .125, .1)
    end

    --Clear any buffered attacks since we're starting a new action
    self.attack_buffer = nil

    self:DoActionAutoEquip(buffaction)

    if self.ismastersim then
        self.locomotor:PushAction(buffaction, true)
    elseif self:CanLocomote() then
        self.locomotor:PreviewAction(buffaction, true)
    end
end

function PlayerController:DoActionAutoEquip(buffaction)
    if buffaction.invobject ~= nil and
        buffaction.invobject.replica.equippable ~= nil and
        buffaction.invobject.replica.equippable:EquipSlot() == EQUIPSLOTS.HANDS and
        buffaction.action ~= ACTIONS.DROP and
        buffaction.action ~= ACTIONS.COMBINESTACK and
        buffaction.action ~= ACTIONS.STORE and
        buffaction.action ~= ACTIONS.EQUIP and
        buffaction.action ~= ACTIONS.GIVETOPLAYER and
        buffaction.action ~= ACTIONS.GIVEALLTOPLAYER and
        buffaction.action ~= ACTIONS.GIVE and
        buffaction.action ~= ACTIONS.ADDFUEL and
        buffaction.action ~= ACTIONS.ADDWETFUEL then
        self.inst.replica.inventory:EquipActionItem(buffaction.invobject)
        buffaction.autoequipped = true
    end
end

function PlayerController:OnLeftClick(down)
    if not self:UsingMouse() then
        return
    elseif not down then
        self:OnLeftUp()
        return
    end

    self.startdragtime = nil

    if not self:IsEnabled() then
        return
    elseif TheInput:GetHUDEntityUnderMouse() ~= nil then 
        self:CancelPlacement()
        return
    end

    if self.placer_recipe ~= nil and self.placer ~= nil then
        --do the placement
        if self.placer.components.placer.can_build and
            self.inst.replica.builder ~= nil and
            not self.inst.replica.builder:IsBusy() then
            self.inst.replica.builder:MakeRecipeAtPoint(self.placer_recipe, TheInput:GetWorldPosition(), self.placer:GetRotation(), self.placer_recipe_skin)
            self:CancelPlacement()
        end
        return
    end

    local act = self:GetLeftMouseAction() or BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, TheInput:GetWorldPosition())
    if act.action == ACTIONS.WALKTO then
        if act.target == nil and TheInput:GetWorldEntityUnderMouse() == nil then
            self.startdragtime = GetTime()
        end
    elseif act.action == ACTIONS.ATTACK then
        if self.inst.sg ~= nil then
            if self.inst.sg:HasStateTag("attack") then
                return
            end
        elseif self.inst:HasTag("attack") then
            return
        end
    elseif act.action == ACTIONS.LOOKAT
        and act.target ~= nil
        and act.target:HasTag("player")
        and self.inst.HUD ~= nil then
        local client_obj = TheNet:GetClientTableForUser(act.target.userid)
        if client_obj ~= nil then
            client_obj.inst = act.target
            self.inst.HUD:TogglePlayerAvatarPopup(client_obj.name, client_obj)
        end
    end

    if self.ismastersim then
        self.inst.components.combat:SetTarget(nil)
    else
        local position = TheInput:GetWorldPosition()
        local mouseover = act.action ~= ACTIONS.DROP and TheInput:GetWorldEntityUnderMouse() or nil
        local controlmods = self:EncodeControlMods()
        if self.locomotor == nil then
            self.remote_controls[CONTROL_PRIMARY] = 0
            SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, mouseover, nil, controlmods, act.action.canforce, act.action.mod_name)
        elseif act.action ~= ACTIONS.WALKTO and self:CanLocomote() then
            act.preview_cb = function()
                self.remote_controls[CONTROL_PRIMARY] = 0
                local isreleased = not TheInput:IsControlPressed(CONTROL_PRIMARY)
                SendRPCToServer(RPC.LeftClick, act.action.code, position.x, position.z, mouseover, isreleased, controlmods, nil, act.action.mod_name)
            end
        end
    end

    self:DoAction(act)
end

function PlayerController:OnRemoteLeftClick(actioncode, position, target, isreleased, controlmodscode, noforce, mod_name)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.inst.components.combat:SetTarget(nil)

        self.remote_controls[CONTROL_PRIMARY] = 0
        self:DecodeControlMods(controlmodscode)
        local lmb, rmb = self.inst.components.playeractionpicker:DoGetMouseActions(position, target)
        if isreleased then
            self.remote_controls[CONTROL_PRIMARY] = nil
        end
        self:ClearControlMods()

        --Default fallback lmb action is WALKTO
        --Possible for lmb action to switch to rmb after autoequip
        lmb =  (lmb == nil and
                actioncode == ACTIONS.WALKTO.code and
                mod_name == nil and
                BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, position))
            or (lmb ~= nil and
                lmb.action.code == actioncode and
                lmb.action.mod_name == mod_name and
                lmb)
            or (rmb ~= nil and
                rmb.action.code == actioncode and
                rmb.action.mod_name == mod_name and
                rmb)
            or nil

        if lmb ~= nil then
            if lmb.action.canforce and not noforce then
                lmb.pos = self:GetRemotePredictPosition() or self.inst:GetPosition()
                lmb.forced = true
            end
            self:DoAction(lmb)
        --elseif mod_name ~= nil then
            --print("Remote left click action failed: "..tostring(ACTION_MOD_IDS[mod_name][actioncode]))
        --else
            --print("Remote left click action failed: "..tostring(ACTION_IDS[actioncode]))
        end
    end
end

function PlayerController:OnRightClick(down)
    if not self:UsingMouse() then
        return
    elseif not down then
        if self:IsEnabled() then
            self:RemoteStopControl(CONTROL_SECONDARY)
        end
        return
    end

    self.startdragtime = nil

    if self.placer_recipe ~= nil then
        self:CancelPlacement()
        return
    end

    if not self:IsEnabled() or TheInput:GetHUDEntityUnderMouse() ~= nil then
        return
    end

    local act = self:GetRightMouseAction()
    if act == nil then
        self.inst.replica.inventory:ReturnActiveItem()
    else
        if not self.ismastersim then
            local position = TheInput:GetWorldPosition()
            local mouseover = TheInput:GetWorldEntityUnderMouse()
            local controlmods = self:EncodeControlMods()
            if self.locomotor == nil then
                self.remote_controls[CONTROL_SECONDARY] = 0
                SendRPCToServer(RPC.RightClick, act.action.code, position.x, position.z, mouseover, nil, controlmods, act.action.canforce, act.action.mod_name)
            elseif act.action ~= ACTIONS.WALKTO and self:CanLocomote() then
                act.preview_cb = function()
                    self.remote_controls[CONTROL_SECONDARY] = 0
                    local isreleased = not TheInput:IsControlPressed(CONTROL_SECONDARY)
                    SendRPCToServer(RPC.RightClick, act.action.code, position.x, position.z, mouseover, isreleased, controlmods, nil, act.action.mod_name)
                end
            end
        end
        self:DoAction(act)
    end
end

function PlayerController:OnRemoteRightClick(actioncode, position, target, isreleased, controlmodscode, noforce, mod_name)
    if self.ismastersim and self:IsEnabled() and self.handler == nil then
        self.remote_controls[CONTROL_SECONDARY] = 0
        self:DecodeControlMods(controlmodscode)
        local lmb, rmb = self.inst.components.playeractionpicker:DoGetMouseActions(position, target)
        if isreleased then
            self.remote_controls[CONTROL_SECONDARY] = nil
        end
        self:ClearControlMods()

        if rmb ~= nil and rmb.action.code == actioncode and rmb.action.mod_name == mod_name then
            if rmb.action.canforce and not noforce then
                rmb.pos = self:GetRemotePredictPosition() or self.inst:GetPosition()
                rmb.forced = true
            end
            self:DoAction(rmb)
        --elseif mod_name ~= nil then
            --print("Remote right click action failed: "..tostring(ACTION_MOD_IDS[mod_name][actioncode]))
        --else
            --print("Remote right click action failed: "..tostring(ACTION_IDS[actioncode]))
        end
    end
end

function PlayerController:GetLeftMouseAction()
    return self.LMBaction
end

function PlayerController:GetRightMouseAction()
    return self.RMBaction
end

function PlayerController:GetItemSelfAction(item)
    if item == nil then
        return
    end
    local act =
        --[[rmb]] self.inst.components.playeractionpicker:GetInventoryActions(item, true)[1] or
        --[[lmb]] self.inst.components.playeractionpicker:GetInventoryActions(item, false)[1]
    return act ~= nil and act.action ~= ACTIONS.LOOKAT and act or nil
end

function PlayerController:GetSceneItemControllerAction(item)
    if item == nil then
        return
    end
    local itempos = item:GetPosition()
    local lmb = self.inst.components.playeractionpicker:GetLeftClickActions(itempos, item)[1]
    local rmb = self.inst.components.playeractionpicker:GetRightClickActions(itempos, item)[1]
    if lmb ~= nil
        and (lmb.action == ACTIONS.LOOKAT or
            (lmb.action == ACTIONS.ATTACK and item.replica.combat ~= nil) or
            lmb.action == ACTIONS.WALKTO) then
        lmb = nil
    end
    if rmb ~= nil
        and (rmb.action == ACTIONS.LOOKAT or
            (rmb.action == ACTIONS.ATTACK and item.replica.combat ~= nil) or
            rmb.action == ACTIONS.WALKTO) then
        rmb = nil
    end
    return lmb, rmb ~= nil and (lmb == nil or lmb.action ~= rmb.action) and rmb or nil
end

function PlayerController:GetGroundUseAction(position)
    position = position or
        (self.reticule ~= nil and self.reticule.targetpos) or
        (self.terraformer ~= nil and self.terraformer:GetPosition()) or
        (self.placer ~= nil and self.placer:GetPosition()) or
        (self.deployplacer ~= nil and self.deployplacer:GetPosition()) or
        self.inst:GetPosition()

    if self.map:IsPassableAtPoint(position:Get()) then
        --Check validitiy because FE controls may call this in WallUpdate
        local equipitem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equipitem ~= nil and equipitem:IsValid() then
            local lmb = self.inst.components.playeractionpicker:GetPointActions(position, equipitem, false)[1]
            local rmb = self.inst.components.playeractionpicker:GetPointActions(position, equipitem, true)[1]
            if lmb ~= nil then
                if lmb.action == ACTIONS.DROP then
                    lmb = nil
                elseif lmb.action == ACTIONS.TERRAFORM then
                    lmb.distance = 2
                end
            end
            if rmb ~= nil and rmb.action == ACTIONS.TERRAFORM then
                rmb.distance = 2
            end
            return lmb, rmb ~= nil and (lmb == nil or lmb.action ~= rmb.action) and rmb or nil
        end
    end
end

function PlayerController:GetItemUseAction(active_item, target)
    if active_item == nil then
        return
    end
    target = target or self:GetControllerTarget()
    if target == nil then
        return
    end
    local act =
        --[[rmb]] self.inst.components.playeractionpicker:GetUseItemActions(target, active_item, true)[1] or
        --[[lmb]] self.inst.components.playeractionpicker:GetUseItemActions(target, active_item, false)[1]
    return act ~= nil and
        (active_item.replica.equippable == nil or not active_item:HasTag(act.action.id.."_tool")) and
        (act.action ~= ACTIONS.STORE or target.replica.inventoryitem == nil or not target.replica.inventoryitem:IsGrandOwner(self.inst)) and
        act.action ~= ACTIONS.COMBINESTACK and
        act.action ~= ACTIONS.ATTACK and
        act or nil
end

function PlayerController:RemoteUseItemFromInvTile(buffaction, item)
    if not self.ismastersim then
        local controlmods = self:EncodeControlMods()
        if self.locomotor == nil then
            SendRPCToServer(RPC.UseItemFromInvTile, buffaction.action.code, item, controlmods, buffaction.action.mod_name)
        elseif buffaction.action ~= ACTIONS.WALKTO and self:CanLocomote() then
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.UseItemFromInvTile, buffaction.action.code, item, controlmods, buffaction.action.mod_name)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

function PlayerController:RemoteControllerUseItemOnItemFromInvTile(buffaction, item, active_item)
    if not self.ismastersim then
        if self.locomotor == nil then
            SendRPCToServer(RPC.ControllerUseItemOnItemFromInvTile, buffaction.action.code, item, active_item, buffaction.action.mod_name)
        elseif buffaction.action ~= ACTIONS.WALKTO and self:CanLocomote() then
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.ControllerUseItemOnItemFromInvTile, buffaction.action.code, item, active_item, buffaction.action.mod_name)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

function PlayerController:RemoteControllerUseItemOnSelfFromInvTile(buffaction, item)
    if not self.ismastersim then
        if self.locomotor == nil then
            SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, buffaction.action.code, item, buffaction.action.mod_name)
        elseif buffaction.action ~= ACTIONS.WALKTO and self:CanLocomote() then
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, buffaction.action.code, item, buffaction.action.mod_name)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

function PlayerController:RemoteControllerUseItemOnSceneFromInvTile(buffaction, item)
    if not self.ismastersim then
        if self.locomotor == nil then
            SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, buffaction.action.code, item, buffaction.target, buffaction.action.mod_name)
        elseif buffaction.action ~= ACTIONS.WALKTO and self:CanLocomote() then
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.ControllerUseItemOnSceneFromInvTile, buffaction.action.code, item, buffaction.target, buffaction.action.mod_name)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

function PlayerController:RemoteInspectItemFromInvTile(item)
    if not self.ismastersim then
        if self.locomotor == nil then
            SendRPCToServer(RPC.InspectItemFromInvTile, item)
        elseif self:CanLocomote() then
            local buffaction = BufferedAction(self.inst, nil, ACTIONS.LOOKAT, item)
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.InspectItemFromInvTile, item)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

function PlayerController:RemoteDropItemFromInvTile(item)
    if not self.ismastersim then
        if self.locomotor == nil then
            SendRPCToServer(RPC.DropItemFromInvTile, item)
        elseif self:CanLocomote() then
            local buffaction = BufferedAction(self.inst, nil, ACTIONS.DROP, item, self.inst:GetPosition())
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.DropItemFromInvTile, item)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

function PlayerController:RemoteMakeRecipeFromMenu(recipe, skin)
    if not self.ismastersim then
		local skin_index = -1
		if PREFAB_SKINS_IDS[recipe.name] ~= nil and skin ~= nil then
			skin_index = PREFAB_SKINS_IDS[recipe.name][skin]
		end
        if self.locomotor == nil then
            SendRPCToServer(RPC.MakeRecipeFromMenu, recipe.rpc_id, skin_index)
		elseif self:CanLocomote() then
            self.locomotor:Stop()
            local buffaction = BufferedAction(self.inst, nil, ACTIONS.BUILD, nil, nil, recipe.name, 1)
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.MakeRecipeFromMenu, recipe.rpc_id, skin_index)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

function PlayerController:RemoteMakeRecipeAtPoint(recipe, pt, rot, skin)
    if not self.ismastersim then

        --if not skin then print ("############# SKIN IS NIL") return end

		local skin_index = nil
        if skin ~= nil then 
           skin_index = PREFAB_SKINS_IDS[recipe.name][skin]
        end

        if self.locomotor == nil then
            SendRPCToServer(RPC.MakeRecipeAtPoint, recipe.rpc_id, pt.x, pt.z, rot, skin_index)
        elseif self:CanLocomote() then
            self.locomotor:Stop()
            local buffaction = BufferedAction(self.inst, nil, ACTIONS.BUILD, nil, pt, recipe.name, 1, nil, rot)
            buffaction.preview_cb = function()
                SendRPCToServer(RPC.MakeRecipeAtPoint, recipe.rpc_id, pt.x, pt.z, rot, skin_index)
            end
            self.locomotor:PreviewAction(buffaction, true)
        end
    end
end

local function DoRemoteBufferedAction(inst, self, buffaction)
    if self.classified ~= nil and self.classified.iscontrollerenabled:value() then
        buffaction.preview_cb()
    end
end

function PlayerController:RemoteBufferedAction(buffaction)
    if not self.ismastersim and buffaction.preview_cb ~= nil then
        --Delay one frame if we just sent movement prediction so that
        --this RPC arrives a frame after the movement prediction RPC
        if self.predictionsent then
            self.inst:DoTaskInTime(0, DoRemoteBufferedAction, self, buffaction)
        else
            DoRemoteBufferedAction(self.inst, self, buffaction)
        end
    end
end

function PlayerController:OnRemoteBufferedAction()
    if self.ismastersim then
        --If we're starting a remote buffered action, prevent the last
        --movement prediction vector from cancelling us out right away
        if self.remote_vector.y >= 3 then
            self.remote_vector.y = 5
        elseif self.remote_vector.y == 0 then
            self.directwalking = false
            self.dragwalking = false
            self.predictwalking = false
        end
    end
end

return PlayerController
