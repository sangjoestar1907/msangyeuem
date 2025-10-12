--// Config
getgenv().AutoCyborg = true
getgenv().SelectWeapon = "Melee"
local TweenSpeed = 350
local HeightAboveOrder = 40
local hakiCooldown = 5
local lastHakiTime = 0
_G.FastAttack = true

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--// Helper
local function SafeWaitForChild(parent, name)
    local success, result = pcall(function() return parent:WaitForChild(name) end)
    if success then return result else return nil end
end

--// Equip Weapon
local function EquipWeapon(toolName)
    local char = player.Character or player.CharacterAdded:Wait()
    local backpack = player:WaitForChild("Backpack")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local function FindTool()
        for _, v in pairs(backpack:GetChildren()) do
            if v:IsA("Tool") and (string.find(v.Name:lower(), toolName:lower()) or (v:GetAttribute("WeaponType") == toolName)) then
                return v
            end
        end
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Tool") and (string.find(v.Name:lower(), toolName:lower()) or (v:GetAttribute("WeaponType") == toolName)) then
                return v
            end
        end
    end

    local tool = FindTool()
    if tool then humanoid:EquipTool(tool) end
end

--// Auto Haki
local function AutoHaki()
    if player.Character and not player.Character:FindFirstChild("HasBuso") then
        if tick() - lastHakiTime >= hakiCooldown then
            pcall(function() CommF:InvokeServer("Buso") end)
            lastHakiTime = tick()
        end
    end
end

--// Smooth Stay Above Target
local function SmoothStayAbove(targetHRP)
    if not targetHRP then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, HeightAboveOrder, 0))
end

--// Keep Player in Air
RunService.Heartbeat:Connect(function()
    if getgenv().AutoCyborg then
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

--// Check if Order exists and alive
local function OrderExists()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return false end
    local order = enemies:FindFirstChild("Order")
    if order and order:FindFirstChild("Humanoid") and order.Humanoid.Health > 0 and order:FindFirstChild("HumanoidRootPart") then
        return true
    else
        return false
    end
end

--// Get Order with retry until HRP exists
local function GetOrder()
    local timer = 0
    local order
    repeat
        order = Workspace:FindFirstChild("Enemies") and Workspace.Enemies:FindFirstChild("Order")
        if order and order:FindFirstChild("HumanoidRootPart") and order:FindFirstChild("Humanoid") then
            return order
        end
        task.wait(0.1)
        timer = timer + 0.1
    until timer >= 5
    return nil
end

--// FastAttack
if _G.FastAttack then
    local Net = SafeWaitForChild(ReplicatedStorage.Modules, "Net")
    local RegisterAttack = SafeWaitForChild(Net, "RE/RegisterAttack")
    local RegisterHit = SafeWaitForChild(Net, "RE/RegisterHit")

    local function AttackEnemies()
        local char = player.Character
        if not char then return end
        EquipWeapon(getgenv().SelectWeapon)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local OthersEnemies = {}

        for _, folder in ipairs({Workspace.Enemies, Workspace.Characters}) do
            for _, enemy in ipairs(folder:GetChildren()) do
                local head = enemy:FindFirstChild("Head")
                local hum = enemy:FindFirstChild("Humanoid")
                local root = enemy:FindFirstChild("HumanoidRootPart")
                if head and hum and hum.Health > 0 and root and enemy ~= char and (hrp.Position - root.Position).Magnitude <= 50 then
                    table.insert(OthersEnemies, {enemy, head})
                end
            end
        end

        if #OthersEnemies > 0 then
            for _, data in ipairs(OthersEnemies) do
                pcall(function()
                    RegisterAttack:FireServer(0)
                    RegisterHit:FireServer(data[2], OthersEnemies)
                end)
            end
        end
    end

    task.spawn(function()
        while task.wait(0.05) do
            if getgenv().AutoCyborg then AttackEnemies() end
        end
    end)
end

--// Main Loop v4
task.spawn(function()
    while task.wait(0.2) do
        if not getgenv().AutoCyborg then continue end
        local char = player.Character
        if not char then continue end
        local backpack = player:WaitForChild("Backpack")

        EquipWeapon(getgenv().SelectWeapon)
        AutoHaki()

        -- Check chip mới nhất
        local chip = backpack:FindFirstChild("Microchip") or char:FindFirstChild("Microchip")
        local hasChip = chip ~= nil

        -- Check order mới nhất
        local order = GetOrder()
        local orderExists = order ~= nil

        -- 1️⃣ Attack Order nếu tồn tại
        if orderExists then
            repeat
                task.wait(0.15)
                AutoHaki()
                EquipWeapon(getgenv().SelectWeapon)
                order = GetOrder()
                if order and order:FindFirstChild("HumanoidRootPart") then
                    SmoothStayAbove(order.HumanoidRootPart)
                    order.HumanoidRootPart.CanCollide = false
                    order.HumanoidRootPart.Size = Vector3.new(120,120,120)
                end
            until not OrderExists() or not getgenv().AutoCyborg
            continue
        end

        -- 2️⃣ Summon nếu có chip nhưng không có Order
        if hasChip and not OrderExists() then
            local ok, btn = pcall(function()
                return Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector
            end)
            if ok and btn then
                fireclickdetector(btn)
            end

            -- Chờ Order spawn + HRP
            local order = GetOrder()
            if order then
                repeat
                    task.wait(0.15)
                    AutoHaki()
                    EquipWeapon(getgenv().SelectWeapon)
                    if order and order:FindFirstChild("HumanoidRootPart") then
                        SmoothStayAbove(order.HumanoidRootPart)
                        order.HumanoidRootPart.CanCollide = false
                        order.HumanoidRootPart.Size = Vector3.new(120,120,120)
                    end
                    order = GetOrder()
                until not OrderExists() or not getgenv().AutoCyborg
            end
            continue
        end

        -- 3️⃣ Mua chip nếu không có Order và không có chip
        if not hasChip and not OrderExists() then
            pcall(function()
                CommF:InvokeServer("BlackbeardReward", "Microchip", "1")
                task.wait(0.3)
                CommF:InvokeServer("BlackbeardReward", "Microchip", "2")
            end)
            task.wait(0.5)
        end
    end
end)
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
