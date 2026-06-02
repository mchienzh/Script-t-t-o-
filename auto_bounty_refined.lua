repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

-- ═════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local VIM               = game:GetService("VirtualInputManager")
local RunService        = game:GetService("RunService")
local TeleportService   = game:GetService("TeleportService")

local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Wrapper an toàn cho remote chính
local function CommF(...)
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if not remote then return end
    local ok, res = pcall(function(...) return remote:InvokeServer(...) end, ...)
    return ok and res or nil
end

-- ════════════════════════════════════════════════════
-- SETTINGS
-- ════════════════════════════════════════════════════
getgenv().Setting = getgenv().Setting or {
    ["Team"]              = "Pirate",
    ["FlySpeed"]          = 360,
    ["AttackDistance"]    = 32,
    ["DelaySwitchWeapon"] = 0.4,
    ["Auto Haki"]         = true,
    ["Auto Ken"]          = true,
    ["Auto PvP"]          = true,
    ["Active"]            = false,   -- [NEW] Toggle bật/tắt toàn bộ script

    ["Max Combat Time"]   = 110,     -- [NEW] Giới hạn thời gian đánh 1 người (giây)

    ["Race V3"] = {["Enable"] = true},
    ["Race V4"] = {["Enable"] = true},

    ["Hunt Method"] = {
        ["Use Move Predict"] = true,
        ["Aimbot"]           = true,
        ["ESP Player"]       = true,
        ["Orbit Radius"]     = 14,
        ["Orbit Speed"]      = 2,
        ["Orbit Height"]     = 6,
    },

    ["SafeZone"] = {
        ["Enable"]     = true,
        ["LowHealth"]  = 3500,
        ["MaxHealth"]  = 7000,
        ["Teleport Y"] = 7000,
    },

    ["Auto Server Hop"] = {
        ["Enable"]          = true,
        ["NoTargetTimeout"] = 5,
    },

    ["Aim Prediction"]     = 0.65,
    ["Ignore Devil Fruit"] = {"Human-Human", "Portal-Portal"},
    ["Spam Dash"]          = false,

    ["Weapons"] = {
        ["Melee"] = {
            ["Enable"] = true,
            ["Skills"] = {
                ["Z"] = {["Enable"] = true, ["HoldTime"] = 0.3},
                ["X"] = {["Enable"] = true, ["HoldTime"] = 0.3},
                ["C"] = {["Enable"] = true, ["HoldTime"] = 0.3},
            }
        },
        ["Blox Fruit"] = {
            ["Enable"] = true,
            ["Skills"] = {
                ["Z"] = {["Enable"] = true,  ["HoldTime"] = 0.3},
                ["X"] = {["Enable"] = true,  ["HoldTime"] = 0.3},
                ["C"] = {["Enable"] = true,  ["HoldTime"] = 0.3},
                ["V"] = {["Enable"] = false, ["HoldTime"] = 0.1},
                ["F"] = {["Enable"] = true,  ["HoldTime"] = 0.3},
            }
        },
        ["Sword"] = {
            ["Enable"] = true,
            ["Skills"] = {
                ["Z"] = {["Enable"] = true, ["HoldTime"] = 1.5},
                ["X"] = {["Enable"] = true, ["HoldTime"] = 1},
            }
        },
        ["Gun"] = {
            ["Enable"] = true,
            ["Skills"] = {
                ["Z"] = {["Enable"] = true, ["HoldTime"] = 0.3},
                ["X"] = {["Enable"] = true, ["HoldTime"] = 0.3},
            }
        },
    }
}

local cfg = getgenv().Setting

-- ════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════
local TargetPlayer      = nil
local IsInSafeZone      = false
local NoTargetTimer     = 0
local IsHopping         = false
local orbitClock        = 0

local IgnoredPlayers    = {}   -- [name] = expireTime
local LastTarget        = nil
local TargetHpTracker   = 0
local DamageTimer       = 0
local CombatTimeTracker = 0    -- [NEW] Tổng thời gian đánh 1 người
local MaxNoDamageTime   = 5

-- ════════════════════════════════════════════════════
-- GUI
-- ════════════════════════════════════════════════════
if CoreGui:FindFirstChild("AutoBounty") then
    CoreGui["AutoBounty"]:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoBounty"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn   = false
ScreenGui.Parent         = CoreGui

local C = {
    accent = Color3.fromRGB(255, 165, 0),
    bg     = Color3.fromRGB(15, 15, 25),
    bg2    = Color3.fromRGB(22, 22, 36),
    white  = Color3.fromRGB(240, 240, 240),
    green  = Color3.fromRGB(80, 220, 120),
    red    = Color3.fromRGB(255, 80, 80),
    yellow = Color3.fromRGB(255, 220, 80),
    blue   = Color3.fromRGB(100, 160, 255),
    gray   = Color3.fromRGB(130, 130, 140),
}

-- FIX: Khai báo tường minh từng biến để tránh nhầm lẫn nil/false
local function MakeDraggable(frame)
    local drag      = false
    local dragInput = nil
    local dragStart = nil
    local startPos  = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            drag      = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and drag then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- [NEW] Mở rộng 23px để chứa nút Toggle
local Main = Instance.new("Frame", ScreenGui)
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 230, 0, 178)
Main.Position         = UDim2.new(0.5, -115, 0.5, -89)
Main.BackgroundColor3 = C.bg
Main.Active           = true
MakeDraggable(Main)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local S = Instance.new("UIStroke", Main)
S.Thickness = 2.5
S.Color     = C.accent

local TBar = Instance.new("Frame", Main)
TBar.Size             = UDim2.new(1, 0, 0, 40)
TBar.BackgroundColor3 = C.bg2
TBar.BorderSizePixel  = 0
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 14)

local TTitle = Instance.new("TextLabel", TBar)
TTitle.Size                  = UDim2.new(1, 0, 1, 0)
TTitle.Text                  = "Auto Bounty"
TTitle.Font                  = Enum.Font.GothamBlack
TTitle.TextSize               = 12
TTitle.TextColor3             = C.accent
TTitle.BackgroundTransparency = 1

local function MkLabel(y, txt, col)
    local l = Instance.new("TextLabel", Main)
    l.Size                   = UDim2.new(0.94, 0, 0, 22)
    l.Position               = UDim2.new(0.03, 0, 0, y)
    l.BackgroundTransparency = 1
    l.Text                   = txt
    l.Font                   = Enum.Font.GothamSemibold
    l.TextSize               = 11
    l.TextColor3             = col or C.gray
    l.TextXAlignment         = Enum.TextXAlignment.Left
    return l
end

local LblTarget = MkLabel(46,  "🎯 Target : Searching...", C.gray)
local LblHP     = MkLabel(66,  "❤️ HP      : --",          C.green)
local LblDist   = MkLabel(86,  "📍 Dist    : --",          C.blue)
local LblHop    = MkLabel(106, "🌐 Hop     : --",          C.yellow)
local LblStatus = MkLabel(128, "📡 Status  : Idle",        C.yellow)

-- [NEW] Nút Toggle ON/OFF
local ToggleBtn = Instance.new("TextButton", Main)
ToggleBtn.Size               = UDim2.new(0.9, 0, 0, 22)
ToggleBtn.Position           = UDim2.new(0.05, 0, 0, 152)
ToggleBtn.BackgroundColor3   = C.green
ToggleBtn.Text               = "✅ ACTIVE"
ToggleBtn.Font               = Enum.Font.GothamBold
ToggleBtn.TextSize           = 11
ToggleBtn.TextColor3         = C.bg
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function()
    cfg["Active"] = not cfg["Active"]
    if cfg["Active"] then
        ToggleBtn.BackgroundColor3 = C.green
        ToggleBtn.Text             = "✅ ACTIVE"
    else
        ToggleBtn.BackgroundColor3 = C.red
        ToggleBtn.Text             = "❌ PAUSED"
        TargetPlayer               = nil
        LblTarget.Text             = "🎯 Target : Paused"
        LblStatus.Text             = "📡 Status  : Paused"
        LblStatus.TextColor3       = C.gray
    end
end)

-- ════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════════════════
local function IsAlive(p)
    return p and p.Character
        and p.Character:FindFirstChild("Humanoid")
        and p.Character.Humanoid.Health > 0
        and p.Character:FindFirstChild("HumanoidRootPart")
end

local function SendKey(key, hold)
    pcall(function()
        VIM:SendKeyEvent(true,  Enum.KeyCode[key], false, game)
        task.wait(hold or 0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode[key], false, game)
    end)
end

-- FIX: AssemblyLinearVelocity thay cho Velocity (deprecated)
local function GetPredicted(hrp)
    if cfg["Hunt Method"]["Use Move Predict"] then
        return hrp.Position + hrp.AssemblyLinearVelocity * cfg["Aim Prediction"]
    end
    return hrp.Position
end

-- [NEW] Dọn dẹp entry hết hạn trong IgnoredPlayers
local function CleanIgnored()
    local now = tick()
    for name, expiry in pairs(IgnoredPlayers) do
        if now >= expiry then
            IgnoredPlayers[name] = nil
        end
    end
end

local function GetTarget()
    CleanIgnored()  -- Dọn trước, không cần check tick() bên trong nữa
    local best, bestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer or not IsAlive(p) or not IsAlive(LocalPlayer) then continue end
        if IgnoredPlayers[p.Name] then continue end

        local ignored = false
        for _, name in pairs(cfg["Ignore Devil Fruit"]) do
            if p.Character:FindFirstChild(name) then
                ignored = true
                break
            end
        end

        if not ignored then
            local d = (p.Character.HumanoidRootPart.Position
                     - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best     = p
            end
        end
    end
    return best
end

local function EquipWeapon(wType)
    if not IsAlive(LocalPlayer) then return nil end
    local char, bp = LocalPlayer.Character, LocalPlayer.Backpack
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return nil end  -- FIX: nil-check trước khi dùng

    local function match(tool)
        return tool:IsA("Tool") and (
            tool.ToolTip == wType or
            (wType == "Blox Fruit" and tool.ToolTip == "Devil Fruit")
        )
    end

    for _, v in pairs(char:GetChildren()) do
        if match(v) then return v end
    end

    for _, v in pairs(bp:GetChildren()) do
        if match(v) then
            hum:UnequipTools()
            task.wait(0.08)
            hum:EquipTool(v)
            return v
        end
    end
    return nil
end

-- ════════════════════════════════════════════════════
-- LOGIC
-- ════════════════════════════════════════════════════

-- FIX: ServerHop – dừng ngay khi một lần teleport thành công
local function ServerHop()
    if IsHopping then return end
    IsHopping = true
    LblHop.Text       = "🌐 Hop : Searching..."
    LblHop.TextColor3 = C.yellow

    local placeId = game.PlaceId
    local success = false

    for attempt = 1, 8 do
        LblHop.Text = string.format("🌐 Hop : Attempt %d/8", attempt)
        -- Thử với LocalPlayer trước, nếu fail thì thử không có player
        local ok = pcall(TeleportService.Teleport, TeleportService, placeId, LocalPlayer)
        if not ok then
            ok = pcall(TeleportService.Teleport, TeleportService, placeId)
        end
        if ok then
            success = true
            break
        end
        task.wait(2.5)
    end

    LblHop.Text       = success and "🌐 Hop : Connecting..." or "🌐 Hop : Failed"
    LblHop.TextColor3 = success and C.green or C.red
    IsHopping         = false
end

-- FIX: Kiểm tra cả team sai, không chỉ nil
task.spawn(function()
    local targetTeamName = cfg["Team"] == "Pirate" and "Pirates" or "Marines"
    while task.wait(3) do
        if not cfg["Active"] then continue end
        local team = LocalPlayer.Team
        if team == nil or team.Name ~= targetTeamName then
            CommF("SetTeam", targetTeamName)
        end
    end
end)

-- FIX: CharacterAdded thay cho RunService.Stepped mỗi frame (tốn CPU)
local function ApplyNoCollide(char)
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    char.DescendantAdded:Connect(function(p)
        if p:IsA("BasePart") then p.CanCollide = false end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    ApplyNoCollide(char)
end)
if LocalPlayer.Character then
    task.spawn(function() ApplyNoCollide(LocalPlayer.Character) end)
end

-- Anti-AFK
task.spawn(function()
    while task.wait(55) do
        if cfg["Active"] and IsAlive(LocalPlayer) then
            SendKey("Space", 0.05)
        end
    end
end)

-- [NEW] PlayerRemoving – reset target & dọn IgnoredPlayers khi player rời
Players.PlayerRemoving:Connect(function(p)
    IgnoredPlayers[p.Name] = nil
    if p == TargetPlayer then
        TargetPlayer      = nil
        LastTarget        = nil
        DamageTimer       = 0
        CombatTimeTracker = 0
    end
end)

-- ESP
task.spawn(function()
    while task.wait(1.2) do
        if not cfg["Hunt Method"]["ESP Player"] then continue end
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer or not IsAlive(p) then continue end
            local char     = p.Character
            local isTarget = (p == TargetPlayer)
            local esp      = char:FindFirstChild("BountyESP_V9")
            if not esp then
                esp                  = Instance.new("Highlight")
                esp.Name             = "BountyESP_V9"
                esp.OutlineColor     = Color3.fromRGB(255, 255, 255)
                esp.FillTransparency = 0.5
                esp.Parent           = char
            end
            esp.FillColor = isTarget
                and Color3.fromRGB(255, 50, 50)
                or  Color3.fromRGB(50, 100, 255)
        end
    end
end)

-- Aimbot
RunService.RenderStepped:Connect(function()
    if not cfg["Hunt Method"]["Aimbot"] or not cfg["Active"] then return end
    if not (TargetPlayer and IsAlive(TargetPlayer) and IsAlive(LocalPlayer)) then return end
    local pred = GetPredicted(TargetPlayer.Character.HumanoidRootPart)
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, pred)
end)

-- Auto Haki / Ken
task.spawn(function()
    local kenCooldown = 0
    while task.wait(0.7) do
        if not cfg["Active"] or not IsAlive(LocalPlayer) then continue end
        local char = LocalPlayer.Character
        if cfg["Auto Haki"] then
            local hasBuso = char:FindFirstChild("HasBuso")
                or char:GetAttribute("HasBuso")
                or char:GetAttribute("Buso")
            if not hasBuso then CommF("Buso") end
        end
        if cfg["Auto Ken"] and TargetPlayer and IsAlive(TargetPlayer) then
            if tick() - kenCooldown > 0.5 then
                SendKey("E", 0.05)
                kenCooldown = tick()
            end
        end
    end
end)

-- Race V3 / V4
task.spawn(function()
    while task.wait(0.08) do
        if not cfg["Active"] or IsInSafeZone
        or not TargetPlayer or not IsAlive(TargetPlayer) or not IsAlive(LocalPlayer) then continue end
        local dist = (LocalPlayer.Character.HumanoidRootPart.Position
                    - TargetPlayer.Character.HumanoidRootPart.Position).Magnitude
        if dist <= cfg["Hunt Method"]["Orbit Radius"] + 20 then
            if cfg["Race V4"]["Enable"] then SendKey("Y", 0.05) end
            if cfg["Race V3"]["Enable"] then SendKey("T", 0.05) end
        end
    end
end)

-- Auto PvP
task.spawn(function()
    while task.wait(3) do
        if cfg["Auto PvP"] and cfg["Active"] and IsAlive(LocalPlayer) then
            pcall(function() CommF("EnablePvp") end)
        end
    end
end)

-- ════════════════════════════════════════════════════
-- COMBAT LOOP
-- ════════════════════════════════════════════════════
task.spawn(function()
    local comboOrder = {"Melee", "Blox Fruit", "Sword", "Gun"}
    local skillOrder = {"Z", "X", "C", "F"}

    while true do
        task.wait(0.05)

        if not cfg["Active"] or IsInSafeZone
        or not TargetPlayer or not IsAlive(TargetPlayer) or not IsAlive(LocalPlayer) then continue end

        local myHRP    = LocalPlayer.Character.HumanoidRootPart
        local enemyHRP = TargetPlayer.Character.HumanoidRootPart
        local dist     = (myHRP.Position - enemyHRP.Position).Magnitude
        local attackRange = cfg["Hunt Method"]["Orbit Radius"] + 18

        if dist > attackRange then continue end

        for _, wType in ipairs(comboOrder) do
            if not cfg["Active"] or IsInSafeZone
            or not IsAlive(TargetPlayer) or not IsAlive(LocalPlayer) then break end

            local wData = cfg["Weapons"][wType]
            if not (wData and wData["Enable"]) then continue end

            local tool = EquipWeapon(wType)
            if not tool then continue end

            task.wait(0.15)

            for _, skillKey in ipairs(skillOrder) do
                local sData = wData["Skills"][skillKey]
                if not (sData and sData["Enable"]) then continue end

                if not cfg["Active"] or IsInSafeZone
                or not IsAlive(TargetPlayer) or not IsAlive(LocalPlayer) then break end

                local curDist = (myHRP.Position - enemyHRP.Position).Magnitude
                if curDist > attackRange + 12 then break end

                SendKey(skillKey, sData["HoldTime"])
                task.wait(0.22)
            end

            task.wait(cfg["DelaySwitchWeapon"])
        end
    end
end)

-- ════════════════════════════════════════════════════
-- MAIN HUNT LOOP
-- ════════════════════════════════════════════════════
task.spawn(function()
    while true do
        local dt = task.wait()
        if not cfg["Active"] or not IsAlive(LocalPlayer) then continue end

        local myHum = LocalPlayer.Character.Humanoid
        local myHRP = LocalPlayer.Character.HumanoidRootPart

        -- SafeZone
        if cfg["SafeZone"]["Enable"] then
            if not IsInSafeZone and myHum.Health <= cfg["SafeZone"]["LowHealth"] then
                IsInSafeZone         = true
                TargetPlayer         = nil
                LblStatus.Text       = "📡 Status : ⚠️ SafeZone!"
                LblStatus.TextColor3 = C.red
                LblTarget.Text       = "🎯 Target : SafeZone (recovering)"
            elseif IsInSafeZone and myHum.Health >= cfg["SafeZone"]["MaxHealth"] then
                IsInSafeZone         = false
                LblStatus.Text       = "📡 Status : 🏹 Hunting"
                LblStatus.TextColor3 = C.green
            end
        end

        if IsInSafeZone then
            myHRP.AssemblyLinearVelocity = Vector3.zero  -- FIX: API mới
            myHRP.CFrame = CFrame.new(
                myHRP.Position.X,
                cfg["SafeZone"]["Teleport Y"],
                myHRP.Position.Z
            )
            continue
        end

        -- Tìm mục tiêu
        if not TargetPlayer or not IsAlive(TargetPlayer) then
            TargetPlayer      = GetTarget()
            NoTargetTimer     = NoTargetTimer + dt
            LastTarget        = nil
            DamageTimer       = 0
            CombatTimeTracker = 0
        else
            NoTargetTimer = 0
        end

        -- Auto server hop
        if cfg["Auto Server Hop"]["Enable"]
        and NoTargetTimer >= cfg["Auto Server Hop"]["NoTargetTimeout"]
        and not IsHopping then
            NoTargetTimer = 0
            task.spawn(ServerHop)
        end

        if TargetPlayer and IsAlive(TargetPlayer) then
            local enemyHRP   = TargetPlayer.Character.HumanoidRootPart
            local enemyHum   = TargetPlayer.Character.Humanoid
            local predictPos = GetPredicted(enemyHRP)
            local dist       = (myHRP.Position - enemyHRP.Position).Magnitude

            -- Reset khi mục tiêu thay đổi
            if TargetPlayer ~= LastTarget then
                LastTarget        = TargetPlayer
                TargetHpTracker   = enemyHum.Health
                DamageTimer       = 0
                CombatTimeTracker = 0
            end

            -- [NEW] Giới hạn thời gian đánh (chống kẹt mục tiêu)
            CombatTimeTracker = CombatTimeTracker + dt
            if CombatTimeTracker >= cfg["Max Combat Time"] then
                IgnoredPlayers[TargetPlayer.Name] = tick() + 300  -- cấm 5 phút
                LblStatus.Text = string.format(
                    "⚠️ Quá %ds! Chuyển mục tiêu...", cfg["Max Combat Time"]
                )
                LblStatus.TextColor3 = C.red
                TargetPlayer         = nil
                LastTarget           = nil
                DamageTimer          = 0
                CombatTimeTracker    = 0
                task.wait(1)
                continue
            end

            -- Kiểm tra no-damage / no-pvp
            if dist <= (cfg["Hunt Method"]["Orbit Radius"] + 18) then
                DamageTimer = DamageTimer + dt

                if enemyHum.Health < TargetHpTracker then
                    TargetHpTracker = enemyHum.Health
                    DamageTimer     = 0
                end

                if DamageTimer >= MaxNoDamageTime then
                    IgnoredPlayers[TargetPlayer.Name] = tick() + 60
                    LblStatus.Text       = "⚠️ No PvP/Damage! Skip..."
                    LblStatus.TextColor3 = C.red
                    TargetPlayer         = nil
                    LastTarget           = nil
                    DamageTimer          = 0
                    CombatTimeTracker    = 0
                    task.wait(0.5)
                    continue
                end
            else
                DamageTimer = math.max(0, DamageTimer - dt)
            end

            -- Cập nhật GUI
            LblTarget.Text = "🎯 Target : " .. TargetPlayer.Name
            LblHP.Text     = string.format("❤️ HP      : %.0f / %.0f",
                                            enemyHum.Health, enemyHum.MaxHealth)
            LblDist.Text   = string.format("📍 Dist    : %.1f studs", dist)

            if DamageTimer > 1 then
                LblStatus.Text       = string.format("📡 Check PvP: %.1fs",
                                                      MaxNoDamageTime - DamageTimer)
                LblStatus.TextColor3 = C.yellow
            else
                LblStatus.Text       = "📡 Status : 🏹 Hunting"
                LblStatus.TextColor3 = C.green
            end

            -- Di chuyển orbit
            orbitClock = orbitClock + dt * cfg["Hunt Method"]["Orbit Speed"]
            local radius = cfg["Hunt Method"]["Orbit Radius"]
            local height = cfg["Hunt Method"]["Orbit Height"]

            local orbitOffset = Vector3.new(
                math.cos(orbitClock) * radius,
                height,
                math.sin(orbitClock) * radius
            )
            local targetPos    = predictPos + orbitOffset
            local targetCFrame = CFrame.lookAt(targetPos, predictPos)

            myHRP.AssemblyLinearVelocity = Vector3.zero  -- FIX: API mới

            if dist > 45 then
                local dir   = (targetPos - myHRP.Position).Unit
                local speed = cfg["FlySpeed"]
                myHRP.CFrame = myHRP.CFrame + dir * (speed * dt)
            else
                local lerpT = math.clamp(8 * dt, 0, 1)
                LocalPlayer.Character:PivotTo(myHRP.CFrame:Lerp(targetCFrame, lerpT))
            end

            if cfg["Spam Dash"] then CommF("Dash") end
        else
            LblTarget.Text = "🎯 Target : Searching..."
            LblHP.Text     = "❤️ HP      : --"
            LblDist.Text   = "📍 Dist    : --"
            local remaining = math.max(0,
                cfg["Auto Server Hop"]["NoTargetTimeout"] - NoTargetTimer)
            LblStatus.Text       = string.format("📡 No target (hop in %.0fs)", remaining)
            LblStatus.TextColor3 = C.yellow
            task.wait(0.25)
        end
    end
end)
end)
