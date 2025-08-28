-- BoostGUI.lua - Client-side script to display boost timers
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for Events folder and BoostUpdate event
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
if not eventsFolder then
	warn("❌ Events folder not found in ReplicatedStorage")
	return
end

local boostUpdateEvent = eventsFolder:WaitForChild("BoostUpdate", 10)
if not boostUpdateEvent then
	warn("❌ BoostUpdate event not found in Events folder")
	return
end

print("✅ BoostGUI script loaded successfully")

-- Boost data storage
local activeBoosts = {
	Speed = {
		active = false,
		endTime = 0,
		gui = nil
	},
	Jump = {
		active = false,
		endTime = 0,
		gui = nil
	}
}

-- Create the main boost GUI container
local function createBoostGUI()
	-- Remove existing GUI if it exists
	local existingGui = playerGui:FindFirstChild("BoostGUI")
	if existingGui then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BoostGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Main frame to hold all boost displays
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 200, 0, 100)
	mainFrame.Position = UDim2.new(0, 10, 0, 10) -- Top-left corner
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = screenGui

	return screenGui, mainFrame
end

-- Create individual boost display
local function createBoostDisplay(boostType, parent)
	local frame = Instance.new("Frame")
	frame.Name = boostType .. "BoostFrame"
	frame.Size = UDim2.new(1, 0, 0, 40)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 2
	frame.Visible = false
	frame.Parent = parent

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	-- Add border
	local stroke = Instance.new("UIStroke")
	stroke.Color = boostType == "Speed" and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Icon/emoji
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 1, 0)
	icon.Position = UDim2.new(0, 5, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = boostType == "Speed" and "🏃" or "🦘"
	icon.TextScaled = true
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.Font = Enum.Font.SourceSansBold
	icon.Parent = frame

	-- Boost name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 60, 1, 0)
	nameLabel.Position = UDim2.new(0, 35, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = boostType:upper()
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = frame

	-- Time remaining label
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0, 90, 1, 0)
	timeLabel.Position = UDim2.new(0, 100, 0, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = "0:00"
	timeLabel.TextScaled = true
	timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeLabel.Font = Enum.Font.SourceSans
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.Parent = frame

	return frame
end

-- Format time for display
local function formatTime(seconds)
	if seconds <= 0 then
		return "0:00"
	end
	
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = math.floor(seconds % 60)
	
	if minutes > 0 then
		return string.format("%d:%02d", minutes, remainingSeconds)
	else
		return string.format("0:%02d", remainingSeconds)
	end
end

-- Update boost display
local function updateBoostDisplay(boostType)
	local boostData = activeBoosts[boostType]
	if not boostData.gui then return end
	
	local currentTime = tick()
	local timeLeft = math.max(0, boostData.endTime - currentTime)
	
	if timeLeft <= 0 then
		-- Hide the boost display
		boostData.active = false
		boostData.gui.Visible = false
		print("🔄 " .. boostType .. " boost expired - hiding GUI")
		return
	end
	
	-- Update time display
	local timeLabel = boostData.gui:FindFirstChild("TimeLabel")
	if timeLabel then
		timeLabel.Text = formatTime(timeLeft)
	end
	
	-- Show the boost display if it's not visible
	if not boostData.gui.Visible then
		boostData.gui.Visible = true
		
		-- Animate in
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tween = TweenService:Create(boostData.gui, tweenInfo, {
			Size = UDim2.new(1, 0, 0, 40)
		})
		tween:Play()
		
		print("✅ " .. boostType .. " boost GUI shown with time:", formatTime(timeLeft))
	end
end

-- Position boost displays
local function repositionBoostDisplays()
	local yOffset = 0
	for _, boostType in ipairs({"Speed", "Jump"}) do
		local boostData = activeBoosts[boostType]
		if boostData.gui and boostData.gui.Visible then
			boostData.gui.Position = UDim2.new(0, 0, 0, yOffset)
			yOffset = yOffset + 45 -- 40 height + 5 spacing
		end
	end
end

-- Initialize GUI
local screenGui, mainFrame = createBoostGUI()

-- Create boost displays
activeBoosts.Speed.gui = createBoostDisplay("Speed", mainFrame)
activeBoosts.Jump.gui = createBoostDisplay("Jump", mainFrame)

-- Handle boost updates from server
boostUpdateEvent.OnClientEvent:Connect(function(boostType, endTime)
	print("📡 Received boost update:", boostType, "EndTime:", endTime, "Current:", tick())
	
	if not activeBoosts[boostType] then
		warn("❌ Unknown boost type:", boostType)
		return
	end
	
	if endTime and endTime > 0 then
		-- Activate boost
		activeBoosts[boostType].active = true
		activeBoosts[boostType].endTime = endTime
		print("✅ Activated " .. boostType .. " boost GUI - EndTime:", endTime)
	else
		-- Deactivate boost
		activeBoosts[boostType].active = false
		activeBoosts[boostType].endTime = 0
		if activeBoosts[boostType].gui then
			activeBoosts[boostType].gui.Visible = false
		end
		print("❌ Deactivated " .. boostType .. " boost GUI")
	end
	
	-- Update displays and repositioning
	updateBoostDisplay(boostType)
	repositionBoostDisplays()
end)

-- Update timer displays every frame
local connection
connection = RunService.Heartbeat:Connect(function()
	local anyActive = false
	
	for boostType, boostData in pairs(activeBoosts) do
		if boostData.active then
			updateBoostDisplay(boostType)
			anyActive = true
		end
	end
	
	-- Reposition displays
	repositionBoostDisplays()
	
	-- If no boosts are active, we could disconnect this for performance
	-- but keeping it simple for now
end)

print("🎮 BoostGUI initialized successfully!")