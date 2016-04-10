--
-- rotation2Animation
--
-- author: mogli
-- date: 28.05.2015


rotation2Animation = {};

function rotation2Animation.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations);
end;

function rotation2Animation:load(xmlFile)
	
	self.rotation2Animations = {};
	local i=0;
  while true do
    local areaKey = string.format("vehicle.rotation2Animation.rotation(%d)", i);
		
    local rotation = {};
		rotation.animation     = getXMLString(xmlFile, areaKey .. "#animation")

		if rotation.animation == nil then			
      break;
    end

		rotation.invert        = Utils.getNoNil(getXMLBool(xmlFile, areaKey .. "#invert"),false);
		rotation.startAngle    = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, areaKey .. "#startAngle"),0))
		local endAngle         = getXMLFloat(xmlFile, areaKey .. "#endAngle")
		if endAngle == nil then
			rotation.endAngle    = rotation.startAngle + math.pi + math.pi
			rotation.normFactor  = 1.0 / ( math.pi + math.pi )
		else
			rotation.endAngle    = math.rad( endAngle )
			local d = rotation.endAngle - rotation.startAngle
			if math.abs( d ) > 1E-4 then
				rotation.normFactor  = 1.0 / d
			else
				rotation.normFactor  = 0.0 
			end 
		end 
		
		rotation.rotationNode  = Utils.indexToObject(self.components, getXMLString(xmlFile, areaKey .. "#rotationIndex"));	
		if rotation.rotationNode ~= nil then
			rotation.referenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, areaKey .. "#referenceIndex"));	
			rotation.axis          = Utils.getNoNil( getXMLInt(xmlFile, areaKey .. "#rotationAxis"), 1 );
		end
		rotation.playSound = Utils.getNoNil(getXMLBool(xmlFile, areaKey .. "#playSound"),false);
		rotation.immediate = Utils.getNoNil(getXMLBool(xmlFile, areaKey .. "#immediate"),true);
		
    i = i + 1;
		self.rotation2Animations[i] = rotation;		
  end
	
	if self.isClient then
		self.rotation2AnimationSample = Utils.loadSample(xmlFile, {}, "vehicle.rotation2AnimationSound", nil, self.baseDirectory)
	end
end;

function rotation2Animation:withSound( )
	if self.isClient and self.rotation2AnimationSample ~= nil and self.rotation2AnimationSample.sample ~= nil then
		return true
	end
	return false
end

function rotation2Animation:delete()
	if rotation2Animation.withSound( self ) then
		pcall( Utils.deleteSample, self.rotation2AnimationSample )
		self.rotation2AnimationSample = nil
	end	
end;

function rotation2Animation:mouseEvent(posX, posY, isDown, isUp, button)
end;

function rotation2Animation:keyEvent(unicode, sym, modifier, isDown)
end;

function rotation2Animation:updateTick(dt)	
end;


function rotation2Animation:update(dt)
	local playSound = false
	
	if self:getIsActive() then
		for _,rotation in pairs(self.rotation2Animations) do
			local curAnimTime = self:getAnimationTime( rotation.animation )
			local tgtAnimTime = curAnimTime
			
			local angle = nil
			if rotation.rotationNode ~= nil then
			-- rotation of node inside the vehicle
				angle = rotation.startAngle
				
				if rotation.referenceNode == nil then
					local r = { getRotation( rotation.rotationNode ) }
					angle = r[rotation.axis]
				elseif rotation.axis == 2 then
					angle = Utils.getYRotationBetweenNodes(rotation.rotationNode, rotation.referenceNode)
				else
					print("Cannot calculate rotation between nodes for axis: "..tostring(rotation.axis))
				end
				
				angle = angle - rotation.startAngle
				
				while angle > math.pi + math.pi + 1E-4	do
					angle = angle - math.pi - math.pi
				end
				while angle < -1E-4 do
					angle = angle + math.pi + math.pi
				end
			elseif self.attacherVehicle ~= nil then
			-- angle between vehicle and attached implement				
				angle     = Utils.getYRotationBetweenNodes(self.steeringAxleNode, self.attacherVehicle.steeringAxleNode) - rotation.startAngle
			end
			
			if angle == nil then
				tgtAnimTime = 0.5
			elseif rotation.invert then
				tgtAnimTime = Utils.clamp( 1 - angle * rotation.normFactor, 0, 1 )
			else
				tgtAnimTime = Utils.clamp( angle * rotation.normFactor, 0, 1 )
			end
			
			--if math.abs( curAnimTime - tgtAnimTime ) > 0.001 then
			--	if angle == nil then
			--		angle = -999
			--	else
			--		angle = math.deg( angle )
			--	end
			--	print(string.format("%s, %d:, %3.1f => %1.3f (%1.3f); [%3.1f .. %3.1f]", rotation.animation, rotation.axis, angle, tgtAnimTime, curAnimTime, math.deg(rotation.startAngle), math.deg(rotation.endAngle) ))
			--end
			
			if rotation.immediate then
				self:setAnimationTime( rotation.animation, tgtAnimTime, true )
			else
				local dir = 0
				if     tgtAnimTime < curAnimTime then
					dir = -1
				elseif tgtAnimTime > curAnimTime then
					dir = 1
				end
				
				if dir ~= 0 then
					self:playAnimation(rotation.animation, dir, curAnimTime, true);
					self:setAnimationStopTime(rotation.animation, tgtAnimTime );
				end
			end
			
			if      rotation2Animation.withSound( self )
					and not ( playSound )
					and rotation.playSound 
					and math.abs( curAnimTime - tgtAnimTime ) > 0.01 then
				playSound = true
			end
		end;
	end;
	
	if rotation2Animation.withSound( self ) then
		if playSound then
			if not self.rotation2AnimationSample.isPlaying and self.getIsActiveForSound(self) then
				Utils.playSample( self.rotation2AnimationSample, 0, 0, nil)
			end
		elseif self.rotation2AnimationSample.isPlaying then
			Utils.stopSample( self.rotation2AnimationSample, true)
		end
	end
end;


function rotation2Animation:draw()
	
end;


function rotation2Animation:onDeactivate()
	
end;

function Cylindered:onDeactivateSounds()
	if rotation2Animation.withSound( self ) and self.rotation2AnimationSample.isPlaying then
		Utils.stopSample( self.rotation2AnimationSample, true )
	end
end
