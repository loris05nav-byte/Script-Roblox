--[[ 
    ULTIMATE ADMIN PANEL v7.0 (FULL VERSION & PREMIUM UI)
    - Système de Bulle Déplaçable : Bouton "-" ajouté + Touche G + Animation (Nouveau)
    - UI Moderne : Glassmorphism & Animations (Fixé)
    - Système de TP : Fenêtre indépendante et stylisée (Fixé)
    - Fly : Statique (Z,Q,S,D / Mobile Touch) (Conservé)
    - NoClip : Désactivation instantanée (Conservé)
    - Fonctionnalités : Dash, ESP, GodMode, Aimbot, XRay, Zoom, Bright. (Toutes conservées)
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

-- --- ÉTATS & VARIABLES ---
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
    Background = Color3.fromRGB(15, 15, 22),
    Header = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(0, 200, 255),
    ButtonOff = Color3.fromRGB(35, 35, 45),
    ButtonOn = Color3.fromRGB(0, 200, 255),
    Text = Color3.fromRGB(255, 255, 255),
    Transparency = 0.1 -- Effet Glass
}

local sizes = isMobile and {w = 240, h = 340, head = 40, btn = 35, txt = 11} or {w = 380, h = 520, head = 60, btn = 45, txt = 14}

-- --- FONCTIONS DE DRAG (GLISSER-DÉPOSER) ---
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- --- GUI BASE ---
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "UltimateAdmin_v70"
screenGui.ResetOnSpawn = false

-- Bulle Flottante (Minimized)
local bubble = Instance.new("TextButton", screenGui)
bubble.Name = "Bubble"
bubble.Size = UDim2.new(0, 50, 0, 50)
bubble.Position = UDim2.new(0, 20, 0.5, -25)
bubble.BackgroundColor3 = GUI_THEME.Background
bubble.Text = "⚡"
bubble.TextColor3 = GUI_THEME.Accent
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 24
bubble.Visible = false
bubble.AutoButtonColor = false
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", bubble).Color = GUI_THEME.Accent
Instance.new("UIStroke", bubble).Thickness = 2

-- Main Frame
local main = Instance.new("Frame", screenGui)
main.Name = "MainFrame"
main.Size = UDim2.new(0, sizes.w, 0, sizes.h)
main.Position = UDim2.new(0.5, -sizes.w/2, 0.5, -sizes.h/2)
main.BackgroundColor3 = GUI_THEME.Background
main.BackgroundTransparency = GUI_THEME.Transparency
main.BorderSizePixel = 0
main.Visible = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 15)

-- Glow Border
local stroke = Instance.new("UIStroke", main)
stroke.Color = GUI_THEME.Accent
stroke.Thickness = 2
stroke.Transparency = 0.3

-- Header & Title
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, sizes.head)
header.BackgroundColor3 = GUI_THEME.Header
header.BackgroundTransparency = GUI_THEME.Transparency
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 15)

-- Pour éviter que les coins arrondis en bas du header ne se voient
local headerBottom = Instance.new("Frame", header)
headerBottom.Size = UDim2.new(1, 0, 0, 10)
headerBottom.Position = UDim2.new(0, 0, 1, -10)
headerBottom.BackgroundColor3 = GUI_THEME.Header
headerBottom.BorderSizePixel = 0

local icon = Instance.new("TextLabel", header)
icon.Text = "⚡"
icon.Size = UDim2.new(0, 40, 1, 0); icon.Position = UDim2.new(0, 10, 0, 0)
icon.TextColor3 = GUI_THEME.Accent; icon.BackgroundTransparency = 1
icon.Font = Enum.Font.GothamBold; icon.TextSize = sizes.txt + 6

local title = Instance.new("TextLabel", header)
title.Text = "ULTIMATE ADMIN v7.0"
title.Size = UDim2.new(1, -90, 1, 0); title.Position = UDim2.new(0, 50, 0, 0)
title.TextColor3 = GUI_THEME.Text; title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold; title.TextSize = sizes.txt + 2
title.TextXAlignment = Enum.TextXAlignment.Left

-- Bouton de réduction "-"
local minBtn = Instance.new("TextButton", header)
minBtn.Size = UDim2.new(0, 40, 1, 0)
minBtn.Position = UDim2.new(1, -40, 0, 0)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = GUI_THEME.Text
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = sizes.txt + 12

-- Scroll Container
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -16, 1, -sizes.head - 16)
scroll.Position = UDim2.new(0, 8, 0, sizes.head + 8)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarImageColor3 = GUI_THEME.Accent
local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 8); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- --- LOGIQUE DE TOGGLE (BULLE / MAIN) ---
local isOpen = true
local isAnimating = false

local function toggleUI()
    if isAnimating then return end
    isAnimating = true
    isOpen = not isOpen
    
    if isOpen then
        bubble.Visible = false
        main.Visible = true
        main.Size = UDim2.new(0, sizes.w * 0.8, 0, sizes.h * 0.8)
        local tween = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, sizes.w, 0, sizes.h)})
        tween:Play()
        tween.Completed:Connect(function() isAnimating = false end)
    else
        local tween = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, sizes.w * 0.8, 0, sizes.h * 0.8)})
        tween:Play()
        tween.Completed:Connect(function()
            main.Visible = false
            bubble.Visible = true
            -- Placement dynamique de la bulle à l'endroit du menu
            bubble.Position = UDim2.new(0, main.AbsolutePosition.X + (sizes.w/2) - 25, 0, main.AbsolutePosition.Y + (sizes.head/2) - 10)
            isAnimating = false
        end)
    end
end

-- Raccourci G
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.G then
        toggleUI()
    end
end)

-- Clic sur la bulle et le bouton réduire
bubble.MouseButton1Click:Connect(function() toggleUI() end)
minBtn.MouseButton1Click:Connect(function() toggleUI() end)

-- Rendre la fenêtre principale et la bulle déplaçables
makeDraggable(main, header)
makeDraggable(bubble, bubble)

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
    local btnFrame = Instance.new("Frame", scroll)
    btnFrame.Size = UDim2.new(1, -10, 0, sizes.btn)
    btnFrame.BackgroundTransparency = 1

    local b = Instance.new("TextButton", btnFrame)
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundColor3 = GUI_THEME.ButtonOff
    b.Text = "  " .. txt
    b.TextColor3 = GUI_THEME.Text
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = sizes.txt
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    
    local statusIndicator = Instance.new("Frame", b)
    statusIndicator.Size = UDim2.new(0, 4, 0.6, 0)
    statusIndicator.Position = UDim2.new(1, -12, 0.2, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", statusIndicator).CornerRadius = UDim.new(1, 0)

    local active = false
    b.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(25, 60, 80) or GUI_THEME.ButtonOff}):Play()
        TweenService:Create(statusIndicator, TweenInfo.new(0.2), {BackgroundColor3 = active and GUI_THEME.Accent or Color3.fromRGB(60, 60, 70)}):Play()
        cb(active)
    end)
end

-- --- LISTE DES CAPACITÉS ---

addToggle("1. NoClip (Murs)", toggleNoClip)

addToggle("2. Fly Mode (Fix)", function(a)
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
tpWin.Size = UDim2.new(0, 200, 0, 250)
tpWin.Position = UDim2.new(0.5, sizes.w/2 + 20, 0.5, -125)
tpWin.BackgroundColor3 = GUI_THEME.Background
tpWin.BackgroundTransparency = GUI_THEME.Transparency
tpWin.Visible = false
Instance.new("UICorner", tpWin).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", tpWin).Color = GUI_THEME.Accent
Instance.new("UIStroke", tpWin).Transparency = 0.3

local tpHeader = Instance.new("Frame", tpWin)
tpHeader.Size = UDim2.new(1, 0, 0, 30)
tpHeader.BackgroundColor3 = GUI_THEME.Header
Instance.new("UICorner", tpHeader).CornerRadius = UDim.new(0, 10)
local tpTitle = Instance.new("TextLabel", tpHeader)
tpTitle.Size = UDim2.new(1, 0, 1, 0)
tpTitle.BackgroundTransparency = 1
tpTitle.Text = "TELEPORTATION"
tpTitle.TextColor3 = GUI_THEME.Accent
tpTitle.Font = Enum.Font.GothamBold

local tpScr = Instance.new("ScrollingFrame", tpWin)
tpScr.Size = UDim2.new(1, -10, 1, -40); tpScr.Position = UDim2.new(0, 5, 0, 35)
tpScr.BackgroundTransparency = 1; tpScr.AutomaticCanvasSize = Enum.AutomaticSize.Y
tpScr.ScrollBarThickness = 2
local tpLayout = Instance.new("UIListLayout", tpScr)
tpLayout.Padding = UDim.new(0, 5)

-- Rendre la fenêtre de TP déplaçable
makeDraggable(tpWin, tpHeader)

addToggle("12. 👥 TP VERS JOUEUR ▼", function(active)
    tpWin.Visible = active
    if tpWin.Visible then
        for _, v in pairs(tpScr:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                local pb = Instance.new("TextButton", tpScr)
                pb.Size = UDim2.new(1, 0, 0, 30); pb.Text = p.DisplayName
                pb.BackgroundColor3 = GUI_THEME.ButtonOff; pb.TextColor3 = GUI_THEME.Text
                pb.Font = Enum.Font.Gotham
                Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 5)
                pb.MouseButton1Click:Connect(function() 
                    if getRoot() and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then 
                        getRoot().CFrame = p.Character.HumanoidRootPart.CFrame 
                    end 
                end)
            end
        end
    end
end)

-- --- NOTIFICATION DE LANCEMENT ---
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "ADMIN v7.0", 
    Text = "Panel chargé ! Touche [G] ou [-] pour réduire le menu.", 
    Duration = 5,
    Icon = "rbxassetid://1087851214" -- Icône par défaut
})
