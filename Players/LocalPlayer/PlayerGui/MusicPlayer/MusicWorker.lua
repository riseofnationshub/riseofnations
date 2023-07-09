-- last game update date when this was written 4/15/2023
-- script hash 5cdaf601fe1f007798d6a7c1f347e840b0b21cf806f2a3eccb48ac9c661fc7349716cda9ca2967af29090c4e989ee94d
-- decompiled by Sentinel (took 1.46394ms)
local _ = game.Players.LocalPlayer
local musicB = script.Parent.MusicB
local mode = musicB.Mode
local allMusic = {}
local scriptChildren = script:GetChildren()
for i, child in pairs(scriptChildren) do
	allMusic[child.Name] = {}
	local childChildren = child:GetChildren()
	for i, v in pairs(childChildren) do
		table.insert(allMusic[child.Name], { v.SoundId, v.Name })
	end
	child:Destroy()
end
local musicForMode = allMusic[mode.Value]
local track = musicForMode[Random.new():NextInteger(1, #musicForMode)]
print("Playing " .. track[2])
musicB.MouseOverText.Value = "Playing: " .. track[2]
musicB.Music.SoundId = track[1]
musicB.Music:Play()
musicB.Music.Ended:connect(function()
	-- upvalues: (copy) musicB, (copy) allMusic, (copy) mode
	warn("Track ended")
	musicB.Music.TimePosition = 0
	local musicForMode = allMusic[mode.Value]
	local track = musicForMode[Random.new():NextInteger(1, #musicForMode)]
	print("Playing " .. track[2])
	musicB.MouseOverText.Value = "Playing: " .. track[2]
	musicB.Music.SoundId = track[1]
	musicB.Music:Play()
end)
musicB.MouseButton1Click:connect(function()
	-- upvalues: (copy) musicB
	if musicB.Music.Volume == 0 then
		musicB.Music.Volume = 0.75
		musicB.ImageColor3 = Color3.new(1, 1, 1)
	else
		musicB.Music.Volume = 0
		musicB.ImageColor3 = Color3.new(1, 0, 0)
	end
end)
musicB.Mode.Changed:Connect(function(_)
	-- upvalues: (copy) musicB
	warn("Changed music mode")
	if musicB.ImageColor3 ~= Color3.new(1, 0, 0) then
		for i = 20, -1, -1 do
			musicB.Music.Volume = i / 20 * 0.75
			wait()
		end
	end
	musicB.Music.TimePosition = musicB.Music.TimeLength - 0.1
	if musicB.ImageColor3 ~= Color3.new(1, 0, 0) then
		musicB.Music.Volume = 0.75
	end
end)
