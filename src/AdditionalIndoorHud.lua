--
-- AdditionalIndoorHud
-- Class for all AdditionalIndoorHuds
--
-- @author  Stefan Biedenstein based on IndoorHud (Manuel Leithner)
-- @date  15.07.2015
--

AdditionalIndoorHud = {}

function AdditionalIndoorHud.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) 
	   and SpecializationUtil.hasSpecialization(Motorized, specializations)
	   and SpecializationUtil.hasSpecialization(IndoorHud, specializations)
end

function AdditionalIndoorHud:load(xmlFile)

	self.additionalIndoorHud = {}
	
	local i = 0
	while true do
		local tagName  = string.format( "vehicle.additionalIndoorHud.hud(%d)", i )
		i = i + 1
		
		local name     = getXMLString(xmlFile, tagName.."#name")
		if name == nil then
			break
		end
	
		local numbers  = Utils.indexToObject(self.components, getXMLString(xmlFile, tagName.."#numbers"))
		local animName = getXMLString(xmlFile, tagName.."#animName")
		
		local precision = nil
		local numChilds = nil
		local maxValue = nil
		if numbers ~= nil then
			precision = Utils.getNoNil(getXMLInt(xmlFile, tagName.."#precision"), 1)
			numChilds = getNumOfChildren(numbers)
			if numChilds-precision <= 0 then
				print("Warning: Not enough number meshes in '"..self.configFileName.."'")
			end
			numChilds = numChilds - precision
			maxValue = (10 ^ (numChilds)) - 1/(10^precision) -- e.g. max with 2 childs and 1 float -> 10^2 - 1/10 -> 99.9 -> makes sure that display doesn't show 00.0 if value is 100
		end
		
		local hud = {name=name, numbers=numbers, animName=animName, lastNormValue=0, lastValue=-1, precision=precision, maxValue=maxValue, numChilds=numChilds}
		
		self:setHudValue(hud, 0, 0)
		
		table.insert( self.additionalIndoorHud, hud )
	end

end

function AdditionalIndoorHud:delete()
end

function AdditionalIndoorHud:mouseEvent(posX, posY, isDown, isUp, button)
end

function AdditionalIndoorHud:keyEvent(unicode, sym, modifier, isDown)
end

function AdditionalIndoorHud:update(dt)
end

function AdditionalIndoorHud:updateTick(dt)

	if self.addHudSumDt == nil then
		self.addHudSumDt         = 0
		self.addHudFuelFillLevel = 0
		self.addHudFuelRatio     = 0
	else
		self.addHudSumDt = self.addHudSumDt + dt
		if self.addHudSumDt > 100 then
			local fuelRatio = math.max( 0, self.addHudFuelFillLevel - self.fuelFillLevel ) * (1000 * 3600) / self.addHudSumDt
			self.addHudFuelFillLevel = self.fuelFillLevel
			self.addHudFuelRatio = self.addHudFuelRatio + 0.1 * ( fuelRatio - self.addHudFuelRatio )
			self.addHudSumDt     = 0
		end
	end

	if self:getIsActive() then
		for i,hud in pairs( self.additionalIndoorHud ) do
			if     hud.name == "speed" then
				local maxSpeed = 30
				if self.cruiseControl ~= nil then
					maxSpeed = self.cruiseControl.maxSpeed
				end
				self:setHudValue(hud, g_i18n:getSpeed(self:getLastSpeed() * self.speedDisplayScale), g_i18n:getSpeed(maxSpeed))
			elseif hud.name == "rpm" then
				self:setHudValue(hud, self.motor.lastMotorRpm, self.motor.maxRpm)
			elseif hud.name == "fuel" then
				self:setHudValue(hud, self.fuelFillLevel, self.fuelCapacity)
			elseif hud.name == "fuelRatio" then
				self:setHudValue(hud, self.addHudFuelRatio, 999)
			elseif hud.name == "fillLevel" and self.fillLevel ~= nil and self.getCapacity ~= nil and self:getCapacity() ~= 0 then
				self:setHudValue(hud, self.fillLevel, self:getCapacity())
			elseif hud.name == "operatingTime" and self.operatingTime ~= nil then
				local minutes = self.operatingTime / (1000 * 60)
				local hours = math.floor(minutes / 60)
				minutes = math.floor(minutes - hours * 60)
				
				local minutesString = string.format("%02d", minutes)
				self:setHudValue(hud, tonumber(hours.."."..minutesString), self.maxOperatingTime)
				
			elseif hud.name == "workedHectars" and self.workedHectars ~= nil then
				self:setHudValue(hud, self.workedHectars, 9999)
			elseif hud.name == "diameter" and self.lastDiameter ~= nil then
				self:setHudValue(hud, self.lastDiameter*1000, 9999)
			elseif hud.name == "cutLength" and self.currentCutLength ~= nil then
				self:setHudValue(hud, self.currentCutLength*100, 9999)
			elseif hud.name == "time" then
				local minutes = g_currentMission.environment.currentMinute
				local hours = g_currentMission.environment.currentHour
				local minutesString = string.format("%02d", minutes)
				self:setHudValue(hud, tonumber(hours.."."..minutesString), 9999)
			elseif hud.name == "cruiseControl" and self.cruiseControl ~= nil then
				self:setHudValue(hud, self.cruiseControl.speed, 9999)
			elseif type( self[hud.name] ) == "function" then
				local fct    = self[hud.name]
				local number = Utils.getNoNil( fct( self ), 0 )
				self:setHudValue(hud, number, 9999)
			end
		end
	end
end

function AdditionalIndoorHud:draw()
end
