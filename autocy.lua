--// Config
getgenv().AutoCyborg = true
getgenv().SelectWeapon = "Melee"
local TweenSpeed = 350
local HeightAboveOrder = 25
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
