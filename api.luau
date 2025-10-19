local YourAPI = {
    BaseURL = "https://saki-hub.vercel.app",
    Endpoints = {
        FullMoon = "/api/fullmoon",
        NearFullMoon = "/api/nearfullmoon",
        MysticIsland = "/api/mysticisland", 
        RipIndra = "/api/ripindra",
        DoughKing = "/api/doughking",
        Darkbeard = "/api/darkbeard",
        CursedCaptain = "/api/cursedcaptain",
        ServerList = "/api/events"
    }
}

local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlaceId = game.PlaceId
local IsWorld1, IsWorld2, IsWorld3 = PlaceId == 2753915549, PlaceId == 4442272183, PlaceId == 7449423635

local EventState = {
    FullMoon = false,
    NearMoon = false,
    Mystic = false,
    Indra = false,
    Dough = false,
    Darkbeard = false,
    Captain = false
}

local MoonTextures = {
    Full = "9709149431",
    Near = "9709149052"
}

local function SendToBothAPIs(mainEndpoint, eventData)
    if not mainEndpoint or mainEndpoint == "" then return end
    
    local mainUrl = YourAPI.BaseURL .. mainEndpoint
    local serverListUrl = YourAPI.BaseURL .. YourAPI.Endpoints.ServerList
    
    local data = {
        event_type = eventData.event_type,
        boss_name = eventData.boss_name,
        color = eventData.color,
        time_remaining = eventData.time_remaining,
        is_boss = eventData.is_boss,
        time_of_day = Lighting.TimeOfDay,
        players = #Players:GetPlayers() .. "/" .. Players.MaxPlayers,
        job_id = game.JobId,
        server_script = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "' .. game.JobId .. '")',
        timestamp = os.date("%H:%M:%S"),
        place_id = PlaceId,
        world = IsWorld1 and "World1" or IsWorld2 and "World2" or IsWorld3 and "World3"
    }
    
    local req = http_request or request or syn and syn.request
    if req then
        local success1, response1 = pcall(function()
            return req({
                Url = mainUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        local success2, response2 = pcall(function()
            return req({
                Url = serverListUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if success1 then
            return true
        else
            return false
        end
    else
        return false
    end
end

local FullMoonStartTime = nil
local FullMoonDuration = 9 * 60

local function MarkFullMoonStart()
    FullMoonStartTime = os.clock()
end

local function CalculateFullMoonTimeRemaining()
    if not FullMoonStartTime then
        return "Không xác định"
    end
    local elapsed = os.clock() - FullMoonStartTime
    local remaining = math.max(0, FullMoonDuration - elapsed)
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    return string.format("%d phút %d giây", minutes, seconds)
end

local function EntityExists(name)
    return Workspace.Enemies:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
end

local function CheckMysticIsland()
    local map = Workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("MysticIsland")
end

local function GetMoonPhase()
    local sky = Lighting:FindFirstChild("Sky")
    if not sky then return "Other" end
    local texture = tostring(sky.MoonTextureId)
    local time = Lighting:GetMinutesAfterMidnight()
    if texture:find(MoonTextures.Full) then
        if (time >= 1080 and time <= 1440) or (time <= 180) then
            return "Full"
        else
            return "Near"
        end
    elseif texture:find(MoonTextures.Near) then
        return "Near"
    else
        return "Other"
    end
end

local function CheckWorld3Events()
    local moonPhase = GetMoonPhase()
    local hasMysticIsland = CheckMysticIsland()

    if moonPhase == "Full" and not EventState.FullMoon then
        EventState.FullMoon = true
        MarkFullMoonStart()
        task.wait(1)
        local timeRemaining = CalculateFullMoonTimeRemaining()
        local success = SendToBothAPIs(YourAPI.Endpoints.FullMoon, {
            event_type = "full_moon",
            boss_name = "Full Moon",
            color = 65280,
            time_remaining = timeRemaining,
            is_boss = false
        })
    elseif moonPhase ~= "Full" and EventState.FullMoon then
        EventState.FullMoon = false
        FullMoonStartTime = nil
    end

    if moonPhase == "Near" and not EventState.NearMoon then
        EventState.NearMoon = true
        local success = SendToBothAPIs(YourAPI.Endpoints.NearFullMoon, {
            event_type = "near_full_moon",
            boss_name = "Near Full Moon",
            color = 16761035,
            time_remaining = nil,
            is_boss = false
        })
    elseif moonPhase ~= "Near" and EventState.NearMoon then
        EventState.NearMoon = false
    end

    if hasMysticIsland and not EventState.Mystic then
        EventState.Mystic = true
        local success = SendToBothAPIs(YourAPI.Endpoints.MysticIsland, {
            event_type = "mystic_island",
            boss_name = "Mystic Island",
            color = 3447003,
            time_remaining = nil,
            is_boss = false
        })
    elseif not hasMysticIsland and EventState.Mystic then
        EventState.Mystic = false
    end

    if EntityExists("rip_indra True Form") and not EventState.Indra then
        EventState.Indra = true
        local success = SendToBothAPIs(YourAPI.Endpoints.RipIndra, {
            event_type = "rip_indra",
            boss_name = "Rip Indra True Form",
            color = 16711680,
            time_remaining = nil,
            is_boss = true
        })
    elseif not EntityExists("rip_indra True Form") and EventState.Indra then
        EventState.Indra = false
    end

    if EntityExists("Dough King") and not EventState.Dough then
        EventState.Dough = true
        local success = SendToBothAPIs(YourAPI.Endpoints.DoughKing, {
            event_type = "dough_king",
            boss_name = "Dough King",
            color = 16753920,
            time_remaining = nil,
            is_boss = true
        })
    elseif not EntityExists("Dough King") and EventState.Dough then
        EventState.Dough = false
    end
end

local function CheckWorld2Events()
    if EntityExists("Darkbeard") and not EventState.Darkbeard then
        EventState.Darkbeard = true
        local success = SendToBothAPIs(YourAPI.Endpoints.Darkbeard, {
            event_type = "darkbeard",
            boss_name = "Darkbeard",
            color = 11184810,
            time_remaining = nil,
            is_boss = true
        })
    elseif not EntityExists("Darkbeard") and EventState.Darkbeard then
        EventState.Darkbeard = false
    end

    if EntityExists("Cursed Captain") and not EventState.Captain then
        EventState.Captain = true
        local success = SendToBothAPIs(YourAPI.Endpoints.CursedCaptain, {
            event_type = "cursed_captain",
            boss_name = "Cursed Captain",
            color = 255,
            time_remaining = nil,
            is_boss = true
        })
    elseif not EntityExists("Cursed Captain") and EventState.Captain then
        EventState.Captain = false
    end
end

local function TriggerTestEvent(eventName)
    local endpoint = YourAPI.Endpoints.FullMoon
    
    if eventName == "near_full_moon" then
        endpoint = YourAPI.Endpoints.NearFullMoon
    elseif eventName == "mystic_island" then
        endpoint = YourAPI.Endpoints.MysticIsland
    elseif eventName == "rip_indra" then
        endpoint = YourAPI.Endpoints.RipIndra
    elseif eventName == "dough_king" then
        endpoint = YourAPI.Endpoints.DoughKing
    elseif eventName == "darkbeard" then
        endpoint = YourAPI.Endpoints.Darkbeard
    elseif eventName == "cursed_captain" then
        endpoint = YourAPI.Endpoints.CursedCaptain
    end
    
    local eventData = {
        event_type = eventName,
        boss_name = eventName,
        color = 16777215,
        time_remaining = "manual_trigger",
        is_boss = true,
        players = #Players:GetPlayers() .. "/" .. Players.MaxPlayers,
        job_id = game.JobId,
        world = IsWorld1 and "World1" or IsWorld2 and "World2" or IsWorld3 and "World3"
    }
    
    local success = SendToBothAPIs(endpoint, eventData)
end

if syn and syn.protect_gui then
    local ScreenGui = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")
    
    ScreenGui.Parent = game.CoreGui
    Frame.Parent = ScreenGui
    Frame.Size = UDim2.new(0, 220, 0, 250)
    Frame.Position = UDim2.new(0, 10, 0, 10)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BackgroundTransparency = 0.3
    
    UIListLayout.Parent = Frame
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    UIListLayout.Padding = UDim.new(0, 5)
    
    local function CreateButton(text, eventName)
        local Button = Instance.new("TextButton")
        Button.Parent = Frame
        Button.Size = UDim2.new(0.9, 0, 0, 30)
        Button.Text = text
        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.MouseButton1Click:Connect(function()
            TriggerTestEvent(eventName)
        end)
    end
    
    CreateButton("Full Moon", "full_moon")
    CreateButton("Near Moon", "near_full_moon")
    CreateButton("Mystic Island", "mystic_island")
    CreateButton("Rip Indra", "rip_indra")
    CreateButton("Dough King", "dough_king")
    CreateButton("Darkbeard", "darkbeard")
    CreateButton("Cursed Captain", "cursed_captain")
    
    syn.protect_gui(ScreenGui)
end

task.spawn(function()
    while task.wait(5) do
        if IsWorld1 then 
            continue 
        end
        
        if IsWorld3 then
            CheckWorld3Events()
        elseif IsWorld2 then
            CheckWorld2Events()
        end
    end
end)
