-- last game update date when this was written 4/15/2023
-- script hash 7d18802d52d038c6ee4a0d9802086c2267e9070e1c4242fa3ada52d13dfcf1ae66de8df9a7572bfbf5c8bd914ab92f12
-- decompiled by Sentinel (took 8.480599ms)
local cache = {}
local unitModifiers = {
	["Building Cost"] = { 100, false },
	["Building Speed"] = { 100, true },
	["Factory Output"] = { 100, true },
	["Fuel Efficiency"] = { 100, true },
	["Government Spending"] = { 100, false },
	["Integration Speed"] = { 100, true },
	["Manpower Increase"] = { 100, true },
	["Research Output"] = { 100, true },
	["Resource Output"] = { 100, true },
	["Tax Income"] = { 100, true },
	["Military Cost"] = { 100, false },
	["Military Starting Experience"] = { 100, true },
	["Military Recruitment Time"] = { 100, false },
	["Military Reinforcement Cost"] = { 100, false },
	["Military Upkeep"] = { 100, false },
	["Military Attack"] = { 100, true },
	["Military Defense"] = { 100, true },
	["Military Speed"] = { 100, true },
	["Base Stability"] = { 0, true },
	["Ideology Power"] = { 100, true },
	["Justification Time"] = { 100, false },
	["Political Power Gain"] = { 100, true },
	["Resistance"] = { 100, true },
	["Stability Hit on Offensive Wars"] = { 0, true },
	["Unrest Reduction"] = { 100, true },
	["War Exhaustion Gain"] = { 0, false },
	["Diplomatic Actions"] = { 2, true },
}
for i, ideology in pairs(game.ReplicatedStorage.Assets.Laws.Ideology:GetChildren()) do
	unitModifiers[ideology.Name .. " Ideology Power"] = { 100, true }
end
for i, building in pairs(game.ReplicatedStorage.Assets.Buildings:GetChildren()) do
	unitModifiers[building.Name .. " Cost"] = { 100, false }
	unitModifiers[building.Name .. " Speed"] = { 100, true }
end
for i, unitStat in pairs(game.ReplicatedStorage.Assets.UnitStats:GetChildren()) do
	unitModifiers[unitStat.Name .. " Cost"] = { 100, false }
	unitModifiers[unitStat.Name .. " Recruitment Time"] = { 100, false }
	unitModifiers[unitStat.Name .. " Starting Experience"] = { 100, true }
	unitModifiers[unitStat.Name .. " Upkeep"] = { 100, false }
	unitModifiers[unitStat.Name .. " Attack"] = { 100, true }
	unitModifiers[unitStat.Name .. " Defense"] = { 100, true }
	unitModifiers[unitStat.Name .. " Speed"] = { 100, true }
end
local transverseTypes = { "Ground", "Naval", "Air" }
for i, transverseType in pairs(transverseTypes) do
	unitModifiers[transverseType .. " Cost"] = { 100, false }
	unitModifiers[transverseType .. " Recruitment Time"] = { 100, false }
	unitModifiers[transverseType .. " Starting Experience"] = { 100, true }
	unitModifiers[transverseType .. " Upkeep"] = { 100, false }
	unitModifiers[transverseType .. " Attack"] = { 100, true }
	unitModifiers[transverseType .. " Defense"] = { 100, true }
	unitModifiers[transverseType .. " Speed"] = { 100, true }
end
local function v16(p11)
	for i, v in pairs(p11:GetChildren()) do
		for i2, v2 in pairs(v:GetChildren()) do
			v2.Parent = p11
		end
		v:Destroy()
	end
end
if not (script:GetAttribute("SetLoad") or game.Players.LocalPlayer) then
	workspace.CityPlacer.ModifierTags.ReadyModifier:Invoke()
	v16(game.ReplicatedStorage.Assets.Laws.Modifiers)
	script:SetAttribute("SetLoad", true)
end
local module = {
	["Function"] = {},
}
local list = {}
list.Terrain = {
	["Flat"] = {
		["MovementPenalty"] = 0,
		["DefenseBuff"] = 0.25,
		["MapColor"] = Color3.new(1, 1, 1),
	},
	["Hilly"] = {
		["MovementPenalty"] = 0.3,
		["DefenseBuff"] = 0.7,
		["MapColor"] = Color3.new(0, 1, 0),
	},
	["Semi-Mountainous"] = {
		["MovementPenalty"] = 0.5,
		["DefenseBuff"] = 1.75,
		["MapColor"] = Color3.new(1, 1, 0),
	},
	["Mountainous"] = {
		["MovementPenalty"] = 0.8,
		["DefenseBuff"] = 3,
		["MapColor"] = Color3.new(1, 0, 0),
	},
}
list.Biome = {
	["Normal"] = {
		["MovementPenalty"] = 0,
		["DefenseBuff"] = 0,
		["ExtraAttrition"] = 0,
		["MapColor"] = Color3.new(1, 1, 1),
	},
	["Jungle"] = {
		["MovementPenalty"] = 0.5,
		["DefenseBuff"] = 2,
		["ExtraAttrition"] = 0.5,
		["MapColor"] = Color3.new(0, 1, 0),
	},
	["Arid"] = {
		["MovementPenalty"] = 0.33,
		["DefenseBuff"] = 0,
		["ExtraAttrition"] = 1.25,
		["MapColor"] = Color3.new(1, 1, 0),
	},
	["Mild Winter"] = {
		["MovementPenalty"] = 0.2,
		["DefenseBuff"] = 0.15,
		["ExtraAttrition"] = 0.5,
		["MapColor"] = Color3.new(0, 1, 1),
	},
	["Severe Winter"] = {
		["MovementPenalty"] = 0.5674,
		["DefenseBuff"] = 0.375,
		["ExtraAttrition"] = 1.5,
		["MapColor"] = Color3.new(0, 0, 1),
	},
	["Arctic"] = {
		["MovementPenalty"] = 0.75,
		["DefenseBuff"] = 0.5,
		["ExtraAttrition"] = 2,
		["MapColor"] = Color3.new(1, 0, 1),
	},
}
module.List = list
setmetatable(module.List.Terrain, {
	["__index"] = function(self, _)
		return self.Flat
	end,
})
setmetatable(module.List.Biome, {
	["__index"] = function(self, _)
		return self.Normal
	end,
})
function module.Function.StabilityAspect(stability, modifierName)
	local instance = game.ReplicatedStorage.Assets.Laws.Stability.Low
	local modifiers = {}
	local idk
	if 50 <= stability then
		instance = game.ReplicatedStorage.Assets.Laws.Stability.High
		idk = 100
	else
		idk = 0
	end
	local coefficent = (50 - math.abs(stability - idk)) / 50
	for i, v in pairs(instance:GetChildren()) do
		table.insert(modifiers, { v.Name, v.Value * coefficent })
	end
	if modifierName ~= nil then
		local found = false
		for i, modifier in pairs(modifiers) do
			if modifier[1] == modifierName then
				modifiers = modifier[2]
				found = true
				break
			end
		end
		modifiers = not found and 0 or modifiers
	end
	return modifiers
end
function module.Function.WarExhaustionAspect(warExhaustion, modifierName)
	local modifiers = {}
	local coefficent = warExhaustion / 10
	for i, v in pairs(game.ReplicatedStorage.Assets.Laws.WarExhaustion:GetChildren()) do
		table.insert(modifiers, { v.Name, v.Value * coefficent })
	end
	if modifierName ~= nil then
		local found = false
		for i, modifier in pairs(modifiers) do
			if modifier[1] == modifierName then
				modifiers = modifier[2]
				found = true
				break
			end
		end
		modifiers = not found and 0 or modifiers
	end
	return modifiers
end
local CountryModifiers = {
	["Technology"] = {},
	["Policies"] = {},
	["Modifiers"] = {},
	["Taxation"] = {},
	["Conscription"] = {},
	["Doctrines"] = {},
	["Ideology"] = {},
}
for i, modifier in pairs(workspace.CountryManager.CountryStatSample.Technology.Modifiers:GetChildren()) do
	CountryModifiers.Technology[modifier.Name] = true
end
for i, policy in pairs(game.ReplicatedStorage.Assets.Laws.Policies:GetChildren()) do
	CountryModifiers.Policies[policy.Name] = {}
	for i, effect in pairs(policy.Effects:GetChildren()) do
		CountryModifiers.Policies[policy.Name][effect.Name] = effect
	end
end
for i, modifier in pairs(game.ReplicatedStorage.Assets.Laws.Modifiers:GetChildren()) do
	CountryModifiers.Modifiers[modifier.Name] = {}
	for i, effect in pairs(modifier.Effects:GetChildren()) do
		CountryModifiers.Modifiers[modifier.Name][effect.Name] = effect
	end
end
for i, tax in pairs(game.ReplicatedStorage.Assets.Laws.Taxation:GetChildren()) do
	CountryModifiers.Taxation[tax.Name] = {}
	for i, child in pairs(tax:GetChildren()) do
		CountryModifiers.Taxation[tax.Name][child.Name] = child
	end
end
for i, conscription in pairs(game.ReplicatedStorage.Assets.Laws.Conscription:GetChildren()) do
	CountryModifiers.Conscription[conscription.Name] = {}
	for i, child in pairs(conscription:GetChildren()) do
		CountryModifiers.Conscription[conscription.Name][child.Name] = child
	end
end
for i, doctrine in pairs(game.ReplicatedStorage.Assets.Laws.Doctrines:GetDescendants()) do
	if doctrine.Name == "CountryModifiers" then
		if not CountryModifiers.Doctrines[doctrine.Parent.Parent.Name .. doctrine.Parent.Name] then
			CountryModifiers.Doctrines[doctrine.Parent.Parent.Name .. doctrine.Parent.Name] = {}
		end
		for i, child in pairs(doctrine:GetChildren()) do
			CountryModifiers.Doctrines[doctrine.Parent.Parent.Name .. doctrine.Parent.Name][child.Name] = child
		end
	end
end
for i, ideology in pairs(game.ReplicatedStorage.Assets.Laws.Ideology:GetChildren()) do
	CountryModifiers.Ideology[ideology.Name] = {}
	for i, stat in pairs(ideology.CountryModifiers:GetChildren()) do
		CountryModifiers.Ideology[ideology.Name][stat.Name] = stat
	end
end
function module.Function.CountryModifier(country, modifierName, Type)
	-- upvalues: (copy) cache, (copy) unitModifiers, (copy) module, (copy) CountryModifiers
	if cache[country .. modifierName] and tick() - cache[country .. modifierName][2] < 4 then
		if not Type then
			return cache[country .. modifierName][1]
		end
		if Type == "Color" then
			return cache[country .. modifierName][3]
		end
	end
	local idk1 = {}
	local unitModifier1 = unitModifiers[modifierName][1]
	local unitModifier2 = unitModifiers[modifierName][1]
	local stabilityModifier =
		module.Function.StabilityAspect(workspace.CountryData[country].Data.Stability.Value, modifierName)
	local warExhaustionModifier =
		module.Function.WarExhaustionAspect(workspace.CountryData[country].Power.WarExhaustion.Value, modifierName)
	local conscriptionModifier =
		CountryModifiers.Conscription[tostring(workspace.CountryData[country].Laws.Conscription.Value)][modifierName]
	if conscriptionModifier then
		table.insert(idk1, 1 + conscriptionModifier.Value / 100)
	end
	local idk2 = 0
	local idk3
	if CountryModifiers.Technology[modifierName] then
		local techModifier = workspace.CountryData[country].Technology.Modifiers[modifierName]
		if techModifier:IsA("NumberValue") then
			idk3 = techModifier.Value
		else
			idk2 = techModifier.Value
			idk3 = 1
		end
	else
		idk3 = 1
	end
	for i, policy in pairs(workspace.CountryData[country].Laws.Policies:GetChildren()) do
		local policyModifier = CountryModifiers.Policies[policy.Name][modifierName]
		if policyModifier then
			if policyModifier:IsA("NumberValue") then
				idk3 = idk3 + policyModifier.Value
			else
				idk2 = idk2 + policyModifier.Value
			end
		end
	end
	for i, v in pairs(workspace.CountryData[country].Laws.Modifiers:GetChildren()) do
		local countryModifier = CountryModifiers.Modifiers[v.Name][modifierName]
		if countryModifier then
			if countryModifier:IsA("NumberValue") and not countryModifier:GetAttribute("Base") then
				idk3 = idk3 + countryModifier.Value
			else
				idk2 = idk2 + countryModifier.Value
			end
		end
	end
	local taxModifier =
		CountryModifiers.Taxation[tostring(workspace.CountryData[country].Laws.Taxation.Value)][modifierName]
	if taxModifier then
		if taxModifier:IsA("NumberValue") then
			idk3 = idk3 * taxModifier.Value
		else
			idk2 = idk2 + taxModifier.Value
		end
	end
	for i, doctrineModifier in pairs(workspace.CountryData[country].Laws.Doctrines:GetChildren()) do
		local instance = CountryModifiers.Doctrines[doctrineModifier.Name .. doctrineModifier.Value][modifierName]
		if instance then
			if instance:IsA("NumberValue") then
				idk3 = idk3 * instance.Value
			else
				idk2 = idk2 + instance.Value
			end
		end
	end
	local ideologyModifier = CountryModifiers.Ideology[workspace.CountryData[country].Laws.Ideology.Value][modifierName]
	if ideologyModifier then
		if not string.match(modifierName, "Ideology Power") then
			local ideologyPower = 1
			if not ideologyModifier:GetAttribute("NoIdeologyPower") then
				ideologyPower = ideologyPower
					* module.Function.CountryModifier(country, "Ideology Power")
					* module.Function.CountryModifier(
						country,
						workspace.CountryData[country].Laws.Ideology.Value .. " Ideology Power"
					)
			end
			unitModifier2 = unitModifier2 + ideologyModifier.Value * ideologyPower
		end
	end
	table.insert(idk1, 1 + stabilityModifier / 100)
	table.insert(idk1, 1 + warExhaustionModifier / 100)
	table.insert(idk1, idk3)
	local modifier = unitModifier2 + idk2
	for v93 = 1, #idk1 do
		modifier = modifier * idk1[v93]
	end
	if unitModifier1 == 100 then
		modifier = modifier / 100
	end
	cache[country .. modifierName] = { modifier, tick(), unitModifiers[modifierName][2] }
	if Type == "Color" then
		return unitModifiers[modifierName][2]
	else
		return modifier
	end
end
return module
