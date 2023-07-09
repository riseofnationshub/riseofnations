-- last game update date when this was written 4/15/2023
-- script hash 993329c46a1fe9ab7185b5a9982fec5d5c3d85d6b32c574cf07bef4479f7c6e9996dccaa5c4d5810793e38244b4f4f37
-- decompiled by Sentinel (took 1.886083ms)
local TweenService = game:GetService("TweenService")
local function nukeEffects(nuclearExplosion, scale)
	-- upvalues: (copy) TweenService
	local vector1 = Vector3.new(0, 0, 0)
	local vector2 = Vector3.new(5, 5, 5) * scale * 1.5
	local vector3 = Vector3.new(9, 18, 9) * scale * 2
	local vector4 = Vector3.new(5, 4, 5) * scale * 1.25
	nuclearExplosion.Fireball.Sound:Play()
	nuclearExplosion.Fireball.Mesh.Scale = vector1
	nuclearExplosion.Fireball.Transparency = 0
	TweenService
		:Create(nuclearExplosion.Fireball.Mesh, TweenInfo.new(3.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			["Scale"] = Vector3.new(100, 100, 100) * scale * 1000,
		})
		:Play()
	TweenService
		:Create(nuclearExplosion.Fireball, TweenInfo.new(2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			["Color"] = Color3.fromRGB(226, 155, 64),
		})
		:Play()
	nuclearExplosion.Shockwave.Mesh.Scale = vector1
	nuclearExplosion.Shockwave.Transparency = 0.5
	TweenService:Create(nuclearExplosion.Shockwave.Mesh, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		["Scale"] = Vector3.new(1000, 1000, 1000) * scale * 250,
	}):Play()
	TweenService:Create(nuclearExplosion.Shockwave, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		["Transparency"] = 1,
	}):Play()
	nuclearExplosion.GroundShockwave.Mesh.Scale = vector1
	nuclearExplosion.GroundShockwave.Transparency = 0.5
	TweenService
		:Create(
			nuclearExplosion.GroundShockwave.Mesh,
			TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				["Scale"] = Vector3.new(250, 250, 1) * scale,
			}
		)
		:Play()
	TweenService:Create(nuclearExplosion.GroundShockwave, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		["Transparency"] = 1,
	}):Play()
	nuclearExplosion.MushroomBase.Mesh.Scale = vector1
	nuclearExplosion.MushroomCloud.Mesh.Scale = vector1
	nuclearExplosion.MushroomStem.Mesh.Scale = vector1
	wait(3)
	nuclearExplosion.MushroomCloud.Mesh.Scale = vector2
	nuclearExplosion.MushroomCloud.CFrame = nuclearExplosion.MushroomStem.CFrame
		+ nuclearExplosion.Fireball.Position.Unit * scale * 30
	TweenService:Create(nuclearExplosion.MushroomCloud.Mesh, TweenInfo.new(15, Enum.EasingStyle.Quad), {
		["Scale"] = vector2 * Vector3.new(3, 3, 3),
	}):Play()
	TweenService:Create(nuclearExplosion.MushroomCloud, TweenInfo.new(16, Enum.EasingStyle.Quad), {
		["Position"] = nuclearExplosion.MushroomStem.Position
			+ vector3.Y * nuclearExplosion.Fireball.Position.Unit * 2.25,
	}):Play()
	TweenService:Create(nuclearExplosion.MushroomStem.Mesh, TweenInfo.new(3, Enum.EasingStyle.Quad), {
		["Scale"] = vector3,
	}):Play()
	nuclearExplosion.MushroomBase.Transparency = 1
	TweenService:Create(nuclearExplosion.MushroomBase, TweenInfo.new(1, Enum.EasingStyle.Linear), {
		["Transparency"] = 0,
	}):Play()
	TweenService:Create(nuclearExplosion.MushroomStem, TweenInfo.new(3, Enum.EasingStyle.Linear), {
		["Color"] = Color3.new(0.45, 0.45, 0.45),
	}):Play()
	TweenService:Create(nuclearExplosion.MushroomCloud, TweenInfo.new(3, Enum.EasingStyle.Linear), {
		["Color"] = Color3.new(0.45, 0.45, 0.45),
	}):Play()
	TweenService:Create(nuclearExplosion.MushroomBase, TweenInfo.new(3, Enum.EasingStyle.Linear), {
		["Color"] = Color3.new(0.45, 0.45, 0.45),
	}):Play()
	nuclearExplosion.MushroomBase.Mesh.Scale = vector4 / 2
	TweenService:Create(nuclearExplosion.MushroomBase.Mesh, TweenInfo.new(15, Enum.EasingStyle.Quad), {
		["Scale"] = vector4 * Vector3.new(3, 2, 3),
	}):Play()
	TweenService:Create(nuclearExplosion.Fireball, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
		["Transparency"] = 1,
	}):Play()
	wait(3)
	TweenService:Create(nuclearExplosion.MushroomBase, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
		["Transparency"] = 1,
	}):Play()
	wait(5)
	TweenService:Create(nuclearExplosion.MushroomStem, TweenInfo.new(8.333333333333334, Enum.EasingStyle.Linear), {
		["Transparency"] = 1,
	}):Play()
	TweenService:Create(nuclearExplosion.MushroomCloud, TweenInfo.new(8.333333333333334, Enum.EasingStyle.Linear), {
		["Transparency"] = 1,
	}):Play()
	wait(20)
	nuclearExplosion:Destroy()
end
workspace.GameManager.NukeEffect.OnClientEvent:Connect(function(pos)
	-- upvalues: (copy) nukeEffects
	local nuclearExplosion = game.ReplicatedStorage.Assets.FX.NuclearExplosion:Clone()
	nuclearExplosion:SetPrimaryPartCFrame(
		CFrame.lookAt(Vector3.new(), pos) * CFrame.new(0, 0, -workspace.Baseplate.Size.X / 2)
	)
	nuclearExplosion.Parent = workspace
	nukeEffects(nuclearExplosion, 0.011)
end)
