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
    Near = {"9709149052", "9709150401"}
}

local function SendWebhook(url, title, bossName, color)
    if not url or url == "" then return end
    
    local jobId = game.JobId
    local currentTime = os.date("%H:%M:%S")
    
    local embed = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = "**" .. bossName .. " đã xuất hiện!**",
            ["color"] = color,
            ["fields"] = {
                {
                    name = "Time Of Day :",
                    value = Lighting.TimeOfDay,
                    inline = false
                },
                {
                    name = "Players :",
                    value = #Players:GetPlayers() .. "/" .. Players.MaxPlayers,
                    inline = false
                },
                {
                    name = "Job-Id :",
                    value = jobId,
                    inline = false
                },
                {
                    name = "Script :",
                    value = 'game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", "'.. jobId ..'")',
                    inline = false
                },
                {
                    name = "Trạng thái :",
                    value = "🟢",
                    inline = false
                }
            },
            ["footer"] = {
                ["text"] = " Saki Hub | " .. os.date("%H:%M")
            }
        }}
    }
    
    local requestFunc = http_request or request or syn and syn.request
    if requestFunc then
        requestFunc({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(embed)
        })
    else
        warn("Không tìm thấy phương thức HTTP.")
    end
end

local function GetMoonPhase()
    local sky = Lighting:FindFirstChild("Sky")
    if not sky then return "Other" end
    
    local moonTextureId = tostring(sky.MoonTextureId)
    
    if moonTextureId:find(MoonTextures.Full) then
        return "Full"
    end
    
    for _, textureId in ipairs(MoonTextures.Near) do
        if moonTextureId:find(textureId) then
            return "Near"
        end
    end
    
    return "Other"
end

local function EntityExists(entityName)
    return Workspace.Enemies:FindFirstChild(entityName) ~= nil or 
           ReplicatedStorage:FindFirstChild(entityName) ~= nil
end

local function CheckMysticIsland()
    local map = Workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("MysticIsland") ~= nil
end

local function CheckWorld3Events()
    local moonPhase = GetMoonPhase()
    local hasMysticIsland = CheckMysticIsland()
    
    -- Moon Phase Checks
    if moonPhase == "Full" and not EventState.FullMoon then
        EventState.FullMoon = true
        SendWebhook(Webhooks.FullMoon, "🌕 FULL MOON", "Full Moon", 65280)
    elseif moonPhase ~= "Full" then
        EventState.FullMoon = false
    end
    
    if moonPhase == "Near" and not EventState.NearMoon then
        EventState.NearMoon = true
        SendWebhook(Webhooks.NearFullMoon, "🌖 4/5 MOON", "Near Full Moon", 16761035)
    elseif moonPhase ~= "Near" then
        EventState.NearMoon = false
    end
    
    -- Mystic Island Check
    if hasMysticIsland and not EventState.Mystic then
        EventState.Mystic = true
        SendWebhook(Webhooks.MysticIsland, "🌴 MYSTIC ISLAND", "Mystic Island", 3447003)
    elseif not hasMysticIsland then
        EventState.Mystic = false
    end
    
    -- Boss Checks
    if EntityExists("rip_indra True Form") and not EventState.Indra then
        EventState.Indra = true
        SendWebhook(Webhooks.RipIndra, "😈 RIP INDRA", "Rip Indra True Form", 16711680)
    elseif not EntityExists("rip_indra True Form") then
        EventState.Indra = false
    end
    
    if EntityExists("Dough King") and not EventState.Dough then
        EventState.Dough = true
        SendWebhook(Webhooks.DoughKing, "🍩 DOUGH KING", "Dough King", 16753920)
    elseif not EntityExists("Dough King") then
        EventState.Dough = false
    end
end

local function CheckWorld2Events()
    if EntityExists("Darkbeard") and not EventState.Darkbeard then
        EventState.Darkbeard = true
        SendWebhook(Webhooks.Darkbeard, "💀 DARKBEARD", "Darkbeard", 11184810)
    elseif not EntityExists("Darkbeard") then
        EventState.Darkbeard = false
    end
    
    if EntityExists("Cursed Captain") and not EventState.Captain then
        EventState.Captain = true
        SendWebhook(Webhooks.CursedCaptain, "⚓ CURSED CAPTAIN", "Cursed Captain", 255)
    elseif not EntityExists("Cursed Captain") then
        EventState.Captain = false
    end
end

-- Main monitoring loop
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
