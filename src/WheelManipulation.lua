_G[g_currentModName..".mogliBase"].newClass( "WheelManipulation", "wheelManipulation" )

function WheelManipulation.prerequisitesPresent(specializations)
   return true
end;

function WheelManipulation:load(xmlFile)

	ComplexSteeringVehicle.registerState( self, "hideTwinWheels",     false, nil, true )
	ComplexSteeringVehicle.registerState( self, "wheelDoDeformation", false, nil, true )

	-- callbacks for IC control
	self.wheelManipulation = {}
	self.wheelManipulation.twinWheelsAreHidden = nil
	self.wheelManipulation.wheelDeformation    = 0
	self.wheelManipulation.wheelDeltaRadius    = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.wheelDeformation#deltaRadius" ), 0 )
	self.wheelManipulation.deformationSpeed    = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.wheelDeformation#timeMs" ), 5000 )
	self.wheelManipulation.normalPressure      = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.wheelDeformation#normalBar" ), 1.5 )
	self.wheelManipulation.deformationPressure = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.wheelDeformation#deformationBar" ), 0.7 )
	-- handbrake
	self.getWheelPressure = WheelManipulation.getWheelPressure
end;

function WheelManipulation:postLoad(xmlFile)
	for i,wheel in ipairs(self.wheels) do
		local wheelnamei = string.format("vehicle.wheels.wheel(%d)", i-1);
		if g_currentMission.tyreTrackSystem ~= nil and Utils.getNoNil(getXMLBool(xmlFile, wheelnamei .. "#hasTyreTracks"), false) then
			wheel.furrowDepth         = getXMLFloat(xmlFile, wheelnamei .. ".wheelManipulation#furrowDepth")
			wheel.fallSpeed           = Utils.getNoNil( getXMLFloat(xmlFile, wheelnamei .. ".wheelManipulation#fallSpeed"), 1000 )
			wheel.twinWheelIndex      = Utils.indexToObject(self.components, getXMLString(xmlFile, wheelnamei .. ".wheelManipulation#twinWheelIndex"));
			wheel.tyreTrackOffsetTwin = getXMLFloat(xmlFile, wheelnamei .. ".wheelManipulation#tyreTrackOffsetTwin")
			if wheel.tyreTrackOffsetTwin ~= nil then
				wheel.tyreTrackIndexTwin = g_currentMission.tyreTrackSystem:createTrack(wheel.width, Utils.getNoNil(getXMLInt(xmlFile, wheelnamei .. "#tyreTrackAtlasIndex"), 0));
			end
		end
		
		local k = 0
		while true do
			local xmlName = string.format("%s.deformationBones(%d)",wheelnamei,k )
			if not hasXMLProperty(xmlFile, xmlName) then
				break
			end						
			k = k + 1
			
			local angleOffset = math.rad(Utils.getNoNil( getXMLFloat(xmlFile, xmlName.."#angleOffset"), 0))
			local parentFrom  = Utils.getNoNil( getXMLInt(xmlFile, xmlName.."#parentFrom"), 1) - 1
			local nodeIndex   = getXMLString(xmlFile, xmlName .. "#grandParentIndex" )
			local grandParent = Utils.indexToObject(self.components, nodeIndex )
			local heightChild = Utils.getNoNil( getXMLInt( xmlFile, xmlName.."#heightChild" ), 2 ) - 1
			local widthFactor = Utils.getNoNil( getXMLFloat( xmlFile, xmlName .. "#widthFactor" ), 1 )
			local widthChild1 = Utils.getNoNil( getXMLInt( xmlFile, xmlName.."#widthChild1" ), 1 ) - 1
			local widthChild2 = Utils.getNoNil( getXMLInt( xmlFile, xmlName.."#widthChild2" ), 2 ) - 1
			
			--print(tostring(nodeIndex) .." ".. tostring(grandParent))
			
			if grandParent ~= nil then
				local count = Utils.getNoNil( getXMLInt(xmlFile, xmlName.."#parentTo"), getNumOfChildren( grandParent ) ) - parentFrom
				--print(tostring(parentFrom).." "..tostring(count).." "..tostring( getNumOfChildren( grandParent ) ) )
				
				for j=0,count-1 do
					local bone              = {}
					bone.angle              = angleOffset + j * 2 * math.pi / count
					bone.index              = getChildAt( getChildAt( grandParent, j+parentFrom ), heightChild )
					bone.currentFactor      = 1					
					bone.initialTranslation = { getTranslation( bone.index ) }
					bone.initialRotation    = { getRotation( bone.index ) }
					bone.initialRadius      = Utils.vector3Length( unpack( bone.initialTranslation ) )
					
					bone.widthFactor        = widthFactor
					bone.wIndex1            = getChildAt( bone.index, widthChild1 )
					
					if bone.wIndex1 ~= nil then
						bone.initialTranslation1 = { getTranslation( bone.wIndex1 ) }
					end
					
					bone.wIndex2            = getChildAt( bone.index, widthChild2 )
					
					if bone.wIndex2 ~= nil then
						bone.initialTranslation2 = { getTranslation( bone.wIndex2 ) }
					end
					
					if wheel.deformationBones == nil then
						wheel.deformationBones ={}
					end
					table.insert( wheel.deformationBones, bone )
					
					--print(string.format("%d %s %s %s", math.deg( bone.angle ), getName( bone.index ), getName( bone.wIndex1 ), getName( bone.wIndex2 ) ) )
				end
			end
		end
		
		if wheel.deformationBones == nil then
			j = 0
			while true do
				local xmlNameJ = string.format("%s.deformationBone(%d)",wheelnamei,j )
				if not hasXMLProperty(xmlFile, xmlNameJ) then
					break
				end						
				j = j + 1
								
				local bone = {}
				
				bone.angle = Utils.degToRad( getXMLFloat(xmlFile, xmlNameJ .. "#angle") )
				bone.index = Utils.indexToObject(self.components, getXMLString(xmlFile, xmlNameJ .. "#heightIndex") )
				if bone.index ~= nil and bone.angle ~= nil then
					bone.currentFactor      = 1					
					bone.initialTranslation = { getTranslation( bone.index ) }
					bone.initialRotation    = { getRotation( bone.index ) }
					bone.initialRadius      = Utils.vector3Length( unpack( bone.initialTranslation ) )
					
					bone.widthFactor        = Utils.getNoNil( getXMLFloat( xmlFile, xmlNameJ .. "#widthFactor" ), 1 )
					bone.wIndex1            = Utils.indexToObject(self.components, getXMLString(xmlFile, xmlNameJ .. "#widthIndex1") )
					if bone.wIndex1 == nil then
						bone.wIndex1 = getChildAt( bone.index, 0 )
					end
					
					if bone.wIndex1 ~= nil then
						bone.initialTranslation1 = { getTranslation( bone.wIndex1 ) }
					end
					
					bone.wIndex2 = Utils.indexToObject(self.components, getXMLString(xmlFile, xmlNameJ .. "#widthIndex2") )
					if bone.wIndex2 == nil then
						bone.wIndex2 = getChildAt( bone.index, 1 )
					end
					
					if bone.wIndex2 ~= nil then
						bone.initialTranslation2 = { getTranslation( bone.wIndex2 ) }
					end
					
					if wheel.deformationBones == nil then
						wheel.deformationBones ={}
					end
					table.insert( wheel.deformationBones, bone )
				end
			end
		end
	end
end

function WheelManipulation:delete()
	if g_currentMission.tyreTrackSystem ~= nil then
		for _,wheel in pairs(self.wheels) do
			if wheel.tyreTrackIndexTwin ~= nil then
				local tmp = wheel.tyreTrackIndexTwin
				wheel.tyreTrackIndexTwin = nil
				g_currentMission.tyreTrackSystem:destroyTrack( tmp );
			end
		end;
	end;

end;
function WheelManipulation:mouseEvent(posX, posY, isDown, isUp, button)
end;
function WheelManipulation:keyEvent(unicode, sym, modifier, isDown)
end;

function WheelManipulation:update(dt)

	if self:getIsActiveForInput( false ) then
		if      self.wheelManipulation.wheelDeltaRadius > 0
				and InputBinding.WheelDeformation ~= nil			
				and InputBinding.hasEvent(InputBinding.WheelDeformation) then
			WheelManipulation:mbSetState( self, "wheelDoDeformation", not self.wheelManipulation.wheelDoDeformation )
		end
	end 
	
	if self.isActive and not ( self.wheelManipulation.hideTwinWheels ) then
		if self.firstTimeRun then

			for _,wheel in ipairs(self.wheels) do
				if wheel.tyreTrackIndexTwin ~= nil then
					local color = nil;
					local wheelSpeed = 0;
					local wx, wy, wz = worldToLocal(wheel.node, getWorldTranslation(wheel.driveNode));
					wy = wy - wheel.radius;
					wx = wx + wheel.xoffset + wheel.tyreTrackOffsetTwin
					wx, wy, wz = localToWorld(wheel.node, wx,wy,wz);

					if self.isServer then
						wheelSpeed = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape);
					else
						wheelSpeed = 1; -- TODO: Calculate wheelSpeed on client
					end;

					if wheel.contact == Vehicle.WHEEL_GROUND_CONTACT then
						local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, wx,wz);
						if densityBits == 0 then
							if GS_IS_OLD_GEN then
								color = {0.157, 0.153, 0.149, 0};
							else
								color = {getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, wx,wy,wz)};
							end
						else
							color = {Utils.getTyreTrackColorFromDensityBits(densityBits)};
						end;
					elseif wheel.contact == Vehicle.WHEEL_OBJ_CONTACT then
						if wheel.dirtAmount > 0 then
							color = wheel.lastColor;
							color[4] = 0; -- no depth to tyre tracks on road etc.
						end;
					end;

					if color ~= nil then
						local ux,uy,uz = localDirectionToWorld(self.rootNode, 0,1,0);
						-- we are using dirtAmount as alpha value -> realistic dirt fadeout
						g_currentMission.tyreTrackSystem:addTrackPoint(wheel.tyreTrackIndexTwin, wx, wy, wz, ux, uy, uz, color[1], color[2], color[3], wheel.dirtAmount, color[4], wheelSpeed);
					else
						g_currentMission.tyreTrackSystem:cutTrack(wheel.tyreTrackIndexTwin);
					end;
				end
			end;	
		end
	else
		if g_currentMission.tyreTrackSystem ~= nil then
			for _,wheel in ipairs(self.wheels) do
				if wheel.tyreTrackIndexTwin ~= nil then
					g_currentMission.tyreTrackSystem:cutTrack(wheel.tyreTrackIndexTwin)
				end
			end
		end
	end
	
end;

function WheelManipulation:setWheelParameter( index, rDelta, wDelta )

	if self.wheels[index].originalRadius == nil then 
		self.wheels[index].originalRadius = self.wheels[index].radius
		self.wheels[index].deltaX         = 0
	end
	
	local radius = self.wheels[index].originalRadius - rDelta 
	local deltaX = 0
	if     self.wheels[index].positionX < 0 then
		deltaX = -wDelta
	elseif self.wheels[index].positionX > 0 then
		deltaX =  wDelta
	end
	
	local positionY = self.wheels[index].positionY + self.wheels[index].deltaY;

	if self.isServer then
		if math.abs( self.wheels[index].radius - radius )  > 1e-3 then
			local collisionMask = 255 - 4; -- all up to bit 8, except bit 2 which is set by the players kinematic object
			self.wheels[index].wheelShape = createWheelShape(self.wheels[index].node, self.wheels[index].positionX, positionY, self.wheels[index].positionZ, radius, self.wheels[index].suspTravel, self.wheels[index].spring, self.wheels[index].damper, self.wheels[index].mass, collisionMask, self.wheels[index].wheelShape);
		end

		if math.abs( self.wheels[index].deltaX - deltaX )  > 1e-3 then
			local forcePointY = positionY - radius * self.wheels[index].forcePointRatio;
			setWheelShapeForcePoint(self.wheels[index].node, self.wheels[index].wheelShape, self.wheels[index].positionX + deltaX, forcePointY, self.wheels[index].positionZ);
		end
	end

	self.wheels[index].radius = radius	
	self.wheels[index].deltaX = deltaX
end

function WheelManipulation:updateTick(dt)

	local tgtDeformation = 0
	if self.wheelManipulation.wheelDoDeformation then
		tgtDeformation = self.wheelManipulation.wheelDeltaRadius
	end
	local speed = self.wheelManipulation.wheelDeltaRadius * dt / self.wheelManipulation.deformationSpeed
	
	self.wheelManipulation.wheelDeformation = self.wheelManipulation.wheelDeformation + Utils.clamp( tgtDeformation - self.wheelManipulation.wheelDeformation, -speed, speed ) 

	if     self.wheelManipulation.twinWheelsAreHidden == nil
			or self.wheelManipulation.twinWheelsAreHidden ~= self.wheelManipulation.hideTwinWheels then
		self.wheelManipulation.twinWheelsAreHidden = self.wheelManipulation.hideTwinWheels
		for i,wheel in pairs( self.wheels ) do
			if wheel.twinWheelIndex ~= nil then
				setVisibility( wheel.twinWheelIndex, not( self.wheelManipulation.twinWheelsAreHidden ) )
			end
		end
	end

	local deltaW = 0.97
	if self.wheelManipulation.hideTwinWheels then
		deltaW = 0
	end
	for i,wheel in pairs( self.wheels ) do
		local deltaR = 0
		if self.wheelManipulation.hideTwinWheels and wheel.furrowDepth ~= nil then
			local x,y,z = getWorldTranslation( wheel.driveNode )
			local w     = 0.3 * Utils.getNoNil( wheel.width, wheel.radius * 0.8)
			local d     = Utils.getDensity(g_currentMission.terrainDetailId, g_currentMission.ploughChannel, x+w, z+w, x-w, z+w, x+w, z-w);
			local dr    = 0
			local dc    = 0
			if d > 0 then
				dr = wheel.furrowDepth
			end
			local dc = 0
			if wheel.originalRadius ~= nil then
				dc = wheel.originalRadius - wheel.radius
			end
			speed = dt / wheel.fallSpeed
			deltaR = dc + Utils.clamp( dr - dc, -speed, speed )
		end
		if deltaR < self.wheelManipulation.wheelDeformation then
			deltaR = self.wheelManipulation.wheelDeformation
		end
		
		WheelManipulation.setWheelParameter( self, i, deltaR, deltaW )
	end

end;

function WheelManipulation:getWheelPressure()
	if     self.wheelManipulation.wheelDeltaRadius <  1e-3 then
		return self.wheelManipulation.normalPressure
	elseif self.wheelManipulation.wheelDeformation <  1e-3 then
		return self.wheelManipulation.normalPressure
	elseif self.wheelManipulation.wheelDeformation >= self.wheelManipulation.wheelDeltaRadius then
		return self.wheelManipulation.deformationPressure
	end
	
	return self.wheelManipulation.normalPressure + ( self.wheelManipulation.deformationPressure - self.wheelManipulation.normalPressure ) * self.wheelManipulation.wheelDeformation / self.wheelManipulation.wheelDeltaRadius
end;

function WheelManipulation:draw()
end;

function WheelManipulation:updateWheelGraphicsAppend( wheel, x, y, z, xDrive )
	if      type( wheel.deformationBones )          == "table"
	    and table.getn( wheel.deformationBones )    >= 2
			and self.wheelManipulation                  ~= nil
			and self.wheelManipulation.wheelDeformation ~= nil then
		if self.wheelManipulation.wheelDeformation >  0 then
			local deltaW = math.pi / table.getn( wheel.deformationBones )
			local corrIR = 1 / math.cos( deltaW )
			for _,bone in pairs( wheel.deformationBones ) do
				local h1 = math.cos( bone.angle + xDrive - deltaW )
				local h2 = math.cos( bone.angle + xDrive + deltaW )
				local h  = 0.5 * ( h1 + h2 ) * bone.initialRadius
				local f  = 1
				if h + h > bone.initialRadius and h > bone.initialRadius - self.wheelManipulation.wheelDeformation then
					f = ( bone.initialRadius - self.wheelManipulation.wheelDeformation ) / h
				end
				if bone.currentFactor == nil or math.abs( bone.currentFactor - f ) > 1e-4 then
					bone.currentFactor = f
					setTranslation( bone.index, f * bone.initialTranslation[1], f * bone.initialTranslation[2], f * bone.initialTranslation[3] )
					
					local rotX = 0
					if f < 0.999 then
						local r1 = math.min( bone.initialRadius, ( bone.initialRadius - self.wheelManipulation.wheelDeformation ) / h1 )
						local r2 = math.min( bone.initialRadius, ( bone.initialRadius - self.wheelManipulation.wheelDeformation ) / h2 )
						
						local d1 = ( r2 + r1 ) * math.sin( deltaW )
						local d2 = ( r2 - r1 ) * math.cos( deltaW )
						
						local rotX = math.atan2( d2, d1 )
					end 
					setRotation( bone.index, bone.initialRotation[1] + rotX, bone.initialRotation[2], bone.initialRotation[3]  )
					
					f = 1 + bone.widthFactor * ( 1/f - 1 )
					if bone.wIndex1 ~= nil then
						setTranslation( bone.wIndex1, bone.initialTranslation1[1] * f, bone.initialTranslation1[2] * f, bone.initialTranslation1[3] * f )
					end
					if bone.wIndex2 ~= nil then
						setTranslation( bone.wIndex2, bone.initialTranslation2[1] * f, bone.initialTranslation2[2] * f, bone.initialTranslation2[3] * f )
					end
				end
			end
		else
			for _,bone in pairs( wheel.deformationBones ) do
				if bone.currentFactor == nil or math.abs( bone.currentFactor - 1 ) > 1e-4 then
					bone.currentFactor = 1
					setTranslation( bone.index, unpack( bone.initialTranslation ) )
					setRotation( bone.index, unpack( bone.initialRotation ) )
					if bone.wIndex1 ~= nil then
						setTranslation( bone.wIndex1, unpack( bone.initialTranslation1 ) )
					end
					if bone.wIndex2 ~= nil then
						setTranslation( bone.wIndex2, unpack( bone.initialTranslation2 ) )
					end
				end
			end
		end
	end
end
WheelsUtil.updateWheelGraphics = Utils.appendedFunction( WheelsUtil.updateWheelGraphics, WheelManipulation.updateWheelGraphicsAppend )
