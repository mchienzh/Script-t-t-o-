-- [[ HỆ THỐNG CỐT LÕI ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- [[ BẢNG TRẠNG THÁI ]]
local Mod = {
    ESP = false,
    Assassinate = false,
    Kill = false,
    FastAttack = false,
    AntiReport = false,
    Range = 3000,
    HeightLimit = 10
}

-- [[ GIAO DIỆN RAINBOW GLOW ]]
if LocalPlayer.PlayerGui:FindFirstChild("MinhChien") then LocalPlayer.PlayerGui.MinhChien:Destroy() end
local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui); ScreenGui.Name = "MinhChien"; ScreenGui.ResetOnSpawn = false

local function Drag(gui)
    local drag, input, start, pos
    gui.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; start = i.Position; pos = gui.Position end end)
    gui.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then input = i end end)
    RunService.RenderStepped:Connect(function() if drag and input then local d = input.Position - start; gui.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y) end end)
end

local Icon = Instance.new("Frame", ScreenGui); Icon.Size = UDim2.new(0, 60, 0, 60); Icon.Position = UDim2.new(0, 15, 0.5, -30); Icon.BackgroundColor3 = Color3.new(0,0,0); Icon.Active = true; Drag(Icon)
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1, 0)
local IconStroke = Instance.new("UIStroke", Icon); IconStroke.Thickness = 3; task.spawn(function() while task.wait(0.01) do IconStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end end)
local Img = Instance.new("ImageLabel", Icon); Img.Size = UDim2.new(0.9, 0, 0.9, 0); Img.Position = UDim2.new(0.05, 0, 0.05, 0); Img.Image = "rbxassetid://77691578095582"; Img.BackgroundTransparency = 1; Instance.new("UICorner", Img).CornerRadius = UDim.new(1, 0)
local IconBtn = Instance.new("TextButton", Icon); IconBtn.Size = UDim2.new(1, 0, 1, 0); IconBtn.BackgroundTransparency = 1; IconBtn.Text = ""

local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 230, 0, 420); Main.Position = UDim2.new(0.5, -115, 0.2, 0); Main.BackgroundColor3 = Color3.fromRGB(5, 5, 10); Main.Visible = false; Main.Active = true; Drag(Main)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12); local MainStroke = Instance.new("UIStroke", Main); MainStroke.Thickness = 3; task.spawn(function() while task.wait(0.01) do MainStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end end)
local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 40); Title.Text = "MINHCHIEN OWNER"; Title.TextColor3 = Color3.new(1, 1, 1); Title.Font = Enum.Font.GothamBlack; Title.TextSize = 14; Title.BackgroundTransparency = 1
local Holder = Instance.new("ScrollingFrame", Main); Holder.Size = UDim2.new(0.9, 0, 0.85, 0); Holder.Position = UDim2.new(0.05, 0, 0.12, 0); Holder.BackgroundTransparency = 1; Holder.CanvasSize = UDim2.new(0, 0, 1.4, 0); Holder.ScrollBarThickness = 0
local Layout = Instance.new("UIListLayout", Holder); Layout.Padding = UDim.new(0, 8); Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
IconBtn.Activated:Connect(function() Main.Visible = not Main.Visible end)

local function AddMod(name, var, colorOn)
    local btn = Instance.new("TextButton", Holder); btn.Size = UDim2.new(1, 0, 0, 42); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35); btn.Text = name .. ": OFF"; btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", btn); s.Thickness = 1.5; s.Color = Color3.fromRGB(50, 50, 60)
    btn.Activated:Connect(function() Mod[var] = not Mod[var]; btn.Text = name .. ": " .. (Mod[var] and "ON" or "OFF"); btn.BackgroundColor3 = Mod[var] and colorOn or Color3.fromRGB(25, 25, 35); s.Color = Mod[var] and Color3.new(1, 1, 1) or Color3.fromRGB(50, 50, 60) end)
end

AddMod("  ESP ", "ESP", Color3.fromRGB(0, 120, 255))
AddMod(" ÁM SÁT ", "Assassinate", Color3.fromRGB(255, 100, 0))
AddMod(" KILL ", "Kill", Color3.fromRGB(200, 0, 0))
AddMod(" ĐÁNH NHANH", "FastAttack", Color3.fromRGB(255, 0, 100))
AddMod(" ANTI-REPORT", "AntiReport", Color3.fromRGB(150, 0, 255))

-- ==========================================================
-- LOGIC TÁCH BIỆT TỪNG NÚT (STANDALONE MODULES)
-- ==========================================================

-- [MODULE 1]: TỐC ĐÁNH 150X
task.spawn(function()
    while true do
        RunService.RenderStepped:Wait()
        if Mod.FastAttack then
            pcall(function()
                local char = LocalPlayer.Character
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    for _, anim in pairs(char.Humanoid:GetPlayingAnimationTracks()) do anim:AdjustSpeed(150) end
                    for i = 1, 25 do task.spawn(function() tool:Activate() end) end
                end
            end)
        end
    end
end)

-- [MODULE 2]: ÁM SÁT (TELE + CHÉM RIÊNG)
task.spawn(function()
    while task.wait() do
        if Mod.Assassinate then
            pcall(function()
                local hrp = LocalPlayer.Character.HumanoidRootPart
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character and v.Character.Humanoid.Health > 0 then
                        local tHRP = v.Character.HumanoidRootPart
                        if (hrp.Position - tHRP.Position).Magnitude < Mod.Range then
                            hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
                            -- Tự cầm kiếm & chém của riêng nút Ám sát
                            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if tool then tool.Parent = LocalPlayer.Character; tool:Activate() end
                        end
                    end
                end
            end)
        end
    end
end)

-- [MODULE 3]: DIỆT HACK (KÉO + CHÉM RIÊNG)
task.spawn(function()
    while task.wait() do
        if Mod.Kill then
            pcall(function()
                local hrp = LocalPlayer.Character.HumanoidRootPart
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character and v.Character.Humanoid.Health > 0 then
                        local tHRP = v.Character.HumanoidRootPart
                        if (hrp.Position - tHRP.Position).Magnitude < Mod.Range then
                            tHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -3.5)
                            -- Tự cầm kiếm & chém của riêng nút Kill
                            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if tool then tool.Parent = LocalPlayer.Character; tool:Activate() end
                        end
                    end
                end
            end)
        end
    end
end)

-- [MODULE 4]: ESP (HIỆN KHUNG RIÊNG)
task.spawn(function()
    while task.wait(1) do
        if Mod.ESP then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("MC_ESP") then
                    local b = Instance.new("BoxHandleAdornment", p.Character); b.Name = "MC_ESP"; b.Adornee = p.Character; b.AlwaysOnTop = true; b.Size = Vector3.new(4, 5, 1); b.Color3 = Color3.new(1,0,0); b.Transparency = 0.6
                end
            end
        end
    end
end)

-- [MODULE 5]: ANTI-REPORT (SERVER HOP RIÊNG)
TextChatService.MessageReceived:Connect(function(msg)
    if Mod.AntiReport and msg.TextSource and msg.TextSource.Name ~= LocalPlayer.Name then
        local reportWords = {"hack", "hacker", "cheat", "cheater", "tố cáo", "report"}
        for _, word in pairs(reportWords) do
            if string.find(string.lower(msg.Text), word) then
                local s = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")).data
                for _, v in pairs(s) do if v.playing < v.maxPlayers and v.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer) break end end
            end
        end
    end
end)

print("👑 MINHCHIEN OWNER ")