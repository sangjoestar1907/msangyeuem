local Webhooks = {
    FullMoon = "https://discord.com/api/webhooks/1427165577062907905/rGwYS7OxDUNMrklxydhZYLxM0pxQ_Z97NzKdVYhjupcDsuOUtzFh4Kc3_D1CFbbV3aGw",
    NearFullMoon = "https://discord.com/api/webhooks/1427165628778938408/C_KNvE0DpZH8utzct_ruiNHl6GfjhN1H4uMdmYS45k8YPrsDLKbw4XQrKnXKG3Xwgd86",
    MysticIsland = "https://discord.com/api/webhooks/1427165824065474602/KAn5YWBRwLiKJ5VGQoYYO0bIDtl9Gt0eCZ9nNqNOwFV-W4bO3gzTyPD0E02CIOYSmHaT",
    RipIndra = "https://discord.com/api/webhooks/1427165761373474836/aPIIvfmecY9TmiAW6Rdln33rRuHqH1NCF5vu3vsdw8fk3OzKz3Eh5wIyJp_CZnyAjtwg",
    DoughKing = "https://discord.com/api/webhooks/1427165862653333526/ZC9Z8IFDcYw863YjWm_1oMD7bXgjCGonOrnLrTh7O2Qn5_3M3hD4nP8sNwHr-DwpY86g",
    Darkbeard = "https://discord.com/api/webhooks/1427165660332560469/djVVcyAulAHnWLWzxRA3R9CNn09LhoCbSRtdfys6ZZ9mR33kpGFpjptX1LJl5UedtfZC",
    CursedCaptain = "https://discord.com/api/webhooks/1427165699570274346/KiHWF0kUqUk1nK6zKOhFt9m9B34ZCBZnedReRXNr1Tezvd0slU3SQMqTuGxtFtJ6gWY2",
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

local function SendWebhook(url, title, bossName, color, timeRemaining, isBoss)
    if not url or url == "" then return end
    local jobId = game.JobId
    local fields = {
        { name = "Time Of Day :", value = Lighting.TimeOfDay, inline = false },
        { name = "Players :", value = #Players:GetPlayers() .. "/" .. Players.MaxPlayers, inline = false },
        { name = "Job-Id :", value = jobId, inline = false },
        { name = "Script :", value = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "' .. jobId .. '")', inline = false },
    }
    if isBoss then
        table.insert(fields, 1, { name = "Boss Name :", value = bossName, inline = false })
    end
    if timeRemaining then
        table.insert(fields, { name = "Full Moon Time Remaining :", value = timeRemaining, inline = false })
    end

    local embed = {
        ["embeds"] = {{
            ["title"] = title,
            ["color"] = color,
            ["fields"] = fields,
            ["footer"] = { ["text"] = "Saki Hub | " .. os.date("%H:%M:%S") }
        }}
    }

    local req = http_request or request or syn and syn.request
    if req then
        req({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(embed)
        })
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
        SendWebhook(Webhooks.FullMoon, "Saki", "Full Moon", 65280, timeRemaining, false)
    elseif moonPhase ~= "Full" and EventState.FullMoon then
        EventState.FullMoon = false
        FullMoonStartTime = nil
    end

    if moonPhase == "Near" and not EventState.NearMoon then
        EventState.NearMoon = true
        SendWebhook(Webhooks.NearFullMoon, "Saki", "Near Full Moon", 16761035, nil, false)
    elseif moonPhase ~= "Near" and EventState.NearMoon then
        EventState.NearMoon = false
    end

    if hasMysticIsland and not EventState.Mystic then
        EventState.Mystic = true
        SendWebhook(Webhooks.MysticIsland, "Saki", "Mystic Island", 3447003, nil, false)
    elseif not hasMysticIsland and EventState.Mystic then
        EventState.Mystic = false
    end

    if EntityExists("rip_indra True Form") and not EventState.Indra then
        EventState.Indra = true
        SendWebhook(Webhooks.RipIndra, "Saki", "Rip Indra True Form", 16711680, nil, true)
    elseif not EntityExists("rip_indra True Form") and EventState.Indra then
        EventState.Indra = false
    end

    if EntityExists("Dough King") and not EventState.Dough then
        EventState.Dough = true
        SendWebhook(Webhooks.DoughKing, "Saki", "Dough King", 16753920, nil, true)
    elseif not EntityExists("Dough King") and EventState.Dough then
        EventState.Dough = false
    end
end

local function CheckWorld2Events()
    if EntityExists("Darkbeard") and not EventState.Darkbeard then
        EventState.Darkbeard = true
        SendWebhook(Webhooks.Darkbeard, "Saki", "Darkbeard", 11184810, nil, true)
    elseif not EntityExists("Darkbeard") and EventState.Darkbeard then
        EventState.Darkbeard = false
    end

    if EntityExists("Cursed Captain") and not EventState.Captain then
        EventState.Captain = true
        SendWebhook(Webhooks.CursedCaptain, "Saki", "Cursed Captain", 255, nil, true)
    elseif not EntityExists("Cursed Captain") and EventState.Captain then
        EventState.Captain = false
    end
end

task.spawn(function()
    while task.wait(5) do
        if IsWorld1 then continue end
        if IsWorld3 then
            CheckWorld3Events()
        elseif IsWorld2 then
            CheckWorld2Events()
        end
    end
end)
