getgenv().FarmChest = true
getgenv().HopServer = true
getgenv().FlySpeed = 300 -- tốc độ bay nhanh hơn
getgenv().JobHistoryFile = "JoinedServers.json"

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

--== LẤY NHÂN VẬT ==--
local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")
	return char, hrp, humanoid
end

--== FILE JOB HISTORY ==--
local function loadJobHistory()
	if isfile(getgenv().JobHistoryFile) then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(getgenv().JobHistoryFile))
		end)
		if ok and type(data) == "table" then
			return data
		end
	end
	writefile(getgenv().JobHistoryFile, "[]")
	return {}
end

local function saveJobHistory(list)
	writefile(getgenv().JobHistoryFile, HttpService:JSONEncode(list))
end

local function hasJoined(jobId)
	for _, id in ipairs(loadJobHistory()) do
		if id == jobId then
			return true
		end
	end
	return false
end

local function addJobId(jobId)
	local list = loadJobHistory()
	table.insert(list, jobId)
	saveJobHistory(list)
end

--== NOTIFY ==--
local function notify(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 2
		})
	end)
end

--== KIỂM TRA FIST ==--
local function hasFist()
	for _, v in pairs(player.Backpack:GetChildren()) do
		if v.Name == "Fist of Darkness" then
			return true
		end
	end
	local char = player.Character
	if char then
		for _, v in pairs(char:GetChildren()) do
			if v.Name == "Fist of Darkness" then
				return true
			end
		end
	end
	return false
end

--== BAY MƯỢT ==--
local function flyTo(targetCF)
	local _, hrp, humanoid = getCharacter()
	local distance = (hrp.Position - targetCF.Position).Magnitude
	local duration = math.clamp(distance / getgenv().FlySpeed, 0.05, 4)

	if hrp:FindFirstChild("FlyingTween") then
		hrp.FlyingTween:Destroy()
	end

	local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCF})
	tween.Name = "FlyingTween"
	tween.Parent = hrp
	tween:Play()
	tween.Completed:Wait()
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

--== FARM CHEST ==--
local function farmChests()
	local collected = {}
	local count = 0

	while getgenv().FarmChest do
		if hasFist() then
			notify("💎 Fist of Darkness", "Đã nhặt Fist! Dừng farm.", 5)
			getgenv().HopServer = false
			return true
		end

		local _, hrp = getCharacter()
		local chests = CollectionService:GetTagged("_ChestTagged")

		-- Lọc chest hợp lệ
		local validChests = {}
		for _, c in ipairs(chests) do
			if c and c:IsDescendantOf(workspace) and not collected[c] then
				table.insert(validChests, c)
			end
		end

		if #validChests == 0 then
			notify("✅ Hết rương", "Chuẩn bị đổi server...", 3)
			return false
		end

		-- Bay đến từng chest theo thứ tự (không cần gần nhất)
		for _, targetChest in ipairs(validChests) do
			if not getgenv().FarmChest then break end
			if hasFist() then return true end

			local chestPos = targetChest:GetPivot().Position
			flyTo(CFrame.new(chestPos + Vector3.new(0, 5, 0)))

			local timeout = tick() + 4
			repeat
				task.wait(0.05)
			until not targetChest:IsDescendantOf(workspace) or tick() > timeout

			collected[targetChest] = true

			if not targetChest:IsDescendantOf(workspace) then
				count += 1
				notify("💰 Chest +" .. count, "Nhặt thành công!", 0.8)
			end
		end
	end
end

--== HOP SERVER ==--
local function hopServer()
	if not getgenv().HopServer then return end
	local placeId = game.PlaceId
	local cursor = ""

	while task.wait(0.5) do
		local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
		if cursor ~= "" then url = url .. "&cursor=" .. cursor end

		local success, response = pcall(function()
			return game:HttpGet(url)
		end)
		if not success then
			task.wait(1)
			continue
		end

		local data = HttpService:JSONDecode(response)
		for _, server in ipairs(data.data) do
			if server.playing < server.maxPlayers and not hasJoined(server.id) then
				addJobId(server.id)
				notify("🌍 Hopping", "Server có " .. server.playing .. "/" .. server.maxPlayers .. " người", 2)
				TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
				return
			end
		end

		if not data.nextPageCursor then break end
		cursor = data.nextPageCursor
	end

	notify("⚠️ Hết server mới", "Không còn server khác để hop", 3)
end

--== MAIN ==--
task.spawn(function()
	while task.wait(0.5) do
		if hasFist() then
			notify("💎 Fist of Darkness", "Đã có Fist, dừng toàn bộ!", 5)
			break
		end

		local done = farmChests()
		if not done and not hasFist() then
			hopServer()
			break
		end
	end
end)
