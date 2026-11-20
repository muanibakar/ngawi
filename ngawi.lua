local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- KONFIGURASI

local CONFIG = {
    REMOTE_FOLDER = "RemoteEvents",
    EGG_EVENT = "EggEvent",
    STEAL_EVENT = "StealEvent",
    BANK_EVENT = "BankEvent",
    SELL_EVENT = "SellEvent",
    BUY_EVENT = "BuyEvent",
    CLAIM_EVENT = "ClaimEvent",
    HATCH_EVENT = "HatchEvent",
    MERGE_EVENT = "MergeEvent",
    LOOP_INTERVAL = 0.35,
    ESP_INTERVAL = 0.5,
    SPEED = 60,
    JUMP = 50,
}

local State = {
    AutoSteal = false,
    AutoBreak = false,
    AutoBank = false,
    HopSteal = false,
    AutoPlace = false,
    InstantSteal = false,
    RareOnly = true,
    AvoidGuard = true,
    AutoSell = false,
    ProtectBest = true,
    AutoBuy = false,
    AutoClaim = false,
    AutoHatch = false,
    AutoMerge = false,
    EggESP = false,
    AnimalESP = false,
    SpeedOn = false,
    JumpOn = false,
    FlyOn = false,
    NoclipOn = false,
    AntiAFK = false,
    Panic = false,
}

local Connections = {}
local ESPObjects = {}
local ActiveTasks = {}

-- HELPER

local function waitChild(parent, name, t)
    if not parent then return nil end
    local ok, c = pcall(function() return parent:WaitForChild(name, t or 5) end)
    return ok and c or nil
end

local RemoteFolder = waitChild(ReplicatedStorage, CONFIG.REMOTE_FOLDER, 10)

local function fire(name, ...)
    if not RemoteFolder then return false end
    local r = RemoteFolder:FindFirstChild(name)
    if not r then return false end
    local a = table.pack(...)
    local ok = pcall(function()
        if r:IsA("RemoteEvent") then
            r:FireServer(table.unpack(a, 1, a.n))
        elseif r:IsA("RemoteFunction") then
            r:InvokeServer(table.unpack(a, 1, a.n))
        end
    end)
    return ok
end

local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function teleport(pos)
    local root = getRoot()
    if root and pos then
        pcall(function() root.CFrame = CFrame.new(pos) end)
    end
end

local function dist(a, b)
    if not a or not b then return math.huge end
    local ok, d = pcall(function() return (a.Position - b.Position).Magnitude end)
    return ok and d or math.huge
end

local function trackTask(name, fn)
    if ActiveTasks[name] then return end
    ActiveTasks[name] = task.spawn(function()
        local ok, err = pcall(fn)
        ActiveTasks[name] = nil
        if not ok then warn("[BSAE] " .. tostring(err)) end
    end)
end

-- AUTO FARM

local function findBestEgg()
    local root = getRoot()
    if not root then return nil end
    local best, bestScore = nil, -math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and obj.Name:lower():find("egg") then
            local pos = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position
                or (obj:IsA("BasePart") and obj.Position) or nil
            if pos then
                local d = dist(root, { Position = pos })
                local score = 1 / math.max(d, 1)
                if score > bestScore then
                    bestScore = score
                    best = obj
                end
            end
        end
    end
    return best
end

local function autoBreakLoop()
    while State.AutoBreak and not State.Panic do
        pcall(function()
            local egg = findBestEgg()
            if egg then
                local pos = egg:IsA("Model") and egg.PrimaryPart and egg.PrimaryPart.Position
                    or (egg:IsA("BasePart") and egg.Position) or nil
                if pos then
                    teleport(pos + Vector3.new(0, 3, 0))
                    task.wait(0.15)
                    fire(CONFIG.EGG_EVENT, egg)
                end
            end
        end)
        task.wait(CONFIG.LOOP_INTERVAL)
    end
    ActiveTasks.AutoBreak = nil
end

local function autoStealLoop()
    while State.AutoSteal and not State.Panic do
        pcall(function()
            fire(CONFIG.STEAL_EVENT, State.InstantSteal and "Instant" or nil)
        end)
        task.wait(State.InstantSteal and 0.1 or CONFIG.LOOP_INTERVAL)
    end
    ActiveTasks.AutoSteal = nil
end

local function autoBankLoop()
    while State.AutoBank and not State.Panic do
        pcall(function() fire(CONFIG.BANK_EVENT) end)
        task.wait(1.5)
    end
    ActiveTasks.AutoBank = nil
end

local function hopStealLoop()
    while State.HopSteal and not State.Panic do
        pcall(function()
            fire(CONFIG.STEAL_EVENT, "Drop")
            task.wait(0.2)
            fire(CONFIG.STEAL_EVENT, "Pickup")
        end)
        task.wait(1)
    end
    ActiveTasks.HopSteal = nil
end

-- EKONOMI

local function autoSellLoop()
    while State.AutoSell and not State.Panic do
        pcall(function()
            fire(CONFIG.SELL_EVENT, State.ProtectBest and "ProtectBest" or nil)
        end)
        task.wait(2)
    end
    ActiveTasks.AutoSell = nil
end

local function autoBuyLoop()
    while State.AutoBuy and not State.Panic do
        pcall(function()
            for _, item in ipairs({ "Pickaxe", "Trail", "PlotUpgrade", "Treadmill", "Satchel" }) do
                fire(CONFIG.BUY_EVENT, item)
            end
        end)
        task.wait(3)
    end
    ActiveTasks.AutoBuy = nil
end

local function autoClaimLoop()
    while State.AutoClaim and not State.Panic do
        pcall(function()
            for _, c in ipairs({ "Reward", "OfflineCash", "GroupReward", "Index" }) do
                fire(CONFIG.CLAIM_EVENT, c)
            end
        end)
        task.wait(5)
    end
    ActiveTasks.AutoClaim = nil
end

local function autoHatchMergeLoop()
    while (State.AutoHatch or State.AutoMerge) and not State.Panic do
        if State.AutoHatch then pcall(function() fire(CONFIG.HATCH_EVENT) end) end
        if State.AutoMerge then pcall(function() fire(CONFIG.MERGE_EVENT) end) end
        task.wait(2)
    end
    ActiveTasks.AutoHatch = nil
end

-- ESP

local function clearESP()
    for _, o in ipairs(ESPObjects) do
        pcall(function() o:Destroy() end)
    end
    ESPObjects = {}
end

local function makeESP(model, text, color)
    if not model or not model:IsA("Model") or not model.PrimaryPart then return end
    local bg = Instance.new("BillboardGui")
    bg.Name = "BSAE_ESP"
    bg.Size = UDim2.new(0, 120, 0, 40)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.Adornee = model.PrimaryPart
    bg.Parent = model.PrimaryPart
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.new(1, 1, 1)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSansBold
    lbl.Parent = bg
    table.insert(ESPObjects, bg)
end

local function refreshESP()
    clearESP()
    local root = getRoot()
    if not root then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if State.EggESP and name:find("egg") then
            local pos = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position
                or (obj:IsA("BasePart") and obj.Position) or nil
            if pos then
                local d = dist(root, { Position = pos })
                makeESP(obj, string.format("EGG %d", math.floor(d)), Color3.fromRGB(255, 215, 0))
            end
        end
        if State.AnimalESP and name:find("animal") then
            makeESP(obj, "ANIMAL", Color3.fromRGB(0, 255, 127))
        end
    end
end

local function espLoop()
    while (State.EggESP or State.AnimalESP) and not State.Panic do
        pcall(refreshESP)
        task.wait(CONFIG.ESP_INTERVAL)
    end
    clearESP()
    ActiveTasks.ESP = nil
end

-- MOVEMENT

local function applySpeed()
    local h = getHumanoid()
    if h then
        pcall(function() h.WalkSpeed = State.SpeedOn and CONFIG.SPEED or 16 end)
    end
end

local function applyJump()
    local h = getHumanoid()
    if h then
        pcall(function() h.JumpPower = State.JumpOn and CONFIG.JUMP or 50 end)
    end
end

local flyConn
local function setFly(on)
    local root = getRoot()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if not on or not root then return end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    flyConn = RunService.Heartbeat:Connect(function()
        local cam = workspace.CurrentCamera
        if cam and bv then bv.Velocity = cam.CFrame.LookVector * 50 end
    end)
    table.insert(Connections, flyConn)
end

local noclipConn
local function setNoclip(on)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if not on then return end
    noclipConn = RunService.Stepped:Connect(function()
        local c = LocalPlayer.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
    end)
    table.insert(Connections, noclipConn)
end

local afkConn
local function setAntiAFK(on)
    if afkConn then afkConn:Disconnect(); afkConn = nil end
    if not on then return end
    afkConn = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    table.insert(Connections, afkConn)
end

-- UTILITY

local function serverHop()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(game.HttpGet(url))
        if data and data.data and #data.data > 0 then
            local s = data.data[math.random(1, #data.data)]
            if s and s.id then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            end
        end
    end)
end

local function rejoin()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end

local function panic()
    State.Panic = true
    for k in pairs(State) do
        if type(State[k]) == "boolean" and k ~= "Panic" then State[k] = false end
    end
    clearESP()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    Connections = {}
    for _, t in pairs(ActiveTasks) do
        pcall(function() task.cancel(t) end)
    end
    ActiveTasks = {}
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if afkConn then afkConn:Disconnect(); afkConn = nil end
    applySpeed()
    applyJump()
end

-- GUI

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "BSAE Hub",
    LoadingTitle = "Break and Steal an Egg",
    LoadingSubtitle = "Mobile",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local FarmTab = Window:CreateTab("Auto Farm", nil)

FarmTab:CreateToggle({ Name = "Auto Steal", CurrentValue = false, Flag = "AS", Callback = function(v)
    State.AutoSteal = v
    if v then trackTask("AutoSteal", autoStealLoop) end
end })

FarmTab:CreateToggle({ Name = "Instant Steal", CurrentValue = false, Flag = "IS", Callback = function(v)
    State.InstantSteal = v
end })

FarmTab:CreateToggle({ Name = "Rare Only", CurrentValue = true, Flag = "RO", Callback = function(v)
    State.RareOnly = v
end })

FarmTab:CreateToggle({ Name = "Avoid Guard", CurrentValue = true, Flag = "AG", Callback = function(v)
    State.AvoidGuard = v
end })

FarmTab:CreateToggle({ Name = "Auto Break", CurrentValue = false, Flag = "AB", Callback = function(v)
    State.AutoBreak = v
    if v then trackTask("AutoBreak", autoBreakLoop) end
end })

FarmTab:CreateToggle({ Name = "Auto Bank", CurrentValue = false, Flag = "ABk", Callback = function(v)
    State.AutoBank = v
    if v then trackTask("AutoBank", autoBankLoop) end
end })

FarmTab:CreateToggle({ Name = "Hop Steal", CurrentValue = false, Flag = "HS", Callback = function(v)
    State.HopSteal = v
    if v then trackTask("HopSteal", hopStealLoop) end
end })

FarmTab:CreateToggle({ Name = "Auto Place", CurrentValue = false, Flag = "AP", Callback = function(v)
    State.AutoPlace = v
end })

local EcoTab = Window:CreateTab("Economy", nil)

EcoTab:CreateToggle({ Name = "Auto Sell", CurrentValue = false, Flag = "ASe", Callback = function(v)
    State.AutoSell = v
    if v then trackTask("AutoSell", autoSellLoop) end
end })

EcoTab:CreateToggle({ Name = "Protect Best", CurrentValue = true, Flag = "PB", Callback = function(v)
    State.ProtectBest = v
end })

EcoTab:CreateToggle({ Name = "Auto Buy", CurrentValue = false, Flag = "ABu", Callback = function(v)
    State.AutoBuy = v
    if v then trackTask("AutoBuy", autoBuyLoop) end
end })

EcoTab:CreateToggle({ Name = "Auto Claim", CurrentValue = false, Flag = "AC", Callback = function(v)
    State.AutoClaim = v
    if v then trackTask("AutoClaim", autoClaimLoop) end
end })

EcoTab:CreateToggle({ Name = "Auto Hatch", CurrentValue = false, Flag = "AH", Callback = function(v)
    State.AutoHatch = v
    if v then trackTask("AutoHatch", autoHatchMergeLoop) end
end })

EcoTab:CreateToggle({ Name = "Auto Merge", CurrentValue = false, Flag = "AM", Callback = function(v)
    State.AutoMerge = v
    if v then trackTask("AutoMerge", autoHatchMergeLoop) end
end })

local VisTab = Window:CreateTab("Visual & Move", nil)

VisTab:CreateToggle({ Name = "Egg ESP", CurrentValue = false, Flag = "EE", Callback = function(v)
    State.EggESP = v
    if v then trackTask("ESP", espLoop) end
end })

VisTab:CreateToggle({ Name = "Animal ESP", CurrentValue = false, Flag = "AE", Callback = function(v)
    State.AnimalESP = v
    if v then trackTask("ESP", espLoop) end
end })

VisTab:CreateSlider({ Name = "Walk Speed", Range = { 16, 200 }, Increment = 1, CurrentValue = CONFIG.SPEED, Flag = "Spd", Callback = function(v)
    CONFIG.SPEED = v
    if State.SpeedOn then applySpeed() end
end })

VisTab:CreateToggle({ Name = "Enable Speed", CurrentValue = false, Flag = "SpdOn", Callback = function(v)
    State.SpeedOn = v
    applySpeed()
end })

VisTab:CreateSlider({ Name = "Jump Power", Range = { 50, 200 }, Increment = 1, CurrentValue = CONFIG.JUMP, Flag = "Jmp", Callback = function(v)
    CONFIG.JUMP = v
    if State.JumpOn then applyJump() end
end })

VisTab:CreateToggle({ Name = "Enable Jump", CurrentValue = false, Flag = "JmpOn", Callback = function(v)
    State.JumpOn = v
    applyJump()
end })

VisTab:CreateToggle({ Name = "Fly", CurrentValue = false, Flag = "Fly", Callback = function(v)
    State.FlyOn = v
    setFly(v)
end })

VisTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Flag = "NC", Callback = function(v)
    State.NoclipOn = v
    setNoclip(v)
end })

VisTab:CreateToggle({ Name = "Anti-AFK", CurrentValue = false, Flag = "AFK", Callback = function(v)
    State.AntiAFK = v
    setAntiAFK(v)
end })

local MiscTab = Window:CreateTab("Lainnya", nil)

MiscTab:CreateButton({ Name = "Server Hop", Callback = function() serverHop() end })
MiscTab:CreateButton({ Name = "Rejoin", Callback = function() rejoin() end })
MiscTab:CreateButton({ Name = "PANIC - Stop All", Callback = function()
    panic()
    Rayfield:Notify({ Title = "PANIC", Content = "Semua fitur dimatikan.", Duration = 5 })
end })
