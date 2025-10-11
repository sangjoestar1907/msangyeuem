getgenv().FarmChest = true
getgenv().HopServer = true
getgenv().FlySpeed = 325
getgenv().JobHistoryFile = "JoinedServers.json"

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    return char, hrp, humanoid
end

--== FILE LỊCH SỬ JOBID ==--
local function loadJobHistory()
    if isfile(getgenv().JobHistoryFile) then
        local content = readfile(getgenv().JobHistoryFile)
        local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
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
            Duration = duration or 3
        })
    end)
end

--== CHECK FIST ==--
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
    local duration = distance / getgenv().FlySpeed
    local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCF})
    tween:Play()
    tween.Completed:Wait()
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping) -- nhảy khi đến
end

--== FARM CHEST ==--
local function getNearestChest()
    local _, hrp = getCharacter()
    local chests = CollectionService:GetTagged("_ChestTagged")
    local nearest, dist = nil, math.huge

    for _, chest in ipairs(chests) do
        if chest and chest:IsDescendantOf(workspace) then
            local mag = (chest:GetPivot().Position - hrp.Position).Magnitude
            if mag < dist then
                dist = mag
                nearest = chest
            end
        end
    end
    return nearest
end

local function farmChests()
    local count = 0
    while task.wait(0.3) and getgenv().FarmChest do
        if hasFist() then
            notify("🛑 Dừng lại", "Đã có Fist of Darkness, không hop nữa!", 6)
            getgenv().HopServer = false
            return true
        end

        local chest = getNearestChest()
        if not chest then
            notify("✅ Hết rương", "Chuẩn bị đổi server...", 3)
            return false
        end

        local chestPos = chest:GetPivot().Position
        flyTo(CFrame.new(chestPos + Vector3.new(0, 5, 0)))
        count += 1
        notify("💰 Farm Chest", "Đã nhặt " .. count .. " rương", 1.5)
    end
    return true
end

--== HOP SERVER ==--
local function hopServer()
    if not getgenv().HopServer then return end
    local placeId = game.PlaceId
    local cursor = ""

    while task.wait(1) do
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then url = url .. "&cursor=" .. cursor end

        local success, response = pcall(game.HttpGet, game, url)
        if not success then continue end

        local data = HttpService:JSONDecode(response)
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and not hasJoined(server.id) then
                addJobId(server.id)
                notify("🌍 Đang đổi server", "Server có " .. server.playing .. " người", 3)
                TeleportService:TeleportToPlaceInstance(placeId, server.id, player)
                return
            end
        end

        if not data.nextPageCursor then break end
        cursor = data.nextPageCursor
    end

    notify("⚠️ Hết server mới", "Không còn server khác để hop", 4)
end

--== MAIN ==--
task.spawn(function()
    while task.wait(1) do
        if hasFist() then
            notify("💎 Phát hiện Fist of Darkness", "Dừng farm & không hop.", 6)
            break
        end

        local done = farmChests()
        if not done and not hasFist() then
            hopServer()
            break
        end
    end
end)
