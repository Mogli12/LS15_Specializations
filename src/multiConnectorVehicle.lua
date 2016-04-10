--
-- multiConnectorVehicle
-- Specialization for multiConnectorVehicle
--
-- @author mogli
-- @date	20.07.2015
--


multiConnectorVehicle = {};

function multiConnectorVehicle.prerequisitesPresent(specializations)
	return true--SpecializationUtil.hasSpecialization(Attachable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end;

function multiConnectorVehicle:load(xmlFile)

	self.onAttachConnector = SpecializationUtil.callSpecializationsFunction("onAttachMultiConnector")
	self.onDetachConnector = SpecializationUtil.callSpecializationsFunction("onDetachMultiConnector")
	
	self.multiConnectorVehicle = {};
	self.multiConnectorVehicle.connectors = {};
	local i=0;
	while true do
		local areaKey = string.format("vehicle.multiConnectorVehicle.connector(%d)", i);
		if not hasXMLProperty(xmlFile, areaKey) then
			break;
		end

		local connector         = {};
		connector.name          = getXMLString(xmlFile, areaKey .. "#name")
		connector.node          = Utils.indexToObject(self.components, getXMLString(xmlFile, areaKey .. "#index"));		
		connector.animation     = getXMLString( xmlFile, areaKey .. "#animation" )
		connector.linkToTrailer = getXMLBool( xmlFile, areaKey .. "#linkToTrailer" )
		connector.linkWorkAreas = getXMLBool( xmlFile, areaKey .. "#linkWorkAreas" )
		connector.linkParent    = getParent( connector.node )
		
		i = i + 1;

		if connector.name ~= nil then
			table.insert(self.multiConnectorVehicle.connectors, connector)
		end
	end
	
	
	if self.getTypedWorkAreas ~= nil then
		self.getTypedWorkAreas = Utils.overwrittenFunction( self.getTypedWorkAreas, multiConnectorVehicle.getTypedWorkAreas )
	end	
	
	self.multiConnectorVehicle.aiLeftMarker  = self.aiLeftMarker 
	self.multiConnectorVehicle.aiRightMarker = self.aiRightMarker
	self.multiConnectorVehicle.aiBackMarker  = self.aiBackMarker  	
end

function multiConnectorVehicle:update(dt)
end;

function multiConnectorVehicle:updateTick(dt)	
end;

function multiConnectorVehicle:getTypedWorkAreas(superFunc, areaType)
	local typedWorkAreas = superFunc( self, areaType )
	
	for _,connector in pairs( self.multiConnectorVehicle.connectors ) do
		if      connector.linkWorkAreas 
				and connector.attacherTrailer ~= nil 
				and connector.trailerConfig   ~= nil then
			local collect = false
			if      areaType == WorkArea.AREATYPE_SOWINGMACHINE
					and connector.trailerConfig.seeds ~= nil then
				for _,s in pairs( connector.trailerConfig.seeds ) do
					if self.seeds[self.currentSeed] == s then
						collect = true
						break
					end
				end
			else
				collect = true
			end
			
			if collect then
				local trailerAreas = connector.attacherTrailer:getTypedWorkAreas( areaType )
				for _,wa in pairs( trailerAreas ) do
					table.insert( typedWorkAreas, wa )
				end
			end
		end
	end
	return typedWorkAreas
end


function multiConnectorVehicle:delete()
end;

function multiConnectorVehicle:mouseEvent(posX, posY, isDown, isUp, button)
end;

function multiConnectorVehicle:keyEvent(unicode, sym, modifier, isDown)
end;

function multiConnectorVehicle:draw()
end;

function multiConnectorVehicle:onAttachConnector( vehicleConfig, trailer, trailerConfig )
	if      vehicleConfig.linkWorkAreas 
			and trailerConfig.aiLeftMarker  ~= nil
			and trailerConfig.aiRightMarker ~= nil
			and trailerConfig.aiBackMarker  ~= nil then
		self.aiLeftMarker  = trailerConfig.aiLeftMarker 
		self.aiRightMarker = trailerConfig.aiRightMarker
		self.aiBackMarker  = trailerConfig.aiBackMarker  
	end
end;

function multiConnectorVehicle:onDetachConnector( vehicleConfig, trailer, trailerConfig )
	if vehicleConfig.linkWorkAreas then
		self.aiLeftMarker  = self.multiConnectorVehicle.aiLeftMarker 
		self.aiRightMarker = self.multiConnectorVehicle.aiRightMarker
		self.aiBackMarker  = self.multiConnectorVehicle.aiBackMarker  
	end
end;

