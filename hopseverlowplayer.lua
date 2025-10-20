local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId
local MaxPlayers = 2

local function HopServer()
    local Servers = {}
    local Cursor = ""
    local Success, Result

    repeat
        Success, Result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" ..
                (Cursor ~= "" and "&cursor=" .. Cursor or "")
            ))
        end)

        if Success and Result and Result.data then
            for _, Server in ipairs(Result.data) do
                if Server.playing < MaxPlayers and Server.id ~= JobId then
                    table.insert(Servers, Server)
                end
            end
            Cursor = Result.nextPageCursor or ""
        else
            task.wait(3)
        end
        task.wait(0.2)
    until Cursor == "" or #Servers >= 5

    if #Servers > 0 then
        local Chosen = Servers[math.random(1, #Servers)]
        TeleportService:TeleportToPlaceInstance(PlaceId, Chosen.id, LocalPlayer)
    else
        task.wait(5)
        HopServer()
    end
end

HopServer()
