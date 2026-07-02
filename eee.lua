-- ExitDoor‑Automation mit Server‑Hop und Auto‑Restart
-- (angepasst an IY‑queue_on_teleport‑Logik)

local player = game.Players.LocalPlayer
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local placeId = game.PlaceId

-- queue_on_teleport wie in IY definieren
local queueteleport = queue_on_teleport or
                     (syn and syn.queue_on_teleport) or
                     (fluxus and fluxus.queue_on_teleport)

local firePrompt = fireproximityprompt

-- Den gesamten Code als String speichern
local scriptCode = [=[
-- ====== INNERER CODE (wird auf jedem Server neu geladen) ======
local player = game.Players.LocalPlayer
local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local placeId = game.PlaceId
local firePrompt = fireproximityprompt

-- queue_on_teleport auch im inneren Code definieren (für weitere Hops)
local queueteleport = queue_on_teleport or
                     (syn and syn.queue_on_teleport) or
                     (fluxus and fluxus.queue_on_teleport)

local function httpGet(url)
    if syn and syn.request then
        local res = syn.request({ Url = url, Method = "GET" })
        return res.Body
    elseif http_request then
        local res = http_request({ Url = url, Method = "GET" })
        return res.Body
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
        if child:IsA("ProximityPrompt") then
            prompt = child
            break
        end
    end
    if not prompt then
        warn("❌ Kein ProximityPrompt gefunden.")
        return false
    end
    prompt.Enabled = true

    -- 1. Versuch: fireproximityprompt (Executor‑Funktion)
    if firePrompt then
        local success, err = pcall(function()
            firePrompt(prompt)
        end)
        if success then
            print("✅ Prompt ausgelöst mit fireproximityprompt: " .. prompt.Name)
            return true
        end
    end

    -- 2. Versuch: Prompt:Prompt(player)
    local success, err = pcall(function()
        prompt:Prompt(player)
    end)
    if success then
        print("✅ Prompt ausgelöst mit Prompt:Prompt(): " .. prompt.Name)
        return true
    else
        warn("❌ Prompt konnte nicht ausgelöst werden: " .. tostring(err))
        return false
    end
end

local function hopToAnotherServer()
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, response = pcall(httpGet, url)
    if not success or not response then
        warn("❌ Server‑Liste nicht ladbar.")
        return false
    end
    local data = httpService:JSONDecode(response)
    if not data or not data.data then return false end

    local available = {}
    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers then
            table.insert(available, server.id)
        end
    end
    if #available == 0 then
        warn("❌ Kein freier Server.")
        return false
    end

    local target = available[math.random(1, #available)]
    if target == game.JobId and #available > 1 then
        target = available[math.random(1, #available)]
    end

    -- 🔥 Auto‑Restart registrieren – wie in IY: String übergeben
    if queueteleport then
        local ok, err = pcall(function()
            -- Wir übergeben den gesamten Skript-Code als String
            queueteleport(scriptCode)
        end)
        if ok then
            print("✅ Auto‑Restart nach Server‑Hop registriert")
        else
            warn("⚠️ Fehler bei queueteleport: " .. tostring(err))
        end
    else
        warn("⚠️ queueteleport nicht verfügbar – Skript läuft nur einmal!")
    end

    teleportService:TeleportToPlaceInstance(placeId, target, player)
    return true
end

function mainLoop()
    print("🔄 Skript gestartet auf Server: " .. game.JobId)
    repeat wait(1) until player.Character and player.Character:FindFirstChild("HumanoidRootPart")

    local part = getTargetPart()
    if not part then
        warn("⏳ Zielpart nicht gefunden – warte 3 Sekunden...")
        wait(3)
        mainLoop()
        return
    end

    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = part.CFrame + Vector3.new(0, 0.5, 0)
            print("📍 Teleportiert")
        end
    end

    wait(0.5)
    local triggered = triggerPrompt(part)
    if triggered then
        print("✅ Aktion erfolgreich")
    else
        print("⚠️ Prompt nicht ausgelöst – trotzdem weiter...")
    end

    wait(1)
    print("🔄 Wechsle Server...")
    hopToAnotherServer()
end

-- Start
mainLoop()
]=]

-- Jetzt den Code ausführen
loadstring(scriptCode)()
