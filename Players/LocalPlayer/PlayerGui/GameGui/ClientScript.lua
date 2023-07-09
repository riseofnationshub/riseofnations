-- last game update date when this was written 4/15/2023
-- script hash 9bf089f04c46c8d8cddc8f4cdaf954267347d8b9cd70d028de168df318ea287eac6539460063e12f605e9659fcf009db
-- decompiled by Sentinel (took 303.705429ms)
local LocalPlayer = game.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local v_u_4 = 0
local v_u_5 = 0
local v_u_6 = 64
local v_u_7 = 0
local v_u_8 = 0
local v_u_9 = 0
local v_u_10 = 0
local unusedVector = Vector3.new()
local isMobile = false
local PlayerXP = LocalPlayer:WaitForChild("XP", 600)
local v_u_14 = 0
local leftMouseDown = false
local citySelection = false
local isShiftDown = false
local v_u_18 = false
local cityAnnexationFrame = false
local mouseInteractionType = ""
local groupInteraction = ""
local selected = {}
local tags = {}
local resourcesNumberTags = {}
local highlitedCities = {}
local currentCountry = ""
local currentCountryData = nil
local selectedCenterPos = nil
local moveUnitPositions = nil
local Units = workspace.Units:GetChildren()
local currentMapType = "Political"
local GameGui = script.Parent
local MainFrame = GameGui.MainFrame
local FirstFrame = GameGui.FirstFrame
local MapFrame = GameGui.MapFrame
local Assets = game.ReplicatedStorage.Assets
local receivedData = {}
local loopFunctions = {}
local loopFunctions2 = {}
local ReferenceTable = require(script.ReferenceTable)
local GetModifier = require(workspace.FunctionDump.ValueCalc.GetModifier)
local CountryModifier = GetModifier.Function.CountryModifier
workspace.CountryManager.ClientReceiver.OnClientEvent:Connect(function(dataKey, data)
	-- upvalues: (copy) receivedData
	receivedData[dataKey] = data
end)
local TeleportData = game:GetService("TeleportService"):GetLocalPlayerTeleportData()
print(TeleportData)
if TeleportData then
	workspace.Transmitter.Set:FireServer(TeleportData)
	print("This is set")
end
repeat
	wait(1)
until workspace.CityPlacer.Ready.Value
local function ClearList(list, filter)
	local filter = filter == nil and {} or filter
	local listParentChildren = list.Parent:GetChildren()
	for i = 1, #listParentChildren do
		if listParentChildren[i]:IsA("GuiBase") then
			if not table.find(filter, listParentChildren[i]) then
				listParentChildren[i]:Destroy()
			end
		end
	end
end
local function SetFlag(flag, countryName)
	-- upvalues: (copy) Assets, (copy) MainFrame
	if countryName then
		if Assets.Flag:FindFirstChild(countryName) then
			if not flag:GetAttribute("OverlayOn") then
				local overlay = script.CommonGui.Overlay:Clone()
				overlay.Visible = MainFrame.TabMenu.FlagOverlay:GetAttribute("Setting")
				overlay.Parent = flag
				game.CollectionService:AddTag(overlay, "Overlay")
				flag:SetAttribute("OverlayOn", true)
			end
			if Assets.Flag[countryName]:GetAttribute("Overlay") then
				flag.Overlay.Image = Assets.Flag[countryName]:GetAttribute("Overlay")
			else
				flag.Overlay.Image = script.CommonGui.Overlay.Image
			end
			flag.Image = Assets.Flag[countryName].Texture
		end
	end
end
local function PositionToCoord(vector)
	return math.deg((math.acos((vector.Unit:Dot((vector * Vector3.new(1, 0, 1)).Unit))))) * math.sign(vector.Y),
		math.deg(
			(math.acos((workspace.Baseplate.CFrame.LookVector.Unit.Unit:Dot((vector * Vector3.new(1, 0, 1)).Unit))))
		) * math.sign(vector.X)
end
local function PopUp(title, description, buttonTitle, flagCountryName)
	-- upvalues: (copy) MainFrame, (copy) SetFlag, (ref) currentCountry, (copy) Assets, (copy) GameGui
	local mainFrameChildren = MainFrame:GetChildren()
	local alertAmount = 0
	for i = 1, #mainFrameChildren do
		if mainFrameChildren[i].Name == "AlertSample" then
			alertAmount = alertAmount + 1
		end
	end
	local alert = script.AlertSample:Clone()
	alert.Title.Text = title
	alert.Desc.Text = description
	alert.Yes.Text = buttonTitle
	SetFlag(alert.FlagOwn, currentCountry)
	if flagCountryName == nil then
		SetFlag(alert.Flag, currentCountry)
	else
		SetFlag(alert.Flag, flagCountryName)
	end
	alert.Yes.MouseButton1Click:Connect(function()
		-- upvalues: (ref) Assets, (ref) GameGui, (copy) alert
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		alert:Destroy()
	end)
	alert.Position = UDim2.new(0.5, 40 * alertAmount, 0.5, 20 * alertAmount)
	alert.Parent = MainFrame
	alert.Desc.Size = UDim2.new(1, -10, 0, (math.ceil(alert.Desc.TextBounds.Y)))
	alert.Size = UDim2.new(0, 300, 0, 65 + math.ceil(alert.Desc.TextBounds.Y))
	if title ~= "War against us" then
		if title == "War declaration" then
			local declareWarSound = Assets.Audio.Declare_War:Clone()
			declareWarSound.Parent = GameGui
			declareWarSound:Play()
			game.Debris:AddItem(declareWarSound, 15)
			return
		end
		if title == "War declaration on us" then
			local declaredOnSound = Assets.Audio.Declared_On:Clone()
			declaredOnSound.Parent = GameGui
			declaredOnSound:Play()
			game.Debris:AddItem(declaredOnSound, 15)
			return
		end
		if title == "Peace treaty signed" then
			local peaceOutSound = Assets.Audio.PeaceOut:Clone()
			peaceOutSound.Parent = GameGui
			peaceOutSound:Play()
			game.Debris:AddItem(peaceOutSound, 15)
			return
		end
		local notificationSound = Assets.Audio.Notification:Clone()
		notificationSound.Parent = GameGui
		notificationSound:Play()
		game.Debris:AddItem(notificationSound, 15)
	end
end
local function CityRange(unit, radius, tag, position)
	-- upvalues: (ref) currentCountry, (copy) GameGui
	local supplyAvailable = false
	local explosion = Instance.new("Explosion")
	explosion.BlastPressure = 0
	explosion.BlastRadius = radius
	explosion.Visible = false
	if position == nil then
		explosion.Position = unit.Position
	else
		explosion.Position = position
	end
	explosion.Parent = workspace.Baseplate
	explosion.Hit:Connect(function(part, distance)
		-- upvalues: (ref) currentCountry, (copy) tag, (copy) unit, (ref) GameGui, (ref) supplyAvailable
		if part.Parent.Parent == workspace.Baseplate.Cities and currentCountry == part.Parent.Name then
			if tag == "UnitTag" then
				local maxDistance = part.Buildings:FindFirstChild("Sonar Station") and 10 or 2.5
				if distance < maxDistance then
					if unit.Type.Value ~= "Submarine" then
						unit.Tag.Enabled = GameGui.Enabled
						return
					end
					if maxDistance == 10 and distance < 2.5 then
						unit.Tag.Enabled = GameGui.Enabled
						return
					end
				end
			elseif tag == "Supply" then
				supplyAvailable = true
			end
		end
	end)
	if tag == "Supply" then
		wait()
		return supplyAvailable
	end
end
local framesWithButtons = {}
for i, v in pairs(MainFrame:GetDescendants()) do
	if v.Name == "QuickSearchSet" then
		local box = v.Parent.Box
		local listFrame = v.Value
		box:GetPropertyChangedSignal("Text"):Connect(function()
			-- upvalues: (copy) listFrame, (copy) box
			for i, v2 in pairs(listFrame:GetChildren()) do
				if v2:IsA("GuiBase") then
					if v2 ~= box.Parent then
						if string.match(string.lower(v2.Name), string.lower(box.Text)) == nil then
							v2.Visible = false
						else
							v2.Visible = true
						end
					end
				end
			end
		end)
		v:Destroy()
	end
end
local function MakeCountryList(frame, addButtons)
	-- upvalues: (ref) currentCountry, (copy) SetFlag, (copy) Assets, (copy) framesWithButtons
	local countries = workspace.Baseplate.Cities:GetChildren()
	local buttons = {}
	for i = 1, #countries do
		if countries[i].Name ~= currentCountry or addButtons then
			local button = frame.UIListLayout.Sample:Clone()
			button.Name = countries[i].Name
			button.Text = countries[i].Name
			SetFlag(button.Flag, countries[i].Name)
			button.Parent = frame
			table.insert(buttons, button)
		end
	end
	frame.UIListLayout.SortOrder = "LayoutOrder"
	local search = script.SearchSample:Clone()
	search.Parent = frame
	local searchBox = search.Box
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		-- upvalues: (copy) frame, (ref) Assets, (copy) searchBox
		for i, v in pairs(frame:GetChildren()) do
			if Assets.Flag:FindFirstChild(v.Name) then
				if string.match(string.lower(v.Name), string.lower(searchBox.Text)) == nil then
					v.Visible = false
				else
					v.Visible = true
				end
			end
		end
	end)
	table.insert(framesWithButtons, frame)
	frame.CanvasSize = UDim2.new(0, 0, 0, #countries * 35)
	return buttons
end
local function MakeMouseOver(frame, text, textSize, maxSize)
	-- upvalues: (copy) GameGui, (copy) MainFrame, (ref) currentCountryData, (copy) ReferenceTable, (ref) selected, (copy) Assets, (copy) CountryModifier, (ref) currentCountry, (copy) GetModifier, (copy) Mouse
	frame.MouseMoved:Connect(function()
		-- upvalues: (ref) GameGui, (copy) textSize, (copy) text, (copy) frame, (ref) MainFrame, (ref) currentCountryData, (ref) ReferenceTable, (ref) selected, (ref) Assets, (ref) CountryModifier, (ref) currentCountry, (ref) GetModifier, (copy) maxSize, (ref) Mouse
		GameGui.MouseOver.Visible = true
		GameGui.MouseOver.Label.TextSize = textSize
		local mouseOverText = text
		if type(mouseOverText) == "function" then
			mouseOverText = text()
		elseif frame:FindFirstChild("MouseOverText") then
			mouseOverText = frame.MouseOverText.Value
		elseif frame:GetAttribute("MouseOverText") then
			mouseOverText = frame:GetAttribute("MouseOverText")
		elseif frame == MainFrame.StatsFrame.Stats.Money then
			local revenueMillions, revenueThousands, revenueHundrends =
				tostring((currentCountryData.Economy.Revenue:GetAttribute("Total"))):match("(%-?%d?)(%d*)(%.?.*)")
			local income = '<font color="rgb('
				.. ReferenceTable.Colors.Positive[1]
				.. ')">'
				.. "$"
				.. revenueMillions
				.. revenueThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. revenueHundrends
				.. "</font>"
			local expenseMillions, expenseThousands, expenseHundrends =
				tostring((currentCountryData.Economy.Expenses:GetAttribute("Total"))):match("(%-?%d?)(%d*)(%.?.*)")
			local expense = '<font color="rgb('
				.. ReferenceTable.Colors.Negative[1]
				.. ')">'
				.. "$"
				.. expenseMillions
				.. expenseThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. expenseHundrends
				.. "</font>"
			local balanceMillions, balanceThousands, balanceHundrends = tostring(
				currentCountryData.Economy.Revenue:GetAttribute("Total")
					- currentCountryData.Economy.Expenses:GetAttribute("Total")
			):match("(%-?%d?)(%d*)(%.?.*)")
			mouseOverText = "BALANCE\n \nIncome: "
				.. income
				.. "\nExpenses: "
				.. expense
				.. "\n \nBalance: "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. "$"
				.. balanceMillions
				.. balanceThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. balanceHundrends
				.. "</font>"
		elseif frame == MainFrame.CenterFrame.EconomyFrame.Main.ExpensesFrame.TradeImport then
			mouseOverText = "Trade: \n"
			for i, v in pairs(currentCountryData.Resources:GetDescendants()) do
				if v.Parent.Name == "Trade" then
					if 0 < v.Value.X then
						mouseOverText = mouseOverText
							.. "Importing "
							.. math.ceil(v.Value.X * 100) / 100
							.. " Units of "
							.. v.Parent.Parent.Name
							.. " from "
							.. v.Name
							.. "\n"
					end
				end
			end
		elseif frame == MainFrame.CenterFrame.EconomyFrame.Main.IncomeFrame.TradeExport then
			mouseOverText = "Trade: \n"
			for i, v in pairs(currentCountryData.Resources:GetDescendants()) do
				if v.Parent.Name == "Trade" then
					if v.Value.X < 0 then
						mouseOverText = mouseOverText
							.. "Exporting "
							.. math.ceil(-v.Value.X * 100) / 100
							.. " Units of "
							.. v.Parent.Parent.Name
							.. " to "
							.. v.Name
							.. "\n"
					end
				end
			end
		elseif
			frame == MainFrame.WarOverFrame.OverallFrame.AStats.Death
			or frame == MainFrame.WarOverFrame.OverallFrame.BStats.Death
		then
			mouseOverText = "Casualities: \n"
			local frame = MainFrame.WarOverFrame.OverallFrame.AFrame
			if frame.Parent.Name == "BStats" then
				frame = MainFrame.WarOverFrame.OverallFrame.BFrame
			end
			for i, v in pairs(frame:GetChildren()) do
				if v:IsA("Frame") then
					local millions, thousands, hundrends = tostring(
						workspace.Wars[MainFrame.WarOverFrame.CurrentWar.Value]:FindFirstChild(v.Name, true).Losses.Value
					):match("(%-?%d?)(%d*)(%.?.*)")
					mouseOverText = mouseOverText
						.. "\n"
						.. v.Name
						.. ": "
						.. millions
						.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. hundrends
				end
			end
		elseif frame == MainFrame.UnitFrame.Main.XP then
			mouseOverText = "Total Experience: "
				.. math.ceil(selected[1].Current.Training.Value * 100) / 100
				.. " / 300\n \nAttack/Defense Bonus: "
				.. math.ceil((selected[1].Current.Training.Value - 100) * 100) / 100
				.. " %"
		elseif frame == MainFrame.UnitFrame.Main.Entrenchment.End then
			mouseOverText = "Combat Modifier from terrain: "
				.. math.ceil(
					(1 + selected[1].Current.UrbanBonus.Terrain.Value * selected[1].Current.Entrenchment.Value / 100)
						* 100
				) / 100
				.. "x"
		elseif frame == MainFrame.CenterFrame.DiplomacyFrame.Main.Flag then
			local rank = workspace.CountryData[MainFrame.CenterFrame.DiplomacyFrame.Country.Value].Ranking.Value
			local rankText = "Minor Power"
			if rank <= 3 then
				rankText = "Superpower"
			elseif 3 < rank then
				rankText = rank <= 20 and "Regional Power" or rankText
			end
			mouseOverText = MainFrame.CenterFrame.DiplomacyFrame.Country.Value
				.. "\n"
				.. rankText
				.. "\nRanking: "
				.. rank
		elseif frame.Parent.Parent == MainFrame.CenterFrame.CountryFrame.Main.ConscriptionFrame then
			local conscription = Assets.Laws.Conscription[frame.Name]
			local stabilityGoalText = 4 <= tonumber(frame.Name) and "\n \nMust be at war" or ""
			local stabilityModifiersText = "Law: "
				.. frame.Text
				.. "\n \nRecruitable Population: "
				.. conscription.Value
				.. "%\n"
			for i, v in pairs(conscription:GetChildren()) do
				stabilityModifiersText = stabilityModifiersText .. v.Name .. ": " .. v.Value .. "%\n"
			end
			mouseOverText = stabilityModifiersText .. "\nRequires 200 Political Power" .. stabilityGoalText
		elseif frame.Parent == MainFrame.CenterFrame.CountryFrame.Ideologies then
			local ideology = Assets.Laws.Ideology[frame.Name]
			local politicalPower = math.clamp(250 * ideology.Value, 250, math.huge)
			local statsText = "\n"
			for i, stat in pairs(ideology.Stats:GetChildren()) do
				local statValueBefore = 0 < stat.Value and "+" or ""
				local statValueType = stat.Name == "Diplomatic Actions" and "" or "%"
				local ideologyPower = CountryModifier(currentCountry, "Ideology Power")
					* CountryModifier(currentCountry, currentCountryData.Laws.Ideology.Value .. " Ideology Power")
				local color = ReferenceTable.Colors.Negative[1]
				if 0 < stat.Value == CountryModifier(currentCountry, stat.Name, "Color") then
					color = ReferenceTable.Colors.Positive[1]
				end
				statsText = statsText
					.. "\n"
					.. stat.Name
					.. ": "
					.. statValueBefore
					.. '<font color="rgb('
					.. color
					.. ')">'
					.. math.ceil(stat.Value * (stat:GetAttribute("NoIdeologyPower") and 1 or ideologyPower) * 100) / 100
					.. statValueType
					.. "</font>"
			end
			mouseOverText = "Ideology: "
				.. frame.Name
				.. statsText
				.. "\n \nRequires "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. politicalPower
				.. "</font>"
				.. " Political Power\n-"
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Negative[1]
				.. ')">'
				.. 3 * politicalPower / 250
				.. "</font>"
				.. "% Stability"
		elseif frame == MainFrame.CenterFrame.CountryFrame.Main.Power then
			mouseOverText = math.floor(currentCountryData.Power.Political.Value * 10) / 10
				.. " Political Power\n \nIncrease: "
				.. math.floor(currentCountryData.Power.Political.Increase.Value * 10) / 10
		elseif frame == MainFrame.CenterFrame.MilitaryFrame.Main.Power then
			mouseOverText = math.floor(currentCountryData.Power.Military.Value * 10) / 10
				.. " Military Power\n \nIncrease: +"
				.. math.floor(currentCountryData.Power.Military.Increase.Value * 10) / 10
		elseif frame == MainFrame.CenterFrame.CountryFrame.Main.Stability then
			local stabilityGoalText = "     "
			for i, v in pairs(currentCountryData.Data.Stability.Goal:GetChildren()) do
				stabilityGoalText = stabilityGoalText .. v.Name .. ": " .. math.floor(v.Value * 10) / 10 .. "%\n     "
			end
			local stabilityModifiersText = ""
			for i, v in pairs(GetModifier.Function.StabilityAspect(currentCountryData.Data.Stability.Value)) do
				stabilityModifiersText = stabilityModifiersText
					.. v[1]
					.. ": "
					.. (0 < v[2] and "+" or "")
					.. math.floor(v[2] * 100) / 100
					.. "%\n"
			end
			mouseOverText = math.floor(currentCountryData.Data.Stability.Value * 100) / 100
				.. "% Stability\nGoal: "
				.. math.floor(currentCountryData.Data.Stability.Goal.Value * 10) / 10
				.. "%\n"
				.. stabilityGoalText
				.. "\nChange: "
				.. math.floor(currentCountryData.Data.Stability.Change.Value * 100) / 100
				.. "%\n \n"
				.. stabilityModifiersText
		elseif frame == MainFrame.CenterFrame.CountryFrame.Main.WarEx then
			local warExhaustionBefore = 0 < currentCountryData.Power.WarExhaustion.Increase.Value and "+" or ""
			local warExhaustionModifiersText = ""
			for i, v in pairs(GetModifier.Function.WarExhaustionAspect(currentCountryData.Power.WarExhaustion.Value)) do
				warExhaustionModifiersText = warExhaustionModifiersText
					.. v[1]
					.. ": "
					.. (0 < v[2] and "+" or "")
					.. math.floor(v[2] * 100) / 100
					.. "%\n"
			end
			mouseOverText = math.floor(currentCountryData.Power.WarExhaustion.Value * 1000) / 1000
				.. " War Exhaustion\n \nChange: "
				.. warExhaustionBefore
				.. math.floor(currentCountryData.Power.WarExhaustion.Increase.Value * 1000) / 1000
				.. "\n \n"
				.. warExhaustionModifiersText
		elseif frame.Parent.Parent ~= MainFrame.CenterFrame.CountryFrame.Main.DecisionFrame then
			if frame == MainFrame.CenterFrame.TechnologyFrame.Power then
				mouseOverText = math.floor(currentCountryData.Power.Research.Value * 10) / 10
					.. " Research Power\n \nIncrease: +"
					.. math.floor(currentCountryData.Power.Research.Increase.Value * 10) / 10
			elseif frame.Parent == MainFrame.CityFrame.BuildingFrame.BuildingFrame then
				local building = Assets.Buildings[frame.Name]
				local requiresText = "Requires: \n"
				if building:FindFirstChild("TechnologyRequired") then
					for i, v in pairs(building.TechnologyRequired:GetChildren()) do
						requiresText = requiresText
							.. " Requires Technology: "
							.. Assets.Technology[v.Name].Title.Value
							.. "\n"
					end
				end
				if building:FindFirstChild("Input") then
					for i, v in pairs(building.Input:GetChildren()) do
						requiresText = requiresText
							.. v.Value
							.. " Units of "
							.. v.Name
							.. " [Stock: "
							.. math.floor(currentCountryData.Resources[v.Name].Value)
							.. "  "
							.. math.ceil(currentCountryData.Resources[v.Name].Flow.Value * 10) / 10
							.. "]\n"
					end
					if building:FindFirstChild("Output") then
						requiresText = requiresText .. "\nProduces: \n"
						for i, v in pairs(building.Output:GetChildren()) do
							requiresText = requiresText .. v.Value .. " Units of " .. v.Name .. "\n"
						end
					end
				elseif building.Cost:FindFirstChild("Resources") then
					for i, v in pairs(building.Cost.Resources:GetChildren()) do
						requiresText = requiresText
							.. v.Value
							.. " Units of "
							.. v.Name
							.. " [Stock: "
							.. math.floor(currentCountryData.Resources[v.Name].Value)
							.. "  "
							.. math.ceil(currentCountryData.Resources[v.Name].Flow.Value * 10) / 10
							.. "]\n"
					end
				end
				mouseOverText = #requiresText <= 12 and "" or requiresText
			elseif frame.Parent == MainFrame.CityFrame.UnitFrame.UnitFrame then
				local unitStats = Assets.UnitStats[frame.Name]
				local requiresText = "Requires: \n"
				if unitStats:FindFirstChild("TechnologyRequired") then
					for i, v in pairs(unitStats.TechnologyRequired:GetChildren()) do
						requiresText = requiresText
							.. " Requires Technology: "
							.. Assets.Technology[v.Name].Title.Value
							.. "\n"
					end
				end
				if unitStats:FindFirstChild("BuildingRequired") then
					for i, v in pairs(unitStats.BuildingRequired:GetChildren()) do
						requiresText = requiresText .. " Requires Building: " .. v.Name .. "\n"
					end
				end
				for i, v in pairs(unitStats.Cost:GetChildren()) do
					requiresText = requiresText
						.. v.Value
						.. " Units of "
						.. v.Name
						.. " [Stock: "
						.. math.floor(currentCountryData.Resources[v.Name].Value)
						.. "  "
						.. math.ceil(currentCountryData.Resources[v.Name].Flow.Value * 10) / 10
						.. "]\n"
				end
				if unitStats:FindFirstChild("OilUsage") then
					requiresText = requiresText
						.. "\nConsumes "
						.. math.ceil(
							unitStats.OilUsage.Value / CountryModifier(currentCountry, "Fuel Efficiency") * 100
						) / 100
						.. " units of oil [Stock: "
						.. math.floor(currentCountryData.Resources.Oil.Value)
						.. "  "
						.. math.ceil(currentCountryData.Resources.Oil.Flow.Value * 10) / 10
						.. "]"
				end
				mouseOverText = #requiresText <= 12 and "" or requiresText
			end
		end
		if mouseOverText and mouseOverText ~= "" then
			GameGui.MouseOver.Label.Text = mouseOverText
			GameGui.MouseOver.Label.AutomaticSize = "None"
			GameGui.MouseOver.Label.AutomaticSize = "XY"
			GameGui.MouseOver.Size = UDim2.new(0, 0, 0, 0)
			if maxSize then
				GameGui.MouseOver.SizeLimit.MaxSize = Vector2.new(maxSize, math.huge)
			else
				GameGui.MouseOver.SizeLimit.MaxSize = Vector2.new(math.huge, math.huge)
			end
			GameGui.MouseOver.Position = UDim2.new(
				0,
				math.clamp(
					Mouse.X + 10,
					5,
					(math.clamp(GameGui.AbsoluteSize.X - GameGui.MouseOver.AbsoluteSize.X - 5, 6, math.huge))
				),
				0,
				(
					math.clamp(
						Mouse.Y + 10,
						5,
						(math.clamp(GameGui.AbsoluteSize.Y - GameGui.MouseOver.AbsoluteSize.Y - 5, 6, math.huge))
					)
				)
			)
		else
			GameGui.MouseOver.Visible = false
		end
	end)
	frame.MouseLeave:Connect(function()
		-- upvalues: (ref) GameGui
		GameGui.MouseOver.Visible = false
	end)
end
local function GeneratePieChart(cities)
	-- upvalues: (copy) GameGui, (copy) MakeMouseOver
	local masterPieChart = script.CommonGui.MasterPieChart:Clone()
	masterPieChart:ClearAllChildren()
	masterPieChart.Parent = GameGui
	table.sort(cities, function(a, b)
		return a.Value < b.Value
	end)
	local citiesPopulation = 0
	for i, v in pairs(cities) do
		citiesPopulation = citiesPopulation + v.Value
	end
	local rotation = 0
	for i, v in pairs(cities) do
		local idk = v.Value / citiesPopulation * 360
		local first = script.CommonGui.MasterPieChart.First:Clone()
		first.Name = v.Tag
		first.ZIndex = i
		first.Rotation = rotation
		first.ImageColor3 = v.Color
		MakeMouseOver(first, v.Tag .. "\n" .. v.Value, 14)
		rotation = rotation - idk
		if 90 < idk and i ~= #cities then
			first.Image = "rbxassetid://12687837520"
		end
		if i == #cities then
			masterPieChart.ImageColor3 = first.ImageColor3
		end
		first.Parent = masterPieChart
		if idk < 90 then
			if rotation + idk < -270 then
				local last = script.CommonGui.MasterPieChart.Last:Clone()
				last.ZIndex = i
				last.Name = first.Name .. "_Container"
				last.Parent = masterPieChart
				first.Parent = last
				first.Size = UDim2.new(2, 0, 1, 0)
				first.Position = UDim2.new(0, 0, 0.5, 0)
			end
		end
	end
end
local function ScaleScrollGui(object, Type)
	if Type == "X" then
		object.Parent.CanvasSize = UDim2.new(0, object.AbsoluteContentSize.X * 1.1, 0, 0)
	elseif Type == "Y" then
		object.Parent.CanvasSize = UDim2.new(0, 0, 0, object.AbsoluteContentSize.Y * 1.1)
	end
end
local function CenterFrameSelect(Type)
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) SetFlag, (copy) Assets, (copy) GameGui, (ref) highlitedCities, (ref) currentCountry, (copy) MakeMouseOver, (copy) ReferenceTable, (copy) ScaleScrollGui
	Disengage()
	MainFrame.CenterFrame.Visible = true
	for i, v in pairs(MainFrame.CenterFrame:GetChildren()) do
		if v:IsA("Frame") then
			if v.Name ~= "ButtonFrame" then
				v.Visible = false
			end
		end
	end
	if Type == "CountryFrame" then
		for i, v in pairs(MainFrame.CenterFrame.CountryFrame.Main.DecisionFrame.List:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
		for i, v in pairs(currentCountryData.Formables:GetChildren()) do
			local formableTag = workspace.CityPlacer.FormableTags.Reference[v.Value]
			local button = MainFrame.CenterFrame.CountryFrame.Main.DecisionFrame.List.Lister.Sample:Clone()
			button.Name = formableTag.DName.Value
			button.Text = formableTag.DName.Value
			SetFlag(button.Flag, formableTag.Name)
			button.Parent = MainFrame.CenterFrame.CountryFrame.Main.DecisionFrame.List
			button.MouseButton1Click:Connect(function()
				-- upvalues: (ref) Assets, (ref) GameGui, (copy) v_u_192
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				workspace.GameManager.ChangeTag:FireServer(v.Name)
			end)
			button.MapButton.MouseButton1Click:Connect(function()
				-- upvalues: (ref) Assets, (ref) GameGui, (ref) highlitedCities, (copy) formableTag, (ref) currentCountry
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				Disengage()
				if #highlitedCities == 0 then
					for i, v in pairs(formableTag.Countries:GetChildren()) do
						for i, v2 in pairs(game.CollectionService:GetTagged("Core" .. v.Name .. "City")) do
							if v2:GetAttribute("ActualOwner") ~= currentCountry then
								local ownershipTag = script.OwnershipTag:Clone()
								ownershipTag.Adornee = v2
								ownershipTag.Img.ImageColor3 = Color3.new(1, 1, 0.4)
								ownershipTag.Parent = v2
								table.insert(highlitedCities, ownershipTag)
								if v2.Parent ~= workspace.Baseplate.Cities[currentCountry] then
									ownershipTag.Img.ImageColor3 = Color3.new(1, 1, 1)
								end
							end
						end
					end
					for i, v in pairs(formableTag.Cities:GetChildren()) do
						local city = game.CollectionService:GetTagged(v.Value .. "_CityUID")[1]
						if city:GetAttribute("ActualOwner") ~= currentCountry then
							local ownershipTag = script.OwnershipTag:Clone()
							ownershipTag.Adornee = city
							ownershipTag.Img.ImageColor3 = Color3.new(1, 1, 0.4)
							ownershipTag.Parent = city
							table.insert(highlitedCities, ownershipTag)
							if city.Parent ~= workspace.Baseplate.Cities[currentCountry] then
								ownershipTag.Img.ImageColor3 = Color3.new(1, 1, 1)
							end
						end
					end
				else
					for i, v in pairs(highlitedCities) do
						v:Destroy()
					end
					highlitedCities = {}
				end
			end)
			MakeMouseOver(button, function()
				-- upvalues: (ref) currentCountryData, (copy) button, (ref) currentCountry, (ref) ReferenceTable
				local formableTag =
					workspace.CityPlacer.FormableTags.Reference[currentCountryData.Formables[button.Name].Value]
				local requiredCountriesText = button.Name
					.. "\n \n"
					.. formableTag.Value
					.. "\n \nAll the following must be true:\n \n"
				local countriesOwned = {
					["Yes"] = {},
					["No"] = {},
				}
				local countriesRequired = formableTag.Countries:GetChildren()
				table.sort(countriesRequired, function(a, b)
					return a.Name < b.Name
				end)
				for i, country in pairs(countriesRequired) do
					local ownsCountry = true
					local default = "Yes"
					for i, city in pairs(game.CollectionService:GetTagged("Core" .. country.Name .. "City")) do
						if city.Parent ~= workspace.Baseplate.Cities[currentCountry] then
							ownsCountry = false
							break
						end
						if city:GetAttribute("ActualOwner") ~= currentCountry then
							ownsCountry = false
							break
						end
					end
					if (not ownsCountry and "No" or default) == "Yes" then
						table.insert(countriesOwned.Yes, country.Name)
					else
						table.insert(countriesOwned.No, country.Name)
					end
				end
				if 0 < #countriesOwned.Yes then
					requiredCountriesText = requiredCountriesText .. "Owns the following countries: "
					for i = 1, #countriesOwned.Yes do
						requiredCountriesText = requiredCountriesText
							.. '<font color="rgb('
							.. ReferenceTable.Colors.Positive[1]
							.. ')">'
							.. countriesOwned.Yes[i]
							.. "</font>"
						if i ~= #countriesOwned.Yes or 0 < #countriesOwned.No then
							requiredCountriesText = requiredCountriesText .. ", "
						end
					end
				end
				if 0 < #countriesOwned.No then
					if #countriesOwned.Yes == 0 then
						requiredCountriesText = requiredCountriesText .. "Owns the following countries: "
					end
					for i = 1, #countriesOwned.No do
						requiredCountriesText = requiredCountriesText
							.. '<font color="rgb('
							.. ReferenceTable.Colors.Negative[1]
							.. ')">'
							.. countriesOwned.No[i]
							.. "</font>"
						if i ~= #countriesOwned.No then
							requiredCountriesText = requiredCountriesText .. ", "
						end
					end
				end
				local requiredCitiesText = requiredCountriesText .. "\n\n"
				local citiesRequired = formableTag.Cities:GetChildren()
				if 0 < #citiesRequired then
					local ownsCitiesText = '<font color="rgb('
						.. ReferenceTable.Colors.Positive[1]
						.. ')">'
						.. "Yes"
						.. "</font>"
					local counter = 0
					for i = 1, #citiesRequired do
						local city = game.CollectionService:GetTagged(citiesRequired[i].Value .. "_CityUID")[1]
						local ownsCity = true
						if city.Parent.Name == currentCountry then
							if city:GetAttribute("ActualOwner") ~= currentCountry then
								ownsCity = false
							end
						else
							ownsCity = false
						end
						if ownsCity then
							counter = counter + 1
						end
					end
					if counter < #citiesRequired then
						ownsCitiesText = '<font color="rgb('
							.. ReferenceTable.Colors.Negative[1]
							.. ')">'
							.. "No"
							.. "</font>"
					end
					requiredCitiesText = requiredCitiesText
						.. "Owns "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.LightBlue[1]
						.. ')">'
						.. counter
						.. "</font>"
						.. " / "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.LightBlue[1]
						.. ')">'
						.. #citiesRequired
						.. "</font>"
						.. " Required Cities: "
						.. ownsCitiesText
						.. "\n"
				end
				local noTagChildren = formableTag.NoTag:GetChildren()
				if 0 < #noTagChildren then
					requiredCitiesText = requiredCitiesText .. "\n"
				end
				for i, v in pairs(noTagChildren) do
					local statusText = '<font color="rgb('
						.. ReferenceTable.Colors.Positive[1]
						.. ')">'
						.. "Yes"
						.. "</font>"
					if v.Name == currentCountry then
						statusText = '<font color="rgb('
							.. ReferenceTable.Colors.Negative[1]
							.. ')">'
							.. "No"
							.. "</font>"
					end
					requiredCitiesText = requiredCitiesText
						.. "Is NOT "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.LightBlue[1]
						.. ')">'
						.. v.Name
						.. "</font>"
						.. ": "
						.. statusText
						.. "\n"
				end
				local peaceStatusText = '<font color="rgb('
					.. ReferenceTable.Colors.Positive[1]
					.. ')">'
					.. "Yes"
					.. "</font>"
				if workspace.Wars:FindFirstChild(currentCountry, true) then
					peaceStatusText = '<font color="rgb('
						.. ReferenceTable.Colors.Negative[1]
						.. ')">'
						.. "No"
						.. "</font>"
				end
				local text = requiredCitiesText
					.. "\nIs at Peace: "
					.. peaceStatusText
					.. "\n \n+"
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. formableTag:GetAttribute("Stability_Gain")
					.. "%"
					.. "</font>"
					.. " Stability\nCountry changes to "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. formableTag.Name
					.. "</font>"
				if formableTag:GetAttribute("HasModifiers") then
					local modifiersText = text .. "\n\nAdd the following modifiers:"
					for i, v in pairs(formableTag.Modifiers:GetChildren()) do
						local statusText = '<font color="rgb('
							.. ReferenceTable.Colors.Gold[1]
							.. ')">'
							.. " Indefinitely"
							.. "</font>"
						if 0 < v:GetAttribute("Length") then
							statusText = " for "
								.. '<font color="rgb('
								.. ReferenceTable.Colors.Gold[1]
								.. ')">'
								.. v:GetAttribute("Length")
								.. " Days"
								.. "</font>"
						end
						modifiersText = modifiersText
							.. "\n  '"
							.. '<font color="rgb('
							.. ReferenceTable.Colors.LightBlue[1]
							.. ')">'
							.. v.Name
							.. "</font>"
							.. "'"
							.. statusText
							.. ":\n"
							.. ModifierEffectText(v.Name, "     -")
					end
					text = modifiersText
						.. "\n"
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Negative[1]
						.. ')">'
						.. "  Your current formable modifiers will be removed"
						.. "</font>"
				end
				return text
			end, 14, 400)
		end
		MainFrame.CenterFrame.CountryFrame.Main.DecisionFrame.List.CanvasSize = UDim2.new(
			0,
			0,
			0,
			MainFrame.CenterFrame.CountryFrame.Main.DecisionFrame.List.Lister.AbsoluteContentSize.Y * 1.1
		)
	end
	MainFrame.CenterFrame[Type].Visible = true
	ScaleScrollGui(MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.List, "Y")
	if MainFrame.CenterFrame[Type]:FindFirstChild("FULLSCREEN") then
		MainFrame.CenterFrame.UISC.MaxSize = Vector2.new(4000, 3000)
	else
		MainFrame.CenterFrame.UISC.MaxSize = Vector2.new(400, 300)
	end
end
local function DiplomacyFrameSelect(frameName)
	-- upvalues: (copy) MainFrame
	for i, v in pairs(MainFrame.CenterFrame.DiplomacyFrame:GetChildren()) do
		if v:IsA("Frame") then
			v.Visible = false
		end
	end
	if MainFrame.CenterFrame.DiplomacyFrame[frameName]:FindFirstChild("Casus") then
		MainFrame.CenterFrame.DiplomacyFrame[frameName].Casus.Value = ""
	end
	if MainFrame.CenterFrame.DiplomacyFrame[frameName]:FindFirstChild("Explan") then
		MainFrame.CenterFrame.DiplomacyFrame[frameName].Explan.Text = ""
	end
	MainFrame.CenterFrame.DiplomacyFrame[frameName].Visible = true
end
local baseplateWidthDividedBy2 = workspace.Baseplate.Size.X / 2
local coefficient = 6371 / baseplateWidthDividedBy2
local function CheckLand(origin)
	local part = workspace:FindPartOnRayWithWhitelist(
		Ray.new(origin + origin.Unit, -origin.Unit * 2),
		{ workspace.Baseplate.Parts }
	)
	if part == nil then
		part = false
	end
	return part
end
local v_u_246 = {}
function Disengage()
	-- upvalues: (ref) v_u_18, (ref) selected, (ref) v_u_246, (ref) v_u_14, (ref) mouseInteractionType, (ref) groupInteraction, (ref) moveUnitPositions, (ref) selectedCenterPos, (ref) isShiftDown, (copy) Mouse, (ref) tags, (copy) GameGui, (copy) DiplomacyFrameSelect, (copy) MainFrame
	if not v_u_18 then
		selected = {}
		v_u_246 = {}
		v_u_14 = 0
		mouseInteractionType = ""
		groupInteraction = ""
		moveUnitPositions = {}
		selectedCenterPos = nil
		if isShiftDown then
			isShiftDown = false
		else
			Mouse.TargetFilter = nil
		end
		for i, v in pairs(tags) do
			v:Destroy()
		end
		tags = {}
		if workspace:FindFirstChild("CirclePath") then
			workspace.CirclePath:Destroy()
		end
		GameGui.MouseOver.Visible = false
		DiplomacyFrameSelect("Main")
		for i, v in pairs(MainFrame:GetDescendants()) do
			if v.Name == "CloseParent" then
				v.Parent.Visible = false
			elseif v.Name == "OpenParent" then
				v.Parent.Visible = true
			end
			if v.Name == "Casus" then
				v.Value = ""
			end
			if v.Name == "GuiDestroy" and v.Parent.Parent.Name ~= "List" then
				v.Parent:Destroy()
			end
			if v:GetAttribute("SetDefaultText") then
				v.Text = v:GetAttribute("SetDefaultText")
			end
		end
	end
end
UserInputService.InputBegan:Connect(function(input, _gameProcessed)
	-- upvalues: (copy) CenterFrameSelect, (copy) MainFrame, (ref) selected, (ref) v_u_8, (ref) isShiftDown, (copy) GameGui, (ref) citySelection, (ref) mouseInteractionType, (copy) Mouse, (ref) v_u_18, (ref) currentCountry, (ref) highlitedCities
	if input.UserInputType == Enum.UserInputType.Keyboard and not _gameProcessed then
		if input.KeyCode == Enum.KeyCode.Q then
			CenterFrameSelect("CountryFrame")
			return
		end
		if input.KeyCode == Enum.KeyCode.W then
			if MainFrame.CityFrame.Visible then
				MainFrame.CenterFrame.DiplomacyFrame.Country.Value = selected[1].Parent.Name
			end
			CenterFrameSelect("DiplomacyFrame")
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			CenterFrameSelect("EconomyFrame")
			return
		end
		if input.KeyCode == Enum.KeyCode.A then
			CenterFrameSelect("TechnologyFrame")
			return
		end
		if input.KeyCode == Enum.KeyCode.S then
			CenterFrameSelect("MilitaryFrame")
			return
		end
		if input.KeyCode == Enum.KeyCode.D then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			v_u_8 = -1
			return
		end
		if input.KeyCode == Enum.KeyCode.F then
			v_u_8 = 1
			return
		end
		if input.KeyCode == Enum.KeyCode.Z then
			Disengage()
			return
		end
		if input.KeyCode == Enum.KeyCode.Return then
			if MainFrame:FindFirstChild("AlertSample") then
				MainFrame.AlertSample:Destroy()
				return
			end
		else
			if input.KeyCode == Enum.KeyCode.Tab then
				Disengage()
				MainFrame.TabMenu.Visible = not MainFrame.TabMenu.Visible
				return
			end
			if input.KeyCode == Enum.KeyCode.G then
				if isShiftDown then
					GameGui.Enabled = not GameGui.Enabled
					return
				end
			else
				if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftAlt then
					citySelection = true
					return
				end
				if input.KeyCode == Enum.KeyCode.LeftShift then
					isShiftDown = true
					if mouseInteractionType ~= "MoveUnit" then
						Mouse.TargetFilter = workspace.Units
						return
					end
				else
					if input.KeyCode == Enum.KeyCode.Space then
						v_u_18 = true
						return
					end
					if input.KeyCode == Enum.KeyCode.M and currentCountry ~= "" then
						for i, v in pairs(workspace.Baseplate.Cities[currentCountry]:GetChildren()) do
							local ownershipTag = script.OwnershipTag:Clone()
							ownershipTag.Adornee = v
							ownershipTag.Img.ImageColor3 =
								Color3.fromRGB(149, 255, 116)
									:Lerp(Color3.fromRGB(255, 121, 121), v:GetAttribute("Unrest") / 100)
							ownershipTag.Parent = v
							table.insert(highlitedCities, ownershipTag)
						end
					end
				end
			end
		end
	end
end)
UserInputService.InputChanged:Connect(function(input, _gameProcessed)
	-- upvalues: (ref) v_u_8, (ref) v_u_6
	if input.UserInputType == Enum.UserInputType.MouseWheel and not _gameProcessed then
		v_u_8 = -input.Position.Z
		if v_u_6 < 0.1 and v_u_8 < 0 then
			v_u_8 = 0
		end
		if 0 < v_u_8 and 1000 < v_u_6 then
			v_u_8 = 0
		end
		wait()
		v_u_8 = 0
	end
end)
UserInputService.InputEnded:Connect(function(input, _gameProcessed)
	-- upvalues: (ref) v_u_7, (ref) v_u_9, (ref) v_u_8, (ref) cityAnnexationFrame, (copy) MainFrame, (ref) citySelection, (ref) isShiftDown, (ref) mouseInteractionType, (copy) Mouse, (ref) v_u_18, (ref) currentCountry, (ref) highlitedCities
	if input.UserInputType == Enum.UserInputType.Keyboard and not _gameProcessed then
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
			v_u_7 = 0
			return
		end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
			v_u_9 = 0
			return
		end
		if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.F then
			v_u_8 = 0
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftAlt then
			if cityAnnexationFrame ~= MainFrame.WarOverFrame.SelectFrame then
				citySelection = false
				return
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			isShiftDown = false
			if mouseInteractionType ~= "MoveUnit" then
				Mouse.TargetFilter = nil
				return
			end
		elseif input.KeyCode == Enum.KeyCode.Space then
			if not cityAnnexationFrame then
				v_u_18 = false
				return
			end
		elseif input.KeyCode == Enum.KeyCode.M and currentCountry ~= "" then
			for i, v in pairs(highlitedCities) do
				v:Destroy()
			end
			highlitedCities = {}
		end
	end
end)
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled or workspace:GetAttribute("Mobile") then
	isMobile = true
	workspace:SetAttribute("Mobile", true)
	print("Loaded mobile controls")
	local v_u_260 = v_u_6
	UserInputService.TouchStarted:Connect(function(p261, _)
		-- upvalues: (ref) unusedVector, (ref) v_u_260, (ref) v_u_6
		unusedVector = p261.Position
		v_u_260 = v_u_6
	end)
	UserInputService.TouchTap:Connect(function(_, _) end)
	UserInputService.TouchMoved:Connect(function(p262, p263)
		-- upvalues: (copy) MainFrame, (ref) v_u_7, (ref) v_u_9
		if not p263 and MainFrame.MobileFrame.LowerLeftFrame.Move.Text == "Map Move Mode" then
			v_u_7 = p262.Delta.Y / 8
			v_u_9 = p262.Delta.X / 8
		end
	end)
	UserInputService.TouchEnded:Connect(function(_, _)
		-- upvalues: (ref) v_u_7, (ref) v_u_9, (ref) v_u_8
		v_u_7 = 0
		v_u_9 = 0
		v_u_8 = 0
	end)
	UserInputService.TouchPinch:Connect(function(_, p264, p265, _, p266)
		-- upvalues: (ref) v_u_6, (ref) v_u_260, (ref) v_u_8
		if not p266 then
			v_u_6 = math.clamp(v_u_260 / p264, 0.1, 3200)
			print("PINCH", p264, p265, v_u_8)
		end
	end)
	MainFrame.MobileFrame.Visible = true
	MainFrame.MobileFrame.LowerLeftFrame.Move.MouseButton1Click:Connect(function()
		-- upvalues: (copy) MainFrame
		if MainFrame.MobileFrame.LowerLeftFrame.Move.Text == "Map Move Mode" then
			MainFrame.MobileFrame.LowerLeftFrame.Move.Text = "Selection Mode"
			MainFrame.MobileFrame.LowerLeftFrame.UnitCity.Visible = true
		else
			MainFrame.MobileFrame.LowerLeftFrame.Move.Text = "Map Move Mode"
			MainFrame.MobileFrame.LowerLeftFrame.UnitCity.Visible = false
		end
	end)
	MainFrame.MobileFrame.LowerLeftFrame.UnitCity.MouseButton1Click:Connect(function()
		-- upvalues: (copy) MainFrame
		if MainFrame.MobileFrame.LowerLeftFrame.UnitCity.Text == "Unit Selection" then
			MainFrame.MobileFrame.LowerLeftFrame.UnitCity.Text = "City Selection"
		else
			MainFrame.MobileFrame.LowerLeftFrame.UnitCity.Text = "Unit Selection"
		end
	end)
	MainFrame.MobileFrame.LowerLeftFrame.MainMenu.MouseButton1Click:Connect(function()
		-- upvalues: (copy) MainFrame
		Disengage()
		MainFrame.TabMenu.Visible = not MainFrame.TabMenu.Visible
	end)
	MainFrame.MobileFrame.Deselect.MouseButton1Click:Connect(function()
		Disengage()
	end)
	MainFrame.MobileFrame.ShiftDown.MouseButton1Click:Connect(function()
		-- upvalues: (ref) isShiftDown
		isShiftDown = not isShiftDown
	end)
	table.insert(loopFunctions, function()
		-- upvalues: (ref) isShiftDown, (copy) MainFrame
		if isShiftDown then
			MainFrame.MobileFrame.ShiftDown.Text = "Shift Down: On"
		else
			MainFrame.MobileFrame.ShiftDown.Text = "Shift Down: Off"
		end
	end)
end
workspace.Transmitter.Set.OnClientEvent:Connect(function()
	-- upvalues: (copy) FirstFrame, (copy) MapFrame, (copy) Assets, (copy) SetFlag, (ref) selected
	FirstFrame.Visible = false
	MapFrame.Visible = true
	for i, country in pairs(Assets.Flag:GetChildren()) do
		local button = MapFrame.CityFrame.CountryList.UIListLayout.Sample:Clone()
		button.Name = country.Name
		button.Text = country.Name
		button.Parent = MapFrame.CityFrame.CountryList
		SetFlag(button.Flag, country.Name)
		button.MouseButton1Click:Connect(function()
			-- upvalues: (ref) selected, (ref) MapFrame
			workspace.EditorManager.Point:FireServer("ChangeOwner", { selected, country.Name })
			MapFrame.CityFrame.CountryList.Visible = false
		end)
	end
	local search = MapFrame.CityFrame.CountryList.A
	search:GetPropertyChangedSignal("Text"):Connect(function()
		-- upvalues: (ref) Assets, (copy) search
		for i, v in pairs(MapFrame.CityFrame.CountryList:GetChildren()) do
			if Assets.Flag:FindFirstChild(v.Name) then
				if string.match(string.lower(v.Name), string.lower(search.Text)) == nil then
					v.Visible = false
				else
					v.Visible = true
				end
			end
		end
	end)
	MapFrame.CityFrame.CountryList.CanvasSize =
		UDim2.new(0, 0, 0, MapFrame.CityFrame.CountryList.UIListLayout.AbsoluteContentSize.Y * 1.1)
	MapFrame.CityFrame.Main.Owner.MouseButton1Click:Connect(function()
		-- upvalues: (ref) MapFrame
		MapFrame.CityFrame.CountryList.Visible = true
	end)
	MapFrame.CityFrame.Main.Select.MouseButton1Click:Connect(function()
		-- upvalues: (ref) selected
		selected = selected[1].Parent:GetChildren()
	end)
	MapFrame.CityFrame.Main.Capital.MouseButton1Click:Connect(function()
		-- upvalues: (ref) selected
		if #selected == 1 then
			workspace.EditorManager.Point:FireServer("ChangeCapital", { selected[1] })
		end
	end)
	MapFrame.BottomFrame.Save.MouseButton1Click:Connect(function()
		-- upvalues: (ref) MapFrame
		if
			MapFrame.BottomFrame.Save.Active
			and MapFrame.BottomFrame.MapName.Text ~= ""
			and tonumber(MapFrame.BottomFrame.YearName.Text) ~= nil
		then
			MapFrame.BottomFrame.Save.Active = false
			MapFrame.BottomFrame.Save.Text = "Saving"
			workspace.EditorManager.PointFunction:InvokeServer(
				"Save",
				{ MapFrame.BottomFrame.MapName.Text, MapFrame.BottomFrame.YearName.Text }
			)
			MapFrame.BottomFrame.Save.Text = "Saved"
			wait(1)
			MapFrame.BottomFrame.Save.Active = true
			MapFrame.BottomFrame.Save.Text = "Save Map"
		end
	end)
end)
local function DeselectObject(instance)
	-- upvalues: (ref) selected
	local found = table.find(selected, instance)
	if found then
		if instance:FindFirstChild("SelectTag") then
			instance.SelectTag:Destroy()
		end
		if instance:FindFirstChild("RangeFinder") then
			instance.RangeFinder:Destroy()
		end
		table.remove(selected, found)
	end
end
local function WipeObjects()
	-- upvalues: (ref) selected
	for i, v in pairs(selected) do
		local instance = v
		if instance:FindFirstChild("SelectTag") then
			instance.SelectTag:Destroy()
		end
		if instance:FindFirstChild("RangeFinder") then
			instance.RangeFinder:Destroy()
		end
	end
	selected = {}
end
Mouse.Button1Up:Connect(function()
	-- upvalues: (ref) leftMouseDown, (copy) GameGui, (copy) MapFrame, (ref) cityAnnexationFrame, (copy) MainFrame, (ref) citySelection, (ref) currentCountry, (ref) mouseInteractionType, (ref) v_u_18, (ref) isMobile, (ref) currentCountryData, (ref) selected, (ref) isShiftDown, (copy) DeselectObject, (ref) selectedCenterPos, (ref) v_u_14, (copy) Mouse, (copy) Assets
	leftMouseDown = false
	local dragFrame = GameGui.DragFrame
	if dragFrame.Size ~= UDim2.new(0, 0, 0, 0) then
		local allCities
		if MapFrame.Visible or cityAnnexationFrame == MainFrame.WarOverFrame.SelectFrame then
			allCities = {}
			for i, city in pairs(workspace.Baseplate.Cities:GetChildren()) do
				for i, v in pairs(city:GetChildren()) do
					table.insert(allCities, v)
				end
			end
			citySelection = true
		else
			allCities = workspace.Baseplate.Cities[currentCountry]:GetChildren()
		end
		if dragFrame.Size.X.Offset < 0 then
			dragFrame.Position = dragFrame.Position + UDim2.new(0, dragFrame.Size.X.Offset, 0, 0)
			dragFrame.Size = dragFrame.Size + UDim2.new(0, -dragFrame.Size.X.Offset * 2, 0, 0)
		end
		if dragFrame.Size.Y.Offset < 0 then
			dragFrame.Position = dragFrame.Position + UDim2.new(0, 0, 0, dragFrame.Size.Y.Offset)
			dragFrame.Size = dragFrame.Size + UDim2.new(0, 0, 0, -dragFrame.Size.Y.Offset * 2)
		end
		if mouseInteractionType == "" or v_u_18 then
			if isMobile and MainFrame.MobileFrame.LowerLeftFrame.UnitCity.Text == "City Selection" then
				citySelection = true
			end
			if citySelection then
				if mouseInteractionType == "" or mouseInteractionType == "SelectCity" then
					for i, city in pairs(allCities) do
						local cityScreenPos = workspace.CurrentCamera:WorldToScreenPoint(city.Position)
						if
							workspace:FindPartOnRayWithIgnoreList(
								Ray.new(
									workspace.CurrentCamera.CFrame.Position,
									CFrame.new(workspace.CurrentCamera.CFrame.Position, city.Position).lookVector
										* ((workspace.CurrentCamera.CFrame.Position - city.Position).Magnitude - 1)
								),
								{ workspace.Baseplate.Cities, workspace.Units, workspace.Baseplate.EarthParts }
							) == nil
						then
							if cityScreenPos.X > dragFrame.Position.X.Offset then
								if cityScreenPos.X < dragFrame.Position.X.Offset + dragFrame.Size.X.Offset then
									if cityScreenPos.Y > dragFrame.Position.Y.Offset then
										if cityScreenPos.Y < dragFrame.Position.Y.Offset + dragFrame.Size.Y.Offset then
											local ownsCity = true
											if cityAnnexationFrame == MainFrame.WarOverFrame.SelectFrame then
												if
													city:GetAttribute("ActualOwner")
													== cityAnnexationFrame.Parent.PeaceFrame.Target:GetAttribute(
														"ActualTarget"
													)
												then
													if
														city.Parent.Name
														~= cityAnnexationFrame.Parent.PeaceFrame.Target:GetAttribute(
															"ActualTarget"
														)
													then
														if city.Parent.Name ~= currentCountry then
															ownsCity = false
														end
													end
												else
													ownsCity = false
												end
											end
											if ownsCity and not (table.find(selected, city) or isShiftDown) then
												table.insert(selected, city)
											end
											if isShiftDown then
												if cityAnnexationFrame == MainFrame.WarOverFrame.SelectFrame then
													if table.find(selected, city) then
														DeselectObject(city)
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			elseif mouseInteractionType == "" or mouseInteractionType == "MoveUnit" then
				for i, unit in pairs(workspace.Units:GetChildren()) do
					if unit.Owner.Value == currentCountryData.Name then
						if not table.find(selected, unit) then
							local unitScreenPos = workspace.CurrentCamera:WorldToScreenPoint(unit.Position)
							if
								workspace:FindPartOnRayWithIgnoreList(
									Ray.new(
										workspace.CurrentCamera.CFrame.Position,
										CFrame.new(workspace.CurrentCamera.CFrame.Position, unit.Position).lookVector
											* ((workspace.CurrentCamera.CFrame.Position - unit.Position).Magnitude - 1)
									),
									{ workspace.Baseplate.Cities, workspace.Units, workspace.Baseplate.EarthParts }
								) == nil
							then
								if unitScreenPos.X > dragFrame.Position.X.Offset then
									if unitScreenPos.X < dragFrame.Position.X.Offset + dragFrame.Size.X.Offset then
										if unitScreenPos.Y > dragFrame.Position.Y.Offset then
											if
												unitScreenPos.Y
												< dragFrame.Position.Y.Offset + dragFrame.Size.Y.Offset
											then
												table.insert(selected, unit)
											end
										end
									end
								end
							end
						end
					end
				end
			end
			if 0 < #selected then
				if selected[1]:IsDescendantOf(workspace.Baseplate.Cities) then
					mouseInteractionType = "SelectCity"
					MapFrame.CityFrame.Visible = true
					if 1 < #selected then
						table.sort(selected, function(a, b)
							return a.Population.Value.X > b.Population.Value.X
						end)
					end
					local cityClickedSound = Assets.Audio.CityClicked:Clone()
					cityClickedSound.Parent = GameGui
					cityClickedSound:Play()
					game.Debris:AddItem(cityClickedSound, 15)
				else
					mouseInteractionType = "MoveUnit"
					selectedCenterPos = Vector3.new()
					for i, v in pairs(selected) do
						selectedCenterPos = selectedCenterPos + v.Position
					end
					selectedCenterPos = selectedCenterPos / #selected
					v_u_14 = 1
					if not workspace:FindFirstChild("CirclePath") then
						local circlePath = Instance.new("Folder")
						circlePath.Name = "CirclePath"
						circlePath.Parent = workspace
						Mouse.TargetFilter = circlePath
					end
					local selectedType = selected[1].Type.Value
					local transverseSound =
						Assets.Audio[(Assets.UnitStats[selectedType].TransverseType.Value == "Naval" and "Destroyer" or Assets.UnitStats[selectedType].TransverseType.Value == "Air" and "Aircraft" or selectedType) .. "Clicked"]:Clone()
					transverseSound.Parent = GameGui
					transverseSound:Play()
					game.Debris:AddItem(transverseSound, 15)
				end
			end
			if isMobile and MainFrame.MobileFrame.LowerLeftFrame.UnitCity.Text == "City Selection" then
				citySelection = false
			end
		end
		dragFrame.Size = UDim2.new()
	end
end)
local function MakePath()
	-- upvalues: (ref) selectedCenterPos, (copy) Mouse, (copy) baseplateWidthDividedBy2, (copy) CheckLand
	workspace.CirclePath:ClearAllChildren()
	local v299 = math.ceil(
		math.pi * workspace.Baseplate.Size.X * math.deg(math.acos(selectedCenterPos.Unit:Dot(Mouse.hit.p.Unit))) / 360
	)
	local v300 = selectedCenterPos.Unit
	local mouseHitPosUnit = Mouse.hit.p.Unit
	local v302 = math.acos(v300:Dot(mouseHitPosUnit))
	local v303 = CFrame.fromMatrix(Vector3.new(), v300, v300:Cross(mouseHitPosUnit))
	local v304 = {}
	local v305 = true
	for v306 = 0, v299 do
		v304[v306] = (v303 * CFrame.Angles(0, v302 * v306 / v299, 0) * CFrame.new(
			baseplateWidthDividedBy2 + 0.025,
			0,
			0
		)).p
		if not CheckLand(v304[v306]) then
			v305 = false
		end
	end
	for i = 0, #v304 - 1 do
		local v308 = (v304[i] - v304[i + 1]).Magnitude
		local highlighter = game.ReplicatedStorage.Highlighter:Clone()
		highlighter.Size = Vector3.new(0.05, 0.05, v308)
		highlighter.CFrame = CFrame.new(v304[i], v304[i + 1]) * CFrame.new(0, 0, -v308 / 2)
		if not v305 then
			highlighter.BrickColor = BrickColor.new("Bright orange")
		end
		highlighter.Parent = workspace.CirclePath
	end
end
Mouse.Button1Down:Connect(function()
	-- upvalues: (ref) isMobile, (copy) Mouse, (ref) leftMouseDown, (ref) v_u_18, (ref) v_u_14, (ref) mouseInteractionType, (ref) isShiftDown, (copy) CheckLand, (ref) selected, (ref) selectedCenterPos, (ref) currentCountryData, (copy) Assets, (copy) GameGui, (ref) cityAnnexationFrame, (copy) MainFrame, (ref) currentCountry, (copy) DeselectObject, (copy) MapFrame, (ref) currentMapType, (copy) MakePath, (ref) tags, (ref) moveUnitPositions
	if isMobile then
		wait()
	end
	local mouseHitPos = Mouse.hit.p
	local mouseTarget = Mouse.Target
	local v313 = false
	leftMouseDown = true
	if v_u_18 then
		if v_u_14 == 1 then
			v313 = true
			v_u_14 = 0
		end
	end
	if mouseTarget == nil then
		Disengage()
	else
		local tile = mouseTarget.Parent.Parent ~= workspace.Baseplate.Cities
			and mouseInteractionType == ""
			and isShiftDown
			and CheckLand(mouseHitPos)
		if tile then
			selected = {}
			local tileCities = game.CollectionService:GetTagged(tile.Name .. "_City")
			for i, city in pairs(tileCities) do
				table.insert(selected, city)
			end
			mouseInteractionType = "SelectCity"
			tile.Transparency = 0.5
			game:GetService("TweenService")
				:Create(tile, TweenInfo.new(1, Enum.EasingStyle.Linear), {
					["Transparency"] = 0.9,
				})
				:Play()
			warn("Highlighted tile is called: ", tile.Name)
			return
		end
		if v_u_14 == 0 then
			Disengage()
			selectedCenterPos = mouseHitPos
			if
				mouseTarget.Parent == workspace.Units
				and mouseTarget.Owner.Value == currentCountryData.Name
				and (mouseInteractionType == "" or mouseInteractionType == "MoveUnit")
			then
				mouseInteractionType = "MoveUnit"
				if not table.find(selected, mouseTarget) then
					table.insert(selected, mouseTarget)
				end
				print(#selected)
				local selectedType = selected[1].Type.Value
				local transverseSound =
					Assets.Audio[(Assets.UnitStats[selectedType].TransverseType.Value == "Naval" and "Destroyer" or Assets.UnitStats[selectedType].TransverseType.Value == "Air" and "Aircraft" or selectedType) .. "Clicked"]:Clone()
				transverseSound.Parent = GameGui
				transverseSound:Play()
				game.Debris:AddItem(transverseSound, 15)
				selectedCenterPos = mouseTarget.Position
			end
			if
				mouseTarget.Parent.Parent == workspace.Baseplate.Cities
				and (mouseInteractionType == "" or mouseInteractionType == "SelectCity")
			then
				mouseInteractionType = "SelectCity"
				if table.find(selected, mouseTarget) then
					if cityAnnexationFrame == MainFrame.WarOverFrame.SelectFrame then
						DeselectObject(mouseTarget)
					end
				else
					local v319 = true
					if cityAnnexationFrame == MainFrame.WarOverFrame.SelectFrame then
						if
							mouseTarget:GetAttribute("ActualOwner")
							== cityAnnexationFrame.Parent.PeaceFrame.Target:GetAttribute("ActualTarget")
						then
							if
								mouseTarget.Parent.Name
								~= cityAnnexationFrame.Parent.PeaceFrame.Target:GetAttribute("ActualTarget")
							then
								if mouseTarget.Parent.Name ~= currentCountry then
									v319 = false
								end
							end
						else
							v319 = false
						end
					end
					if v319 then
						table.insert(selected, mouseTarget)
					end
				end
				MapFrame.CityFrame.Visible = true
				local cityClickedSound = Assets.Audio.CityClicked:Clone()
				cityClickedSound.Parent = GameGui
				cityClickedSound:Play()
				game.Debris:AddItem(cityClickedSound, 15)
				if currentMapType == "Diplomatic" then
					UpdateTiles(nil, "UniversalCheck")
				end
			end
			if mouseInteractionType == "MoveUnit" then
				v_u_14 = 1
				if not workspace:FindFirstChild("CirclePath") then
					local circlePath = Instance.new("Folder")
					circlePath.Name = "CirclePath"
					circlePath.Parent = workspace
					Mouse.TargetFilter = circlePath
				end
			end
		elseif v_u_14 == 1 and not v_u_18 then
			if mouseInteractionType ~= "RoadBuild" and isShiftDown then
				if isMobile then
					MakePath()
				end
				selectedCenterPos = mouseHitPos
				if workspace:FindFirstChild("CirclePath") then
					local circlePath = workspace.CirclePath:Clone()
					table.insert(tags, circlePath)
					circlePath.Name = "Ha"
					circlePath.Parent = workspace
				end
			end
			table.insert(moveUnitPositions, mouseHitPos)
			if mouseInteractionType == "MoveUnit" then
				if not isShiftDown then
					local selectedType = selected[1].Type.Value
					local transverseSound =
						Assets.Audio[(Assets.UnitStats[selectedType].TransverseType.Value == "Naval" and "Destroyer" or Assets.UnitStats[selectedType].TransverseType.Value == "Air" and "Aircraft" or selectedType) .. "Moved"]:Clone()
					transverseSound.Parent = GameGui
					transverseSound:Play()
					game.Debris:AddItem(transverseSound, 15)
					local followingUnit = nil
					if mouseTarget.Parent == workspace.Units then
						if mouseTarget.Owner.Value ~= currentCountryData.Name then
							followingUnit = mouseTarget
						end
					end
					workspace.GameManager.MoveUnit:FireServer(selected, moveUnitPositions, followingUnit, {
						["HoldFormation"] = MainFrame.UnitFrame.MovementSettingFrame.HoldFormation.Text
							== "Hold Formation: On",
						["SlavedUnit"] = MainFrame.UnitFrame.MovementSettingFrame.EqualSpeed.Text
							== "Equalize Movement Speed: On",
					})
				end
			elseif mouseInteractionType == "RoadBuild" then
				if mouseTarget.Parent.Name == currentCountry and mouseTarget ~= selected[1] then
					workspace.GameManager.CreateRoad:FireServer(selected[1], mouseTarget)
				end
			elseif mouseInteractionType == "RoadDestroy" and mouseTarget.Parent == workspace.Baseplate.Roads then
				workspace.GameManager.DestroyRoad:FireServer(mouseTarget)
			end
			if isShiftDown then
				if mouseInteractionType == "RoadBuild" then
					Disengage()
				end
			elseif mouseInteractionType == "RoadBuild" then
				if mouseTarget.Parent.Name == currentCountry and mouseTarget ~= selected[1] then
					selected = { mouseTarget }
					local city = selected[1]
					local cityPopulation = city.Population.Value.X
					if 1000000 <= cityPopulation then
						local _ = math.ceil(cityPopulation / 100000) / 10 .. "M"
					else
						local _ = math.ceil(cityPopulation / 100) / 10 .. "k"
					end
					local millions, thousands, hundrends =
						tostring(city.Population.Value.X):match("(%-?%d?)(%d*)(%.?.*)")
					MainFrame.CityFrame.Main.CityName.Text = selected[1].Name
					MainFrame.CityFrame.Main.Population.Text = millions
						.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. hundrends
					selectedCenterPos = selected[1].Position
				end
			else
				Disengage()
			end
		end
	end
	if leftMouseDown and (mouseInteractionType == "" or v_u_18) then
		GameGui.DragFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
	end
	if v313 then
		v_u_14 = 1
	end
end)
Mouse.Move:Connect(function()
	-- upvalues: (ref) leftMouseDown, (ref) mouseInteractionType, (ref) v_u_18, (ref) isMobile, (copy) MainFrame, (copy) GameGui, (copy) Mouse, (copy) CheckLand, (ref) currentMapType, (copy) coefficient, (ref) selectedCenterPos, (copy) MakePath, (ref) currentCountry
	if leftMouseDown and (mouseInteractionType == "" or v_u_18) then
		local v331 = true
		if isMobile then
			if MainFrame.MobileFrame.LowerLeftFrame.Move.Text == "Map Move Mode" then
				v331 = false
			end
		end
		print("Checking if can drag", isMobile, MainFrame.MobileFrame.LowerLeftFrame.Move.Text == "Map Move Mode", v331)
		if v331 then
			GameGui.DragFrame.Size = UDim2.new(
				0,
				Mouse.X - GameGui.DragFrame.Position.X.Offset,
				0,
				Mouse.Y - GameGui.DragFrame.Position.Y.Offset
			)
		end
	end
	local roadText = ""
	if Mouse.Target == nil then
		GameGui.TextLabel.Text = ""
		GameGui.LandSea.Text = ""
	else
		local part = CheckLand(Mouse.hit.p)
		if part then
			local terrain = not part:GetAttribute("Terrain") and "" or part:GetAttribute("Terrain")
			if part:GetAttribute("Biome") then
				terrain = terrain .. "\n" .. part:GetAttribute("Biome")
			end
			if currentMapType == "Tiles" then
				terrain = terrain .. "\n" .. part.Name
			end
			GameGui.LandSea.Text = terrain
		else
			GameGui.LandSea.Text = "Sea"
		end
		if workspace:FindFirstChild("CirclePath") then
			roadText = "\n"
				.. math.ceil(
					coefficient
						* math.pi
						* workspace.Baseplate.Size.X
						* math.deg((math.acos((selectedCenterPos.Unit:Dot(Mouse.hit.p.Unit)))))
						/ 360
						* 10
				) / 10
				.. " km"
			if mouseInteractionType == "RoadBuild" then
				local millions, thousands, hundrends = tostring(
					(
						math.ceil(
							(
								coefficient
								* math.pi
								* workspace.Baseplate.Size.X
								* math.deg((math.acos((selectedCenterPos.Unit:Dot(Mouse.hit.p.Unit)))))
								/ 360
								* 4000
							) ^ 1.2
						)
					)
				):match("(%-?%d?)(%d*)(%.?.*)")
				roadText = roadText
					.. "\nCost: $"
					.. millions
					.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. hundrends
					.. "\nPress Z to disengage"
			end
			MakePath()
		else
			roadText = ""
			if mouseInteractionType == "RoadDestroy" then
				roadText = Mouse.Target.Parent == workspace.Baseplate.Roads and "\nDestroy Road" or roadText
			end
		end
		if Mouse.Target.Parent.Parent.Name == "Cities" then
			GameGui.TextLabel.Position = UDim2.new(0, Mouse.X + 20, 0, Mouse.Y + 20)
			local cityPopulation = Mouse.Target.Population.Value.X
			local cityPopulationText
			if 1000000 <= cityPopulation then
				cityPopulationText = math.ceil(cityPopulation / 100000) / 10 .. "M"
			else
				cityPopulationText = math.ceil(cityPopulation / 100) / 10 .. "k"
			end
			GameGui.TextLabel.Text = Mouse.Target.Parent.Name
				.. "\n"
				.. Mouse.Target.Name
				.. "\nPopulation: "
				.. cityPopulationText
			if 0 < #Mouse.Target.Buildings:GetChildren() then
				GameGui.TextLabel.Text = GameGui.TextLabel.Text .. "\nBuildings: "
				for i, building in pairs(Mouse.Target.Buildings:GetChildren()) do
					GameGui.TextLabel.Text = GameGui.TextLabel.Text .. "\n" .. building.Name
				end
			end
			GameGui.UnitMouse.Text = ""
		elseif Mouse.Target.Parent == workspace.Units then
			if Mouse.Target.Owner.Value == currentCountry or Mouse.Target.Type.Value ~= "Submarine" then
				GameGui.UnitMouse.Text = "[]"
				GameGui.TextLabel.Text = Mouse.Target.Type.Value
				if Mouse.Target.Current.Training:GetAttribute("BiomeTraining") then
					local textLabel = GameGui.TextLabel
					textLabel.Text = textLabel.Text
						.. "\n"
						.. Mouse.Target.Current.Training:GetAttribute("BiomeTraining")
						.. " Specialization"
				end
				GameGui.TextLabel.Position = UDim2.new(0, Mouse.X + 20, 0, Mouse.Y + 20)
			else
				GameGui.UnitMouse.Text = ""
				GameGui.TextLabel.Text = ""
			end
			local mouseTargetScreenPos = workspace.CurrentCamera:WorldToScreenPoint(Mouse.Target.Position)
			if 0 < mouseTargetScreenPos.Z then
				GameGui.UnitMouse.Position = UDim2.new(0, mouseTargetScreenPos.X, 0, mouseTargetScreenPos.Y)
			else
				GameGui.UnitMouse.Position = UDim2.new(2, 0, 2, 0)
			end
		else
			GameGui.TextLabel.Text = ""
			GameGui.UnitMouse.Text = ""
		end
	end
	local landSea = GameGui.LandSea
	landSea.Text = landSea.Text .. roadText
	if GameGui.LandSea.Text ~= "" then
		GameGui.LandSea.Position = UDim2.new(0, Mouse.X - 40, 0, Mouse.Y - 20)
	end
end)
local console = GameGui.ConsoleFrame.Console
game.StarterGui:SetCoreGuiEnabled("PlayerList", false)
game.StarterGui:SetCoreGuiEnabled("Backpack", false)
local function AddPlayer(player)
	-- upvalues: (copy) GameGui, (copy) SetFlag, (copy) MakeMouseOver, (copy) Assets, (copy) MainFrame, (copy) CenterFrameSelect, (copy) console, (copy) AddPlayer
	if not GameGui.PlayerList:FindFirstChild(player.Name) then
		local playerFrame = GameGui.PlayerList.List.Sample:Clone()
		playerFrame.Name = player.Name
		playerFrame.Label.Text = player.Name
		playerFrame.Parent = GameGui.PlayerList
		SetFlag(playerFrame.Flag, player:GetAttribute("Country"))
		playerFrame:SetAttribute("Country", player:GetAttribute("Country") or "")
		MakeMouseOver(playerFrame, player:GetAttribute("Country"), 14)
		playerFrame.MouseButton1Click:Connect(function()
			-- upvalues: (ref) Assets, (ref) GameGui, (copy) player, (ref) MainFrame, (ref) CenterFrameSelect
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			if player:GetAttribute("Country") ~= "" then
				MainFrame.CenterFrame.DiplomacyFrame.Country.Value = player:GetAttribute("Country")
				CenterFrameSelect("DiplomacyFrame")
			end
		end)
		GameGui.PlayerList.CanvasSize = UDim2.new(0, 0, 0, GameGui.PlayerList.List.AbsoluteContentSize.Y * 1.1)
		local playerFrame2 = console.ContainerFrame.PlayerList.List.List.Sample:Clone()
		playerFrame2.Name = player.Name
		playerFrame2.Toggle.Label.Text = player.Name
		playerFrame2.Parent = console.ContainerFrame.PlayerList.List
		SetFlag(playerFrame2.Toggle.Flag, player:GetAttribute("Country"))
		MakeMouseOver(playerFrame2, player:GetAttribute("Country"), 14)
		playerFrame2.Toggle.MouseButton1Click:Connect(function()
			-- upvalues: (copy) playerFrame2
			playerFrame2.OptionFrame.Visible = not playerFrame2.OptionFrame.Visible
			if playerFrame2.OptionFrame.Visible then
				playerFrame2.AutomaticSize = "Y"
			else
				playerFrame2.AutomaticSize = "X"
				playerFrame2.AutomaticSize = "None"
			end
		end)
		playerFrame2.OptionFrame.Abandon.MouseButton1Click:Connect(function()
			-- upvalues: (copy) player
			workspace.GameManager.VipConsole:FireServer("PlayerAction", {
				["Action"] = "Abandon",
				["Player"] = player.Name,
			})
		end)
		playerFrame2.OptionFrame.Kick.MouseButton1Click:Connect(function()
			-- upvalues: (copy) player
			workspace.GameManager.VipConsole:FireServer("PlayerAction", {
				["Action"] = "Kick",
				["Player"] = player.Name,
			})
		end)
		playerFrame2.OptionFrame.Ban.MouseButton1Click:Connect(function()
			-- upvalues: (copy) player
			workspace.GameManager.VipConsole:FireServer("PlayerAction", {
				["Action"] = "Ban",
				["Player"] = player.Name,
			})
		end)
		player:GetAttributeChangedSignal("Country"):Connect(function()
			-- upvalues: (copy) playerFrame, (copy) playerFrame2, (ref) AddPlayer, (copy) player
			playerFrame:Destroy()
			playerFrame2:Destroy()
			AddPlayer(player)
			print("flag changed")
		end)
	end
end
local function ConsoleFrameSelect(Type)
	-- upvalues: (copy) console, (copy) ClearList
	for i, v in pairs(console.ContainerFrame:GetChildren()) do
		if v:IsA("Frame") then
			v.Visible = Type == v.Name
		end
	end
	if Type == "Bans" then
		ClearList(console.ContainerFrame.Bans.List.List)
		for i, ban in pairs(workspace.ServerSettings.Bans:GetChildren()) do
			local banFrame = console.ContainerFrame.Bans.List.List.Sample:Clone()
			banFrame.Label.Text = ban.Name
			banFrame.Name = ban.Name
			banFrame.Parent = console.ContainerFrame.Bans.List
			banFrame.Delete.MouseButton1Click:Connect(function()
				-- upvalues: (copy) banFrame
				workspace.GameManager.VipConsole:FireServer("PlayerAction", {
					["Action"] = "ClearBan",
					["Player"] = ban.Name,
				})
				banFrame:Destroy()
			end)
		end
	end
end
GameGui.ConsoleFrame.Toggle.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	GameGui.ConsoleFrame.Console.Visible = not GameGui.ConsoleFrame.Console.Visible
end)
coroutine.resume(coroutine.create(function()
	-- upvalues: (copy) LocalPlayer, (copy) GameGui
	while task.wait(1) do
		warn("VIP check: ", workspace.GameManager.VipConsole.VipOwner.Value)
		if LocalPlayer.UserId == workspace.GameManager.VipConsole.VipOwner.Value then
			GameGui.ConsoleFrame.Visible = true
			warn("You are the vip server owner")
			return
		end
		if workspace.GameManager.VipConsole.VipOwner:GetAttribute("Cached") then
			warn("Cache return")
			return
		end
	end
end))
coroutine.resume(coroutine.create(function()
	-- upvalues: (copy) LocalPlayer, (copy) GameGui
	if LocalPlayer:GetAttribute("Authorized") and 2 <= LocalPlayer:GetAttribute("Authorized") then
		GameGui.ConsoleFrame.Visible = true
		warn("You are staff")
	end
end))
for i, v in pairs(console.ButtonFrame:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			-- upvalues: (copy) ConsoleFrameSelect
			ConsoleFrameSelect(v.Name)
		end)
	end
end
ConsoleFrameSelect("Settings")
local allServerSettings = {
	["CedeAutoCore"] = "Ceding Auto Cores",
	["CedeLimit"] = "Cede Limits",
	["EmptyCede"] = "Cede to Empty Countries",
	["Events"] = "Events",
	["NewRulerTimer"] = "New Ruler Timer",
	["PopulationGrowth"] = "Population Change",
}
local serverSettings = workspace.ServerSettings:GetAttributes()
for i, _ in pairs(serverSettings) do
	local settingFrame = console.ContainerFrame.Settings.List.List.Sample:Clone()
	settingFrame.Title.Text = allServerSettings[i] or i
	settingFrame.Name = i
	settingFrame.Parent = console.ContainerFrame.Settings.List
	settingFrame.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) i
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		workspace.GameManager.VipConsole:FireServer("Option", i)
	end)
end
table.insert(loopFunctions2, function()
	-- upvalues: (copy) console, (copy) serverSettings, (copy) ReferenceTable
	if console.ContainerFrame.Settings.Visible then
		for i, _ in pairs(serverSettings) do
			if workspace.ServerSettings:GetAttribute(i) then
				console.ContainerFrame.Settings.List[i].Status.BackgroundColor3 = ReferenceTable.Colors.Positive[2]
			else
				console.ContainerFrame.Settings.List[i].Status.BackgroundColor3 = ReferenceTable.Colors.Negative[2]
			end
		end
	end
end)
table.insert(loopFunctions2, function()
	-- upvalues: (copy) GameGui
	for i, playerFrame in pairs(GameGui.PlayerList:GetChildren()) do
		if playerFrame:IsA("TextButton") then
			if playerFrame:GetAttribute("Country") then
				local playerFaction = workspace.Factions:FindFirstChild(playerFrame:GetAttribute("Country"), true)
				if playerFaction then
					playerFrame.Label.Text = playerFrame.Name .. "   |   " .. playerFaction.Parent.Parent.Name
				else
					playerFrame.Label.Text = playerFrame.Name
				end
			end
		end
	end
end)
for i, player in pairs(game.Players:GetChildren()) do
	AddPlayer(player)
end
game.Players.PlayerAdded:Connect(function(player)
	-- upvalues: (copy) AddPlayer
	AddPlayer(player)
end)
game.Players.PlayerRemoving:Connect(function(player)
	-- upvalues: (copy) GameGui, (copy) console
	local playerFrame = GameGui.PlayerList:FindFirstChild(player.Name)
	if playerFrame then
		playerFrame:Destroy()
		console.ContainerFrame.PlayerList.List[player.Name]:Destroy()
		GameGui.PlayerList.CanvasSize = UDim2.new(0, 0, 0, GameGui.PlayerList.List.AbsoluteContentSize.Y * 1.1)
	end
end)
GameGui.PlayerListToggle.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	GameGui.PlayerList.Visible = not GameGui.PlayerList.Visible
end)
local function BuildUnit(unitType)
	-- upvalues: (ref) mouseInteractionType, (ref) selected, (copy) MainFrame, (copy) Assets, (copy) GameGui
	if mouseInteractionType == "SelectCity" then
		workspace.GameManager.CreateUnit:FireServer(
			selected,
			unitType,
			MainFrame.CityFrame.UnitFrame.GroupFrame.Group.Text
		)
		local recruitSound =
			Assets.Audio[(Assets.UnitStats[unitType].TransverseType.Value == "Naval" and "Destroyer" or Assets.UnitStats[unitType].TransverseType.Value == "Air" and "Tank" or unitType) .. "Recruit"]:Clone()
		recruitSound.Parent = GameGui
		recruitSound:Play()
		game.Debris:AddItem(recruitSound, 15)
	end
end
local function BuildBuilding(buildingType)
	-- upvalues: (ref) mouseInteractionType, (ref) selected, (copy) Assets, (copy) GameGui, (copy) MainFrame
	if mouseInteractionType == "SelectCity" then
		local sideAlertText = ""
		if 3 < #selected then
			sideAlertText = buildingType == "Fortifications" and "Select less than 4 cities to build the building!"
				or sideAlertText
		end
		if sideAlertText == "" then
			local destroyerRecruitSound = Assets.Audio.DestroyerRecruit:Clone()
			destroyerRecruitSound.Parent = GameGui
			destroyerRecruitSound:Play()
			game.Debris:AddItem(destroyerRecruitSound, 15)
			workspace.GameManager.CreateBuilding:FireServer(selected, buildingType)
			return
		end
		local sideAlertTextColor = Color3.fromRGB(255, 121, 121)
		local aliveTime = 4
		coroutine.resume(coroutine.create(function()
			-- upvalues: (ref) MainFrame, (copy) sideAlertText, (copy) sideAlertTextColor, (copy) aliveTime
			local sideAlert = MainFrame.RightFrame.Notifications.UIListLayout.MSG:Clone()
			sideAlert.Text = sideAlertText
			sideAlert.TextColor3 = sideAlertTextColor
			sideAlert.Parent = MainFrame.RightFrame.Notifications
			wait(aliveTime)
			game:GetService("TweenService")
				:Create(sideAlert, TweenInfo.new(3, Enum.EasingStyle.Linear), {
					["TextStrokeTransparency"] = 1,
					["TextTransparency"] = 1,
				})
				:Play()
			wait(3.1)
			sideAlert:Destroy()
		end))
	end
end
for i, unitStats in pairs(Assets.UnitStats:GetChildren()) do
	local unitFrame = MainFrame.CityFrame.UnitFrame.UnitFrame.List.Sample:Clone()
	unitFrame.Name = unitStats.Name
	unitFrame.Type.Text = unitStats.Name
	if unitStats.TransverseType.Value == "Naval" then
		unitFrame.Frame.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
		unitFrame.LayoutOrder = 3
	elseif unitStats.TransverseType.Value == "Air" then
		unitFrame.Frame.BackgroundColor3 = Color3.fromRGB(149, 255, 116)
		unitFrame.LayoutOrder = 2
	end
	if unitStats.Name == "Nuke" then
		unitFrame.Frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		unitFrame.LayoutOrder = 5
	end
	unitFrame.Parent = MainFrame.CityFrame.UnitFrame.UnitFrame
	unitFrame.MouseButton1Click:Connect(function()
		-- upvalues: (copy) BuildUnit, (copy) v_u_386, (copy) v_u_387
		BuildUnit(unitStats.Name)
	end)
	unitFrame.MouseEnter:Connect(function()
		-- upvalues: (copy) MainFrame, (copy) v_u_386, (copy) v_u_387, (copy) CountryModifier, (ref) currentCountry
		MainFrame.CityFrame.UnitFrame.DescFrame.Title.Text = unitStats.Name
		MainFrame.CityFrame.UnitFrame.DescFrame.Desc.Text = unitStats:GetAttribute("Desc")
		local costMillions, costThousands, costHundrends = tostring(
			math.ceil(
				unitStats.Cost.Value
					* CountryModifier(currentCountry, "Military Cost")
					* CountryModifier(currentCountry, unitStats.Name .. " Cost")
					* CountryModifier(currentCountry, unitStats.TransverseType.Value .. " Cost")
					* 10
			) / 10
		):match("(%-?%d?)(%d*)(%.?.*)")
		local cost = costMillions .. costThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse() .. costHundrends
		local manpowerMillions, manpowerThousands, manpowerHundrends =
			tostring(unitStats.ManpowerCost.Value):match("(%-?%d?)(%d*)(%.?.*)")
		local manpower = manpowerMillions
			.. manpowerThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. manpowerHundrends
		local upkeepMillions, upkeepThousands, upkeepHundrends = tostring(
			math.ceil(
				unitStats.Cost:GetAttribute("UpkeepCost")
					* CountryModifier(currentCountry, "Military Upkeep")
					* CountryModifier(currentCountry, unitStats.Name .. " Upkeep")
					* CountryModifier(currentCountry, unitStats.TransverseType.Value .. " Upkeep")
					* 10
			) / 10
		):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CityFrame.UnitFrame.DescFrame.Price.Text = "Cost: $"
			.. cost
			.. " / "
			.. manpower
			.. " MP - Upkeep: $"
			.. upkeepMillions
			.. upkeepThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. upkeepHundrends
	end)
	MakeMouseOver(unitFrame, "", 14)
end
MainFrame.CityFrame.UnitFrame.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CityFrame.UnitFrame.Visible = false
	MainFrame.CityFrame.Main.Visible = true
end)
MainFrame.CityFrame.UnitFrame.GroupFrame.Group.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) ClearList, (ref) currentCountryData, (copy) ScaleScrollGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.Visible then
		MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.Visible = false
	else
		ClearList(MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.List)
		for i, group in pairs(currentCountryData.Military.Groups:GetChildren()) do
			local groupFrame = MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.List.Sample:Clone()
			groupFrame.Name = group.Name
			groupFrame.Text = group.Name
			groupFrame.Parent = MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame
		end
		local groupNoneFrame = MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.List.Sample:Clone()
		groupNoneFrame.Name = "None"
		groupNoneFrame.Text = "None"
		groupNoneFrame.LayoutOrder = 1
		groupNoneFrame.Parent = MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame
		for i, v in pairs(MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame:GetChildren()) do
			if v:IsA("TextButton") then
				v.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (copy) v_u_406, (copy) v_u_407
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					MainFrame.CityFrame.UnitFrame.GroupFrame.Group.Text = v.Text
					MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.Visible = false
				end)
			end
		end
		ScaleScrollGui(MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.List, "Y")
		MainFrame.CityFrame.UnitFrame.GroupFrame.ListFrame.Visible = true
	end
end)
MainFrame.CityFrame.Main.AFrame.Unit.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) selected, (ref) currentCountry, (copy) MainFrame, (copy) ScaleScrollGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if selected[1].Parent.Name == currentCountry then
		MainFrame.CityFrame.UnitFrame.Visible = true
		MainFrame.CityFrame.Main.Visible = false
		ScaleScrollGui(MainFrame.CityFrame.UnitFrame.UnitFrame.List, "Y")
	end
end)
MainFrame.CityFrame.Main.AFrame.Road.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) selected, (ref) currentCountry, (ref) selectedCenterPos, (ref) v_u_14, (copy) Mouse, (ref) mouseInteractionType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if #selected == 1 and selected[1].Parent.Name == currentCountry then
		selectedCenterPos = selected[1].Position
		v_u_14 = 1
		if not workspace:FindFirstChild("CirclePath") then
			local circlePath = Instance.new("Folder")
			circlePath.Name = "CirclePath"
			circlePath.Parent = workspace
			Mouse.TargetFilter = circlePath
		end
		mouseInteractionType = "RoadBuild"
	end
end)
MainFrame.CityFrame.Main.AFrame.RoadDestroy.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) selected, (ref) mouseInteractionType, (ref) v_u_14, (copy) Mouse
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if #selected == 1 then
		mouseInteractionType = "RoadDestroy"
		v_u_14 = 1
		Mouse.TargetFilter = workspace.Baseplate.Parts
	end
end)
local buildingsStats = Assets.Buildings:GetChildren()
for i, buildingStats in pairs(buildingsStats) do
	local buildingFrame = MainFrame.CityFrame.BuildingFrame.BuildingFrame.List.Sample:Clone()
	buildingFrame.Name = buildingStats.Name
	buildingFrame.Type.Text = buildingStats.Name
	if buildingStats:FindFirstChild("Tier") then
		buildingFrame.Frame.BackgroundColor3 = buildingStats.Tier.Value
		buildingFrame.LayoutOrder = buildingStats.Tier.Value.r * 255
	end
	buildingFrame.Parent = MainFrame.CityFrame.BuildingFrame.BuildingFrame
	buildingFrame.MouseButton1Click:Connect(function()
		-- upvalues: (copy) BuildBuilding, (copy) v_u_414
		BuildBuilding(buildingStats.Name)
	end)
	buildingFrame.MouseEnter:Connect(function()
		-- upvalues: (copy) MainFrame, (copy) v_u_414, (ref) selected, (copy) CountryModifier, (ref) currentCountry
		MainFrame.CityFrame.BuildingFrame.DescFrame.Title.Text = buildingStats.Name
		MainFrame.CityFrame.BuildingFrame.DescFrame.Desc.Text = buildingStats.Value
		local defaultCost = 0
		for i, v in pairs(selected) do
			local cost = math.ceil(
				(
					math.clamp(
						v.Population.Value.X / 100000 * buildingStats.Cost.Value,
						buildingStats.Cost.Value / 4,
						math.huge
					)
				)
			)
			if buildingStats.Cost:FindFirstChild("Fixed") then
				cost = buildingStats.Cost.Value
			end
			if buildingStats.Name == "Develop City" then
				cost = cost * v.Population.Value.Y
			end
			defaultCost = defaultCost
				+ cost
					* CountryModifier(currentCountry, "Building Cost")
					* CountryModifier(currentCountry, buildingStats.Name .. " Cost")
		end
		local millions, thousands, hundrends = tostring(defaultCost):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CityFrame.BuildingFrame.DescFrame.Price.Text = "Cost: $"
			.. millions
			.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. hundrends
	end)
	MakeMouseOver(buildingFrame, "", 14)
end
warn(#buildingsStats, MainFrame.CityFrame.BuildingFrame.BuildingFrame.List.AbsoluteContentSize.Y * 1.1)
MainFrame.CityFrame.BuildingFrame.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CityFrame.BuildingFrame.Visible = false
	MainFrame.CityFrame.Main.Visible = true
end)
MainFrame.CityFrame.Main.AFrame.Building.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) selected, (ref) currentCountry, (copy) ScaleScrollGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if selected[1].Parent.Name == currentCountry then
		ScaleScrollGui(MainFrame.CityFrame.BuildingFrame.BuildingFrame.List, "Y")
		MainFrame.CityFrame.BuildingFrame.Visible = true
		MainFrame.CityFrame.Main.Visible = false
	end
end)
local searchBox = MainFrame.CityFrame.CountryList.SearchSample.Box
local countryList = MainFrame.CityFrame.CountryList
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) countryList, (copy) searchBox
	for i, v in pairs(countryList:GetChildren()) do
		if v:IsA("GuiBase") then
			if v ~= searchBox.Parent then
				if string.match(string.lower(v.Name), string.lower(searchBox.Text)) == nil then
					v.Visible = false
				else
					v.Visible = true
				end
			end
		end
	end
end)
MainFrame.CityFrame.Main.Cede.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ClearList, (copy) MainFrame, (ref) currentCountry, (ref) selected, (copy) SetFlag, (copy) ScaleScrollGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ClearList(MainFrame.CityFrame.CountryList.List, { MainFrame.CityFrame.CountryList.SearchSample })
	for i, country in pairs(workspace.Baseplate.Cities:GetChildren()) do
		if country.Name ~= currentCountry then
			if
				MainFrame.CityFrame.Main.Cede.Text ~= "Transfer Occupation" and true
				or require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
					selected[1]:GetAttribute("ActualOwner"),
					country.Name,
					"Against"
				) and true
				or false
			then
				local button = MainFrame.CityFrame.CountryList.List.Sample:Clone()
				button.Name = country.Name
				button.Text = country.Name
				SetFlag(button.Flag, country.Name)
				button.Parent = MainFrame.CityFrame.CountryList
				button.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) selected, (copy) v_u_429, (copy) v_u_430, (ref) MainFrame
					local v432 = Assets.Audio.Click_2:Clone()
					v432.Parent = GameGui
					v432:Play()
					game.Debris:AddItem(v432, 15)
					workspace.GameManager.Cede:FireServer(selected, country)
					MainFrame.CityFrame.CountryList.Visible = false
				end)
			end
		end
	end
	ScaleScrollGui(MainFrame.CityFrame.CountryList.List, "Y")
	MainFrame.CityFrame.CountryList.Visible = true
end)
MakeMouseOver(
	MainFrame.CityFrame.Main.Move,
	"Move capital\n \nCosts 250 Political Power\n500 during wartime\n \nDecreases stability by 3% [10% during wartime]",
	14
)
MainFrame.CityFrame.Main.Move.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) selected, (ref) currentCountry
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if #selected == 1 and selected[1].Parent.Name == currentCountry then
		workspace.GameManager.ChangeCapital:FireServer(selected[1])
		Disengage()
	end
end)
MainFrame.CityFrame.Main.Flag.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) selected, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.DiplomacyFrame.Country.Value = selected[1].Parent.Name
	CenterFrameSelect("DiplomacyFrame")
end)
MakeMouseOver(MainFrame.CityFrame.Main.Population, "", 14)
MainFrame.CityFrame.Main.Burn.MouseButton1Click:Connect(function()
	-- upvalues: (ref) mouseInteractionType, (ref) selected, (ref) currentCountry, (copy) Assets, (copy) GameGui
	if mouseInteractionType == "SelectCity" then
		for i, v in pairs(selected) do
			if v.Parent.Parent == workspace.Baseplate.Cities then
				if v.Parent.Name == currentCountry then
					workspace.GameManager.Burn:FireServer(v)
					local clickSound = Assets.Audio.ScorchedEarth:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
				end
			end
		end
	end
end)
MainFrame.CityFrame.Main.Canal.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "SelectCity" and selected[1]:FindFirstChild("Canal") then
		for i, v in pairs(workspace.Baseplate.Canals[selected[1].Canal.Value].ControlDetails.BlackList:GetChildren()) do
			if MainFrame.CityFrame.CanalFrame.WhiteList:FindFirstChild(v.Name) then
				MainFrame.CityFrame.CanalFrame.WhiteList[v.Name].Parent = MainFrame.CityFrame.CanalFrame.BlackList
			end
		end
		for i, v in pairs(MainFrame.CityFrame.CanalFrame.BlackList:GetChildren()) do
			if v:IsA("TextButton") then
				if
					not workspace.Baseplate.Canals[selected[1].Canal.Value].ControlDetails.BlackList:FindFirstChild(
						v.Name
					)
				then
					MainFrame.CityFrame.CanalFrame.BlackList[v.Name].Parent = MainFrame.CityFrame.CanalFrame.WhiteList
				end
			end
		end
		MainFrame.CityFrame.CanalFrame.Visible = true
		MainFrame.CityFrame.Main.Visible = false
	end
end)
MainFrame.CityFrame.CanalFrame.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CityFrame.CanalFrame.Visible = false
	MainFrame.CityFrame.Main.Visible = true
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame
	if MainFrame.CityFrame.CanalFrame.Visible then
		MainFrame.CityFrame.CanalFrame.WhiteList.CanvasSize =
			UDim2.new(0, 0, 0, MainFrame.CityFrame.CanalFrame.WhiteList.UIListLayout.AbsoluteContentSize.Y * 1.1)
		MainFrame.CityFrame.CanalFrame.BlackList.CanvasSize =
			UDim2.new(0, 0, 0, MainFrame.CityFrame.CanalFrame.BlackList.UIListLayout.AbsoluteContentSize.Y * 1.1)
	end
end)
table.insert(loopFunctions, function()
	-- upvalues: (ref) currentCountry
	local function SetC(part, colorName)
		for i, v in pairs(part:GetChildren()) do
			if v:IsA("BasePart") then
				v.BrickColor = BrickColor.new(colorName)
			end
		end
	end
	for i, v in pairs(workspace.Baseplate.Canals:GetChildren()) do
		if v.ControlDetails.BlackList:FindFirstChild(currentCountry) then
			SetC(v, "Bright red")
		else
			SetC(v, "Gold")
		end
	end
end)
for i, button in pairs(MakeCountryList(MainFrame.CityFrame.CanalFrame.WhiteList, true)) do
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) v_u_450, (copy) v_u_451, (copy) MainFrame, (ref) selected
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		if button.Parent.Name == "WhiteList" then
			button.Parent = MainFrame.CityFrame.CanalFrame.BlackList
			workspace.GameManager.ChangeCanal:FireServer(selected[1], "Block", button.Name)
		else
			button.Parent = MainFrame.CityFrame.CanalFrame.WhiteList
			workspace.GameManager.ChangeCanal:FireServer(selected[1], "Allow", button.Name)
		end
	end)
end
local whitelistSearch = MainFrame.CityFrame.CanalFrame.WhiteList.SearchSample:Clone()
whitelistSearch.Parent = MainFrame.CityFrame.CanalFrame.BlackList
local whitelistSearchBox = whitelistSearch.Box
local blacklist = MainFrame.CityFrame.CanalFrame.BlackList
whitelistSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) blacklist, (copy) Assets, (copy) whitelistSearchBox
	for i, v in pairs(blacklist:GetChildren()) do
		if Assets.Flag:FindFirstChild(v.Name) then
			if string.match(string.lower(v.Name), string.lower(whitelistSearchBox.Text)) == nil then
				v.Visible = false
			else
				v.Visible = true
			end
		end
	end
end)
MainFrame.CityFrame.CanalFrame.WhiteAll.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	for i, v in pairs(MainFrame.CityFrame.CanalFrame.BlackList:GetChildren()) do
		if v:IsA("TextButton") then
			v.Parent = MainFrame.CityFrame.CanalFrame.WhiteList
			workspace.GameManager.ChangeCanal:FireServer(selected[1], "Allow", v.Name)
		end
	end
end)
MainFrame.CityFrame.CanalFrame.BlackAll.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) currentCountry, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	for i, v in pairs(MainFrame.CityFrame.CanalFrame.WhiteList:GetChildren()) do
		if v:IsA("TextButton") then
			if v.Name ~= currentCountry then
				v.Parent = MainFrame.CityFrame.CanalFrame.BlackList
				workspace.GameManager.ChangeCanal:FireServer(selected[1], "Block", v.Name)
			end
		end
	end
end)
MainFrame.CityFrame.ResourceFrame.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CityFrame.ResourceFrame.Visible = false
	MainFrame.CityFrame.Main.Visible = true
end)
MainFrame.CityFrame.Main.AFrame.Resource.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CityFrame.ResourceFrame.Visible = true
	MainFrame.CityFrame.Main.Visible = false
end)
table.insert(loopFunctions, function()
	-- upvalues: (ref) mouseInteractionType, (ref) cityAnnexationFrame, (copy) MainFrame, (ref) selected, (copy) SetFlag, (ref) currentCountry, (ref) currentCountryData, (copy) ReferenceTable, (copy) Assets, (copy) GameGui, (copy) MakeMouseOver
	if mouseInteractionType == "SelectCity" and cityAnnexationFrame ~= MainFrame.WarOverFrame.SelectFrame then
		MainFrame.CityFrame.Main.StatsFrame.UnrestBack.Bar.Size =
			UDim2.new(math.clamp(selected[1]:GetAttribute("Unrest") / 100, 0, 1), 0, 1, 0)
		SetFlag(MainFrame.CityFrame.Main.Flag, selected[1].Parent.Name)
		if selected[1]:GetAttribute("IsCoring") then
			MainFrame.CityFrame.Main.Integrate.Visible = true
			MainFrame.CityFrame.Main.Integrate.UnrestBack.Bar.Size =
				UDim2.new(1 - selected[1]:GetAttribute("IsCoring") / 1200, 0, 1, 0)
		else
			MainFrame.CityFrame.Main.Integrate.Visible = false
		end
		local citiesEcoStats = Vector3.new()
		local citiesPopulation = 0
		for i, v in pairs(MainFrame.CityFrame.ResourceFrame.RList:GetChildren()) do
			if v:IsA("TextLabel") then
				v.LayoutOrder = 0
				v.Visible = false
			end
		end
		for i, v in pairs(selected) do
			citiesPopulation = citiesPopulation + v.Population.Value.X
			citiesEcoStats = citiesEcoStats + v.EcoStat.Value
			if MainFrame.CityFrame.ResourceFrame.Visible then
				for attributeIndex, attributeValue in pairs(v.Resources:GetAttributes()) do
					local v473 = MainFrame.CityFrame.ResourceFrame.RList[string.gsub(attributeIndex, "_", " ")]
					v473.LayoutOrder = v473.LayoutOrder + attributeValue * 100
					if attributeValue ~= 0 then
						v473.Visible = true
					end
				end
			end
		end
		local populationMillions, populationThousands, populationHundrends =
			tostring(citiesPopulation):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CityFrame.Main.Population.Text = "Population: "
			.. populationMillions
			.. populationThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. populationHundrends
		if #selected == 1 then
			MainFrame.CityFrame.Main.CityName.Text = selected[1].Name
		else
			MainFrame.CityFrame.Main.CityName.Text = #selected .. " cities"
		end
		if selected[1].Parent.Name == currentCountry then
			local growthRate = "Growth Rate: "
				.. math.ceil(
					(currentCountryData.Population.GrowthRate.Value + selected[1].Population.GrowthRate.Value) * 100
				) / 100
				.. "% a year:\n\n"
			for attributeIndex, attributeValue in pairs(currentCountryData.Population.GrowthRate:GetAttributes()) do
				local text1 = math.ceil(attributeValue * 100) / 100
				local text2 = ": "
				local text4 = text1 .. "%"
				local Table = { -0.01, 0.01 }
				local colors = {
					ReferenceTable.Colors.Negative[1],
					ReferenceTable.Colors.Gold[1],
					ReferenceTable.Colors.Positive[1],
				}
				local text3
				if text1 < Table[1] then
					text3 = colors[1]
				elseif Table[1] <= text1 and text1 <= Table[2] then
					text3 = colors[2]
				elseif Table[2] < text1 then
					text3 = colors[3]
				else
					text3 = nil
				end
				growthRate = growthRate
					.. attributeIndex
					.. text2
					.. '<font color="rgb('
					.. text3
					.. ')">'
					.. text4
					.. "</font>"
					.. "\n"
			end
			local growthRateStats = growthRate .. "\n"
			for attributeIndex, attributeValue in pairs(selected[1].Population.GrowthRate:GetAttributes()) do
				local text1 = math.ceil(attributeValue * 100) / 100
				local text2 = ": "
				local text4 = text1 .. "%"
				local Table = { -0.01, 0.01 }
				local colors = {
					ReferenceTable.Colors.Negative[1],
					ReferenceTable.Colors.Gold[1],
					ReferenceTable.Colors.Positive[1],
				}
				local text3
				if text1 < Table[1] then
					text3 = colors[1]
				elseif Table[1] <= text1 and text1 <= Table[2] then
					text3 = colors[2]
				elseif Table[2] < text1 then
					text3 = colors[3]
				else
					text3 = nil
				end
				growthRateStats = growthRateStats
					.. attributeIndex
					.. text2
					.. '<font color="rgb('
					.. text3
					.. ')">'
					.. text4
					.. "</font>"
					.. "\n"
			end
			MainFrame.CityFrame.Main.Population.MouseOverText.Value = string.gsub(growthRateStats, "_", " ")
		else
			MainFrame.CityFrame.Main.Population.MouseOverText.Value = ""
		end
		if MainFrame.CityFrame.ResourceFrame.Visible then
			for i, v in pairs(MainFrame.CityFrame.ResourceFrame.RList:GetChildren()) do
				if v:IsA("TextLabel") then
					v.RText.Text = tostring(v.LayoutOrder / 100) .. " Units"
				end
			end
		end
		local taxMillions, taxThousands, taxHundrends =
			tostring(math.ceil(citiesEcoStats.X)):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CityFrame.Main.StatsFrame.Tax.Text = "Tax: $"
			.. taxMillions
			.. taxThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. taxHundrends
		local manpowerMillions, manpowerThousands, manpowerHundrends =
			tostring(math.ceil(citiesEcoStats.Y)):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CityFrame.Main.StatsFrame.Manpower.Text = "Manpower: +"
			.. manpowerMillions
			.. manpowerThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. manpowerHundrends
		local resourcesMillions, resourcesThousands, resourcesHundrends =
			tostring(math.ceil(citiesEcoStats.Z)):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CityFrame.Main.StatsFrame.Resource.Text = "Resources: $"
			.. resourcesMillions
			.. resourcesThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. resourcesHundrends
		MainFrame.CityFrame.Main.StatsFrame.Tier.Text = "Tier: "
			.. (
				selected[1].Population.Value.Y == 2 and "II"
				or selected[1].Population.Value.Y == 3 and "III"
				or selected[1].Population.Value.Y == 4 and "IV"
				or selected[1].Population.Value.Y == 5 and "V"
				or selected[1].Population.Value.Y == 6 and "VI"
				or selected[1].Population.Value.Y == 7 and "VII"
				or selected[1].Population.Value.Y == 8 and "VIII"
				or "I"
			)
		if selected[1].Parent.Name == currentCountry then
			for i, unitQueueFrame in pairs(MainFrame.CityFrame.UnitFrame.QueueFrame:GetChildren()) do
				if unitQueueFrame.Name ~= "List" then
					if unitQueueFrame.Name ~= "UIPadding" then
						unitQueueFrame:Destroy()
					end
				end
			end
			for i, buildingQueueFrame in pairs(MainFrame.CityFrame.BuildingFrame.QueueFrame:GetChildren()) do
				if buildingQueueFrame.Name ~= "List" then
					if buildingQueueFrame.Name ~= "UIPadding" then
						buildingQueueFrame:Destroy()
					end
				end
			end
			for i, v in pairs(selected[1].Queue:GetChildren()) do
				if v.Unit.Value.Parent.Name == "UnitStats" then
					local frame = MainFrame.CityFrame.UnitFrame.QueueFrame.List.Sample:Clone()
					frame.Type.Text = string.upper(v.Unit.Value.Name)
					frame.Backdrop.Bar.Size = UDim2.new(v.Value.X / v.Value.Z, 0, 1, 0)
					if v.Value.X ~= 0 then
						frame.Name = "Rample"
					end
					frame.Parent = MainFrame.CityFrame.UnitFrame.QueueFrame
				else
					local frame = MainFrame.CityFrame.BuildingFrame.QueueFrame.List.Sample:Clone()
					frame.Type.Text = string.upper(v.Unit.Value.Name)
					frame.Backdrop.Bar.Size = UDim2.new(v.Value.X / v.Value.Z, 0, 1, 0)
					if v.Value.X ~= 0 then
						frame.Name = "Rample"
					end
					frame.Parent = MainFrame.CityFrame.BuildingFrame.QueueFrame
				end
			end
			for i, v in pairs(selected[1].Buildings:GetChildren()) do
				local frame = MainFrame.CityFrame.BuildingFrame.QueueFrame.List.Sample:Clone()
				frame.Type.Text = string.upper(v.Name)
				frame.Backdrop:Destroy()
				frame.Name = "Zone"
				frame.Parent = MainFrame.CityFrame.BuildingFrame.QueueFrame
				frame.X.Visible = true
				frame.X.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) selected, (ref) v_u_514, (copy) v_u_515
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					workspace.GameManager.DestroyBuilding:FireServer(selected, v.Name)
				end)
			end
			MainFrame.CityFrame.Main.Move.Visible = true
			if selected[1]:FindFirstChild("Canal") then
				MainFrame.CityFrame.Main.Canal.Visible = true
			else
				MainFrame.CityFrame.Main.Canal.Visible = false
			end
		else
			MainFrame.CityFrame.Main.Move.Visible = false
			MainFrame.CityFrame.Main.Canal.Visible = false
		end
		if selected[1]:GetAttribute("ActualOwner") == selected[1].Parent.Name then
			MainFrame.CityFrame.Main.StatsFrame.Occupied.Visible = false
			MainFrame.CityFrame.Main.Cede.Text = "Cede"
		else
			MainFrame.CityFrame.Main.StatsFrame.Occupied.Visible = true
			MainFrame.CityFrame.Main.Cede.Text = "Transfer Occupation"
		end
		if workspace.CountryData[selected[1].Parent.Name].Capital.Value == selected[1] then
			MainFrame.CityFrame.Main.Flag.Capital.Visible = true
		else
			MainFrame.CityFrame.Main.Flag.Capital.Visible = false
		end
		for i, v in pairs(MainFrame.CityFrame.Main.AFrame.CoreFrame:GetChildren()) do
			if v.Name ~= "List" then
				v:Destroy()
			end
		end
		for i, v in pairs(selected[1].Core:GetChildren()) do
			local flag = MainFrame.CityFrame.Main.AFrame.CoreFrame.List.Flag:Clone()
			flag.Name = v.Name
			SetFlag(flag, v.Name)
			if v.Value == "Full" then
				flag.BackgroundTransparency = 0.25
				flag.LayoutOrder = 0
			end
			flag.Parent = MainFrame.CityFrame.Main.AFrame.CoreFrame
			MakeMouseOver(flag, v.Name, 14)
		end
		MainFrame.CityFrame.Visible = true
	else
		MainFrame.CityFrame.Visible = false
	end
end)
for i, v in pairs(MainFrame.CenterFrame.ButtonFrame:GetChildren()) do
	if v:IsA("TextButton") then
		if MainFrame.CenterFrame:FindFirstChild(v.Name .. "Frame") then
			v.MouseButton1Click:Connect(function()
				-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect, (copy) v_u_523, (copy) v_u_524
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				CenterFrameSelect(v.Name .. "Frame")
			end)
		end
	end
end
MainFrame.StatsFrame.Flag.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	CenterFrameSelect("EconomyFrame")
end)
MainFrame.CenterFrame.EconomyFrame.Main.Cities.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ClearList, (copy) MainFrame, (ref) currentCountry, (ref) tags
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ClearList(MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.List)
	MainFrame.CenterFrame.EconomyFrame.Cities.Visible = true
	MainFrame.CenterFrame.EconomyFrame.Main.Visible = false
	for i, city in pairs(workspace.Baseplate.Cities[currentCountry]:GetChildren()) do
		if i % 30 == 0 then
			wait()
		end
		local frame = MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.List.Sample:Clone()
		table.insert(tags, frame)
		frame.Name = city.Name .. " "
		frame.LayoutOrder = -city.Population.Value.X
		frame["Select?"].Text = "No"
		frame["Select?"].MouseButton1Click:Connect(function()
			-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame
			local clickSound = Assets.Audio.Click_3:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			if frame["Select?"].Text == "No" then
				frame["Select?"].Text = "Yes"
				frame["Select?"].Number.Value = 1
			else
				frame["Select?"].Text = "No"
				frame["Select?"].Number.Value = 0
			end
		end)
		frame["City Name"].Text = city.Name
		local populationMillions, populationThousands, populationHundrends =
			tostring(city.Population.Value.X):match("(%-?%d?)(%d*)(%.?.*)")
		frame.Population.Text = populationMillions
			.. populationThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. populationHundrends
		frame.Population.Number.Value = city.Population.Value.X
		frame.Tier.Text = city.Population.Value.Y
		frame.Tier.Number.Value = city.Population.Value.Y
		local manpowerMillions, manpowerThousands, manpowerHundrends =
			tostring((math.ceil(city.EcoStat.Value.Y))):match("(%-?%d?)(%d*)(%.?.*)")
		frame["Manpower Gain"].Text = manpowerMillions
			.. manpowerThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. manpowerHundrends
		frame["Manpower Gain"].Number.Value = city.EcoStat.Value.Y * 100
		local taxMillions, taxThousands, taxHundrends =
			tostring((math.ceil(city.EcoStat.Value.X))):match("(%-?%d?)(%d*)(%.?.*)")
		frame["Tax Income"].Text = "$"
			.. taxMillions
			.. taxThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. taxHundrends
		frame["Tax Income"].Number.Value = city.EcoStat.Value.X * 100
		local resourceMillions, resourceThousands, resourceHundrends =
			tostring((math.ceil(city.EcoStat.Value.Z))):match("(%-?%d?)(%d*)(%.?.*)")
		frame["Resource Income"].Text = "$"
			.. resourceMillions
			.. resourceThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. resourceHundrends
		frame["Resource Income"].Number.Value = city.EcoStat.Value.Z * 100
		frame.Unrest.Text = math.ceil((city:GetAttribute("Unrest"))) .. "%"
		frame.Unrest.Number.Value = city:GetAttribute("Unrest") * 100
		if city:GetAttribute("IsCoring") then
			frame.Integration.Text = math.ceil((1 - city:GetAttribute("IsCoring") / 1200) * 100) .. "%"
			frame.Integration.Number.Value = (1 - city:GetAttribute("IsCoring") / 1200) * 10000
		else
			frame.Integration.Text = "100%"
			frame.Integration.Number.Value = 10000
		end
		for i, resource in pairs(Assets.Resources:GetChildren()) do
			local resourceAmount = city.Resources:GetAttribute(string.gsub(resource.Name, "_", " "))
			if resourceAmount then
				frame[resource.Name].Text = math.ceil(resourceAmount * 10) / 10
				frame[resource.Name].Number.Value = resourceAmount * 100
			else
				frame[resource.Name].Text = "0"
				frame[resource.Name].Number.Value = 0
			end
		end
		frame.Parent = MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame
	end
	MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.CanvasSize = UDim2.new(
		0,
		MainFrame.CenterFrame.EconomyFrame.Cities.HeaderFrame.CanvasSize.X.Offset,
		0,
		MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.List.AbsoluteContentSize.Y * 1.05
	)
	MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.CanvasPosition = Vector2.new(0, 0)
end)
MainFrame.CenterFrame.EconomyFrame.Cities.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EconomyFrame.Cities.Visible = false
	MainFrame.CenterFrame.EconomyFrame.Main.Visible = true
end)
MainFrame.CenterFrame.EconomyFrame.Cities.Select.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) mouseInteractionType, (ref) selected, (ref) currentCountry
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	local selectedCities = {}
	local v550 = MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame:GetChildren()
	for i, v in pairs(MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame:GetChildren()) do
		if v:IsA("Frame") then
			if v["Select?"].Text == "Yes" then
				table.insert(selectedCities, v["City Name"].Text)
			end
		end
	end
	Disengage()
	if 0 < #selectedCities then
		mouseInteractionType = "SelectCity"
		for i, cityName in pairs(selectedCities) do
			table.insert(selected, workspace.Baseplate.Cities[currentCountry][cityName])
		end
	end
end)
MainFrame.CenterFrame.EconomyFrame.Cities.SelectAll.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountry, (ref) mouseInteractionType, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	local currentCountryCities = workspace.Baseplate.Cities[currentCountry]:GetChildren()
	if 0 < #currentCountryCities then
		mouseInteractionType = "SelectCity"
		for i, city in pairs(currentCountryCities) do
			table.insert(selected, city)
		end
	end
end)
local economyHeaders = {
	{ "Select?", 30 },
	{ "City Name", 90 },
	{ "Population", 80 },
	{ "Tier", 40 },
	{ "Manpower Gain", 75 },
	{ "Tax Income", 75 },
	{ "Resource Income", 75 },
	{ "Unrest", 60 },
	{ "Integration", 60 },
}
for i, resource in pairs(Assets.Resources:GetChildren()) do
	table.insert(economyHeaders, { resource.Name, 60 })
end
for i, v in pairs(economyHeaders) do
	local frame = MainFrame.CenterFrame.EconomyFrame.Cities.HeaderFrame.Header.List.Sample:Clone()
	frame.Name = v[1]
	frame.Text = v[1]
	frame.Size = UDim2.new(0, v[2], 1, 0)
	frame.LayoutOrder = i
	if i == #economyHeaders then
		frame.VLine.Visible = false
	end
	frame.Parent = MainFrame.CenterFrame.EconomyFrame.Cities.HeaderFrame.Header
	frame.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		local listFrameChildren = MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame:GetChildren()
		local sign = math.sign(listFrameChildren[2].LayoutOrder)
					== math.sign(listFrameChildren[2][v[1]].Number.Value + 1)
				and -1
			or 1
		for i, child in pairs(listFrameChildren) do
			if child:IsA("Frame") then
				child.LayoutOrder = (child[v[1]].Number.Value + 1) * sign
			end
		end
	end)
end
local headerSample = MainFrame.CenterFrame.EconomyFrame.Cities.HeaderFrame.Header:Clone()
headerSample.Name = "Sample"
headerSample.Size = UDim2.new(headerSample.List.AbsoluteContentSize.X, 0, 0, 20)
headerSample.Parent = MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.List
for i, v in pairs(headerSample:GetChildren()) do
	if v:IsA("TextButton") then
		v.AutoButtonColor = false
		v.HLine.Visible = true
		v.Text = "---"
	end
end
MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.Changed:Connect(function()
	-- upvalues: (copy) MainFrame
	MainFrame.CenterFrame.EconomyFrame.Cities.HeaderFrame.CanvasPosition =
		Vector2.new(MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame.CanvasPosition.X, 0)
end)
MainFrame.CenterFrame.EconomyFrame.Cities.HeaderFrame.CanvasSize =
	UDim2.new(0, headerSample.List.AbsoluteContentSize.X * 1.05, 0, 0)
local citySearchBox = MainFrame.CenterFrame.EconomyFrame.Cities.SearchFrame.Box
citySearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) citySearchBox
	for i, cityFrame in pairs(MainFrame.CenterFrame.EconomyFrame.Cities.ListFrame:GetChildren()) do
		if cityFrame:IsA("GuiBase") then
			if cityFrame ~= citySearchBox.Parent then
				if string.match(string.lower(cityFrame.Name), string.lower(citySearchBox.Text)) == nil then
					cityFrame.Visible = false
				else
					cityFrame.Visible = true
				end
			end
		end
	end
end)
MainFrame.CenterFrame.EconomyFrame.Main.Laws.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EconomyFrame.Laws.Visible = true
	MainFrame.CenterFrame.EconomyFrame.Main.Visible = false
end)
MainFrame.CenterFrame.EconomyFrame.Laws.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EconomyFrame.Laws.Visible = false
	MainFrame.CenterFrame.EconomyFrame.Main.Visible = true
end)
local researchSpendingChildren = Assets.Laws.ResearchSpending:GetChildren()
for i, researchSpending in pairs(researchSpendingChildren) do
	local button = MainFrame.CenterFrame.EconomyFrame.Laws.Taxation.List.Sample:Clone()
	button.Name = researchSpending.Name
	button.Text = researchSpending.Value
	button.Size = UDim2.new(1 / #researchSpendingChildren, 0, 1, 0)
	button.LayoutOrder = tonumber(researchSpending.Name)
	button.Parent = MainFrame.CenterFrame.EconomyFrame.Laws.Research
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		workspace.GameManager.ChangeLaw:FireServer("ResearchSpending", tonumber(researchSpending.Name))
	end)
	MakeMouseOver(button, "Research Power Generation: +" .. math.ceil(researchSpending.Name * 0.6 * 100) / 100, 14)
end
local popSpendingChildren = Assets.Laws.PopSpending:GetChildren()
for i, popSpending in pairs(popSpendingChildren) do
	local button = MainFrame.CenterFrame.EconomyFrame.Laws.Taxation.List.Sample:Clone()
	button.Name = popSpending.Name
	button.Text = popSpending.Value
	button.Size = UDim2.new(1 / #popSpendingChildren, 0, 1, 0)
	button.LayoutOrder = tonumber(popSpending.Name)
	button.Parent = MainFrame.CenterFrame.EconomyFrame.Laws.Government
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		workspace.GameManager.ChangeLaw:FireServer("PopSpending", tonumber(popSpending.Name))
	end)
	MakeMouseOver(
		button,
		"Base Stability: +"
			.. popSpending.Name * 5
			.. "%\nRebel Suppression: "
			.. 1 + popSpending.Name
			.. "x\nWar Exhaustion Reduction: "
			.. 0.004 * popSpending.Name
			.. "%\nPolitical Power Gain: "
			.. math.ceil(0.4 * popSpending.Name * 100) / 100,
		14
	)
end
local everyTaxation = Assets.Laws.Taxation:GetChildren()
for i, taxation in pairs(everyTaxation) do
	local button = MainFrame.CenterFrame.EconomyFrame.Laws.Taxation.List.Sample:Clone()
	button.Name = taxation.Name
	button.Text = taxation.Value
	button.Size = UDim2.new(1 / #everyTaxation, 0, 1, 0)
	button.LayoutOrder = tonumber(taxation.Name)
	button.Parent = MainFrame.CenterFrame.EconomyFrame.Laws.Taxation
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) everyTaxation, (copy) v_u_583
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		workspace.GameManager.ChangeLaw:FireServer("Taxation", tonumber(taxation.Name))
	end)
	local text = taxation.Value .. " Taxation\n \n"
	local taxationChildren = taxation:GetChildren()
	for i, child in pairs(taxationChildren) do
		if child:IsA("NumberValue") then
			text = text .. child.Name .. ": " .. math.ceil(child.Value * 100) / 100 .. "x\n"
		elseif child:IsA("IntValue") then
			text = text .. child.Name .. ": " .. (child.Value < 0 and "" or "+") .. child.Value .. "\n"
		end
	end
	MakeMouseOver(button, text, 14)
end
for i, v in pairs(workspace.CountryManager.CountryStatSample.Economy.Revenue:GetChildren()) do
	local textLabel = MainFrame.CenterFrame.EconomyFrame.Main.IncomeFrame.List.SampleText:Clone()
	textLabel.Name = v.Name
	textLabel:SetAttribute("Title", v:GetAttribute("Title"))
	textLabel.LayoutOrder = v:GetAttribute("LayoutOrder")
	textLabel.Parent = MainFrame.CenterFrame.EconomyFrame.Main.IncomeFrame
end
for i, v in pairs(workspace.CountryManager.CountryStatSample.Economy.Expenses:GetChildren()) do
	local textLabel = MainFrame.CenterFrame.EconomyFrame.Main.IncomeFrame.List.SampleText:Clone()
	textLabel.Name = v.Name
	textLabel:SetAttribute("Title", v:GetAttribute("Title"))
	textLabel.LayoutOrder = v:GetAttribute("LayoutOrder")
	textLabel.Parent = MainFrame.CenterFrame.EconomyFrame.Main.ExpensesFrame
end
MakeMouseOver(MainFrame.CenterFrame.EconomyFrame.Main.ExpensesFrame.TradeImport, "", 14)
MakeMouseOver(MainFrame.CenterFrame.EconomyFrame.Main.IncomeFrame.TradeExport, "", 14)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) Assets
	if MainFrame.CenterFrame.EconomyFrame.Visible and MainFrame.CenterFrame.Visible then
		for i, v in pairs(currentCountryData.Economy.Revenue:GetChildren()) do
			local textLabel = MainFrame.CenterFrame.EconomyFrame.Main.IncomeFrame[v.Name]
			local millions, thousands, hundrends = tostring(v.Value):match("(%-?%d?)(%d*)(%.?.*)")
			textLabel.Text = textLabel:GetAttribute("Title")
				.. ": $"
				.. millions
				.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. hundrends
		end
		for i, v in pairs(currentCountryData.Economy.Expenses:GetChildren()) do
			local textLabel = MainFrame.CenterFrame.EconomyFrame.Main.ExpensesFrame[v.Name]
			local millions, thousands, hundrends = tostring(v.Value):match("(%-?%d?)(%d*)(%.?.*)")
			textLabel.Text = textLabel:GetAttribute("Title")
				.. ": $"
				.. millions
				.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. hundrends
		end
		local incomeMillions, incomeThousands, incomeHundrends =
			tostring((currentCountryData.Economy.Revenue:GetAttribute("Total"))):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CenterFrame.EconomyFrame.Main.Income.Text = "$"
			.. incomeMillions
			.. incomeThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. incomeHundrends
		local expenseMillions, expenseThousands, expenseHundrends =
			tostring((currentCountryData.Economy.Expenses:GetAttribute("Total"))):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CenterFrame.EconomyFrame.Main.Expenses.Text = "$"
			.. expenseMillions
			.. expenseThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. expenseHundrends
		local balanceMillions, balanceThousands, balanceHundrends = tostring(
			currentCountryData.Economy.Revenue:GetAttribute("Total")
				- currentCountryData.Economy.Expenses:GetAttribute("Total")
		):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CenterFrame.EconomyFrame.Main.Balance.Text = "$"
			.. balanceMillions
			.. balanceThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. balanceHundrends
		for i, v in pairs(Assets.Laws.Taxation:GetChildren()) do
			if currentCountryData.Laws.Taxation.Value == tonumber(v.Name) then
				MainFrame.CenterFrame.EconomyFrame.Laws.Taxation[v.Name].BackgroundColor3 = Color3.fromRGB(21, 25, 30)
			else
				MainFrame.CenterFrame.EconomyFrame.Laws.Taxation[v.Name].BackgroundColor3 = Color3.fromRGB(30, 36, 43)
			end
		end
		for i, v in pairs(Assets.Laws.ResearchSpending:GetChildren()) do
			if currentCountryData.Laws.ResearchSpending.Value == tonumber(v.Name) then
				MainFrame.CenterFrame.EconomyFrame.Laws.Research[v.Name].BackgroundColor3 = Color3.fromRGB(21, 25, 30)
			else
				MainFrame.CenterFrame.EconomyFrame.Laws.Research[v.Name].BackgroundColor3 = Color3.fromRGB(30, 36, 43)
			end
		end
		for i, v in pairs(Assets.Laws.PopSpending:GetChildren()) do
			if currentCountryData.Laws.PopSpending.Value == tonumber(v.Name) then
				MainFrame.CenterFrame.EconomyFrame.Laws.Government[v.Name].BackgroundColor3 = Color3.fromRGB(21, 25, 30)
			else
				MainFrame.CenterFrame.EconomyFrame.Laws.Government[v.Name].BackgroundColor3 = Color3.fromRGB(30, 36, 43)
			end
		end
	end
end)
MainFrame.RightFrame.PageList.MapMode.Resources.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.RightFrame.PageList.MapMode.Resources.DropDown.Visible =
		not MainFrame.RightFrame.PageList.MapMode.Resources.DropDown.Visible
end)
local resourceFrameSample = MainFrame.RightFrame.PageList.MapMode.Resources.DropDown.List.Sample:Clone()
resourceFrameSample.Name = "None"
resourceFrameSample.Text = "None"
resourceFrameSample.Parent = MainFrame.RightFrame.PageList.MapMode.Resources.DropDown
resourceFrameSample.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) resourcesNumberTags
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	for i, v in pairs(resourcesNumberTags) do
		v:Destroy()
	end
	resourcesNumberTags = {}
end)
local resources = Assets.Resources:GetChildren()
for i, resource in pairs(resources) do
	local frame = MainFrame.CityFrame.ResourceFrame.RList.List.Sample:Clone()
	frame.Name = resource.Name
	frame.Text = resource.Name
	frame.Parent = MainFrame.CityFrame.ResourceFrame.RList
	MainFrame.CityFrame.ResourceFrame.RList.CanvasSize = MainFrame.CityFrame.ResourceFrame.RList.CanvasSize
		+ UDim2.new(0, 0, 0, 25)
	local frame2 = MainFrame.RightFrame.PageList.Resources.GroupFrame.List.Sample:Clone()
	frame2.Name = resource.Name
	frame2.Label.Text = resource.Name
	frame2.Icon.Image = resource:GetAttribute("Icon")
	frame2.Parent = MainFrame.RightFrame.PageList.Resources.GroupFrame
	MainFrame.RightFrame.PageList.Resources.GroupFrame.CanvasSize =
		UDim2.new(0, 0, 0, MainFrame.RightFrame.PageList.Resources.GroupFrame.List.AbsoluteContentSize.Y * 1.1)
	local button = MainFrame.RightFrame.PageList.MapMode.Resources.DropDown.List.Sample:Clone()
	button.Name = resource.Name
	button.Text = resource.Name
	button.Parent = MainFrame.RightFrame.PageList.MapMode.Resources.DropDown
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (ref) resourcesNumberTags, (copy) resources, (copy) v_u_627
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		for i, v in pairs(resourcesNumberTags) do
			v:Destroy()
		end
		resourcesNumberTags = {}
		for i, country in pairs(workspace.Baseplate.Cities:GetChildren()) do
			local countryCities = country:GetChildren()
			for i, city in pairs(countryCities) do
				local cityResource = city.Resources:GetAttribute(string.gsub(resource.Name, " ", "_"))
				if cityResource then
					if 0 < cityResource then
						local numberTag = Assets.FX.NumberTag:Clone()
						numberTag.Number.Text = "+" .. math.ceil(cityResource * 10) / 10
						numberTag.Parent = city
						table.insert(resourcesNumberTags, numberTag)
					end
				end
			end
		end
	end)
	local resourceFrame = MainFrame.CenterFrame.EconomyFrame.Resources.ResourceFrame.List.Sample:Clone()
	resourceFrame.Name = resource.Name
	resourceFrame.Resource.Text = resource.Name .. ":"
	resourceFrame.Icon.Image = resource:GetAttribute("Icon")
	resourceFrame.Parent = MainFrame.CenterFrame.EconomyFrame.Resources.ResourceFrame
	resourceFrame.SelectCities.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountry, (copy) resources, (copy) v_u_627, (ref) mouseInteractionType, (ref) selected
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		Disengage()
		local cityWithResource = {}
		for i, city in pairs(workspace.Baseplate.Cities[currentCountry]:GetChildren()) do
			local cityResource = city.Resources:GetAttribute(string.gsub(resource.Name, " ", "_"))
			if cityResource then
				if 0 < cityResource then
					table.insert(cityWithResource, city)
				end
			end
		end
		if 0 < #cityWithResource then
			mouseInteractionType = "SelectCity"
			selected = cityWithResource
		end
	end)
	resourceFrame.Trade.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) resources, (copy) v_u_627, (ref) currentCountry, (copy) SetFlag, (copy) MakeMouseOver, (ref) currentCountryData, (copy) ReferenceTable, (copy) ScaleScrollGui
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		MainFrame.CenterFrame.EconomyFrame.Resources.ResourceFrame.Visible = false
		MainFrame.CenterFrame.EconomyFrame.Resources.ResourceName.Visible = true
		MainFrame.CenterFrame.EconomyFrame.Resources.ResourceName.Text = resource.Name
		MainFrame.CenterFrame.EconomyFrame.Resources.ResourceName.ResourceName.Text = resource.Name
		for i, v in pairs(MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame:GetChildren()) do
			if v:IsA("Frame") then
				v:Destroy()
			end
		end
		local search = MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame.List.SearchSample:Clone()
		search.LayoutOrder = -1000000000
		search.Parent = MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame
		local searchBox = search.Box
		local tradeFrame = MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			-- upvalues: (copy) tradeFrame, (ref) Assets, (copy) searchBox
			for i, v in pairs(tradeFrame:GetChildren()) do
				if Assets.Flag:FindFirstChild(v.Name) then
					if string.match(string.lower(v.Name), string.lower(searchBox.Text)) == nil then
						v.Visible = false
					else
						v.Visible = true
					end
				end
			end
		end)
		for i, countryData in pairs(workspace.CountryData:GetChildren()) do
			if countryData.Name ~= currentCountry then
				if countryData.Population.Value ~= 0 then
					local frame = MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame.List.Sample:Clone()
					frame.LayoutOrder = -countryData.Resources[resource.Name].Value
						- countryData.Resources[resource.Name].Flow.Value
					if game.Players:FindFirstChild(countryData.Leader.Value) then
						frame.Country.TextColor3 = Color3.fromRGB(255, 208, 89)
					end
					SetFlag(frame.Flag, countryData.Name)
					frame.Name = countryData.Name
					frame.Country.Text = countryData.Name
					frame.Amount.Text = math.floor(countryData.Resources[resource.Name].Value)
						.. "Units "
						.. string.format("[%d]", math.ceil(countryData.Resources[resource.Name].Flow.Value * 10) / 10)
					MakeMouseOver(frame.PriceBox, "Price Modifier", 14)
					MakeMouseOver(frame.AmountBox, "Amount", 14)
					if currentCountryData.Resources[resource.Name].Trade:FindFirstChild(countryData.Name) then
						local resourceTrade =
							currentCountryData.Resources[resource.Name].Trade:FindFirstChild(countryData.Name)
						frame.LayoutOrder = -10000000
						local color = ReferenceTable.Colors.Positive[1]
						if 0 < resourceTrade.Value.X then
							color = ReferenceTable.Colors.Negative[1]
						end
						frame.Amount.RichText = true
						local amount = frame.Amount
						amount.Text = amount.Text
							.. " | Trade: "
							.. '<font color="rgb('
							.. color
							.. ')">'
							.. math.abs(resourceTrade.Value.X)
							.. "</font>"
						frame.Amount.TextColor3 = Color3.fromRGB(255, 234, 158)
					end
					frame.Parent = MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame
					frame.Cancel.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (ref) v_u_653, (copy) v_u_654, (ref) resources, (ref) v_u_627
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						workspace.GameManager.ManageAlliance:FireServer(countryData.Name, "TradeCancel", resource.Name)
					end)
					frame.Buy.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame, (ref) MainFrame, (ref) resources, (ref) v_u_627, (ref) v_u_653, (copy) v_u_654
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						if tonumber(frame.AmountBox.Text) ~= nil then
							local price = math.abs(tonumber(frame.PriceBox.Text))
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Visible = true
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Amount.Value =
								tonumber(frame.AmountBox.Text)
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Price.Value = price
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Resource.Value = resource.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Country.Value = countryData.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Action.Value = "Buy"
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Source.Value = "Trade"
							local millions, thousands, hundrends = tostring(
								(math.ceil(tonumber(frame.AmountBox.Text) * resource.Value * price))
							):match("(%-?%d?)(%d*)(%.?.*)")
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Desc.Text = "You are buying "
								.. tonumber(frame.AmountBox.Text)
								.. " units of "
								.. resource.Name
								.. " every 5 days from "
								.. countryData.Name
								.. " for $"
								.. millions
								.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
								.. hundrends
						end
					end)
					frame.Sell.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame, (ref) MainFrame, (ref) resources, (ref) v_u_627, (ref) v_u_653, (copy) v_u_654
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						if tonumber(frame.AmountBox.Text) ~= nil then
							local price = math.abs(tonumber(frame.PriceBox.Text))
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Visible = true
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Amount.Value =
								tonumber(frame.AmountBox.Text)
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Price.Value = price
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Resource.Value = resource.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Country.Value = countryData.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Action.Value = "Sell"
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Source.Value = "Trade"
							local millions, thousands, hundrends = tostring(
								(math.ceil(tonumber(frame.AmountBox.Text) * resource.Value * 0.8 * price))
							):match("(%-?%d?)(%d*)(%.?.*)")
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Desc.Text = "You are selling "
								.. tonumber(frame.AmountBox.Text)
								.. " units of "
								.. resource.Name
								.. " every 5 days to "
								.. countryData.Name
								.. " for $"
								.. millions
								.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
								.. hundrends
						end
					end)
					MakeMouseOver(frame.BuyBulk, "One time transaction", 14)
					frame.BuyBulk.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame, (ref) MainFrame, (ref) resources, (ref) v_u_627, (ref) v_u_653, (copy) v_u_654
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						if tonumber(frame.AmountBox.Text) ~= nil then
							local price = math.abs(tonumber(frame.PriceBox.Text))
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Visible = true
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Amount.Value =
								tonumber(frame.AmountBox.Text)
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Price.Value = price
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Resource.Value = resource.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Country.Value = countryData.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Action.Value = "Buy"
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Source.Value = "Bulk"
							local millions, thousands, hundrends = tostring(
								(math.ceil(tonumber(frame.AmountBox.Text) * resource.Value * price))
							):match("(%-?%d?)(%d*)(%.?.*)")
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Desc.Text = "You are buying "
								.. tonumber(frame.AmountBox.Text)
								.. " units of "
								.. resource.Name
								.. " one time from "
								.. countryData.Name
								.. " for $"
								.. millions
								.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
								.. hundrends
						end
					end)
					MakeMouseOver(frame.SellBulk, "One time transaction", 14)
					frame.SellBulk.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame, (ref) MainFrame, (ref) resources, (ref) v_u_627, (ref) v_u_653, (copy) v_u_654
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						if tonumber(frame.AmountBox.Text) ~= nil then
							local price = math.abs(tonumber(frame.PriceBox.Text))
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Visible = true
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Amount.Value =
								tonumber(frame.AmountBox.Text)
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Price.Value = price
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Resource.Value = resource.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Country.Value = countryData.Name
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Action.Value = "Sell"
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Source.Value = "Bulk"
							local millions, thousands, hundrends = tostring(
								(math.ceil(tonumber(frame.AmountBox.Text) * resource.Value * 0.8 * price))
							):match("(%-?%d?)(%d*)(%.?.*)")
							MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Desc.Text = "You are selling "
								.. tonumber(frame.AmountBox.Text)
								.. " units of "
								.. resource.Name
								.. " one time from "
								.. countryData.Name
								.. " for $"
								.. millions
								.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
								.. hundrends
						end
					end)
				end
			end
		end
		MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame.Visible = true
		ScaleScrollGui(MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame.List, "Y")
	end)
end
MainFrame.CenterFrame.EconomyFrame.Resources.ResourceFrame.CanvasSize = UDim2.new(0, 0, 0, #resources * 35)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) SetFlag, (copy) Assets, (copy) GameGui
	if MainFrame.RightFrame.PageList.Trade.Visible then
		local tradingCountries = {}
		local trades = {}
		for i, resource in pairs(currentCountryData.Resources:GetChildren()) do
			for i, v in pairs(resource.Trade:GetChildren()) do
				table.insert(tradingCountries, v.Name .. resource.Name)
				table.insert(trades, v)
			end
		end
		for i, v in pairs(MainFrame.RightFrame.PageList.Trade.GroupFrame:GetChildren()) do
			if not table.find(tradingCountries, v.Name) then
				if v.Name ~= "List" then
					v:Destroy()
				end
			end
		end
		for i, v in pairs(trades) do
			if not MainFrame.RightFrame.PageList.Trade.GroupFrame:FindFirstChild(tradingCountries[i]) then
				local frame = MainFrame.RightFrame.PageList.Trade.GroupFrame.List.Sample:Clone()
				frame.Name = tradingCountries[i]
				SetFlag(frame.Flag, v.Name)
				frame.Label.Text = (v.Value.X < 0 and "Selling | " or "Buying | ")
					.. math.ceil(math.abs(v.Value.X) * 100) / 100
					.. " "
					.. v.Parent.Parent.Name
				frame.Parent = MainFrame.RightFrame.PageList.Trade.GroupFrame
				frame.Cancel.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (copy) trades, (copy) i
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					workspace.GameManager.ManageAlliance:FireServer(v.Name, "TradeCancel", v.Parent.Parent.Name)
				end)
			end
		end
		MainFrame.RightFrame.PageList.Trade.GroupFrame.CanvasSize =
			UDim2.new(0, 0, 0, MainFrame.RightFrame.PageList.Trade.GroupFrame.List.AbsoluteContentSize.Y * 1.1)
	end
	if MainFrame.CenterFrame.EconomyFrame.Resources.Visible or MainFrame.RightFrame.PageList.Resources.Visible then
		for i, frame in pairs(MainFrame.CenterFrame.EconomyFrame.Resources.ResourceFrame:GetChildren()) do
			if frame:IsA("Frame") then
				if currentCountryData.Resources:FindFirstChild(frame.Name) then
					local unitsBefore = ""
					if 0 < currentCountryData.Resources[frame.Name].Flow.Value then
						frame.National.TextColor3 = Color3.fromRGB(255, 255, 255)
						unitsBefore = "+"
					elseif currentCountryData.Resources[frame.Name].Value <= 0 then
						frame.National.TextColor3 = Color3.fromRGB(255, 70, 70)
					else
						frame.National.TextColor3 = Color3.fromRGB(255, 163, 70)
					end
					local stockpileMillions, stockpileThousands, stockpileHundrends = tostring(
						math.floor(currentCountryData.Resources[frame.Name].Value * 10) / 10
					):match("(%-?%d?)(%d*)(%.?.*)")
					local stockpile = stockpileMillions
						.. stockpileThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. stockpileHundrends
					local unitsMillions, unitsThousands, unitsHundrends = tostring(
						math.floor(currentCountryData.Resources[frame.Name].Flow.Value * 100) / 100
					):match("(%-?%d?)(%d*)(%.?.*)")
					frame.National.Text = "Stockpile: "
						.. stockpile
						.. " Units    "
						.. unitsBefore
						.. unitsMillions
						.. unitsThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. unitsHundrends
					local unitsMillions2, unitsThousands2, unitsHundrends2 = tostring(
						math.floor(currentCountryData.Resources[frame.Name].Value * 10) / 10
					):match("(%-?%d?)(%d*)(%.?.*)")
					local units = unitsMillions2
						.. unitsThousands2:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. unitsHundrends2
					local flowMillions, flowThousands, flowHundrends = tostring(
						math.floor(currentCountryData.Resources[frame.Name].Flow.Value * 100) / 100
					):match("(%-?%d?)(%d*)(%.?.*)")
					MainFrame.RightFrame.PageList.Resources.GroupFrame[frame.Name].Amount.Text = units
						.. " Units ["
						.. unitsBefore
						.. flowMillions
						.. flowThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. flowHundrends
						.. "]"
					MainFrame.RightFrame.PageList.Resources.GroupFrame[frame.Name].Amount.TextColor3 =
						frame.National.TextColor3
				end
			end
		end
	end
end)
MainFrame.CenterFrame.EconomyFrame.Main.Resources.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EconomyFrame.Resources.Visible = true
	MainFrame.CenterFrame.EconomyFrame.Main.Visible = false
end)
MainFrame.CenterFrame.EconomyFrame.Resources.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EconomyFrame.Resources.Visible = false
	MainFrame.CenterFrame.EconomyFrame.Resources.TradeFrame.Visible = false
	MainFrame.CenterFrame.EconomyFrame.Resources.ResourceFrame.Visible = true
	MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Visible = false
	MainFrame.CenterFrame.EconomyFrame.Main.Visible = true
	MainFrame.CenterFrame.EconomyFrame.Resources.ResourceName.Visible = false
end)
MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.No.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Visible = false
end)
MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Yes.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Visible = false
	workspace.GameManager.ManageAlliance:FireServer(
		MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Country.Value,
		"ResourceTrade",
		{
			MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Resource.Value,
			MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Action.Value,
			MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Amount.Value,
			MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Price.Value,
			MainFrame.CenterFrame.EconomyFrame.Resources.SalesFrame.Source.Value,
		}
	)
end)
MakeMouseOver(MainFrame.CenterFrame.DiplomacyFrame.Main.Flag, "", 14)
ScaleScrollGui(MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.List, "Y")
for i, button in pairs(MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList:GetChildren()) do
	if button:IsA("TextButton") then
		if button.Name ~= "View" then
			button.MouseButton1Click:Connect(function()
				-- upvalues: (copy) Assets, (copy) GameGui, (copy) v_u_712, (copy) v_u_713, (copy) DiplomacyFrameSelect, (copy) MainFrame, (copy) SetFlag, (ref) currentCountry, (copy) ClearList, (ref) currentCountryData, (copy) MakeMouseOver, (copy) ScaleScrollGui
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				if button.Active then
					DiplomacyFrameSelect(button.Name .. "Frame")
					if MainFrame.CenterFrame.DiplomacyFrame[button.Name .. "Frame"]:FindFirstChild("Flag") then
						SetFlag(MainFrame.CenterFrame.DiplomacyFrame[button.Name .. "Frame"].FlagOwn, currentCountry)
						SetFlag(
							MainFrame.CenterFrame.DiplomacyFrame[button.Name .. "Frame"].Flag,
							MainFrame.CenterFrame.DiplomacyFrame.Country.Value
						)
					end
					if button.Name == "War" then
						ClearList(MainFrame.CenterFrame.DiplomacyFrame.WarFrame.AllyFrame.List)
						ClearList(MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Status.List)
						local diplomacyCountry = MainFrame.CenterFrame.DiplomacyFrame.Country.Value
						if diplomacyCountry ~= nil then
							for i, alliance in
								pairs(workspace.CountryData[diplomacyCountry].Diplomacy.Alliances:GetChildren())
							do
								local flag = MainFrame.CenterFrame.DiplomacyFrame.WarFrame.AllyFrame.List.Flag:Clone()
								SetFlag(flag, alliance.Name)
								flag.Parent = MainFrame.CenterFrame.DiplomacyFrame.WarFrame.AllyFrame
							end
							if
								workspace.Factions:FindFirstChild(
									MainFrame.CenterFrame.DiplomacyFrame.Country.Value,
									true
								)
							then
								for i, faction in
									pairs(
										workspace.Factions
											:FindFirstChild(MainFrame.CenterFrame.DiplomacyFrame.Country.Value, true).Parent
											:GetChildren()
									)
								do
									if faction.Name ~= MainFrame.CenterFrame.DiplomacyFrame.Country.Value then
										local flag =
											MainFrame.CenterFrame.DiplomacyFrame.WarFrame.AllyFrame.List.Flag:Clone()
										SetFlag(flag, faction.Name)
										flag.Parent = MainFrame.CenterFrame.DiplomacyFrame.WarFrame.AllyFrame
									end
								end
							end
							for i, descendant in pairs(currentCountryData.Diplomacy.CasusBelli:GetDescendants()) do
								if descendant.Name == MainFrame.CenterFrame.DiplomacyFrame.Country.Value then
									local button =
										MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Status.List.Sample:Clone()
									button.Text = descendant.Parent.Name
									button.Parent = MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Status
									button.MouseButton1Click:Connect(function()
										-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (copy) v_u_722, (copy) v_u_723
										local clickSound = Assets.Audio.Click_2:Clone()
										clickSound.Parent = GameGui
										clickSound:Play()
										game.Debris:AddItem(clickSound, 15)
										MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Casus.Value =
											descendant.Parent.Name
										MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Explan.Text = descendant.Parent.Name
											.. " Selected"
									end)
								end
							end
							return
						end
					else
						if button.Name == "Justify" then
							ClearList(MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Status.List)
							local warCasusBellis = { "Conquest", "Subjugate", "Liberation" }
							for i, descendant in pairs(currentCountryData.Diplomacy.CasusBelli:GetDescendants()) do
								if descendant.Name == MainFrame.CenterFrame.DiplomacyFrame.Country.Value then
									for i, casusBelli in pairs(warCasusBellis) do
										if casusBelli == descendant.Parent.Name then
											table.remove(warCasusBellis, i)
											break
										end
									end
								end
							end
							for i, casusBelli in pairs(warCasusBellis) do
								local button =
									MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Status.List.Sample:Clone()
								button.Text = casusBelli
								button.Parent = MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Status
								button.MouseButton1Click:Connect(function()
									-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (copy) warCasusBellis, (copy) v_u_730, (ref) currentCountryData
									local clickSound = Assets.Audio.Click_2:Clone()
									clickSound.Parent = GameGui
									clickSound:Play()
									game.Debris:AddItem(clickSound, 15)
									MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Casus.Value = casusBelli
									MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Explan.Text = casusBelli
										.. " Selected. This will take "
										.. require(workspace.FunctionDump.DiplomacyStatus).JustifyTime(
											currentCountryData.Name,
											MainFrame.CenterFrame.DiplomacyFrame.Country.Value,
											casusBelli
										)
										.. " days to justify"
								end)
							end
							return
						end
						if button.Name == "Aid" then
							local aidTypes = { "Money", "Manpower" }
							for i, aidType in pairs(aidTypes) do
								MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType]:SetAttribute("Mode", "One Time")
								MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Input.Text = 0
								MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Desc.Text = aidType
									.. ": One Time"
								MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Ongoing.Visible = false
								local monthlyAid = currentCountryData.Aid:FindFirstChild(
									MainFrame.CenterFrame.DiplomacyFrame.Country.Value
								)
								if monthlyAid then
									if monthlyAid:GetAttribute(aidType) then
										local millions, thousands, hundrends =
											tostring((monthlyAid:GetAttribute(aidType))):match("(%-?%d?)(%d*)(%.?.*)")
										MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Ongoing.Desc.Text = "We are currently sending "
											.. millions
											.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
											.. hundrends
											.. " "
											.. aidType
											.. " monthly"
										MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Ongoing.Visible = true
									end
								end
							end
							return
						end
						if button.Name == "Rebel" then
							local millions, thousands, hundrends = tostring(
								(
									math.clamp(
										workspace.CountryData[MainFrame.CenterFrame.DiplomacyFrame.Country.Value].Population.Value,
										350000000,
										math.huge
									)
								)
							):match("(%-?%d?)(%d*)(%.?.*)")
							MainFrame.CenterFrame.DiplomacyFrame.RebelFrame.Desc.Text = "Provide funding to separatist rebels within "
								.. MainFrame.CenterFrame.DiplomacyFrame.Country.Value
								.. " for 12 months at a cost of $"
								.. millions
								.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
								.. hundrends
							return
						end
						if button.Name == "ViewTrade" then
							ClearList(MainFrame.CenterFrame.DiplomacyFrame.ViewTradeFrame.Status.List)
							MainFrame.CenterFrame.DiplomacyFrame.ViewTradeFrame.Title.Text = MainFrame.CenterFrame.DiplomacyFrame.Country.Value
								.. " Trades"
							local v742 =
								workspace.CountryData[MainFrame.CenterFrame.DiplomacyFrame.Country.Value].Resources:GetChildren()
							for i, resource in
								pairs(
									workspace.CountryData[MainFrame.CenterFrame.DiplomacyFrame.Country.Value].Resources:GetChildren()
								)
							do
								for i, trade in pairs(resource.Trade:GetChildren()) do
									local tradeTypeText = "Buying "
									local text = tradeTypeText .. "from "
									if trade.Value.X < 0 then
										tradeTypeText = "Selling  "
										text = tradeTypeText .. "to "
									end
									local frame =
										MainFrame.CenterFrame.DiplomacyFrame.ViewTradeFrame.Status.List.Sample:Clone()
									frame.Name = trade.Name .. " " .. resource.Name
									SetFlag(frame.Flag, trade.Name)
									frame.Label.Text = tradeTypeText
										.. math.ceil(math.abs(trade.Value.X) * 100) / 100
										.. " Units of "
										.. resource.Name
										.. " at "
										.. math.ceil(math.abs(trade.Value.Y) * 100) / 100
										.. "x Value"
									frame.Parent = MainFrame.CenterFrame.DiplomacyFrame.ViewTradeFrame.Status
									MakeMouseOver(frame, text .. trade.Name, 14)
								end
							end
							ScaleScrollGui(MainFrame.CenterFrame.DiplomacyFrame.ViewTradeFrame.Status.List, "Y")
						end
					end
				end
			end)
		end
	end
end
local tradeSearchBox = MainFrame.CenterFrame.DiplomacyFrame.ViewTradeFrame.SearchSample.Box
local tradeStatus = MainFrame.CenterFrame.DiplomacyFrame.ViewTradeFrame.Status
tradeSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) tradeStatus, (copy) tradeSearchBox
	for i, v in pairs(tradeStatus:GetChildren()) do
		if v:IsA("GuiBase") then
			if v ~= tradeSearchBox.Parent then
				if string.match(string.lower(v.Name), string.lower(tradeSearchBox.Text)) == nil then
					v.Visible = false
				else
					v.Visible = true
				end
			end
		end
	end
end)
MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.View.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) tags
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	local cities = workspace.Baseplate.Cities[MainFrame.CenterFrame.DiplomacyFrame.Country.Value]:GetChildren()
	if 0 < #cities then
		for i = 1, #cities do
			local ownershipTag = script.OwnershipTag:Clone()
			ownershipTag.Adornee = cities[i]
			ownershipTag.Img.ImageColor3 = Color3.new(1, 1, 1)
			ownershipTag.Parent = cities[i]
			table.insert(tags, ownershipTag)
		end
	end
end)
local releaseSearchBox = MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.SearchSample.Box
local releaseStatus = MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Status
releaseSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) releaseStatus, (copy) releaseSearchBox
	for i, v in pairs(releaseStatus:GetChildren()) do
		if v:IsA("GuiBase") then
			if v ~= releaseSearchBox.Parent then
				if string.match(string.lower(v.Name), string.lower(releaseSearchBox.Text)) == nil then
					v.Visible = false
				else
					v.Visible = true
				end
			end
		end
	end
end)
MainFrame.CenterFrame.DiplomacyFrame.Main.Release.MouseButton1Click:Connect(function()
	-- upvalues: (copy) DiplomacyFrameSelect, (copy) ClearList, (copy) MainFrame, (ref) currentCountry, (copy) SetFlag, (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected, (copy) ScaleScrollGui
	DiplomacyFrameSelect("ReleaseFrame")
	ClearList(MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Status.List)
	for country, cities in pairs(require(workspace.FunctionDump.ValueCalc.GetCities).Composition(currentCountry, true)) do
		if country ~= currentCountry then
			if not MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Status:FindFirstChild(country) then
				local frame = MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Status.List.Sample:Clone()
				frame.Name = country
				frame.CName.Text = country
				SetFlag(frame.Flag, country)
				local citiesPopulation = 0
				local citiesCount = 0
				for i, city in pairs(cities) do
					citiesPopulation = citiesPopulation + city.Population.Value.X
					citiesCount = citiesCount + 1
				end
				local popMillions, popThousands, popHundrends = tostring(citiesPopulation):match("(%-?%d?)(%d*)(%.?.*)")
				local popText = popMillions .. popThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse() .. popHundrends
				local countMillions, countThousands, countHundrends =
					tostring(citiesCount):match("(%-?%d?)(%d*)(%.?.*)")
				frame.CStat.Text = "Population: "
					.. popText
					.. "  |  Cities: "
					.. countMillions
					.. countThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. countHundrends
				frame.Parent = MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Status
				frame.Release.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					if frame.ReleasePuppet.Confirm.Visible then
						frame.ReleasePuppet.Confirm.Visible = false
						frame.Release.Confirm.Visible = true
					else
						frame.Release.Confirm.Visible = not frame.Release.Confirm.Visible
					end
				end)
				if
					not workspace.Baseplate.Cities:FindFirstChild(country) and true
					or #workspace.Baseplate.Cities[country]:GetChildren() == 0 and true
					or false
				then
					frame.ReleasePuppet.Visible = true
					frame.ReleasePuppet.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						if frame.Release.Confirm.Visible then
							frame.Release.Confirm.Visible = false
							frame.ReleasePuppet.Confirm.Visible = true
						else
							frame.ReleasePuppet.Confirm.Visible = not frame.ReleasePuppet.Confirm.Visible
						end
					end)
				end
				frame.Select.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) mouseInteractionType, (copy) cities, (ref) selected
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					Disengage()
					mouseInteractionType = "SelectCity"
					for i, city in pairs(cities) do
						table.insert(selected, city)
					end
				end)
			end
		end
	end
	ScaleScrollGui(MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Status.List, "Y")
end)
MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	for i, v in pairs(MainFrame.CenterFrame.DiplomacyFrame.ReleaseFrame.Status:GetChildren()) do
		if v:IsA("Frame") then
			local isPuppet = v.ReleasePuppet.Confirm.Visible and "Puppet" or nil
			if v.Release.Confirm.Visible or v.ReleasePuppet.Confirm.Visible then
				workspace.CountryManager.ReleaseCountry:FireServer(v.Name, isPuppet)
			end
		end
	end
	Disengage()
end)
MainFrame.CenterFrame.DiplomacyFrame.Main.PastLeader.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) DiplomacyFrameSelect, (copy) MainFrame, (copy) ClearList, (copy) ScaleScrollGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	DiplomacyFrameSelect("PastLeaderFrame")
	MainFrame.CenterFrame.DiplomacyFrame.PastLeaderFrame.Title.Text = MainFrame.CenterFrame.DiplomacyFrame.Country.Value
		.. "'s Past Leaders"
	ClearList(MainFrame.CenterFrame.DiplomacyFrame.PastLeaderFrame.Status.List)
	for i, leader in
		pairs(workspace.CountryData[MainFrame.CenterFrame.DiplomacyFrame.Country.Value].Leader:GetChildren())
	do
		local frame = MainFrame.CenterFrame.DiplomacyFrame.PastLeaderFrame.Status.List.Sample:Clone()
		frame.Name = leader.Name
		frame.LName.Text = leader.Name
		frame.LDate.Text = leader:GetAttribute("Start")
			.. "           -----           "
			.. (not leader:GetAttribute("End") and "" or leader:GetAttribute("End"))
		frame.LayoutOrder = i
		frame.Parent = MainFrame.CenterFrame.DiplomacyFrame.PastLeaderFrame.Status
	end
	ScaleScrollGui(MainFrame.CenterFrame.DiplomacyFrame.PastLeaderFrame.Status.List, "Y")
end)
for i, v in pairs(MainFrame.CenterFrame.DiplomacyFrame:GetChildren()) do
	if v:FindFirstChild("Back") then
		v.Back.MouseButton1Click:Connect(function()
			-- upvalues: (copy) Assets, (copy) GameGui, (copy) DiplomacyFrameSelect
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			DiplomacyFrameSelect("Main")
		end)
	end
end
MainFrame.CenterFrame.DiplomacyFrame.Main.Own.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) currentCountry
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.DiplomacyFrame.Country.Value = currentCountry
end)
MainFrame.CenterFrame.DiplomacyFrame.AllianceFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountryData, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if currentCountryData.Diplomacy.Alliances:FindFirstChild(MainFrame.CenterFrame.DiplomacyFrame.Country.Value) then
		workspace.GameManager.ManageAlliance:FireServer(MainFrame.CenterFrame.DiplomacyFrame.Country.Value, "Break")
	else
		workspace.GameManager.ManageAlliance:FireServer(
			MainFrame.CenterFrame.DiplomacyFrame.Country.Value,
			"SendRequest"
		)
	end
	Disengage()
end)
MainFrame.CenterFrame.DiplomacyFrame.PuppetFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountryData, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if
		not currentCountryData.Diplomacy.Alliances:FindFirstChild(MainFrame.CenterFrame.DiplomacyFrame.Country.Value)
	then
		workspace.GameManager.ManageAlliance:FireServer(
			MainFrame.CenterFrame.DiplomacyFrame.Country.Value,
			"SendRequest",
			"PuppetRequest"
		)
	end
	Disengage()
end)
MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Casus.Value ~= "" then
		workspace.GameManager.ManageAlliance:FireServer(
			MainFrame.CenterFrame.DiplomacyFrame.Country.Value,
			"WarDeclare",
			MainFrame.CenterFrame.DiplomacyFrame.WarFrame.Casus.Value
		)
		Disengage()
	end
end)
MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Casus.Value ~= "" then
		workspace.GameManager.JustifyWar:FireServer(
			MainFrame.CenterFrame.DiplomacyFrame.Country.Value,
			MainFrame.CenterFrame.DiplomacyFrame.JustifyFrame.Casus.Value
		)
		Disengage()
	end
end)
local aidTypes = { "Money", "Manpower" }
for i, aidType in pairs(aidTypes) do
	MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].K.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) aidTypes, (copy) v_u_795
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		if tonumber(MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Input.Text) then
			local input = MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Input
			input.Text = input.Text * 1000
		end
	end)
	MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].M.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) aidTypes, (copy) v_u_795
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		if tonumber(MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Input.Text) then
			local input = MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Input
			input.Text = input.Text * 1000000
		end
	end)
	MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].B.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) aidTypes, (copy) v_u_795
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		if tonumber(MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Input.Text) then
			local input = MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Input
			input.Text = input.Text * 1000000000
		end
	end)
	MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].OneTime.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) aidTypes, (copy) v_u_795
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType]:SetAttribute("Mode", "One Time")
		MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Desc.Text = aidType .. ": " .. "One Time"
	end)
	MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Monthly.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) aidTypes, (copy) v_u_795
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType]:SetAttribute("Mode", "Monthly")
		MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Desc.Text = aidType .. ": " .. "Monthly"
	end)
	MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Ongoing.Cancel.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) aidTypes, (copy) v_u_795
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		MainFrame.CenterFrame.DiplomacyFrame.AidFrame[aidType].Ongoing.Visible = false
		workspace.GameManager.ManageAlliance:FireServer(
			MainFrame.CenterFrame.DiplomacyFrame.Country.Value,
			"CancelAid",
			{ aidType }
		)
	end)
end
MainFrame.CenterFrame.DiplomacyFrame.AidFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.ManageAlliance:FireServer(MainFrame.CenterFrame.DiplomacyFrame.Country.Value, "Aid", {
		{
			tonumber(MainFrame.CenterFrame.DiplomacyFrame.AidFrame.Money.Input.Text),
			MainFrame.CenterFrame.DiplomacyFrame.AidFrame.Money:GetAttribute("Mode"),
		},
		{
			tonumber(MainFrame.CenterFrame.DiplomacyFrame.AidFrame.Manpower.Input.Text),
			MainFrame.CenterFrame.DiplomacyFrame.AidFrame.Manpower:GetAttribute("Mode"),
		},
	})
	Disengage()
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) SetFlag, (copy) Assets, (copy) GameGui
	if MainFrame.RightFrame.PageList.Aid.Visible then
		local aidingCountries = {}
		local allAid = {}
		for i, aid in pairs(currentCountryData.Aid:GetChildren()) do
			table.insert(aidingCountries, aid.Name)
			table.insert(allAid, aid)
		end
		for i, v in pairs(MainFrame.RightFrame.PageList.Aid.GroupFrame:GetChildren()) do
			if not table.find(aidingCountries, v.Name) then
				if v.Name ~= "List" then
					v:Destroy()
				end
			end
		end
		for i = 1, #allAid do
			local amountText = "Sending "
			if allAid[i]:GetAttribute("Money") then
				local moneyMillions, moneyThousands, moneyHundrends =
					tostring((allAid[i]:GetAttribute("Money"))):match("(%-?%d?)(%d*)(%.?.*)")
				amountText = amountText
					.. "$"
					.. moneyMillions
					.. moneyThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. moneyHundrends
			end
			if allAid[i]:GetAttribute("Money") then
				if allAid[i]:GetAttribute("Manpower") then
					amountText = amountText .. " and "
				end
			end
			if allAid[i]:GetAttribute("Manpower") then
				local manpowerMillions, manpowerThousands, manpowerHundrends =
					tostring((allAid[i]:GetAttribute("Manpower"))):match("(%-?%d?)(%d*)(%.?.*)")
				amountText = amountText
					.. manpowerMillions
					.. manpowerThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. manpowerHundrends
					.. " Manpower"
			end
			local text = amountText
				.. " Monthly: "
				.. require(workspace.FunctionDump.SharedFunction).FutureDate(
					allAid[i].Timer.Value.Z - allAid[i].Timer.Value.X
				)
			if MainFrame.RightFrame.PageList.Aid.GroupFrame:FindFirstChild(aidingCountries[i]) then
				MainFrame.RightFrame.PageList.Aid.GroupFrame[aidingCountries[i]].Label.Text = text
			else
				local frame = MainFrame.RightFrame.PageList.Aid.GroupFrame.List.Sample:Clone()
				frame.Name = aidingCountries[i]
				SetFlag(frame.Flag, allAid[i].Name)
				frame.Label.Text = text
				frame.Parent = MainFrame.RightFrame.PageList.Aid.GroupFrame
				frame.Cancel.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (copy) allAid, (copy) i
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					workspace.GameManager.ManageAlliance:FireServer(
						allAid[i].Name,
						"CancelAid",
						{ "Money", "Manpower" }
					)
				end)
			end
		end
		MainFrame.RightFrame.PageList.Aid.GroupFrame.CanvasSize =
			UDim2.new(0, 0, 0, MainFrame.RightFrame.PageList.Trade.GroupFrame.List.AbsoluteContentSize.Y * 1.1)
	end
end)
MainFrame.CenterFrame.DiplomacyFrame.RebelFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountryData, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if
		currentCountryData.Economy.Balance.Value
		> math.clamp(
			workspace.CountryData[MainFrame.CenterFrame.DiplomacyFrame.Country.Value].Population.Value,
			350000000,
			math.huge
		)
	then
		workspace.GameManager.ManageAlliance:FireServer(MainFrame.CenterFrame.DiplomacyFrame.Country.Value, "RebelAid")
		Disengage()
	end
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (copy) SetFlag, (ref) currentCountry, (ref) currentCountryData, (copy) MakeMouseOver, (copy) Assets, (copy) GameGui
	if MainFrame.CenterFrame.DiplomacyFrame.Visible and MainFrame.CenterFrame.Visible then
		local diplomacyCountry = MainFrame.CenterFrame.DiplomacyFrame.Country.Value
		MainFrame.CenterFrame.DiplomacyFrame.Main.CountryName.Text = diplomacyCountry
		SetFlag(MainFrame.CenterFrame.DiplomacyFrame.Main.Flag, diplomacyCountry)
		if workspace.CountryData[diplomacyCountry].Ranking.Value <= 3 then
			MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.BorderColor3 = Color3.fromRGB(255, 208, 89)
			MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.BorderSizePixel = 4
		elseif
			3 < workspace.CountryData[diplomacyCountry].Ranking.Value
			and workspace.CountryData[diplomacyCountry].Ranking.Value <= 20
		then
			MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.BorderColor3 = Color3.fromRGB(255, 255, 255)
			MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.BorderSizePixel = 3
		else
			MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.BorderSizePixel = 0
		end
		MainFrame.CenterFrame.DiplomacyFrame.Main.RulerName.Text = "Ruler: "
			.. workspace.CountryData[diplomacyCountry].Leader.Value
		MainFrame.CenterFrame.DiplomacyFrame.Main.Ideology.Text =
			workspace.CountryData[diplomacyCountry].Laws.Ideology.Value
		MainFrame.CenterFrame.DiplomacyFrame.Main.FactionName.Text = ""
		if game.Players:FindFirstChild(workspace.CountryData[diplomacyCountry].Leader.Value) then
			MainFrame.CenterFrame.DiplomacyFrame.Main.Profile.Visible = true
			coroutine.resume(coroutine.create(function()
				-- upvalues: (ref) MainFrame, (copy) diplomacyCountry
				MainFrame.CenterFrame.DiplomacyFrame.Main.Profile.Image = game.Players:GetUserThumbnailAsync(
					game.Players[workspace.CountryData[diplomacyCountry].Leader.Value].userId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size180x180
				)
			end))
		else
			MainFrame.CenterFrame.DiplomacyFrame.Main.Profile.Visible = false
		end
		if workspace.Factions:FindFirstChild(diplomacyCountry, true) then
			MainFrame.CenterFrame.DiplomacyFrame.Main.FactionName.Text = "Faction: "
				.. workspace.Factions:FindFirstChild(diplomacyCountry, true).Parent.Parent.Name
			if workspace.Factions:FindFirstChild(diplomacyCountry, true).Value == "Leader" then
				MainFrame.CenterFrame.DiplomacyFrame.Main.FactionName.Text = MainFrame.CenterFrame.DiplomacyFrame.Main.FactionName.Text
					.. " [Leader]"
			end
		end
		if diplomacyCountry == currentCountry then
			MainFrame.CenterFrame.DiplomacyFrame.Main.CountryList.Visible = true
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Visible = false
			MainFrame.CenterFrame.DiplomacyFrame.Main.Release.Visible = true
		else
			MainFrame.CenterFrame.DiplomacyFrame.Main.CountryList.Visible = false
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Visible = true
			MainFrame.CenterFrame.DiplomacyFrame.Main.Release.Visible = false
		end
		MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Active = true
		MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Text = "Declare War"
		if
			require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
				currentCountryData.Name,
				diplomacyCountry,
				"Against"
			)
		then
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Active = false
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Text = "Already At War"
		elseif
			require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
				currentCountryData.Name,
				diplomacyCountry,
				"Together"
			)
		then
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Active = false
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Text = "In War together"
		elseif currentCountryData.Diplomacy.Truces:FindFirstChild(diplomacyCountry) then
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Active = false
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Text = "In a truce"
		elseif currentCountryData.Diplomacy.Alliances:FindFirstChild(diplomacyCountry) then
			if currentCountryData.Diplomacy.Alliances[diplomacyCountry].Value == "Alliance" then
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Active = false
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Text = "Allied"
			elseif currentCountryData.Diplomacy.Alliances[diplomacyCountry].Value == "Puppet" then
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Active = false
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Text = "Puppeted"
			end
			if
				workspace.Factions:FindFirstChild(diplomacyCountry, true)
				or workspace.Factions:FindFirstChild(currentCountry, true)
			then
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Active = false
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.War.Text = "In a faction"
			end
		end
		if require(workspace.FunctionDump.DiplomacyStatus).GetPuppet(diplomacyCountry) then
			local puppetOwner = require(workspace.FunctionDump.DiplomacyStatus).GetPuppet(diplomacyCountry)
			MainFrame.CenterFrame.DiplomacyFrame.Main.Subject.Text = "Subject of " .. puppetOwner
			MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.Master.Visible = true
			SetFlag(MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.Master, puppetOwner)
		else
			MainFrame.CenterFrame.DiplomacyFrame.Main.Subject.Text = ""
			MainFrame.CenterFrame.DiplomacyFrame.Main.Flag.Master.Visible = false
		end
		MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Puppet.Text = "Make puppet state"
		MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Puppet.Active = true
		MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Alliance.Active = true
		if currentCountryData.Diplomacy.Alliances:FindFirstChild(diplomacyCountry) then
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Alliance.Text = "Break Ties"
			MainFrame.CenterFrame.DiplomacyFrame.AllianceFrame.Desc.Text = "Break off all diplomatic relations"
			MainFrame.CenterFrame.DiplomacyFrame.AllianceFrame.Title.Text = "Break ties"
		else
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Alliance.Text = "Form Alliance"
			MainFrame.CenterFrame.DiplomacyFrame.AllianceFrame.Title.Text = "Form Alliance"
			MainFrame.CenterFrame.DiplomacyFrame.AllianceFrame.Desc.Text = "Form a military Alliance"
			if
				workspace.Wars:FindFirstChild(currentCountry, true)
				or workspace.Wars:FindFirstChild(diplomacyCountry, true)
			then
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Puppet.Text = "In a War"
				MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Puppet.Active = false
			end
		end
		if
			workspace.Factions:FindFirstChild(diplomacyCountry, true)
			or workspace.Factions:FindFirstChild(currentCountry, true)
		then
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Alliance.Active = false
			MainFrame.CenterFrame.DiplomacyFrame.Main.ActionList.Alliance.Text = "In a faction"
		end
		local countryPop = 0
		for i, v in pairs(workspace.Baseplate.Cities[diplomacyCountry]:GetChildren()) do
			countryPop = countryPop + v.Population.Value.X
		end
		local popMillions, popThousands, popHundrends = tostring(countryPop):match("(%-?%d?)(%d*)(%.?.*)")
		MainFrame.CenterFrame.DiplomacyFrame.Main.Population.Text = "Population: "
			.. popMillions
			.. popThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. popHundrends
		local function FlagList(frame, Table, Type)
			-- upvalues: (ref) MainFrame, (ref) SetFlag, (ref) MakeMouseOver, (ref) Assets, (ref) GameGui
			for i, v in pairs(frame:GetChildren()) do
				if v.Name ~= "List" then
					local name = v.Name
					local found = false
					for i, v in pairs(Table) do
						if v.Name == name then
							found = true
							break
						end
					end
					if not found then
						v:Destroy()
					end
				end
			end
			for i, v in pairs(Table) do
				if not frame:FindFirstChild(v.Name) then
					local flag = MainFrame.CenterFrame.DiplomacyFrame.Main.Status.List.Flag:Clone()
					SetFlag(flag, v.Name)
					flag.Name = v.Name
					flag.Parent = frame
					if frame == MainFrame.CenterFrame.DiplomacyFrame.Main.Status.Truces.ListFrame then
						MakeMouseOver(
							flag,
							flag.Name
								.. "\nExpires: "
								.. require(workspace.FunctionDump.SharedFunction).FutureDate(v.Value.Z - v.Value.X),
							16
						)
					elseif Type == "War" then
						MakeMouseOver(flag, v.Parent.Parent.Name, 16)
					else
						MakeMouseOver(flag, flag.Name, 16)
					end
					flag.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (copy) flag
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						MainFrame.CenterFrame.DiplomacyFrame.Country.Value = flag.Name
					end)
				end
			end
		end
		local allies = {}
		for i, alliance in pairs(workspace.CountryData[diplomacyCountry].Diplomacy.Alliances:GetChildren()) do
			if alliance.Value == "Alliance" then
				table.insert(allies, alliance)
			end
		end
		FlagList(MainFrame.CenterFrame.DiplomacyFrame.Main.Status.Allies.ListFrame, allies)
		local wars = {}
		for i, war in pairs(workspace.Wars:GetChildren()) do
			local warFound = war:FindFirstChild(diplomacyCountry, true)
			if warFound then
				for i, descendant in pairs(war:GetDescendants()) do
					if descendant:IsA("StringValue") then
						if descendant.Value == "WarLeader" then
							if descendant.Parent.Name ~= warFound.Parent.Name then
								table.insert(wars, descendant)
								break
							end
						end
					end
				end
			end
		end
		FlagList(MainFrame.CenterFrame.DiplomacyFrame.Main.Status.Wars.ListFrame, wars, "War")
		local puppets = {}
		for i, alliance in pairs(workspace.CountryData[diplomacyCountry].Diplomacy.Alliances:GetChildren()) do
			if alliance.Value == "Puppet" then
				table.insert(puppets, alliance)
			end
		end
		FlagList(MainFrame.CenterFrame.DiplomacyFrame.Main.Status.Subjects.ListFrame, puppets)
		FlagList(
			MainFrame.CenterFrame.DiplomacyFrame.Main.Status.Truces.ListFrame,
			workspace.CountryData[diplomacyCountry].Diplomacy.Truces:GetChildren()
		)
	end
end)
function ModifierEffectText(modifierName, p857)
	-- upvalues: (copy) Assets, (copy) ReferenceTable
	local text = ""
	for i, effect in pairs(Assets.Laws.Modifiers[modifierName].Effects:GetChildren()) do
		if effect:IsA("NumberValue") and not effect:GetAttribute("Base") then
			text = text
				.. p857
				.. effect.Name
				.. ": "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. (effect.Value < 0 and "" or "+")
				.. math.ceil(effect.Value * 100 * 100) / 100
				.. "%"
				.. "</font>"
				.. "\n"
		elseif effect:IsA("IntValue") or effect:GetAttribute("Base") then
			text = text
				.. p857
				.. effect.Name
				.. ": "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. (effect.Value < 0 and "" or "+")
				.. math.ceil(effect.Value * 100000) / 100000
				.. "</font>"
				.. "\n"
		end
	end
	return text
end
for i, conscription in pairs(Assets.Laws.Conscription:GetChildren()) do
	MainFrame.CenterFrame.CountryFrame.Main.ConscriptionFrame.ButtonFrame[conscription.Name].MouseButton1Click:Connect(
		function()
			-- upvalues: (copy) Assets, (copy) GameGui
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			workspace.GameManager.ChangeLaw:FireServer("Conscription", tonumber(conscription.Name))
		end
	)
	MakeMouseOver(MainFrame.CenterFrame.CountryFrame.Main.ConscriptionFrame.ButtonFrame[conscription.Name], "", 14)
end
for i, ideology in pairs(Assets.Laws.Ideology:GetChildren()) do
	MainFrame.CenterFrame.CountryFrame.Ideologies[ideology.Name].MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		workspace.GameManager.ChangeLaw:FireServer("Ideology", ideology.Name)
	end)
	MakeMouseOver(MainFrame.CenterFrame.CountryFrame.Ideologies[ideology.Name], "", 14)
end
MainFrame.CenterFrame.CountryFrame.Main.Ideology.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Ideologies.Visible = true
	MainFrame.CenterFrame.CountryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.CountryFrame.Ideologies.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Ideologies.Visible = false
	MainFrame.CenterFrame.CountryFrame.Main.Visible = true
end)
MainFrame.CenterFrame.CountryFrame.Main.Modifier.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Modifier.Visible = true
	MainFrame.CenterFrame.CountryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.CountryFrame.Modifier.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Modifier.Visible = false
	MainFrame.CenterFrame.CountryFrame.Main.Visible = true
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) Assets, (copy) MakeMouseOver, (copy) ScaleScrollGui
	if MainFrame.CenterFrame.CountryFrame.Modifier.Visible then
		local v871 = MainFrame.CenterFrame.CountryFrame.Modifier.ListFrame:GetChildren()
		for v872 = 1, #v871 do
			if not currentCountryData.Laws.Modifiers:FindFirstChild(v871[v872].Name) then
				if v871[v872].Name ~= "List" then
					v871[v872]:Destroy()
				end
			end
		end
		local v873 = currentCountryData.Laws.Modifiers:GetChildren()
		for v874 = 1, #v873 do
			if MainFrame.CenterFrame.CountryFrame.Modifier.ListFrame:FindFirstChild(v873[v874].Name) then
				if v873[v874].Value == -1 then
					MainFrame.CenterFrame.CountryFrame.Modifier.ListFrame[v873[v874].Name].Expire.Text = ""
				else
					MainFrame.CenterFrame.CountryFrame.Modifier.ListFrame[v873[v874].Name].Expire.Text = "Expires: "
						.. require(workspace.FunctionDump.SharedFunction).FutureDate(v873[v874].Value)
				end
			else
				local v875 = MainFrame.CenterFrame.CountryFrame.Modifier.ListFrame.List.Sample:Clone()
				v875.Name = v873[v874].Name
				v875.Label.Text = v873[v874].Name
				v875.Description.Text = Assets.Laws.Modifiers[v873[v874].Name].Value
				if Assets.Laws.Modifiers[v873[v874].Name]:FindFirstChild("Icon") then
					v875.Icon.Image = Assets.Laws.Modifiers[v873[v874].Name].Icon.Texture
					v875.Icon.ImageColor3 = Assets.Laws.Modifiers[v873[v874].Name].Icon.Color3
				end
				v875.Parent = MainFrame.CenterFrame.CountryFrame.Modifier.ListFrame
				MakeMouseOver(v875, "Modifiers:\n" .. ModifierEffectText(v873[v874].Name, " -"), 14)
			end
		end
		ScaleScrollGui(MainFrame.CenterFrame.CountryFrame.Modifier.ListFrame.List, "Y")
	end
end)
MainFrame.CenterFrame.CountryFrame.Main.Policies.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ScaleScrollGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ScaleScrollGui(MainFrame.CenterFrame.CountryFrame.Policies.ListFrame.List, "Y")
	MainFrame.CenterFrame.CountryFrame.Policies.Visible = true
	MainFrame.CenterFrame.CountryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.CountryFrame.Policies.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Policies.Visible = false
	MainFrame.CenterFrame.CountryFrame.Main.Visible = true
end)
for i, policy in pairs(Assets.Laws.Policies:GetChildren()) do
	local button = MainFrame.CenterFrame.CountryFrame.Policies.ListFrame.List.Sample:Clone()
	button.Name = policy.Name
	button.Label.Text = policy.Name
	button.Description.Text = policy.Value
	button.Parent = MainFrame.CenterFrame.CountryFrame.Policies.ListFrame
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) v_u_878, (copy) v_u_879
		local clickSound = Assets.Audio.Click:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		workspace.GameManager.ChangeLaw:FireServer("Policy", policy.Name)
	end)
	local text = "Effects:\n"
	for i, effect in pairs(policy.Effects:GetChildren()) do
		if effect:IsA("NumberValue") then
			text = text
				.. effect.Name
				.. ": "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. (effect.Value < 0 and "" or "+")
				.. math.ceil(effect.Value * 100 * 100) / 100
				.. "%\n"
				.. "</font>"
		elseif effect:IsA("IntValue") then
			text = text
				.. effect.Name
				.. ": "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. (effect.Value < 0 and "" or "+")
				.. math.ceil(effect.Value * 100000) / 100000
				.. "\n"
				.. "</font>"
		end
	end
	if policy:FindFirstChild("Requirements") then
		text = text .. "\nRequirements\n"
		for i, requirement in pairs(policy.Requirements:GetChildren()) do
			if requirement.Name == "Ideology" then
				text = text
					.. "Ideology: "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. requirement.Value
					.. "</font>"
					.. "\n"
			elseif requirement.Name == "NOTIdeology" then
				text = text
					.. "Ideology: NOT "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. requirement.Value
					.. "</font>"
					.. "\n"
			elseif requirement.Name == "Policy" then
				text = text
					.. "Policy: "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. requirement.Value
					.. "</font>"
					.. "\n"
			elseif requirement.Name == "NOTPolicy" then
				text = text
					.. "Does not have Policy: "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. requirement.Value
					.. "</font>"
					.. "\n"
			elseif requirement.Name == "War" then
				if requirement.Value then
					text = text .. "Must be at war\n"
				else
					text = text .. "Must not be at war\n"
				end
			elseif requirement.Name == "Stability" then
				text = text
					.. "Stability greater than "
					.. math.ceil(requirement.Value.X * 10) / 10
					.. "% and less than "
					.. math.ceil(requirement.Value.Z * 10) / 10
					.. "%\n"
			end
		end
	end
	MakeMouseOver(
		button,
		text
			.. "\n"
			.. '<font color="rgb('
			.. ReferenceTable.Colors.Gold[1]
			.. ')">'
			.. math.ceil(policy.PPCost.Value.X * 10) / 10
			.. "</font>"
			.. " Political Power to implement\n"
			.. '<font color="rgb('
			.. ReferenceTable.Colors.Gold[1]
			.. ')">'
			.. math.ceil(policy.PPCost.Value.Y * 100) / 100
			.. "</font>"
			.. " Political Power Maintenance",
		14
	)
end
MainFrame.CenterFrame.CountryFrame.Main.Ranking.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ClearList, (copy) MainFrame, (copy) SetFlag, (copy) MakeMouseOver, (ref) currentCountry, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ClearList(MainFrame.CenterFrame.CountryFrame.Ranking.GraphFrame.List)
	local countries = {}
	for i, country in pairs(workspace.CountryData:GetChildren()) do
		if country.Population.Value ~= 0 then
			table.insert(countries, country)
		end
	end
	table.sort(countries, function(a, b)
		return require(workspace.FunctionDump.ValueCalc.GetPower)(a.Name)
			> require(workspace.FunctionDump.ValueCalc.GetPower)(b.Name)
	end)
	for i, country in pairs(countries) do
		local frame = MainFrame.CenterFrame.CountryFrame.Ranking.GraphFrame.List.Sample:Clone()
		frame.Name = country.Name
		frame.LayoutOrder = i
		SetFlag(frame.Flag, country.Name)
		MakeMouseOver(frame.Flag, country.Name, 16)
		frame.Graph.Size = UDim2.new(
			0.8,
			0,
			require(workspace.FunctionDump.ValueCalc.GetPower)(country.Name)
				/ require(workspace.FunctionDump.ValueCalc.GetPower)(countries[1].Name)
				* 0.8,
			0
		)
		frame.Graph.Rank.Text = i
		if country.Name == currentCountry then
			frame.Graph.Rank.TextColor3 = Color3.fromRGB(255, 208, 89)
		end
		if i <= 3 then
			frame.Graph.BackgroundColor3 = Color3.fromRGB(255, 208, 89)
		elseif 3 < i and i <= 20 then
			frame.Graph.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		else
			frame.Graph.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end
		frame.Flag.MouseButton1Click:Connect(function()
			-- upvalues: (ref) Assets, (ref) GameGui, (ref) CenterFrameSelect, (ref) MainFrame, (copy) countries, (copy) i
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			CenterFrameSelect("DiplomacyFrame")
			MainFrame.CenterFrame.DiplomacyFrame.Country.Value = country.Name
		end)
		frame.Parent = MainFrame.CenterFrame.CountryFrame.Ranking.GraphFrame
	end
	MainFrame.CenterFrame.CountryFrame.Ranking.GraphFrame.CanvasSize =
		UDim2.new(0, MainFrame.CenterFrame.CountryFrame.Ranking.GraphFrame.List.AbsoluteContentSize.X * 1.1, 0, 0)
	MainFrame.CenterFrame.CountryFrame.Ranking.Visible = true
	MainFrame.CenterFrame.CountryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.CountryFrame.Ranking.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Ranking.Visible = false
	MainFrame.CenterFrame.CountryFrame.Main.Visible = true
end)
local v898 = Assets.Laws.Factions.Second:GetChildren()
for i, v in pairs(Assets.Laws.Factions.First:GetChildren()) do
	local button = MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.List.List.Sample:Clone()
	button.Name = v.Name
	button.Text = v.Name
	button.Parent = MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.List
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) button
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.List.Visible = false
		MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.Text = button.Name
	end)
end
for i, v in pairs(Assets.Laws.Factions.Second:GetChildren()) do
	local button = MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.List.List.Sample:Clone()
	button.Name = v.Name
	button.Text = v.Name
	button.Parent = MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name2.List
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) button
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name2.List.Visible = false
		MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name2.Text = button.Name
	end)
end
MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ScaleScrollGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ScaleScrollGui(MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.List.List, "Y")
	MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.List.Visible = true
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name2.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ScaleScrollGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ScaleScrollGui(MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name2.List.List, "Y")
	MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name2.List.Visible = true
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Create.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountry, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.ManageAlliance:FireServer(currentCountry, "FactionCreate", {
		MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name1.Text,
		MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Name2.Text,
	})
	MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Visible = false
	MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Visible = true
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Visible = false
	MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Visible = true
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Create.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Factions.FactionCreate.Visible = true
	MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Visible = false
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Leave.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountry
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.ManageAlliance:FireServer(currentCountry, "FactionLeave")
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Disband.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountry
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.ManageAlliance:FireServer(currentCountry, "FactionDisband")
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.View.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Visible = false
	MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Visible = true
end)
MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentCountry, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if workspace.Factions:FindFirstChild(currentCountry, true) then
		MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Visible = true
		MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Visible = false
	end
end)
MainFrame.CenterFrame.CountryFrame.Main.Faction.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Factions.Visible = true
	MainFrame.CenterFrame.CountryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.CountryFrame.Factions.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.CountryFrame.Factions.Visible = false
	MainFrame.CenterFrame.CountryFrame.Main.Visible = true
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (copy) SetFlag, (ref) currentCountry, (copy) LocalPlayer, (ref) currentCountryData, (copy) Assets, (copy) ReferenceTable, (copy) MakeMouseOver, (copy) GameGui, (copy) CenterFrameSelect
	if MainFrame.CenterFrame.CountryFrame.Visible and MainFrame.CenterFrame.Visible then
		SetFlag(MainFrame.CenterFrame.CountryFrame.Main.Flag, currentCountry)
		SetFlag(MainFrame.CenterFrame.CountryFrame.Main.Flag2, currentCountry)
		MainFrame.CenterFrame.CountryFrame.Main.CountryName.Text = currentCountry
		MainFrame.CenterFrame.CountryFrame.Main.RulerName.Text = "Ruler: " .. LocalPlayer.Name
		MainFrame.CenterFrame.CountryFrame.Main.Capital.Text = "Capital: " .. currentCountryData.Capital.Value.Name
		for i, conscription in pairs(Assets.Laws.Conscription:GetChildren()) do
			if currentCountryData.Laws.Conscription.Value == tonumber(conscription.Name) then
				MainFrame.CenterFrame.CountryFrame.Main.ConscriptionFrame.ButtonFrame[conscription.Name].BackgroundColor3 =
					Color3.fromRGB(21, 25, 30)
			else
				MainFrame.CenterFrame.CountryFrame.Main.ConscriptionFrame.ButtonFrame[conscription.Name].BackgroundColor3 =
					Color3.fromRGB(30, 36, 43)
			end
		end
		for i, ideology in pairs(Assets.Laws.Ideology:GetChildren()) do
			if currentCountryData.Laws.Ideology.Value == ideology.Name then
				MainFrame.CenterFrame.CountryFrame.Ideologies[ideology.Name].BackgroundColor3 =
					Color3.fromRGB(21, 25, 30)
			else
				MainFrame.CenterFrame.CountryFrame.Ideologies[ideology.Name].BackgroundColor3 =
					Color3.fromRGB(30, 36, 43)
			end
		end
		MainFrame.CenterFrame.CountryFrame.Main.Stability.Text = math.floor(currentCountryData.Data.Stability.Value)
			.. "%"
		local stability = MainFrame.CenterFrame.CountryFrame.Main.Stability
		local stabilityChange = currentCountryData.Data.Stability.Change.Value
		local stabilityColorGoals = { 0, 0.02 }
		local colors =
			{ ReferenceTable.Colors.Negative[2], ReferenceTable.Colors.Gold[2], ReferenceTable.Colors.Positive[2] }
		local stabilityColor
		if stabilityChange < stabilityColorGoals[1] then
			stabilityColor = colors[1]
		elseif stabilityColorGoals[1] <= stabilityChange and stabilityChange <= stabilityColorGoals[2] then
			stabilityColor = colors[2]
		elseif stabilityColorGoals[2] < stabilityChange then
			stabilityColor = colors[3]
		else
			stabilityColor = nil
		end
		stability.TextColor3 = stabilityColor
		MainFrame.CenterFrame.CountryFrame.Main.Power.Text = math.floor(currentCountryData.Power.Political.Value)
		local power = MainFrame.CenterFrame.CountryFrame.Main.Power
		local politicalPowerIncrease = currentCountryData.Power.Political.Increase.Value
		local politicalPowerGoals = { 0, 0.75 }
		local colors =
			{ ReferenceTable.Colors.Negative[2], ReferenceTable.Colors.Gold[2], ReferenceTable.Colors.Positive[2] }
		local powerColor
		if politicalPowerIncrease < politicalPowerGoals[1] then
			powerColor = colors[1]
		elseif
			politicalPowerGoals[1] <= politicalPowerIncrease and politicalPowerIncrease <= politicalPowerGoals[2]
		then
			powerColor = colors[2]
		elseif politicalPowerGoals[2] < politicalPowerIncrease then
			powerColor = colors[3]
		else
			powerColor = nil
		end
		power.TextColor3 = powerColor
		MainFrame.CenterFrame.CountryFrame.Main.WarEx.Text = math.floor(
			currentCountryData.Power.WarExhaustion.Value * 100
		) / 100
		if MainFrame.CenterFrame.CountryFrame.Policies.Visible then
			local policies = MainFrame.CenterFrame.CountryFrame.Policies.ListFrame:GetChildren()
			for i = 2, #policies do
				if currentCountryData.Laws.Policies:FindFirstChild(policies[i].Name) then
					policies[i].Status.Text = "Active"
					policies[i].Status.TextColor3 = Color3.fromRGB(149, 255, 116)
					policies[i].LayoutOrder = 0
				else
					policies[i].Status.Text = "Inactive"
					policies[i].Status.TextColor3 = Color3.fromRGB(182, 182, 182)
					policies[i].LayoutOrder = 1
				end
				if
					require(workspace.FunctionDump.ValueCalc.GetRequirement).Policy(currentCountry, policies[i].Name)
					and currentCountryData.Power.Political.Value
						>= Assets.Laws.Policies[policies[i].Name].PPCost.Value.X
				then
					policies[i].BorderSizePixel = 0
				else
					policies[i].BorderSizePixel = 1
				end
			end
		end
		if MainFrame.CenterFrame.CountryFrame.Factions.Visible then
			if workspace.Factions:FindFirstChild(currentCountry, true) then
				local factionFound = workspace.Factions:FindFirstChild(currentCountry, true)
				local factionCountriesInstance = factionFound.Parent
				MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.FactionName.Text =
					factionCountriesInstance.Parent.Name
				local factionCountries = factionCountriesInstance:GetChildren()
				for i, v in
					pairs(MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.FactionScroll:GetChildren())
				do
					if v.Name ~= "List" then
						local name = v.Name
						local found = false
						for i, v2 in pairs(factionCountries) do
							if v2.Name == name then
								found = true
								break
							end
						end
						if not found then
							v:Destroy()
						end
					end
				end
				local currentCountryIsLeader = false
				for i, country in pairs(factionCountries) do
					if country.Value == "Leader" then
						SetFlag(MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Flag, country.Name)
						currentCountryIsLeader = country.Name == currentCountry and true or currentCountryIsLeader
					end
					if
						not MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.FactionScroll:FindFirstChild(
							country.Name
						)
					then
						local flag =
							MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.FactionScroll.List.Flag:Clone()
						SetFlag(flag, country.Name)
						flag.Name = country.Name
						flag.Parent = MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.FactionScroll
						MakeMouseOver(flag, flag.Name, 16)
						flag.MouseButton1Click:Connect(function()
							-- upvalues: (ref) Assets, (ref) GameGui, (ref) CenterFrameSelect, (ref) MainFrame, (copy) flag
							local clickSound = Assets.Audio.Click_2:Clone()
							clickSound.Parent = GameGui
							clickSound:Play()
							game.Debris:AddItem(clickSound, 15)
							CenterFrameSelect("DiplomacyFrame")
							MainFrame.CenterFrame.DiplomacyFrame.Country.Value = flag.Name
						end)
						flag.Toggle.MouseButton1Click:Connect(function()
							-- upvalues: (ref) Assets, (ref) GameGui, (copy) factionCountries, (copy) v_u_941, (ref) currentCountry, (ref) currentCountryIsLeader, (copy) flag
							local clickSound = Assets.Audio.Click_2:Clone()
							clickSound.Parent = GameGui
							clickSound:Play()
							game.Debris:AddItem(clickSound, 15)
							if country.Name ~= currentCountry then
								if currentCountryIsLeader then
									flag.Option.Visible = not flag.Option.Visible
									return
								end
								flag.Option.Visible = false
							end
						end)
						MakeMouseOver(flag.Toggle, "Toggle Actions", 14)
						flag.Option.Exile.MouseButton1Click:Connect(function()
							-- upvalues: (ref) Assets, (ref) GameGui, (ref) currentCountry, (copy) factionCountries, (copy) v_u_941, (copy) flag
							local clickSound = Assets.Audio.Click_2:Clone()
							clickSound.Parent = GameGui
							clickSound:Play()
							game.Debris:AddItem(clickSound, 15)
							workspace.GameManager.ManageAlliance:FireServer(
								currentCountry,
								"FactionAction",
								{ country.Name, "Exile" }
							)
							flag.Option.Visible = false
						end)
						flag.Option.Transfer.MouseButton1Click:Connect(function()
							-- upvalues: (ref) Assets, (ref) GameGui, (ref) currentCountry, (copy) factionCountries, (copy) v_u_941, (copy) flag
							local clickSound = Assets.Audio.Click_2:Clone()
							clickSound.Parent = GameGui
							clickSound:Play()
							game.Debris:AddItem(clickSound, 15)
							workspace.GameManager.ManageAlliance:FireServer(
								currentCountry,
								"FactionAction",
								{ country.Name, "Transfer" }
							)
							flag.Option.Visible = false
						end)
					end
				end
				if factionFound.Value == "Leader" then
					MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Pending.Visible = true
					local pending = {}
					for i, descendant in pairs(factionCountriesInstance:GetDescendants()) do
						if descendant.Name == "Pending" then
							table.insert(pending, workspace.CountryData[descendant.Value])
						end
					end
					for i, v in pairs(MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Pending:GetChildren()) do
						if v.Name ~= "List" then
							local name = v.Name
							local found = false
							for i, v2 in pairs(pending) do
								if v2.Name == name then
									found = true
									break
								end
							end
							if not found then
								v:Destroy()
							end
						end
					end
					for i, country in pairs(pending) do
						if
							not MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Pending:FindFirstChild(
								country.Name
							)
						then
							local flag =
								MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Pending.List.Flag:Clone()
							SetFlag(flag, country.Name)
							flag.Name = country.Name
							flag.Parent = MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Pending
							MakeMouseOver(flag, flag.Name, 16)
							flag.Yes.MouseButton1Click:Connect(function()
								-- upvalues: (ref) Assets, (ref) GameGui, (ref) currentCountry, (copy) pending, (copy) v_u_955
								local clickSound = Assets.Audio.Click_2:Clone()
								clickSound.Parent = GameGui
								clickSound:Play()
								game.Debris:AddItem(clickSound, 15)
								workspace.GameManager.ManageAlliance:FireServer(
									currentCountry,
									"FactionResponse",
									{ country.Name, "Accept" }
								)
							end)
							MakeMouseOver(flag.Yes, "Accept", 14)
							flag.No.MouseButton1Click:Connect(function()
								-- upvalues: (ref) Assets, (ref) GameGui, (ref) currentCountry, (copy) pending, (copy) v_u_955
								local clickSound = Assets.Audio.Click_2:Clone()
								clickSound.Parent = GameGui
								clickSound:Play()
								game.Debris:AddItem(clickSound, 15)
								workspace.GameManager.ManageAlliance:FireServer(
									currentCountry,
									"FactionResponse",
									{ country.Name, "Decline" }
								)
							end)
							MakeMouseOver(flag.No, "Decline", 14)
						end
					end
				else
					MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Pending.Visible = false
				end
			elseif MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Visible then
				MainFrame.CenterFrame.CountryFrame.Factions.FactionInternal.Visible = false
				MainFrame.CenterFrame.CountryFrame.Factions.FactionView.Visible = true
			end
			local factions = workspace.Factions:GetChildren()
			local scrollChildren = MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll:GetChildren()
			for i, child in pairs(scrollChildren) do
				if child.Name ~= "List" then
					local name = child.Name
					local found = false
					for i, faction in pairs(factions) do
						if faction.Name == name then
							found = true
							break
						end
					end
					if not found then
						child:Destroy()
					end
				end
			end
			MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll.CanvasSize = UDim2.new(
				0,
				0,
				0,
				MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll.List.AbsoluteContentSize.Y * 1.1
			)
			for i, faction in pairs(factions) do
				if
					MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll:FindFirstChild(faction.Name)
				then
					for i, v in
						pairs(
							MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll[faction.Name].Countries:GetChildren()
						)
					do
						if v.Name ~= "List" then
							v:Destroy()
						end
					end
					MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll[faction.Name].Join.Text =
						"Join"
					for i, member in pairs(faction.Members:GetChildren()) do
						if member.Value == "Leader" then
							SetFlag(
								MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll[faction.Name].Flag,
								member.Name
							)
						else
							local flag = MainFrame.CenterFrame.DiplomacyFrame.Main.Status.List.Flag:Clone()
							SetFlag(flag, member.Name)
							flag.Name = member.Name
							flag.Parent =
								MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll[faction.Name].Countries
						end
						for i, v in pairs(member:GetChildren()) do
							if v.Value == currentCountry then
								MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll[faction.Name].Join.Text =
									"Pending"
							end
						end
					end
				else
					local frame =
						MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll.List.Sample:Clone()
					frame.Name = faction.Name
					frame.FactionName.Text = faction.Name
					frame.Parent = MainFrame.CenterFrame.CountryFrame.Factions.FactionView.FactionScroll
					frame.Join.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (ref) currentCountry, (copy) factions, (copy) v_u_965
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						workspace.GameManager.ManageAlliance:FireServer(currentCountry, "FactionJoin", { faction.Name })
					end)
				end
			end
		end
	end
end)
MakeMouseOver(MainFrame.CenterFrame.CountryFrame.Main.Power, "", 14)
MakeMouseOver(MainFrame.CenterFrame.CountryFrame.Main.WarEx, "", 14)
MakeMouseOver(MainFrame.CenterFrame.CountryFrame.Main.Stability, "", 14)
for i, doctrine in pairs(Assets.Laws.Doctrines:GetChildren()) do
	for i, v in pairs(doctrine:GetChildren()) do
		MainFrame.CenterFrame.MilitaryFrame.Doctrines[doctrine.Name][v.Name].MouseButton1Click:Connect(function()
			-- upvalues: (copy) Assets, (copy) GameGui, (copy) v_u_975, (copy) v_u_976, (copy) v_u_977, (copy) v_u_978
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			workspace.GameManager.ChangeLaw:FireServer("Doctrine", { doctrine.Name, v.Name })
		end)
		local text = "Doctrine: " .. v.Name .. "\n"
		for i, stat in pairs(v.Stats:GetChildren()) do
			text = text .. stat.Name .. ": " .. stat.Value .. "x\n"
		end
		MakeMouseOver(
			MainFrame.CenterFrame.MilitaryFrame.Doctrines[doctrine.Name][v.Name],
			text .. "\nRequires 500 Military Power",
			14
		)
	end
end
MakeMouseOver(MainFrame.CenterFrame.MilitaryFrame.Main.Power, "", 14)
MainFrame.CenterFrame.MilitaryFrame.Main.Doctrines.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.MilitaryFrame.Doctrines.Visible = true
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.MilitaryFrame.Doctrines.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.MilitaryFrame.Doctrines.Visible = false
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = true
end)
MainFrame.CenterFrame.MilitaryFrame.Main.Groups.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.MilitaryFrame.Groups.Visible = true
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.MilitaryFrame.Groups.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.MilitaryFrame.Groups.Visible = false
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = true
end)
MainFrame.UnitFrame.GroupList.A.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "Group", nil)
	end
	MainFrame.UnitFrame.GroupList.Visible = false
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected, (ref) selectedCenterPos, (ref) v_u_14, (copy) Mouse, (ref) groupInteraction, (ref) Units, (copy) ScaleScrollGui
	if
		MainFrame.CenterFrame.MilitaryFrame.Groups.Visible
		or MainFrame.UnitFrame.GroupList.Visible
		or MainFrame.RightFrame.PageList.MilitaryGroups.Visible
	then
		for i, group in pairs(MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame:GetChildren()) do
			if not currentCountryData.Military.Groups:FindFirstChild(group.Name) then
				if group.Name ~= "List" then
					group:Destroy()
					MainFrame.UnitFrame.GroupList[group.Name]:Destroy()
					MainFrame.RightFrame.PageList.MilitaryGroups.GroupFrame[group.Name]:Destroy()
				end
			end
		end
		for i, group in pairs(currentCountryData.Military.Groups:GetChildren()) do
			if MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame:FindFirstChild(group.Name) then
				MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame[group.Name].GSize.Text = ""
				MainFrame.RightFrame.PageList.MilitaryGroups.GroupFrame[group.Name].GSize.Text = ""
				local groupLeader = group.Value == "" and "No Leader"
					or group.Value
						.. "    "
						.. MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[group.Value].XPStat.Text
				MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame[group.Name].Leader.Text = groupLeader
				MainFrame.RightFrame.PageList.MilitaryGroups.GroupFrame[group.Name].Leader.Text = groupLeader
			else
				local groupFrame = MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame.List.Sample:Clone()
				groupFrame.Name = group.Name
				groupFrame.GName.Text = group.Name
				groupFrame.Parent = MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame
				local button = MainFrame.UnitFrame.GroupList.List.Sample:Clone()
				button.Name = groupFrame.Name
				button.Text = groupFrame.Name
				button.Parent = MainFrame.UnitFrame.GroupList
				button.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) mouseInteractionType, (ref) selected, (ref) v_u_990, (copy) v_u_991, (ref) MainFrame
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					if mouseInteractionType == "MoveUnit" then
						workspace.GameManager.IssueUnitOrder:FireServer(selected, "Group", group.Name)
					end
					MainFrame.UnitFrame.GroupList.Visible = false
				end)
				local groupFrame2 = groupFrame:Clone()
				groupFrame2.Disband:Destroy()
				groupFrame2.Parent = MainFrame.RightFrame.PageList.MilitaryGroups.GroupFrame
				local function Select()
					-- upvalues: (ref) currentCountryData, (ref) v_u_990, (copy) v_u_991, (ref) selected, (ref) mouseInteractionType, (ref) selectedCenterPos, (ref) v_u_14, (ref) Mouse
					Disengage()
					for i, unit in pairs(workspace.Units:GetChildren()) do
						if unit.Owner.Value == currentCountryData.Name then
							if unit.Group.Value == group then
								table.insert(selected, unit)
							end
						end
					end
					if 0 < #selected then
						mouseInteractionType = "MoveUnit"
						selectedCenterPos = Vector3.new()
						for i, v in pairs(selected) do
							selectedCenterPos = selectedCenterPos + v.Position
						end
						selectedCenterPos = selectedCenterPos / #selected
						v_u_14 = 1
						if not workspace:FindFirstChild("CirclePath") then
							local circlePath = Instance.new("Folder")
							circlePath.Name = "CirclePath"
							circlePath.Parent = workspace
							Mouse.TargetFilter = circlePath
						end
					end
				end
				groupFrame2.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (copy) Select
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					Select()
				end)
				groupFrame.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) groupInteraction, (copy) Select, (ref) selected, (ref) v_u_990, (copy) v_u_991
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					if groupInteraction == "" then
						Select()
					else
						workspace.GameManager.CountryWorker:FireServer("AssignLeader", { selected, group.Name })
						selected = {}
						groupInteraction = ""
					end
				end)
				groupFrame.Disband.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) v_u_990, (copy) v_u_991
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					workspace.GameManager.CountryWorker:FireServer("DestroyMilitaryGroup", { group.Name })
				end)
			end
		end
		local unitsRef = Units
		local groups = {}
		local groupsUnits = {}
		for i, unit in pairs(unitsRef) do
			if unit.Owner.Value == currentCountryData.Name then
				if unit.Group.Value ~= nil then
					if unit.Group.Value:IsDescendantOf(workspace) then
						if not table.find(groups, unit.Group.Value.Name) then
							table.insert(groups, unit.Group.Value.Name)
						end
						local unitGroup = table.find(groups, unit.Group.Value.Name)
						if groupsUnits[unitGroup] == nil then
							groupsUnits[unitGroup] = {
								0,
								0,
								0,
								0,
							}
						end
						if unit.Type.Value == "Infantry" then
							groupsUnits[unitGroup][1] = groupsUnits[unitGroup][1] + unit.Current.Value
						elseif unit.Type.Value == "Tank" then
							groupsUnits[unitGroup][2] = groupsUnits[unitGroup][2] + unit.Current.Value
						elseif unit.Stats.TransverseType.Value == "Naval" then
							groupsUnits[unitGroup][3] = groupsUnits[unitGroup][3]
								+ math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
						elseif unit.Stats.TransverseType.Value == "Air" then
							groupsUnits[unitGroup][4] = groupsUnits[unitGroup][4]
								+ math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
						end
					end
				end
			end
		end
		for i, group in pairs(groups) do
			local text = ""
			if groupsUnits[i][1] ~= 0 then
				local groupInfantry = groupsUnits[i][1]
				if 1000 <= groupInfantry then
					groupInfantry = math.ceil(groupInfantry / 100) / 10 .. "k"
				elseif 1000000 <= groupInfantry then
					groupInfantry = math.ceil(groupInfantry / 100000) / 10 .. "m"
				end
				text = text .. " | Infantry: " .. groupInfantry
			end
			if groupsUnits[i][2] ~= 0 then
				text = text .. " | Tanks: " .. groupsUnits[i][2]
			end
			if groupsUnits[i][3] ~= 0 then
				text = text .. " | Ships: " .. groupsUnits[i][3]
			end
			if groupsUnits[i][4] ~= 0 then
				text = text .. " | Aircraft: " .. groupsUnits[i][4]
			end
			if 1 < #text then
				text = text .. " |"
			end
			MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame[groups[i]].GSize.Text = text
			MainFrame.RightFrame.PageList.MilitaryGroups.GroupFrame[groups[i]].GSize.Text = text
		end
		ScaleScrollGui(MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame.List, "Y")
		ScaleScrollGui(MainFrame.RightFrame.PageList.MilitaryGroups.GroupFrame.List, "Y")
		ScaleScrollGui(MainFrame.UnitFrame.GroupList.List, "Y")
	end
end)
MainFrame.CenterFrame.MilitaryFrame.Groups.Create.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if
		MainFrame.CenterFrame.MilitaryFrame.Groups.GroupName.Text ~= ""
		and not MainFrame.CenterFrame.MilitaryFrame.Groups.GroupFrame:FindFirstChild(
			MainFrame.CenterFrame.MilitaryFrame.Groups.GroupName.Text
		)
	then
		workspace.GameManager.CountryWorker:FireServer(
			"CreateMilitaryGroup",
			{ MainFrame.CenterFrame.MilitaryFrame.Groups.GroupName.Text }
		)
	end
end)
MainFrame.CenterFrame.MilitaryFrame.Main.Leaders.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.MilitaryFrame.Leaders.Visible = true
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.MilitaryFrame.Leaders.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.MilitaryFrame.Leaders.Visible = false
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = true
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) Assets, (copy) GameGui, (ref) groupInteraction, (ref) selected, (copy) MakeMouseOver, (copy) ReferenceTable, (copy) ScaleScrollGui
	if MainFrame.CenterFrame.MilitaryFrame.Leaders.Visible or MainFrame.RightFrame.PageList.MilitaryGroups.Visible then
		for i, leader in pairs(MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame:GetChildren()) do
			if not currentCountryData.Military.Leaders:FindFirstChild(leader.Name) then
				if leader.Name ~= "List" then
					leader:Destroy()
				end
			end
		end
		for i, leader in pairs(currentCountryData.Military.Leaders:GetChildren()) do
			if MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame:FindFirstChild(leader.Name) then
				MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[leader.Name].LName.Text = '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. require(workspace.FunctionDump.ValueCalc.GetNames).MilitaryRank[leader.Value][leader.Rank.Value]
					.. "</font>"
					.. " "
					.. leader.Name
				MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[leader.Name].Assignment.Text = "Unassigned"
				for i, group in pairs(currentCountryData.Military.Groups:GetChildren()) do
					if group.Value == leader.Name then
						MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[leader.Name].Assignment.Text =
							group.Name
						break
					end
				end
				local statsText = "| "
				for i, effect in pairs(leader.Effects:GetChildren()) do
					statsText = statsText .. effect.Name .. ": " .. math.ceil(effect.Value * 100) .. "% | "
				end
				MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[leader.Name].Stats.Text = statsText
				MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[leader.Name].XP.Bar.Size =
					UDim2.new(leader.XP.Value.X / leader.XP.Value.Z, 0, 1, 0)
				local xpMillions, xpThousands, xpHundrends =
					tostring(math.ceil(leader.XP.Value.X)):match("(%-?%d?)(%d*)(%.?.*)")
				local leaderXp = xpMillions .. xpThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse() .. xpHundrends
				local maxXpMillions, maxXpThousands, maxXpHundrends =
					tostring(leader.XP.Value.Z):match("(%-?%d?)(%d*)(%.?.*)")
				MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[leader.Name].XPStat.Text = leaderXp
					.. " / "
					.. maxXpMillions
					.. maxXpThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. maxXpHundrends
					.. " XP"
				if leader.Rank.Value == 5 then
					MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame[leader.Name].XPStat.Text = "Maximum Rank"
				end
			else
				local button = MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame.List.Sample:Clone()
				button.Name = leader.Name
				button.LName.Text = leader.Name
				button.Parent = MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame
				button.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (ref) groupInteraction, (ref) selected, (ref) v_u_1018, (copy) v_u_1019
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					MainFrame.CenterFrame.MilitaryFrame.Leaders.Visible = false
					MainFrame.CenterFrame.MilitaryFrame.Groups.Visible = true
					groupInteraction = "AssignLeader"
					selected = leader.Name
				end)
				MakeMouseOver(button, "Assign Leader", 14)
				button.Dismiss.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) v_u_1018, (copy) v_u_1019
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					workspace.GameManager.CountryWorker:FireServer("DismissLeader", { leader.Name })
				end)
			end
			ScaleScrollGui(MainFrame.CenterFrame.MilitaryFrame.Leaders.LeaderFrame.List, "Y")
		end
	end
end)
MainFrame.CenterFrame.MilitaryFrame.Leaders.Army.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.CountryWorker:FireServer("RecruitLeader", { 1 })
end)
MainFrame.CenterFrame.MilitaryFrame.Leaders.Navy.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.CountryWorker:FireServer("RecruitLeader", { 2 })
end)
MainFrame.CenterFrame.MilitaryFrame.Leaders.Airforce.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.CountryWorker:FireServer("RecruitLeader", { 3 })
end)
MainFrame.CenterFrame.MilitaryFrame.Main.Wars.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ClearList, (copy) MainFrame, (copy) SetFlag, (copy) MakeMouseOver, (copy) ReferenceTable, (copy) ScaleScrollGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ClearList(MainFrame.CenterFrame.MilitaryFrame.Wars.ListFrame.List)
	for i, war in pairs(workspace.Wars:GetChildren()) do
		local frame = MainFrame.CenterFrame.MilitaryFrame.Wars.ListFrame.List.Sample:Clone()
		frame.Name = war.Name
		frame.WName.Text = war.Name
		frame.StartDate.Text = "Started:\n" .. war.Date.Value
		local totalLosses = 0
		local warLeader = nil
		for i, child in pairs(war.Attacker:GetChildren()) do
			if child.Value == "WarLeader" then
				SetFlag(frame.Attacker, child.Name)
				warLeader = child
			else
				local frame = frame.AList.Grid.Sample:Clone()
				frame.Name = child.Name
				SetFlag(frame, child.Name)
				frame.Parent = frame.AList
				local millions, thousands, hundrends = tostring(child.Losses.Value):match("(%-?%d?)(%d*)(%.?.*)")
				MakeMouseOver(
					frame,
					child.Name
						.. "\n \nLosses: "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Negative[1]
						.. ')">'
						.. millions
						.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. hundrends
						.. "</font>",
					14
				)
			end
			totalLosses = totalLosses + child.Losses.Value
		end
		local warLeaderLossesMillions, warLeaderLossesThousands, warLeaderLossesHundrends =
			tostring(warLeader.Losses.Value):match("(%-?%d?)(%d*)(%.?.*)")
		local warLeaderLosses = '<font color="rgb('
			.. ReferenceTable.Colors.Negative[1]
			.. ')">'
			.. warLeaderLossesMillions
			.. warLeaderLossesThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. warLeaderLossesHundrends
			.. "</font>"
		local lossesMillions, lossesThousands, lossesHundrends = tostring(totalLosses):match("(%-?%d?)(%d*)(%.?.*)")
		MakeMouseOver(
			frame.Attacker,
			warLeader.Name
				.. "\n \nLosses: "
				.. warLeaderLosses
				.. "\n \nTotal Attacking Losses: "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Negative[1]
				.. ')">'
				.. lossesMillions
				.. lossesThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. lossesHundrends
				.. "</font>",
			14
		)
		local defendingLosses = 0
		local defenderWarLeader = nil
		for i, defender in pairs(war.Defender:GetChildren()) do
			if defender.Value == "WarLeader" then
				SetFlag(frame.Defender, defender.Name)
				defenderWarLeader = defender
			else
				local frame = frame.AList.Grid.Sample:Clone()
				frame.Name = defender.Name
				SetFlag(frame, defender.Name)
				frame.Parent = frame.DList
				local millions, thousands, hundrends = tostring(defender.Losses.Value):match("(%-?%d?)(%d*)(%.?.*)")
				MakeMouseOver(
					frame,
					defender.Name
						.. "\n \nLosses: "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Negative[1]
						.. ')">'
						.. millions
						.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. hundrends
						.. "</font>",
					14
				)
			end
			defendingLosses = defendingLosses + defender.Losses.Value
		end
		local defenderWarLeaderLossesMillions, defenderWarLeaderLossesThousands, defenderWarLeaderLossesHundrends =
			tostring(defenderWarLeader.Losses.Value):match("(%-?%d?)(%d*)(%.?.*)")
		local defenderWarLeaderLosses = '<font color="rgb('
			.. ReferenceTable.Colors.Negative[1]
			.. ')">'
			.. defenderWarLeaderLossesMillions
			.. defenderWarLeaderLossesThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. defenderWarLeaderLossesHundrends
			.. "</font>"
		local defendingLossesMillions, defendingLossesThousands, defendingLossesHundrends =
			tostring(defendingLosses):match("(%-?%d?)(%d*)(%.?.*)")
		MakeMouseOver(
			frame.Defender,
			defenderWarLeader.Name
				.. "\n \nLosses: "
				.. defenderWarLeaderLosses
				.. "\n \nTotal Defending Losses: "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Negative[1]
				.. ')">'
				.. defendingLossesMillions
				.. defendingLossesThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. defendingLossesHundrends
				.. "</font>",
			14
		)
		frame.Parent = MainFrame.CenterFrame.MilitaryFrame.Wars.ListFrame
	end
	ScaleScrollGui(MainFrame.CenterFrame.MilitaryFrame.Wars.ListFrame.List, "Y")
	MainFrame.CenterFrame.MilitaryFrame.Wars.Visible = true
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = false
end)
MainFrame.CenterFrame.MilitaryFrame.Wars.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.MilitaryFrame.Wars.Visible = false
	MainFrame.CenterFrame.MilitaryFrame.Main.Visible = true
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (copy) Assets, (ref) currentCountryData
	if MainFrame.CenterFrame.MilitaryFrame.Visible and MainFrame.CenterFrame.Visible then
		for i, doctrine in pairs(Assets.Laws.Doctrines:GetChildren()) do
			for i, child in pairs(doctrine:GetChildren()) do
				if currentCountryData.Laws.Doctrines[doctrine.Name].Value == child.Name then
					MainFrame.CenterFrame.MilitaryFrame.Doctrines[doctrine.Name][child.Name].BackgroundColor3 =
						Color3.fromRGB(21, 25, 30)
				else
					MainFrame.CenterFrame.MilitaryFrame.Doctrines[doctrine.Name][child.Name].BackgroundColor3 =
						Color3.fromRGB(30, 36, 43)
				end
			end
		end
		MainFrame.CenterFrame.MilitaryFrame.Main.Power.Text = math.floor(currentCountryData.Power.Military.Value)
	end
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (copy) receivedData, (ref) currentCountryData, (copy) Assets, (copy) GameGui, (copy) ClearList, (copy) ScaleScrollGui
	if MainFrame.CenterFrame.Visible and MainFrame.CenterFrame.EspionageFrame.Visible and receivedData.Spy then
		MainFrame.CenterFrame.EspionageFrame.Main.Power.Text = math.floor(currentCountryData.Power.Political.Value)
		local spy = receivedData.Spy
		local listFrame = MainFrame.CenterFrame.EspionageFrame.Main.ListFrame
		for i, v in pairs(listFrame:GetChildren()) do
			if not spy[v.Name] then
				if v:IsA("Frame") then
					v:Destroy()
				end
			end
		end
		for i, v in pairs(spy) do
			if listFrame:FindFirstChild(i) then
				listFrame[i].Visible = true
				listFrame[i].Assignment.Text = "[" .. v[".Assignment.Value"].Name .. "] " .. v[".Order.Desc.Value"]
				if spy[i][".Order.Progress.Value"].Y == 0 then
					listFrame[i].Progress.Visible = true
					listFrame[i].Progress.Bar.Size =
						UDim2.new(v[".Order.Progress.Value"].X / v[".Order.Progress.Value"].Z, 0, 1, 0)
					listFrame[i].NewOrder.Text = ""
				else
					listFrame[i].Progress.Visible = false
					if spy[i][".Order.Value"] == "Ready" then
						listFrame[i].NewOrder.Text = "Launch Mission"
					else
						listFrame[i].NewOrder.Text = "New Order"
					end
				end
			else
				local frame = listFrame.List.Sample:Clone()
				frame.Visible = false
				frame.Name = i
				frame.LName.Text = "Agent " .. i
				frame.Parent = listFrame
				frame.Abort.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (copy) i
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					workspace.GameManager.CountryWorker:FireServer("Espionage", { "Abort", i })
				end)
				frame.Dismiss.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (copy) i
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					workspace.GameManager.CountryWorker:FireServer("Espionage", { "Dismiss", i })
				end)
				frame.NewOrder.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame, (ref) MainFrame, (ref) ClearList, (copy) i, (ref) ScaleScrollGui, (ref) receivedData, (ref) currentCountryData
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					if frame.NewOrder.Text == "New Order" then
						local function Purge()
							-- upvalues: (ref) MainFrame, (ref) ClearList
							MainFrame.CenterFrame.EspionageFrame.NewOrder.TargetFrame.Visible = false
							MainFrame.CenterFrame.EspionageFrame.NewOrder.AdditionalFrame.Visible = false
							MainFrame.CenterFrame.EspionageFrame.NewOrder.TargetFrame.Setting.Value = ""
							MainFrame.CenterFrame.EspionageFrame.NewOrder.AdditionalFrame.Setting.Value = ""
							ClearList(MainFrame.CenterFrame.EspionageFrame.NewOrder.TargetFrame.ListFrame.List)
							ClearList(MainFrame.CenterFrame.EspionageFrame.NewOrder.AdditionalFrame.ListFrame.List)
							MainFrame.CenterFrame.EspionageFrame.NewOrder.InfoFrame.Info.Text = ""
						end
						Purge()
						MainFrame.CenterFrame.EspionageFrame.NewOrder.InfoFrame.Info.Text = ""
						MainFrame.CenterFrame.EspionageFrame.NewOrder.Agent.Value = i
						MainFrame.CenterFrame.EspionageFrame.NewOrder.AgentTitle.Text = "Agent: " .. i
						ClearList(MainFrame.CenterFrame.EspionageFrame.NewOrder.ActionFrame.List)
						local function MakeList(frame, targets, action)
							-- upvalues: (ref) ScaleScrollGui
							local v_u_1091 = action == "Blame" and "Blame Country: " or "Target: "
							frame.Title.Text = v_u_1091
							for i, v in pairs(targets) do
								local button = frame.ListFrame.List.Sample:Clone()
								if action == "Blame" or action == "Move" then
									button.Name = v.Name
									button.Text = button.Name
								elseif action == "Sabotage" then
									button.Name = v.Parent.Parent.Name .. v.Name
									button.Text = v.Name .. " in " .. v.Parent.Parent.Name
								end
								button.Parent = frame.ListFrame
								button.MouseButton1Click:Connect(function()
									-- upvalues: (copy) frame, (copy) button, (ref) v_u_1091
									frame.Setting.Value = button.Name
									frame.Title.Text = v_u_1091 .. button.Text
								end)
							end
							if action == "Blame" or action == "Move" then
								local button = frame.ListFrame.List.Sample:Clone()
								button.Name = "None"
								button.Text = "None"
								button.LayoutOrder = -5
								button.Parent = frame.ListFrame
								button.MouseButton1Click:Connect(function()
									-- upvalues: (copy) frame, (copy) button, (ref) v_u_1091
									frame.Setting.Value = button.Name
									frame.Title.Text = v_u_1091 .. button.Text
								end)
							end
							ScaleScrollGui(frame.ListFrame.List, "Y")
						end
						local actionType = receivedData.Spy[frame.Name][".Assignment.Value"].Name
									== currentCountryData.Name
								and "Home"
							or "Foreign"
						for _, action in pairs(Assets.Laws.Espionage.Actions:GetChildren()) do
							if action.Value == actionType or action.Value == "Universal" then
								local button =
									MainFrame.CenterFrame.EspionageFrame.NewOrder.ActionFrame.List.Sample:Clone()
								button.Name = action.Name
								button.Text = action.Name
								button.Parent = MainFrame.CenterFrame.EspionageFrame.NewOrder.ActionFrame
								button.MouseButton1Click:Connect(function()
									-- upvalues: (ref) Assets, (ref) GameGui, (copy) Purge, (ref) MainFrame, (copy) v_u_1098, (copy) button, (ref) receivedData, (ref) i, (copy) MakeList
									local clickSound = Assets.Audio.Click_2:Clone()
									clickSound.Parent = GameGui
									clickSound:Play()
									game.Debris:AddItem(clickSound, 15)
									Purge()
									MainFrame.CenterFrame.EspionageFrame.NewOrder.InfoFrame.Info.Text = action.Name
										.. "\n\n"
										.. action.Desc.Value
									MainFrame.CenterFrame.EspionageFrame.NewOrder.ActionFrame.Setting.Value =
										button.Name
									if action:FindFirstChild("Target") then
										MainFrame.CenterFrame.EspionageFrame.NewOrder.TargetFrame.Visible = true
										local v1101 = action.Target.Value == "Blame" and "Blame" or action.Name
										MakeList(
											MainFrame.CenterFrame.EspionageFrame.NewOrder.TargetFrame,
											require(workspace.FunctionDump.ValueCalc.Data_Espionage).GetTargets(
												v1101,
												receivedData.Spy[i][".Assignment.Value"].Name
											),
											v1101
										)
									end
									if action:FindFirstChild("Additional") then
										MainFrame.CenterFrame.EspionageFrame.NewOrder.AdditionalFrame.Visible = true
										local v1102 = action.Additional.Value == "Blame" and "Blame" or action.Name
										MakeList(
											MainFrame.CenterFrame.EspionageFrame.NewOrder.AdditionalFrame,
											require(workspace.FunctionDump.ValueCalc.Data_Espionage).GetTargets(
												v1102,
												receivedData.Spy[i][".Assignment.Value"].Name
											),
											v1102
										)
									end
								end)
							end
						end
						ScaleScrollGui(MainFrame.CenterFrame.EspionageFrame.NewOrder.ActionFrame.List, "Y")
						MainFrame.CenterFrame.EspionageFrame.NewOrder.Visible = true
						MainFrame.CenterFrame.EspionageFrame.Main.Visible = false
					elseif frame.NewOrder.Text == "Launch Mission" then
						workspace.GameManager.CountryWorker:FireServer("Espionage", { "FireMission", i })
					end
				end)
			end
		end
		ScaleScrollGui(listFrame.List, "Y")
	end
end)
MainFrame.CenterFrame.EspionageFrame.Main.Recruit.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.CountryWorker:FireServer("Espionage", { "Recruit" })
end)
MainFrame.CenterFrame.EspionageFrame.NewOrder.Confirm.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EspionageFrame.NewOrder.Visible = false
	MainFrame.CenterFrame.EspionageFrame.Main.Visible = true
	workspace.GameManager.CountryWorker:FireServer("Espionage", {
		"NewMission",
		MainFrame.CenterFrame.EspionageFrame.NewOrder.Agent.Value,
		{
			MainFrame.CenterFrame.EspionageFrame.NewOrder.ActionFrame.Setting.Value,
			MainFrame.CenterFrame.EspionageFrame.NewOrder.TargetFrame.Setting.Value,
			MainFrame.CenterFrame.EspionageFrame.NewOrder.AdditionalFrame.Setting.Value,
		},
	})
end)
MainFrame.CenterFrame.EspionageFrame.NewOrder.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.CenterFrame.EspionageFrame.NewOrder.Visible = false
	MainFrame.CenterFrame.EspionageFrame.Main.Visible = true
end)
local v_u_1106 = {}
MainFrame.WarOverFrame.OverallFrame.Peace.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) v_u_1106
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.WarOverFrame.PeaceFrame.Visible = true
	MainFrame.WarOverFrame.OverallFrame.Visible = false
	v_u_1106 = {}
	for i, v in pairs(MainFrame.WarOverFrame.OverallFrame.BFrame:GetChildren()) do
		if v:IsA("Frame") then
			if v.Flag.Leader.Visible then
				MainFrame.WarOverFrame.PeaceFrame.Target.Value = v.Name
				break
			end
		end
	end
	MainFrame.WarOverFrame.PeaceFrame.Mode.Value = "Demand"
end)
MainFrame.WarOverFrame.OverallFrame.Add.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) currentCountryData, (ref) currentCountry
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.WarOverFrame.OverallFrame.AllyFrame.Visible = true
	for i, v in pairs(MainFrame.WarOverFrame.OverallFrame.AllyFrame:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end
	local alliances = currentCountryData.Diplomacy.Alliances:GetChildren()
	local countryInAFaction = workspace.Factions:FindFirstChild(currentCountry, true)
	local isInAFaction
	if countryInAFaction then
		alliances = countryInAFaction.Parent:GetChildren()
		isInAFaction = true
	else
		isInAFaction = false
	end
	for i, alliance in pairs(alliances) do
		if alliance.Name ~= currentCountry then
			if alliance.Value == "Alliance" or isInAFaction then
				if not MainFrame.WarOverFrame.OverallFrame.AFrame:FindFirstChild(alliance.Name) then
					if
						not require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
							alliance.Name,
							MainFrame.WarOverFrame.OverallFrame.BFrame:GetChildren()[3].Name,
							"Together"
						)
					then
						if
							not workspace.CountryData[alliance.Name].Diplomacy.Truces:FindFirstChild(
								MainFrame.WarOverFrame.OverallFrame.BFrame:GetChildren()[3].Name
							)
						then
							local button = MainFrame.WarOverFrame.OverallFrame.AllyFrame.List.Sample:Clone()
							button.Name = alliance.Name
							button.Text = alliance.Name
							button.Parent = MainFrame.WarOverFrame.OverallFrame.AllyFrame
							button.MouseButton1Click:Connect(function()
								-- upvalues: (ref) Assets, (ref) GameGui, (ref) alliances, (copy) v_u_1116, (ref) MainFrame
								local clickSound = Assets.Audio.Click_2:Clone()
								clickSound.Parent = GameGui
								clickSound:Play()
								game.Debris:AddItem(clickSound, 15)
								workspace.GameManager.ManageAlliance:FireServer(
									alliance.Name,
									"RequestJoin",
									{ workspace.Wars[MainFrame.WarOverFrame.CurrentWar.Value] }
								)
								MainFrame.WarOverFrame.OverallFrame.AllyFrame.Visible = false
							end)
						end
					end
				end
			end
		end
	end
	MainFrame.WarOverFrame.PeaceFrame.Mode.Value = "Demand"
end)
MainFrame.WarOverFrame.PeaceFrame.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) v_u_1106
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.WarOverFrame.PeaceFrame.Visible = false
	MainFrame.WarOverFrame.OverallFrame.Visible = true
	v_u_1106 = {}
end)
local function GetPeaceMatch(warGoal)
	-- upvalues: (copy) MainFrame
	local termAvailable = true
	local currentWar = workspace.Wars:FindFirstChild(MainFrame.WarOverFrame.CurrentWar.Value)
	if currentWar then
		if
			not require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).AllowedTerms(
				warGoal,
				currentWar.CasusBelli.Value
			)
		then
			termAvailable = false
		end
	end
	return termAvailable
end
local allTerms = {
	"AnnexSome",
	"Puppet",
	"Reparations",
	"Money",
	"Liberate",
	"Resource",
	"Ideology",
	"Disarmament",
}
MainFrame.WarOverFrame.PeaceFrame.TermsFrame.AnnexSome.Select.MouseButton1Click:Connect(function()
	-- upvalues: (copy) GetPeaceMatch, (copy) MainFrame, (ref) cityAnnexationFrame, (ref) v_u_18, (ref) citySelection, (copy) WipeObjects, (ref) currentCountry, (ref) v_u_246, (ref) selected, (ref) mouseInteractionType, (ref) currentMapType
	if GetPeaceMatch("AnnexSome") then
		MainFrame.WarOverFrame.PeaceFrame.Visible = false
		MainFrame.WarOverFrame.SelectFrame.Visible = true
		cityAnnexationFrame = MainFrame.WarOverFrame.SelectFrame
		v_u_18 = true
		citySelection = true
		WipeObjects()
		local targetCities =
			workspace.Baseplate.Cities[cityAnnexationFrame.Parent.PeaceFrame.Target.Value]:GetChildren()
		if cityAnnexationFrame.Parent.PeaceFrame.Mode.Value == "Demand" then
			targetCities = workspace.Baseplate.Cities[currentCountry]:GetChildren()
		end
		if 0 < #v_u_246 then
			targetCities = v_u_246
		end
		for i, city in pairs(targetCities) do
			if
				city:GetAttribute("ActualOwner")
				== cityAnnexationFrame.Parent.PeaceFrame.Target:GetAttribute("ActualTarget")
			then
				table.insert(selected, city)
			end
		end
		if 0 < #selected then
			mouseInteractionType = "SelectCity"
		end
		currentMapType = "PeaceTreaty"
		UpdateTiles(nil, "UniversalCheck")
	end
end)
table.insert(loopFunctions, function()
	-- upvalues: (ref) currentMapType, (ref) cityAnnexationFrame, (ref) selected
	if
		currentMapType == "PeaceTreaty"
		and cityAnnexationFrame
		and #selected ~= cityAnnexationFrame:GetAttribute("AnnexedAmount")
	then
		cityAnnexationFrame:SetAttribute("AnnexedAmount", #selected)
		UpdateTiles(nil, "UniversalCheck")
		print("Updated", currentMapType)
	end
end)
MainFrame.WarOverFrame.SelectFrame.Clear.MouseButton1Click:Connect(function()
	-- upvalues: (copy) WipeObjects
	WipeObjects()
end)
MainFrame.WarOverFrame.SelectFrame.Occupied.MouseButton1Click:Connect(function()
	-- upvalues: (copy) WipeObjects, (ref) cityAnnexationFrame, (ref) currentCountry, (ref) selected, (ref) mouseInteractionType
	WipeObjects()
	local targetCities = workspace.Baseplate.Cities[cityAnnexationFrame.Parent.PeaceFrame.Target.Value]:GetChildren()
	if cityAnnexationFrame.Parent.PeaceFrame.Mode.Value == "Demand" then
		targetCities = workspace.Baseplate.Cities[currentCountry]:GetChildren()
	end
	for i, city in pairs(targetCities) do
		if
			city:GetAttribute("ActualOwner")
			== cityAnnexationFrame.Parent.PeaceFrame.Target:GetAttribute("ActualTarget")
		then
			table.insert(selected, city)
		end
	end
	if 0 < #selected then
		mouseInteractionType = "SelectCity"
	end
end)
local selectSearchBox = MainFrame.WarOverFrame.SelectFrame.Countries.SearchSample.Box
local selectCountries = MainFrame.WarOverFrame.SelectFrame.Countries
selectSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) selectCountries, (copy) selectSearchBox
	for i, v in pairs(selectCountries:GetChildren()) do
		if v:IsA("GuiBase") then
			if v ~= selectSearchBox.Parent then
				if string.match(string.lower(v.Name), string.lower(selectSearchBox.Text)) == nil then
					v.Visible = false
				else
					v.Visible = true
				end
			end
		end
	end
end)
MainFrame.WarOverFrame.SelectFrame.CountrySelect.MouseButton1Click:Connect(function()
	-- upvalues: (copy) MainFrame, (copy) ClearList, (ref) cityAnnexationFrame, (copy) SetFlag, (copy) Assets, (copy) GameGui, (ref) selected, (ref) mouseInteractionType
	if MainFrame.WarOverFrame.SelectFrame.Countries.Visible then
		MainFrame.WarOverFrame.SelectFrame.Countries.Visible = false
	else
		ClearList(
			MainFrame.WarOverFrame.SelectFrame.Countries.List,
			{ MainFrame.WarOverFrame.SelectFrame.Countries.SearchSample }
		)
		for country, cities in
			pairs(
				(
					require(workspace.FunctionDump.ValueCalc.GetCities).Composition(
						cityAnnexationFrame.Parent.PeaceFrame.Target:GetAttribute("ActualTarget"),
						true
					)
				)
			)
		do
			local button = MainFrame.WarOverFrame.SelectFrame.Countries.List.Sample:Clone()
			button.Name = country
			SetFlag(button.Flag, country)
			button.CName.Text = country
			button.MouseButton1Click:Connect(function()
				-- upvalues: (ref) Assets, (ref) GameGui, (copy) cities, (ref) selected, (ref) mouseInteractionType
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				for i, v in pairs(cities) do
					if not table.find(selected, v) then
						table.insert(selected, v)
					end
				end
				if 0 < #selected then
					mouseInteractionType = "SelectCity"
				end
			end)
			button.Parent = MainFrame.WarOverFrame.SelectFrame.Countries
		end
		MainFrame.WarOverFrame.SelectFrame.Countries.Visible = true
	end
end)
MainFrame.WarOverFrame.SelectFrame.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) MainFrame, (ref) cityAnnexationFrame, (ref) v_u_18, (ref) citySelection, (ref) v_u_246, (ref) selected, (copy) WipeObjects, (ref) mouseInteractionType, (ref) currentMapType
	MainFrame.WarOverFrame.PeaceFrame.Visible = true
	MainFrame.WarOverFrame.SelectFrame.Visible = false
	MainFrame.WarOverFrame.SelectFrame.Countries.Visible = false
	cityAnnexationFrame = false
	v_u_18 = false
	citySelection = false
	v_u_246 = {}
	for i, v in pairs(selected) do
		table.insert(v_u_246, v)
	end
	WipeObjects()
	mouseInteractionType = ""
	currentMapType = "Political"
	UpdateTiles(nil, "UniversalCheck")
end)
for i, v in pairs(allTerms) do
	local termFrame = MainFrame.WarOverFrame.PeaceFrame.TermsFrame[v]
	termFrame.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) GetPeaceMatch, (copy) allTerms, (copy) v_u_1139, (ref) v_u_1106
		local clickSound = Assets.Audio.Click_3:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		if GetPeaceMatch(v) then
			local term = v
			local v1143 = false
			for v1144, _ in pairs(v_u_1106) do
				if v1144 == term then
					v_u_1106[v1144] = nil
					v1143 = true
					break
				end
			end
			if not v1143 then
				v_u_1106[term] = 0
				return
			end
		end
	end)
	for i, v in pairs(termFrame:GetChildren()) do
		if v:GetAttribute("IncrementTab") then
			MakeMouseOver(v.Increase, "Right click to increase to maximum", 14)
			MakeMouseOver(v.Decrease, "Right click to decrease to minimum", 14)
			v.Increase.MouseButton1Click:Connect(function()
				-- upvalues: (copy) Assets, (copy) GameGui, (copy) allTerms, (copy) v_u_1139, (copy) v_u_1145, (copy) v_u_1146
				local clickSound = Assets.Audio.Click_3:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				v:SetAttribute(
					"Choice",
					(
						math.clamp(
							v:GetAttribute("Choice") + 1,
							1,
							#require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).TermChoices(v, v.Name)[1]
						)
					)
				)
			end)
			v.Decrease.MouseButton1Click:Connect(function()
				-- upvalues: (copy) Assets, (copy) GameGui, (copy) allTerms, (copy) v_u_1139, (copy) v_u_1145, (copy) v_u_1146
				local clickSound = Assets.Audio.Click_3:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				v:SetAttribute(
					"Choice",
					(
						math.clamp(
							v:GetAttribute("Choice") - 1,
							1,
							#require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).TermChoices(v, v.Name)[1]
						)
					)
				)
			end)
			v.Increase.MouseButton2Click:Connect(function()
				-- upvalues: (copy) Assets, (copy) GameGui, (copy) allTerms, (copy) v_u_1139, (copy) v_u_1145, (copy) v_u_1146
				local clickSound = Assets.Audio.Click_3:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				v:SetAttribute(
					"Choice",
					#require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).TermChoices(v, v.Name)[1]
				)
			end)
			v.Decrease.MouseButton2Click:Connect(function()
				-- upvalues: (copy) Assets, (copy) GameGui, (copy) v_u_1145, (copy) v_u_1146
				local clickSound = Assets.Audio.Click_3:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				v:SetAttribute("Choice", 1)
			end)
		end
	end
end
MainFrame.WarOverFrame.PeaceFrame.Demand.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) v_u_1106
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.WarOverFrame.PeaceFrame.Mode.Value = "Demand"
	v_u_1106 = {}
end)
MainFrame.WarOverFrame.PeaceFrame.Concede.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) v_u_1106
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.WarOverFrame.PeaceFrame.Mode.Value = "Concede"
	v_u_1106 = {}
end)
MainFrame.WarOverFrame.PeaceFrame.Send.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) v_u_1106
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if MainFrame.WarOverFrame.PeaceFrame.Send.Text == "Send Terms" then
		MainFrame.WarOverFrame.PeaceFrame.Send.Text = "Are you sure?"
		wait(5)
		MainFrame.WarOverFrame.PeaceFrame.Send.Text = "Send Terms"
	else
		workspace.GameManager.ManageAlliance:FireServer(
			MainFrame.WarOverFrame.PeaceFrame.Target.Value,
			"PeaceOut",
			{ MainFrame.WarOverFrame.CurrentWar.Value, MainFrame.WarOverFrame.PeaceFrame.Mode.Value, v_u_1106 }
		)
		Disengage()
	end
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountry, (copy) SetFlag, (copy) MakeMouseOver, (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect, (ref) tags, (ref) v_u_10, (ref) Units, (copy) ReferenceTable, (ref) currentCountryData, (ref) v_u_1106, (copy) allTerms, (ref) v_u_246, (copy) ClearList
	if MainFrame.WarOverFrame.Visible then
		local frameWar = workspace.Wars:FindFirstChild(MainFrame.WarOverFrame.CurrentWar.Value)
		local currentCountryWar = frameWar and frameWar:FindFirstChild(currentCountry, true)
		if currentCountryWar then
			local Team = currentCountryWar.Parent
			local oppositeTeam
			if currentCountryWar.Parent.Name == "Attacker" then
				oppositeTeam = frameWar.Defender
			else
				oppositeTeam = frameWar.Attacker
			end
			if currentCountryWar.Value == "WarLeader" then
				MainFrame.WarOverFrame.OverallFrame.Add.Visible = true
			else
				MainFrame.WarOverFrame.OverallFrame.Add.Visible = false
			end
			MainFrame.WarOverFrame.OverallFrame.Title.Text = frameWar.Name
			MainFrame.WarOverFrame.OverallFrame.Date.Text = "Started " .. frameWar.Date.Value
			MainFrame.WarOverFrame.OverallFrame.Goal.Text = "Wargoal: " .. frameWar.Wargoal.Value
			local function FlagList(frame, countries)
				-- upvalues: (ref) MainFrame, (ref) SetFlag, (ref) MakeMouseOver, (ref) Assets, (ref) GameGui, (ref) CenterFrameSelect, (ref) tags, (ref) v_u_10
				for i, v in pairs(frame:GetChildren()) do
					if v.Name ~= "List" then
						if v.Name ~= "UIPadding" then
							local name = v.Name
							local found = false
							for i, v2 in pairs(countries) do
								if v2.Name == name then
									found = true
									break
								end
							end
							if not found then
								v:Destroy()
							end
						end
					end
				end
				for i, v in pairs(countries) do
					if frame:FindFirstChild(v.Name) then
						if v_u_10 % 2 == 0 then
							local currentCitiesCount = #workspace.Baseplate.Cities[v.Name]:GetChildren()
							local allCitiesCount = require(workspace.FunctionDump.ValueCalc.GetCities).Total(v.Name)
							if 0 < workspace.CountryData[v.Name].Population.Value then
								if 0.1 <= currentCitiesCount / allCitiesCount then
									frame[v.Name].CName.TextColor3 = Color3.fromRGB(255, 255, 255)
								else
									frame[v.Name].CName.TextColor3 = Color3.fromRGB(155, 155, 0)
								end
							else
								frame[v.Name].CName.TextColor3 = Color3.fromRGB(152, 45, 45)
							end
							frame[v.Name].Flag:SetAttribute(
								"MouseOverText",
								v.Name
									.. "\nCities Left: "
									.. currentCitiesCount
									.. " / "
									.. allCitiesCount
									.. " - "
									.. math.ceil(currentCitiesCount / allCitiesCount * 100 * 100) / 100
									.. "%"
							)
						end
					else
						local frame = MainFrame.WarOverFrame.OverallFrame.AFrame.List.Sample:Clone()
						SetFlag(frame.Flag, v.Name)
						frame.CName.Text = v.Name
						frame.Name = v.Name
						if v.Value == "WarLeader" then
							frame.Flag.Leader.Visible = true
							frame.LayoutOrder = 0
						end
						frame.Parent = frame
						MakeMouseOver(frame.Flag, frame.Name, 14)
						frame.Flag.MouseButton1Click:Connect(function()
							-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (copy) frame, (ref) CenterFrameSelect
							local clickSound = Assets.Audio.Click_2:Clone()
							clickSound.Parent = GameGui
							clickSound:Play()
							game.Debris:AddItem(clickSound, 15)
							Disengage()
							MainFrame.CenterFrame.DiplomacyFrame.Country.Value = frame.Name
							CenterFrameSelect("DiplomacyFrame")
						end)
						frame.View.MouseButton1Click:Connect(function()
							-- upvalues: (ref) Assets, (ref) GameGui, (copy) countries, (copy) v_u_1165, (ref) tags
							local clickSound = Assets.Audio.Click_2:Clone()
							clickSound.Parent = GameGui
							clickSound:Play()
							game.Debris:AddItem(clickSound, 15)
							Disengage()
							for i, city in pairs(workspace.Baseplate.Cities[v.Name]:GetChildren()) do
								local ownershipTag = script.OwnershipTag:Clone()
								ownershipTag.Adornee = city
								ownershipTag.Img.ImageColor3 = Color3.new(1, 1, 1)
								ownershipTag.Parent = city
								table.insert(tags, ownershipTag)
							end
						end)
					end
				end
			end
			FlagList(MainFrame.WarOverFrame.OverallFrame.AFrame, Team:GetChildren())
			FlagList(MainFrame.WarOverFrame.OverallFrame.BFrame, oppositeTeam:GetChildren())
			local ourTeamMillitary = Vector3.new()
			local oppositeTeamMillitary = Vector3.new()
			local ourTeamTable = {}
			local oppositeTeamTable = {}
			local unitsRef = Units
			for i, unit in pairs(unitsRef) do
				local unitOwner = unit.Owner.Value
				local unitAmount = Vector3.new()
				if unit.Type.Value == "Infantry" then
					unitAmount = unitAmount + Vector3.new(unit.Current.Value, 0, 0)
				elseif unit.Type.Value == "Tank" then
					unitAmount = unitAmount + Vector3.new(0, unit.Current.Value, 0)
				elseif unit.Stats.TransverseType.Value == "Naval" then
					unitAmount = unitAmount
						+ Vector3.new(0, 0, (math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)))
				end
				local isFound = false
				for i, child in pairs(Team:GetChildren()) do
					if child.Name == unitOwner then
						isFound = true
						break
					end
				end
				if isFound then
					ourTeamMillitary = ourTeamMillitary + unitAmount
					if ourTeamTable[unit.Type.Value] == nil then
						ourTeamTable[unit.Type.Value] = 0
					end
					if unit.Stats.TransverseType.Value == "Naval" or unit.Stats.TransverseType.Value == "Air" then
						local unitType = unit.Type.Value
						ourTeamTable[unitType] = ourTeamTable[unitType]
							+ math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
					else
						local unitType = unit.Type.Value
						ourTeamTable[unitType] = ourTeamTable[unitType] + unit.Current.Value
					end
				else
					local isFound = false
					for i, country in pairs(oppositeTeam:GetChildren()) do
						if country.Name == unitOwner then
							isFound = true
							break
						end
					end
					if isFound then
						if unit.Type.Value ~= "Submarine" then
							oppositeTeamMillitary = oppositeTeamMillitary + unitAmount
							if oppositeTeamTable[unit.Type.Value] == nil then
								oppositeTeamTable[unit.Type.Value] = 0
							end
							if
								unit.Stats.TransverseType.Value == "Naval"
								or unit.Stats.TransverseType.Value == "Air"
							then
								local unitType = unit.Type.Value
								oppositeTeamTable[unitType] = oppositeTeamTable[unitType]
									+ math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
							else
								local unitType = unit.Type.Value
								oppositeTeamTable[unitType] = oppositeTeamTable[unitType] + unit.Current.Value
							end
						end
					end
				end
			end
			local troopsMillions, troopsThousands, troopsHundrends =
				tostring(ourTeamMillitary.X):match("(%-?%d?)(%d*)(%.?.*)")
			local troops = troopsMillions
				.. troopsThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. troopsHundrends
			local tanksMillions, tanksThousands, tanksHundrends =
				tostring(ourTeamMillitary.Y):match("(%-?%d?)(%d*)(%.?.*)")
			local tanks = tanksMillions .. tanksThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse() .. tanksHundrends
			local shipsMillions, shipsThousands, shipsHundrends =
				tostring(ourTeamMillitary.Z):match("(%-?%d?)(%d*)(%.?.*)")
			MainFrame.WarOverFrame.OverallFrame.AStats.Count.Text = "Troops: "
				.. troops
				.. "  Tanks: "
				.. tanks
				.. "  Ships: "
				.. shipsMillions
				.. shipsThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. shipsHundrends
			local troopsMillions2, troopsThousands2, troopsHundrends2 =
				tostring(oppositeTeamMillitary.X):match("(%-?%d?)(%d*)(%.?.*)")
			local troops2 = troopsMillions2
				.. troopsThousands2:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. troopsHundrends2
			local tanksMillions2, tanksThousands2, tanksHundrends2 =
				tostring(oppositeTeamMillitary.Y):match("(%-?%d?)(%d*)(%.?.*)")
			local tanks2 = tanksMillions2
				.. tanksThousands2:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. tanksHundrends2
			local shipsMillions2, shipsThousands2, shipsHundrends2 =
				tostring(oppositeTeamMillitary.Z):match("(%-?%d?)(%d*)(%.?.*)")
			MainFrame.WarOverFrame.OverallFrame.BStats.Count.Text = "Troops: "
				.. troops2
				.. "  Tanks: "
				.. tanks2
				.. "  Ships: "
				.. shipsMillions2
				.. shipsThousands2:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. shipsHundrends2
			local militaryComposition = "Military Composition:\n \n"
			for unitType, amount in pairs(ourTeamTable) do
				local millions, thousands, hundrends = tostring(amount):match("(%-?%d?)(%d*)(%.?.*)")
				militaryComposition = militaryComposition
					.. unitType
					.. ": "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. millions
					.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. hundrends
					.. "</font>"
					.. "\n"
			end
			MainFrame.WarOverFrame.OverallFrame.AStats.Count.MouseOverText.Value = militaryComposition
			local militaryComposition2 = "Military Composition:\n \n"
			for unitType, amount in pairs(oppositeTeamTable) do
				local millions, thousands, hundrends = tostring(amount):match("(%-?%d?)(%d*)(%.?.*)")
				militaryComposition2 = militaryComposition2
					.. unitType
					.. ": "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. millions
					.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. hundrends
					.. "</font>"
					.. "\n"
			end
			MainFrame.WarOverFrame.OverallFrame.BStats.Count.MouseOverText.Value = militaryComposition2
			local oppositeTeamLosses = 0
			local ourTeamLosses = 0
			for i, country in pairs(Team:GetChildren()) do
				ourTeamLosses = ourTeamLosses + country.Losses.Value
			end
			for i, country in pairs(oppositeTeam:GetChildren()) do
				oppositeTeamLosses = oppositeTeamLosses + country.Losses.Value
			end
			local lossesMillions, lossesThousands, lossesHundrends =
				tostring(ourTeamLosses):match("(%-?%d?)(%d*)(%.?.*)")
			MainFrame.WarOverFrame.OverallFrame.AStats.Death.Text = "Losses: "
				.. lossesMillions
				.. lossesThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. lossesHundrends
			local lossesMillions2, lossesThousands2, lossesHundrends2 =
				tostring(oppositeTeamLosses):match("(%-?%d?)(%d*)(%.?.*)")
			MainFrame.WarOverFrame.OverallFrame.BStats.Death.Text = "Losses: "
				.. lossesMillions2
				.. lossesThousands2:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. lossesHundrends2
			local function FlagList2(frame, countries)
				-- upvalues: (ref) MainFrame, (ref) SetFlag, (ref) MakeMouseOver, (copy) currentCountryWar, (ref) currentCountryData, (copy) frameWar, (copy) Team, (ref) currentCountry, (ref) oppositeTeam, (ref) Assets, (ref) GameGui, (ref) v_u_1106
				for i, v in pairs(frame:GetChildren()) do
					if v.Name ~= "List" then
						if v.Name ~= "UIPadding" then
							local name = v.Name
							local found = false
							for i2, v2 in pairs(countries) do
								if v2.Name == name then
									found = true
									break
								end
							end
							if not found then
								v:Destroy()
							end
						end
					end
				end
				for i, v in pairs(countries) do
					if not frame:FindFirstChild(v.Name) then
						local flag = MainFrame.WarOverFrame.PeaceFrame.AFrame.List.Flag:Clone()
						SetFlag(flag, v.Name)
						flag.Name = v.Name
						if v.Value == "WarLeader" then
							flag.Leader.Visible = true
							flag.LayoutOrder = 0
						end
						flag.Parent = frame
						MakeMouseOver(flag, flag.Name, 16)
						local canView = true
						if currentCountryWar.Value ~= "WarLeader" then
							if v.Value ~= "WarLeader" then
								canView = false
							end
						end
						if frame.Name ~= "BFrame" then
							canView = false
						end
						if
							require(workspace.FunctionDump.DiplomacyStatus).GetPuppet(v.Name)
							or require(workspace.FunctionDump.DiplomacyStatus).GetPuppet(currentCountryData.Name)
						then
							canView = false
						end
						local warLeader = require(workspace.FunctionDump.DiplomacyStatus).GetWarLeader(
							frameWar.Name,
							Team.Name,
							currentCountry
						)[1]
						if currentCountry ~= warLeader then
							if workspace.Factions:FindFirstChild(currentCountry, true) then
								if workspace.Factions:FindFirstChild(warLeader, true) then
									if
										workspace.Factions:FindFirstChild(currentCountry, true).Parent
										== workspace.Factions:FindFirstChild(warLeader, true).Parent
									then
										if workspace.Factions:FindFirstChild(warLeader, true).Value == "Leader" then
											canView = false
										end
									end
								end
							end
						end
						if workspace.Factions:FindFirstChild(currentCountry, true) then
							if workspace.Factions:FindFirstChild(v.Name, true) then
								if workspace.Factions:FindFirstChild(v.Name, true).Value ~= "Leader" then
									if
										oppositeTeam:FindFirstChild(
											require(workspace.FunctionDump.DiplomacyStatus).GetFactionLeader(
												nil,
												v.Name
											)
										)
									then
										canView = false
									end
								end
							end
						end
						if not canView and frame.Name == "BFrame" then
							flag.CanTarget.Visible = true
						end
						if canView then
							flag.MouseButton1Click:Connect(function()
								-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (copy) flag, (ref) v_u_1106
								local clickSound = Assets.Audio.Click_2:Clone()
								clickSound.Parent = GameGui
								clickSound:Play()
								game.Debris:AddItem(clickSound, 15)
								MainFrame.WarOverFrame.PeaceFrame.Target.Value = flag.Name
								v_u_1106 = {}
							end)
						end
					end
				end
			end
			MainFrame.WarOverFrame.PeaceFrame.Title.Text = frameWar.Name
			FlagList2(MainFrame.WarOverFrame.PeaceFrame.AFrame, Team:GetChildren())
			FlagList2(MainFrame.WarOverFrame.PeaceFrame.BFrame, oppositeTeam:GetChildren())
			local peaceTarget = MainFrame.WarOverFrame.PeaceFrame.Target.Value
			local peaceActualTarget = MainFrame.WarOverFrame.PeaceFrame.Target:GetAttribute("ActualTarget")
			MainFrame.WarOverFrame.PeaceFrame.Concede.Status.Visible = MainFrame.WarOverFrame.PeaceFrame.Mode.Value
				== "Concede"
			MainFrame.WarOverFrame.PeaceFrame.Demand.Status.Visible = MainFrame.WarOverFrame.PeaceFrame.Mode.Value
				== "Demand"
			for i, term in pairs(allTerms) do
				MainFrame.WarOverFrame.PeaceFrame.TermsFrame[term].Status.BackgroundColor3 =
					Color3.fromRGB(255, 121, 121)
				for i, child in pairs(MainFrame.WarOverFrame.PeaceFrame.TermsFrame[term]:GetChildren()) do
					if child:GetAttribute("IncrementTab") then
						local choices =
							require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).TermChoices(term, child.Name)
						child.Label.Text = choices[1][child:GetAttribute("Choice")] .. choices[2]
					end
				end
			end
			for term, _ in pairs(v_u_1106) do
				local termFrame = MainFrame.WarOverFrame.PeaceFrame.TermsFrame[term]
				termFrame.Status.BackgroundColor3 = Color3.fromRGB(149, 255, 116)
				v_u_1106[term] = {}
				local choices = require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).TermChoices(term)
				if choices then
					for v1261, v1262 in pairs(choices) do
						v_u_1106[term][v1261] = v1262[1][termFrame[v1261]:GetAttribute("Choice")]
					end
				end
			end
			if v_u_1106.AnnexSome then
				MainFrame.WarOverFrame.PeaceFrame.TermsFrame.AnnexSome.Select.Visible = true
				for i, v in pairs(v_u_246) do
					table.insert(v_u_1106.AnnexSome, v)
				end
			else
				v_u_246 = {}
				MainFrame.WarOverFrame.PeaceFrame.TermsFrame.AnnexSome.Select.Visible = false
			end
			if v_u_1106.Liberate then
				local liberate = MainFrame.WarOverFrame.PeaceFrame.TermsFrame.Liberate
				if liberate.Countries:GetAttribute("Setup") then
					for i, child in pairs(liberate.Countries:GetChildren()) do
						if child:IsA("TextButton") then
							if child:GetAttribute("Selected") then
								child.Status.BackgroundColor3 = Color3.fromRGB(149, 255, 116)
								table.insert(v_u_1106.Liberate, child.Name)
							else
								child.Status.BackgroundColor3 = Color3.fromRGB(255, 121, 121)
							end
						end
					end
				else
					ClearList(liberate.Countries.List)
					local target
					if MainFrame.WarOverFrame.PeaceFrame.Mode.Value == "Concede" then
						target = peaceTarget
					else
						target = currentCountry
					end
					for country, _ in
						pairs(
							require(workspace.FunctionDump.ValueCalc.GetCities).Composition(
								peaceActualTarget,
								true,
								target
							)
						)
					do
						if country ~= peaceActualTarget then
							local frame = liberate.Countries.List.Sample:Clone()
							frame.Name = country
							SetFlag(frame.Flag, country)
							frame.CName.Text = country
							frame.MouseButton1Click:Connect(function()
								-- upvalues: (ref) Assets, (ref) GameGui, (copy) frame
								local clickSound = Assets.Audio.Click_2:Clone()
								clickSound.Parent = GameGui
								clickSound:Play()
								game.Debris:AddItem(clickSound, 15)
								if frame:GetAttribute("Selected") then
									frame:SetAttribute("Selected", false)
								else
									frame:SetAttribute("Selected", true)
								end
							end)
							frame.Parent = liberate.Countries
						end
					end
					MainFrame.WarOverFrame.PeaceFrame.TermsFrame.CanvasSize = UDim2.new(
						0,
						0,
						0,
						MainFrame.WarOverFrame.PeaceFrame.TermsFrame.List.AbsoluteContentSize.Y * 1.1
							+ liberate.Countries.List.AbsoluteContentSize.Y * 1.1
					)
					liberate.Countries:SetAttribute("Setup", true)
				end
			else
				local liberate = MainFrame.WarOverFrame.PeaceFrame.TermsFrame.Liberate
				if liberate.Countries:GetAttribute("Setup") then
					ClearList(liberate.Countries.List)
					MainFrame.WarOverFrame.PeaceFrame.TermsFrame.CanvasSize = UDim2.new(
						0,
						0,
						0,
						MainFrame.WarOverFrame.PeaceFrame.TermsFrame.List.AbsoluteContentSize.Y * 1.1
					)
					liberate.Countries:SetAttribute("Setup", false)
				end
			end
			if MainFrame.WarOverFrame.PeaceFrame.Mode.Value == "Demand" then
				MainFrame.WarOverFrame.PeaceFrame.Target:SetAttribute("ActualTarget", peaceTarget)
			else
				MainFrame.WarOverFrame.PeaceFrame.Target:SetAttribute("ActualTarget", currentCountry)
			end
			MainFrame.WarOverFrame.PeaceFrame.DescFrame.Desc.Text = peaceTarget
				.. " Peace terms\n \n"
				.. require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).Text(
					v_u_1106,
					peaceTarget,
					MainFrame.WarOverFrame.PeaceFrame.Mode.Value
				)
			MainFrame.WarOverFrame.PeaceFrame.Truce.Text = "Truce until: "
				.. require(workspace.FunctionDump.SharedFunction).FutureDate(730)
		end
	end
	local warLeaders = {}
	for i, war in pairs(workspace.Wars:GetChildren()) do
		local currentCountryWar = war:FindFirstChild(currentCountry, true)
		if currentCountryWar then
			for i, descendant in pairs(war:GetDescendants()) do
				if descendant:IsA("StringValue") then
					if descendant.Value == "WarLeader" then
						if descendant.Parent.Name ~= currentCountryWar.Parent.Name then
							table.insert(warLeaders, descendant)
							break
						end
					end
				end
			end
		end
	end
	for i, warFrame in pairs(MainFrame.StatsFrame.Stats.WarsFrame:GetChildren()) do
		if warFrame.Name ~= "List" then
			local name = warFrame.Name
			local found = false
			for i, warLeader in pairs(warLeaders) do
				if warLeader.Name == name then
					found = true
					break
				end
			end
			if not found then
				warFrame:Destroy()
			end
		end
	end
	for i, warLeader in pairs(warLeaders) do
		if not MainFrame.StatsFrame.Stats.WarsFrame:FindFirstChild(warLeader.Name) then
			local flag = MainFrame.StatsFrame.Stats.WarsFrame.List.Flag:Clone()
			SetFlag(flag, warLeader.Name)
			flag.Name = warLeader.Name
			flag.Parent = MainFrame.StatsFrame.Stats.WarsFrame
			MakeMouseOver(flag, warLeader.Parent.Parent.Name, 16)
			flag.MouseButton1Click:Connect(function()
				-- upvalues: (ref) MainFrame, (ref) Assets, (ref) GameGui, (copy) warLeaders, (copy) v_u_1283
				if not MainFrame.WarOverFrame.SelectFrame.Visible then
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					Disengage()
					MainFrame.WarOverFrame.Visible = true
					MainFrame.WarOverFrame.CurrentWar.Value = warLeader.Parent.Parent.Name
				end
			end)
		end
	end
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) selected, (copy) Assets, (copy) GameGui, (copy) DeselectObject, (copy) MakeMouseOver
	if MainFrame.UnitFrame.Visible then
		local v1286 = false
		local v1287 = false
		local v1288 = false
		local selectedTypes = {}
		for i, v in pairs(selected) do
			if not table.find(selectedTypes, v.Type.Value) then
				table.insert(selectedTypes, v.Type.Value)
			end
		end
		if #selectedTypes == 1 then
			if selectedTypes[1] == "Transport Aircraft" then
				v1287 = true
				v1288 = true
			end
		end
		local selectedTypes2 = #selectedTypes <= 1 and {} or selectedTypes
		for i, v in pairs(MainFrame.UnitFrame.Main.Selection:GetChildren()) do
			if not table.find(selectedTypes2, v.Name) then
				if v.Name ~= "List" then
					v:Destroy()
				end
			end
		end
		for i, v in pairs(selectedTypes2) do
			if 1 <= #selectedTypes2 then
				if v == "Transport Aircraft" then
					v1286 = not v1287 and true or v1286
				end
			end
			v1288 = v == "Transport Aircraft" and true or v1288
			if not MainFrame.UnitFrame.Main.Selection:FindFirstChild(v) then
				local button = MainFrame.UnitFrame.Main.Selection.List.Sample:Clone()
				button.Name = v
				button.Text = "Select " .. v .. " Only"
				button.Parent = MainFrame.UnitFrame.Main.Selection
				button.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) selected, (ref) selectedTypes2, (copy) i, (ref) DeselectObject
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					GameGui.MouseOver.Visible = false
					local i = 1
					while i <= #selected do
						if v.Type.Value ~= v then
							DeselectObject(v)
							i = 0
						end
						i = i + 1
					end
					print("End")
				end)
				MakeMouseOver(button, "Right Click to remove unit type from selection", 14, 160)
				button.MouseButton2Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) selected, (ref) selectedTypes2, (copy) i, (ref) DeselectObject
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					GameGui.MouseOver.Visible = false
					local i = 1
					while i <= #selected do
						if v.Type.Value == v then
							DeselectObject(v)
							i = 0
						end
						i = i + 1
					end
					print("End")
				end)
			end
		end
		MainFrame.UnitFrame.Main.ViewTransport.Visible = v1288
		MainFrame.UnitFrame.Main.LoadTransport.Visible = v1286
		MainFrame.UnitFrame.Main.UnloadTransport.Visible = v1287
		MainFrame.UnitFrame.Main.Selection.CanvasSize =
			UDim2.new(0, 0, 0, MainFrame.UnitFrame.Main.Selection.List.AbsoluteContentSize.Y * 1.1)
	end
end)
local unitSearch = script.SearchSample:Clone()
unitSearch.Parent = MainFrame.UnitFrame.CountryList
local unitSearchBox = unitSearch.Box
local unitCountryList = MainFrame.UnitFrame.CountryList
unitSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) unitCountryList, (copy) unitSearchBox
	for i, country in pairs(unitCountryList:GetChildren()) do
		if country:IsA("GuiBase") then
			if country ~= unitSearchBox.Parent then
				if string.match(string.lower(country.Name), string.lower(unitSearchBox.Text)) == nil then
					country.Visible = false
				else
					country.Visible = true
				end
			end
		end
	end
end)
MainFrame.UnitFrame.Main.Cap.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) ClearList, (copy) MainFrame, (ref) mouseInteractionType, (ref) selected, (ref) currentCountryData, (copy) MakeMouseOver
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	ClearList(
		MainFrame.UnitFrame.CountryList.List,
		{ MainFrame.UnitFrame.CountryList.CloseParent, MainFrame.UnitFrame.CountryList.SearchSample }
	)
	local autocaptureActions = {
		{ "Recapture", "Recapture Cities" },
		{ "UnrestrictedConquest", "Capture All" },
	}
	for i, action in pairs(autocaptureActions) do
		local button = MainFrame.UnitFrame.CountryList.List.Sample:Clone()
		button.LayoutOrder = 0
		button.Name = action[2]
		button.Text = action[2]
		button.Parent = MainFrame.UnitFrame.CountryList
		button.MouseButton1Click:Connect(function()
			-- upvalues: (ref) Assets, (ref) GameGui, (ref) mouseInteractionType, (ref) selected, (copy) autocaptureActions, (copy) v_u_1307
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			if mouseInteractionType == "MoveUnit" then
				workspace.GameManager.IssueUnitOrder:FireServer(selected, "Capture", { action[1] })
				Disengage()
			end
		end)
	end
	for i, country in pairs(workspace.Baseplate.Cities:GetChildren()) do
		if
			require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
				currentCountryData.Name,
				country.Name,
				"Against"
			)
		then
			local button = MainFrame.UnitFrame.CountryList.List.Sample:Clone()
			button.Name = country.Name
			button.Text = country.Name
			button.Parent = MainFrame.UnitFrame.CountryList
			button.MouseButton1Click:Connect(function()
				-- upvalues: (ref) Assets, (ref) GameGui, (ref) mouseInteractionType, (ref) selected, (copy) v_u_1310, (copy) v_u_1311
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				if mouseInteractionType == "MoveUnit" then
					workspace.GameManager.IssueUnitOrder:FireServer(selected, "Capture", { country.Name })
					Disengage()
				end
			end)
			local countryCities = require(workspace.FunctionDump.ValueCalc.GetCities).Composition(country.Name, false)
			local countriesOwned = 0
			for country, _ in pairs(countryCities) do
				if country ~= country.Name then
					countriesOwned = countriesOwned + 1
				end
			end
			if 0 < countriesOwned then
				MakeMouseOver(button, "Right click to further subdivide by country\nCountries: " .. countriesOwned, 14)
				button.MouseButton2Click:Connect(function()
					-- upvalues: (ref) GameGui, (ref) Assets, (ref) ClearList, (ref) MainFrame, (copy) countryCities, (copy) v_u_1310, (copy) v_u_1311, (ref) mouseInteractionType, (ref) selected
					GameGui.MouseOver.Visible = false
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					ClearList(
						MainFrame.UnitFrame.CountryList.List,
						{ MainFrame.UnitFrame.CountryList.CloseParent, MainFrame.UnitFrame.CountryList.SearchSample }
					)
					for country, _ in pairs(countryCities) do
						local button = MainFrame.UnitFrame.CountryList.List.Sample:Clone()
						button.Name = country
						button.Text = country.Name .. ": " .. country
						button.Parent = MainFrame.UnitFrame.CountryList
						button.MouseButton1Click:Connect(function()
							-- upvalues: (ref) Assets, (ref) GameGui, (ref) mouseInteractionType, (ref) selected, (ref) v_u_1310, (ref) v_u_1311, (copy) country
							local clickSound = Assets.Audio.Click_2:Clone()
							clickSound.Parent = GameGui
							clickSound:Play()
							game.Debris:AddItem(clickSound, 15)
							if mouseInteractionType == "MoveUnit" then
								workspace.GameManager.IssueUnitOrder:FireServer(
									selected,
									"Capture",
									{ country.Name, country }
								)
								Disengage()
							end
						end)
					end
				end)
			end
		end
	end
	MainFrame.UnitFrame.CountryList.Visible = true
end)
MainFrame.UnitFrame.Main.Halt.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "Halt")
	end
end)
MainFrame.UnitFrame.Main.Split.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "Split")
		Disengage()
	end
end)
MainFrame.UnitFrame.Main.Line.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		local frontPoints = {}
		for i, child in pairs(workspace:GetChildren()) do
			if child.Name == "Ha" then
				for i, v in pairs(child:GetChildren()) do
					table.insert(frontPoints, v.Position)
				end
			end
		end
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "Frontline", frontPoints)
		Disengage()
	end
end)
MainFrame.UnitFrame.Main.Title.Focused:Connect(function()
	-- upvalues: (copy) MainFrame
	MainFrame.UnitFrame.Main.Title.Active = false
end)
MainFrame.UnitFrame.Main.Title.FocusLost:Connect(function()
	-- upvalues: (copy) MainFrame, (ref) mouseInteractionType, (ref) selected
	MainFrame.UnitFrame.Main.Title.Active = true
	if mouseInteractionType == "MoveUnit" and #selected == 1 then
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "Rename", MainFrame.UnitFrame.Main.Title.Text)
	end
end)
MainFrame.UnitFrame.Main.Merge.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		workspace.GameManager.IssueUnitOrder:FireServer(
			selected,
			"ToggleMerge",
			MainFrame.UnitFrame.Main.Merge.Text ~= "Auto Merge: On"
		)
	end
end)
MainFrame.UnitFrame.Main.Reinforce.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		workspace.GameManager.IssueUnitOrder:FireServer(
			selected,
			"ToggleReinforce",
			MainFrame.UnitFrame.Main.Reinforce.Text ~= "Reinforcements: On"
		)
	end
end)
MakeMouseOver(MainFrame.UnitFrame.Main.Train, "Right Click to toggle advanced training", 14)
MainFrame.UnitFrame.Main.Train.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame, (ref) isMobile, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		local isNotTraining = MainFrame.UnitFrame.Main.Train.Text ~= "Stop Training"
		if not isMobile then
			workspace.GameManager.IssueUnitOrder:FireServer(selected, "Train", isNotTraining)
			return
		end
		if not MainFrame.UnitFrame.TrainingList.Visible then
			MainFrame.UnitFrame.TrainingList.Visible = true
			return
		end
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "Train", isNotTraining)
	end
end)
for i, biome in pairs(Assets.Mechanics.BiomeTraining:GetChildren()) do
	local button = MainFrame.UnitFrame.TrainingList.List.Sample:Clone()
	button.Name = biome.Name
	button.Text = biome.Name .. " Specialization"
	button.Parent = MainFrame.UnitFrame.TrainingList
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected, (copy) v_u_1333, (copy) v_u_1334, (copy) MainFrame
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		if mouseInteractionType == "MoveUnit" then
			workspace.GameManager.IssueUnitOrder:FireServer(selected, "BiomeTraining", biome.Name)
		end
		MainFrame.UnitFrame.TrainingList.Visible = false
	end)
end
MainFrame.UnitFrame.Main.Train.MouseButton2Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		MainFrame.UnitFrame.TrainingList.Visible = not MainFrame.UnitFrame.TrainingList.Visible
	end
end)
MainFrame.UnitFrame.Main.Group.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		MainFrame.UnitFrame.GroupList.Visible = true
	end
end)
MainFrame.UnitFrame.Main.ViewSelection.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) ClearList, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		ClearList(
			MainFrame.UnitFrame.SelectedFrame.List,
			{ MainFrame.UnitFrame.SelectedFrame.CloseParent, MainFrame.UnitFrame.SelectedFrame.UIPadding }
		)
		MainFrame.UnitFrame.SelectedFrame.Visible = not MainFrame.UnitFrame.SelectedFrame.Visible
	end
end)
MainFrame.UnitFrame.Main.ViewTransport.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) ClearList, (copy) MainFrame, (ref) selected, (ref) tags
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		ClearList(
			MainFrame.UnitFrame.TransportFrame.List,
			{ MainFrame.UnitFrame.TransportFrame.CloseParent, MainFrame.UnitFrame.TransportFrame.UIPadding }
		)
		if not MainFrame.UnitFrame.TransportFrame.Visible then
			local transportingUnits = {}
			for i, v in pairs(selected) do
				if v.Stats:FindFirstChild("Transport") then
					for i2, unit in pairs(v.Stats.Transport:GetChildren()) do
						table.insert(transportingUnits, unit)
					end
				end
			end
			for i, unit in pairs(transportingUnits) do
				local frame = MainFrame.UnitFrame.TransportFrame.List.Sample:Clone()
				frame.Name = unit.Name
				frame.Focus.UnitName.Text = unit.Name
				frame.Focus.UnitType.Text = unit.Type.Value
				local millions, thousands, hundrends = tostring(unit.Current.Value):match("(%-?%d?)(%d*)(%.?.*)")
				frame.Focus.UnitNumber.Text = millions
					.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. hundrends
				frame.Focus.MouseButton1Click:Connect(function()
					-- upvalues: (ref) tags, (ref) selected, (copy) transportingUnits, (copy) i, (ref) MainFrame
					for i, tag in pairs(tags) do
						if tag.Name == "SelectTag" then
							tag:Destroy()
						end
					end
					selected = { unit.Parent.Parent.Parent }
					MainFrame.UnitFrame.TransportFrame.Visible = false
				end)
				frame.Parent = MainFrame.UnitFrame.TransportFrame
			end
			if #transportingUnits == 0 then
				MainFrame.UnitFrame.TransportFrame.Visible = true
			end
		end
		MainFrame.UnitFrame.TransportFrame.Visible = not MainFrame.UnitFrame.TransportFrame.Visible
	end
end)
MainFrame.UnitFrame.Main.LoadTransport.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		local toTransport = {}
		local transportPlane = nil
		for i, v in pairs(selected) do
			if v.Stats:FindFirstChild("Transport") then
				transportPlane = v
			else
				table.insert(toTransport, v)
			end
		end
		workspace.GameManager.IssueUnitOrder:FireServer(toTransport, "LoadOnTransport", transportPlane)
		Disengage()
	end
end)
MainFrame.UnitFrame.Main.UnloadTransport.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "UnloadTransport")
		Disengage()
	end
end)
MainFrame.UnitFrame.Main.Disband.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.UnitFrame.DisbandFrame.Visible = true
end)
MainFrame.UnitFrame.DisbandFrame.No.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.UnitFrame.DisbandFrame.Visible = false
end)
MainFrame.UnitFrame.DisbandFrame.Yes.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (ref) selected
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		workspace.GameManager.IssueUnitOrder:FireServer(selected, "Disband")
		Disengage()
	end
end)
MainFrame.UnitFrame.Main.MovementSetting.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		MainFrame.UnitFrame.MovementSettingFrame.Visible = true
		MainFrame.UnitFrame.Main.Visible = false
	end
end)
MainFrame.UnitFrame.MovementSettingFrame.HoldFormation.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		if MainFrame.UnitFrame.MovementSettingFrame.HoldFormation.Text == "Hold Formation: Off" then
			MainFrame.UnitFrame.MovementSettingFrame.HoldFormation.Text = "Hold Formation: On"
			return
		end
		MainFrame.UnitFrame.MovementSettingFrame.HoldFormation.Text = "Hold Formation: Off"
	end
end)
MainFrame.UnitFrame.MovementSettingFrame.EqualSpeed.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		if MainFrame.UnitFrame.MovementSettingFrame.EqualSpeed.Text == "Equalize Movement Speed: Off" then
			MainFrame.UnitFrame.MovementSettingFrame.EqualSpeed.Text = "Equalize Movement Speed: On"
			return
		end
		MainFrame.UnitFrame.MovementSettingFrame.EqualSpeed.Text = "Equalize Movement Speed: Off"
	end
end)
MainFrame.UnitFrame.MovementSettingFrame.Back.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) mouseInteractionType, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if mouseInteractionType == "MoveUnit" then
		MainFrame.UnitFrame.MovementSettingFrame.Visible = false
		MainFrame.UnitFrame.Main.Visible = true
	end
end)
MakeMouseOver(MainFrame.UnitFrame.Main.XP, "", 14)
MakeMouseOver(MainFrame.UnitFrame.Main.UnitComp, "", 16)
table.insert(loopFunctions, function()
	-- upvalues: (ref) mouseInteractionType, (ref) selected, (copy) Assets, (copy) ReferenceTable, (copy) MainFrame
	if mouseInteractionType == "MoveUnit" then
		local unitsAmount = {}
		for i, v in pairs(selected) do
			if unitsAmount[v.Type.Value] == nil then
				unitsAmount[v.Type.Value] = 0
			end
			if v.Stats.TransverseType.Value == "Naval" or v.Stats.TransverseType.Value == "Air" then
				local Type = v.Type.Value
				unitsAmount[Type] = unitsAmount[Type]
					+ math.ceil(v.Current.Value / Assets.UnitStats[v.Type.Value].Value.X)
			else
				local Type = v.Type.Value
				unitsAmount[Type] = unitsAmount[Type] + v.Current.Value
			end
		end
		local text = "Unit Composition:\n \n"
		for unitType, amount in pairs(unitsAmount) do
			local millions, thousands, hundrends = tostring(amount):match("(%-?%d?)(%d*)(%.?.*)")
			text = text
				.. unitType
				.. ": "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. millions
				.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. hundrends
				.. "</font>"
				.. "\n"
		end
		MainFrame.UnitFrame.Main.UnitComp.MouseOverText.Value = text
	end
end)
MakeMouseOver(MainFrame.UnitFrame.Main.Entrenchment.End, "", 14)
table.insert(loopFunctions, function()
	-- upvalues: (ref) mouseInteractionType, (copy) MainFrame, (ref) selected, (ref) v_u_10, (copy) ClearList, (copy) Assets, (ref) tags, (copy) ScaleScrollGui
	if mouseInteractionType ~= "MoveUnit" then
		MainFrame.UnitFrame.Visible = false
		return
	end
	MainFrame.UnitFrame.Visible = true
	if selected[1]:GetAttribute("AutoMerge") then
		MainFrame.UnitFrame.Main.Merge.Text = "Auto Merge: On"
	else
		MainFrame.UnitFrame.Main.Merge.Text = "Auto Merge: Off"
	end
	if selected[1]:GetAttribute("Reinforce") then
		MainFrame.UnitFrame.Main.Reinforce.Text = "Reinforcements: On"
	else
		MainFrame.UnitFrame.Main.Reinforce.Text = "Reinforcements: Off"
	end
	if selected[1].Current.Training.IsDoing.Value then
		MainFrame.UnitFrame.Main.Train.Text = "Stop Training"
	else
		MainFrame.UnitFrame.Main.Train.Text = "Start Training"
	end
	if selected[1].Current.Training:GetAttribute("BiomeTrainingOngoing") then
		MainFrame.UnitFrame.Main.Train.BiomeTraining.Size =
			UDim2.new(selected[1].Current.Training:GetAttribute("BiomeTrainingOngoing") / 120, 0, 0, 4)
	else
		MainFrame.UnitFrame.Main.Train.BiomeTraining.Size = UDim2.new(0, 0, 0, 0)
	end
	if selected[1].Stats.TransverseType.Value == "Air" then
		MainFrame.UnitFrame.Main.Endurance.Visible = true
		MainFrame.UnitFrame.Main.Endurance.End.Bar.Size = UDim2.new(selected[1].Stats.Stockpile.Value / 100, 0, 1, 0)
	else
		MainFrame.UnitFrame.Main.Endurance.Visible = false
	end
	if selected[1].Type.Value == "Infantry" or selected[1].Type.Value == "Tank" then
		MainFrame.UnitFrame.Main.Entrenchment.Visible = true
		MainFrame.UnitFrame.Main.Entrenchment.End.Bar.Size =
			UDim2.new(selected[1].Current.Entrenchment.Value / 100, 0, 1, 0)
	else
		MainFrame.UnitFrame.Main.Entrenchment.Visible = false
	end
	MainFrame.UnitFrame.Main.GroupName.Text = ""
	if MainFrame.UnitFrame.SelectedFrame.Visible and v_u_10 % 1 == 0 then
		ClearList(
			MainFrame.UnitFrame.SelectedFrame.List,
			{ MainFrame.UnitFrame.SelectedFrame.CloseParent, MainFrame.UnitFrame.SelectedFrame.UIPadding }
		)
	end
	for i, unit in pairs(selected) do
		if unit.Group.Value == nil then
			if MainFrame.UnitFrame.Main.GroupName.Text ~= "" then
				MainFrame.UnitFrame.Main.GroupName.Text = "Multiple Groups Selected"
				break
			end
		elseif unit.Group.Value:IsDescendantOf(workspace) then
			if
				MainFrame.UnitFrame.Main.GroupName.Text ~= unit.Group.Value.Name
				and MainFrame.UnitFrame.Main.GroupName.Text ~= ""
			then
				MainFrame.UnitFrame.Main.GroupName.Text = "Multiple Groups Selected"
				break
			end
			MainFrame.UnitFrame.Main.GroupName.Text = unit.Group.Value.Name
		end
		if MainFrame.UnitFrame.SelectedFrame.Visible and v_u_10 % 1 == 0 then
			local frame = MainFrame.UnitFrame.SelectedFrame.List.Sample:Clone()
			frame.Name = unit.Name
			frame.Focus.UnitName.Text = unit.Name
			frame.Focus.UnitType.Text = unit.Type.Value
			if unit.Stats.TransverseType.Value == "Naval" or unit.Stats.TransverseType.Value == "Air" then
				frame.Focus.UnitNumber.Text = math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
			else
				local millions, thousands, hundrends = tostring(unit.Current.Value):match("(%-?%d?)(%d*)(%.?.*)")
				frame.Focus.UnitNumber.Text = millions
					.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. hundrends
			end
			if unit.Current.Training:GetAttribute("BiomeTraining") then
				frame.Focus.UnitSpecialization.Text = unit.Current.Training:GetAttribute("BiomeTraining")
					.. " Specialization"
			else
				frame.Focus.UnitSpecialization.Text = ""
			end
			frame.Deselect.MouseButton1Click:Connect(function()
				-- upvalues: (ref) selected, (copy) i, (ref) MainFrame, (copy) frame
				unit.SelectTag:Destroy()
				if unit:FindFirstChild("RangeFinder") then
					unit.RangeFinder:Destroy()
				end
				table.remove(selected, i)
				if #selected == 1 then
					MainFrame.UnitFrame.SelectedFrame.Visible = false
				end
				frame:Destroy()
			end)
			frame.Focus.MouseButton1Click:Connect(function()
				-- upvalues: (ref) tags, (ref) selected, (copy) i, (ref) MainFrame
				for i, tag in pairs(tags) do
					if tag.Name == "SelectTag" or tag.Name == "RangeFinder" then
						tag:Destroy()
					end
				end
				selected = { unit }
				MainFrame.UnitFrame.SelectedFrame.Visible = false
			end)
			frame.Focus.MouseEnter:Connect(function()
				-- upvalues: (ref) selected, (copy) i
				unit.SelectTag.Count.ImageColor3 = Color3.fromRGB(247, 169, 79)
				unit.SelectTag.Size = UDim2.new(0.1, 30, 0.1, 30)
			end)
			frame.Focus.MouseLeave:Connect(function()
				-- upvalues: (ref) selected, (copy) i
				unit.SelectTag.Count.ImageColor3 = Color3.fromRGB(187, 247, 157)
				unit.SelectTag.Size = UDim2.new(0.1, 20, 0.1, 20)
			end)
			frame.Parent = MainFrame.UnitFrame.SelectedFrame
		end
		if unit.Parent == nil then
			table.remove(selected, i)
		end
	end
	if MainFrame.UnitFrame.Main.ViewSelection.Visible then
		ScaleScrollGui(MainFrame.UnitFrame.SelectedFrame.List, "Y")
	end
	if 1 < #selected then
		MainFrame.UnitFrame.Main.Title.Text = #selected .. " Units selected"
		MainFrame.UnitFrame.Main.ViewSelection.Visible = true
	else
		MainFrame.UnitFrame.Main.ViewSelection.Visible = false
		if MainFrame.UnitFrame.Main.Title.Active then
			MainFrame.UnitFrame.Main.Title.Text = selected[1].Name
		end
	end
	MainFrame.UnitFrame.Main.XP.Bar.Size = UDim2.new(selected[1].Current.Training.Value / 300, 0, 1, 0)
end)
wait()
workspace.GameManager.SideAlertPopup.OnClientEvent:Connect(function(text, color, aliveTime)
	-- upvalues: (copy) MainFrame
	coroutine.resume(coroutine.create(function()
		-- upvalues: (ref) MainFrame, (copy) text, (copy) color, (copy) aliveTime
		local textLabel = MainFrame.RightFrame.Notifications.UIListLayout.MSG:Clone()
		textLabel.Text = text
		textLabel.TextColor3 = color
		textLabel.Parent = MainFrame.RightFrame.Notifications
		wait(aliveTime)
		game:GetService("TweenService")
			:Create(textLabel, TweenInfo.new(3, Enum.EasingStyle.Linear), {
				["TextStrokeTransparency"] = 1,
				["TextTransparency"] = 1,
			})
			:Play()
		wait(3.1)
		textLabel:Destroy()
	end))
end)
workspace.GameManager.ChangeTag.OnClientEvent:Connect(function(currentCountryName, newCountryName)
	-- upvalues: (copy) MainFrame, (ref) currentCountry, (copy) SetFlag, (ref) currentCountryData
	for i, descendant in pairs(MainFrame:GetDescendants()) do
		if descendant:IsA("TextButton") then
			if descendant.Name == currentCountryName then
				descendant.Name = newCountryName
				descendant.Text = newCountryName
			end
		end
	end
	if currentCountry == currentCountryName then
		currentCountry = newCountryName
		Disengage()
		MainFrame.StatsFrame.Stats.CountryName.Text = currentCountry
		MainFrame.CenterFrame.DiplomacyFrame.Country.Value = currentCountry
		SetFlag(MainFrame.StatsFrame.Flag, currentCountry)
		MainFrame.ProfileFrame.List[newCountryName].CountryListFrame[string.sub(
			currentCountryData.OriginalTag.Value,
			1,
			#currentCountryData.OriginalTag.Value - 1
		)].Check.Visible =
			true
	end
end)
workspace.CountryManager.NewCountry.OnClientEvent:Connect(function(countryName)
	-- upvalues: (copy) framesWithButtons, (copy) SetFlag, (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) selected
	for i, frame in pairs(framesWithButtons) do
		if not frame:FindFirstChild(countryName) then
			local button = frame:GetChildren()[4]:Clone()
			button.Name = countryName
			button.Text = countryName
			if button:FindFirstChild("Flag") then
				SetFlag(button.Flag, countryName)
			end
			button.Parent = frame
			button.MouseButton1Click:Connect(function()
				-- upvalues: (ref) Assets, (ref) GameGui, (ref) framesWithButtons, (copy) i, (ref) MainFrame, (copy) button, (ref) selected
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				if frame == MainFrame.CenterFrame.DiplomacyFrame.Main.CountryList then
					MainFrame.CenterFrame.DiplomacyFrame.Country.Value = button.Name
				elseif frame == MainFrame.CityFrame.CanalFrame.WhiteList then
					if button.Parent.Name == "WhiteList" then
						button.Parent = MainFrame.CityFrame.CanalFrame.BlackList
						workspace.GameManager.ChangeCanal:FireServer(selected[1], "Block", button.Name)
						return
					end
					button.Parent = MainFrame.CityFrame.CanalFrame.WhiteList
					workspace.GameManager.ChangeCanal:FireServer(selected[1], "Allow", button.Name)
				end
			end)
		end
	end
end)
workspace.GameManager.DisablePlayer.OnClientEvent:Connect(function()
	for i, part in pairs(workspace.Baseplate.Parts:GetChildren()) do
		part:ClearAllChildren()
	end
	script.Disabled = true
end)
local Technology = Assets.Technology:GetChildren()
for i, tech in pairs(Technology) do
	local frame = MainFrame.CenterFrame.TechnologyFrame.Main.Dragger.Sample:Clone()
	frame.Position = UDim2.new(0.5, -tech.Position.X * 40, 0.5, -tech.Position.Z * 20)
	frame.Name = tech.Name
	frame.Title.Text = tech.Title.Value
	frame.Parent = MainFrame.CenterFrame.TechnologyFrame.Main.Dragger
	local requirementText = ""
	for i, requirement in pairs(tech.Requirement:GetChildren()) do
		local requirementTech = Assets.Technology[requirement.Name]
		local vector1 = (tech.Position.X - requirementTech.Position.X) * 40
		local vector2 = (tech.Position.Z - requirementTech.Position.Z) * 20
		local line = frame.Line:Clone()
		line.Position = UDim2.new(0.5, frame.Position.X.Offset + vector1, 0.5, frame.Position.Y.Offset + vector2 / 2)
		line.Size = UDim2.new(0, 10, 0, vector2 + 10)
		line.Parent = MainFrame.CenterFrame.TechnologyFrame.Main.Dragger
		if 0 < math.abs(vector1) then
			local line = line:Clone()
			line.Position = UDim2.new(0.5, frame.Position.X.Offset + vector1 * 0.5, 0.5, frame.Position.Y.Offset)
			line.Size = UDim2.new(0, math.abs(vector1) + 10, 0, 10)
			line.Parent = MainFrame.CenterFrame.TechnologyFrame.Main.Dragger
		end
		requirementText = requirementText
			.. '<font color="rgb('
			.. ReferenceTable.Colors.Gold[1]
			.. ')">'
			.. ">"
			.. requirementTech.Title.Value
			.. "\n"
			.. "</font>"
	end
	local text = requirementText .. "\nEffects:\n"
	local effects = tech.Effect:GetChildren()
	if #effects == 0 then
		text = text .. "Theoretical Prerequiste"
	else
		for i, effect in pairs(effects) do
			if effect:IsA("NumberValue") then
				text = text
					.. effect.Name
					.. ": "
					.. (effect.Value < 0 and "" or "+")
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. math.ceil(effect.Value * 100 * 100) / 100
					.. "%\n"
					.. "</font>"
			elseif effect:IsA("IntValue") then
				text = text
					.. effect.Name
					.. ": "
					.. (effect.Value < 0 and "" or "+")
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. math.ceil(effect.Value * 100000) / 100000
					.. "\n"
					.. "</font>"
			elseif effect:IsA("Vector3Value") then
				if effect.Value.X ~= 0 then
					text = text
						.. effect.Name
						.. " Attack: "
						.. (effect.Value.X < 0 and "" or "+")
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Gold[1]
						.. ')">'
						.. math.ceil(effect.Value.X * 100)
						.. "%\n"
						.. "</font>"
				end
				if effect.Value.Y ~= 0 then
					text = text
						.. effect.Name
						.. " Defense: "
						.. (effect.Value.Y < 0 and "" or "+")
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Gold[1]
						.. ')">'
						.. math.ceil(effect.Value.Y * 100)
						.. "%\n"
						.. "</font>"
				end
				if effect.Value.Z ~= 0 then
					text = text
						.. effect.Name
						.. " Mobility: "
						.. (effect.Value.Z < 0 and "" or "+")
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Gold[1]
						.. ')">'
						.. math.ceil(effect.Value.Z * 100)
						.. "%\n"
						.. "</font>"
				end
			end
		end
	end
	MakeMouseOver(
		frame,
		'<font color="rgb('
			.. ReferenceTable.Colors.Gold[1]
			.. ')">'
			.. tech.Title.Value
			.. "</font>"
			.. "\n \n"
			.. tech.Description.Value
			.. "\n \nRequires "
			.. '<font color="rgb('
			.. ReferenceTable.Colors.LightBlue[1]
			.. ')">'
			.. tech.Cost.Value
			.. "</font>"
			.. " Research Power\n"
			.. text,
		14,
		300
	)
	frame.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Technology, (copy) i, (copy) Assets, (copy) GameGui
		workspace.GameManager.ChangeLaw:FireServer("Research", tech)
		local clickSound = Assets.Audio.Click:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
	end)
	frame.MouseButton2Click:Connect(function()
		-- upvalues: (copy) frame, (copy) Assets, (copy) GameGui
		frame.Ignore.Visible = not frame.Ignore.Visible
		local clickSound = Assets.Audio.Click:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
	end)
end
for i, child in pairs(MainFrame.CenterFrame.TechnologyFrame.QuickFrame:GetChildren()) do
	if child:IsA("TextButton") then
		child.MouseButton1Click:Connect(function()
			-- upvalues: (copy) MainFrame, (copy) i, (copy) Assets, (copy) GameGui
			local pos = MainFrame.CenterFrame.TechnologyFrame.Main.Dragger[child.Name].Position
			MainFrame.CenterFrame.TechnologyFrame.Main.Dragger.Position =
				UDim2.new(0.5, -pos.X.Offset * 0.8, 0.5, -pos.Y.Offset * 0.8)
			local clickSound = Assets.Audio.Click:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
		end)
	end
end
MainFrame.CenterFrame.TechnologyFrame.Main.Dragger.Sample:Destroy()
MakeMouseOver(MainFrame.CenterFrame.TechnologyFrame.Power, "", 14)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (ref) currentCountryData, (copy) Technology
	MainFrame.CenterFrame.TechnologyFrame.Power.Text = math.floor(currentCountryData.Power.Research.Value)
	for i, tech in pairs(Technology) do
		if currentCountryData.Technology.Slots:FindFirstChild(tech.Name) then
			MainFrame.CenterFrame.TechnologyFrame.Main.Dragger[tech.Name].Status.BackgroundColor3 =
				Color3.fromRGB(133, 255, 80)
		else
			local canBuy = currentCountryData.Power.Research.Value >= tech.Cost.Value
			for i, requirement in pairs(tech.Requirement:GetChildren()) do
				if not currentCountryData.Technology.Slots:FindFirstChild(requirement.Name) then
					canBuy = false
					break
				end
			end
			if canBuy then
				MainFrame.CenterFrame.TechnologyFrame.Main.Dragger[tech.Name].Status.BackgroundColor3 =
					Color3.fromRGB(255, 208, 89)
			else
				MainFrame.CenterFrame.TechnologyFrame.Main.Dragger[tech.Name].Status.BackgroundColor3 =
					Color3.fromRGB(255, 121, 121)
			end
		end
	end
end)
function UpdateTiles(city, checkType)
	-- upvalues: (ref) currentMapType, (ref) currentCountry, (ref) mouseInteractionType, (ref) selected, (copy) GetModifier, (copy) Assets, (ref) currentCountryData, (ref) cityAnnexationFrame
	local status, errorMessage = pcall(function()
		-- upvalues: (ref) currentMapType, (ref) currentCountry, (ref) mouseInteractionType, (ref) selected, (ref) GetModifier, (ref) Assets, (ref) currentCountryData, (ref) cityAnnexationFrame, (copy) checkType, (copy) city
		local function SetColor(countryName, part)
			-- upvalues: (ref) currentMapType, (ref) currentCountry, (ref) mouseInteractionType, (ref) selected, (ref) GetModifier, (ref) Assets, (ref) currentCountryData, (ref) cityAnnexationFrame
			local color = Color3.new(0, 0, 0)
			for i, country in pairs(workspace.CountryData:GetChildren()) do
				if country.Name == countryName then
					if currentMapType == "Political" or currentMapType == "PeaceTreaty" then
						color = country.C3.Value
					elseif currentMapType == "Diplomatic" then
						color = Color3.new(0, 0, 0)
					end
					break
				end
			end
			local currentCountryName = currentCountry
			if currentMapType == "Diplomatic" then
				if mouseInteractionType == "SelectCity" then
					currentCountryName = selected[1].Parent.Name
				end
			end
			if countryName == currentCountryName then
				if currentMapType == "Political" then
					color = Color3.new(1, 1, 1)
				elseif
					currentMapType == "Diplomatic"
					or currentMapType == "Truces"
					or currentMapType == "Justifications"
				then
					color = Color3.new(0, 1, 0)
				end
			elseif currentMapType == "Diplomatic" then
				local alliance =
					workspace.CountryData[currentCountryName].Diplomacy.Alliances:FindFirstChild(countryName)
				if alliance then
					color = Color3.new(0, 0, 1)
					if alliance.Value == "Puppet" or alliance.Value == "PuppetMaster" then
						color = Color3.new(0, 1, 1)
					end
				end
				if workspace.Factions:FindFirstChild(currentCountryName, true) then
					if
						workspace.Factions:FindFirstChild(currentCountryName, true).Parent:FindFirstChild(countryName)
					then
						color = Color3.new(1, 1, 0)
					end
				end
				if
					require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
						currentCountryName,
						countryName,
						"Against"
					)
				then
					color = Color3.new(1, 0, 0)
				end
				if
					require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
						currentCountryName,
						countryName,
						"Together"
					)
				then
					color = Color3.new(0.1, 0.4, 0.1)
				end
			end
			if currentMapType == "Terrain" then
				return GetModifier.List.Terrain[part:GetAttribute("Terrain")].MapColor
			end
			if currentMapType == "Biome" then
				return GetModifier.List.Biome[part:GetAttribute("Biome")].MapColor
			end
			if currentMapType == "Tiles" then
				return Color3.fromHSV(
					Random.new():NextNumber(0, 1),
					Random.new():NextNumber(0.5, 1),
					Random.new():NextNumber(0.4, 1)
				)
			end
			if currentMapType == "Ideology" then
				return Assets.Laws.Ideology[workspace.CountryData[countryName].Laws.Ideology.Value].Color.Value
			end
			if currentMapType == "Truces" then
				if currentCountryData.Diplomacy.Truces:FindFirstChild(countryName) then
					return Color3.new(0, 1, 1)
				end
			elseif currentMapType == "Justifications" then
				if currentCountryData.Diplomacy.CasusBelli:FindFirstChild(countryName, true) then
					color = Color3.new(1, 0.9, 0.3)
				end
				if currentCountryData.Diplomacy.Actions:FindFirstChild(countryName) then
					if currentCountryData.Diplomacy.Actions[countryName]:GetAttribute("Type") ~= "FundRebel" then
						color = Color3.new(0, 1, 1)
					end
				end
				if
					workspace.CountryData[countryName].Diplomacy.CasusBelli:FindFirstChild(
						currentCountryData.Name,
						true
					)
				then
					return Color3.new(1, 0.2, 0.2)
				end
			elseif currentMapType == "Faction" then
				local factionCountry = workspace.Factions:FindFirstChild(countryName, true)
				if not factionCountry then
					return Color3.new(0, 0, 0)
				end
				color = factionCountry.Parent.Parent.Value
				if factionCountry.Value == "Leader" then
					return color:Lerp(Color3.new(1, 1, 1), 0.4)
				end
			else
				if currentMapType == "Population" then
					local partCities = game.CollectionService:GetTagged(part.Name .. "_City")
					local partCitiesEconomy = 0
					for i, city in pairs(partCities) do
						if city ~= nil then
							partCitiesEconomy = partCitiesEconomy + city.EcoStat.Value.X + city.EcoStat.Value.Z
						end
					end
					return Color3.fromHSV(math.clamp(partCitiesEconomy / 1000000, 0, 1) / 3, 1, 1)
				end
				if currentMapType == "PeaceTreaty" then
					if countryName == "Claimed" then
						return Color3.new(1, 1, 0)
					end
					if countryName ~= currentCountryName then
						if countryName == cityAnnexationFrame.Parent.PeaceFrame.Target.Value then
							return Color3.new(1, 0, 0)
						else
							return Color3.new(0, 0, 0)
						end
					end
					color = Color3.new(0, 1, 0)
				end
			end
			return color
		end
		if checkType == "CityCheck" then
			if currentMapType == "PeaceTreaty" then
				return
			end
			if city:GetAttribute("Region") ~= "" then
				local regionCities = game.CollectionService:GetTagged(city:GetAttribute("Region") .. "_City")
				local regionPop = {}
				for i, city in pairs(regionCities) do
					local cityOwner = city.Parent.Name
					if regionPop[cityOwner] == nil then
						regionPop[cityOwner] = city.Population.Value.X
					else
						regionPop[cityOwner] = regionPop[cityOwner] + city.Population.Value.X
					end
				end
				local regionPopSorted = {}
				local counter = 1
				for i, v in pairs(regionPop) do
					regionPopSorted[counter] = { i, v }
					counter = counter + 1
				end
				table.sort(regionPopSorted, function(a, b)
					return a[2] > b[2]
				end)
				if #regionPopSorted ~= 0 then
					game:GetService("TweenService")
						:Create(
							workspace.Baseplate.Parts[city:GetAttribute("Region")],
							TweenInfo.new(0.5, Enum.EasingStyle.Quad),
							{
								["Color"] = SetColor(
									regionPopSorted[1][1],
									workspace.Baseplate.Parts[city:GetAttribute("Region")]
								),
							}
						)
						:Play()
					return
				end
			end
		elseif checkType == "UniversalCheck" then
			for i, part in pairs(workspace.Baseplate.Parts:GetChildren()) do
				local transparency = (currentMapType == "PeaceTreaty" or currentMapType == "Tiles") and 0.75 or 0.9
				if part.Transparency ~= transparency then
					part.Transparency = transparency
				end
				local partCitiesPop = {}
				for i, city in pairs(game.CollectionService:GetTagged(part.Name .. "_City")) do
					local cityOwner = city.Parent.Name
					if currentMapType == "PeaceTreaty" then
						cityOwner = table.find(selected, city) and "Claimed" or city:GetAttribute("ActualOwner")
					end
					if partCitiesPop[cityOwner] == nil then
						partCitiesPop[cityOwner] = city.Population.Value.X
					else
						partCitiesPop[cityOwner] = partCitiesPop[cityOwner] + city.Population.Value.X
					end
				end
				local partCitiesPopSorted = {}
				local counter = 1
				for countryName, pop in pairs(partCitiesPop) do
					partCitiesPopSorted[counter] = { countryName, pop }
					counter = counter + 1
				end
				table.sort(partCitiesPopSorted, function(a, b)
					return a[2] > b[2]
				end)
				if #partCitiesPopSorted ~= 0 then
					part.Color = SetColor(partCitiesPopSorted[1][1], part)
				end
			end
		end
	end)
	if not status then
		print("Bod:  ", errorMessage)
	end
end
local v_u_1456 = "MapMode"
local v_u_1457 = {}
for i, v in pairs(MainFrame.RightFrame.PageList:GetChildren()) do
	table.insert(v_u_1457, v.Name)
end
local function Select(p1460)
	-- upvalues: (copy) MainFrame, (ref) v_u_1456, (copy) v_u_1457
	for i, v in pairs(MainFrame.RightFrame.PageList:GetChildren()) do
		if v.Name == p1460 then
			v.Visible = true
			MainFrame.RightFrame.Label.Text = v.Text
		else
			v.Visible = false
		end
	end
	v_u_1456 = p1460
	local v1463 = table.find(v_u_1457, v_u_1456) + 1
	MainFrame.RightFrame.Next:SetAttribute(
		"MouseOverText",
		MainFrame.RightFrame.PageList[v_u_1457[#v_u_1457 < v1463 and 1 or v1463]].Text
	)
	local v1464 = table.find(v_u_1457, v_u_1456) - 1
	MainFrame.RightFrame.Previous:SetAttribute(
		"MouseOverText",
		MainFrame.RightFrame.PageList[v_u_1457[v1464 < 1 and #v_u_1457 or v1464]].Text
	)
end
MakeMouseOver(MainFrame.RightFrame.Next, "", 14)
MakeMouseOver(MainFrame.RightFrame.Previous, "", 14)
Select(v_u_1456)
MainFrame.RightFrame.Next.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) v_u_1457, (ref) v_u_1456, (copy) Select
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	local v1467 = table.find(v_u_1457, v_u_1456) + 1
	Select(v_u_1457[#v_u_1457 < v1467 and 1 or v1467])
end)
MainFrame.RightFrame.Previous.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) v_u_1457, (ref) v_u_1456, (copy) Select
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	local v1469 = table.find(v_u_1457, v_u_1456) - 1
	Select(v_u_1457[v1469 < 1 and #v_u_1457 or v1469])
end)
table.insert(loopFunctions, function()
	-- upvalues: (ref) v_u_10, (copy) ClearList, (copy) MainFrame, (ref) currentCountryData, (copy) SetFlag, (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	if v_u_10 % 1 == 0 then
		ClearList(MainFrame.RightFrame.PageList.DiploAction.List)
		for i, action in pairs(currentCountryData.Diplomacy.Actions:GetChildren()) do
			local frame = MainFrame.RightFrame.PageList.DiploAction.List.Sample:Clone()
			frame.Type.Text = "Justify War: " .. action.Name
			frame.Time.Text = require(workspace.FunctionDump.SharedFunction).FutureDate(action.Value.Z - action.Value.X)
			SetFlag(frame.Flag, action.Name)
			frame.Bar.Back.Size = UDim2.new(action.Value.X / action.Value.Z, 0, 1, 0)
			frame.Parent = MainFrame.RightFrame.PageList.DiploAction
			frame.Flag.MouseButton1Click:Connect(function()
				-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame, (copy) v_u_1470, (copy) i, (ref) CenterFrameSelect
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				MainFrame.CenterFrame.DiplomacyFrame.Country.Value = action.Name
				CenterFrameSelect("DiplomacyFrame")
			end)
			frame.Cancel.MouseButton1Click:Connect(function()
				-- upvalues: (ref) Assets, (ref) GameGui, (copy) v_u_1470, (copy) i
				local clickSound = Assets.Audio.Click_2:Clone()
				clickSound.Parent = GameGui
				clickSound:Play()
				game.Debris:AddItem(clickSound, 15)
				workspace.GameManager.JustifyWar:FireServer(action.Name, {
					["FunctionMode"] = "Cancel",
					["ActionType"] = action:GetAttribute("Type"),
				})
			end)
			if action:GetAttribute("Type") == "FundRebel" then
				frame.Type.Text = "Funding Rebels in " .. action.Name
			end
		end
	end
end)
MainFrame.RightFrame.PageList.MapMode.Pol.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Political"
	UpdateTiles(nil, "UniversalCheck")
end)
MainFrame.RightFrame.PageList.MapMode.Dip.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Diplomatic"
	UpdateTiles(nil, "UniversalCheck")
end)
MainFrame.RightFrame.PageList.MapMode.Ter.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Terrain"
	UpdateTiles(nil, "UniversalCheck")
end)
MainFrame.RightFrame.PageList.MapMode.Tiles.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Tiles"
	UpdateTiles(nil, "UniversalCheck")
end)
CurrentMonth = 0
MainFrame.RightFrame.PageList.MapMode.Bio.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Biome"
	CurrentMonth = workspace.CountryManager.Date.Actual.Value.X
	UpdateTiles(nil, "UniversalCheck")
end)
table.insert(loopFunctions, function()
	-- upvalues: (ref) currentMapType
	if currentMapType == "Biome" and workspace.CountryManager.Date.Actual.Value.X ~= CurrentMonth then
		CurrentMonth = workspace.CountryManager.Date.Actual.Value.X
		UpdateTiles(nil, "UniversalCheck")
		warn("Season auto change")
	end
end)
MainFrame.RightFrame.PageList.MapMode.Faction.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Faction"
	UpdateTiles(nil, "UniversalCheck")
end)
MainFrame.RightFrame.PageList.MapMode.Ideology.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Ideology"
	UpdateTiles(nil, "UniversalCheck")
end)
MainFrame.RightFrame.PageList.MapMode.Truces.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Truces"
	UpdateTiles(nil, "UniversalCheck")
end)
MainFrame.RightFrame.PageList.MapMode.Justifications.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Justifications"
	UpdateTiles(nil, "UniversalCheck")
end)
MainFrame.RightFrame.PageList.MapMode.Population.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) currentMapType
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	currentMapType = "Population"
	UpdateTiles(nil, "UniversalCheck")
end)
MakeMouseOver(MainFrame.StatsFrame.Stats.Population, "", 14)
MakeMouseOver(MainFrame.StatsFrame.Stats.Manpower, function()
	-- upvalues: (ref) currentCountryData, (copy) ReferenceTable, (copy) Assets
	local maximumManpowerMillions, maximumManpowerThousands, maximumManpowerHundrends =
		tostring(currentCountryData.Manpower.Value.Z):match("(%-?%d?)(%d*)(%.?.*)")
	local maximumManpower = '<font color="rgb('
		.. ReferenceTable.Colors.Gold[1]
		.. ')">'
		.. maximumManpowerMillions
		.. maximumManpowerThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
		.. maximumManpowerHundrends
		.. "</font>"
	local manpowerIncreaseMillions, manpowerIncreaseThousands, manpowerIncreaseHundrends =
		tostring(currentCountryData.Manpower.Value.Y):match("(%-?%d?)(%d*)(%.?.*)")
	return "MANPOWER\n \nMaximum Manpower: "
		.. maximumManpower
		.. "\nManpower Increase: +"
		.. '<font color="rgb('
		.. ReferenceTable.Colors.Gold[1]
		.. ')">'
		.. manpowerIncreaseMillions
		.. manpowerIncreaseThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
		.. manpowerIncreaseHundrends
		.. "</font>"
		.. "\n \n"
		.. '<font color="rgb('
		.. ReferenceTable.Colors.Gold[1]
		.. ')">'
		.. Assets.Laws.Conscription[tostring(currentCountryData.Laws.Conscription.Value)].Value
		.. "</font>"
		.. "% of Population"
end, 14)
MakeMouseOver(MainFrame.StatsFrame.Stats.Money, "", 14)
MakeMouseOver(MainFrame.StatsFrame.Stats.Military, "", 16)
MakeMouseOver(MainFrame.WarOverFrame.OverallFrame.AStats.Count, "", 16)
MakeMouseOver(MainFrame.WarOverFrame.OverallFrame.BStats.Count, "", 16)
MakeMouseOver(MainFrame.WarOverFrame.OverallFrame.AStats.Death, "", 14)
MakeMouseOver(MainFrame.WarOverFrame.OverallFrame.BStats.Death, "", 14)
for i, warning in pairs(MainFrame.StatsFrame.Stats.WarningFrame:GetChildren()) do
	if warning:IsA("TextButton") then
		MakeMouseOver(warning, "", 14)
	end
end
MainFrame.StatsFrame.Stats.WarningFrame.Debt.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("EconomyFrame")
end)
MainFrame.StatsFrame.Stats.WarningFrame.Deficit.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("EconomyFrame")
end)
MainFrame.StatsFrame.Stats.WarningFrame.FactionPending.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("CountryFrame")
end)
MainFrame.StatsFrame.Stats.WarningFrame.NoOil.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("EconomyFrame")
end)
MainFrame.StatsFrame.Stats.WarningFrame.OilDeficit.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("EconomyFrame")
end)
MainFrame.StatsFrame.Stats.WarningFrame.Stability.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("CountryFrame")
end)
MainFrame.StatsFrame.Stats.WarningFrame.TechResearch.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("TechnologyFrame")
end)
MainFrame.StatsFrame.Stats.WarningFrame.WarEx.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) CenterFrameSelect
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	CenterFrameSelect("CountryFrame")
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) currentCountryData, (copy) ReferenceTable, (ref) currentCountry, (copy) Technology
	local debt = MainFrame.StatsFrame.Stats.WarningFrame.Debt
	if currentCountryData.Economy.Balance.Value < 0 then
		if not debt.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		debt.Visible = true
	else
		debt.Visible = false
	end
	local stability = MainFrame.StatsFrame.Stats.WarningFrame.Stability
	if currentCountryData.Data.Stability.Value < 45 then
		if not stability.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		stability.Visible = true
	else
		stability.Visible = false
	end
	MainFrame.StatsFrame.Stats.WarningFrame.Stability.MouseOverText.Value = "Your stability is low! This can have dire consequences to the country!\n\nStability: "
		.. '<font color="rgb('
		.. ReferenceTable.Colors.Negative[1]
		.. ')">'
		.. math.ceil(currentCountryData.Data.Stability.Value * 100) / 100
		.. "%"
		.. "</font>"
	local warEx = MainFrame.StatsFrame.Stats.WarningFrame.WarEx
	if 3 < currentCountryData.Power.WarExhaustion.Value then
		if not warEx.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		warEx.Visible = true
	else
		warEx.Visible = false
	end
	MainFrame.StatsFrame.Stats.WarningFrame.WarEx.MouseOverText.Value = "High War Exhaustion can ruin your country!\n\nWar Exhaustion: "
		.. '<font color="rgb('
		.. ReferenceTable.Colors.Negative[1]
		.. ')">'
		.. math.ceil(currentCountryData.Power.WarExhaustion.Value * 100) / 100
		.. "</font>"
	local noOil = MainFrame.StatsFrame.Stats.WarningFrame.NoOil
	if currentCountryData.Resources.Oil.Value <= 0 then
		if not noOil.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		noOil.Visible = true
	else
		noOil.Visible = false
	end
	local deficit = MainFrame.StatsFrame.Stats.WarningFrame.Deficit
	if
		currentCountryData.Economy.Revenue:GetAttribute("Total")
		< currentCountryData.Economy.Expenses:GetAttribute("Total")
	then
		if not deficit.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		deficit.Visible = true
	else
		deficit.Visible = false
	end
	local millions, thousands, hundrends = tostring(
		currentCountryData.Economy.Revenue:GetAttribute("Total")
			- currentCountryData.Economy.Expenses:GetAttribute("Total")
	):match("(%-?%d?)(%d*)(%.?.*)")
	MainFrame.StatsFrame.Stats.WarningFrame.Deficit.MouseOverText.Value = "You are losing more money than you earn!\n\nBalance: "
		.. '<font color="rgb('
		.. ReferenceTable.Colors.Negative[1]
		.. ')">'
		.. "$"
		.. millions
		.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
		.. hundrends
		.. "</font>"
	local oilDeficit = MainFrame.StatsFrame.Stats.WarningFrame.OilDeficit
	local isOilDeficit
	if currentCountryData.Resources.Oil.Flow.Value < 0 then
		isOilDeficit = 0 < currentCountryData.Resources.Oil.Value
	else
		isOilDeficit = false
	end
	if isOilDeficit then
		if not oilDeficit.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		oilDeficit.Visible = true
	else
		oilDeficit.Visible = false
	end
	MainFrame.StatsFrame.Stats.WarningFrame.OilDeficit.MouseOverText.Value = "You are currently using more oil than you are producing!\n \nCurrent Flow: "
		.. math.ceil(currentCountryData.Resources.Oil.Flow.Value * 100) / 100
		.. "\nStockpile: "
		.. math.ceil(currentCountryData.Resources.Oil.Value * 100) / 100
		.. " Units"
	local isFactionPending = false
	local factionCountry = workspace.Factions:FindFirstChild(currentCountry, true)
	if factionCountry then
		if factionCountry.Value == "Leader" then
			isFactionPending = 0 < #factionCountry:GetChildren() and true or isFactionPending
		end
	end
	local factionPending = MainFrame.StatsFrame.Stats.WarningFrame.FactionPending
	if isFactionPending then
		if not factionPending.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		factionPending.Visible = true
	else
		factionPending.Visible = false
	end
	local techAvailable = {}
	for i, tech in pairs(Technology) do
		if
			MainFrame.CenterFrame.TechnologyFrame.Main.Dragger[tech.Name].Status.BackgroundColor3
			== Color3.fromRGB(255, 208, 89)
		then
			if not MainFrame.CenterFrame.TechnologyFrame.Main.Dragger[tech.Name].Ignore.Visible then
				table.insert(techAvailable, tech.Title.Value)
			end
		end
	end
	local techResearch = MainFrame.StatsFrame.Stats.WarningFrame.TechResearch
	if 0 < #techAvailable then
		if not techResearch.Visible then
			local alertSound = Assets.Audio.Alert:Clone()
			alertSound.Parent = GameGui
			alertSound:Play()
			game.Debris:AddItem(alertSound, 15)
		end
		techResearch.Visible = true
	else
		techResearch.Visible = false
	end
	if 0 < #techAvailable then
		MainFrame.StatsFrame.Stats.WarningFrame.TechResearch.MouseOverText.Value =
			"You have one or more technologies you can research:\n"
		for i, tech in pairs(techAvailable) do
			local mouseOverText = MainFrame.StatsFrame.Stats.WarningFrame.TechResearch.MouseOverText
			mouseOverText.Value = mouseOverText.Value
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. tech
				.. "</font>"
				.. "\n"
		end
	end
end)
local function PreviewCountry(countryName)
	-- upvalues: (copy) LocalPlayer, (copy) SetFlag, (copy) FirstFrame, (ref) v_u_4, (ref) v_u_5, (copy) PositionToCoord
	if not LocalPlayer:GetAttribute("Country") then
		SetFlag(FirstFrame.CountryStat.Flag, countryName)
		FirstFrame.CountryStat.CName.Text = countryName
		FirstFrame.CountryStat.Manpower.Text = "Max Manpower: " .. workspace.CountryData[countryName].Manpower.Value.Z
		FirstFrame.CountryStat.XP.Text = "XP Required: " .. workspace.CountryData[countryName].Requirement.Value.X
		FirstFrame.CountryStat.XPGain.Text = "XP Gain Modifier: "
			.. math.ceil(workspace.CountryData[countryName].Requirement.Value.Y * 100) / 100
			.. "x"
		FirstFrame.CountryStat.Formables.Text = "Formables:"
		for i, formable in pairs(workspace.CountryData[countryName].Formables:GetChildren()) do
			FirstFrame.CountryStat.Formables.Text = FirstFrame.CountryStat.Formables.Text
				.. "\n>"
				.. formable.Value
				.. "<"
		end
		FirstFrame.Playing.Value = countryName
		local countryPop = 0
		for i, city in pairs(workspace.Baseplate.Cities[countryName]:GetChildren()) do
			countryPop = countryPop + city.Population.Value.X
		end
		local millions, thousands, hundrends = tostring(countryPop):match("(%-?%d?)(%d*)(%.?.*)")
		FirstFrame.CountryStat.Population.Text = "Population: "
			.. millions
			.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
			.. hundrends
		if workspace.CountryData[countryName].Capital.Value.Parent.Name ~= countryName then
			local v1537, v1538 = PositionToCoord(workspace.Baseplate.Cities[countryName]:GetChildren()[1].Position)
			v_u_4 = v1537
			v_u_5 = v1538
			return
		end
		local v1539, v1540 = PositionToCoord(workspace.CountryData[countryName].Capital.Value.Position)
		v_u_4 = v1539
		v_u_5 = v1540
	end
end
FirstFrame.RandomPlay.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) PreviewCountry
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	local countries = GameGui.FirstFrame.CountryList:GetChildren()
	local randomCountry = countries[Random.new():NextInteger(2, #countries)].Name
	if workspace.CountryData[randomCountry].Leader.Value == randomCountry .. "AI" then
		PreviewCountry(randomCountry)
	else
		GameGui.FirstFrame.CountryList[randomCountry]:Destroy()
	end
end)
FirstFrame.Return.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	workspace.GameManager.ReturnToLobby:FireServer()
end)
local cityTable = {}
for i, city in pairs(workspace.Baseplate.Cities:GetChildren()) do
	table.insert(cityTable, {
		["Tag"] = city.Name,
		["Color"] = workspace.CountryData[city.Name].C3.Value,
		["Value"] = workspace.CountryData[city.Name].Population.Value,
	})
	if 0 < #city:GetChildren() then
		local frame = FirstFrame.CountryList.UIListLayout.Sample:Clone()
		frame.Name = city.Name
		frame.Text = city.Name
		if workspace.CountryData[city.Name].Ranking.Value <= 3 then
			frame.Rank.BackgroundColor3 = Color3.fromRGB(255, 208, 89)
			frame.Rank.Visible = true
		elseif
			3 < workspace.CountryData[city.Name].Ranking.Value
			and workspace.CountryData[city.Name].Ranking.Value <= 20
		then
			frame.Rank.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			frame.Rank.Visible = true
		end
		SetFlag(frame.Flag, city.Name)
		frame.Parent = GameGui.FirstFrame.CountryList
		frame.MouseButton1Click:Connect(function()
			-- upvalues: (copy) Assets, (copy) GameGui, (copy) frame, (copy) PreviewCountry
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			if workspace.CountryData[frame.Name].Leader.Value == frame.Name .. "AI" then
				PreviewCountry(frame.Name)
			else
				frame:Destroy()
			end
		end)
		for i, child in pairs(city:GetChildren()) do
			child:GetPropertyChangedSignal("Parent"):Connect(function()
				-- upvalues: (copy) child, (ref) currentCountry, (copy) MainFrame, (ref) currentCountryData, (copy) PopUp
				if child.Parent.Name == currentCountry then
					game:GetService("TweenService")
						:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
							["Color"] = BrickColor.Red().Color,
						})
						:Play()
					local text = child.Name .. " has been captured!"
					local color = Color3.fromRGB(255, 208, 89)
					local aliveTime = 2
					coroutine.resume(coroutine.create(function()
						-- upvalues: (ref) MainFrame, (copy) text, (copy) color, (copy) aliveTime
						local textLabel = MainFrame.RightFrame.Notifications.UIListLayout.MSG:Clone()
						textLabel.Text = text
						textLabel.TextColor3 = color
						textLabel.Parent = MainFrame.RightFrame.Notifications
						wait(aliveTime)
						game:GetService("TweenService")
							:Create(textLabel, TweenInfo.new(3, Enum.EasingStyle.Linear), {
								["TextStrokeTransparency"] = 1,
								["TextTransparency"] = 1,
							})
							:Play()
						wait(3.1)
						textLabel:Destroy()
					end))
				else
					if child:FindFirstChild("OccupiedTag") then
						child.OccupiedTag:Destroy()
					end
					game:GetService("TweenService")
						:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
							["Color"] = workspace.CountryData[child.Parent.Name].C3.Value,
						})
						:Play()
				end
				if currentCountry ~= "" and child:FindFirstChild(currentCountry .. "Loss") then
					local text = child.Name .. " has been lost!"
					local color = Color3.fromRGB(255, 121, 121)
					local aliveTime = 2
					coroutine.resume(coroutine.create(function()
						-- upvalues: (ref) MainFrame, (copy) text, (copy) color, (copy) aliveTime
						local textLabel = MainFrame.RightFrame.Notifications.UIListLayout.MSG:Clone()
						textLabel.Text = text
						textLabel.TextColor3 = color
						textLabel.Parent = MainFrame.RightFrame.Notifications
						wait(aliveTime)
						game:GetService("TweenService")
							:Create(textLabel, TweenInfo.new(3, Enum.EasingStyle.Linear), {
								["TextStrokeTransparency"] = 1,
								["TextTransparency"] = 1,
							})
							:Play()
						wait(3.1)
						textLabel:Destroy()
					end))
					if currentCountryData.Capital.Value == child then
						PopUp(
							"The loss of " .. child.Name .. "!",
							"We have lost our capital to invading forces! Our manpower increase has been crippled!",
							"Curse them!"
						)
					end
				end
				UpdateTiles(child, "CityCheck")
			end)
		end
	end
end
GeneratePieChart(cityTable)
local countriesFilteredByRank = GameGui.FirstFrame.CountryList:GetChildren()
table.remove(countriesFilteredByRank, 1)
table.remove(countriesFilteredByRank, 1)
if 1 < #countriesFilteredByRank then
	table.sort(countriesFilteredByRank, function(a, b)
		local aRank = workspace.CountryData[a.Name].Ranking.Value
		local bRank = workspace.CountryData[b.Name].Ranking.Value
		return (workspace.CountryData[a.Name].Leader.Value ~= a.Name .. "AI" and 10000 or aRank <= 3 and 10000 or aRank)
			< (workspace.CountryData[b.Name].Leader.Value ~= b.Name .. "AI" and 10000 or bRank <= 3 and 10000 or bRank)
	end)
	for i = 1, math.clamp(#countriesFilteredByRank, 1, 10) do
		local button = FirstFrame.InterestingCountryFrame.GridList.List.Sample:Clone()
		button.Name = countriesFilteredByRank[i].Name
		SetFlag(button, countriesFilteredByRank[i].Name)
		button.Parent = FirstFrame.InterestingCountryFrame.GridList
		MakeMouseOver(button, countriesFilteredByRank[i].Name, 14)
		button.MouseButton1Click:Connect(function()
			-- upvalues: (copy) countriesFilteredByRank, (copy) i, (copy) PreviewCountry, (copy) button
			if
				workspace.CountryData[countriesFilteredByRank[i].Name].Leader.Value
				== countriesFilteredByRank[i].Name .. "AI"
			then
				PreviewCountry(countriesFilteredByRank[i].Name)
			else
				button.Visible = false
			end
		end)
	end
end
FirstFrame.CountryList.CanvasSize = UDim2.new(0, 0, 0, FirstFrame.CountryList.UIListLayout.AbsoluteContentSize.Y * 1.1)
local firstFrameSearchBox = FirstFrame.SearchFrame.Box
firstFrameSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) Assets, (copy) firstFrameSearchBox
	for i, country in pairs(FirstFrame.CountryList:GetChildren()) do
		if Assets.Flag:FindFirstChild(country.Name) then
			if string.match(string.lower(country.Name), string.lower(firstFrameSearchBox.Text)) == nil then
				country.Visible = false
			else
				country.Visible = true
			end
		end
	end
end)
FirstFrame.Play.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) FirstFrame, (copy) TeleportData, (copy) LocalPlayer, (copy) PlayerXP, (ref) currentCountry, (ref) currentCountryData, (copy) MainFrame, (copy) SetFlag, (copy) PopUp, (ref) v_u_4, (ref) v_u_5, (copy) PositionToCoord, (copy) MakeCountryList
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	local countrySelected = FirstFrame.Playing.Value
	if TeleportData == "Tutorial" then
		if countrySelected ~= "Russia" then
			countrySelected = nil
		end
	end
	if countrySelected ~= nil then
		local country = workspace.Baseplate.Cities[countrySelected]
		if
			workspace.CountryData[country.Name].Leader.Value == country.Name .. "AI"
			and not LocalPlayer:GetAttribute("Country")
			and PlayerXP.Value > workspace.CountryData[country.Name].Requirement.Value.X
		then
			GameGui.FirstFrame.Visible = false
			currentCountry = country.Name
			currentCountryData = workspace.CountryData[currentCountry]
			MainFrame.StatsFrame.Stats.CountryName.Text = currentCountry
			MainFrame.CenterFrame.DiplomacyFrame.Country.Value = currentCountry
			SetFlag(MainFrame.StatsFrame.Flag, currentCountry)
			MainFrame.Visible = true
			workspace.GameManager.CreateCountry:FireServer(currentCountry)
			for i, city in pairs(country:GetChildren()) do
				city.BrickColor = BrickColor.Red()
			end
			currentCountryData.Laws.Modifiers.ChildAdded:Connect(function(modifier)
				-- upvalues: (ref) PopUp
				PopUp("New Modifier!", "We have gained a new national modifier: " .. modifier.Name, "Ok")
			end)
			currentCountryData.Laws.Modifiers.ChildRemoved:Connect(function(modifier)
				-- upvalues: (ref) PopUp
				PopUp("Modifier Lost!", "We have lost a national modifier: " .. modifier.Name, "Ok")
			end)
			if workspace.CountryData[country.Name].Capital.Value.Parent.Name == country.Name then
				local v1579, v1580 = PositionToCoord(workspace.CountryData[country.Name].Capital.Value.Position)
				v_u_4 = v1579
				v_u_5 = v1580
			else
				local v1581, v1582 = PositionToCoord(country:GetChildren()[1].Position)
				v_u_4 = v1581
				v_u_5 = v1582
			end
			UpdateTiles(nil, "UniversalCheck")
			for i, button in pairs(MakeCountryList(MainFrame.CenterFrame.DiplomacyFrame.Main.CountryList)) do
				button.MouseButton1Click:Connect(function()
					-- upvalues: (ref) Assets, (ref) GameGui, (ref) MainFrame
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					MainFrame.CenterFrame.DiplomacyFrame.Country.Value = button.Name
				end)
			end
			currentCountryData.Resources.DescendantRemoving:Connect(function(descendant)
				-- upvalues: (ref) PopUp
				if descendant.Parent.Name == "Trade" then
					PopUp(
						"Trade Cancelled",
						"Trade of "
							.. descendant.Parent.Parent.Name
							.. " between Us and "
							.. descendant.Name
							.. " has been cancelled",
						"Ok",
						descendant.Name
					)
				end
			end)
		end
	end
end)
for i, country in pairs(workspace.CountryData:GetChildren()) do
	if country.Name ~= currentCountry then
		for i, child in pairs(workspace.Baseplate.Cities[country.Name]:GetChildren()) do
			child.Color = country.C3.Value
		end
	end
end
UpdateTiles(nil, "UniversalCheck")
workspace.CountryData.ChildAdded:Connect(function(country)
	-- upvalues: (ref) currentCountry
	if country.Name ~= currentCountry then
		country:WaitForChild("C3", 60)
		for i, city in pairs(workspace.Baseplate.Cities[country.Name]:GetChildren()) do
			city.Color = country.C3.Value
		end
		UpdateTiles(nil, "UniversalCheck")
	end
end)
for i, country in pairs(workspace.CountryData:GetChildren()) do
	if GameGui.FirstFrame.CountryList:FindFirstChild(country.Name) then
		if country.Leader.Value ~= country.Name .. "AI" then
			GameGui.FirstFrame.CountryList[country.Name]:Destroy()
		end
	end
end
local function OnScreen(pos)
	-- upvalues: (ref) v_u_6, (copy) Mouse, (copy) baseplateWidthDividedBy2
	local onScreen = false
	if v_u_6 < 64 then
		local screenPos = workspace.CurrentCamera:WorldToScreenPoint(pos)
		if 0 < screenPos.X then
			if screenPos.X < Mouse.ViewSizeX then
				if 0 < screenPos.Y then
					if screenPos.Y < Mouse.ViewSizeY then
						onScreen = (workspace.CurrentCamera.CFrame.Position - pos).Magnitude
									< baseplateWidthDividedBy2 / 2
								and true
							or onScreen
					end
				end
			end
		end
	end
	return onScreen
end
workspace.BattleManager.DeathText.OnClientEvent:Connect(function(pos, text)
	-- upvalues: (copy) Assets
	local deathText = Assets.FX.DeathText:Clone()
	deathText.TextGui.Num.Text = -text
	deathText.Position = pos + pos.Unit
	deathText.Parent = workspace
	game:GetService("TweenService")
		:Create(deathText, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
			["Position"] = pos + pos.Unit * 2,
		})
		:Play()
	game:GetService("TweenService")
		:Create(deathText.TextGui.Num, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
			["TextStrokeTransparency"] = 1,
			["TextTransparency"] = 1,
		})
		:Play()
	game.Debris:AddItem(deathText, 4)
end)
workspace.BattleManager.CaptureBar.OnClientEvent:Connect(function(instance)
	-- upvalues: (copy) MainFrame
	local captureTag = script.CaptureTag:Clone()
	captureTag.Adornee = instance.Parent
	captureTag.Name = instance.Name
	if instance.Name == "TransportChange" then
		captureTag.BarBack.Bar.BackgroundColor3 = Color3.fromRGB(143, 197, 212)
		captureTag.StudsOffsetWorldSpace = Vector3.new(1.5, 0, 0)
	elseif instance.Name == "TransportChangeAir" then
		captureTag.BarBack.Bar.BackgroundColor3 = Color3.fromRGB(166, 212, 143)
		captureTag.StudsOffsetWorldSpace = Vector3.new(1.5, 0, 0)
	end
	captureTag.Parent = MainFrame.SubGui
end)
workspace.GameManager.ManageAlliance.OnClientEvent:Connect(function(country, Type, data)
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (ref) currentCountry, (ref) currentCountryData, (copy) SetFlag, (copy) MakeMouseOver, (copy) ReferenceTable
	if Type == "RequestClient" or Type == "RequestPeace" or Type == "RequestJoin" or Type == "RequestTrade" then
		local notificationButtonSound = Assets.Audio.NotificationButton:Clone()
		notificationButtonSound.Parent = GameGui
		notificationButtonSound:Play()
		game.Debris:AddItem(notificationButtonSound, 15)
		local buttonIconImage = ""
		local buttonIconColor = Color3.new(1, 1, 1)
		for i, v in pairs(MainFrame:GetChildren()) do
			local _ = v.Name == "AllianceFrame"
		end
		local allianceFrame = script.AllianceFrame:Clone()
		if Type == "RequestClient" then
			if data == nil then
				allianceFrame.Desc.Text = country .. " requests a military alliance with you."
			else
				allianceFrame.Desc.Text = country .. " has sent a request asking us to become puppets towards them"
				allianceFrame.Title.Text = "Puppet request"
				buttonIconColor = Color3.fromRGB(255, 195, 120)
			end
			buttonIconImage = "http://www.roblox.com/asset/?id=3890522466"
		elseif Type == "RequestPeace" then
			allianceFrame.Desc.Text = country
				.. " sends a offer of peace with the following terms: "
				.. require(workspace.FunctionDump.ValueCalc.Data_PeaceTerms).Text(
					data[3],
					country,
					data[2] == "Demand" and "Concede" or "Demand"
				)
			allianceFrame.Title.Text = "Peace terms"
			buttonIconImage = "http://www.roblox.com/asset/?id=3890521171"
		elseif Type == "RequestJoin" then
			allianceFrame.Desc.Text = country
				.. " asks you to join their side in the following war: "
				.. data[1].Name
				.. "\n \nDeclining the call to arms will break the alliance"
			if workspace.Factions:FindFirstChild(currentCountry, true) then
				allianceFrame.Desc.Text = country
					.. " asks you to join their side in the following war: "
					.. data[1].Name
			end
			allianceFrame.Title.Text = "Call to Arms"
			buttonIconColor = Color3.fromRGB(156, 255, 120)
			buttonIconImage = "http://www.roblox.com/asset/?id=3890522466"
		elseif Type == "RequestTrade" then
			local resourceMillions, resourceThousands, resourceHundrends =
				tostring(data[4] * data[3] * Assets.Resources[data[1]].Value):match("(%-?%d?)(%d*)(%.?.*)")
			allianceFrame.Desc.Text = country
				.. " proposes the following trade offer: \n They will be "
				.. data[2]
				.. "ing "
				.. data[3]
				.. " units of "
				.. data[1]
				.. " valued $"
				.. resourceMillions
				.. resourceThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
				.. resourceHundrends
				.. " ("
				.. data[4]
				.. "x Value) "
				.. (data[5] == "Bulk" and " one time" or " every 5 days ")
				.. (data[2] == "Sell" and "to us" or " from us")
				.. "\nCurrent "
				.. data[1]
				.. " flow: "
				.. math.ceil(currentCountryData.Resources[data[1]].Flow.Value * 10) / 10
			allianceFrame.Title.Text = "Trade Offer"
			buttonIconImage = "http://www.roblox.com/asset/?id=3890519959"
		end
		SetFlag(allianceFrame.Flag, country)
		SetFlag(allianceFrame.FlagOwn, currentCountry)
		allianceFrame.Yes.MouseButton1Click:Connect(function()
			-- upvalues: (ref) Assets, (ref) GameGui, (copy) Type, (copy) country, (ref) MainFrame, (copy) data, (ref) currentCountry, (copy) allianceFrame
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			if Type == "RequestClient" then
				workspace.GameManager.ManageAlliance:FireServer(country, "AcceptRequest")
			elseif Type == "RequestPeace" then
				MainFrame.CountryGui:ClearAllChildren()
				workspace.GameManager.ManageAlliance:FireServer(country, "AcceptPeace", data)
			elseif Type == "RequestJoin" then
				workspace.GameManager.ManageAlliance:FireServer(currentCountry, "WarJoin", data)
			elseif Type == "RequestTrade" then
				workspace.GameManager.ManageAlliance:FireServer(country, "TradeAccept", data)
			end
			allianceFrame:Destroy()
		end)
        local function unknownFunc()
			-- upvalues: (ref) Assets, (ref) GameGui, (copy) Type, (copy) country, (ref) MainFrame, (copy) data, (copy) allianceFrame
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			if Type == "RequestClient" or Type == "RequestTrade" then
				workspace.GameManager.ManageAlliance:FireServer(country, "DeclineRequest")
			elseif Type == "RequestPeace" then
				MainFrame.CountryGui:ClearAllChildren()
				workspace.GameManager.ManageAlliance:FireServer(country, "DeclinePeace", data)
			elseif Type == "RequestJoin" then
				workspace.GameManager.ManageAlliance:FireServer(country, "Break")
			end
			allianceFrame:Destroy()
		end
		allianceFrame.No.MouseButton1Click:Connect(function()
			-- upvalues: (copy) unknownFunc
			unknownFunc()
		end)
		allianceFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		allianceFrame.Parent = MainFrame
		allianceFrame.Desc.Size = UDim2.new(1, -10, 0, allianceFrame.Desc.TextBounds.Y)
		allianceFrame.Size = UDim2.new(0, 300, 0, 65 + allianceFrame.Desc.TextBounds.Y)
		allianceFrame.Visible = false
		local button = MainFrame.StatsFrame.Stats.IconFrame.List.Sample:Clone()
		button.Icon.Image = buttonIconImage
		button.Icon.ImageColor3 = buttonIconColor
		SetFlag(button.Flag, country)
		button.MouseButton1Click:Connect(function()
			-- upvalues: (ref) Assets, (ref) GameGui, (copy) allianceFrame, (copy) button, (copy) Type, (copy) data
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			allianceFrame.Visible = true
			button:Destroy()
			GameGui.MouseOver.Visible = false
			if Type == "RequestPeace" and data[3].AnnexSome then
				for i, v in pairs(data[3].AnnexSome) do
					ObjectPopup("X", Color3.fromRGB(255, 255, 255), v, 999)
				end
			end
		end)
		button.MouseButton2Click:Connect(function()
			-- upvalues: (copy) unknownFunc, (copy) button
			unknownFunc()
			button:Destroy()
		end)
		button.Parent = MainFrame.StatsFrame.Stats.IconFrame
		MakeMouseOver(button, allianceFrame.Desc.Text, 12)
		game.Debris:AddItem(button, 90)
		return
	elseif Type == "RequestEvent" then
		local counter = 0
		for i, v in pairs(MainFrame:GetChildren()) do
			if v.Name == "AlertSample" or v.Name == "EventFrame" then
				counter = counter + 1
			end
		end
		local event = Assets.Laws.Events[data]
		local eventFrame = script.EventFrame:Clone()
		eventFrame.Title.Text = data
		eventFrame.Desc.Text = event.Value
		SetFlag(eventFrame.FlagOwn, currentCountry)
		SetFlag(eventFrame.Flag, currentCountry)
		eventFrame.Visible = false
		eventFrame.Position = UDim2.new(0.5, 40 * counter, 0.5, 20 * counter)
		eventFrame.Parent = MainFrame
		eventFrame.Desc.Size = UDim2.new(1, -10, 0, (math.ceil(eventFrame.Desc.TextBounds.Y)))
		eventFrame.Size = UDim2.new(0, 360, 0, 65 + math.ceil(eventFrame.Desc.TextBounds.Y))
		for i, choice in pairs(event.Choices:GetChildren()) do
			local button = eventFrame.Choices.List.Sample:Clone()
			button.Text = choice.Name
			button.Parent = eventFrame.Choices
			coroutine.resume(coroutine.create(function()
				-- upvalues: (copy) button, (ref) currentCountry, (copy) data, (copy) v_u_1628, (copy) v_u_1629, (ref) Assets, (ref) GameGui, (copy) eventFrame
				button.TextColor3 = Color3.new(0.7, 0.7, 0.7)
				wait(4)
				button.TextColor3 = Color3.new(1, 1, 1)
				button.MouseButton1Click:Connect(function()
					-- upvalues: (ref) currentCountry, (ref) data, (ref) v_u_1628, (ref) v_u_1629, (ref) Assets, (ref) GameGui, (ref) eventFrame
					workspace.GameManager.ManageAlliance:FireServer(
						currentCountry,
						"EventAnswer",
						{ data, choice.Name }
					)
					local clickSound = Assets.Audio.Click_2:Clone()
					clickSound.Parent = GameGui
					clickSound:Play()
					game.Debris:AddItem(clickSound, 15)
					eventFrame:Destroy()
					GameGui.MouseOver.Visible = false
				end)
			end))
			local text = choice.Value .. "\n "
			local choiceChildren = choice:GetChildren()
			for i, v in pairs(choiceChildren) do
				if v.Name == "Spawn Modifier" then
					local modifierText = " for "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Gold[1]
						.. ')">'
						.. v.Data.Number.Value
						.. "</font>"
						.. " days"
					if v.Data.Number.Value == -1 then
						modifierText = '<font color="rgb('
							.. ReferenceTable.Colors.Gold[1]
							.. ')">'
							.. " Indefinitely"
							.. "</font>"
					end
					text = text
						.. "\nGain National Modifier: "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Gold[1]
						.. ')">'
						.. v.Value
						.. "</font>"
						.. modifierText
						.. " with the following effects: \n"
					for i, effect in pairs(Assets.Laws.Modifiers[v.Value].Effects:GetChildren()) do
						if effect:IsA("NumberValue") and not effect:GetAttribute("Base") then
							text = text
								.. effect.Name
								.. ": "
								.. (effect.Value < 0 and "" or "+")
								.. '<font color="rgb('
								.. ReferenceTable.Colors.Gold[1]
								.. ')">'
								.. math.ceil(effect.Value * 100 * 100) / 100
								.. "%\n"
								.. "</font>"
						elseif effect:IsA("IntValue") or effect:GetAttribute("Base") then
							text = text
								.. effect.Name
								.. ": "
								.. '<font color="rgb('
								.. ReferenceTable.Colors.Gold[1]
								.. ')">'
								.. (effect.Value < 0 and "" or "+")
								.. math.ceil(effect.Value * 100000) / 100000
								.. "\n"
								.. "</font>"
						end
					end
				elseif v.Name == "Remove Modifier" then
					text = text
						.. "\nRemove National Modifier: "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Gold[1]
						.. ')">'
						.. v.Value
						.. "</font>"
				elseif v.Name == "Gain" or v.Name == "Lose" then
					if v.Value == "Money" then
						local millions, thousands, hundrends = tostring(
							currentCountryData.Laws.Events[data][choice.Name].Money.Value
						):match("(%-?%d?)(%d*)(%.?.*)")
						text = text
							.. "\n"
							.. v.Name
							.. " $ "
							.. '<font color="rgb('
							.. ReferenceTable.Colors.Gold[1]
							.. ')">'
							.. millions
							.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
							.. hundrends
							.. "</font>"
					elseif v.Value == "Manpower" then
						local millions, thousands, hundrends = tostring(
							currentCountryData.Laws.Events[data][choice.Name].Manpower.Value
						):match("(%-?%d?)(%d*)(%.?.*)")
						text = text
							.. "\n"
							.. v.Name
							.. " "
							.. '<font color="rgb('
							.. ReferenceTable.Colors.Gold[1]
							.. ')">'
							.. millions
							.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
							.. hundrends
							.. "</font>"
							.. " Manpower"
					else
						text = text
							.. "\n"
							.. v.Name
							.. " "
							.. '<font color="rgb('
							.. ReferenceTable.Colors.Gold[1]
							.. ')">'
							.. math.ceil(v.Data.Number.Value * 100) / 100
							.. "</font>"
							.. " "
							.. v.Value
					end
				end
			end
			if #choiceChildren == 0 then
				text = text .. "\nNo effect"
			end
			MakeMouseOver(button, text, 14, 300)
		end
		local button = MainFrame.StatsFrame.Stats.IconFrame.List.Sample:Clone()
		button.Name = data
		button.Icon.Image = "rbxassetid://6391894460"
		button.Flag.Image = "rbxassetid://71994455"
		button.MouseButton1Click:Connect(function()
			-- upvalues: (ref) Assets, (ref) GameGui, (copy) eventFrame, (copy) button
			local clickSound = Assets.Audio.Click_2:Clone()
			clickSound.Parent = GameGui
			clickSound:Play()
			game.Debris:AddItem(clickSound, 15)
			eventFrame.Visible = true
			button:Destroy()
			GameGui.MouseOver.Visible = false
		end)
		button.Parent = MainFrame.StatsFrame.Stats.IconFrame
		MakeMouseOver(button, data, 14)
		local notificationSound = Assets.Audio.Notification:Clone()
		notificationSound.Parent = GameGui
		notificationSound:Play()
		game.Debris:AddItem(notificationSound, 15)
	elseif Type == "RemoveEvent" then
		for i, v in pairs(MainFrame:GetChildren()) do
			if v.Name == "EventFrame" then
				if v.Title.Text == data then
					v:Destroy()
				end
			end
		end
		for i, v in pairs(MainFrame.StatsFrame.Stats.IconFrame:GetChildren()) do
			if v.Name == data then
				v:Destroy()
			end
		end
	end
end)
workspace.GameManager.AlertPopup.OnClientEvent:Connect(function(title, description, buttonTitle, flagCountryName)
	-- upvalues: (ref) currentCountryData, (copy) PopUp
	if currentCountryData then
		PopUp(title, description, buttonTitle, flagCountryName)
	end
end)
function ObjectPopup(text, color, adornee, aliveTime)
	-- upvalues: (copy) MainFrame
	local Table = {}
	local objectAlert = script.ObjectAlert:Clone()
	objectAlert.Label.Text = text
	objectAlert.Label.TextColor3 = color
	objectAlert.Adornee = adornee
	objectAlert.Enabled = true
	objectAlert.Parent = MainFrame.CountryGui
	table.insert(Table, objectAlert)
	game.Debris:AddItem(objectAlert, aliveTime)
	return Table
end
workspace.GameManager.ObjectPopup.OnClientEvent:Connect(function(p1661, p1662, p1663, p1664)
	ObjectPopup(p1661, p1662, p1663, p1664)
end)
if TeleportData == "Tutorial" and not LocalPlayer:GetAttribute("TutorialDone") then
	local tutorialFrame = GameGui.TutorialFrame
	local tutorialText = require(script.TutorialText)
	local v_u_1667 = {}
	for i, text in pairs(tutorialText) do
		local frame = tutorialFrame.HelpFrame.PageFrame.UIPageLayout.Sample:Clone()
		frame.Title.Text = text.Title
		frame.Desc.Text = text.Description
		frame.Name = i
		frame.LayoutOrder = i
		frame.Parent = tutorialFrame.HelpFrame.PageFrame
	end
	tutorialFrame.Visible = true
	local function SetPage()
		-- upvalues: (copy) tutorialText, (copy) tutorialFrame, (copy) v_u_1667
		local currentPageText = tutorialText[tonumber(tutorialFrame.HelpFrame.PageFrame.UIPageLayout.CurrentPage.Name)]
		local currentPage = tutorialFrame.HelpFrame.PageFrame.UIPageLayout.CurrentPage
		if v_u_1667.WarCountry then
			currentPage.Desc.Text =
				string.gsub(currentPageText.Description, "!TutorialData.WarCountry!", v_u_1667.WarCountry)
		end
		tutorialFrame.Arrow.Visible = false
		if currentPageText.Arrow then
			tutorialFrame.Arrow.Rotation = currentPageText.Arrow.Rotation
			tutorialFrame.Arrow.Position = UDim2.new(
				0,
				currentPageText.Arrow.Frame.AbsolutePosition.X,
				0,
				currentPageText.Arrow.Frame.AbsolutePosition.Y
			)
			tutorialFrame.Arrow.Visible = true
		end
	end
	tutorialFrame.HelpFrame.Next.MouseButton1Click:Connect(function()
		-- upvalues: (copy) tutorialFrame, (copy) tutorialText, (copy) LocalPlayer, (copy) SetPage
		if tutorialFrame.HelpFrame.PageFrame.UIPageLayout.CurrentPage.Name == tostring(#tutorialText) then
			tutorialFrame.Visible = false
			LocalPlayer:SetAttribute("TutorialDone", true)
		else
			tutorialFrame.HelpFrame.PageFrame.UIPageLayout:Next()
			tutorialFrame.HelpFrame.Next.Visible = false
			SetPage()
		end
	end)
	tutorialFrame.HelpFrame.Next.MouseButton2Click:Connect(function()
		-- upvalues: (copy) tutorialFrame, (copy) tutorialText, (copy) LocalPlayer, (copy) MainFrame
		if tutorialFrame.HelpFrame.PageFrame.UIPageLayout.CurrentPage.Name == tostring(#tutorialText) then
			tutorialFrame.Visible = false
			LocalPlayer:SetAttribute("TutorialDone", true)
			MainFrame.HelpFrame.Visible = true
		end
	end)
	table.insert(loopFunctions, function()
		-- upvalues: (copy) tutorialFrame, (copy) tutorialText, (ref) currentCountry, (ref) selected, (copy) MainFrame, (ref) currentCountryData, (copy) v_u_1667, (ref) mouseInteractionType, (copy) SetPage
		if tutorialFrame.Visible then
			local currentPage = tonumber(tutorialFrame.HelpFrame.PageFrame.UIPageLayout.CurrentPage.Name)
			local currentPageText = tutorialText[currentPage]
			if currentPageText.Arrow and currentPageText.Arrow.IsVisible then
				if currentPageText.Arrow.IsVisible.Visible then
					tutorialFrame.Arrow.Visible = true
				else
					tutorialFrame.Arrow.Visible = false
				end
			end
			local function ConditionalCheck(page)
				-- upvalues: (ref) currentCountry, (ref) selected, (ref) MainFrame, (ref) currentCountryData, (ref) v_u_1667, (ref) mouseInteractionType
				if page == 2 then
					if currentCountry == "Russia" then
						return true
					end
				elseif page == 4 then
					if
						selected[1] ~= nil
						and selected[1]:GetAttribute("ActualOwner") == currentCountry
						and MainFrame.CityFrame.Visible
					then
						return true
					end
				elseif page == 5 then
					if MainFrame.CityFrame.Visible and MainFrame.CityFrame.UnitFrame.Visible then
						return true
					end
				elseif page == 7 then
					if
						selected[1] ~= nil
						and selected[1]:GetAttribute("ActualOwner") ~= currentCountry
						and MainFrame.CityFrame.Visible
					then
						return true
					end
				elseif page == 8 then
					if MainFrame.CenterFrame.Visible and MainFrame.CenterFrame.DiplomacyFrame.Visible then
						return true
					end
				elseif page == 10 then
					if 0 < #currentCountryData.Diplomacy.Actions:GetChildren() then
						v_u_1667.WarCountry = MainFrame.CenterFrame.DiplomacyFrame.Country.Value
						print(v_u_1667.WarCountry)
						return true
					end
				elseif page == 11 then
					if MainFrame.CenterFrame.Visible and MainFrame.CenterFrame.EconomyFrame.Visible then
						return true
					end
				elseif page == 12 then
					if MainFrame.CenterFrame.Visible and MainFrame.CenterFrame.CountryFrame.Visible then
						return true
					end
				elseif page == 13 then
					if MainFrame.CenterFrame.Visible and MainFrame.CenterFrame.TechnologyFrame.Visible then
						return true
					end
				elseif page == 14 then
					if MainFrame.CenterFrame.Visible and MainFrame.CenterFrame.MilitaryFrame.Visible then
						return true
					end
				elseif page == 15 then
					if
						MainFrame.CenterFrame.Visible
						and MainFrame.CenterFrame.DiplomacyFrame.Visible
						and #currentCountryData.Diplomacy.Actions:GetChildren() == 0
						and MainFrame.CenterFrame.DiplomacyFrame.Country.Value == v_u_1667.WarCountry
					then
						return true
					end
				elseif page == 16 then
					if 0 < #workspace.Wars:GetChildren() then
						return true
					end
				elseif page == 17 then
					if selected[1] ~= nil and mouseInteractionType == "MoveUnit" then
						return true
					end
				elseif page == 18 then
					if
						0 < #workspace.Wars:GetChildren()
						and #workspace.Baseplate.Cities[workspace.Wars
								:GetChildren()[1].Defender
								:GetChildren()[1].Name]:GetChildren()
							== 0
					then
						return true
					end
				elseif page == 19 then
					if MainFrame.WarOverFrame.Visible then
						return true
					end
				elseif page == 20 then
					if MainFrame.WarOverFrame.Visible and MainFrame.WarOverFrame.PeaceFrame.Visible then
						return true
					end
				elseif page == 21 then
					if #workspace.Wars:GetChildren() == 0 then
						return true
					end
				elseif
					page == 22
					and selected[1] ~= nil
					and selected[1]:GetAttribute("ActualOwner") == currentCountry
					and MainFrame.CityFrame.Visible
					and 0 < selected[1]:GetAttribute("Unrest")
				then
					return true
				end
				return false
			end
			if currentPageText.Conditional then
				tutorialFrame.HelpFrame.Next.Visible = false
				if ConditionalCheck(currentPage) then
					tutorialFrame.HelpFrame.PageFrame.UIPageLayout:Next()
					SetPage()
					return
				end
			else
				tutorialFrame.HelpFrame.Next.Visible = true
			end
		end
	end)
end
MainFrame.TabMenu.Exit.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (ref) resourcesNumberTags, (ref) highlitedCities
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	Disengage()
	for i, v in pairs(resourcesNumberTags) do
		v:Destroy()
	end
	resourcesNumberTags = {}
	for i, highlight in pairs(highlitedCities) do
		highlight:Destroy()
	end
	highlitedCities = {}
	workspace.GameManager.Abandon:FireServer()
end)
MainFrame.TabMenu.Rules.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.RuleFrame.Visible = not MainFrame.RuleFrame.Visible
	MainFrame.TabMenu.Visible = false
end)
local manualText = require(script.ManualText)
local function SelectTopic(pages)
	-- upvalues: (copy) ClearList, (copy) MainFrame
	ClearList(MainFrame.HelpFrame.PageFrame.UIPageLayout)
	for i, v in pairs(pages) do
		local frame = MainFrame.HelpFrame.PageFrame.UIPageLayout.Sample:Clone()
		frame.Title.Text = v.Title
		frame.Desc.Text = v.Desc
		frame.Name = i
		frame.LayoutOrder = i
		frame.Parent = MainFrame.HelpFrame.PageFrame
	end
	MainFrame.HelpFrame.PageNum.Text = "Page: 1 / " .. #pages
end
for i, v in pairs(manualText) do
	local button = MainFrame.HelpFrame.TopicList.List.Sample:Clone()
	button.Name = v.Topic
	button.Text = v.Topic
	button.LayoutOrder = i
	button.Parent = MainFrame.HelpFrame.TopicList
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) SelectTopic, (copy) manualText, (copy) i
		SelectTopic(v.SubTopics)
	end)
end
ScaleScrollGui(MainFrame.HelpFrame.TopicList.List, "Y")
SelectTopic(manualText[1].SubTopics)
MainFrame.TabMenu.Help.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if MainFrame.HelpFrame.Visible then
		MainFrame.HelpFrame.Visible = false
	else
		MainFrame.HelpFrame.Visible = true
	end
	MainFrame.TabMenu.Visible = false
end)
MainFrame.HelpFrame.Prev.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.HelpFrame.PageFrame.UIPageLayout:Previous()
	MainFrame.HelpFrame.PageNum.Text = "Page: "
		.. MainFrame.HelpFrame.PageFrame.UIPageLayout.CurrentPage.Name
		.. " / "
		.. #MainFrame.HelpFrame.PageFrame:GetChildren() - 1
end)
MainFrame.HelpFrame.Next.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.HelpFrame.PageFrame.UIPageLayout:Next()
	MainFrame.HelpFrame.PageNum.Text = "Page: "
		.. MainFrame.HelpFrame.PageFrame.UIPageLayout.CurrentPage.Name
		.. " / "
		.. #MainFrame.HelpFrame.PageFrame:GetChildren() - 1
end)
local changeLogs = require(workspace.ChangeLogs)
for i, log in pairs(changeLogs) do
	local button = MainFrame.UpdateFrame.TopicList.List.Sample:Clone()
	button.Name = log.Date
	button.Text = log.Date
	button.LayoutOrder = i
	button.Parent = MainFrame.UpdateFrame.TopicList
	button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) MainFrame, (copy) changeLogs, (copy) i
		MainFrame.UpdateFrame.PageFrame.Sample.Desc.Text = log.Content
		MainFrame.UpdateFrame.PageFrame.Sample.Title.Text = log.Date
	end)
	if i == 1 then
		button.TextColor3 = Color3.fromRGB(255, 237, 98)
		MainFrame.UpdateFrame.PageFrame.Sample.Desc.Text = log.Content
		MainFrame.UpdateFrame.PageFrame.Sample.Title.Text = log.Date
	end
end
MainFrame.TabMenu.Updates.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	if MainFrame.UpdateFrame.Visible then
		MainFrame.UpdateFrame.Visible = false
	else
		MainFrame.UpdateFrame.Visible = true
	end
	MainFrame.TabMenu.Visible = false
end)
MainFrame.TabMenu.FlagOverlay.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.TabMenu.FlagOverlay:SetAttribute("Setting", not MainFrame.TabMenu.FlagOverlay:GetAttribute("Setting"))
	local overlay = game.CollectionService:GetTagged("Overlay")
	for i, v in pairs(overlay) do
		v.Visible = MainFrame.TabMenu.FlagOverlay:GetAttribute("Setting")
	end
end)
MainFrame.TabMenu.Profile.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.ProfileFrame.Visible = not MainFrame.ProfileFrame.Visible
	MainFrame.TabMenu.Visible = false
end)
local function UpdateButtonStatus(frame, skin)
	-- upvalues: (copy) LocalPlayer, (copy) ReferenceTable
	if require(workspace.FunctionDump.ValueCalc.GetRequirement).SkinOwnership(LocalPlayer, skin.Name) then
		frame.Button.Text = "Select"
		frame.Button.TextColor3 = ReferenceTable.Colors.Positive[2]
		if LocalPlayer.SkinChoice.Value == skin.Name then
			frame.Button.Text = "Selected"
			frame.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			return
		end
	else
		frame.Button.Text = "Locked"
		frame.Button.TextColor3 = ReferenceTable.Colors.Negative[2]
		if skin:FindFirstChild("Gamepass") then
			frame.Button.Text = "Buy"
			frame.Button.TextColor3 = ReferenceTable.Colors.Gold[2]
		end
	end
end
local skins = Assets.Skins:GetChildren()
MainFrame.TabMenu.Skin.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) skins, (copy) UpdateButtonStatus
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.SkinFrame.Visible = not MainFrame.SkinFrame.Visible
	if MainFrame.SkinFrame.Visible then
		for i, skin in pairs(skins) do
			task.spawn(UpdateButtonStatus, MainFrame.SkinFrame.List[skin.Name], skin)
		end
	end
	MainFrame.TabMenu.Visible = false
end)
MainFrame.SkinFrame.List.CanvasSize = UDim2.new(0, 0, 0, #skins * 120)
for i, skin in pairs(skins) do
	local frame = MainFrame.SkinFrame.List.List.Sample:Clone()
	frame.Name = skin.Name
	frame.Title.Text = skin.Name
	frame.Desc.Text = skin.Value
	frame.Parent = MainFrame.SkinFrame.List
	if frame.Name == "Default" then
		frame.LayoutOrder = -10
	end
	local packModelsText = "Skin pack contains: \n"
	for i, unitModel in pairs(Assets.UnitModels[skin.Name]:GetChildren()) do
		packModelsText = packModelsText .. unitModel.Name .. " Model\n"
	end
	MakeMouseOver(frame.PreviewFrame, packModelsText, 14)
	frame.Button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) skins, (copy) i, (copy) LocalPlayer
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		local data = workspace.GameManager.ChangeProfile:InvokeServer("Skin", skin.Name)
		if data == "Yes" then
			Disengage()
		elseif data == "Buy" then
			game.MarketplaceService:PromptGamePassPurchase(LocalPlayer, skin.Gamepass.Value)
		end
	end)
	if skin:FindFirstChild("Requirement") then
		local unlockText = "Skin can be unlocked by "
		if skin.Requirement.Value == "Formable" then
			local unlockText2 = unlockText .. " Forming " .. skin.Requirement.Form.Value
			if skin.Requirement.As.Value ~= "ANY" then
				unlockText2 = unlockText2 .. " as " .. skin.Requirement.As.Value
			end
			unlockText = unlockText2 .. "\nin a PUBLIC server"
		end
		MakeMouseOver(frame.Button, unlockText, 14)
	end
	if skin:FindFirstChild("Gamepass") then
		frame.Gamepass.Visible = true
	end
	task.spawn(UpdateButtonStatus, frame, skin)
	local camera = Instance.new("Camera")
	camera.Parent = frame.PreviewFrame
	camera.CFrame = CFrame.new(Vector3.new(-25, 12.5, -25), (Vector3.new(0, 0, 0)))
	camera.Focus = CFrame.new()
	camera.FieldOfView = 1
	frame.PreviewFrame.CurrentCamera = camera
	local tankModel = Assets.UnitModels[skin.Name].Tank:Clone()
	tankModel.Name = "Model"
	tankModel:PivotTo(CFrame.new() * CFrame.Angles(0, math.pi / 2, math.pi / 2))
	tankModel.Parent = frame.PreviewFrame
	local skinModels = {}
	for i, model in pairs(Assets.UnitModels[skin.Name]:GetChildren()) do
		if model.Name ~= "Transport" then
			table.insert(skinModels, model)
		end
	end
	table.sort(skinModels, function(p1719, p1720)
		-- upvalues: (copy) Assets
		return Assets.UnitStats[p1719.Name].TransverseType.Value .. p1719.Name
			< Assets.UnitStats[p1720.Name].TransverseType.Value .. p1720.Name
	end)
	if Assets.UnitModels[skin.Name]:FindFirstChild("Transport") then
		table.insert(skinModels, Assets.UnitModels[skin.Name].Transport)
	end
	local tankModelIndex = table.find(skinModels, Assets.UnitModels[skin.Name].Tank)
	frame.PreviewFrame.Next.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (ref) tankModelIndex, (copy) skinModels, (copy) frame
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		tankModelIndex = math.clamp(tankModelIndex + 1, 1, #skinModels)
		frame.PreviewFrame.Model:Destroy()
		local tankModel = skinModels[tankModelIndex]:Clone()
		tankModel.Name = "Model"
		local offset = 0
		if Assets.UnitStats:FindFirstChild(skinModels[tankModelIndex].Name) then
			offset = Assets.UnitStats[skinModels[tankModelIndex].Name].TransverseType.Value == "Air" and -0.175
				or offset
		end
		tankModel:PivotTo(CFrame.new(0, offset, 0) * CFrame.Angles(0, math.pi / 2, math.pi / 2))
		tankModel.Parent = frame.PreviewFrame
		frame.PreviewFrame.Title.Text = skinModels[tankModelIndex].Name
	end)
	frame.PreviewFrame.Previous.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (ref) tankModelIndex, (copy) skinModels, (copy) frame
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		tankModelIndex = math.clamp(tankModelIndex - 1, 1, #skinModels)
		frame.PreviewFrame.Model:Destroy()
		local tankModel = skinModels[tankModelIndex]:Clone()
		tankModel.Name = "Model"
		local offset = 0
		if Assets.UnitStats:FindFirstChild(skinModels[tankModelIndex].Name) then
			offset = Assets.UnitStats[skinModels[tankModelIndex].Name].TransverseType.Value == "Air" and -0.175
				or offset
		end
		tankModel:PivotTo(CFrame.new(0, offset, 0) * CFrame.Angles(0, math.pi / 2, math.pi / 2))
		tankModel.Parent = frame.PreviewFrame
		frame.PreviewFrame.Title.Text = skinModels[tankModelIndex].Name
	end)
end
local function UpdatePreview(frame, text, modelName)
	-- upvalues: (copy) Assets
	if frame.PreviewFrame:FindFirstChild("Model") then
		frame.PreviewFrame.Model:Destroy()
	end
	local modelName2 = not Assets.UnitModels[modelName]:FindFirstChild(text) and "Default" or modelName
	local model = Assets.UnitModels[modelName2][text]:Clone()
	model.Name = "Model"
	local offset = 0
	if Assets.UnitStats:FindFirstChild(text) then
		offset = Assets.UnitStats[text].TransverseType.Value == "Air" and -0.175 or offset
	end
	model:PivotTo(CFrame.new(0, offset, 0) * CFrame.Angles(0, math.pi / 2, math.pi / 2))
	model.Parent = frame.PreviewFrame
	frame.Title.Text = modelName2
end
local function UpdateListing(frame)
	-- upvalues: (copy) ClearList, (copy) Assets, (copy) LocalPlayer, (copy) GameGui, (copy) UpdatePreview
	ClearList(frame.SkinList.List)
	for i, model in pairs(Assets.UnitModels:GetChildren()) do
		if model:FindFirstChild(frame.PreviewFrame.Title.Text) then
			task.spawn(function()
				-- upvalues: (ref) LocalPlayer, (copy) i, (copy) frame, (ref) Assets, (ref) GameGui, (ref) UpdatePreview
				if require(workspace.FunctionDump.ValueCalc.GetRequirement).SkinOwnership(LocalPlayer, model.Name) then
					local button = frame.SkinList.List.Sample:Clone()
					button.Name = model.Name
					button.Text = model.Name
					button.Parent = frame.SkinList
					if model.Name == "Default" then
						button.LayoutOrder = -1
					end
					button.MouseButton1Click:Connect(function()
						-- upvalues: (ref) Assets, (ref) GameGui, (ref) UpdatePreview, (ref) frame,  (ref) i
						local clickSound = Assets.Audio.Click_2:Clone()
						clickSound.Parent = GameGui
						clickSound:Play()
						game.Debris:AddItem(clickSound, 15)
						UpdatePreview(frame, frame.PreviewFrame.Title.Text, model.Name)
					end)
				end
			end)
		end
	end
end
MainFrame.SkinFrame.SkinList.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.SkinFrame.List.Visible = true
	MainFrame.SkinFrame.CustomSkinList.Visible = false
end)
MainFrame.SkinFrame.CustomSkin.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame, (copy) UpdateListing, (copy) LocalPlayer, (copy) UpdatePreview
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.SkinFrame.List.Visible = false
	MainFrame.SkinFrame.CustomSkinList.Visible = true
	for i, v in pairs(MainFrame.SkinFrame.CustomSkinList:GetChildren()) do
		if v:IsA("Frame") then
			UpdateListing(v)
			if LocalPlayer.SkinChoice:FindFirstChild(v.Name) then
				UpdatePreview(v, v.Name, LocalPlayer.SkinChoice[v.Name].Value)
			else
				UpdatePreview(v, v.Name, LocalPlayer.SkinChoice.Value)
			end
		end
	end
end)
local unitStats = Assets.UnitStats:GetChildren()
table.sort(unitStats, function(a, b)
	return a.TransverseType.Value .. a.Name < b.TransverseType.Value .. b.Name
end)
table.insert(unitStats, {
	["Name"] = "Transport",
})
for i, unitStat in pairs(unitStats) do
	local frame = MainFrame.SkinFrame.CustomSkinList.List.Sample:Clone()
	frame.Name = unitStat.Name
	frame.PreviewFrame.Title.Text = unitStat.Name
	frame.LayoutOrder = i
	frame.Parent = MainFrame.SkinFrame.CustomSkinList
	local camera = Instance.new("Camera")
	camera.Parent = frame.PreviewFrame
	camera.CFrame = CFrame.new(Vector3.new(-25, 12.5, -25), (Vector3.new(0, 0, 0)))
	camera.Focus = CFrame.new()
	camera.FieldOfView = 1
	frame.PreviewFrame.CurrentCamera = camera
	if LocalPlayer.SkinChoice:FindFirstChild(unitStat.Name) then
		UpdatePreview(frame, unitStat.Name, LocalPlayer.SkinChoice[unitStat.Name].Value)
	else
		UpdatePreview(frame, unitStat.Name, LocalPlayer.SkinChoice.Value)
	end
end
MainFrame.SkinFrame.CustomSkinList.Apply.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	local equipped = {}
	for i, v in pairs(MainFrame.SkinFrame.CustomSkinList:GetChildren()) do
		if v:IsA("Frame") then
			table.insert(equipped, {
				["Unit"] = v.PreviewFrame.Title.Text,
				["Skin"] = v.Title.Text,
			})
		end
	end
	workspace.GameManager.ChangeProfile:InvokeServer("CustomSkin", equipped)
end)
MainFrame.TabMenu.Titles.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	MainFrame.TitleFrame.Visible = not MainFrame.TitleFrame.Visible
	MainFrame.TabMenu.Visible = false
end)
local titles = Assets.Titles:GetChildren()
MainFrame.TitleFrame.List.CanvasSize = UDim2.new(0, 0, 0, #titles * 45)
for i, title in pairs(titles) do
	local frame = MainFrame.TitleFrame.List.List.Sample:Clone()
	frame.Name = title.Name
	frame.Title.TextColor3 = title.Value
	frame.Title.Text = title.Name
	frame.Parent = MainFrame.TitleFrame.List
	if frame.Name == "None" then
		frame.LayoutOrder = -10
	end
	frame.Button.MouseButton1Click:Connect(function()
		-- upvalues: (copy) Assets, (copy) GameGui, (copy) titles, (copy) i, (copy) LocalPlayer
		local clickSound = Assets.Audio.Click_2:Clone()
		clickSound.Parent = GameGui
		clickSound:Play()
		game.Debris:AddItem(clickSound, 15)
		local data = workspace.GameManager.ChangeProfile:InvokeServer("Title", title.Name)
		if data == "Yes" then
			Disengage()
		elseif data == "Buy" then
			game.MarketplaceService:PromptGamePassPurchase(LocalPlayer, title.Gamepass.Value)
		end
	end)
	if title:FindFirstChild("Requirement") then
		local text = "Title can be unlocked by "
		if title.Requirement.Value == "Formable" then
			local text2 = text .. " Forming " .. title.Requirement.Form.Value
			if title.Requirement.As.Value ~= "ANY" then
				text2 = text2 .. " as " .. title.Requirement.As.Value
			end
			text = text2 .. "\nin a PUBLIC server"
		elseif title.Requirement.Value == "XP" then
			text = text .. "having more than " .. title.Requirement.XP.Value .. " XP"
		end
		if title:GetAttribute("Description") then
			text = title:GetAttribute("Description")
		end
		MakeMouseOver(frame.Button, text, 14)
	end
	if title:FindFirstChild("Gamepass") then
		frame.Gamepass.Visible = true
	end
end
LocalPlayer:WaitForChild("FormableSave", 160)
for i, tag in pairs(workspace.CityPlacer.FormableTags.Reference:GetChildren()) do
	local frame = MainFrame.ProfileFrame.List.List.Sample:Clone()
	frame.Name = tag.Name
	frame.FormableName.Text = tag.Name
	SetFlag(frame.FormableFlag, tag.Name)
	frame.Parent = MainFrame.ProfileFrame.List
	for i, v in pairs(tag.FormedBy:GetChildren()) do
		local countryName = v.Value
		local flag = frame.CountryListFrame.List.Flag:Clone()
		flag.Name = countryName
		SetFlag(flag, countryName)
		flag.Parent = frame.CountryListFrame
		MakeMouseOver(flag, countryName, 14)
		frame.CountryListFrame.CanvasSize = frame.CountryListFrame.CanvasSize
			+ UDim2.new(0, flag.AbsoluteSize.X + 5, 0, 0)
		if LocalPlayer.FormableSave:FindFirstChild(tag.Name) then
			if LocalPlayer.FormableSave[tag.Name]:FindFirstChild(countryName) then
				flag.Check.Visible = true
			end
		end
	end
end
MainFrame.ProfileFrame.All.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	for i, v in pairs(MainFrame.ProfileFrame.List:GetChildren()) do
		if v:IsA("Frame") then
			v.Visible = true
		end
	end
end)
MainFrame.ProfileFrame.Uncompleted.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	for i, v in pairs(MainFrame.ProfileFrame.List:GetChildren()) do
		if v:IsA("Frame") then
			v.Visible = false
			local idk = true
			for i2, v2 in pairs(v.CountryListFrame:GetChildren()) do
				if v2:IsA("ImageButton") then
					if v2.Check.Visible then
						idk = false
						break
					end
				end
			end
			if idk then
				v.Visible = true
			end
		end
	end
end)
MainFrame.ProfileFrame.Completed.MouseButton1Click:Connect(function()
	-- upvalues: (copy) Assets, (copy) GameGui, (copy) MainFrame
	local clickSound = Assets.Audio.Click_2:Clone()
	clickSound.Parent = GameGui
	clickSound:Play()
	game.Debris:AddItem(clickSound, 15)
	for i, v in pairs(MainFrame.ProfileFrame.List:GetChildren()) do
		if v:IsA("Frame") then
			v.Visible = false
			for i2, v2 in pairs(v.CountryListFrame:GetChildren()) do
				if v2:IsA("ImageButton") then
					if v2.Check.Visible then
						v.Visible = true
						break
					end
				end
			end
		end
	end
end)
local profileSearchBox = MainFrame.ProfileFrame.SearchFrame.Box
local profileList = MainFrame.ProfileFrame.List
profileSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	-- upvalues: (copy) profileList, (copy) profileSearchBox
	for i, v in pairs(profileList:GetChildren()) do
		if v:IsA("GuiBase") then
			if v ~= profileSearchBox.Parent then
				if string.match(string.lower(v.Name), string.lower(profileSearchBox.Text)) == nil then
					v.Visible = false
				else
					v.Visible = true
				end
			end
		end
	end
end)
table.insert(loopFunctions, function()
	-- upvalues: (copy) MainFrame, (copy) ScaleScrollGui
	if MainFrame.ProfileFrame.Visible then
		local counter = 0
		for i, v in pairs(MainFrame.ProfileFrame.List:GetChildren()) do
			if v:IsA("Frame") then
				for i2, v2 in pairs(v.CountryListFrame:GetChildren()) do
					if v2:IsA("ImageButton") then
						if v2.Check.Visible then
							counter = counter + 1
							break
						end
					end
				end
			end
		end
		MainFrame.ProfileFrame.Shown.Text = counter
			.. " / "
			.. #workspace.CityPlacer.FormableTags.Reference:GetChildren()
			.. " Completed"
		ScaleScrollGui(MainFrame.ProfileFrame.List.List, "Y")
	end
end)
local function Explode(pos)
	-- upvalues: (ref) v_u_6, (copy) Assets
	if (workspace.CurrentCamera.CFrame.Position - pos).Magnitude < math.clamp(v_u_6 * 3, 7.5, 16) then
		local battleFlash = Assets.FX.BattleFlash:Clone()
		battleFlash.Position = pos
		battleFlash.Parent = workspace
		battleFlash.Sounds:GetChildren()[Random.new():NextInteger(1, 6)]:Play()
		game:GetService("TweenService")
			:Create(battleFlash, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
				["Size"] = Vector3.new(0.2, 0.2, 0.2),
				["Transparency"] = 1.15,
			})
			:Play()
		game:GetService("TweenService")
			:Create(battleFlash.BillboardGui.TextLabel, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
				["Size"] = UDim2.new(15, 0, 15, 0),
				["ImageTransparency"] = 1.3,
			})
			:Play()
		game.Debris:AddItem(battleFlash, 6)
	end
end
local function UnitRange(unit, radius)
	-- upvalues: (copy) Assets, (ref) currentCountryData, (copy) GameGui
	local explosion = Instance.new("Explosion")
	explosion.BlastPressure = 0
	explosion.BlastRadius = radius
	explosion.Visible = false
	explosion.Position = unit.Position
	explosion.Parent = workspace.Baseplate
	explosion.Hit:Connect(function(part, distance)
		-- upvalues: (copy) unit, (ref) Assets, (ref) currentCountryData, (ref) GameGui
		if part.Parent == workspace.Units then
			if
				unit ~= part
				and unit:GetAttribute("ShowModel")
				and distance < 0.08
				and part.Owner.Value == unit.Owner.Value
				and part.Type.Value == unit.Type.Value
				and part:GetAttribute("Transit") == unit:GetAttribute("Transit")
				and part.Stats.TransverseType.Value == unit.Stats.TransverseType.Value
			then
				part:SetAttribute("ShowModel", false)
				if part:GetAttribute("Transit") and part:FindFirstChild("Tag") then
					part.Tag.Adornee = unit.Tag.Adornee
				end
				part.Tag.Enabled = false
				unit:SetAttribute(
					"ActualCurrent",
					unit:GetAttribute("ActualCurrent") + part:GetAttribute("ActualCurrent")
				)
				unit.Tag:SetAttribute("NumberUnits", unit.Tag:GetAttribute("NumberUnits") + 1)
				unit.Tag.Frame.RegiCount.Text = unit.Tag:GetAttribute("NumberUnits") .. " Units"
				if 1000 <= unit:GetAttribute("ActualCurrent") then
					unit.Tag.Frame.Count.Text = math.ceil(unit:GetAttribute("ActualCurrent") / 100) / 10 .. "k"
				else
					unit.Tag.Frame.Count.Text = unit:GetAttribute("ActualCurrent")
				end
				if unit.Stats.TransverseType.Value == "Naval" or unit.Stats.TransverseType.Value == "Air" then
					unit.Tag.Frame.Count.Text = math.clamp(
						math.ceil(unit:GetAttribute("ActualCurrent") / Assets.UnitStats[unit.Type.Value].Value.X),
						1,
						1000000
					)
				end
			end
			if
				unit.Owner.Value == currentCountryData.Name
				and currentCountryData.Name ~= part.Owner.Value
				and part:FindFirstChild("Tag")
			then
				local isEnabled = GameGui.Enabled
				if part.Type.Value == "Submarine" then
					if unit.Stats.TransverseType.Value == "Naval" or unit.Stats.TransverseType.Value == "Sea" then
						if not part.Tag.Enabled then
							if unit.Type.Value ~= "Frigate" then
								if unit.Type.Value ~= "Destroyer" then
									if 0.75 < distance then
										isEnabled = false
									end
								end
							end
						end
					else
						isEnabled = false
					end
				end
				if not part:GetAttribute("ShowModel") then
					isEnabled = false
				end
				part.Tag.Enabled = isEnabled
			end
		end
	end)
end
local musicPlayer = LocalPlayer.PlayerGui:WaitForChild("MusicPlayer", 120)
MakeMouseOver(musicPlayer.MusicB, "", 14)
coroutine.resume(coroutine.create(function()
	-- upvalues: (ref) v_u_10, (copy) GameGui, (copy) ReferenceTable, (copy) PlayerXP, (copy) MapFrame, (ref) selected, (copy) SetFlag, (copy) MainFrame, (ref) tags, (ref) Units, (copy) loopFunctions2, (copy) LocalPlayer, (ref) currentCountryData, (ref) currentCountry, (copy) musicPlayer, (copy) loopFunctions, (copy) Assets, (copy) coefficient, (copy) Explode, (copy) OnScreen, (copy) CityRange, (copy) UnitRange, (copy) ClearList
	while wait(0.25) do
		local status, errorMessage = pcall(function()
			-- upvalues: (ref) v_u_10, (ref) GameGui, (ref) ReferenceTable, (ref) PlayerXP, (ref) MapFrame, (ref) selected, (ref) SetFlag, (ref) MainFrame, (ref) tags, (ref) Units, (ref) loopFunctions2, (ref) LocalPlayer, (ref) currentCountryData, (ref) currentCountry, (ref) musicPlayer, (ref) loopFunctions, (ref) Assets, (ref) coefficient, (ref) Explode, (ref) OnScreen, (ref) CityRange, (ref) UnitRange, (ref) ClearList
			v_u_10 = v_u_10 + 0.25
			GameGui.ID.Text = "Server ID: "
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. string.sub(workspace.ServerID.JobId.Value, 1, 6)
				.. "</font>"
				.. "\n"
				.. '<font color="rgb('
				.. ReferenceTable.Colors.Gold[1]
				.. ')">'
				.. PlayerXP.Value
				.. " XP"
				.. "</font>"
			if MapFrame.Visible then
				if #selected == 0 then
					MapFrame.CityFrame.Visible = false
				else
					MapFrame.CityFrame.Visible = true
				end
				if MapFrame.CityFrame.Visible then
					SetFlag(MapFrame.CityFrame.Main.Flag, selected[1].Parent.Name)
					local selectedPop = 0
					for i, v in pairs(selected) do
						selectedPop = selectedPop + v.Population.Value.X
					end
					local millions, thousands, hundrends = tostring(selectedPop):match("(%-?%d?)(%d*)(%.?.*)")
					MapFrame.CityFrame.Main.Population.Text = "Population: "
						.. millions
						.. thousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. hundrends
					if #selected == 1 then
						MapFrame.CityFrame.Main.CityName.Text = selected[1].Name
					else
						MapFrame.CityFrame.Main.CityName.Text = #selected .. " cities"
					end
					if workspace.CountryData[selected[1].Parent.Name].Capital.Value == selected[1] then
						MainFrame.CityFrame.Main.Flag.Capital.Visible = true
					else
						MainFrame.CityFrame.Main.Flag.Capital.Visible = false
					end
				end
				for i, v in pairs(selected) do
					if not v:FindFirstChild("SelectTag") then
						local selectTag = script.SelectTag:Clone()
						selectTag.Enabled = true
						selectTag.Parent = v
						table.insert(tags, selectTag)
					end
				end
			end
			Units = workspace.Units:GetChildren()
			for i, unit in pairs(game.CollectionService:GetTagged("TransportedUnits")) do
				table.insert(Units, unit)
			end
			for i, func in pairs(loopFunctions2) do
				func()
			end
			if LocalPlayer:GetAttribute("Country") then
				local idLabel = GameGui.ID
				idLabel.Text = idLabel.Text
					.. "\nXP Multiplier: "
					.. '<font color="rgb('
					.. ReferenceTable.Colors.Gold[1]
					.. ')">'
					.. math.ceil(currentCountryData.Requirement.Value.Y * 100) / 100
					.. "x"
					.. "</font>"
				local musicType = workspace.Wars:FindFirstChild(currentCountry, true) and "War"
					or (currentCountryData.Data.Stability.Value <= 40 or 5 <= currentCountryData.Power.WarExhaustion.Value) and "Hurt"
					or "Normal"
				if workspace:GetAttribute("NukeStrike") then
					musicType = os.time() - workspace:GetAttribute("NukeStrike") < 300 and "Nuke" or musicType
				end
				if musicPlayer.MusicB.Mode.Value ~= musicType then
					musicPlayer.MusicB.Mode.Value = musicType
				end
				for i, func in pairs(loopFunctions) do
					func()
				end
				MainFrame.TopBar.Date.Text = workspace.CountryManager.Date.Value
				if selected[1] ~= nil then
					for i, v in pairs(selected) do
						if not v:FindFirstChild("SelectTag") then
							local selectTag = script.SelectTag:Clone()
							selectTag.Enabled = true
							selectTag.Parent = v
							table.insert(tags, selectTag)
						end
						local range = v:FindFirstChild("Range", true)
						if range then
							if not range:FindFirstAncestor("Transport") then
								if v:FindFirstChild("RangeFinder") then
									v.RangeFinder.CFrame = v.CFrame * CFrame.new(0.1, 0, 0)
								else
									local rangeFinder = Assets.FX.RangeFinder:Clone()
									rangeFinder.CFrame = v.CFrame * CFrame.new(0.1, 0, 0)
									rangeFinder.Mesh.Scale =
										Vector3.new(0, range.Value / coefficient * 40, range.Value / coefficient * 40)
									rangeFinder.Parent = v
									table.insert(tags, rangeFinder)
								end
							end
						end
					end
				end
				if currentCountry ~= "" then
					local countryPop = 0
					for i, city in pairs(workspace.Baseplate.Cities[currentCountry]:GetChildren()) do
						countryPop = countryPop + city.Population.Value.X
						if 0 < city:GetAttribute("Unrest") then
							if not city:FindFirstChild("OccupiedTag") then
								script.OccupiedTag:Clone().Parent = city
							end
						elseif city:FindFirstChild("OccupiedTag") then
							city.OccupiedTag:Destroy()
						end
					end
					local countryPopMillions, countryPopThousands, countryPopHundrends =
						tostring(countryPop):match("(%-?%d?)(%d*)(%.?.*)")
					MainFrame.StatsFrame.Stats.Population.Text = "Population: "
						.. countryPopMillions
						.. countryPopThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. countryPopHundrends
					local populationChange = currentCountryData.Population:GetAttribute("PopulationChange")
					local mouseOverText = MainFrame.StatsFrame.Stats.Population.MouseOverText
					local populationChangeText = "Population Change in the last 5 days: "
					local populationChangeMillions, populationChangeThousands, populationChangeHundrends =
						tostring(populationChange):match("(%-?%d?)(%d*)(%.?.*)")
					local populationChangeText = populationChangeMillions
						.. populationChangeThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. populationChangeHundrends
					local goals = { 1, 1 }
					local colors = {
						ReferenceTable.Colors.Negative[1],
						ReferenceTable.Colors.Gold[1],
						ReferenceTable.Colors.Positive[1],
					}
					local color
					if populationChange < goals[1] then
						color = colors[1]
					elseif goals[1] <= populationChange and populationChange <= goals[2] then
						color = colors[2]
					elseif goals[2] < populationChange then
						color = colors[3]
					else
						color = nil
					end
					mouseOverText.Value = populationChangeText
						.. '<font color="rgb('
						.. color
						.. ')">'
						.. populationChangeText
						.. "</font>"
					local treasuryMillions, treasuryThousands, treasuryHundrends =
						tostring(currentCountryData.Economy.Balance.Value):match("(%-?%d?)(%d*)(%.?.*)")
					MainFrame.StatsFrame.Stats.Money.Text = "Treasury:   $"
						.. treasuryMillions
						.. treasuryThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. treasuryHundrends
					local manpowerMillions, manpowerThousands, manpowerHundrends =
						tostring(currentCountryData.Manpower.Value.X):match("(%-?%d?)(%d*)(%.?.*)")
					local manpower = manpowerMillions
						.. manpowerThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. manpowerHundrends
					local maxManpowerMillions, maxManpowerThousands, maxManpowerHundrends =
						tostring(currentCountryData.Manpower.Value.Z):match("(%-?%d?)(%d*)(%.?.*)")
					MainFrame.StatsFrame.Stats.Manpower.Text = "Manpower:  "
						.. manpower
						.. "  /  "
						.. maxManpowerMillions
						.. maxManpowerThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. maxManpowerHundrends
				end
				for i, v in pairs(MainFrame.SubGui:GetChildren()) do
					if v.Adornee == nil then
						v:Destroy()
					elseif v.Adornee:FindFirstChild(v.Name) then
						v.BarBack.Bar.Size = UDim2.new(v.Adornee[v.Name].Value.X / v.Adornee[v.Name].Value.Z, 0, 1, 0)
						if v.Name == "CaptureProgress" then
							if Random.new():NextInteger(0, 4) == 1 then
								Explode(
									v.Adornee.Position
										+ Vector3.new(
											Random.new():NextNumber(-0.25, 0.25),
											Random.new():NextNumber(-0.25, 0.25),
											Random.new():NextNumber(-0.25, 0.25)
										)
								)
							end
						end
					else
						v:Destroy()
					end
				end
				local unitsRef = Units
				local airAmount = 0
				local navyAmount = 0
				local tankAmount = 0
				local unitsTable = {}
				local infantryAmount = 0
				for i, unit in pairs(unitsRef) do
					unit:SetAttribute("ShowModel", true)
					unit:SetAttribute("ActualCurrent", 0)
					if unit.Owner.Value == currentCountryData.Name then
						if unit.Type.Value == "Infantry" then
							infantryAmount = infantryAmount + unit.Current.Value
						elseif unit.Type.Value == "Tank" then
							tankAmount = tankAmount + unit.Current.Value
						elseif unit.Stats.TransverseType.Value == "Naval" then
							navyAmount = navyAmount
								+ math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
						elseif unit.Stats.TransverseType.Value == "Air" then
							airAmount = airAmount
								+ math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
						end
						if unitsTable[unit.Type.Value] == nil then
							unitsTable[unit.Type.Value] = { 0, 0 }
						end
						local Table = unitsTable[unit.Type.Value]
						Table[2] = Table[2] + unit.Current.Upkeep.Value
						if unit.Stats.TransverseType.Value == "Naval" or unit.Stats.TransverseType.Value == "Air" then
							local Table = unitsTable[unit.Type.Value]
							Table[1] = Table[1]
								+ math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X)
						else
							local unit = unitsTable[unit.Type.Value]
							unit[1] = unit[1] + unit.Current.Value
						end
					end
					if OnScreen(unit.Position) then
						local tag = unit:FindFirstChild("Tag")
						if tag then
							tag:SetAttribute("NumberUnits", 1)
							if tag.Adornee ~= nil then
								local _ = tag.Adornee.Parent == nil
							end
							tag.Frame.BarBack.Bar.Size = UDim2.new(unit.Current.Value / unit.Stats.Value.X, 0, 1, 0)
							if 1000 <= unit.Current.Value then
								tag.Frame.Count.Text = math.ceil(unit.Current.Value / 100) / 10 .. "k"
							else
								tag.Frame.Count.Text = unit.Current.Value
							end
							unit:SetAttribute("ActualCurrent", unit.Current.Value)
							tag.Frame.RegiCount.Text = math.clamp(
								math.floor(unit.Stats.Value.X / Assets.UnitStats[unit.Type.Value].Value.X),
								1,
								1000000
							)
							if
								unit.Stats.TransverseType.Value == "Naval"
								or unit.Stats.TransverseType.Value == "Air"
							then
								tag.Frame.RegiCount.Text = ""
								tag.Frame.Count.Text = math.clamp(
									math.ceil(unit.Current.Value / Assets.UnitStats[unit.Type.Value].Value.X),
									1,
									1000000
								)
							end
							if unit:GetAttribute("Supply") <= 30 then
								tag.Frame.Supply.Visible = true
							else
								tag.Frame.Supply.Visible = false
							end
							if 90 <= unit.Current.Entrenchment.Value then
								tag.Frame.Entrench.Visible = true
							else
								tag.Frame.Entrench.Visible = false
							end
							tag.Frame.Repair.Visible = unit.Current:GetAttribute("Repairing") == true
							if unit.Current.Training.Value <= 60 then
								tag.Frame.XP.ImageRectOffset = Vector2.new(0, 0)
							elseif 60 < unit.Current.Training.Value and unit.Current.Training.Value <= 100 then
								tag.Frame.XP.ImageRectOffset = Vector2.new(27, 0)
							elseif 100 < unit.Current.Training.Value and unit.Current.Training.Value <= 150 then
								tag.Frame.XP.ImageRectOffset = Vector2.new(54, 0)
							elseif 150 < unit.Current.Training.Value and unit.Current.Training.Value <= 250 then
								tag.Frame.XP.ImageRectOffset = Vector2.new(81, 0)
							elseif 250 < unit.Current.Training.Value then
								tag.Frame.XP.ImageRectOffset = Vector2.new(108, 0)
							end
							SetFlag(tag.Frame.Flag, unit.Owner.Value)
							if unit.Owner.Value == currentCountryData.Name then
								tag.Frame.BackgroundColor3 = Color3.fromRGB(149, 255, 116)
								tag.Enabled = GameGui.Enabled
							else
								tag.Frame.BackgroundColor3 = Color3.fromRGB(60, 68, 76)
								tag.Enabled = false
								CityRange(unit, 2, "UnitTag")
								if
									require(workspace.FunctionDump.DiplomacyStatus).GetAllied(
										currentCountryData.Name,
										unit.Owner.Value
									)
								then
									tag.Enabled = GameGui.Enabled
									tag.Frame.BackgroundColor3 = Color3.fromRGB(39, 138, 199)
								end
								if
									require(workspace.FunctionDump.DiplomacyStatus).GetWarStatus(
										currentCountryData.Name,
										unit.Owner.Value,
										"Against"
									)
								then
									tag.Frame.BackgroundColor3 = Color3.fromRGB(199, 47, 47)
								end
							end
							UnitRange(unit, 1.5)
							if tag.Enabled then
								for i, v in pairs(unit.InBattle:GetChildren()) do
									if v.Value == nil then
										break
									end
									if Random.new():NextInteger(0, 2) == 1 then
										Explode(
											(unit.Position + v.Value.Position) / 2
												+ Vector3.new(
													Random.new():NextNumber(-0.25, 0.25),
													Random.new():NextNumber(-0.25, 0.25),
													Random.new():NextNumber(-0.25, 0.25)
												)
										)
									end
								end
								if unit:FindFirstChild("BombardFX") and 1 < Random.new():NextInteger(1, 3) then
									Explode(
										unit.Position
											+ Vector3.new(
												Random.new():NextNumber(-0.25, 0.25),
												Random.new():NextNumber(-0.25, 0.25),
												Random.new():NextNumber(-0.25, 0.25)
											)
									)
									if unit.BombardFX:FindFirstChild("Bomber") then
										Explode(
											unit.Position
												+ Vector3.new(
													Random.new():NextNumber(-0.65, 0.65),
													Random.new():NextNumber(-0.65, 0.65),
													Random.new():NextNumber(-0.65, 0.65)
												)
										)
									end
								end
								if
									unit.Current.Training.IsDoing.Value
									or unit.Current.Training:GetAttribute("BiomeTrainingOngoing")
								then
									if Random.new():NextInteger(0, 4) == 1 then
										Explode(
											unit.Position
												+ Vector3.new(
													Random.new():NextNumber(-0.25, 0.25),
													Random.new():NextNumber(-0.25, 0.25),
													Random.new():NextNumber(-0.25, 0.25)
												)
										)
									end
								end
							end
						else
							script.Tag:Clone().Parent = unit
						end
					end
				end
				local infantryAmountMillions, infantryAmountThousands, infantryAmountHundrends =
					tostring(infantryAmount):match("(%-?%d?)(%d*)(%.?.*)")
				local infantryAmountText = infantryAmountMillions
					.. infantryAmountThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. infantryAmountHundrends
				local tankAmountMillions, tankAmountThousands, tankAmountHundrends =
					tostring(tankAmount):match("(%-?%d?)(%d*)(%.?.*)")
				local tankAmountText = tankAmountMillions
					.. tankAmountThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. tankAmountHundrends
				local navyAmountMillions, navyAmountThousands, navyAmountHundrends =
					tostring(navyAmount):match("(%-?%d?)(%d*)(%.?.*)")
				local navyAmountText = navyAmountMillions
					.. navyAmountThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. navyAmountHundrends
				local airAmountMillions, airAmountThousands, airAmountHundrends =
					tostring(airAmount):match("(%-?%d?)(%d*)(%.?.*)")
				MainFrame.StatsFrame.Stats.Military.Text = "Troops: "
					.. infantryAmountText
					.. "  |  Tanks: "
					.. tankAmountText
					.. "  |  Ships: "
					.. navyAmountText
					.. "  |  Aircraft: "
					.. airAmountMillions
					.. airAmountThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
					.. airAmountHundrends
				local compositionText = "Military Composition:\n \n"
				for unitType, Table in pairs(unitsTable) do
					local amountMillions, amountThousands, amountHundrends =
						tostring(Table[1]):match("(%-?%d?)(%d*)(%.?.*)")
					compositionText = compositionText
						.. unitType
						.. ": "
						.. '<font color="rgb('
						.. ReferenceTable.Colors.Gold[1]
						.. ')">'
						.. amountMillions
						.. amountThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
						.. amountHundrends
						.. "</font>"
						.. "\n"
				end
				MainFrame.StatsFrame.Stats.Military.MouseOverText.Value = compositionText
				if MainFrame.CenterFrame.Visible and MainFrame.CenterFrame.MilitaryFrame.Visible then
					ClearList(MainFrame.CenterFrame.MilitaryFrame.Main.UnitFrame.List)
					for unitType, Table in pairs(unitsTable) do
						local frame = MainFrame.CenterFrame.MilitaryFrame.Main.UnitFrame.List.Sample:Clone()
						frame.Name = unitType
						frame.Type.Text = unitType
						local amountMillions, amountThousands, amountHundrends =
							tostring(Table[1]):match("(%-?%d?)(%d*)(%.?.*)")
						frame.Amount.Text = amountMillions
							.. amountThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
							.. amountHundrends
						local upkeepMillions, upkeepThousands, upkeepHundrends =
							tostring(Table[2]):match("(%-?%d?)(%d*)(%.?.*)")
						frame.Upkeep.Text = upkeepMillions
							.. upkeepThousands:reverse():gsub("(%d%d%d)", "%1 "):reverse()
							.. upkeepHundrends
						frame.Parent = MainFrame.CenterFrame.MilitaryFrame.Main.UnitFrame
					end
					return
				end
			elseif
				currentCountry ~= ""
				and currentCountryData.Leader.Value ~= currentCountry .. "AI"
				and currentCountryData.Leader.Value ~= LocalPlayer.Name
			then
				print("Restarted because player-country conflict")
				Disengage()
				workspace.GameManager.Abandon:FireServer()
			end
		end)
		if not status then
			warn(errorMessage)
		end
	end
end))
local newsTextLabels = {}
workspace.GameManager.NewsTicker.OnClientEvent:Connect(function(text, color)
	-- upvalues: (copy) MainFrame, (ref) newsTextLabels
	local textLabel = MainFrame.TopBar.Date.Sample:Clone()
	textLabel.Text = text
	textLabel.Visible = true
	textLabel.TextColor3 = color
	table.insert(newsTextLabels, textLabel)
	warn(#MainFrame.TopBar.Ticker:GetChildren() .. " in set", #newsTextLabels)
end)
table.insert(loopFunctions, function()
	-- upvalues: (ref) newsTextLabels, (copy) MainFrame
	for i, v in pairs(newsTextLabels) do
		local textLabel = v
		textLabel.Parent = MainFrame.TopBar.Ticker
		textLabel.Size = UDim2.new(0, textLabel.TextBounds.X + 75, 1, 0)
		local absoluteSizeX = MainFrame.TopBar.Ticker.AbsoluteSize.X
		local tickerChildren = MainFrame.TopBar.Ticker:GetChildren()
		print(textLabel.TextBounds.X, #tickerChildren)
		if 0 < #tickerChildren - 1 then
			absoluteSizeX = math.clamp(
				tickerChildren[#tickerChildren - 1].Position.X.Offset
					+ tickerChildren[#tickerChildren - 1].Size.X.Offset,
				MainFrame.TopBar.Ticker.AbsoluteSize.X,
				math.huge
			)
		end
		textLabel.Position = UDim2.new(0, absoluteSizeX, 0, 0)
		local tween = game:GetService("TweenService"):Create(
			textLabel,
			TweenInfo.new((textLabel.Position.X.Offset + textLabel.Size.X.Offset) / 100, Enum.EasingStyle.Linear),
			{
				["Position"] = UDim2.new(0, -textLabel.Size.X.Offset, 0, 0),
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			-- upvalues: (copy) textLabel
			wait(2)
			textLabel:Destroy()
		end)
	end
	newsTextLabels = {}
end)
game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
	-- upvalues: (ref) Units, (ref) v_u_6, (copy) Assets
	local deltaTime = math.clamp(deltaTime, 0, 1)
	if workspace.BattleManager.RenderUn.Value then
		local status, errorMessage = pcall(function()
			-- upvalues: (ref) Units, (ref) v_u_6, (copy) deltaTime, (ref) Assets
			local unitsRef = Units
			for i, unit in pairs(unitsRef) do
				unit:WaitForChild("Type", 60)
				unit:WaitForChild("Stats", 60)
				local unitSkin = workspace.CountryData[unit.Owner.Value].Skin:GetAttribute(
					string.gsub(unit.Type.Value, " ", "_")
				) or workspace.CountryData[unit.Owner.Value].Skin.Value
				local modelName = unit.Type.Value .. "Model" .. unitSkin
				local unitType = unit.Type.Value
				if unit.Stats.TransverseType.Value == "Sea" then
					modelName = "TransportModel" .. unitSkin
					unitType = "Transport"
				end
				local unitModel = unit:FindFirstChildOfClass("Model")
				if
					v_u_6 < 64
					and (unit.Position - workspace.CurrentCamera.CFrame.Position).Magnitude < math.clamp(
						v_u_6 * 3,
						7.5,
						math.huge
					)
					and unit:GetAttribute("ShowModel")
				then
					if unitModel then
						if unitModel.Name == modelName then
							if 0.04 < (unitModel.PrimaryPart.Position - unit.Position).Magnitude then
								unitModel:PivotTo(
									unitModel.PrimaryPart.CFrame:Lerp(unit.CFrame, deltaTime * unit.Stats.Value.Y)
								)
							end
							if unit:FindFirstChild("Tag") then
								if unit.Type.Value == "Submarine" and not unit.Tag.Enabled then
									unitModel:PivotTo(CFrame.new(unit.Position * 0.95))
								end
								unit.Tag.Adornee = unitModel.Base
								for i, child in pairs(unitModel:GetChildren()) do
									if child.Name == "Uniform" then
										child.Color = workspace.CountryData[unit.Owner.Value].C3.Value:Lerp(
											Color3.new(0, 0, 0),
											0.5
										)
									end
								end
							end
						else
							unitModel:Destroy()
						end
					else
						local unitModel
						if Assets.UnitModels[unitSkin]:FindFirstChild(unitType) then
							unitModel = Assets.UnitModels[unitSkin][unitType]:Clone()
						else
							unitModel = Assets.UnitModels.Default[unitType]:Clone()
						end
						unitModel.Name = unitModel.Name .. "Model" .. unitSkin
						if unit.Type.Value == "Submarine" then
							unitModel:PivotTo(CFrame.new(unit.Position * 0.9))
						else
							unitModel:PivotTo(unit.CFrame)
						end
						unitModel.Parent = unit
					end
				elseif unitModel then
					unitModel:Destroy()
				end
			end
		end)
		if not status then
			warn("! " .. errorMessage)
		end
	end
end)
workspace.CurrentCamera.CameraType = "Scriptable"
local v_u_1916 = Vector3.new(v_u_4, v_u_5, 0)
local v_u_1917 = v_u_6
game:GetService("RunService").RenderStepped:Connect(function()
	-- upvalues: (ref) isMobile, (copy) UserInputService, (ref) v_u_7, (ref) v_u_9, (ref) v_u_6, (ref) v_u_8, (ref) v_u_4, (ref) v_u_5, (ref) v_u_1916, (ref) v_u_1917, (copy) baseplateWidthDividedBy2
	if not isMobile then
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
			local mouseDelta = UserInputService:GetMouseDelta() / 8
			v_u_7 = mouseDelta.Y
			v_u_9 = mouseDelta.X
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			v_u_7 = 0
			v_u_9 = 0
		end
	end
	if v_u_6 < 0.1 and v_u_8 < 0 then
		v_u_8 = 0
	end
	if 0 < v_u_8 and 1000 < v_u_6 then
		v_u_8 = 0
	end
	v_u_4 = math.clamp(v_u_4 + v_u_7 * v_u_6 / 16, -90, 90)
	v_u_5 = v_u_5 + v_u_9 * v_u_6 / 16
	if math.sign(v_u_8) == -1 and 0.1 < v_u_6 or math.sign(v_u_8) == 1 and v_u_6 < 3200 then
		v_u_6 = v_u_6 + v_u_8 * v_u_6 / 16
	end
	script.AmbientAir.Volume = math.clamp(0.5 - v_u_6 / 30, 0, 0.5)
	v_u_1916 = v_u_1916:Lerp(
		Vector3.new(
			v_u_4,
			v_u_5,
			5 < v_u_6 and v_u_6 < 30 and 5 or v_u_6 < 5 and 1.5 < v_u_6 and 30 or v_u_6 < 1.5 and 60 or 0
		),
		0.2
	)
	v_u_1917 = Vector3.new(v_u_1917, 0, 0):Lerp(Vector3.new(v_u_6, 0, 0), 0.2).X
	game.Lighting.GeographicLatitude = -v_u_1916.Y - 25
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
		workspace.Baseplate.CFrame
			* CFrame.Angles(0, -math.rad(v_u_1916.Y + 180), 0)
			* CFrame.Angles(-math.rad(v_u_1916.X), 0, 0)
			* CFrame.new(0, 0, baseplateWidthDividedBy2 + v_u_1917)
			* CFrame.Angles(math.rad(v_u_1916.Z), 0, 0),
		1
	)
end)
script.AmbientAir:Play()
