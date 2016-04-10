--
-- ComplexSteeringBase
--
-- author: mogli
-- date: 30.12.2015

_G[g_currentModName..".mogliBase"].newClass( "ComplexSteeringBase", "complexSteeringBase" )

function ComplexSteeringBase.prerequisitesPresent(specializations)
	return true
end

function ComplexSteeringBase:load(xmlFile)
	self.complexSteeringBase                  = {}
	self.complexSteeringBase.rotAnimation  = getXMLString( xmlFile, "vehicle.complexSteering#rotationAnimation")
	self.complexSteeringBase.rotJointIndex = { Utils.getVectorFromString(  getXMLString( xmlFile, "vehicle.complexSteering#rotationJointIndex" ) ) }
	self.complexSteeringBase.dfltCrabAngle = Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#defaultCrabAngle" ), math.rad( 10 ) )
	self.complexSteeringBase.transSpeed    = 1 / Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#translationTimeMs" ), 500 )
	self.complexSteeringBase.rotSpeed      = 1 / Utils.getNoNil( getXMLFloat( xmlFile, "vehicle.complexSteering#rotationTimeMs" ), 500 )
	self.complexSteeringBase.crabAngle     = 0
	self.complexSteeringBase.curCrabAngle  = 0
	self.complexSteeringBase.zTrans        = 0
	self.complexSteeringBase.invRadius     = 0
	self.complexSteeringBase.speedLimit    = math.huge
	self.complexSteeringBase.aiDistance    = getXMLFloat( xmlFile, "vehicle.complexSteering#aiDistance" )

	self.complexSteeringBase.baseNode      = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.complexSteering#baseIndex"))
	if self.complexSteeringBase.baseNode ~= nil then
		self.complexSteeringBase.refNode     = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.complexSteering#referenceIndex"))
	else	
		local refNode  = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTractorDirectionNode#index"))
		if refNode == nil then
			refNode  = self.steeringAxleNode
		end
	
		self.complexSteeringBase.baseNode = createTransformGroup( "xsv2BaseNode" )
		link( refNode, self.complexSteeringBase.baseNode )
	end
	
	if      self.complexSteeringBase.refNode              ~= nil 
			and getParent( self.complexSteeringBase.refNode ) ~= self.complexSteeringBase.baseNode then
		print("ERROR: complexSteering#referenceIndex is not child of complexSteering#baseIndex")
		self.complexSteeringBase.refNode = nil
	end

	if self.complexSteeringBase.refNode == nil then
		self.complexSteeringBase.refNode  = createTransformGroup( "xsv2RefNode" )
		link( self.complexSteeringBase.baseNode, self.complexSteeringBase.refNode )
	end	
end

function ComplexSteeringBase:postLoad(xmlFile)

	
	local na, xa, zf, zr, nf, nr
	
	for _,wheel in pairs(self.wheels) do
		local temp1 = { getRotation(wheel.driveNode) }
		local temp2 = { getRotation(wheel.repr) }
		setRotation(wheel.driveNode, 0, 0, 0)
		setRotation(wheel.repr, 0, 0, 0)
		local x,y,z = ComplexSteeringBase.getRelativeTranslation(self.complexSteeringBase.baseNode,wheel.driveNode);
		setRotation(wheel.repr, unpack(temp2))
		setRotation(wheel.driveNode, unpack(temp1))
		
		local r = math.min( math.max( wheel.rotMax, wheel.steeringAxleRotMax ), - math.min( wheel.rotMin, wheel.steeringAxleRotMin ) )
		
		if na == nil then
			na = 1
			xa = x
			self.complexSteeringBase.xMin = x
			self.complexSteeringBase.zMin = z
			self.complexSteeringBase.rMin = r
			self.complexSteeringBase.xMax = x
			self.complexSteeringBase.zMax = z
			self.complexSteeringBase.rMax = r
		else
			na = na + 1
			xa = xa + x
			self.complexSteeringBase.xMin = math.min( self.complexSteeringBase.xMin, x )
			self.complexSteeringBase.zMin = math.min( self.complexSteeringBase.zMin, z )
			self.complexSteeringBase.rMin = math.min( self.complexSteeringBase.rMin, r )
			self.complexSteeringBase.xMax = math.max( self.complexSteeringBase.xMax, x )
			self.complexSteeringBase.zMax = math.max( self.complexSteeringBase.zMax, z )
			self.complexSteeringBase.rMax = math.max( self.complexSteeringBase.rMax, r )
		end
		
		if r > 14-4 then
			if nr == nil then
				nr = 1
				zr = z
			else
				nr = nr + 1
				zr = zr + z
			end
		else
			if nf == nil then
				nf = 1
				zf = z
			else
				nf = nf + 1
				zf = zf + z
			end
		end			
	end
	
	self.complexSteeringBase.xAvg = xa / na
	
	if nf == nil then
		self.complexSteeringBase.zAvg = zr / nr
	else
		self.complexSteeringBase.zAvg = zf / nf
	end
	
	self.complexSteeringBase.xMin = self.complexSteeringBase.xMin - self.complexSteeringBase.xAvg 
	self.complexSteeringBase.zMin = self.complexSteeringBase.zMin - self.complexSteeringBase.zAvg 
	self.complexSteeringBase.xMax = self.complexSteeringBase.xMax - self.complexSteeringBase.xAvg 
	self.complexSteeringBase.zMax = self.complexSteeringBase.zMax - self.complexSteeringBase.zAvg 
	
	setTranslation( self.complexSteeringBase.baseNode, self.complexSteeringBase.xAvg, 0, self.complexSteeringBase.zAvg )

	self.getSpeedLimit      = Utils.overwrittenFunction( self.getSpeedLimit, ComplexSteeringBase.newGetSpeedLimit )
	self.getMaxCrabAngle    = ComplexSteeringBase.getMaxCrabAngle
	self.setComplexSteering = ComplexSteeringBase.setComplexSteering

	local mr = getXMLFloat( xmlFile, "vehicle.complexSteering#maxRotation" )
	if mr == nil then
		self.complexSteeringBase.maxCrabAngle = self.complexSteeringBase.rMax
	else
		self.complexSteeringBase.maxCrabAngle = math.rad( mr )
	end
	mr = getXMLFloat( xmlFile, "vehicle.complexSteering#minRotation" )
	if mr == nil then
		self.complexSteeringBase.minCrabAngle = -self.complexSteeringBase.maxCrabAngle
	else
		self.complexSteeringBase.minCrabAngle = math.rad( mr )
	end

	if      self.complexSteeringBase.rotAnimation ~= nil 
			and self.getAnimationDuration ~= nil
			and self.setAnimationTime     ~= nil
			and self.getAnimationTime     ~= nil then
		self:setAnimationTime( self.complexSteeringBase.rotAnimation, 0.5, true )			
	end
	
	if      self.aiTractorDirectionNode ~= nil
			and self.complexSteeringBase.aiDistance ~= nil then
		if getParent( self.aiTractorDirectionNode ) ~= self.complexSteeringBase.refNode then
			print("ERROR: aiTractorDirectionNode#index is not child of complexSteering#referenceIndex")
			self.complexSteeringBase.aiDistance = nil
		else
			self.complexSteeringBase.aiPosition = { getTranslation( self.aiTractorDirectionNode ) }
		end
	end
end

function ComplexSteeringBase:draw()
--local x,y,z = getWorldTranslation( self.complexSteeringBase.baseNode )
--
--drawDebugPoint( x,y,z, 1, 1, 1, 1 )
--drawDebugLine(  x,y-2,z, 1,0,0, x,y+8,z, 1,0,0 );
--
--x,y,z = getWorldTranslation( self.complexSteeringBase.refNode )
--
--drawDebugLine(  x,y-2,z+0.02, 0,1,0, x,y+8,z+0.02, 0,1,0 );
--
--local x1,y1,z1 = localToWorld( self.complexSteeringBase.refNode, 3, 0, 0 )
--
--drawDebugLine(  x,y,z, 0,0,1, x1,y1,z1, 0,0,1 );
end


function ComplexSteeringBase:postUpdate( dt )
	local rotAnimTime = 0.5
	if     self.complexSteeringBase     == nil 
			or self.complexSteeringBase.set == nil
			or not ( self.complexSteeringBase.set.enabled ) then
		self.complexSteeringBase.enabled    = false
		self.complexSteeringBase.invRadius  = 0
		self.complexSteeringBase.crabAngle  = 0
		self.complexSteeringBase.zTrans     = 0
	else
		self.complexSteeringBase.enabled    = true
		self.complexSteeringBase.invRadius  = ComplexSteeringBase.moveValue( self.complexSteeringBase.invRadius, self.complexSteeringBase.set.invRadius, dt, self.complexSteeringBase.rotSpeed * 0.2)    
		self.complexSteeringBase.crabAngle  = ComplexSteeringBase.moveValue( self.complexSteeringBase.crabAngle, self.complexSteeringBase.set.crabAngle, dt, self.complexSteeringBase.rotSpeed * math.max( self.complexSteeringBase.maxCrabAngle, -self.complexSteeringBase.minCrabAngle ) )
		self.complexSteeringBase.zTrans     = ComplexSteeringBase.moveValue( self.complexSteeringBase.zTrans, self.complexSteeringBase.set.zTrans, dt, self.complexSteeringBase.transSpeed )
		local _,ry,_ = getRotation( self.complexSteeringBase.refNode )
		if math.abs( ry - self.complexSteeringBase.crabAngle ) > 1e-4 then
			setRotation( self.complexSteeringBase.refNode, 0, self.complexSteeringBase.crabAngle, 0 )
			if self.complexSteeringBase.aiPosition ~= nil then
				local x, y, z = unpack( self.complexSteeringBase.aiPosition )
				x = x - self.complexSteeringBase.aiDistance * math.sin( self.complexSteeringBase.crabAngle )
				setTranslation( self.aiTractorDirectionNode, x, y, z )
			end
		end
		local _,_,tz = getTranslation( self.complexSteeringBase.refNode )
		if math.abs( tz - self.complexSteeringBase.zTrans ) > 1e-3 then
			setTranslation( self.complexSteeringBase.refNode, 0, 0, self.complexSteeringBase.zTrans )
		end
		
		if self.complexSteeringBase.set.enableRotAnim then
			rotAnimTime = 0.5 * ( 1 + self.complexSteeringBase.crabAngle / self.complexSteeringBase.maxCrabAngle )
		end
	end
	
	if      self.complexSteeringBase.rotJointIndex ~= nil
			and self.attacherJoints                    ~= nil then
		for _,i in pairs( self.complexSteeringBase.rotJointIndex ) do
			local rotateJoint = false
			for _, implement in pairs(self.attachedImplements) do
				if implement.object ~= nil and implement.jointDescIndex == i and self.attacherJoints[i] ~= nil then
					rotateJoint = true
					break
				end
			end
		
			if rotateJoint then
				local jointDesc = self.attacherJoints[i]
				local delta     = self.complexSteeringBase.crabAngle - 0.5 * ( jointDesc.minRot[2] + jointDesc.maxRot[2] )
				if math.abs(delta) > 1e-4 then
					jointDesc.minRot[2] = jointDesc.minRot[2] + delta
					jointDesc.maxRot[2] = jointDesc.maxRot[2] + delta
					
					if jointDesc.allowsLowering then
						local moveAlpha = Utils.getMovedLimitedValue(jointDesc.moveAlpha, jointDesc.lowerAlpha, jointDesc.upperAlpha, jointDesc.moveTime, dt, not jointDesc.moveDown);

						if moveAlpha ~= nil then
							jointDesc.moveAlpha = moveAlpha
							if jointDesc.rotationNode ~= nil then
								setRotation(jointDesc.rotationNode, Utils.vector3ArrayLerp(jointDesc.minRot, jointDesc.maxRot, jointDesc.moveAlpha));
							end
							if jointDesc.rotationNode2 ~= nil then
								setRotation(jointDesc.rotationNode2, Utils.vector3ArrayLerp(jointDesc.minRot2, jointDesc.maxRot2, jointDesc.moveAlpha));
							end
							jointDesc.jointFrameInvalid = true
						else
							print(tostring(jointDesc.moveAlpha).." "..tostring(jointDesc.lowerAlpha).." "..tostring(jointDesc.upperAlpha).." "..tostring(jointDesc.moveTime).." "..tostring(dt).." "..tostring(jointDesc.moveDown))
						end						
					end
				end
			end
		end
	end
	
	if      self.complexSteeringBase.rotAnimation ~= nil 
			and self.getAnimationDuration ~= nil
			and self.setAnimationTime     ~= nil
			and self.getAnimationTime     ~= nil then
		local curAnimTime = self:getAnimationTime( self.complexSteeringBase.rotAnimation )
		rotAnimTime = ComplexSteeringBase.moveValue( curAnimTime, rotAnimTime, dt, 1.0/math.max(0.01, self:getAnimationDuration( self.complexSteeringBase.rotAnimation ) ) )
		if math.abs( curAnimTime - rotAnimTime ) > 0.001 then
			self:setAnimationTime( self.complexSteeringBase.rotAnimation, rotAnimTime, true )						
		end
	end
end

function ComplexSteeringBase:setComplexSteering( enabled, invRadius, crabAngle, zTrans, speedLimit, enableRotAnim )
	self.complexSteeringBase.set         = {}
	self.complexSteeringBase.set.enabled = enabled
	
	if enabled then
		self.complexSteeringBase.speedLimit        = speedLimit 
		self.complexSteeringBase.set.invRadius     = invRadius
		self.complexSteeringBase.set.crabAngle     = crabAngle
		self.complexSteeringBase.set.zTrans        = zTrans
		self.complexSteeringBase.set.enableRotAnim = enableRotAnim
	end
end

function ComplexSteeringBase:delete()
	pcall( ComplexSteeringBase.delete2, self )
end

function ComplexSteeringBase:delete2()
	if self.complexSteeringBase ~= nil and self.complexSteeringBase.baseNode ~= nil then
		unlink( self.complexSteeringBase.refNode  )
		unlink( self.complexSteeringBase.baseNode )
		delete( self.complexSteeringBase.refNode  )
		delete( self.complexSteeringBase.baseNode )
	end
end

function ComplexSteeringBase:getMaxCrabAngle( vehicleOnly )

	local maxCrabAngle = nil

	if self.complexSteeringBase ~= nil then
		maxCrabAngle = self.complexSteeringBase.maxCrabAngle
	end
	
	if vehicleOnly or self.attachedImplements == nil then
		return maxCrabAngle
	end
	
	for _, implement in pairs(self.attachedImplements) do
		if      implement.object ~= nil
				and implement.complexSteeringBase ~= nil then
			-- attached implements of implements
			local m1 = implement.object:getMaxCrabAngle()
			if       m1 ~= nil 
					and ( maxCrabAngle == nil or maxCrabAngle > m1 ) then
				maxCrabAngle = m1
			end
		end
	end
	
	return maxCrabAngle
end

function ComplexSteeringBase:newUpdateWheelSteeringAngle(superFunc, wheel, dt)
	if     self.complexSteeringBase == nil 
			or not ( self.complexSteeringBase.enabled ) 
			or ( math.abs( wheel.rotSpeed )          <= 1E-4 
			 and math.abs( wheel.steeringAxleScale ) <= 1E-4 ) then
		return superFunc( self, wheel, dt )
	end
	
	local wx, wy, wz    = getWorldTranslation( wheel.driveNode )
	local x,  y,  z     = worldToLocal( self.complexSteeringBase.refNode, wx, wy, wz )
	local steeringAngle = Utils.clamp( self.complexSteeringBase.crabAngle, self.complexSteeringBase.minCrabAngle, self.complexSteeringBase.maxCrabAngle )
	
	if     math.abs( z ) >= 0.25 then
		steeringAngle  = steeringAngle + math.atan2( z * self.complexSteeringBase.invRadius, 1  - x * self.complexSteeringBase.invRadius )
	elseif self.complexSteeringBase.invRadius >= 0.01 then
		steeringAngle  = steeringAngle + math.atan2( z, 1/self.complexSteeringBase.invRadius  - x )
	elseif self.complexSteeringBase.invRadius <= -0.01 then
		steeringAngle  = steeringAngle + math.atan2( -z, -1/self.complexSteeringBase.invRadius  + x )
	end
		
	
	--if math.abs( self.complexSteeringBase.invRadius ) >= 0.01 then
	--	steeringAngle  = steeringAngle + math.atan2( z, 1/self.complexSteeringBase.invRadius  - x )
	--elseif math.abs(z)                   >= 0.25 then
	--	steeringAngle  = steeringAngle + math.atan2( z * self.complexSteeringBase.invRadius, 1  - x * self.complexSteeringBase.invRadius )
	--end
	
	if     math.abs( wheel.rotSpeed ) > 1E-4 then
		wheel.steeringAngle = Utils.clamp( steeringAngle, wheel.rotMin, wheel.rotMax )
	else
		wheel.steeringAngle = Utils.clamp( steeringAngle, wheel.steeringAxleRotMin, wheel.steeringAxleRotMax )
	end
end

WheelsUtil.updateWheelSteeringAngle  = Utils.overwrittenFunction( WheelsUtil.updateWheelSteeringAngle, ComplexSteeringBase.newUpdateWheelSteeringAngle )

function ComplexSteeringBase:newGetSpeedLimit(superFunc, ...)
	if self.complexSteeringBase == nil or not( self.complexSteeringBase.enabled ) or self.complexSteeringBase.speedLimit == nil then
		return superFunc( self, ... )
	end
	local r1, r2 = superFunc( self, ... )
	r1 = math.min( self.complexSteeringBase.speedLimit, r1 )
	return r1, r2
end


------------------------------------------------------------------------
-- getRelativeTranslation
------------------------------------------------------------------------
function ComplexSteeringBase.getRelativeTranslation(root,node)
	if root == nil or node == nil then
		return 0,0,0
	end
	local x,y,z;
	if getParent(node)==root then
		x,y,z = getTranslation(node);
	else
		x,y,z = worldToLocal(root,getWorldTranslation(node));
	end;
	return x,y,z;
end

function ComplexSteeringBase.moveValue( last, current, dt, speed )
	if current  == nil then
		return
	elseif last == nil or speed == nil or speed < 0 or dt == nil or dt < 0 then
		return current 
	elseif last < current then
		return math.min( last + speed * dt, current )
	elseif last > current then
		return math.max( last - speed * dt, current )
	end
	return current 
end

