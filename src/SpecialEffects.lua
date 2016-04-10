--
-- SpecialEffects
-- Class for effect nodes
--
-- @author  Mogli
-- @date    28.08.2015
--

SpecialEffects = {}
SpecialEffects.doDebugPrint = false

function SpecialEffects.debugPrint( ... )
	if SpecialEffects.doDebugPrint then
		print( ... )
	end
end

function SpecialEffects.prerequisitesPresent(specializations)
	return true
end

function SpecialEffects:load(xmlFile)

	self.specialEffects = {}

	local i=0;
	while true do
		local keyName = string.format("vehicle.specialEffects.specialEffect(%d)", i);
		i = i + 1
		SpecialEffects.debugPrint(tostring(keyName))
		local name    = getXMLString(xmlFile, keyName.. "#name");
		SpecialEffects.debugPrint(tostring(name))

		if name == nil then
			break
		end
		
		self.specialEffects[name] = {}
		self.specialEffects[name].isActive = false
		
		self.specialEffects[name].set = function( self, isActive )
			SpecialEffects.debugPrint(name..": set("..tostring(isActive)..")")
			self.specialEffects[name].isActive = isActive
		end

		self.specialEffects[name].get = function( self )
			return self.specialEffects[name].isActive
		end
		
		self.specialEffects[name].effect = {}
		if self.isClient then
			--self.specialEffects[name].effect = EffectManager:loadEffect(xmlFile, keyName, self.components, self);
			state, result = pcall( EffectManager.loadEffect, EffectManager, xmlFile, keyName, self.components, self)
			if state  then
				self.specialEffects[name].effect = result 
			else
				SpecialEffects.debugPrint(tostring(result))
			end
			
			if self.specialEffects[name].effect ~= nil then
				local fillTypeName = getXMLString(xmlFile, keyName.. "#fillType");
				if fillTypeName ~= nil and Fillable.fillTypeNameToDesc[fillTypeName] ~= nil then
					self.specialEffects[name].effect:setFillType(Fillable.fillTypeNameToDesc[fillTypeName].index);
				end
			end
		end
	end
	
end

function SpecialEffects:delete()
	for name,specialEffect in pairs( self.specialEffects ) do
		if specialEffect.effect ~= nil then
			EffectManager:deleteEffect(specialEffect.effect);
		end
	end
end

function SpecialEffects:mouseEvent(posX, posY, isDown, isUp, button)
end

function SpecialEffects:keyEvent(unicode, sym, modifier, isDown)
end

function SpecialEffects:update(dt)
end

function SpecialEffects:updateTick(dt)
	if self:getIsActive() then
		if self.isClient then
			for name,specialEffect in pairs( self.specialEffects ) do
			
				if specialEffect.isActive then
					if not ( specialEffect.lastIsActive ) and specialEffect.effect ~= nil then
						EffectManager:startEffect(specialEffect.effect);
					end
				elseif specialEffect.lastIsActive and specialEffect.effect ~= nil then
					EffectManager:stopEffect(specialEffect.effect);
				end
				
				specialEffect.lastIsActive = specialEffect.isActive
			end
		end
	end
end

function SpecialEffects:draw()
end



