--[[ 
    ULTIMATE ADMIN PANEL v8.0 (SPECTATE & BOOMBOX INTEGRATED EDITION)
    - Système de Bulle Déplaçable : Bouton "-" ajouté + Touche G + Animation (Conservé)
    - Système de TP : Fenêtre indépendante (Conservé)
    - Système de Spectate : Fenêtre indépendante (Conservé)
    - Système de Boombox RELICSxyz v4.1 Final Compact : Fenêtre indépendante réactive (Nouveau)
    - Fonctions Core : Fly, NoClip, Dash, ESP, GodMode, Aimbot, XRay, Zoom, Bright (Conservées)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- --- ÉTATS & VARIABLES ---
local states = {
    noclip = false, godmode = false, dash = false, fly = false,
    esp = false, entitiesESP = false, infjump = false, infzoom = false, xray = false, aimbot = false
}

local connections = {}
local xrayOriginals = {}
local xrayConnection = nil
local xrayAccumulator = 0
local XRAY_RADIUS = 220       -- Ne traite que la zone autour du joueur
local XRAY_MAX_PARTS = 450    -- Limite stricte pour éviter les cartes surchargées
local XRAY_UPDATE_INTERVAL = 0.45
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
    Transparency = 0.1
}

local sizes = isMobile and {w = 240, h = 340, head = 40, btn = 35, txt = 11} or {w = 380, h = 550, head = 60, btn = 45, txt = 14}

-- --- BOOMBOX CORE CONFIGURATION ---
local sound = Instance.new("Sound")
sound.Name = "RelicsBoombox"
sound.Volume = 0.7
sound.Parent = Workspace

local favorites = {}
local SAVE_KEY = "relics_v41_favs"

local function saveFavs()
    local data = HttpService:JSONEncode(favorites)
    if writefile then pcall(writefile, SAVE_KEY..".json", data) end
    player:SetAttribute(SAVE_KEY, data)
end

local function loadFavs()
    local data = nil
    if readfile and isfile and isfile(SAVE_KEY..".json") then
        data = readfile(SAVE_KEY..".json")
    else
        data = player:GetAttribute(SAVE_KEY)
    end
    if data then
        local ok, tbl = pcall(HttpService.JSONDecode, HttpService, data)
        if ok and type(tbl) == "table" then favorites = tbl end
    end
end
loadFavs()

-- --- FONCTIONS DE DRAG (GLISSER-DÉPOSER) ---
-- Un seul suivi global évite d'empiler des connexions à chaque fenêtre.
local activeDrag = nil
local DRAG_THRESHOLD = 4

local function makeDraggable(frame, handle)
    local dragState = { dragged = false }
    handle.Active = true

    handle.InputBegan:Connect(function(input)
        local inputType = input.UserInputType
        if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
            return
        end

        dragState.dragged = false
        activeDrag = {
            frame = frame,
            handle = handle,
            input = input,
            inputType = inputType,
            startPointer = input.Position,
            startAbsolute = frame.AbsolutePosition,
            startSize = frame.AbsoluteSize,
            state = dragState,
        }
    end)

    return dragState
end

UserInputService.InputChanged:Connect(function(input)
    local drag = activeDrag
    if not drag or not drag.frame or not drag.frame.Parent then return end

    local isMouseMove = drag.inputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement
    local isTouchMove = drag.inputType == Enum.UserInputType.Touch
        and input.UserInputType == Enum.UserInputType.Touch
        and input == drag.input
    if not isMouseMove and not isTouchMove then return end

    local delta = input.Position - drag.startPointer
    if delta.Magnitude < DRAG_THRESHOLD and not drag.state.dragged then return end
    drag.state.dragged = true

    local viewport = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
    local frameSize = drag.frame.AbsoluteSize
    local left = math.clamp(drag.startAbsolute.X + delta.X, 0, math.max(0, viewport.X - frameSize.X))
    local top = math.clamp(drag.startAbsolute.Y + delta.Y, 0, math.max(0, viewport.Y - frameSize.Y))

    -- AbsolutePosition est le coin supérieur gauche ; Position dépend de l'AnchorPoint.
    local anchor = drag.frame.AnchorPoint
    drag.frame.Position = UDim2.fromOffset(
        left + frameSize.X * anchor.X,
        top + frameSize.Y * anchor.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    local drag = activeDrag
    if not drag then return end
    if input == drag.input or (drag.inputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
        activeDrag = nil
    end
end)

-- --- GUI BASE ---
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "UltimateAdmin_v80"
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
local mainGradient = Instance.new("UIGradient", main)
mainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 24, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 13, 19)),
})
mainGradient.Rotation = 90

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
local headerGradient = Instance.new("UIGradient", header)
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 43, 61)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 22, 32)),
})
headerGradient.Rotation = 0

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
title.Text = "ULTIMATE ADMIN v8.0"
title.Size = UDim2.new(1, -90, 1, 0); title.Position = UDim2.new(0, 50, 0, 0)
title.TextColor3 = GUI_THEME.Text; title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold; title.TextSize = sizes.txt + 2
title.TextXAlignment = Enum.TextXAlignment.Left

-- Bouton de réduction "-"
local minBtn = Instance.new("TextButton", header)
minBtn.Size = UDim2.new(0, 40, 1, 0)
minBtn.Position = UDim2.new(1, -80, 0, 0)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = GUI_THEME.Text
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = sizes.txt + 12

-- Bouton de fermeture définitive (avec confirmation)
local closeBtn = Instance.new("TextButton", header)
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 40, 1, 0)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 95, 105)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = sizes.txt + 10
closeBtn.AutoButtonColor = false
closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(255, 145, 150) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(255, 95, 105) end)

-- Fenêtre de confirmation, cachée tant que l'utilisateur ne clique pas sur ×.
local closeConfirm = Instance.new("Frame", screenGui)
closeConfirm.Name = "CloseConfirmation"
closeConfirm.AnchorPoint = Vector2.new(0.5, 0.5)
closeConfirm.Position = UDim2.new(0.5, 0, 0.5, 0)
closeConfirm.Size = UDim2.new(0, isMobile and 280 or 360, 0, 175)
closeConfirm.BackgroundColor3 = Color3.fromRGB(20, 22, 31)
closeConfirm.BorderSizePixel = 0
closeConfirm.Visible = false
closeConfirm.ZIndex = 50
Instance.new("UICorner", closeConfirm).CornerRadius = UDim.new(0, 12)
local confirmStroke = Instance.new("UIStroke", closeConfirm)
confirmStroke.Color = Color3.fromRGB(255, 95, 105)
confirmStroke.Thickness = 1.5

local confirmTitle = Instance.new("TextLabel", closeConfirm)
confirmTitle.BackgroundTransparency = 1
confirmTitle.Position = UDim2.new(0, 14, 0, 12)
confirmTitle.Size = UDim2.new(1, -28, 0, 30)
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.Text = "Fermer le panel ?"
confirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmTitle.TextSize = isMobile and 16 or 18
confirmTitle.ZIndex = 51

local confirmText = Instance.new("TextLabel", closeConfirm)
confirmText.BackgroundTransparency = 1
confirmText.Position = UDim2.new(0, 16, 0, 45)
confirmText.Size = UDim2.new(1, -32, 0, 48)
confirmText.Font = Enum.Font.Gotham
confirmText.Text = "Le script va s'arrêter et ses effets seront annulés. Cette action est définitive pour cette session."
confirmText.TextWrapped = true
confirmText.TextColor3 = Color3.fromRGB(205, 210, 220)
confirmText.TextSize = isMobile and 11 or 13
confirmText.ZIndex = 51

local cancelCloseBtn = Instance.new("TextButton", closeConfirm)
cancelCloseBtn.Name = "CancelClose"
cancelCloseBtn.Size = UDim2.new(0.43, 0, 0, 36)
cancelCloseBtn.Position = UDim2.new(0.05, 0, 1, -48)
cancelCloseBtn.BackgroundColor3 = Color3.fromRGB(55, 59, 72)
cancelCloseBtn.Text = "Annuler"
cancelCloseBtn.TextColor3 = Color3.new(1, 1, 1)
cancelCloseBtn.Font = Enum.Font.GothamSemibold
cancelCloseBtn.TextSize = isMobile and 12 or 14
cancelCloseBtn.ZIndex = 51
Instance.new("UICorner", cancelCloseBtn).CornerRadius = UDim.new(0, 7)

local confirmCloseBtn = Instance.new("TextButton", closeConfirm)
confirmCloseBtn.Name = "ConfirmClose"
confirmCloseBtn.Size = UDim2.new(0.43, 0, 0, 36)
confirmCloseBtn.Position = UDim2.new(0.52, 0, 1, -48)
confirmCloseBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 55)
confirmCloseBtn.Text = "Fermer"
confirmCloseBtn.TextColor3 = Color3.new(1, 1, 1)
confirmCloseBtn.Font = Enum.Font.GothamBold
confirmCloseBtn.TextSize = isMobile and 12 or 14
confirmCloseBtn.ZIndex = 51
Instance.new("UICorner", confirmCloseBtn).CornerRadius = UDim.new(0, 7)

closeBtn.MouseButton1Click:Connect(function()
    closeConfirm.Visible = true
end)
cancelCloseBtn.MouseButton1Click:Connect(function()
    closeConfirm.Visible = false
end)

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
            bubble.Position = UDim2.new(0, main.AbsolutePosition.X + (sizes.w/2) - 25, 0, main.AbsolutePosition.Y + (sizes.head/2) - 10)
            isAnimating = false
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.G then
        toggleUI()
    end
end)

makeDraggable(main, header)
local bubbleDragState = makeDraggable(bubble, bubble)

bubble.MouseButton1Click:Connect(function()
    -- Un glissement de la bulle ne doit pas être interprété comme un clic d'ouverture.
    if not bubbleDragState.dragged then toggleUI() end
end)
minBtn.MouseButton1Click:Connect(function() toggleUI() end)

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
    local buttonStroke = Instance.new("UIStroke", b)
    buttonStroke.Color = GUI_THEME.Accent
    buttonStroke.Thickness = 1
    buttonStroke.Transparency = 0.88

    local statusIndicator = Instance.new("Frame", b)
    statusIndicator.Size = UDim2.new(0, 4, 0.6, 0)
    statusIndicator.Position = UDim2.new(1, -12, 0.2, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Instance.new("UICorner", statusIndicator).CornerRadius = UDim.new(1, 0)

    local active = false
    local hovered = false

    local function refreshToggleStyle()
        local targetColor
        if active then
            targetColor = Color3.fromRGB(25, 60, 80)
        elseif hovered then
            targetColor = Color3.fromRGB(45, 50, 64)
        else
            targetColor = GUI_THEME.ButtonOff
        end
        TweenService:Create(b, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = targetColor
        }):Play()
        TweenService:Create(buttonStroke, TweenInfo.new(0.14), {
            Transparency = (active or hovered) and 0.45 or 0.88
        }):Play()
        TweenService:Create(statusIndicator, TweenInfo.new(0.14), {
            BackgroundColor3 = active and GUI_THEME.Accent or (hovered and Color3.fromRGB(100, 115, 135) or Color3.fromRGB(60, 60, 70))
        }):Play()
    end

    b.MouseEnter:Connect(function()
        hovered = true
        refreshToggleStyle()
    end)
    b.MouseLeave:Connect(function()
        hovered = false
        refreshToggleStyle()
    end)
    b.MouseButton1Click:Connect(function()
        active = not active
        refreshToggleStyle()
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

addToggle("7. Vitesse Éclair", function(a) if getHum() then getHum().WalkSpeed = a and 70 or 16 end end)

addToggle("8. Saut Infini", function(a)
    states.infjump = a
    connections["Jump"] = UserInputService.JumpRequest:Connect(function() if states.infjump and getHum() then getHum():ChangeState(3) end end)
end)

-- X-Ray optimisé : aucun parcours de toute la map.
-- Utilise une requête spatiale limitée autour du joueur et traite un nombre maximal de pièces.
local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function restoreXRayPart(part)
    local original = xrayOriginals[part]
    if original ~= nil then
        if part and part.Parent then
            part.LocalTransparencyModifier = original
        end
        xrayOriginals[part] = nil
    end
end

local function stopXRay()
    if xrayConnection then
        xrayConnection:Disconnect()
        xrayConnection = nil
    end
    for part, original in pairs(xrayOriginals) do
        if part and part.Parent then
            part.LocalTransparencyModifier = original
        end
        xrayOriginals[part] = nil
    end
    xrayAccumulator = 0
    states.xray = false
end

local function updateXRay()
    local root = getRoot()
    if not root then return end

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = player.Character and {player.Character} or {}
    overlap.MaxParts = XRAY_MAX_PARTS

    local ok, nearbyParts = pcall(function()
        return Workspace:GetPartBoundsInRadius(root.Position, XRAY_RADIUS, overlap)
    end)
    if not ok or not nearbyParts then return end

    local currentlyNearby = {}
    for _, part in ipairs(nearbyParts) do
        if part:IsA("BasePart") and part.Parent and not isCharacterPart(part) then
            currentlyNearby[part] = true
            if xrayOriginals[part] == nil then
                xrayOriginals[part] = part.LocalTransparencyModifier
            end
            part.LocalTransparencyModifier = math.max(xrayOriginals[part], 0.5)
        end
    end

    -- Restaure les pièces sorties de la zone afin de limiter la mémoire et les effets visuels.
    for part, original in pairs(xrayOriginals) do
        if not currentlyNearby[part] then
            restoreXRayPart(part)
        end
    end
end

addToggle("9. X-Ray (Zone optimisée)", function(a)
    if not a then
        stopXRay()
        return
    end

    if xrayConnection then
        xrayConnection:Disconnect()
        xrayConnection = nil
    end
    states.xray = true
    xrayAccumulator = XRAY_UPDATE_INTERVAL
    xrayConnection = RunService.Heartbeat:Connect(function(dt)
        if not states.xray then return end
        xrayAccumulator += dt
        if xrayAccumulator >= XRAY_UPDATE_INTERVAL then
            xrayAccumulator = 0
            updateXRay()
        end
    end)
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

-- --- SYSTÈME SPECTATE JOUEUR (NOUVELLE FENÊTRE) ---
local specWin = Instance.new("Frame", screenGui)
specWin.Size = UDim2.new(0, 200, 0, 250)
specWin.Position = UDim2.new(0.5, -sizes.w/2 - 220, 0.5, -125)
specWin.BackgroundColor3 = GUI_THEME.Background
specWin.BackgroundTransparency = GUI_THEME.Transparency
specWin.Visible = false
Instance.new("UICorner", specWin).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", specWin).Color = GUI_THEME.Accent
Instance.new("UIStroke", specWin).Transparency = 0.3

local specHeader = Instance.new("Frame", specWin)
specHeader.Size = UDim2.new(1, 0, 0, 30)
specHeader.BackgroundColor3 = GUI_THEME.Header
Instance.new("UICorner", specHeader).CornerRadius = UDim.new(0, 10)
local specTitle = Instance.new("TextLabel", specHeader)
specTitle.Size = UDim2.new(1, 0, 1, 0)
specTitle.BackgroundTransparency = 1
specTitle.Text = "SPECTATE"
specTitle.TextColor3 = GUI_THEME.Accent
specTitle.Font = Enum.Font.GothamBold

local specScr = Instance.new("ScrollingFrame", specWin)
specScr.Size = UDim2.new(1, -10, 1, -40); specScr.Position = UDim2.new(0, 5, 0, 35)
specScr.BackgroundTransparency = 1; specScr.AutomaticCanvasSize = Enum.AutomaticSize.Y
specScr.ScrollBarThickness = 2
local specLayout = Instance.new("UIListLayout", specScr)
specLayout.Padding = UDim.new(0, 5)

makeDraggable(specWin, specHeader)

addToggle("13. 👁️ SPECTATE JOUEUR ▼", function(active)
    specWin.Visible = active
    if specWin.Visible then
        for _, v in pairs(specScr:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        
        local stopBtn = Instance.new("TextButton", specScr)
        stopBtn.Size = UDim2.new(1, 0, 0, 30); stopBtn.Text = "❌ STOP SPECTATE"
        stopBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40); stopBtn.TextColor3 = Color3.new(1, 1, 1)
        stopBtn.Font = Enum.Font.GothamBold
        Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 5)
        stopBtn.MouseButton1Click:Connect(function() 
            if getHum() then camera.CameraSubject = getHum() end
        end)

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                local pb = Instance.new("TextButton", specScr)
                pb.Size = UDim2.new(1, 0, 0, 30); pb.Text = p.DisplayName
                pb.BackgroundColor3 = GUI_THEME.ButtonOff; pb.TextColor3 = GUI_THEME.Text
                pb.Font = Enum.Font.Gotham
                Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 5)
                pb.MouseButton1Click:Connect(function() 
                    if p.Character and p.Character:FindFirstChild("Humanoid") then 
                        camera.CameraSubject = p.Character.Humanoid
                    end 
                end)
            end
        end
    else
        if getHum() then camera.CameraSubject = getHum() end
    end
end)

-- --- SYSTÈME BOOMBOX RELICSxyz v4.1 (NOUVELLE FENÊTRE EMBARQUÉE) ---
local boomboxFrame = Instance.new("Frame", screenGui)
boomboxFrame.Name = "BoomboxFrame"
boomboxFrame.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
boomboxFrame.BackgroundTransparency = 0.05
boomboxFrame.BorderSizePixel = 0
boomboxFrame.ClipsDescendants = true
boomboxFrame.Visible = false

local bbCorner = Instance.new("UICorner", boomboxFrame)
bbCorner.CornerRadius = UDim.new(0, 22)

local bbStroke = Instance.new("UIStroke", boomboxFrame)
bbStroke.Color = Color3.fromRGB(100, 110, 255)
bbStroke.Thickness = 1.5
bbStroke.Transparency = 0.3

local bbGrad = Instance.new("UIGradient", bbStroke)
bbGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 90, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 180))
}

task.spawn(function()
    while boomboxFrame.Parent do
        bbGrad.Rotation = (bbGrad.Rotation + 0.2) % 360
        task.wait(0.03)
    end
end)

local function updateBoomboxSize()
    if isMobile then
        boomboxFrame.AnchorPoint = Vector2.new(0.5, 1)
        boomboxFrame.Position = UDim2.new(0.5, 0, 1, -10)
        boomboxFrame.Size = UDim2.new(1, -14, 0, 280)
    else
        boomboxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        boomboxFrame.Position = UDim2.new(0.5, sizes.w / 2 + 250, 0.5, 0)
        boomboxFrame.Size = UDim2.new(0, 440, 0, 600)
    end
end
updateBoomboxSize()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateBoomboxSize)

local bbTopBar = Instance.new("Frame", boomboxFrame)
bbTopBar.Size = UDim2.new(1, 0, 0, 42)
bbTopBar.BackgroundTransparency = 1

local bbTitle = Instance.new("TextLabel", bbTopBar)
bbTitle.Text = "⬣ RELICSxyz"
bbTitle.Font = Enum.Font.GothamBlack
bbTitle.TextSize = isMobile and 18 or 22
bbTitle.TextColor3 = Color3.new(1,1,1)
bbTitle.BackgroundTransparency = 1
bbTitle.Position = UDim2.new(0, 16, 0, 0)
bbTitle.Size = UDim2.new(1, -80, 1, 0)
bbTitle.TextXAlignment = Enum.TextXAlignment.Left

local bbMinBtn = Instance.new("TextButton", bbTopBar)
bbMinBtn.Text = "—"
bbMinBtn.Font = Enum.Font.GothamBold
bbMinBtn.TextSize = 22
bbMinBtn.Size = UDim2.new(0, 34, 0, 34)
bbMinBtn.Position = UDim2.new(1, -44, 0, 4)
bbMinBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
bbMinBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", bbMinBtn).CornerRadius = UDim.new(0, 8)

makeDraggable(boomboxFrame, bbTopBar)

local bbPages = Instance.new("Frame", boomboxFrame)
bbPages.Position = UDim2.new(0, 0, 0, 46)
bbPages.Size = UDim2.new(1, 0, 1, isMobile and -102 or -116)
bbPages.BackgroundTransparency = 1
bbPages.ClipsDescendants = true

local bbPageBrowse = Instance.new("Frame", bbPages); bbPageBrowse.Size = UDim2.new(1,0,1,0); bbPageBrowse.BackgroundTransparency = 1
local bbPagePlay = Instance.new("Frame", bbPages); bbPagePlay.Size = UDim2.new(1,0,1,0); bbPagePlay.Position = UDim2.new(1,0,0,0); bbPagePlay.BackgroundTransparency = 1
local bbPageFavs = Instance.new("ScrollingFrame", bbPages); bbPageFavs.Size = UDim2.new(1,0,1,0); bbPageFavs.Position = UDim2.new(2,0,0,0); bbPageFavs.BackgroundTransparency = 1; bbPageFavs.ScrollBarThickness = 2; bbPageFavs.CanvasSize = UDim2.new(0,0,0,0)

-- Browse Page
local bbSearchBox = Instance.new("TextBox", bbPageBrowse)
bbSearchBox.PlaceholderText = "⌕ Colle un ID Roblox..."
bbSearchBox.Text = ""
bbSearchBox.Font = Enum.Font.GothamMedium
bbSearchBox.TextSize = 15
bbSearchBox.TextColor3 = Color3.new(1,1,1)
bbSearchBox.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
bbSearchBox.Size = UDim2.new(1, -20, 0, isMobile and 38 or 44)
bbSearchBox.Position = UDim2.new(0, 10, 0, 0)
bbSearchBox.ClearTextOnFocus = false
Instance.new("UICorner", bbSearchBox).CornerRadius = UDim.new(0, 10)

local bbScrollList = Instance.new("ScrollingFrame", bbPageBrowse)
bbScrollList.Position = UDim2.new(0, 0, 0, isMobile and 46 or 52)
bbScrollList.Size = UDim2.new(1, 0, 1, isMobile and -46 or -52)
bbScrollList.BackgroundTransparency = 1
bbScrollList.BorderSizePixel = 0
bbScrollList.ScrollBarThickness = 2
bbScrollList.CanvasSize = UDim2.new(0,0,0,0)
local bbListLayout = Instance.new("UIListLayout", bbScrollList)
bbListLayout.Padding = UDim.new(0, 6)
bbListLayout.SortOrder = Enum.SortOrder.LayoutOrder
bbListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    bbScrollList.CanvasSize = UDim2.new(0,0,0, bbListLayout.AbsoluteContentSize.Y + 8)
end)

-- Play Page
local bbBtnHeart = Instance.new("TextButton", bbPagePlay)
bbBtnHeart.Text = "♡"
bbBtnHeart.Font = Enum.Font.GothamBold
bbBtnHeart.TextSize = 24
bbBtnHeart.Size = UDim2.new(0, 36, 0, 36)
bbBtnHeart.Position = UDim2.new(0, 12, 0, 4)
bbBtnHeart.BackgroundTransparency = 1
bbBtnHeart.TextColor3 = Color3.fromRGB(200,200,210)

local bbBtnLoop = Instance.new("TextButton", bbPagePlay)
bbBtnLoop.Text = "∞"
bbBtnLoop.Font = Enum.Font.GothamBold
bbBtnLoop.TextSize = 22
bbBtnLoop.Size = UDim2.new(0, 36, 0, 36)
bbBtnLoop.Position = UDim2.new(0, 50, 0, 4)
bbBtnLoop.BackgroundTransparency = 1
bbBtnLoop.TextColor3 = Color3.fromRGB(160,165,180)

local bbCoverSize = isMobile and 70 or 130
local bbCover = Instance.new("Frame", bbPagePlay)
bbCover.Size = UDim2.new(0, bbCoverSize, 0, bbCoverSize)
bbCover.Position = UDim2.new(0.5, -bbCoverSize/2, 0, isMobile and 6 or 10)
bbCover.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
Instance.new("UICorner", bbCover).CornerRadius = UDim.new(1,0)
local bbCoverGrad = Instance.new("UIGradient", bbCover)
bbCoverGrad.Color = ColorSequence.new(Color3.fromRGB(130,100,255), Color3.fromRGB(70,160,255))

local bbCoverLabel = Instance.new("TextLabel", bbCover)
bbCoverLabel.Size = UDim2.new(1,0,1,0)
bbCoverLabel.BackgroundTransparency = 1
bbCoverLabel.Text = "♪"
bbCoverLabel.Font = Enum.Font.GothamBlack
bbCoverLabel.TextSize = isMobile and 32 or 48
bbCoverLabel.TextColor3 = Color3.new(1,1,1)

local bbLblSong = Instance.new("TextLabel", bbPagePlay)
bbLblSong.Text = "Aucun son"
bbLblSong.Font = Enum.Font.GothamBold
bbLblSong.TextSize = isMobile and 16 or 20
bbLblSong.TextColor3 = Color3.new(1,1,1)
bbLblSong.BackgroundTransparency = 1
bbLblSong.Position = UDim2.new(0, 14, 0, isMobile and 84 or 148)
bbLblSong.Size = UDim2.new(1, -28, 0, 20)
bbLblSong.TextXAlignment = Enum.TextXAlignment.Left
bbLblSong.TextTruncate = Enum.TextTruncate.AtEnd

local bbLblArtist = Instance.new("TextLabel", bbPagePlay)
bbLblArtist.Text = "Browse pour chercher"
bbLblArtist.Font = Enum.Font.Gotham
bbLblArtist.TextSize = 13
bbLblArtist.TextColor3 = Color3.fromRGB(170,175,185)
bbLblArtist.BackgroundTransparency = 1
bbLblArtist.Position = UDim2.new(0, 14, 0, isMobile and 104 or 172)
bbLblArtist.Size = UDim2.new(1, -80, 0, 16)
bbLblArtist.TextXAlignment = Enum.TextXAlignment.Left

local bbLblTime = Instance.new("TextLabel", bbPagePlay)
bbLblTime.Text = "-0:00"
bbLblTime.Font = Enum.Font.GothamMedium
bbLblTime.TextSize = 12
bbLblTime.TextColor3 = Color3.fromRGB(180,185,195)
bbLblTime.BackgroundTransparency = 1
bbLblTime.Position = UDim2.new(1, -50, 0, isMobile and 104 or 172)
bbLblTime.Size = UDim2.new(0, 40, 0, 16)
bbLblTime.TextXAlignment = Enum.TextXAlignment.Right

-- Progress Bar
local bbBarBack = Instance.new("Frame", bbPagePlay)
bbBarBack.Size = UDim2.new(1, -28, 0, 5)
bbBarBack.Position = UDim2.new(0, 14, 0, isMobile and 124 or 196)
bbBarBack.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
bbBarBack.BorderSizePixel = 0
Instance.new("UICorner", bbBarBack).CornerRadius = UDim.new(1,0)

local bbBarFill = Instance.new("Frame", bbBarBack)
bbBarFill.Size = UDim2.new(0,0,1,0)
bbBarFill.BackgroundColor3 = Color3.new(1,1,1)
bbBarFill.BorderSizePixel = 0
Instance.new("UICorner", bbBarFill).CornerRadius = UDim.new(1,0)
local bbBarGrad = Instance.new("UIGradient", bbBarFill)
bbBarGrad.Color = ColorSequence.new(Color3.fromRGB(120,110,255), Color3.fromRGB(255,110,180))

local bbPlaySize = isMobile and 50 or 68
local bbBtnPlay = Instance.new("TextButton", bbPagePlay)
bbBtnPlay.Text = "▶"
bbBtnPlay.Font = Enum.Font.GothamBlack
bbBtnPlay.TextSize = isMobile and 22 or 28
bbBtnPlay.Size = UDim2.new(0, bbPlaySize, 0, bbPlaySize)
bbBtnPlay.Position = UDim2.new(0.5, -bbPlaySize/2, 0, isMobile and 138 or 218)
bbBtnPlay.BackgroundColor3 = Color3.fromRGB(45, 48, 68)
bbBtnPlay.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", bbBtnPlay).CornerRadius = UDim.new(1,0)

-- Navigation Bottom
local bbNavH = isMobile and 48 or 60
local bbNav = Instance.new("Frame", boomboxFrame)
bbNav.Size = UDim2.new(1, -16, 0, bbNavH)
bbNav.Position = UDim2.new(0, 8, 1, -bbNavH - 6)
bbNav.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
bbNav.BorderSizePixel = 0
Instance.new("UICorner", bbNav).CornerRadius = UDim.new(0, 14)

local function bbMakeNav(text, iconStr, xPos)
    local b = Instance.new("TextButton", bbNav)
    b.Size = UDim2.new(0.333, 0, 1, 0)
    b.Position = UDim2.new(xPos, 0, 0, 0)
    b.BackgroundTransparency = 1
    b.Text = iconStr.."\n"..text
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(130,135,150)
    b.TextYAlignment = Enum.TextYAlignment.Center
    return b
end

local bbNavBrowse = bbMakeNav("Browse", "◫", 0)
local bbNavPlay = bbMakeNav("Play", "▶", 0.333)
local bbNavFavs = bbMakeNav("Favorites", "♥", 0.666)
bbNavBrowse.TextColor3 = Color3.new(1,1,1)

local bbCurrentTab = 1
local function bbSwitchPage(index)
    bbCurrentTab = index
    local target = UDim2.new(-(index-1), 0, 0, 0)
    TweenService:Create(bbPageBrowse, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Position = target}):Play()
    TweenService:Create(bbPagePlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Position = target + UDim2.new(1,0,0,0)}):Play()
    TweenService:Create(bbPageFavs, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Position = target + UDim2.new(2,0,0,0)}):Play()
    bbNavBrowse.TextColor3 = index==1 and Color3.new(1,1,1) or Color3.fromRGB(130,135,150)
    bbNavPlay.TextColor3 = index==2 and Color3.new(1,1,1) or Color3.fromRGB(130,135,150)
    bbNavFavs.TextColor3 = index==3 and Color3.fromRGB(255,110,180) or Color3.fromRGB(130,135,150)
end

bbNavBrowse.MouseButton1Click:Connect(function() bbSwitchPage(1) end)
bbNavPlay.MouseButton1Click:Connect(function() bbSwitchPage(2) end)
bbNavFavs.MouseButton1Click:Connect(function() bbSwitchPage(3) end)

local bbCurrentSong = nil

local function bbFormatTime(s)
    s = math.floor(s)
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

local function bbCreateItem(parent, id, name, creator)
    local item = Instance.new("TextButton")
    item.Size = UDim2.new(1, -10, 0, isMobile and 50 or 60)
    item.Position = UDim2.new(0, 5, 0, 0)
    item.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    item.AutoButtonColor = false
    item.Text = ""
    item.Parent = parent
    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 10)

    local itemTitle = Instance.new("TextLabel", item)
    itemTitle.Text = name
    itemTitle.Font = Enum.Font.GothamBold
    itemTitle.TextSize = 15
    itemTitle.TextColor3 = Color3.new(1,1,1)
    itemTitle.BackgroundTransparency = 1
    itemTitle.Position = UDim2.new(0, 10, 0, 6)
    itemTitle.Size = UDim2.new(1, -44, 0, 18)
    itemTitle.TextXAlignment = Enum.TextXAlignment.Left
    itemTitle.TextTruncate = Enum.TextTruncate.AtEnd

    local sub = Instance.new("TextLabel", item)
    sub.Text = "@"..creator
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextColor3 = Color3.fromRGB(160,165,175)
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0, 10, 0, 26)
    sub.Size = UDim2.new(1, -44, 0, 16)
    sub.TextXAlignment = Enum.TextXAlignment.Left

    local heart = Instance.new("TextLabel", item)
    heart.Text = favorites[tostring(id)] and "♥" or "♡"
    heart.Font = Enum.Font.GothamBold
    heart.TextSize = 18
    heart.TextColor3 = Color3.fromRGB(255,110,180)
    heart.BackgroundTransparency = 1
    heart.Size = UDim2.new(0, 20, 0, 20)
    heart.Position = UDim2.new(1, -30, 0.5, -10)

    item.MouseEnter:Connect(function()
        TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(38,40,52)}):Play()
    end)
    item.MouseLeave:Connect(function()
        TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28,30,40)}):Play()
    end)

    item.MouseButton1Click:Connect(function()
        bbCurrentSong = {id=id, name=name, creator=creator}
        sound.SoundId = "rbxassetid://"..id
        sound:Play()
        bbBtnPlay.Text = "⏸"
        bbLblSong.Text = name
        bbLblArtist.Text = "@"..creator
        bbCoverLabel.Text = string.sub(name,1,1):upper()
        bbBtnHeart.Text = favorites[tostring(id)] and "♥" or "♡"
        bbBtnHeart.TextColor3 = favorites[tostring(id)] and Color3.fromRGB(255,110,180) or Color3.fromRGB(200,200,210)
        bbSwitchPage(2)
    end)

    return item
end

bbSearchBox.FocusLost:Connect(function(enter)
    if not enter then return end
    local id = tonumber(bbSearchBox.Text:match("%d+"))
    if not id then return end
    local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Asset)
    if success and info and info.AssetTypeId == 3 then
        bbCreateItem(bbScrollList, id, info.Name, info.Creator.Name)
        bbSearchBox.Text = ""
    else
        bbSearchBox.Text = "ID invalide"
        task.wait(1)
        bbSearchBox.Text = ""
    end
end)

bbBtnPlay.MouseButton1Click:Connect(function()
    if sound.IsPlaying then
        sound:Pause()
        bbBtnPlay.Text = "▶"
    else
        sound:Resume()
        bbBtnPlay.Text = "⏸"
    end
end)

bbBtnHeart.MouseButton1Click:Connect(function()
    if not bbCurrentSong then return end
    local id = tostring(bbCurrentSong.id)
    if favorites[id] then
        favorites[id] = nil
        bbBtnHeart.Text = "♡"
        bbBtnHeart.TextColor3 = Color3.fromRGB(200,200,210)
    else
        favorites[id] = {name=bbCurrentSong.name, creator=bbCurrentSong.creator}
        bbBtnHeart.Text = "♥"
        bbBtnHeart.TextColor3 = Color3.fromRGB(255,110,180)
    end
    saveFavs()
end)

bbBtnLoop.MouseButton1Click:Connect(function()
    sound.Looped = not sound.Looped
    bbBtnLoop.TextColor3 = sound.Looped and Color3.fromRGB(120,140,255) or Color3.fromRGB(160,165,180)
end)

RunService.Heartbeat:Connect(function()
    if sound.IsLoaded and sound.TimeLength > 0 then
        local progress = sound.TimePosition / sound.TimeLength
        bbBarFill.Size = UDim2.new(math.clamp(progress,0,1), 0, 1, 0)
        bbLblTime.Text = "-"..bbFormatTime(sound.TimeLength - sound.TimePosition)
    end
end)

local bbIsMinimized = false
bbMinBtn.MouseButton1Click:Connect(function()
    bbIsMinimized = not bbIsMinimized
    local targetHeight = bbIsMinimized and 60 or (isMobile and 280 or 600)
    TweenService:Create(boomboxFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(boomboxFrame.Size.X.Scale, boomboxFrame.Size.X.Offset, 0, targetHeight)}):Play()
    bbPages.Visible = not bbIsMinimized
    bbNav.Visible = not bbIsMinimized
end)

local bbFavLayout = Instance.new("UIListLayout", bbPageFavs)
bbFavLayout.Padding = UDim.new(0,6)
bbFavLayout.SortOrder = Enum.SortOrder.LayoutOrder
bbFavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    bbPageFavs.CanvasSize = UDim2.new(0,0,0, bbFavLayout.AbsoluteContentSize.Y + 10)
end)

bbNavFavs.MouseButton1Click:Connect(function()
    bbPageFavs:ClearAllChildren()
    local layoutRef = Instance.new("UIListLayout", bbPageFavs)
    layoutRef.Padding = UDim.new(0,6)
    for id, data in pairs(favorites) do
        bbCreateItem(bbPageFavs, tonumber(id), data.name, data.creator)
    end
end)

bbCreateItem(bbScrollList, 1837657613, "HR - WASSA", "Clippsly")
bbCreateItem(bbScrollList, 9043887097, "FEMININO DO VAPO FUNK", "DistrokidOfficial")
bbCreateItem(bbScrollList, 8422288236, "have", "4jayxx")

bbSwitchPage(1)

-- --- ATTACHEMENT DU BOUTON BOOMBOX DANS LE PANEL DE CONTROLE ---
addToggle("14. 🎵 BOOMBOX RELICSxyz ▼", function(active)
    boomboxFrame.Visible = active
    if active then
        bbSwitchPage(1)
    end
end)


-- --- ESP ENTITÉS (AJOUT INDÉPENDANT, SANS MODIFIER L'ESP JOUEURS) ---
local entityESPObjects = {}
local entityESPScanConnection = nil
local entityESPAddedConnection = nil
local entityESPRemovingConnection = nil

local function isEntityModel(model)
    if not model or not model:IsA("Model") then
        return false
    end

    -- Ne pas afficher l'ESP sur les personnages des joueurs.
    if Players:GetPlayerFromCharacter(model) then
        return false
    end

    -- Critères d'identification : attribut explicite ou structure courante d'entité/NPC.
    return model:GetAttribute("IsEntity") == true
        or model:FindFirstChild("Entity") ~= nil
        or model:FindFirstChildOfClass("Humanoid") ~= nil
        or model:FindFirstChild("HumanoidRootPart") ~= nil
end

local function removeEntityESP(model)
    local data = entityESPObjects[model]
    if not data then
        return
    end

    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    entityESPObjects[model] = nil
end

local function createEntityESP(model)
    if not states.entitiesESP or entityESPObjects[model] or not isEntityModel(model) then
        return
    end

    local adornee = model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
        or model:FindFirstChildWhichIsA("BasePart", true)

    if not adornee then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "AdminEntityESP_Highlight"
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(255, 45, 45)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = screenGui

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AdminEntityESP_Info"
    billboard.Adornee = adornee
    billboard.Size = UDim2.fromOffset(180, 42)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 10000
    billboard.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Name = "Info"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 70, 70)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = model.Name
    label.Parent = billboard

    entityESPObjects[model] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
    }
end

local function scanEntityInstance(instance)
    if instance:IsA("Model") then
        createEntityESP(instance)
    elseif instance:IsA("BasePart") or instance:IsA("Humanoid")
        or instance.Name == "HumanoidRootPart" or instance.Name == "Entity"
        or instance:GetAttribute("IsEntity") == true then
        local model = instance:FindFirstAncestorOfClass("Model")
        if model then
            task.defer(function()
                if states.entitiesESP and model.Parent then
                    createEntityESP(model)
                end
            end)
        end
    end
end

local function setEntitiesESP(active)
    states.entitiesESP = active

    if entityESPAddedConnection then
        entityESPAddedConnection:Disconnect()
        entityESPAddedConnection = nil
    end
    if entityESPRemovingConnection then
        entityESPRemovingConnection:Disconnect()
        entityESPRemovingConnection = nil
    end
    if entityESPScanConnection then
        entityESPScanConnection:Disconnect()
        entityESPScanConnection = nil
    end

    if not active then
        for model in pairs(entityESPObjects) do
            removeEntityESP(model)
        end
        return
    end

    -- Scanner les entités déjà présentes.
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if instance:IsA("Model") then
            createEntityESP(instance)
        end
    end

    -- Détecter les entités ajoutées après l'activation.
    entityESPAddedConnection = Workspace.DescendantAdded:Connect(scanEntityInstance)

    entityESPRemovingConnection = Workspace.DescendantRemoving:Connect(function(instance)
        if instance:IsA("Model") then
            removeEntityESP(instance)
        end
    end)

    -- Mettre à jour les distances sans créer de connexion en double.
    entityESPScanConnection = RunService.RenderStepped:Connect(function()
        if not states.entitiesESP then return end

        local root = getRoot()
        for model, data in pairs(entityESPObjects) do
            if not model.Parent then
                removeEntityESP(model)
            elseif root and data.billboard and data.billboard.Adornee
                and data.billboard.Adornee:IsA("BasePart") then
                local distance = (root.Position - data.billboard.Adornee.Position).Magnitude
                data.label.Text = string.format("%s\n%d studs", model.Name, math.floor(distance))
                data.billboard.Enabled = distance <= 10000
            end
        end
    end)
end


addToggle("15. 🔴 ESP Entités", setEntitiesESP)

-- Arrêt complet : désactive les effets connus, restaure les valeurs visuelles et détruit le GUI.
local scriptClosed = false
local function closeAdminPanelPermanently()
    if scriptClosed then return end
    scriptClosed = true

    -- Désactive les boucles avant de détruire l'interface.
    for key in pairs(states) do states[key] = false end
    stopXRay()
    setEntitiesESP(false)

    for name, connection in pairs(connections) do
        if connection then pcall(function() connection:Disconnect() end) end
        connections[name] = nil
    end
    if xrayConnection then pcall(function() xrayConnection:Disconnect() end); xrayConnection = nil end

    -- Supprime les marqueurs ESP des joueurs.
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if instance.Name == "ESP_MARK" then pcall(function() instance:Destroy() end) end
    end

    -- Supprime les forces de vol créées par ce script.
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end

    -- Restaure les valeurs par défaut que ce panel modifie.
    local character = player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            camera.CameraSubject = humanoid
        end
    end
    pcall(function()
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.Brightness = 1
        player.CameraMaxZoomDistance = 400
        player.CameraMinZoomDistance = 0.5
    end)

    pcall(function() sound:Stop(); sound:Destroy() end)
    activeDrag = nil
    screenGui:Destroy()
end

confirmCloseBtn.MouseButton1Click:Connect(closeAdminPanelPermanently)

-- --- NOTIFICATION DE LANCEMENT ---
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "ADMIN v8.0", 
    Text = "Panel & Boombox RELICS chargés ! Touche [G] pour réduire le menu.", 
    Duration = 5,
    Icon = "rbxassetid://1087851214"
})
