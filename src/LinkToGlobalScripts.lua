--***************************************************************
--
-- LinkToGlobalScripts
-- 
-- version 1.00 by mogli (biedens)
-- 2015/12/01
--
--***************************************************************

--***************************************************************
-- empty default functions
--***************************************************************
LinkToGlobalScripts = {}
LinkToGlobalScripts.debug = true
--********************************
-- prerequisitesPresent
--********************************
function LinkToGlobalScripts.prerequisitesPresent(specializations) 
	return true
end 

--********************************
-- load
--********************************
function LinkToGlobalScripts:load(xmlFile)

	for n,f in pairs( LinkToGlobalScripts ) do
		if type(f) == "function" and string.sub( n, 1, 4 ) == "l2gs" then
			self[n] = f
		end
	end
end

--********************************
-- delete
--********************************
function LinkToGlobalScripts:delete()
end

--********************************
-- mouseEvent
--********************************
function LinkToGlobalScripts:mouseEvent(posX, posY, isDown, isUp, button)
end

--********************************
-- keyEvent
--********************************
function LinkToGlobalScripts:keyEvent(unicode, sym, modifier, isDown)
end

--********************************
-- update
--********************************
function LinkToGlobalScripts:update(dt)
end

--********************************
-- updateTick
--********************************
function LinkToGlobalScripts:updateTick(dt)	
end

--********************************
-- draw
--********************************
function LinkToGlobalScripts:draw()	
end  
				 
--********************************
-- getSaveAttributesAndNodes
--********************************
function LinkToGlobalScripts:l2gsGetSaveAttributesAndNodes(nodeIdent)
	local attributes = ""
	local nodes      = ""					
	return attributes, nodes
end;

--********************************
-- loadFromAttributesAndNodes
--********************************
function LinkToGlobalScripts:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	return BaseMission.VEHICLE_LOAD_OK
end 
--***************************************************************

--***************************************************************
-- warning
--***************************************************************
function LinkToGlobalScripts.warning( text, ms )
	g_currentMission:showBlinkingWarning( text, Utils.getNoNil( ms, 5000 ) )
	if LinkToGlobalScripts.debug then
		print( text )
	end
end

--**********************************************************************************************************	
-- LinkToGlobalScripts:l2gsToggleAutoTractorOn
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleAITractorOn( force )

	local enable = force
	if force == nil then
		enable = not ( self.isAITractorActivated )
	end
	
  if self.isAITractorActivated and not ( enable ) then
    self:stopAITractor()
  elseif AITractor.canStartAITractor(self) and enable then
    self:startAITractor()
  end
end

--**********************************************************************************************************	
-- toggleAutoTractorEnabled
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleAutoTractorEnabled( force )

	if     AutoTractor          == nil 
			or self.acParameters    == nil 
			or AutoTractor.onEnable == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts:setAutoTractorOn: mod zzzAutoTractor is missing!" )
		return
	end
	
	local enable
	if force == nil then
		enable = not ( self.acParameters.enabled )
	else
		enable = force
	end
	AutoTractor.onEnable( self, enable ) 
	
	if AutoTractor.sendParameters ~= nil then
		AutoTractor.sendParameters(self)
	end
end

--**********************************************************************************************************	
-- getAutoTractorEnabled
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorEnabled()
	if     AutoTractor          == nil 
			or self.acParameters    == nil then
		return false
	end
	return self.acParameters.enabled
end

--**********************************************************************************************************	
-- toggleAutoTractorLeftRight
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleAutoTractorLeftRight( force )

	if     AutoTractor             == nil 
			or self.acParameters       == nil 
			or AutoTractor.setAreaLeft == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod zzzAutoTractor is missing!" )
		return
	end
	
	local enable
	if force == nil then
		enable = not ( self.acParameters.leftAreaActive )
	else
		enable = force
	end
	AutoTractor.setAreaLeft( self, enable ) 
	
	if AutoTractor.sendParameters ~= nil then
		AutoTractor.sendParameters(self)
	end
end

--**********************************************************************************************************	
-- getAutoTractorLeftRight
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorLeftRight()
	if     AutoTractor          == nil 
			or self.acParameters    == nil then
		return nil 
	end
	return self.acParameters.leftAreaActive
end

--**********************************************************************************************************	
-- toggleAutoTractorUTurn
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleAutoTractorUTurn( force )

	if     AutoTractor          == nil 
			or self.acParameters    == nil 
			or AutoTractor.setUTurn == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod zzzAutoTractor is missing!" )
		return
	end
	
	local enable
	if force == nil then
		enable = not ( self.acParameters.upNDown )
	else
		enable = force
	end
	AutoTractor.setUTurn( self, enable ) 
	
	if AutoTractor.sendParameters ~= nil then
		AutoTractor.sendParameters(self)
	end
end

--**********************************************************************************************************	
-- getAutoTractorUTurn
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorUTurn()
	if     AutoTractor          == nil 
			or self.acParameters    == nil then
		return true 
	end
	return self.acParameters.upNDown
end

--**********************************************************************************************************	
-- getAutoTractorWorkingWidth
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorWorkingWidth()
	if     AutoTractor                     == nil 
			or AutoTractor.calculateDimensions == nil 
			or self.acParameters               == nil then
		return nil
	end
	
	if     self.acDimensions                   == nil 
			or self.acDimensions.distance          == nil then
		AutoTractor.calculateDimensions( self )
	end
	if     self.acDimensions                   == nil 
			or self.acDimensions.distance          == nil then
		return 0
	end
	
	return self.acDimensions.distance + self.acDimensions.distance
end

--**********************************************************************************************************	
-- getAutoTractorWorkingDistanceMid
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorWorkingDistanceMid()
	if self.aseActiveX == nil and AutoTractor ~= nil and AutoTractor.checkState ~= nil then
		AutoTractor.checkState( self )
	end

	if self.aseActiveX == nil then
		return nil
	end
	
	if self.aseLRSwitch then
		return self.aseActiveX
	else
		return -self.aseActiveX
	end
end

--**********************************************************************************************************	
-- getAutoTractorWorkingDistanceMid
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorWorkingDistanceOutside()
	if self.aseActiveX == nil and AutoTractor ~= nil and AutoTractor.checkState ~= nil then
		AutoTractor.checkState( self )
	end
	
	if self.aseActiveX == nil then
		return nil
	end
	return self:l2gsGetAutoTractorWorkingDistanceMid() + 0.5 * self.sizeWidth
end

--**********************************************************************************************************	
-- getAutoTractorWorkingDistanceFront
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorWorkingDistanceFront()
	
	if self.aseToolParams == nil and AutoTractor ~= nil and AutoTractor.checkState ~= nil then
		AutoTractor.checkState( self )
	end
	
	if type(self.aseToolParams) == "table" then
		local z = nil
		
		for _,tp in pairs(self.aseToolParams) do
			if tp.zReal ~= nil and ( z == nil or z < tp.zReal ) then
				z = tp.zReal
			end
		end
		
		return z
	end
	
	return nil
end

--**********************************************************************************************************	
-- getAutoTractorWorkingDistanceBack
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorWorkingDistanceBack()

	if type(self.aseToolParams) == "table" then
		local z = nil
		
		for _,tp in pairs(self.aseToolParams) do
			if tp.zReal ~= nil and ( z == nil or z < -tp.zReal ) then
				z = -tp.zReal
			end
		end
		
		return z
	end

	return nil	
end


--**********************************************************************************************************	
-- getAutoTractorHeadland
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetAutoTractorHeadland()
	if     AutoTractor                     == nil 
			or AutoTractor.calculateDimensions == nil 
			or self.acParameters               == nil then
		return 0
	end
	
	if     not ( self.acParameters.upNDown ) 
			or not ( self.acParameters.headland ) then
		return 0
	end
	
	if     self.acDimensions                                == nil 
			or self.acDimensions.self.acDimensions.headlandDist == nil then
		AutoTractor.calculateDimensions( self )
	end
	if     self.acDimensions                                == nil 
			or self.acDimensions.self.acDimensions.headlandDist == nil then
		return 0
	end
	
	return self.acDimensions.self.acDimensions.headlandDist
end

--**********************************************************************************************************	
-- toggleGearboxOnOff
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleGearboxOnOff()
	if     self.mrGbMSetIsOnOff  == nil 
			or self.mrGbMGetIsOnOff  == nil then
		-- show blinking warning
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod zzzMrGearboxAddon is missing!" )
		return
	end
	
	if self.mrGbMS.NoDisable then
		return 
	end
	
	local target
	if force == nil then
		traget = not ( self:mrGbMGetIsOnOff() )
	else
		target = force
	end
	
	if target == self:mrGbMGetIsOnOff() then
		return
	end
	
	if      self.isMotorStarted
			and ( ( self.dCcheckModule ~= nil
					and self:dCcheckModule("manMotorStart") )
				 or ( self.setManualIgnitionMode ~= nil ) ) then
		LinkToGlobalScripts.warning( "Cannot exchange gearbox while motor is running" )
	else	
		self:mrGbMSetIsOnOff( target ) 
	end
end

--**********************************************************************************************************	
-- toggleDC4WD
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleDC4WD()

	if     self.dCcheckModule == nil
			or self.driveControl == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod ZZZ_driveControl is missing!" )
		return 
	end
	
	if      self:dCcheckModule("fourWDandDifferentials") 
			and self.driveControl.fourWDandDifferentials ~= nil
			and not ( self.driveControl.fourWDandDifferentials.isSurpressed ) then
			
		local enable 
		if force == nil then
			enable = not ( self.driveControl.fourWDandDifferentials.fourWheel )
		else
			enable = force
		end
		
		self.driveControl.fourWDandDifferentials.fourWheel = enable
		driveControlInputEvent.sendEvent(self)
	end

end

--**********************************************************************************************************	
-- toggleDCDiffLockFront 
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleDCDiffLockFront()

	if     self.dCcheckModule == nil
			or self.driveControl == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod ZZZ_driveControl is missing!" )
		return 
	end
	
	if      self:dCcheckModule("fourWDandDifferentials") 
			and self.driveControl.fourWDandDifferentials ~= nil
			and not ( self.driveControl.fourWDandDifferentials.isSurpressed ) then
			
		local enable 
		if force == nil then
			enable = not ( self.driveControl.fourWDandDifferentials.diffLockFront )
		else
			enable = force
		end
		
		self.driveControl.fourWDandDifferentials.diffLockFront = enable
		driveControlInputEvent.sendEvent(self)
	end

end

--**********************************************************************************************************	
-- toggleDCDiffLockBack
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleDCDiffLockBack()

	if     self.dCcheckModule == nil
			or self.driveControl == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod ZZZ_driveControl is missing!" )
		return 
	end
	
	if      self:dCcheckModule("fourWDandDifferentials") 
			and self.driveControl.fourWDandDifferentials ~= nil
			and not ( self.driveControl.fourWDandDifferentials.isSurpressed ) then
			
		local enable 
		if force == nil then
			enable = not ( self.driveControl.fourWDandDifferentials.diffLockBack )
		else
			enable = force
		end
		
		self.driveControl.fourWDandDifferentials.diffLockBack = enable
		driveControlInputEvent.sendEvent(self)
	end

end

--**********************************************************************************************************	
-- toggleMotorIsStarted
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleMotorIsStarted( force )

	if     self.dCcheckModule == nil
			or self.driveControl  == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod ZZZ_driveControl is missing!" )
		return 
	end
				
	local enable 
	if force == nil then
		enable = not ( self.isMotorStarted )
	else
		enable = force
	end	
	
	if      self:dCcheckModule("manMotorStart") 
			and self.driveControl.manMotorStart ~= nil then
		self.driveControl.manMotorStart.isMotorStarted = enable
		driveControlInputEvent.sendEvent(self)
	end

end

--**********************************************************************************************************	
-- toggleHandBrake
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleHandBrake( force )

	if     self.dCcheckModule == nil
			or self.driveControl  == nil then
		LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod ZZZ_driveControl is missing!" )
		return 
	end
	
	if      self:dCcheckModule("handBrake") 
			and self.driveControl.handBrake ~= nil then
			
		local enable 
		if force == nil then
			enable = not ( self.driveControl.handBrake.isActive )
		else
			enable = force
		end
		
		self.driveControl.handBrake.isActive = enable
		driveControlInputEvent.sendEvent(self)
	end

end

--**********************************************************************************************************	
-- getHandBrake
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetHandBrake( force )

	if      self.dCcheckModule ~= nil
			and self.driveControl  ~= nil 
			and self:dCcheckModule("handBrake") 
			and self.driveControl.handBrake ~= nil
			and self.driveControl.handBrake.isActive then
		return true
	end
	
	return false
end

--**********************************************************************************************************	
-- toggleShuttleDirection
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsToggleShuttleDirection( force )

  if      self.mrGbMGetIsOnOff ~= nil 
			and self:mrGbMGetIsOnOff() then
		
		if force == nil then
			self:mrGbMSetReverseActive( not self:mrGbMGetReverseActive() )
		elseif force > 0 then
			self:mrGbMSetReverseActive( false )
			self:mrGbMSetNeutralActive( false ) 
		elseif force < 0 then
			self:mrGbMSetReverseActive( true )
			self:mrGbMSetNeutralActive( false ) 
		else
			self:mrGbMSetNeutralActive( true ) 
		end
		
	else
		if     self.dCcheckModule == nil
				or self.driveControl  == nil then
			LinkToGlobalScripts.warning( "LinkToGlobalScripts: mod ZZZ_driveControl is missing!" )
			return 
		end
		
		if      self:dCcheckModule("shuttle")
				and self.driveControl.shuttle ~= nil 
				and self.driveControl.shuttle.isActive then
				
			local enable = 0
			if force == nil then
				enable = -self.driveControl.shuttle.direction
			elseif force > 0 then
				enable = 1.0
			elseif force < 0 then
				enable = 1.0
			end

			if enable == 0 then
				if      self:dCcheckModule("handBrake") 
						and self.driveControl.handBrake ~= nil then
					self.driveControl.handBrake.isActive = true
				end
			else
				if      self:dCcheckModule("handBrake") 
						and self.driveControl.handBrake ~= nil then
					self.driveControl.handBrake.isActive = false
				end
				self.driveControl.shuttle.direction = enable
			end
			driveControlInputEvent.sendEvent(self)
		end
	end
end

--**********************************************************************************************************	
-- getShuttleDirection
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsGetShuttleDirection( force )

  if      self.mrGbMGetIsOnOff ~= nil 
			and self:mrGbMGetIsOnOff() then
		
		if     self:mrGbMGetNeutralActive() then
			return 0 
		elseif self:mrGbMGetReverseActive() then
			return -1
		else
			return 1
		end
		
	elseif self:l2gsGetHandBrake() then
		return 0
	elseif  self.dCcheckModule ~= nil
			and self.driveControl  ~= nil 
			and self:dCcheckModule("shuttle") 
			and self.driveControl.shuttle ~= nil
			and self.driveControl.shuttle.isActive then
		return self.driveControl.shuttle.direction
	end
	
	return self.movingDirection
end

--**********************************************************************************************************	
-- drawShuttleToggleButton
--**********************************************************************************************************	
function LinkToGlobalScripts:l2gsDrawShuttleDirection()
  if      self.mrGbMGetIsOnOff ~= nil 
			and self:mrGbMGetIsOnOff() 
			and InputBinding.mrGearboxMogliREVERSE ~= nil then
		
		local textId
		if self:mrGbMGetReverseActive() then
			textId = "mrGearboxMogliGEARFWD"
		else
			textId = "mrGearboxMogliGEARBACK"
		end
		if not g_i18n:hasText( textId ) then
			textId = "mrGearboxMogliREVERSE"
		end
		if g_i18n:hasText( textId ) then
			g_currentMission:addHelpButtonText(g_i18n:getText( textId ), InputBinding.mrGearboxMogliREVERSE);
		end
	elseif  self.dCcheckModule ~= nil 
			and self.driveControl  ~= nil
			and self:dCcheckModule("shuttle")
			and self.driveControl.shuttle.isActive then
		if self.driveControl.shuttle.direction > 0 then
			g_currentMission:addHelpButtonText(g_i18n:getText("driveControlShuttle"), InputBinding.driveControlShuttle);
		else
			g_currentMission:addHelpButtonText(g_i18n:getText("driveControlShuttle"), InputBinding.driveControlShuttle);
		end;
	end;

end

--**********************************************************************************************************	
-- LinkToGlobalScriptsTest 
--**********************************************************************************************************	
function LinkToGlobalScripts:LinkToGlobalScriptsTest()
	local self = g_currentMission.controlledVehicle
	
	for n,f in pairs( LinkToGlobalScripts ) do
		if type(f) == "function" and string.sub( n, 1, 4 ) == "l2gs" then
			print("Calling "..tostring(n).."...")
			local state, result = pcall( f, self )
			if state then
				print("Result of "..tostring(n)..": "..tostring(result))
			else
				print("Failed: "..tostring(result))
			end
		end
	end
end

if LinkToGlobalScripts.debug then
	addConsoleCommand("LinkToGlobalScriptsTest", "Call all functions of LinkToGlobalScripts", "LinkToGlobalScriptsTest", LinkToGlobalScripts);
end

