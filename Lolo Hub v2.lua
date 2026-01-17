--[[ 
    ULTIMATE ADMIN PANEL v6.5 (FULL VERSION)
    - Système de TP : Fenêtre indépendante (Fixé)
    - Fly : Statique (Z,Q,S,D / Mobile Touch) (Fixé)
    - NoClip : Désactivation instantanée (Fixé)
    - Tout le reste : Dash, ESP, GodMode, Aimbot, XRay, Zoom, Bright.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

-- --- ÉTATS ---
local states = {
    noclip = false, godmode = false, dash = false, fly = false,
    esp = false, infjump = false, infzoom = false, xray = false, aimbot = false
}

local connections = {}
local xrayOriginals = {}
local flyBV, flyBG = nil, nil

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- --- THEME ET TAILLES (RESPONSIVE) ---
local GUI_THEME = {
    Background = Color3.fromRGB(15, 15, 20),
    Header = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(0, 200, 255),
    ButtonOff = Color3.fromRGB(35, 35, 45),
    ButtonOn = Color3.fromRGB(0, 200, 255),
    Text = Color3.fromRGB(255, 255, 255)
}

local sizes = isMobile and {w = 210, h = 320, head = 35, btn = 32, txt = 10} or {w = 380, h = 500, head = 60, btn = 55, txt = 14}

-- --- GUI BASE ---
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "UltimateAdmin_v65"
screenGui.ResetOnSpawn = false

local main = Instance.new("Frame", screenGui)
main.Name = "MainFrame"
main.Size = UDim2.new(0, sizes.w, 0, sizes.h)
main.Position = UDim2.new(0.5, -sizes.w/2, 0.5, -sizes.h/2)
main.BackgroundColor3 = GUI_THEME.Background
main.BorderSizePixel = 0
main.Visible = not isMobile
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 15)

-- Glow Border
local stroke = Instance.new("UIStroke", main)
stroke.Color = GUI_THEME.Accent
stroke.Thickness = 2
stroke.Transparency = 0.5

-- Bouton Menu Mobile
if isMobile then
    local menuBtn = Instance.new("TextButton", screenGui)
    menuBtn.Size = UDim2.new(0, 45, 0, 45); menuBtn.Position = UDim2.new(0, 10, 0.5, -22)
    menuBtn.BackgroundColor3 = GUI_THEME.Accent; menuBtn.Text = "MENU"; menuBtn.Font = Enum.Font.GothamBold; menuBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(1, 0)
    menuBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
end

-- Header & Title
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, sizes.head); header.BackgroundColor3 = GUI_THEME.Header
Instance.new("UICorner", header)

local icon = Instance.new("TextLabel", header)
icon.Text = "⚡"; icon.Size = UDim2.new(0, 30, 1, 0); icon.Position = UDim2.new(0, 10, 0, 0)
icon.TextColor3 = GUI_THEME.Accent; icon.BackgroundTransparency = 1; icon.Font = Enum.Font.GothamBold; icon.TextSize = sizes.txt + 4

local title = Instance.new("TextLabel", header)
title.Text = "ULTIMATE ADMIN v6.5"; title.Size = UDim2.new(1, -40, 1, 0); title.Position = UDim2.new(0, 40, 0, 0)
title.TextColor3 = Color3.new(1,1,1); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.TextSize = sizes.txt; title.TextXAlignment = "Left"

-- Scroll Container
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -10, 1, -sizes.head - 10); scroll.Position = UDim2.new(0, 5, 0, sizes.head + 5)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 2; scroll.AutomaticCanvasSize = "Y"
local layout = Instance.new("UIListLayout", scroll); layout.Padding = UDim.new(0, 5); layout.HorizontalAlignment = "Center"

-- --- UTILS ---
local function getChar() return player.Character end
local function getHum() return getChar() and getChar():FindFirstChild("Humanoid") end
local function getRoot() return getChar() and getChar():FindFirstChild("HumanoidRootPart") end

-- --- FONCTIONS SPÉCIFIQUES ---

-- FLY FIXE
local function handleFly()
    if not states.fly or not getRoot() then return end
    local speed = 50; local dir = Vector3.new(0,0,0); local cf = camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
    if isMobile and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then dir = cf.LookVector end
    flyBG.cframe = cf; flyBV.velocity = dir * speed
end

-- NOCLIP FIXE
local function toggleNoClip(active)
    states.noclip = active
    if active then
        connections["NoClip"] = RunService.Stepped:Connect(function()
            if states.noclip and getChar() then
                for _, v in pairs(getChar():GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
            end
        end)
    else
        if connections["NoClip"] then connections["NoClip"]:Disconnect() end
        if getChar() then
            for _, v in pairs(getChar():GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
        end
    end
end

-- AIMBOT / AUTO-LOCK
local function handleAimbot()
    if not states.aimbot then return end
    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or (isMobile and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))
    if isAiming then
        local target = nil; local dist = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
                local d = (getRoot().Position - p.Character.Head.Position).Magnitude
                if d < dist and d < 500 then dist = d; target = p.Character.Head end
            end
        end
        if target then camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position) end
    end
end

-- --- CRÉATION DES BOUTONS ---
local function addToggle(txt, cb)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, -10, 0, sizes.btn); b.BackgroundColor3 = GUI_THEME.ButtonOff
    b.Text = txt; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold; b.TextSize = sizes.txt
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local active = false
    b.MouseButton1Click:Connect(function()
        active = not active
        b.BackgroundColor3 = active and GUI_THEME.Accent or GUI_THEME.ButtonOff
        cb(active)
    end)
end

-- --- LISTE DES CAPACITÉS ---

addToggle("1. NoClip (Murs) ✓", toggleNoClip)

addToggle("2. Fly Mode (Fix) ✓", function(a)
    states.fly = a
    if a and getRoot() then
        flyBG = Instance.new("BodyGyro", getRoot()); flyBG.maxTorque = Vector3.new(9e9,9e9,9e9)
        flyBV = Instance.new("BodyVelocity", getRoot()); flyBV.maxForce = Vector3.new(9e9,9e9,9e9)
        connections["Fly"] = RunService.RenderStepped:Connect(handleFly)
    else
        if connections["Fly"] then connections["Fly"]:Disconnect() end
        if flyBG then flyBG:Destroy() end; if flyBV then flyBV:Destroy() end
    end
end)

addToggle("3. Admin Auto-Lock", function(a)
    states.aimbot = a
    if a then connections["Aimbot"] = RunService.RenderStepped:Connect(handleAimbot)
    else if connections["Aimbot"] then connections["Aimbot"]:Disconnect() end end
end)

addToggle("4. ESP Joueurs", function(a)
    states.esp = a
    if not a then for _,v in pairs(Workspace:GetDescendants()) do if v.Name == "ESP_MARK" then v:Destroy() end end end
    connections["ESP"] = RunService.RenderStepped:Connect(function()
        if states.esp then
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("Head") and not p.Character.Head:FindFirstChild("ESP_MARK") then
                    local b = Instance.new("BillboardGui", p.Character.Head); b.Name = "ESP_MARK"; b.AlwaysOnTop = true; b.Size = UDim2.new(0,80,0,40)
                    local t = Instance.new("TextLabel", b); t.Text = p.Name; t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.TextColor3 = GUI_THEME.Accent; t.Font = "GothamBold"; t.TextScaled = true
                end
            end
        end
    end)
end)

addToggle("5. Dash (Clic/Touch)", function(a) states.dash = a end)
mouse.Button1Down:Connect(function() if states.dash and getRoot() then getRoot().CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0)) end end)

addToggle("6. God Mode", function(a)
    states.godmode = a
    connections["God"] = RunService.Heartbeat:Connect(function() if states.godmode and getHum() then getHum().Health = 100 end end)
end)

addToggle("7. Vitesse Éclair", function(a) if getHum() then getHum().WalkSpeed = a and 100 or 16 end end)

addToggle("8. Saut Infini", function(a)
    states.infjump = a
    connections["Jump"] = UserInputService.JumpRequest:Connect(function() if states.infjump and getHum() then getHum():ChangeState(3) end end)
end)

addToggle("9. X-Ray (Murs)", function(a)
    for _,v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
        if a then xrayOriginals[v] = v.Transparency; v.Transparency = 0.5 else v.Transparency = xrayOriginals[v] or 0 end
    end end
end)

addToggle("10. Full Bright", function(a)
    Lighting.Ambient = a and Color3.new(1,1,1) or Color3.fromRGB(127,127,127)
    Lighting.Brightness = a and 2 or 1
end)

addToggle("11. Zoom Infini", function(a)
    player.CameraMaxZoomDistance = a and 9999 or 400
    player.CameraMinZoomDistance = a and 0 or 0.5
end)

-- --- SYSTÈME TP JOUEUR (FENÊTRE FIXE) ---
local tpWin = Instance.new("Frame", screenGui)
tpWin.Size = UDim2.new(0, 180, 0, 200); tpWin.Position = UDim2.new(0.5, 60, 0.5, -100)
tpWin.BackgroundColor3 = Color3.fromRGB(20, 20, 30); tpWin.Visible = false
Instance.new("UICorner", tpWin); Instance.new("UIStroke", tpWin).Color = GUI_THEME.Accent

local tpScr = Instance.new("ScrollingFrame", tpWin)
tpScr.Size = UDim2.new(1, -10, 1, -10); tpScr.Position = UDim2.new(0, 5, 0, 5)
tpScr.BackgroundTransparency = 1; tpScr.AutomaticCanvasSize = "Y"; tpScr.ScrollBarThickness = 2
Instance.new("UIListLayout", tpScr).Padding = UDim.new(0, 3)

addToggle("12. 👥 TP VERS JOUEUR ▼", function()
    tpWin.Visible = not tpWin.Visible
    if tpWin.Visible then
        for _, v in pairs(tpScr:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                local pb = Instance.new("TextButton", tpScr)
                pb.Size = UDim2.new(1, 0, 0, 30); pb.Text = p.DisplayName; pb.BackgroundColor3 = Color3.fromRGB(40, 45, 60); pb.TextColor3 = Color3.new(1,1,1)
                pb.MouseButton1Click:Connect(function() if getRoot() and p.Character then getRoot().CFrame = p.Character.HumanoidRootPart.CFrame end; tpWin.Visible = false end)
            end
        end
    end
end)

-- Drag & Drop
local d = false; local s; local sp
header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true s = i.Position sp = main.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
    local delta = i.Position - s; main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
end end)
UserInputService.InputEnded:Connect(function() d = false end)

game:GetService("StarterGui"):SetCore("SendNotification", {Title = "ADMIN v6.5", Text = "Tout est prêt !", Duration = 3})
