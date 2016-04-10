--
-- multiConnectorTrailer
-- Specialization for multiConnectorTrailer
--
-- @author mogli
-- @date	20.07.2015
--


multiConnectorTrailer = {};
multiConnectorTrailer.doDebugPrint = false

function multiConnectorTrailer.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Attachable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end;

function multiConnectorTrailer:load(xmlFile)
	
	self.multiConnectorTrailer = {};
		
	self.multiConnectorTrailer.connectors = {};
	local i=0;
	while true do
		local areaKey = string.format("vehicle.multiConnectorTrailer.connector(%d)", i);
		if not hasXMLProperty(xmlFile, areaKey) then
			break;
		end

		local connector = {};
		connector.name         = getXMLString(xmlFile, areaKey .. "#name")
		connector.status       = 0

		connector.vehicleSide  = Utils.indexToObject(self.components, getXMLString(xmlFile, areaKey .. "#endIndex"));		
		connector.translation  = { getTranslation( connector.vehicleSide ) }
		connector.rotation     = { getRotation( connector.vehicleSide ) }
		connector.trailerSide  = Utils.indexToObject(self.components, getXMLString(xmlFile, areaKey .. "#startIndex"));		
		connector.sendFillLevel    = getXMLBool( xmlFile, areaKey .."#sendFillLevel" )
		connector.receiveFillLevel = getXMLBool( xmlFile, areaKey .."#receiveFillLevel" )
		
		local maxDist          = getXMLFloat( xmlFile, areaKey .."#maxDistance" )
		if maxDist ~= nil then
			connector.maxDistSq  = maxDist * maxDist 
		end
		
		connector.animRotation = getXMLString( xmlFile, areaKey .. "#animRotation" )

		if connector.animRotation ~= nil then
			connector.minAngle     = math.rad( Utils.getNoNil(getXMLFloat(xmlFile, areaKey .. "#minAngle"), -180 ) )
			connector.maxAngle     = math.rad( Utils.getNoNil(getXMLFloat(xmlFile, areaKey .. "#maxAngle"), 180 ) )			
			connector.angleFactor  = 0
			if math.abs( connector.maxAngle - connector.minAngle ) > 1e-3 then
				connector.angleFactor = 1.0 / ( connector.maxAngle - connector.minAngle )
			end
		end

		connector.configurations = {}
		
		local j=0;
		while true do
			local configKey = string.format("%s.configuration(%d)", areaKey, j);
			if not hasXMLProperty(xmlFile, configKey) then
				break;
			end
		
			local config = {}
			
			config.configFileName = getXMLString( xmlFile, configKey .. "#configFileName" )
			config.specialization = getXMLString( xmlFile, configKey .. "#specialization" )
			config.isReference    = getXMLBool( xmlFile, configKey .. "#isReference" )
			
			config.translation    = Utils.getVectorNFromString( getXMLString( xmlFile, configKey .. "#translation" ) )
			config.rotation       = Utils.getVectorNFromString( getXMLString( xmlFile, configKey .. "#rotation" ) )
			config.animation      = getXMLString( xmlFile, configKey .. "#animation" )
			config.noConnect      = getXMLBool( xmlFile, configKey .. "#noConnect" )

			config.aiLeftMarker   = Utils.indexToObject(self.components, getXMLString(xmlFile, configKey .."#aiLeftMarkerIndex"));
			config.aiRightMarker  = Utils.indexToObject(self.components, getXMLString(xmlFile, configKey .."#aiRightMarkerIndex"));
			config.aiBackMarker   = Utils.indexToObject(self.components, getXMLString(xmlFile, configKey .."#aiBackMarkerIndex"));
			
			local seedFruitTypes  = getXMLString(xmlFile, configKey .."#seedFruitTypes")

			if seedFruitTypes ~= nil and seedFruitTypes ~= "" then
				config.seeds = {}
				local types  = Utils.splitString(" ", seedFruitTypes)

				for _, v in pairs(types) do
					local fruitTypeDesc = FruitUtil.fruitTypes[v]

					if fruitTypeDesc ~= nil and fruitTypeDesc.allowsSeeding then
						table.insert(config.seeds, fruitTypeDesc.index)
					else
						print("Warning: '" .. self.configFileName .."' ('" .. config.configFileName .. "') has invalid seedFruitType '" .. v .. "'.")
					end
				end
			end
			
			j = j + 1
			
			if      ( config.configFileName == nil or config.configFileName == "" )
					and ( config.specialization == nil or config.specialization == "" ) 
					and ( config.isReference == nil    or config.isReference    == false ) then
				connector.defaultConfiguration = j 
			end
			
			table.insert( connector.configurations, config )
		end
		
		if connector.defaultConfiguration == nil then
			local config = {}
			config.translation = connector.translation 
			config.rotation    = connector.rotation 
			table.insert( connector.configurations, config )
			connector.defaultConfiguration = table.getn( connector.configurations )
		end
		
		i = i + 1;
		
		if connector.name ~= nil then
			table.insert(self.multiConnectorTrailer.connectors, connector)
		end
	end
	
	self.multiConnectorTrailer.isAttached = false;
	
	self.getMCFillLevel = multiConnectorTrailer.getMCFillLevel
	self.setMCFillLevel = multiConnectorTrailer.setMCFillLevel
	self.getMCCapacity  = multiConnectorTrailer.getMCCapacity
end

function multiConnectorTrailer:postLoad(xmlFile)
	for _,connector in pairs(self.multiConnectorTrailer.connectors) do
		connector.detachedNode = getParent( connector.vehicleSide )
		connector.translation  = { getTranslation( connector.vehicleSide ) }
		connector.rotation     = { getRotation( connector.vehicleSide ) }
		
		for _,config in pairs(connector.configurations) do
			if config.translation == nil then
				config.translation = connector.translation
			end
			if config.rotation == nil then
				config.rotation = connector.rotation
			end
			self:setAnimationTime( config.animation, 0.1 )
			self:setAnimationTime( config.animation, 0 )
		end
		if connector.animRotation ~= nil then
			self:setAnimationTime( connector.animRotation, 0.49 )
			self:setAnimationTime( connector.animRotation, 0.5 )
		end
	end;
	
end;

function multiConnectorTrailer.debugPrint( ... )
	if multiConnectorTrailer.doDebugPrint then
		print( ... )
	end
end

function multiConnectorTrailer:update(dt)
	
	
	if self.attacherVehicle~= nil then
		for _,connector in pairs(self.multiConnectorTrailer.connectors) do
			
			if connector.status == 0 then--self.attacherVehicle.cableAttacherNode[k] == nil then
				connector.status = -1
				
				unlink( connector.vehicleSide )
				link(connector.detachedNode,connector.vehicleSide)
				setTranslation( connector.vehicleSide, unpack( connector.translation ) )
				setRotation( connector.vehicleSide, unpack( connector.rotation ) )
				
				local implementIndex = self.attacherVehicle:getImplementIndexByObject(self);
				local implement      = self.attacherVehicle.attachedImplements[implementIndex];
				local jointDescIndex = implement.jointDescIndex;
				local k              = 0								
				local vehicle        = multiConnectorTrailer.getRootAttacherVehicle( self.attacherVehicle )				
				local toScan         = { vehicle }
				local wx, wy, wz     = getWorldTranslation( connector.vehicleSide )
				local d2             = nil

				multiConnectorTrailer.debugPrint( "============================================" )
				multiConnectorTrailer.debugPrint( "Connector: "..connector.name )
				
				while table.getn( toScan ) > 0 do
					local nextScan = {}
					
					for _,v in pairs( toScan ) do
						multiConnectorTrailer.debugPrint( "Vehicle: "..tostring(v.configFileName) )
						if v.multiConnectorVehicle ~= nil then
							for i,cv in pairs( v.multiConnectorVehicle.connectors ) do
								multiConnectorTrailer.debugPrint("Trying: "..cv.name.." "..tostring(cv.isGeneric))
								if      not ( cv.isGeneric )
										and cv.attacherTrailer == nil
										and cv.name == connector.name
										and cv.node ~= nil then
									local vx, vy, vz = getWorldTranslation( cv.node )
									local d = ( vx-wx )^2 + ( vy-wy )^2 + ( vz - wz )^2
									if ( connector.maxDistSq == nil or d < connector.maxDistSq ) and ( k < 1 or d < d2 ) then
										multiConnectorTrailer.debugPrint("found one")
										d2      = d
										vehicle = v
										k       = i
									end
								end
							end
						end
						
						if v.attachedImplements    ~= nil then
							multiConnectorTrailer.debugPrint("found implement I: "..table.getn(v.attachedImplements))
							
							for _,impl in pairs( v.attachedImplements ) do
								multiConnectorTrailer.debugPrint("found implement II: "..tostring(impl.object).." "..tostring(self))
								if impl.object ~= nil and impl.object ~= self then
									multiConnectorTrailer.debugPrint("found implement III")
									table.insert( nextScan, impl.object )
								end
							end
						end
					end
					
					toScan = {}
					for _,v in pairs( nextScan ) do
						table.insert( toScan, v )
					end

					multiConnectorTrailer.debugPrint("Next level: "..tostring(table.getn(toScan)).." "..tostring(table.getn(nextScan)))
				end
								
				if k < 1 then
					multiConnectorTrailer.debugPrint("no mcv found")
					vehicle = self.attacherVehicle
				end
				multiConnectorTrailer.debugPrint( "============================================" )
				
				if k < 1 then
					if vehicle.multiConnectorVehicle == nil then
						vehicle.multiConnectorVehicle = {}
					end
					if vehicle.multiConnectorVehicle.connectors == nil then
						vehicle.multiConnectorVehicle.connectors = {}
					end
					k = table.getn( vehicle.multiConnectorVehicle.connectors ) + 1
					vehicle.multiConnectorVehicle.connectors[k]      = {}
				end
				
				if vehicle.multiConnectorVehicle.connectors[k].node == nil then
					multiConnectorTrailer.debugPrint("adding node")
					vehicle.multiConnectorVehicle.connectors[k].name   = connector.name
					vehicle.multiConnectorVehicle.connectors[k].isGeneric = true
					vehicle.multiConnectorVehicle.connectors[k].parent = createTransformGroup("multiConnector1"..connector.name); 					
					vehicle.multiConnectorVehicle.connectors[k].node   = createTransformGroup("multiConnector2"..connector.name); 					
					link(vehicle.attacherJoints[jointDescIndex].jointTransform,vehicle.multiConnectorVehicle.connectors[k].parent);					
					link(vehicle.multiConnectorVehicle.connectors[k].parent,vehicle.multiConnectorVehicle.connectors[k].node);					
					setRotation(vehicle.multiConnectorVehicle.connectors[k].parent,0,-math.pi/2,0)
				end;
				
				vehicle.multiConnectorVehicle.connectors[k].attacherTrailer = self
				connector.attacherVehicle = vehicle
				connector.vehicleConfig   = vehicle.multiConnectorVehicle.connectors[k]
				connector.status          = connector.defaultConfiguration
				
				for j,config in pairs(connector.configurations) do
					if config.configFileName ~= nil then
						local c1 = string.lower( Utils.removeModDirectory(connector.attacherVehicle.configFileName) )
						local c2 = string.lower( config.configFileName )
						if c1 == c2 then
							connector.status = j
							break
						end
					end
					
					if config.specialization ~= nil then
					end
					
					if config.isReference then
						if not ( connector.vehicleConfig.isGeneric ) then
							connector.status = j
							break
						end
					end
				end
				
				multiConnectorTrailer.debugPrint(connector.name.." "..tostring(connector.status).." "..tostring(connector.defaultConfiguration))
				
				multiConnectorTrailer.debugPrint("Final index: "..tostring(connector.status))
				
				local config = connector.configurations[connector.status]
				
				if config.noConnect then
					multiConnectorTrailer.debugPrint("no connect...")
				elseif connector.vehicleConfig ~= nil and connector.vehicleConfig.linkToTrailer then
					multiConnectorTrailer.debugPrint("link to trailer")
					connector.saveTranslation = { getTranslation( connector.vehicleConfig.node ) }
					connector.saveRotation    = { getRotation( connector.vehicleConfig.node ) }
					unlink( connector.vehicleConfig.node )
					
					multiConnectorTrailer.debugPrint(getName(connector.vehicleSide).." "..getName(connector.vehicleConfig.node).." "..tostring(config.translation[1]).." "..tostring(config.translation[2]).." "..tostring(config.translation[3]))
					
					link( connector.vehicleSide, connector.vehicleConfig.node )
					setTranslation( connector.vehicleConfig.node, unpack( config.translation ) )
					setRotation( connector.vehicleConfig.node, unpack( config.rotation ) )
				else
					multiConnectorTrailer.debugPrint("normal")
					unlink( connector.vehicleSide )
					link( connector.vehicleConfig.node, connector.vehicleSide )
				
					if config ~= nil then
						setTranslation( connector.vehicleSide, unpack( config.translation ) )
						setRotation( connector.vehicleSide, unpack( config.rotation ) )
					else
						setTranslation( connector.vehicleSide, unpack( connector.translation ) )
						setRotation( connector.vehicleSide, unpack( connector.rotation ) )
					end
					if config.animation ~= nil then
						multiConnectorTrailer.debugPrint( "Playing I: "..tostring(config.animation))
						self:playAnimation( config.animation, 1, 0 )
					end
				end
								
				vehicle.multiConnectorVehicle.connectors[k].trailerConfig   = config 
				
				if connector.vehicleConfig ~= nil then
					if connector.vehicleConfig.animation ~= nil then
						multiConnectorTrailer.debugPrint( "Playing II: "..tostring(connector.vehicleConfig.animation))
						connector.attacherVehicle:playAnimation( connector.vehicleConfig.animation, 1, 0 )
					end
					if connector.attacherVehicle.onAttachMultiConnector ~= nil then
						connector.attacherVehicle:onAttachMultiConnector( connector.vehicleConfig, self, connector )
					end
				end

			end;
				
			if connector.status > 0 and connector.animRotation ~= nil then
				local yRot = 0
				if connector.trailerSide ~= nil then
					local dx1,dy1,dz1 = localDirectionToWorld(getParent( connector.vehicleSide ), 0, 0, 1)
					local dx2,dy2,dz2 = worldDirectionToLocal(connector.trailerSide,dx1,dy1,dz1)					
					yRot = Utils.getYRotationFromDirection(dx2, dz2)
				end
				
				local animTime = 0.5
				
				if     yRot <= connector.minAngle then
					animTime = 0
				elseif yRot >= connector.maxAngle then
					animTime = 1
				else
					animTime = ( yRot - connector.minAngle ) * connector.angleFactor
				end
				
				self:setAnimationTime( connector.animRotation, animTime )
			end
		end
	end;
end;

function multiConnectorTrailer:updateTick(dt)	
end;


function multiConnectorTrailer:delete()
	for _,connector in pairs(self.multiConnectorTrailer.connectors) do
		connector.status = 0
	end
end;

function multiConnectorTrailer:mouseEvent(posX, posY, isDown, isUp, button)
end;

function multiConnectorTrailer:keyEvent(unicode, sym, modifier, isDown)
end;

function multiConnectorTrailer:draw()
end;

function multiConnectorTrailer.getRootAttacherVehicle( attacherVehicle )
	local vehicle = attacherVehicle
	while vehicle.attacherVehicle ~= nil do
		vehicle = vehicle.attacherVehicle
	end
	return vehicle 
end

function multiConnectorTrailer:onAttach( attacherVehicle, jointDescIndex )
	local vehicle = multiConnectorTrailer.getRootAttacherVehicle( attacherVehicle )

	for _,connector in pairs(self.multiConnectorTrailer.connectors) do
		connector.status = 0		
		multiConnectorTrailer:resetGenerics( self, vehicle, connector.name )
	end;

	if self.attachedImplements ~= nil then
		for _,impl in pairs(self.attachedImplements) do
			if impl.object ~= nil and impl.object.multiConnectorTrailer ~= nil then
				multiConnectorTrailer.onAttach( impl.object, self, impl.jointDescIndex )
			end
		end
	end
end; 	

function multiConnectorTrailer:resetGenerics( vehicle, name )
	if     vehicle == nil  then
		return 
	elseif vehicle == self then
		return 
	elseif vehicle.multiConnectorTrailer ~= nil then
		for _,connector in pairs(vehicle.multiConnectorTrailer.connectors) do
			if      connector.status ~= nil
					and connector.status > 0
					and connector.name == name
					and connector.isGeneric then
				multiConnectorTrailer.detachConnector( vehicle, connector )
			end
		end;
	end
	
	if vehicle.attachedImplements ~= nil then
		for _,impl in pairs( vehicle.attachedImplements ) do
			multiConnectorTrailer.resetGenerics( self, impl.object, name )
		end
	end
end

function multiConnectorTrailer:onDetach( attacherVehicle, jointDescIndex )
	for _,connector in pairs(self.multiConnectorTrailer.connectors) do
		multiConnectorTrailer.detachConnector( self, connector )
	end
	
	if self.attachedImplements ~= nil then
		for _,impl in pairs(self.attachedImplements) do
			if impl.object ~= nil and impl.object.multiConnectorTrailer ~= nil then
				multiConnectorTrailer.onDetach( impl.object, self, impl.jointDescIndex )
				multiConnectorTrailer.onAttach( impl.object, self, impl.jointDescIndex )
			end
		end
	end
end;

function multiConnectorTrailer:detachConnector( connector )

	if connector ~= nil and connector.status > 0 then
		multiConnectorTrailer.debugPrint( "Detaching: "..connector.name.." of "..self.configFileName )
		local config = connector.configurations[connector.status]
		if config.noConnect then
		else
			if config ~= nil and config.animation ~= nil then
				self:playAnimation( config.animation, -1, 1 )
			end
			if connector.animRotation ~= nil then
				self:setAnimationTime( connector.animRotation, 0.5 )
			end
			
			if connector.vehicleConfig ~= nil then
				if connector.attacherVehicle.onDetachMultiConnector ~= nil then
					connector.attacherVehicle:onDetachMultiConnector( connector.vehicleConfig, self, connector )
				end
				connector.vehicleConfig.attacherTrailer = nil
				connector.vehicleConfig.trailerConfig   = nil
			end
			
			if connector.vehicleConfig ~= nil and connector.vehicleConfig.animation ~= nil then
				connector.attacherVehicle:playAnimation( connector.vehicleConfig.animation, -1, 1 )
			end
			
			if connector.vehicleConfig ~= nil and connector.vehicleConfig.linkToTrailer then
				unlink( connector.vehicleConfig.node )
				link( connector.vehicleConfig.linkParent, connector.vehicleConfig.node )
				setTranslation( connector.vehicleConfig.node, unpack( connector.saveTranslation ) )
				setRotation(    connector.vehicleConfig.node, unpack( connector.saveRotation ) )  
			end
			
			unlink( connector.vehicleSide )
			link(connector.detachedNode,connector.vehicleSide)
			setTranslation( connector.vehicleSide, unpack( connector.translation ) )
			setRotation( connector.vehicleSide, unpack( connector.rotation ) )
		end
		connector.status = 0
	end
end

function multiConnectorTrailer:getMCFillLevel( fillType )
	local fillLevel = 0
	
	if self.getFillLevel ~= nil then
		fillLevel = self:getFillLevel( fillType )
	end

	for _,connector in pairs(self.multiConnectorTrailer.connectors) do
		if      connector.receiveFillLevel
				and connector.attacherVehicle              ~= nil
				and connector.attacherVehicle.getFillLevel ~= nil
				and connector.vehicleConfig                ~= nil
				and connector.vehicleConfig.sendFillLevel then
			fillLevel = fillLevel + connector.attacherVehicle:getFillLevel( fillType )
		end
	end
	
	return fillLevel
end

function multiConnectorTrailer:getMCCapacity()
	local capacity = 0
	
	if self.getCapacity ~= nil then
		capacity = self:getCapacity()
	end
	
	for _,connector in pairs(self.multiConnectorTrailer.connectors) do
		if      connector.receiveFillLevel
				and connector.attacherVehicle              ~= nil
				and connector.attacherVehicle.getCapacity  ~= nil
				and connector.vehicleConfig                ~= nil
				and connector.vehicleConfig.sendFillLevel then
			capacity = capacity + connector.attacherVehicle:getCapacity()
		end
	end

	return capacity 
end
