-- Flesh Made Fear: first-person camera. Settings: ../settings.txt
-- The game uses fixed cameras (AFixed_Camera_BP triggers) and a pawn with no
-- camera component; ControlRotation is unused (always 0). We repurpose one level
-- CameraActor as a follow-cam at the pawn's head, aimed along the pawn's facing
-- (the direction the character's face points), and pre-hook the game's
-- SetViewTargetWithBlend/ClientSetViewTarget calls so they retarget to us.

local UEHelpers = require("UEHelpers")

local function LoadSettings()
    local cfg = { ToggleKey = "F", EyeHeight = 90, ForwardOffset = 45, FieldOfView = 95, StartFirstPerson = 1,
                  PitchUpKey = "PAGE_UP", PitchDownKey = "PAGE_DOWN" }
    local f
    for _, path in ipairs({ "Mods/FirstPerson/settings.txt", "Mods\\FirstPerson\\settings.txt" }) do
        f = io.open(path, "r")
        if f then break end
    end
    if not f then
        print("[FirstPerson] settings.txt not found, using defaults\n")
        return cfg
    end
    for line in f:lines() do
        local s = line:match("^%s*(.-)%s*$")
        if s ~= "" and not s:match("^[#;]") then
            local k, v = s:match("^([%w_]+)%s*=%s*(.+)$")
            if k and v then
                v = v:gsub("%s*[#;].*$", "")
                v = v:match("^%s*(.-)%s*$")
                local num = tonumber(v)
                cfg[k:lower()] = num ~= nil and num or v
            end
        end
    end
    f:close()
    return cfg
end

local Cfg = LoadSettings()

local EyeHeight = tonumber(Cfg.EyeHeight) or 90
local ForwardOffset = tonumber(Cfg.ForwardOffset) or 45
local FOV = tonumber(Cfg.FieldOfView) or 95
local bFirstPerson = tonumber(Cfg.StartFirstPerson) ~= 0
local ToggleKey = Key[string.upper(tostring(Cfg.ToggleKey or "F"))] or Key.F
local function ResolveKey(name, fallback)
    return Key[string.upper(tostring(name))] or fallback
end
local PitchUpKey = ResolveKey(Cfg.PitchUpKey, Key.PAGE_UP)
local PitchDownKey = ResolveKey(Cfg.PitchDownKey, Key.PAGE_DOWN)

local PC, Pawn, FollowCam, LastGameTarget
local bNoCamLogged = false
local LoggedErrs = {}

-- Vertical look state (see keybinds near the bottom).
local Pitch, PitchStep, PitchMax = 0.0, 10.0, 45.0

-- Logs each unique error once (keeps the log clean but never silent on failure).
local function LogErr(what, err)
    local key = tostring(what)
    if LoggedErrs[key] then return end
    LoggedErrs[key] = true
    print(string.format("[FirstPerson] %s failed: %s\n", key, tostring(err)))
end

local function GetFollowCam()
    if FollowCam and FollowCam:IsValid() then return FollowCam end
    local cams = FindAllOf("CameraActor")
    if not cams or #cams == 0 then return nil end
    FollowCam = cams[1]
    pcall(function() FollowCam.CameraComponent.FieldOfView = FOV end)
    return FollowCam
end

local function SameActor(A, B)
    if not (A and B) then return false end
    local Ok, Eq = pcall(function() return A:GetAddress() == B:GetAddress() end)
    return Ok and Eq
end

local function Tick()
    if not bFirstPerson then return false end

    if not (PC and PC:IsValid()) then PC = UEHelpers.GetPlayerController() end
    if not (PC and PC:IsValid()) then return false end
    if not (Pawn and Pawn:IsValid()) then Pawn = PC:K2_GetPawn() end
    if not (Pawn and Pawn:IsValid()) then return false end
    if not FollowCam or not FollowCam:IsValid() then
        if not GetFollowCam() then
            if not bNoCamLogged then
                bNoCamLogged = true
                print("[FirstPerson] no CameraActor found in world\n")
            end
            return false
        end
    end

    local Loc = Pawn:K2_GetActorLocation()
    local Rot = Pawn:K2_GetActorRotation()

    local okRot, errRot = pcall(function() FollowCam:K2_SetActorRotation({ Pitch = Pitch, Yaw = Rot.Yaw, Roll = 0.0 }, false) end)
    if not okRot then LogErr("SetActorRotation", errRot) end

    -- yaw-only forward, so looking up/down doesn't lift/sink the head position
    local RadYaw = math.rad(Rot.Yaw)
    local NewLoc = {
        X = Loc.X + math.cos(RadYaw) * ForwardOffset,
        Y = Loc.Y + math.sin(RadYaw) * ForwardOffset,
        Z = Loc.Z + EyeHeight,
    }
    local okLoc, errLoc = pcall(function() FollowCam:K2_SetActorLocation(NewLoc, false, {}, true) end)
    if not okLoc then LogErr("SetActorLocation", errLoc) end
    local okVT, errVT = pcall(function() PC:SetViewTargetWithBlend(FollowCam, 0.0, 0, 0, false) end)
    if not okVT then LogErr("SetViewTargetWithBlend", errVT) end
    return false
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    PC, Pawn, FollowCam = nil, nil, nil
    Pitch = 0.0
end)

-- The game re-asserts its fixed cameras constantly. Pre-hook: while in FP,
-- rewrite the requested target to our follow-cam, remembering the game's own
-- request so toggling back restores it.
RegisterHook("/Script/Engine.PlayerController:SetViewTargetWithBlend", function(Self, NewViewTarget)
    if not bFirstPerson or not (FollowCam and FollowCam:IsValid()) then return end
    local ok, err = pcall(function()
        local Wanted = NewViewTarget:get()
        if Wanted and Wanted:IsValid() and not SameActor(Wanted, FollowCam) then LastGameTarget = Wanted end
        NewViewTarget:set(FollowCam)
    end)
    if not ok then LogErr("SetViewTargetWithBlend hook", err) end
end)

RegisterHook("/Script/Engine.PlayerController:ClientSetViewTarget", function(Self, A)
    if not bFirstPerson or not (FollowCam and FollowCam:IsValid()) then return end
    local ok, err = pcall(function()
        local Wanted = A:get()
        if Wanted and Wanted:IsValid() and not SameActor(Wanted, FollowCam) then LastGameTarget = Wanted end
        A:set(FollowCam)
    end)
    if not ok then LogErr("ClientSetViewTarget hook", err) end
end)

RegisterKeyBind(ToggleKey, function()
    bFirstPerson = not bFirstPerson
    Pitch = 0.0
    if not bFirstPerson and LastGameTarget and LastGameTarget:IsValid() then
        pcall(function()
            UEHelpers.GetPlayerController():SetViewTargetWithBlend(LastGameTarget, 0.3, 0, 0, false)
        end)
    end
    print(string.format("[FirstPerson] %s\n", bFirstPerson and "first-person" or "third-person"))
end)

-- Vertical look: the game eats raw mouse input into native state that is invisible
-- from Lua (no UFunction hook fires, no Enhanced Input exists, pawn pitch stays 0),
-- so pitch gets its own keys (see PitchUpKey/PitchDownKey in settings.txt), tilting
-- the view 10 degrees per press, clamped to +/-45. (UE4SS keybinds are keydown-only
-- here: no hold/auto-repeat.)
RegisterKeyBind(PitchUpKey, function()
    Pitch = math.min(PitchMax, Pitch + PitchStep)
end)
RegisterKeyBind(PitchDownKey, function()
    Pitch = math.max(-PitchMax, Pitch - PitchStep)
end)

LoopInGameThreadWithDelay(0, Tick)

print(string.format("[FirstPerson] loaded. Toggle key=%s start=%s pitch=PageUp/PageDown\n",
    tostring(Cfg.ToggleKey), bFirstPerson and "FP" or "TP"))
