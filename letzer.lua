-- ExitDoor-Automation | Server-Hop + Auto-Restart via GitHub-Loader
-- =============================================================
local RAW_URL = "https://raw.githubusercontent.com/SFRDevelopment/asdasd/refs/heads/main/letzer.lua"
-- =============================================================

print("════════ ExitDoor v3.0 (GitHub-Loader) ════════")
print("Loader-URL: " .. RAW_URL)

local player = game.Players.LocalPlayer
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local placeId = game.PlaceId
local firePrompt = fireproximityprompt

local function resolveQueueTeleport()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if syn and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if fluxus and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    return nil
end

local function httpGet(url)
    if syn and syn.request then
        return syn.request({ Url = url, Method = "GET" }).Body
    elseif http_request then
        return http_request({ Url = url, Method = "GET" }).Body
    elseif request then
        return request({ Url = url, Method = "GET" }).Body
    else
        return httpService:GetAsync(url)
    end
end

local function getTargetPart()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local puzzle = map:FindFirstChild("Puzzle")
    if not puzzle then return nil end
    local children = puzzle:GetChildren()
    local doorGroup = nil
    if #children >= 18 then doorGroup = children[17] end
    if not doorGroup or doorGroup.Name ~= "Door3" then
        doorGroup = puzzle:FindFirstChild("Door3")
    end
    if not doorGroup then return nil end
    local door = doorGroup:FindFirstChild("Door")
    if not door then return nil end
    return door:FindFirstChild("Part")
end

local function triggerPrompt(part)
    if not part then return false end
    local prompt = nil
    for _, child in ipairs(part:GetDescendants()) do
        if child:IsA("ProximityPrompt") then prompt = child break end
    end
    if not prompt then warn("❌ Kein ProximityPrompt gefunden.") return false end
    prompt.Enabled = true

    if firePrompt then
        local ok = pcall(function() firePrompt(prompt) end)
        if ok then print("✅ Prompt ausgelöst mit fireproximityprompt") return true end
    end
    local ok = pcall(function() prompt:Prompt(player) end)
    if ok then print("✅ Prompt ausgelöst mit Prompt:Prompt()") return true end
    warn("❌ Prompt konnte nicht ausgelöst werden.")
    return false
end

local function hopToAnotherServer()
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, response = pcall(httpGet, url)
    if not success or not response then warn("❌ Server-Liste nicht ladbar.") return false end
    local ok, data = pcall(function() return httpService:JSONDecode(response) end)
    if not ok or not data or not data.data then return false end

    local available = {}
    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            table.insert(available, server.id)
        end
    end
    if #available == 0 then warn("❌ Kein freier Server.") return false end
    local target = available[math.random(1, #available)]

    -- Auto-Restart: GitHub-Loader einreihen (immer ein String!)
    local q = resolveQueueTeleport()
    if q then
        local ok2 = pcall(q, 'loadstring(game:HttpGet("' .. RAW_URL .. '"))()')
        if ok2 then print("✅ Auto-Restart registriert") else warn("⚠️ queueteleport fehlgeschlagen") end
    else
        warn("⚠️ queue_on_teleport nicht verfügbar – läuft nur einmal!")
    end

    teleportService:TeleportToPlaceInstance(placeId, target, player)
    return true
end

local function mainLoop()
    -- Erst warten bis der Server wirklich geladen ist (wichtig nach Teleport)
    if not game:IsLoaded() then game.Loaded:Wait() end
    print("🔄 Gestartet auf Server: " .. game.JobId)
    repeat wait(1) until player.Character and player.Character:FindFirstChild("HumanoidRootPart")

    local part = getTargetPart()
    if not part then
        warn("⏳ Zielpart nicht gefunden – warte 3 Sekunden...")
        wait(3)
        return mainLoop()
    end

    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = part.CFrame + Vector3.new(0, 0.5, 0)
        print("📍 Teleportiert zum Part")
    end

    print("⏳ Warte 2 Sekunden vor Prompt...")
    wait(2)
    triggerPrompt(part)

    print("⏳ Warte 1 Sekunde vor Serverwechsel...")
    wait(1)
    print("🔄 Wechsle Server...")
    hopToAnotherServer()
end

print("⏳ Warte 15 Sekunden vor dem ersten Durchlauf...")
wait(15)
mainLoop()
