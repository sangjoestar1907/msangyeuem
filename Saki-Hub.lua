local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local placeId = game.PlaceId

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "tung tung sahur"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 130)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "uzuzazi"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = frame

local jobBox = Instance.new("TextBox")
jobBox.Size = UDim2.new(1, -16, 0, 22)
jobBox.Position = UDim2.new(0, 8, 0, 30)
jobBox.PlaceholderText = "Paste JobId here"
jobBox.Text = ""
jobBox.ClearTextOnFocus = false
jobBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
jobBox.TextColor3 = Color3.new(1,1,1)
jobBox.Parent = frame

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0, 80, 0, 22)
delayLabel.Position = UDim2.new(0, 8, 0, 60)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Delay (s)"
delayLabel.TextColor3 = Color3.new(1,1,1)
delayLabel.Font = Enum.Font.SourceSans
delayLabel.TextSize = 14
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = frame

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(0, 60, 0, 22)
delayBox.Position = UDim2.new(0, 100, 0, 60)
delayBox.PlaceholderText = "3"
delayBox.Text = "3"
delayBox.ClearTextOnFocus = false
delayBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
delayBox.TextColor3 = Color3.new(1,1,1)
delayBox.Parent = frame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 90, 0, 24)
startBtn.Position = UDim2.new(0, 8, 0, 90)
startBtn.Text = "Start"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 14
startBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.Parent = frame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 90, 0, 24)
stopBtn.Position = UDim2.new(0, 114, 0, 90)
stopBtn.Text = "Stop"
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 14
stopBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Parent = frame

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 6)
corner1.Parent = startBtn

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 6)
corner2.Parent = stopBtn

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -8, 0, 18)
status.Position = UDim2.new(0, 4, 0, 116)
status.BackgroundTransparency = 1
status.Text = "Status: Stopped"
status.TextColor3 = Color3.fromRGB(255, 80, 80)
status.Font = Enum.Font.SourceSansBold
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local running = false
local workerThread

local function updateStatus(text, color)
	status.Text = text
	status.TextColor3 = color
end

local function safeToNumber(s)
	local ok, n = pcall(function() return tonumber(s) end)
	if not ok then return nil end
	return n
end

startBtn.MouseButton1Click:Connect(function()
	if running then return end
	local jobId = tostring(jobBox.Text):gsub("^%s*(.-)%s*$","%1")
	if jobId == "" then
		updateStatus("JobId not entered", Color3.fromRGB(255, 200, 80))
		return
	end

	local delayNum = safeToNumber(delayBox.Text) or 3
	if delayNum < 0.1 then delayNum = 0.1 end

	running = true
	updateStatus("Status: Joining...", Color3.fromRGB(80, 255, 80))

	workerThread = coroutine.create(function()
		while running do
			local ok, err = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
			end)
			if not ok then
				updateStatus("Teleport error", Color3.fromRGB(255,80,80))
			end
			task.wait(delayNum)
		end
	end)
	coroutine.resume(workerThread)
end)

stopBtn.MouseButton1Click:Connect(function()
	if not running then
		updateStatus("Status: Stopped", Color3.fromRGB(255, 80, 80))
		return
	end
	running = false
	updateStatus("Status: Stopped", Color3.fromRGB(255, 80, 80))
end)

player.AncestryChanged:Connect(function()
	if not player:IsDescendantOf(game) then
		running = false
	end
end)
