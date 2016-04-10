--
-- RCReceiver
-- Specialization for RCReceiver
--
-- @author mogli
-- @date	20.07.2015
--


RCReceiver = {};
RCReceiver.doDebugPrint = false

function RCReceiver.debugPrint( ... )
	if RCReceiver.doDebugPrint then
		print( ... )
	end
end

function RCReceiver.prerequisitesPresent(specializations)
	return true
end;

function RCReceiver:load(xmlFile)
	self.RCInputProcessing = SpecializationUtil.callSpecializationsFunction("RCInputProcessing");
	self.RCGetIsLowered    = RCReceiver.RCGetIsLowered
	self.RCSetIsLowered    = RCReceiver.RCSetIsLowered
	self.RCGetIsUnfolded   = RCReceiver.RCGetIsUnfolded
	self.RCSetIsUnfolded   = RCReceiver.RCSetIsUnfolded
	local detachInputButtonStr = getXMLString( xmlFile, "vehicle.RCReceiver#detachInputButton" )
	if detachInputButtonStr ~= nil then
		self.RCDetachInputButton = InputBinding[detachInputButtonStr]
		RCReceiver.debugPrint(detachInputButtonStr.." => "..tostring(self.RCDetachInputButton))
--else 
--	self.RCDetachInputButton = InputBinding.ATTACH
	end
end

function RCReceiver:draw()
	RCReceiver.debugPrint("RCReceiver:draw: "..tostring(self))
	if not ( self.isSelected ) then
		if      self.attacherJoint.allowsLowering 
				and self.attacherVehicle          ~= nil then
			local implementIndex = self.attacherVehicle:getImplementIndexByObject(self)
			local implement = self.attacherVehicle.attachedImplements[implementIndex]
			local jointDesc = self.attacherVehicle.attacherJoints[implement.jointDescIndex];
			if jointDesc.allowsLowering then
				if jointDesc.moveDown then
					g_currentMission:addHelpButtonText(string.format(g_i18n:getText("lift_OBJECT"), self.typeDesc), InputBinding.LOWER_IMPLEMENT)
				else
					g_currentMission:addHelpButtonText(string.format(g_i18n:getText("lower_OBJECT"), self.typeDesc), InputBinding.LOWER_IMPLEMENT)
				end
			end
		end
		
		if      self.foldInputButton          ~= nil
				and self.isClient
				and 0 < table.getn(self.foldingParts) 
				and self.getIsFoldAllowed(self) 
				and (self.foldMiddleAnimTime      == nil 
					or self.foldMiddleAnimTime      ~= 1) then
			if 0 < self.getToggledFoldDirection(self) then
				g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.posDirectionText), self.typeDesc), self.foldInputButton)
			else
				g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.negDirectionText), self.typeDesc), self.foldInputButton)
			end
		end

		if      self.getCanBeTurnedOn         ~= nil
				and self.toggleTurnOnInputBinding ~= nil
				and self.isClient
				and self.getCanBeTurnedOn(self) then
			if self.isTurnedOn then
				g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.turnOffText), self.typeDesc), self.toggleTurnOnInputBinding)
			else
				g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.turnOnText), self.typeDesc), self.toggleTurnOnInputBinding)
			end
		end
			
		if      self.RCDetachInputButton      ~= nil 
				and self.attacherVehicle          ~= nil 
				and not ( self.isSelected ) 
				and self:isDetachAllowed() then
			g_currentMission:addHelpButtonText(g_i18n:getText("Detach"), self.RCDetachInputButton)
		else
			RCReceiver.debugPrint(tostring(self.RCDetachInputButton).." "..tostring(self.attacherVehicle).." "..tostring(self.isSelected).." "..tostring(self:isDetachAllowed()))
		end
	end
end;

function RCReceiver:RCInputProcessing()
	RCReceiver.debugPrint("RCReceiver:RCInputProcessing: "..tostring(self))
	if      InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) 
			and self.attacherJoint.allowsLowering 
			and self.attacherVehicle          ~= nil then
		local implementIndex = self.attacherVehicle:getImplementIndexByObject(self)
		local implement = self.attacherVehicle.attachedImplements[implementIndex]
		local jointDesc = self.attacherVehicle.attacherJoints[implement.jointDescIndex];
		if jointDesc.allowsLowering then
			self:RCSetIsLowered()
		end
	end
	
	if      self.foldInputButton          ~= nil
			and InputBinding.hasEvent(self.foldInputButton) 
			and self.isClient
			and 0 < table.getn(self.foldingParts) 
			and self.getIsFoldAllowed(self) 
			and (self.foldMiddleAnimTime      == nil 
				or self.foldMiddleAnimTime      ~= 1) then
		self:RCSetIsUnfolded()
	end
	
	if      self.getCanBeTurnedOn         ~= nil
			and self.toggleTurnOnInputBinding ~= nil
			and self.isClient
			and self.getCanBeTurnedOn(self) 
			and InputBinding.hasEvent(self.toggleTurnOnInputBinding) then
		if self.getIsTurnedOnAllowed(self, not self.isTurnedOn) then
			self.setIsTurnedOn(self, not self.isTurnedOn)
		elseif not self.isTurnedOn then
			local warning = self.getTurnedOnNotAllowedWarning(self)

			if warning ~= nil then
				g_currentMission:showBlinkingWarning(warning, 2000)
			end
		end
	end
			
	if      self.RCDetachInputButton      ~= nil 
			and InputBinding.hasEvent(self.RCDetachInputButton)
			and self.attacherVehicle          ~= nil 
			and self:isDetachAllowed() then
		self.attacherVehicle:detachImplementByObject( self )
	end
end

function RCReceiver:RCSetIsLowered( moveDown )
	if self.attacherVehicle ~= nil then
		local implementIndex = self.attacherVehicle:getImplementIndexByObject(self)
		local implement = self.attacherVehicle.attachedImplements[implementIndex]
		local jointDesc = self.attacherVehicle.attacherJoints[implement.jointDescIndex];
		if      self.attacherJoint.allowsLowering 
				and jointDesc.allowsLowering 
				and ( moveDown == nil
					 or ( moveDown and not ( jointDesc.moveDown ) )
					 or ( jointDesc.moveDown and not ( moveDown ) ) ) then
			self.attacherVehicle:setJointMoveDown(implement.jointDescIndex, not jointDesc.moveDown, false);
		end
	end
end

function RCReceiver:RCGetIsLowered()
	return self:isLowered(false)
end

function RCReceiver:RCSetIsUnfolded( unfolded )
	if     unfolded == nil then
		unfolded = not ( RCReceiver.RCGetIsUnfolded( self ) )
	elseif unfolded == RCReceiver.RCGetIsUnfolded( self ) then
		return 
	end
	
	if unfolded then
		self:setFoldState( self.getToggledFoldDirection(self), true)
	else
		self:setFoldState( self.getToggledFoldDirection(self), false)
	end
end

function RCReceiver:RCGetIsUnfolded()
	if self.getToggledFoldDirection(self) == self.turnOnFoldDirection then
		return false
	else
		return true
	end
end

function RCReceiver:update(dt)	
	--if self:getIsActiveForInput(true) then
	--	self:RCInputProcessing( )
	--end
end;

function RCReceiver:updateTick(dt)	
end;

function RCReceiver:delete()
end;

function RCReceiver:mouseEvent(posX, posY, isDown, isUp, button)
end;

function RCReceiver:keyEvent(unicode, sym, modifier, isDown)
end;

function RCReceiver:onAttach( attacherVehicle, jointDescIndex )
	RCReceiver.debugPrint("RCReceiver:onAttach: "..tostring(self))
	if attacherVehicle.RCSenderVehicles ~= nil then
		attacherVehicle.RCSenderVehicles[self]  = true
	end
end

function RCReceiver:onDetach( attacherVehicle, jointDescIndex )
	RCReceiver.debugPrint("RCReceiver:onDetach: "..tostring(self))
	if attacherVehicle.RCSenderVehicles ~= nil then
		attacherVehicle.RCSenderVehicles[self]  = nil
	end
end

function RCReceiver:newVehicleGetIsSelectable( superFunc, ... )
	if self.RCDetachInputButton ~= nil and self.attacherVehicle ~= nil and self.attacherVehicle.RCSenderVehicles ~= nil then
		return false
	else
		return superFunc( self, ... )
	end
end

Vehicle.getIsSelectable = Utils.overwrittenFunction( Vehicle.getIsSelectable, RCReceiver.newVehicleGetIsSelectable )
