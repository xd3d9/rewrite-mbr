local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData")

local PlayerBoosts = {}
local PlayerData = {} -- This will hold all player data including skins, coins, etc.

local ShopModule = require(ReplicatedStorage:WaitForChild("Shop"):WaitForChild("ShopModule"))

print("🚀 ENHANCED SERVER SCRIPT STARTING...")

local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = ReplicatedStorage
	print("✅ Created Events folder")
else
	print("✅ Events folder already exists")
end

local EquipSkinEvent = eventsFolder:FindFirstChild("EquipSkin")
if not EquipSkinEvent then
	EquipSkinEvent = Instance.new("RemoteEvent")
	EquipSkinEvent.Name = "EquipSkin"
	EquipSkinEvent.Parent = eventsFolder
end

local UnequipSkinEvent = eventsFolder:FindFirstChild("UnequipSkin")
if not UnequipSkinEvent then
	UnequipSkinEvent = Instance.new("RemoteEvent")
	UnequipSkinEvent.Name = "UnequipSkin"
	UnequipSkinEvent.Parent = eventsFolder
end

local BoostUpdateEvent = eventsFolder:FindFirstChild("BoostUpdate")
if not BoostUpdateEvent then
	BoostUpdateEvent = Instance.new("RemoteEvent")
	BoostUpdateEvent.Name = "BoostUpdate"
	BoostUpdateEvent.Parent = eventsFolder
end

local PurchaseEvent = eventsFolder:FindFirstChild("PurchaseItem")
if not PurchaseEvent then
	PurchaseEvent = Instance.new("RemoteEvent")
	PurchaseEvent.Name = "PurchaseItem"
	PurchaseEvent.Parent = eventsFolder
end

print("✅ All remote events created/found")

local function getDefaultPlayerData()
	return {
		Coins = 500,
		OwnedSkins = {"Default"},
		CurrentSkin = "Default",
		BoostTimers = {
			Speed = 0,
			Jump = 0
		}
	}
end

local function savePlayerData(player)
	if not PlayerData[player] then return end

	local success, errorMessage = pcall(function()
		PlayerDataStore:SetAsync(player.UserId, PlayerData[player])
	end)

	if success then
		print("💾 Saved data for:", player.Name)
	else
		warn("❌ Failed to save data for", player.Name, ":", errorMessage)
	end
end

local function loadPlayerData(player)
	local data = getDefaultPlayerData()

	local success, savedData = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if success and savedData then
		for key, value in pairs(savedData) do
			data[key] = value
		end
		print("📂 Loaded data for:", player.Name)
	else
		print("📝 Using default data for:", player.Name)
	end

	return data
end

local function applySkinToCharacter(character, skinName)
	if not character then 
		warn("❌ No character provided")
		return 
	end

	-- Wait for character to be fully loaded
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then 
		warn("❌ No humanoid found in character")
		return 
	end

	-- Wait a bit more for character to be fully spawned
	task.wait(0.5)

	print("🎨 Applying skin:", skinName, "to character:", character.Name)

	-- Remove existing clothing and accessories
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") then
			item:Destroy()
		end
	end
	print("   🧹 Removed existing clothing and accessories")

	local skinsFolder = ReplicatedStorage:FindFirstChild("Skins")
	if not skinsFolder then 
		warn("❌ Skins folder not found in ReplicatedStorage")
		return 
	end

	local skinModel = skinsFolder:FindFirstChild(skinName)
	if not skinModel then 
		warn("❌ Skin model not found:", skinName)
		return 
	end

	-- Apply clothing and accessories
	for _, item in ipairs(skinModel:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("Accessory") then
			local clone = item:Clone()
			clone.Parent = character
			print("   🎽 Applied clothing item:", item.Name, "to character")
		end
	end

	-- Apply body part properties
	local bodyParts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

	for _, partName in ipairs(bodyParts) do
		local characterPart = character:FindFirstChild(partName)
		local skinPart = skinModel:FindFirstChild(partName)

		if characterPart and skinPart then
			characterPart.BrickColor = skinPart.BrickColor
			characterPart.Material = skinPart.Material

			for _, surfaceName in ipairs({"Front", "Back", "Left", "Right", "Top", "Bottom"}) do
				local surfaceProperty = surfaceName .. "Surface"
				if skinPart[surfaceProperty] then
					characterPart[surfaceProperty] = skinPart[surfaceProperty]
				end
			end

			print("   🎨 Applied", partName, "properties from skin")
		end
	end

	-- Apply body colors
	local skinBodyColors = skinModel:FindFirstChild("Body Colors")
	if skinBodyColors then
		local characterBodyColors = character:FindFirstChild("Body Colors")
		if not characterBodyColors then
			characterBodyColors = Instance.new("BodyColors")
			characterBodyColors.Parent = character
		end

		characterBodyColors.HeadColor3 = skinBodyColors.HeadColor3
		characterBodyColors.LeftArmColor3 = skinBodyColors.LeftArmColor3
		characterBodyColors.LeftLegColor3 = skinBodyColors.LeftLegColor3
		characterBodyColors.RightArmColor3 = skinBodyColors.RightArmColor3
		characterBodyColors.RightLegColor3 = skinBodyColors.RightLegColor3
		characterBodyColors.TorsoColor3 = skinBodyColors.TorsoColor3

		print("   🌈 Applied Body Colors from skin")
	end

	print("✅ Skin successfully applied:", skinName)
end

local function syncPlayerBoosts(player)
	if not PlayerBoosts[player] or not player.Character then
		return
	end

	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	print("🔄 Syncing boosts for", player.Name)

	if PlayerBoosts[player].SpeedTimeLeft > 0 then
		local newSpeed = PlayerBoosts[player].OriginalWalkSpeed + 20
		humanoid.WalkSpeed = newSpeed
		print("   🏃 Applied Speed boost - From:", PlayerBoosts[player].OriginalWalkSpeed, "To:", newSpeed, "TimeLeft:", PlayerBoosts[player].SpeedTimeLeft)

		local endTime = tick() + PlayerBoosts[player].SpeedTimeLeft
		BoostUpdateEvent:FireClient(player, "Speed", endTime)
	end

	if PlayerBoosts[player].JumpTimeLeft > 0 then
		local newJumpPower = PlayerBoosts[player].OriginalJumpPower + 100
		humanoid.JumpPower = newJumpPower
		print("   🦘 Applied Jump boost - From:", PlayerBoosts[player].OriginalJumpPower, "To:", newJumpPower, "TimeLeft:", PlayerBoosts[player].JumpTimeLeft)

		local endTime = tick() + PlayerBoosts[player].JumpTimeLeft
		BoostUpdateEvent:FireClient(player, "Jump", endTime)
	end
end

local function applyBoost(player, boostType, amount, duration)
	if not player or not player.Character then
		warn("Cannot apply boost: No player or character")
		return
	end

	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		warn("Cannot apply boost: No humanoid found")
		return
	end

	if not PlayerBoosts[player] then
		PlayerBoosts[player] = {
			SpeedTimeLeft = 0,
			JumpTimeLeft = 0,
			OriginalWalkSpeed = humanoid.WalkSpeed,
			OriginalJumpPower = humanoid.JumpPower,
			ActiveConnection = nil
		}
	end

	print("Applying", boostType, "boost:", amount, "for", duration, "seconds to", player.Name)

	if boostType == "Speed" then
		PlayerBoosts[player].SpeedTimeLeft = PlayerBoosts[player].SpeedTimeLeft + duration
		humanoid.WalkSpeed = PlayerBoosts[player].OriginalWalkSpeed + amount
		print("Speed boost time remaining:", PlayerBoosts[player].SpeedTimeLeft, "seconds")

	elseif boostType == "Jump" then
		PlayerBoosts[player].JumpTimeLeft = PlayerBoosts[player].JumpTimeLeft + duration
		humanoid.JumpPower = PlayerBoosts[player].OriginalJumpPower + amount
		print("Jump boost time remaining:", PlayerBoosts[player].JumpTimeLeft, "seconds")
	end

	if PlayerData[player] then
		PlayerData[player].BoostTimers[boostType] = PlayerBoosts[player][boostType .. "TimeLeft"]
	end

	local currentTime = tick()
	local endTime = currentTime + PlayerBoosts[player][boostType .. "TimeLeft"]
	BoostUpdateEvent:FireClient(player, boostType, endTime)
	print("📡 Sent boost update to client:", boostType, "EndTime:", endTime, "Current:", currentTime, "TimeLeft:", PlayerBoosts[player][boostType .. "TimeLeft"])
end

local function startBoostCountdown()
	RunService.Heartbeat:Connect(function()
		for player, boostData in pairs(PlayerBoosts) do
			if player.Parent and player.Character then
				local character = player.Character
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if humanoid then
					local updated = false

					if boostData.SpeedTimeLeft > 0 then
						boostData.SpeedTimeLeft = boostData.SpeedTimeLeft - (1/30)
						if boostData.SpeedTimeLeft <= 0 then
							boostData.SpeedTimeLeft = 0
							humanoid.WalkSpeed = boostData.OriginalWalkSpeed
							print("Speed boost expired for", player.Name)
							updated = true
						end
					end

					if boostData.JumpTimeLeft > 0 then
						boostData.JumpTimeLeft = boostData.JumpTimeLeft - (1/30)
						if boostData.JumpTimeLeft <= 0 then
							boostData.JumpTimeLeft = 0
							humanoid.JumpPower = boostData.OriginalJumpPower
							print("Jump boost expired for", player.Name)
							updated = true
						end
					end

					if updated then
						local currentTime = tick()
						if boostData.SpeedTimeLeft <= 0 and humanoid.WalkSpeed ~= boostData.OriginalWalkSpeed then
							BoostUpdateEvent:FireClient(player, "Speed", 0)
							print("📡 Speed boost expired - notifying client")
						end

						if boostData.JumpTimeLeft <= 0 and humanoid.JumpPower ~= boostData.OriginalJumpPower then
							BoostUpdateEvent:FireClient(player, "Jump", 0)
							print("📡 Jump boost expired - notifying client")
						end
					end

					if PlayerData[player] then
						PlayerData[player].BoostTimers.Speed = boostData.SpeedTimeLeft
						PlayerData[player].BoostTimers.Jump = boostData.JumpTimeLeft
					end
				end
			end
		end
	end)
end

-- Handle fall damage/void respawn
local function handleFallBox()
	local killBox = workspace:FindFirstChild("FallBox")
	if killBox then
		killBox.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)

			if not player then return end

			print("💀 Player", player.Name, "fell into void - respawning...")

			-- Force respawn the player
			task.wait(0.1) -- Small delay to prevent issues
			if player.Character then
				player.Character.Humanoid.Health = 0
			end
		end)
		print("✅ Fall box respawn handler connected")
	else
		warn("❌ FallBox not found in workspace")
	end
end

startBoostCountdown()

-- FIXED PLAYER LOADING SYSTEM
Players.PlayerAdded:Connect(function(player)
	print("🎮 Player joined:", player.Name)

	-- Load player data first
	PlayerData[player] = loadPlayerData(player)

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = PlayerData[player].Coins
	coins.Parent = leaderstats

	print("💰 Created leaderstats for:", player.Name, "with", coins.Value, "coins")

	-- Initialize boost data with saved timers
	PlayerBoosts[player] = {
		SpeedTimeLeft = PlayerData[player].BoostTimers.Speed or 0,
		JumpTimeLeft = PlayerData[player].BoostTimers.Jump or 0,
		OriginalWalkSpeed = 16, -- Will be updated when character spawns
		OriginalJumpPower = 50, -- Will be updated when character spawns
	}

	print("🔄 Loaded boost data for", player.Name, "- Speed:", PlayerBoosts[player].SpeedTimeLeft, "Jump:", PlayerBoosts[player].JumpTimeLeft)

	-- Handle character spawning
	player.CharacterAdded:Connect(function(character)
		print("🏃 Character spawned for:", player.Name)

		-- Wait for character to be fully loaded with better error handling
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			warn("❌ Humanoid not found for:", player.Name)
			return
		end

		-- Wait for essential character parts to load
		local head = character:WaitForChild("Head", 5)
		local torso = character:WaitForChild("Torso", 5)
		
		if not head or not torso then
			warn("❌ Essential body parts not found for:", player.Name)
			return
		end
		
		-- Additional wait to ensure character is fully spawned and ready
		task.wait(2)

		-- Update original stats for boosts BEFORE applying any modifications
		if PlayerBoosts[player] then
			PlayerBoosts[player].OriginalWalkSpeed = humanoid.WalkSpeed
			PlayerBoosts[player].OriginalJumpPower = humanoid.JumpPower
			print("📊 Updated original stats for", player.Name, "- WalkSpeed:", humanoid.WalkSpeed, "JumpPower:", humanoid.JumpPower)
		end

		-- Apply current skin if it's not default (run in separate thread to avoid blocking)
		if PlayerData[player] and PlayerData[player].CurrentSkin and PlayerData[player].CurrentSkin ~= "Default" then
			print("🎨 Applying skin on spawn:", PlayerData[player].CurrentSkin, "for:", player.Name)
			task.spawn(function()
				applySkinToCharacter(character, PlayerData[player].CurrentSkin)
			end)
		end

		-- Wait a bit more then sync boosts (if any exist)
		task.wait(1)
		if PlayerBoosts[player] and (PlayerBoosts[player].SpeedTimeLeft > 0 or PlayerBoosts[player].JumpTimeLeft > 0) then
			print("🔄 Syncing existing boosts for:", player.Name)
			task.spawn(function()
				syncPlayerBoosts(player)
			end)
		end

		-- Send skin data to client after character is fully ready
		task.wait(0.5)
		if player.Parent then
			pcall(function()
				EquipSkinEvent:FireClient(player, "INIT", {
					OwnedSkins = PlayerData[player].OwnedSkins,
					CurrentSkin = PlayerData[player].CurrentSkin
				})
				print("📤 Sent character-ready skin data to:", player.Name)
			end)
		end
	end)

	-- Send initial skin data for UI (separate from character spawning)
	-- This ensures the UI gets data even if character hasn't spawned yet
	task.spawn(function()
		task.wait(3) -- Wait longer to ensure client is fully ready
		if player.Parent then
			pcall(function()
				EquipSkinEvent:FireClient(player, "INIT", {
					OwnedSkins = PlayerData[player].OwnedSkins,
					CurrentSkin = PlayerData[player].CurrentSkin
				})
				print("📤 Sent initial UI skin data to:", player.Name)
			end)
		end
	end)
end)

EquipSkinEvent.OnServerEvent:Connect(function(player, action, skinName)
	print("🎨 EquipSkinEvent:", player.Name, action, skinName or "nil")

	if not PlayerData[player] then
		PlayerData[player] = getDefaultPlayerData()
		print("🔧 Initialized player data")
	end

	if action == "GET_DATA" then
		EquipSkinEvent:FireClient(player, "INIT", {
			OwnedSkins = PlayerData[player].OwnedSkins,
			CurrentSkin = PlayerData[player].CurrentSkin
		})
		print("📤 Sent skin data to:", player.Name)

	elseif action == "EQUIP" and skinName then
		if table.find(PlayerData[player].OwnedSkins, skinName) then
			PlayerData[player].CurrentSkin = skinName

			if player.Character then
				applySkinToCharacter(player.Character, skinName)
			end

			EquipSkinEvent:FireClient(player, "EQUIPPED", skinName)
			print("✅ Equipped skin:", skinName, "for:", player.Name)

			savePlayerData(player)
		else
			warn("❌ Player", player.Name, "doesn't own skin:", skinName)
		end

	elseif action == "UNEQUIP" then
		PlayerData[player].CurrentSkin = "Default"

		if player.Character then
			applySkinToCharacter(player.Character, "Default")
		end

		EquipSkinEvent:FireClient(player, "UNEQUIPPED")
		UnequipSkinEvent:FireClient(player)
		print("✅ Unequipped skin for:", player.Name)

		savePlayerData(player)
	end
end)

UnequipSkinEvent.OnServerEvent:Connect(function(player)
	print("🔄 === UNEQUIP EVENT RECEIVED ===")
	print("   Player:", player and player.Name or "NIL")

	if not player or not player.Parent then
		warn("❌ Invalid player for unequip")
		return
	end

	if not PlayerData[player] then
		PlayerData[player] = getDefaultPlayerData()
	end

	local oldSkin = PlayerData[player].CurrentSkin
	PlayerData[player].CurrentSkin = "Default"

	if player.Character then
		applySkinToCharacter(player.Character, "Default")
	end

	UnequipSkinEvent:FireClient(player)
	EquipSkinEvent:FireClient(player, "INIT", {
		OwnedSkins = PlayerData[player].OwnedSkins,
		CurrentSkin = PlayerData[player].CurrentSkin
	})

	print("✅ Unequipped skin for:", player.Name)

	savePlayerData(player)
end)

PurchaseEvent.OnServerEvent:Connect(function(player, itemName, page)
	print("💳 === PURCHASE EVENT RECEIVED ===")
	print("   Player:", player and player.Name or "NIL")
	print("   Item:", itemName or "NIL")
	print("   Page:", page or "NIL")

	if not player or not player.Parent or not itemName or not page then
		warn("❌ Invalid purchase parameters")
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")

	if not coins then
		warn("❌ No coins found for player:", player.Name)
		return
	end

	local items = ShopModule:GetItems(page)
	local itemData = nil

	for _, item in pairs(items) do
		if item.Name == itemName then
			itemData = item
			break
		end
	end

	if not itemData then
		warn("❌ Item not found in shop:", itemName, "on page:", page)
		return
	end

	print("   💲 Item price:", itemData.Price)
	print("   💰 Current coins:", coins.Value)

	if coins.Value < itemData.Price then
		print("❌ Not enough coins. Has:", coins.Value, "Needs:", itemData.Price)
		return
	end

	coins.Value = coins.Value - itemData.Price
	PlayerData[player].Coins = coins.Value
	print("✅ Purchase successful! New balance:", coins.Value)

	if page == "Skins" then
		print("   🎨 Processing skin purchase...")

		if not table.find(PlayerData[player].OwnedSkins, itemName) then
			table.insert(PlayerData[player].OwnedSkins, itemName)
			print("   ✅ Added skin to owned list:", itemName)

			EquipSkinEvent:FireClient(player, "INIT", {
				OwnedSkins = PlayerData[player].OwnedSkins,
				CurrentSkin = PlayerData[player].CurrentSkin
			})
			print("   📤 Sent updated skin data to client")
		end

	elseif page == "Consumables" or page == "Powers" then
		print("   🧪 Processing consumable/power purchase:", itemName)
		print("   📋 Item data:", itemData.Name, "Price:", itemData.Price)

		if itemData.ApplyEffect then
			-- Custom effect function
			itemData.ApplyEffect(player)
			print("   ✅ Applied custom effect for", itemName, "to", player.Name)
		elseif itemData.BoostType and itemData.Amount and itemData.Duration then
			-- Direct boost properties
			applyBoost(player, itemData.BoostType, itemData.Amount, itemData.Duration)
			print("   ✅ Applied stacking boost:", itemData.BoostType, "Amount:", itemData.Amount, "Duration:", itemData.Duration)
		elseif itemData.Boost then
			-- Nested boost structure
			local boost = itemData.Boost
			if boost.Type and boost.Amount and boost.Duration then
				applyBoost(player, boost.Type, boost.Amount, boost.Duration)
				print("   ✅ Applied nested boost:", boost.Type, "Amount:", boost.Amount, "Duration:", boost.Duration)
			end
		else
			local defaultEffects = {
				["Jump Coil"] = {BoostType = "Jump", Amount = 100, Duration = 10},
				["Speed Coil"] = {BoostType = "Speed", Amount = 20, Duration = 5},
				["SUPER JUMP"] = {BoostType = "Jump", Amount = 100, Duration = 999999},
				["SUPER SPEED"] = {BoostType = "Speed", Amount = 20, Duration = 999999}
			}

			local defaultEffect = defaultEffects[itemName]
			if defaultEffect then
				applyBoost(player, defaultEffect.BoostType, defaultEffect.Amount, defaultEffect.Duration)
				print("   ✅ Applied default effect for", itemName, ":", defaultEffect.BoostType)
			else
				warn("   ❌ No effect defined for:", itemName, "- Item structure:", itemData)
			end
		end
	end

	savePlayerData(player)
	print("💳 === PURCHASE PROCESSING COMPLETE ===")
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)

	if PlayerBoosts[player] then
		PlayerBoosts[player] = nil
	end

	PlayerData[player] = nil
	print("🧹 Cleaned up and saved data for:", player.Name)
end)

-- Auto-save system
spawn(function()
	while true do
		wait(300) -- 5 minutes
		for player, _ in pairs(PlayerData) do
			if player.Parent then
				savePlayerData(player)
			end
		end
		print("💾 Auto-saved all player data")
	end
end)

-- Initialize fall box handler after a delay to ensure workspace is loaded
task.wait(2)
handleFallBox()