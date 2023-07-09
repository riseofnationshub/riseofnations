-- last game update date when this was written 4/15/2023
-- script hash da32a89fb7ccad93e02c300a80c0b839c7b55a072d5f717d1540a68c9476f785f1e4967914163a6dd96d8ed324a739ff
-- decompiled by Sentinel (took 2.257031ms)
local module = {
	["Policy"] = function(country, policyName)
		local countryData = workspace.CountryData[country]
		local policy = game.ReplicatedStorage.Assets.Laws.Policies[policyName]
		local default = true
		if policy:FindFirstChild("Requirements") then
			for i, requirement in pairs(policy.Requirements:GetChildren()) do
				if requirement.Name == "Ideology" then
					if countryData.Laws.Ideology.Value ~= requirement.Value then
						return false
					end
				elseif requirement.Name == "NOTIdeology" then
					if countryData.Laws.Ideology.Value == requirement.Value then
						return false
					end
				elseif requirement.Name == "Policy" then
					if not countryData.Laws.Policies:FindFirstChild(requirement.Value) then
						return false
					end
				elseif requirement.Name == "NOTPolicy" then
					if countryData.Laws.Policies:FindFirstChild(requirement.Value) then
						return false
					end
				elseif requirement.Name == "Stability" then
					if
						countryData.Data.Stability.Value > requirement.Value.Z
						or countryData.Data.Stability.Value < requirement.Value.X
					then
						return false
					end
				elseif requirement.Name == "War" then
					if (workspace.Wars:FindFirstChild(country, true) and true or false) ~= requirement.Value then
						return false
					end
				end
			end
		end
		return default
	end,
}
local Assets = game.ReplicatedStorage.Assets
function module.SkinOwnership(player, skinName)
	-- upvalues: (copy) Assets
	local ownsGamepass = true
	if not Assets.Skins:FindFirstChild(skinName) then
		return false
	end
	if Assets.Skins[skinName]:FindFirstChild("Gamepass") then
		local status, errorMessage = pcall(function()
			-- upvalues: (copy) player, (ref) Assets, (copy) skinName, (ref) ownsGamepass
			if
				not game:GetService("MarketplaceService")
					:UserOwnsGamePassAsync(player.userId, Assets.Skins[skinName].Gamepass.Value)
			then
				ownsGamepass = false
			end
		end)
		if not status then
			ownsGamepass = false
			warn(errorMessage)
		end
	end
	local ownsSkin
	if ownsGamepass then
		ownsSkin = ownsGamepass
	elseif Assets.Skins[skinName]:FindFirstChild("Requirement") then
		ownsGamepass = true
		if Assets.Skins[skinName].Requirement.Value == "Formable" then
			if player.FormableSave:FindFirstChild(Assets.Skins[skinName].Requirement.Form.Value) then
				if Assets.Skins[skinName].Requirement.As.Value == "ANY" then
					ownsSkin = ownsGamepass
				elseif
					player.FormableSave[Assets.Skins[skinName].Requirement.Form.Value]:FindFirstChild(
						Assets.Skins[skinName].Requirement.As.Value
					)
				then
					ownsSkin = ownsGamepass
				else
					ownsGamepass = false
					ownsSkin = ownsGamepass
				end
			else
				ownsGamepass = false
				ownsSkin = ownsGamepass
			end
		else
			ownsSkin = ownsGamepass
		end
	else
		ownsSkin = ownsGamepass
	end
	ownsGamepass = player:GetAttribute("Authorized") and true or player:FindFirstChild(skinName) and true or ownsSkin
	return ownsGamepass or player:GetRankInGroup(832833) == 5 and true or ownsGamepass
end
return module
