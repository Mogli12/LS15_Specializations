--
-- RCSender
-- Specialization for RCSender
--
-- @author mogli
-- @date	20.07.2015
--


RCSender = {};
RCSender.doDebugPrint = false

function RCSender.debugPrint( ... )
	if RCSender.doDebugPrint then
		print( ... )
	end
end

function RCSender.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Attachable, specializations)
end;

function RCSender:load(xmlFile)

	self.RCSender = {}
	self.RCSenderVehicles = {}
	
	local i=0
	while true do
		local xmlName = string.format("vehicle.RCSender.remote(%d)", i);
		i = i + 1
		local name    = getXMLString(xmlFile, xmlName .. "#name")
		
		if name == nil then
			break
		end
		
		local event     = getXMLString(xmlFile, xmlName .. "#event");
		local setter    = getXMLString(xmlFile, xmlName .. "#setFunction");
		local getter    = getXMLString(xmlFile, xmlName .. "#getFunction");
		local animation = getXMLString(xmlFile, xmlName .. "#animation");
		
		self.RCSender[name] = {}
		self.RCSender[name].esg = RCSender.parseEventSetterGetter( event, setter, getter, animation )
		self.RCSender[name].set = function( self, value ) 
			for vehicle, bool in pairs( self.RCSenderVehicles ) do
				if bool then
					local fct = RCSender.getSetter( vehicle, self.RCSender[name].esg )
					if type( fct ) == "function" then
						fct( vehicle, value )
						return
					end
				end
			end
		end
		self.RCSender[name].get = function( self ) 
			for vehicle, bool in pairs( self.RCSenderVehicles ) do
				if bool then
					local fct = RCSender.getGetter( vehicle, self.RCSender[name].esg )
					if type( fct ) == "function" then
						return fct( vehicle )
					end
				end
			end
			return nil
		end
	end
end

--function RCSender:handleDetachAttachableEvent(superFunc)
--	local temp  = self.selectedImplement
--	local didIt = false
--	
--	if self.selectedImplement.RCSenderVehicles ~= nil then
--		for vehicle, bool in pairs( self.selectedImplement.RCSenderVehicles ) do
--			if bool then	
--				self.selectedImplement = vehicle
--			end
--		end
--	end
--	
--	superFunc( self )
--	
--	if didIt then
--		self.selectedImplement = temp
--	end
--end
--Vehicle.handleDetachAttachableEvent = Utils.overwrittenFunction( Vehicle.handleDetachAttachableEvent, RCSender.handleDetachAttachableEvent )

function RCSender:update(dt)	
	if self:getIsActiveForInput(true) and RCReceiver ~= nil then
		for vehicle, bool in pairs( self.RCSenderVehicles ) do
			if bool then	
				RCReceiver.RCInputProcessing( vehicle )
			end
		end
	end
end;

function RCSender:updateTick(dt)	
end;

function RCSender:delete()
end;

function RCSender:mouseEvent(posX, posY, isDown, isUp, button)
end;

function RCSender:keyEvent(unicode, sym, modifier, isDown)
end;

function RCSender:draw()
	if self:getIsActiveForInput(true) and RCReceiver ~= nil then
		for vehicle, bool in pairs( self.RCSenderVehicles ) do
			if bool then	
				RCReceiver.draw( vehicle )
			end
		end
	end
end;

function RCSender.parseEventSetterGetter( event, setter, getter, animation )
	local dummy = {}
	dummy.event  = event 
	dummy.setter = setter 
	dummy.getter = getter 
	local esg = {}
	esg.animation = animation
	for _,n in pairs({"event","setter","getter"}) do
		local n2 = n.."Tab";
		if dummy[n] == nil then
			esg[n]  = nil
			esg[n2] = nil			
		else			
			esg[n2] = Utils.splitString(".",dummy[n]);
			if table.getn( esg[n2] ) == 1 then
				esg[n] = esg[n2][1]
				esg[n2] = nil			
			else
				esg[n] = nil
				if table.getn( esg[n2] ) < 1 then
					esg[n2] = nil			
				end
			end
		end
	end
	return esg
end	


local function getHelper( object, tab, index )
	if object == nil then
		return
	elseif tab[index] == nil then
		return object
	else
		return getHelper( object[tab[index]], tab, index+1 )
	end
end

local function setHelper( object, tab, index, value )
	if object == nil then
		print("WARNING in RCSender: object is nil");
		return
	end
	if tab[index] == nil then
		print("ERROR in RCSender: tab[index] is nil");
		return 
	end
	
	if tab[index+1] == nil then
		object[tab[index]] = value
	else
		setHelper( object[tab[index]], tab, index+1, value )
	end
end

local function getAnimation( vehicle, animation )
	if     vehicle.getAnimationTime == nil
			or vehicle.getIsAnimationPlaying == nil then
		return nil
	elseif vehicle:getIsAnimationPlaying( animation ) then
		if vehicle.animations[animation].currentSpeed < 0 then
			return false
		end
		return true
	elseif vehicle:getAnimationTime( animation ) < 0.5 then
		return false
	end
	return true
end

local function setAnimation( vehicle, animation, value )
	RCSender.debugPrint("setAnimation: "..tostring(animation))
	if     vehicle.getAnimationTime == nil
			or vehicle.playAnimation == nil then
		return 
	end
	
	local old = getAnimation( vehicle, animation )
	
	RCSender.debugPrint(tostring(animation).." / "..tostring(old).." / "..tostring(value))
	
	if value == old then
		return
	end
	
	local dir = -1
	if value then
		dir = 1
	end
	
	vehicle:playAnimation( animation, dir, Utils.clamp(vehicle:getAnimationTime( animation ), 0, 1), true)
end

function RCSender.getGetter( vehicle, esg )
	local fct = nil
	if     vehicle == nil or esg == nil then
		return
	elseif esg.getter ~= nil then
		fct = esg.vehicle[esg.getter]
	elseif esg.getterTab ~= nil then
		fct = getHelper( esg.vehicle, esg.getterTab, 1 )
	elseif esg.event ~= nil then
		fct = function( vehicle )
			return vehicle[esg.event]
		end
	elseif esg.eventTab ~= nil then
		fct = function( vehicle )
			return getHelper( vehicle, esg.eventTab, 1 )
		end
	elseif esg.animation ~= nil then
		fct = function( vehicle )
			return getAnimation( vehicle, esg.animation )
		end
	end
	
	if fct ~= nil and type( fct ) ~= "function" then
		print("Error in getGetter: "..tostring(fct))		
		return
	end
	
	return fct
end

function RCSender.getSetter( vehicle, esg )
	local fct = nil
	if     vehicle == nil or esg == nil then
		return
	elseif esg.setter ~= nil then
		fct = esg.vehicle[esg.setter]
	elseif esg.setterTab ~= nil then
		fct = getHelper( esg.vehicle, esg.setterTab, 1 )
	elseif esg.event ~= nil then
		fct = function( vehicle, value )
			vehicle[esg.event] = value
		end
	elseif esg.eventTab ~= nil then
		fct = function( vehicle, value )
			setHelper( vehicle, esg.eventTab, 1, value )
		end
	elseif esg.animation ~= nil then
		fct = function( vehicle, value )
			return setAnimation( vehicle, esg.animation, value )
		end
	end
	
	if fct ~= nil and type( fct ) ~= "function" then
		print("Error in getSetter: "..tostring(fct))
		return
	end
	
	return fct
end
