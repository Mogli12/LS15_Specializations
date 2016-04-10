
_G[g_currentModName..".mogliBase"].newClass( "ComplexSteeringVehicle", "complexSteeringVehicle" )

function ComplexSteeringVehicle.prerequisitesPresent(specializations)
	return  SpecializationUtil.hasSpecialization(Steerable, specializations)
			and SpecializationUtil.hasSpecialization(ComplexSteeringBase, specializations)
end

function ComplexSteeringVehicle:load(xmlFile)
	self.isSelectable                         = true
	self.complexSteeringVehicle               = {}
	self.complexSteeringVehicle.modes         = {}
	
	ComplexSteeringVehicle.registerState( self, "mode", Utils.getNoNil( getXMLInt( xmlFile, "vehicle.complexSteering#defaultMode" ), 1 ), ComplexSteeringVehicle.onSetComplexSteeringVehicleModeNumber, true )
 
	ComplexSteeringVehicle.registerState( self, "curShift", 0, nil, true )
	self.complexSteeringVehicle.enableRotAnim = false
	
	self.complexSteeringBase.aiTurnMode = getXMLInt( xmlFile, "vehicle.complexSteering#aiTurnMode")
	
	i = 0
	while true do
		local baseName = string.format("vehicle.complexSteering.mode(%d)", i)
		if not hasXMLProperty(xmlFile, baseName) then
			break
		end		
		i = i + 1
		
		local mode = {}
		
		mode.nameTextId          = getXMLString( xmlFile, baseName.."#textID" )
		mode.extraTextId         = getXMLString( xmlFile, baseName.."#extraTextID" )
		mode.speedLimit          = Utils.getNoNil( getXMLFloat( xmlFile, baseName.."#speedLimit" ), math.huge )
		mode.baseRot             = getXMLFloat( xmlFile, baseName.."#rotation" )
		mode.baseTrans           = getXMLFloat( xmlFile, baseName.."#translation" )

		mode.minRot              = getXMLFloat( xmlFile, baseName.."#minRotation" )
		mode.maxRot              = getXMLFloat( xmlFile, baseName.."#maxRotation" )

		mode.minTrans            = getXMLFloat( xmlFile, baseName.."#minTranslation" )
		mode.maxTrans            = getXMLFloat( xmlFile, baseName.."#maxTranslation" )

		mode.steeringRotFactor   = Utils.getNoNil( getXMLFloat( xmlFile, baseName.."#steeringRotation" ), 0 ) 
		mode.steeringTransFactor = Utils.getNoNil( getXMLFloat( xmlFile, baseName.."#steeringTranslation" ), 0 ) 
		
		local radius             = getXMLFloat( xmlFile, baseName.."#steeringRadius" )
		if     radius == nil then
			mode.steeringRadiusFactor = 1 / 7.5 
		elseif radius > 1e-4 then
			mode.steeringRadiusFactor = 1 / radius 
		else
			mode.steeringRadiusFactor = 0
		end
		
		mode.speedTransDelta     = Utils.getNoNil( getXMLFloat( xmlFile, baseName.."#speedTranslation" ), 0 ) 
		mode.speedTransFactor    = Utils.getNoNil( getXMLFloat( xmlFile, baseName.."#speedTranslationFactor" ), 0 ) 
		mode.speedTransOffset    = Utils.getNoNil( getXMLFloat( xmlFile, baseName.."#speedTranslationOffset" ), 20 ) 
		
		table.insert( self.complexSteeringVehicle.modes, mode )
	end	
	
	self.setComplexSteeringVehicleModeNumber = ComplexSteeringVehicle.setComplexSteeringVehicleModeNumber
	self.setComplexSteeringVehicleModeId     = ComplexSteeringVehicle.setComplexSteeringVehicleModeId
	self.getComplexSteeringVehicleModeId     = ComplexSteeringVehicle.getComplexSteeringVehicleModeId
	
end

function ComplexSteeringVehicle:postLoad(xmlFile)

	self.complexSteeringVehicle.minShift     = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#minTranslation" ), self.complexSteeringBase.zMin )
	self.complexSteeringVehicle.maxShift     = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#maxTranslation" ), self.complexSteeringBase.zMax )

	ComplexSteeringVehicle.registerState( self, "curCrabAngle", self.complexSteeringBase.dfltCrabAngle, nil, true )
end

function ComplexSteeringVehicle:update(dt)
	
	if self:getIsActiveForInput(true) and Input.isKeyPressed(Input.KEY_lshift) then
		if Input.isKeyPressed(Input.KEY_j) then
			ComplexSteeringVehicle.mbSetState( self, "curShift", ComplexSteeringBase.moveValue( self.complexSteeringVehicle.curShift, self.complexSteeringVehicle.maxShift, dt, 0.001 ) )
		end		
		if Input.isKeyPressed(Input.KEY_n) then
			ComplexSteeringVehicle.mbSetState( self, "curShift", ComplexSteeringBase.moveValue( self.complexSteeringVehicle.curShift, self.complexSteeringVehicle.minShift, dt, 0.001 ) )
		end
		if Input.isKeyPressed(Input.KEY_k) then
			ComplexSteeringVehicle.mbSetState( self, "curShift", ComplexSteeringBase.moveValue( self.complexSteeringVehicle.curCrabAngle,self.complexSteeringBase.maxCrabAngle, dt, 0.0001 ) )
		end		
		if Input.isKeyPressed(Input.KEY_m) then 
			ComplexSteeringVehicle.mbSetState( self, "curShift", ComplexSteeringBase.moveValue( self.complexSteeringVehicle.curCrabAngle,self.complexSteeringBase.minCrabAngle, dt, 0.0001 ) )
		end
	end

	if self:getIsActiveForInput(false) then	
		if ComplexSteeringVehicle.mbHasInputEvent( "ComplexSteeringVehicle" ) then
			self:setComplexSteeringVehicleModeNumber( self.complexSteeringVehicle.mode + 1 )
		end
	end

	local mode
	
	if      self.complexSteeringBase.aiTurnMode ~= nil
			and self.isAITractorActivated
			and self.turnStage > 0 then
		mode = self.complexSteeringVehicle.modes[self.complexSteeringBase.aiTurnMode]
	else
		mode = self.complexSteeringVehicle.modes[self.complexSteeringVehicle.mode]
	end
	if mode == nil then
		self.complexSteeringVehicle.mode = 1
		mode = self.complexSteeringVehicle.modes[1]
	end			
	
--if self.complexSteeringVehicle.mode == 3 or self.complexSteeringVehicle.mode == 4 then
--	local m = ComplexSteeringVehicle.getMaxCrabAngleOfTrailer( self )
--	if m ~= nil and m < math.rad(1) then
--		if self.complexSteeringVehicle.enableFreeMode then
--			self.complexSteeringVehicle.mode = 5
--		else
--			self.complexSteeringVehicle.mode = 0
--		end
--		self.complexSteeringVehicle.warningTimer = g_currentMission.time + 5000
--	end
--end
--
--if self.complexSteeringVehicle.warningTimer ~= nil and g_currentMission.time < self.complexSteeringVehicle.warningTimer then
--	g_currentMission:addWarning( g_i18n:getText("XerionSteerV2Warning"), 0.018, 0.033)
--end
	
	local steering   = 0
	if     self.rotatedTime > 0 and self.maxRotTime > 0 then
		steering =  self.rotatedTime / self.maxRotTime
	elseif self.rotatedTime < 0 and self.minRotTime < 0 then
		steering = -self.rotatedTime / self.minRotTime
	end
		
	local tz0, ry0 = 0, 0
	if mode.baseTrans == nil then
		tz0 = self.complexSteeringVehicle.curShift
	else
		tz0 = mode.baseTrans 
	end
	if mode.baseRot == nil then
		ry0 = self.complexSteeringVehicle.curCrabAngle
	else
		ry0 = mode.baseRot 
	end
	
	sp  = Utils.clamp( ( self.lastSpeed * 3600 - mode.speedTransOffset ) * mode.speedTransFactor, 0, 1 )
	tz0 = tz0 + sp * mode.speedTransDelta
	
	ry0 = ry0 + steering * mode.steeringRotFactor * self.complexSteeringBase.rMax
	tz0 = tz0 + steering * mode.steeringTransFactor 	
	
	if mode.minTrans ~= nil and tz0 < mode.minTrans then tz0 = mode.minTrans end
	if mode.maxTrans ~= nil and tz0 > mode.maxTrans then tz0 = mode.maxTrans end
	
	if mode.minRot   ~= nil and ry0 < mode.minRot   then ry0 = mode.minRot   end
	if mode.maxRot   ~= nil and ry0 > mode.maxRot   then ry0 = mode.maxRot   end
		
	tz0 = Utils.clamp( tz0, self.complexSteeringVehicle.minShift, self.complexSteeringVehicle.maxShift )
	local rMax = math.min( self:getMaxCrabAngle(), self.complexSteeringBase.maxCrabAngle )
	ry0 = Utils.clamp( ry0, -rMax, rMax )
	
	local invRadius =  steering * mode.steeringRadiusFactor

	self:setComplexSteering(  true,
														invRadius, 
														ry0, 
														tz0, 
														mode.speedLimit,
														self.complexSteeringVehicle.enableRotAnim )

	self.GPSangleOffSet = self.complexSteeringBase.crabAngle
	--self.GPS_externalLRoffset = 0														
end

function ComplexSteeringVehicle:draw()
	local mode = self.complexSteeringVehicle.modes[self.complexSteeringVehicle.mode]
	if mode ~= nil and self:getIsActiveForInput(true) and InputBinding["ComplexSteeringVehicle"] ~= nil then
		if mode.nameTextId == nil then
			g_currentMission:addHelpButtonText(string.format("ComplexSteering: [%d]", self.complexSteeringVehicle.mode) , InputBinding.ComplexSteeringVehicle) 
		else
			g_currentMission:addHelpButtonText(g_i18n:getText(mode.nameTextId), InputBinding.ComplexSteeringVehicle) 
		end
	end
end

function ComplexSteeringVehicle:onSetComplexSteeringVehicleModeNumber( old, new, noEventSend )
	self.complexSteeringVehicle.mode = new
	local mode = self.complexSteeringVehicle.modes[self.complexSteeringVehicle.mode]
	if mode == nil then
		self.complexSteeringVehicle.mode = 1
		mode = self.complexSteeringVehicle.modes[1]
	end
	if mode.baseRot == nil then
		if     ( mode.maxRot ~= nil and math.abs( mode.maxRot ) < 1e-4 and self.complexSteeringVehicle.curCrabAngle > mode.maxRot )
				or ( mode.minRot ~= nil and math.abs( mode.minRot ) < 1e-4 and self.complexSteeringVehicle.curCrabAngle < mode.minRot ) then
			ComplexSteeringVehicle.mbSetState( self, "curCrabAngle", -self.complexSteeringVehicle.curCrabAngle, noEventSend )
		end
	end
	
	--if mode ~= nil then
	--	print(string.format("New mode: %s (%d)", g_i18n:getText(mode.nameTextId), self.complexSteeringVehicle.mode ))
	--else
	--	print("Invalid mode")
	--end
end

function ComplexSteeringVehicle:setComplexSteeringVehicleModeNumber( newNumber )
	if newNumber == nil or newNumber < 1 or newNumber > table.getn( self.complexSteeringVehicle.modes ) then	
		ComplexSteeringVehicle.mbSetState( self, "mode", 1 )
	else
		ComplexSteeringVehicle.mbSetState( self, "mode", newNumber )
	end
end

function ComplexSteeringVehicle:setComplexSteeringVehicleModeId( newTextId )
	for i,m in pairs( self.complexSteeringVehicle.modes ) do
		if m.nameTextId == newTextId then
			self:setComplexSteeringVehicleModeNumber( i )
			return 
		end
	end
	print("Invalid mode text ID: "..tostring(newTextId))	
end

function ComplexSteeringVehicle:getComplexSteeringVehicleModeId( )
	return self.complexSteeringVehicle.modes[self.complexSteeringVehicle.mode].nameTextId
end

