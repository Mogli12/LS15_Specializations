
_G[g_currentModName..".mogliBase"].newClass( "ComplexSteeringTrailer", "complexSteeringTrailer" )

function ComplexSteeringTrailer.prerequisitesPresent(specializations)
	return  SpecializationUtil.hasSpecialization(Attachable, specializations)
			and SpecializationUtil.hasSpecialization(ComplexSteeringBase, specializations)
end

function ComplexSteeringTrailer:load(xmlFile)
	self.complexSteeringTrailer = {}
	self.complexSteeringTrailer.liftWheels      = { Utils.getVectorFromString(  getXMLString( xmlFile, "vehicle.complexSteering#liftWheels" ) ) }
	self.complexSteeringTrailer.liftTranslation = Utils.getVectorNFromString( getXMLString( xmlFile, "vehicle.complexSteering#liftTranslation" ), 3 )
	self.complexSteeringTrailer.liftAnimation   = getXMLString( xmlFile, "vehicle.complexSteering#liftAnimation" )
	if self.capacity ~= nil then
		self.complexSteeringTrailer.liftFillLevel = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#liftFillLevel" ), 0.65 * self.capacity )
	else
		self.complexSteeringTrailer.liftFillLevel = 0
	end
	self.complexSteeringTrailer.liftSpeed       = 1.0 / Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#liftTimeMs" ), 2000 )
	self.complexSteeringTrailer.liftMode        = 0
	self.complexSteeringTrailer.translation     = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#translation" ), 0 )
	self.complexSteeringTrailer.liftValue       = 0

	
	ComplexSteeringTrailer.registerState( self, "liftMode", 0, nil, true )
	ComplexSteeringTrailer.registerState( self, "curCrabAngle", 0, nil, true )	
end

function ComplexSteeringTrailer:update(dt)
	if  self:getIsActiveForInput( false ) then
		if InputBinding["ComplexSteeringTrailer"] ~= nil and InputBinding.hasEvent( InputBinding.ComplexSteeringTrailer ) then
			if     self.complexSteeringTrailer.curCrabAngle < -1e-4 then
				ComplexSteeringTrailer.mbSetState( self, "curCrabAngle", 0 )
			elseif self.complexSteeringTrailer.curCrabAngle >  1e-4 then
				ComplexSteeringTrailer.mbSetState( self, "curCrabAngle",-self.complexSteeringBase.dfltCrabAngle )
			else
				ComplexSteeringTrailer.mbSetState( self, "curCrabAngle", self.complexSteeringBase.dfltCrabAngle )
			end
		end
		if InputBinding["ComplexSteeringLiftAxis"] ~= nil and InputBinding.hasEvent( InputBinding.ComplexSteeringLiftAxis ) then
			if self.complexSteeringTrailer.liftMode < 2 then
				ComplexSteeringTrailer.mbSetState( self, "liftMode", self.complexSteeringTrailer.liftMode + 1 )
			else
				ComplexSteeringTrailer.mbSetState( self, "liftMode", 0 )
			end
		end
	end

	local crabAngle = self.complexSteeringTrailer.curCrabAngle
	local root = self:getRootAttacherVehicle( )
	if      root                               ~= nil 
			and root                               ~= self
			and root.complexSteeringBase           ~= nil 
			and root.complexSteeringBase.crabAngle ~= nil then
		crabAngle = root.complexSteeringBase.crabAngle
	end
	
	local invRadius = 0
	if      self.attacherVehicle    ~= nil 
			and self.attacherJoint      ~= nil 
			and self.attacherJoint.node ~= nil
			and (0 <= self.movingDirection or self.steeringAxleUpdateBackwards) then
		local yRot
		if root.complexSteeringBase == nil or self.attacherVehicle ~= root then
			yRot = Utils.getYRotationBetweenNodes(self.steeringAxleNode, self.attacherVehicle.steeringAxleNode) - crabAngle 
		else
			yRot = Utils.getYRotationBetweenNodes(self.complexSteeringBase.refNode, root.complexSteeringBase.refNode)
		end
		local node = self.attacherJoint.node
		local b1   = 1
		if self.attacherVehicle.complexSteeringBase ~= nil and self.attacherVehicle.complexSteeringBase.refNode ~= nil then
			b1       = math.abs( ComplexSteeringBase.getRelativeTranslation( self.attacherVehicle.complexSteeringBase.refNode, node ) )
		end
		local b2   = math.abs( ComplexSteeringBase.getRelativeTranslation( node, self.complexSteeringBase.refNode ) )
		invRadius  = math.sin(yRot) / ( b1 + b2 * math.cos( yRot ) )
	end
	
	self:setComplexSteering( true, 
													 invRadius, 
													 crabAngle, 
													 self.complexSteeringTrailer.translation, 
													 math.huge,
													 true )
																 
	local tgtLiftValue = 0
	if     self.complexSteeringTrailer.liftMode == 1 then
		tgtLiftValue = 1
	elseif self.complexSteeringTrailer.liftMode == 2 then
		tgtLiftValue = 0
	elseif  math.abs( self.complexSteeringBase.crabAngle ) < 1e-4
			and self.fillLevel <= self.complexSteeringTrailer.liftFillLevel then
		tgtLiftValue = 1
	end

	self.complexSteeringTrailer.liftValue = ComplexSteeringBase.moveValue( self.complexSteeringTrailer.liftValue, tgtLiftValue, dt, self.complexSteeringTrailer.liftSpeed )
		
	if      self.complexSteeringTrailer.liftAnimation ~= nil
			and self.setAnimationTime                     ~= nil
			and self.getAnimationTime                     ~= nil
			and math.abs( self:getAnimationTime( self.complexSteeringTrailer.liftAnimation ) - self.complexSteeringTrailer.liftValue ) < 1e-3 then
		self:setAnimationTime( self.complexSteeringTrailer.liftAnimation, self.complexSteeringTrailer.liftValue, true);
	end
end

function ComplexSteeringTrailer:draw()
	if self:getIsActiveForInput(true) then
		if self.complexSteeringBase.maxCrabAngle > 1e-4 and InputBinding["ComplexSteeringTrailer"] ~= nil then
			g_currentMission:addHelpButtonText(g_i18n:getText("ComplexSteeringTrailer"),  InputBinding.ComplexSteeringTrailer) 
		end
		if ( self.complexSteeringTrailer.liftAnimation ~= nil or self.complexSteeringTrailer.liftWheels ~= nil ) and InputBinding["ComplexSteeringLiftAxis"] ~= nil then
			g_currentMission:addHelpButtonText(g_i18n:getText("ComplexSteeringLiftAxis"), InputBinding.ComplexSteeringLiftAxis) 
		end
	end
end

function ComplexSteeringTrailer:newUpdateWheelGraphics( superFunc, wheel, x, y, z, xDrive )
	if     self.complexSteeringTrailer                 == nil
			or self.complexSteeringTrailer.liftWheels      == nil
			or self.complexSteeringTrailer.liftTranslation == nil then
		return superFunc( self, wheel, x, y, z, xDrive )
	end
	
	for _,w in pairs( self.complexSteeringTrailer.liftWheels ) do
		if wheel.xmlIndex+1 == w then
			if wheel.cstRotMin == nil then
				wheel.cstRotMin  = wheel.rotMin 
				wheel.cstRotMax  = wheel.rotMax 
				wheel.cstAxlwMin = wheel.steeringAxleRotMin
				wheel.cstAxleMax = wheel.steeringAxleRotMax		
			end
			local ly = wheel.positionY + self.complexSteeringTrailer.liftTranslation[2]
			local cy = math.min( y, wheel.positionY )
			ly = cy + ( ly - cy ) * self.complexSteeringTrailer.liftValue
			if self.complexSteeringTrailer.liftValue > 0.01 and ly > y then
				y = ly
				x = wheel.positionX + self.complexSteeringTrailer.liftTranslation[1] * self.complexSteeringTrailer.liftValue
				z = wheel.positionZ + self.complexSteeringTrailer.liftTranslation[3] * self.complexSteeringTrailer.liftValue
				xDrive = 0 
				wheel.rotMin             = 0
				wheel.rotMax             = 0
				wheel.steeringAxleRotMin = 0
				wheel.steeringAxleRotMax = 0	
			else
				wheel.rotMin             = wheel.cstRotMin 
				wheel.rotMax             = wheel.cstRotMax 
				wheel.steeringAxleRotMin = wheel.cstAxlwMin
				wheel.steeringAxleRotMax = wheel.cstAxleMax	
			end
			break
		end
	end
	
	return superFunc( self, wheel, x, y, z, xDrive )
end
			
	

WheelsUtil.updateWheelGraphics = Utils.overwrittenFunction( WheelsUtil.updateWheelGraphics, ComplexSteeringTrailer.newUpdateWheelGraphics )
