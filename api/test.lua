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

local function SendWebhook(url, title, desc, color)
    if not url or url == "" then return end
    local data = {
        embeds = {{
            title = title,
            description = desc,
            color = color,
            fields = {
                {
                    name = "🧑‍💻 Players",
                    value = string.format("`%d/%d`", #Players:GetPlayers(), Players.MaxPlayers),
                    inline = true
                },
                {
                    name = "🕒 Time",
                    value = "`" .. Lighting.TimeOfDay .. "`",
                    inline = true
                }
            },
            footer = { text = "🌙 Saki Hub" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    request({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(data)
    })
end

local function GetJoinScript(jobId)
    return ("**JobId:** `%s`\n> game:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \"%s\")")
        :format(tostring(jobId), tostring(jobId))
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

local function Exists(name)
    return Workspace.Enemies:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
end

local function CheckMystic()
    return Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("MysticIsland")
end

local World1, World2, World3 = false, false, false
if placeId == 2753915549 then
    World1 = true
elseif placeId == 4442272183 then
    World2 = true
elseif placeId == 7449423635 then
    World3 = true
end

local State = {
    FullMoon = false,
    NearMoon = false,
    Mystic = false,
    Indra = false,
    Dough = false,
    Darkbeard = false,
    Captain = false
}

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            local jobid = game.JobId
            if World1 then return end

            if World3 then
                local moon = GetMoonPhase()
                local mystic = CheckMystic()
                local hasFull = (moon == "Full")
                local hasNear = (moon == "Near")

                if hasFull and not State.FullMoon then
                    State.FullMoon = true
                    SendWebhook(Webhooks.FullMoon, "🌕 FULL MOON", "**A Full Moon has appeared!**\n" .. GetJoinScript(jobid), 65280)
                elseif not hasFull then
                    State.FullMoon = false
                end

                if hasNear and not State.NearMoon then
                    State.NearMoon = true
                    SendWebhook(Webhooks.NearFullMoon, "🌖 4/5 MOON", "**The moon is nearly full!**\n" .. GetJoinScript(jobid), 16761035)
                elseif not hasNear then
                    State.NearMoon = false
                end

                if mystic and not State.Mystic then
                    State.Mystic = true
                    SendWebhook(Webhooks.MysticIsland, "🌴 MYSTIC ISLAND FOUND", "**Mystic Island has spawned!**\n" .. GetJoinScript(jobid), 3447003)
                elseif not mystic then
                    State.Mystic = false
                end

                if Exists("rip_indra True Form") and not State.Indra then
                    State.Indra = true
                    SendWebhook(Webhooks.RipIndra, "😈 RIP INDRA TRUE FORM", "**rip_indra True Form has appeared!**\n" .. GetJoinScript(jobid), 16711680)
                elseif not Exists("rip_indra True Form") then
                    State.Indra = false
                end

                if Exists("Dough King") and not State.Dough then
                    State.Dough = true
                    SendWebhook(Webhooks.DoughKing, "🍩 DOUGH KING FOUND", "**Dough King has spawned!**\n" .. GetJoinScript(jobid), 16753920)
                elseif not Exists("Dough King") then
                    State.Dough = false
                end
            end

            if World2 then
                if Exists("Darkbeard") and not State.Darkbeard then
                    State.Darkbeard = true
                    SendWebhook(Webhooks.Darkbeard, "💀 DARKBEARD FOUND", "**Darkbeard has spawned!**\n" .. GetJoinScript(jobid), 11184810)
                elseif not Exists("Darkbeard") then
                    State.Darkbeard = false
                end

                if Exists("Cursed Captain") and not State.Captain then
                    State.Captain = true
                    SendWebhook(Webhooks.CursedCaptain, "⚓ CURSED CAPTAIN FOUND", "**Cursed Captain is here!**\n" .. GetJoinScript(jobid), 255)
                elseif not Exists("Cursed Captain") then
                    State.Captain = false
                end
            end
        end)
    end
end)
