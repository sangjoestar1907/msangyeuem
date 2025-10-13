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

local placeId = game.PlaceId
local jobId = game.JobId
_G.Keep_Job = _G.Keep_Job or {}

local function SendWebhook(url, title, desc, color)
    if not url or url == "" then return end
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = desc,
            ["color"] = color,
            ["fields"] = {
                {["name"] = "🧩 JobId", ["value"] = string.format("`%s`", jobId), ["inline"] = false},
                {["name"] = "📜 Join Script", ["value"] = string.format("```lua\ngame:GetService('ReplicatedStorage').__ServerBrowser:InvokeServer('teleport','%s')\n```", jobId), ["inline"] = false},
                {["name"] = "🧑‍💻 Players", ["value"] = string.format("`%d/%d`", #Players:GetPlayers(), Players.MaxPlayers), ["inline"] = true},
                {["name"] = "🕒 Time", ["value"] = "`" .. Lighting.TimeOfDay .. "`", ["inline"] = true}
            },
            ["footer"] = {["text"] = "🌙 Saki Hub Tracker"},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

local function GetMoonPhase()
    local sky = Lighting:FindFirstChild("Sky")
    if not sky then return "Other" end
    local id = tostring(sky.MoonTextureId)
    if id:find("9709149431") then
        return "Full"
    elseif id:find("9709149052") or id:find("9709150401") then
        return "Near"
    else
        return "Other"
    end
end

local function CheckMystic()
    local map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("MysticIsland") then
        return true
    end
    return false
end

local function Exists(name)
    return Workspace.Enemies:FindFirstChild(name)
        or ReplicatedStorage:FindFirstChild(name)
        or Workspace:FindFirstChild(name)
end

local World1, World2, World3 = false, false, false
if placeId == 2753915549 then
    World1 = true
elseif placeId == 4442272183 then
    World2 = true
elseif placeId == 7449423635 then
    World3 = true
end

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            if World1 then return end
            if World3 then
                local moon = GetMoonPhase()
                local mystic = CheckMystic()
                if moon == "Full" and not table.find(_G.Keep_Job, "Full_" .. jobId) then
                    table.insert(_G.Keep_Job, "Full_" .. jobId)
                    SendWebhook(Webhooks.FullMoon, "🌕 FULL MOON", "**A Full Moon has appeared!**", 65280)
                end
                if moon == "Near" and not table.find(_G.Keep_Job, "Near_" .. jobId) then
                    table.insert(_G.Keep_Job, "Near_" .. jobId)
                    SendWebhook(Webhooks.NearFullMoon, "🌖 4/5 MOON", "**The moon is nearly full!**", 16761035)
                end
                if mystic and not table.find(_G.Keep_Job, "Mystic_" .. jobId) then
                    table.insert(_G.Keep_Job, "Mystic_" .. jobId)
                    SendWebhook(Webhooks.MysticIsland, "🌴 MYSTIC ISLAND FOUND", "**Mystic Island has spawned!**", 3447003)
                end
                if Exists("rip_indra True Form") and not table.find(_G.Keep_Job, "Indra_" .. jobId) then
                    table.insert(_G.Keep_Job, "Indra_" .. jobId)
                    SendWebhook(Webhooks.RipIndra, "😈 RIP INDRA TRUE FORM", "**rip_indra True Form has appeared!**", 16711680)
                end
                if Exists("Dough King") and not table.find(_G.Keep_Job, "Dough_" .. jobId) then
                    table.insert(_G.Keep_Job, "Dough_" .. jobId)
                    SendWebhook(Webhooks.DoughKing, "🍩 DOUGH KING FOUND", "**Dough King has spawned!**", 16753920)
                end
            end
            if World2 then
                if Exists("Darkbeard") and not table.find(_G.Keep_Job, "Darkbeard_" .. jobId) then
                    table.insert(_G.Keep_Job, "Darkbeard_" .. jobId)
                    SendWebhook(Webhooks.Darkbeard, "💀 DARKBEARD FOUND", "**Darkbeard has spawned!**", 11184810)
                end
                if Exists("Cursed Captain") and not table.find(_G.Keep_Job, "Captain_" .. jobId) then
                    table.insert(_G.Keep_Job, "Captain_" .. jobId)
                    SendWebhook(Webhooks.CursedCaptain, "⚓ CURSED CAPTAIN FOUND", "**Cursed Captain is here!**", 255)
                end
            end
        end)
    end
end)
