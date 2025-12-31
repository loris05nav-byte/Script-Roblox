--[[ 
    ULTIMATE ADMIN PANEL v5.5 (MOBILE RESIZED)
    
    Modifications:
    - GUI Redimensionné pour mobile (plus petit)
    - Bouton "MENU" ajouté pour ouvrir/fermer (car pas de clavier)
    - TOUTES les fonctionnalités (Aimbot, ESP, etc.) sont conservées à 100%
]]

-- --- SERVICES ESSENTIELS ---
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- --- VARIABLES GLOBALES & ÉTATS ---
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

-- État des fonctionnalités
local states = {
    noclip = false,
    godmode = false,
    dash = false,
    fly = false,
    esp = false,
    infjump = false,
    infzoom = false,
    xray = false,
    aimbot = false -- Utilisé pour l'Auto-Lock
}

-- Variable pour le clic droit (Simulation mobile plus tard si besoin)
local isRightClickHeld = false

-- Connexions de boucles actives
local connections = {}
local espObjects = {}
local xrayOriginals = {}

-- Variables pour le fly
local flyBodyVelocity = nil
local flyBodyGyro = nil

-- --- UTILS & GETTERS ---
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChild("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- --- CONFIGURATION VISUELLE DU GUI ---
local GUI_THEME = {
    Background = Color3.fromRGB(15, 15, 20),
    BackgroundGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    }),
    Header = Color3.fromRGB(25, 25, 35),
    ButtonOff = Color3.fromRGB(35, 35, 45),
    ButtonOn = Color3.fromRGB(0, 200, 255),
    ButtonHover = Color3.fromRGB(45, 45, 60),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 200),
    Accent = Color3.fromRGB(0, 200, 255),
    AccentGlow = Color3.fromRGB(0, 150, 200)
}

-- --- INITIALISATION DU GUI ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UltimateAdminGUI_Mobile"
screenGui.ResetOnSpawn = false 
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- >> AJOUT SPÉCIAL MOBILE : BOUTON D'OUVERTURE <<
local mobileToggleBtn = Instance.new("TextButton")
mobileToggleBtn.Name = "MobileMenuBtn"
mobileToggleBtn.Size = UDim2.new(0, 50, 0, 50)
mobileToggleBtn.Position = UDim2.new(0, 10, 0.5, -25) -- À gauche au milieu
mobileToggleBtn.BackgroundColor3 = GUI_THEME.Accent
mobileToggleBtn.Text = "MENU"
mobileToggleBtn.TextColor3 = Color3.new(1,1,1)
mobileToggleBtn.Font = Enum.Font.GothamBold
mobileToggleBtn.TextSize = 12
mobileToggleBtn.Parent = screenGui
Instance.new("UICorner", mobileToggleBtn).CornerRadius = UDim.new(1, 0) -- Rond

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
-- >> MODIFICATION TAILLE : Plus petit pour mobile <<
mainFrame.Size = UDim2.new(0, 260, 0, 350) 
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -175)
mainFrame.BackgroundColor3 = GUI_THEME.Background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false -- Caché au début, on ouvre avec le bouton
mainFrame.Parent = screenGui

mobileToggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Gradient d'arrière-plan futuriste
local bgGradient = Instance.new("UIGradient", mainFrame)
bgGradient.Color = GUI_THEME.BackgroundGradient
bgGradient.Rotation = 45

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)

-- Bordure lumineuse animée
local glowStroke = Instance.new("UIStroke", mainFrame)
glowStroke.Color = GUI_THEME.Accent
glowStroke.Thickness = 2
glowStroke.Transparency = 0.3

-- Animation de la bordure
task.spawn(function()
    while task.wait(2) do
        TweenService:Create(glowStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Transparency = 0.7
        }):Play()
    end
end)

-- Header & Title
local header = Instance.new("Frame", mainFrame)
header.Name = "Header"
-- >> MODIFICATION TAILLE HEADER <<
header.Size = UDim2.new(1, 0, 0, 45) -- Réduit de 60 à 45
header.BackgroundColor3 = GUI_THEME.Header
header.BorderSizePixel = 0

local headerGradient = Instance.new("UIGradient", header)
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
})
headerGradient.Rotation = 90

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 15)

-- Ligne de séparation lumineuse
local headerLine = Instance.new("Frame", header)
headerLine.Name = "HeaderLine"
headerLine.Size = UDim2.new(1, -30, 0, 2)
headerLine.Position = UDim2.new(0, 15, 1, -2)
headerLine.BackgroundColor3 = GUI_THEME.Accent
headerLine.BorderSizePixel = 0

local lineGradient = Instance.new("UIGradient", headerLine)
lineGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
})

-- Icône futuriste
local iconLabel = Instance.new("TextLabel", header)
iconLabel.Text = "⚡"
iconLabel.Font = Enum.Font.GothamBold
iconLabel.TextSize = 20 -- Réduit
iconLabel.TextColor3 = GUI_THEME.Accent
iconLabel.Size = UDim2.new(0, 30, 0, 30)
iconLabel.Position = UDim2.new(0, 10, 0, 7)
iconLabel.BackgroundTransparency = 1

-- Animation de l'icône
task.spawn(function()
    while task.wait(1) do
        TweenService:Create(iconLabel, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            TextColor3 = Color3.fromRGB(100, 255, 255)
        }):Play()
    end
end)

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Text = "ULTIMATE ADMIN"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14 -- Réduit
titleLabel.TextColor3 = GUI_THEME.Text
titleLabel.Size = UDim2.new(1, -100, 0, 20)
titleLabel.Position = UDim2.new(0, 45, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local versionLabel = Instance.new("TextLabel", header)
versionLabel.Text = "v5.5 | MOBILE"
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextSize = 10 -- Réduit
versionLabel.TextColor3 = GUI_THEME.TextSecondary
versionLabel.Size = UDim2.new(1, -100, 0, 15)
versionLabel.Position = UDim2.new(0, 45, 0, 22)
versionLabel.BackgroundTransparency = 1
versionLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Bouton de réduction (minimize)
local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Text = "─"
minimizeBtn.Size = UDim2.new(0, 30, 0, 30) -- Réduit
minimizeBtn.Position = UDim2.new(1, -70, 0, 8)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
minimizeBtn.TextColor3 = GUI_THEME.Accent
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.AutoButtonColor = false

Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

local minStroke = Instance.new("UIStroke", minimizeBtn)
minStroke.Color = GUI_THEME.Accent
minStroke.Thickness = 1
minStroke.Transparency = 0.7

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    -- Mises à jour des tailles cibles pour mobile
    local targetSize = isMinimized and UDim2.new(0, 260, 0, 45) or UDim2.new(0, 260, 0, 350)
    local targetText = isMinimized and "+" or "─"
    
    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = targetSize
    }):Play()
    
    minimizeBtn.Text = targetText
end)

-- Popup de confirmation
local confirmPopup = Instance.new("Frame")
confirmPopup.Name = "ConfirmPopup"
confirmPopup.Size = UDim2.new(0, 240, 0, 150) -- Plus petit
confirmPopup.Position = UDim2.new(0.5, -120, 0.5, -75)
confirmPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
confirmPopup.BorderSizePixel = 0
confirmPopup.Visible = false
confirmPopup.ZIndex = 100
confirmPopup.Parent = screenGui

Instance.new("UICorner", confirmPopup).CornerRadius = UDim.new(0, 15)

local popupGradient = Instance.new("UIGradient", confirmPopup)
popupGradient.Color = GUI_THEME.BackgroundGradient
popupGradient.Rotation = 45

local popupStroke = Instance.new("UIStroke", confirmPopup)
popupStroke.Color = Color3.fromRGB(255, 100, 100)
popupStroke.Thickness = 3

-- Titre du popup
local popupTitle = Instance.new("TextLabel", confirmPopup)
popupTitle.Text = "⚠️ CONFIRMATION"
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextSize = 16
popupTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
popupTitle.Size = UDim2.new(1, -20, 0, 30)
popupTitle.Position = UDim2.new(0, 10, 0, 10)
popupTitle.BackgroundTransparency = 1
popupTitle.TextXAlignment = Enum.TextXAlignment.Center

-- Message du popup
local popupMessage = Instance.new("TextLabel", confirmPopup)
popupMessage.Text = "Fermer ?\nLes effets seront désactivés."
popupMessage.Font = Enum.Font.Gotham
popupMessage.TextSize = 12
popupMessage.TextColor3 = GUI_THEME.Text
popupMessage.Size = UDim2.new(1, -20, 0, 40)
popupMessage.Position = UDim2.new(0, 10, 0, 45)
popupMessage.BackgroundTransparency = 1
popupMessage.TextWrapped = true
popupMessage.TextXAlignment = Enum.TextXAlignment.Center

-- Container pour les boutons
local buttonContainer = Instance.new("Frame", confirmPopup)
buttonContainer.Size = UDim2.new(1, -30, 0, 40)
buttonContainer.Position = UDim2.new(0, 15, 0, 95)
buttonContainer.BackgroundTransparency = 1

-- Bouton OUI (Confirmer)
local confirmYesBtn = Instance.new("TextButton", buttonContainer)
confirmYesBtn.Text = "✓ OUI"
confirmYesBtn.Size = UDim2.new(0.48, 0, 1, 0)
confirmYesBtn.Position = UDim2.new(0, 0, 0, 0)
confirmYesBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
confirmYesBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
confirmYesBtn.Font = Enum.Font.GothamBold
confirmYesBtn.TextSize = 14
confirmYesBtn.AutoButtonColor = false

Instance.new("UICorner", confirmYesBtn).CornerRadius = UDim.new(0, 10)

local yesStroke = Instance.new("UIStroke", confirmYesBtn)
yesStroke.Color = Color3.fromRGB(255, 100, 100)
yesStroke.Thickness = 2

-- Bouton NON (Annuler)
local confirmNoBtn = Instance.new("TextButton", buttonContainer)
confirmNoBtn.Text = "✕ NON"
confirmNoBtn.Size = UDim2.new(0.48, 0, 1, 0)
confirmNoBtn.Position = UDim2.new(0.52, 0, 0, 0)
confirmNoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
confirmNoBtn.TextColor3 = GUI_THEME.Accent
confirmNoBtn.Font = Enum.Font.GothamBold
confirmNoBtn.TextSize = 14
confirmNoBtn.AutoButtonColor = false

Instance.new("UICorner", confirmNoBtn).CornerRadius = UDim.new(0, 10)

local noStroke = Instance.new("UIStroke", confirmNoBtn)
noStroke.Color = GUI_THEME.Accent
noStroke.Thickness = 2

-- Bouton de fermeture
local closeBtn = Instance.new("TextButton", header)
closeBtn.Name = "CloseBtn"
closeBtn.Text = "✕"
closeBtn.Size = UDim2.new(0, 30, 0, 30) -- Réduit
closeBtn.Position = UDim2.new(1, -35, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.AutoButtonColor = false

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Color = Color3.fromRGB(255, 100, 100)
closeStroke.Thickness = 1
closeStroke.Transparency = 0.7

-- Scrolling Container
local scrollContainer = Instance.new("ScrollingFrame", mainFrame)
scrollContainer.Name = "ScrollContainer"
scrollContainer.Size = UDim2.new(1, -10, 1, -55) -- Ajusté
scrollContainer.Position = UDim2.new(0, 5, 0, 50)
scrollContainer.BackgroundTransparency = 1
scrollContainer.ScrollBarThickness = 4
scrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollContainer.ScrollBarImageColor3 = GUI_THEME.Accent
scrollContainer.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", scrollContainer)
layout.Padding = UDim.new(0, 5) -- Espacement réduit
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- --- LOGIQUE DE DÉPLACEMENT (DRAG) ---
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
header.InputChanged:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
        dragInput = input 
    end 
end)
UserInputService.InputChanged:Connect(function(input) 
    if input == dragInput and dragging then 
        update(input) 
    end 
end)

-- --- FABRIQUE DE BOUTONS ---
local function createToggle(name, callback)
    local btnFrame = Instance.new("TextButton")
    btnFrame.Name = name
    -- >> MODIFICATION TAILLE BOUTONS : Moins haut <<
    btnFrame.Size = UDim2.new(1, -5, 0, 35) -- Réduit de 55 à 35
    btnFrame.BackgroundColor3 = GUI_THEME.ButtonOff
    btnFrame.Text = ""
    btnFrame.AutoButtonColor = false
    btnFrame.Parent = scrollContainer
    
    Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 10)
    
    local btnStroke = Instance.new("UIStroke", btnFrame)
    btnStroke.Color = Color3.fromRGB(50, 50, 70)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.6
    
    local btnGradient = Instance.new("UIGradient", btnFrame)
    btnGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 40))
    })
    btnGradient.Rotation = 90
    
    local contentFrame = Instance.new("Frame", btnFrame)
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", contentFrame)
    label.Text = name
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = GUI_THEME.Text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12 -- Réduit
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    
    local toggleContainer = Instance.new("Frame", contentFrame)
    toggleContainer.Size = UDim2.new(0, 40, 0, 20) -- Plus petit
    toggleContainer.Position = UDim2.new(1, -45, 0.5, -10)
    toggleContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    Instance.new("UICorner", toggleContainer).CornerRadius = UDim.new(1, 0)
    
    local toggleStroke = Instance.new("UIStroke", toggleContainer)
    toggleStroke.Color = Color3.fromRGB(70, 70, 90)
    toggleStroke.Thickness = 2
    toggleStroke.Transparency = 0.5
    
    local indicator = Instance.new("Frame", toggleContainer)
    indicator.Size = UDim2.new(0, 16, 0, 16) -- Plus petit
    indicator.Position = UDim2.new(0, 2, 0.5, -8)
    indicator.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    local indicatorStroke = Instance.new("UIStroke", indicator)
    indicatorStroke.Color = Color3.fromRGB(100, 100, 110)
    indicatorStroke.Thickness = 2

    local isActive = false
    
    btnFrame.MouseButton1Click:Connect(function()
        isActive = not isActive
        
        local targetBgColor = isActive and GUI_THEME.ButtonOn or GUI_THEME.ButtonOff
        local targetStrokeColor = isActive and GUI_THEME.Accent or Color3.fromRGB(50, 50, 70)
        
        TweenService:Create(btnFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundColor3 = targetBgColor}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.3), {Color = targetStrokeColor, Transparency = isActive and 0.2 or 0.6}):Play()
        TweenService:Create(label, TweenInfo.new(0.3), {TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or GUI_THEME.Text}):Play()
        
        local targetToggleColor = isActive and GUI_THEME.Accent or Color3.fromRGB(50, 50, 60)
        local targetIndicatorPos = isActive and UDim2.new(0, 22, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local targetIndicatorColor = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
        
        TweenService:Create(toggleContainer, TweenInfo.new(0.3), {BackgroundColor3 = targetToggleColor}):Play()
        TweenService:Create(toggleStroke, TweenInfo.new(0.3), {Color = isActive and GUI_THEME.Accent or Color3.fromRGB(70, 70, 90)}):Play()
        TweenService:Create(indicator, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = targetIndicatorPos,
            BackgroundColor3 = targetIndicatorColor
        }):Play()
        TweenService:Create(indicatorStroke, TweenInfo.new(0.3), {Color = isActive and Color3.fromRGB(200, 200, 255) or Color3.fromRGB(100, 100, 110)}):Play()
        
        task.spawn(function() callback(isActive) end)
    end)
end

-- --- FONCTION DE NETTOYAGE ESP ---
local function clearESP()
    for _, espData in pairs(espObjects) do
        if espData.billboard then espData.billboard:Destroy() end
        if espData.line then espData.line:Destroy() end
        if espData.connection then espData.connection:Disconnect() end
        if espData.deathConnection then espData.deathConnection:Disconnect() end
    end
    espObjects = {}
end

-- --- FONCTION POUR DÉSACTIVER TOUS LES EFFETS ---
local function disableAllEffects()
    states.noclip = false
    states.godmode = false
    states.dash = false
    states.fly = false
    states.esp = false
    states.infjump = false
    states.infzoom = false
    states.xray = false
    states.aimbot = false 
    
    for name, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    
    clearESP()
    
    local hum = getHum()
    local root = getRoot()
    local char = getChar()
    
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.UseJumpPower = true
        hum.PlatformStand = false
    end
    
    if root then
        root.Anchored = false
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    end
    
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                part.CanCollide = true
                part.Transparency = 0
            end
        end
    end
    
    Workspace.Gravity = 196.2
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.Brightness = 1

    player.CameraMaxZoomDistance = 400
    player.CameraMinZoomDistance = 0.5

    for obj, trans in pairs(xrayOriginals) do
        if obj then
            obj.Transparency = trans
        end
    end
    xrayOriginals = {}
    if connections["XRayAdded"] then connections["XRayAdded"]:Disconnect() end
end

-- Actions du popup
closeBtn.MouseButton1Click:Connect(function() 
    confirmPopup.Visible = true
    confirmPopup.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(confirmPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 240, 0, 150)
    }):Play()
end)

confirmYesBtn.MouseButton1Click:Connect(function()
    TweenService:Create(confirmPopup, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    task.wait(0.2)
    confirmPopup.Visible = false
    
    disableAllEffects()
    
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    task.wait(0.3)
    mainFrame.Visible = false
    mainFrame.Size = UDim2.new(0, 260, 0, 350)
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Admin Panel";
        Text = "Effets désactivés.";
        Duration = 3;
    })
end)

confirmNoBtn.MouseButton1Click:Connect(function()
    TweenService:Create(confirmPopup, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    task.wait(0.2)
    confirmPopup.Visible = false
end)

-- --- DASH (Clic Gauche) ---
createToggle("1. Dash Rapide", function(active)
    states.dash = active
end)

mouse.Button1Down:Connect(function()
    if not states.dash then return end
    
    local root = getRoot()
    if not root then return end
    
    local targetPosition = mouse.Hit.Position
    root.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
    root.Velocity = Vector3.zero
end)

-- --- ESP ---
local function getColorByDistance(distance)
    if distance < 50 then return Color3.fromRGB(0, 255, 0)
    elseif distance < 150 then return Color3.fromRGB(255, 255, 0)
    else return Color3.fromRGB(255, 0, 0) end
end

local function createESPForPlayer(targetPlayer)
    if targetPlayer == player then return end
    
    local espData = {
        player = targetPlayer,
        billboard = nil, line = nil, connection = nil, deathConnection = nil
    }
    
    local function cleanupESP()
        if espData.billboard then espData.billboard:Destroy() espData.billboard = nil end
        if espData.line then espData.line:Destroy() espData.line = nil end
        if espData.connection then espData.connection:Disconnect() espData.connection = nil end
        if espData.deathConnection then espData.deathConnection:Disconnect() espData.deathConnection = nil end
    end
    
    local function setupESP()
        cleanupESP()
        local char = targetPlayer.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not head or not rootPart or not humanoid then return end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 100, 0, 40) -- Taille réduite ESP
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        local frame = Instance.new("Frame", billboard)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 0.5
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

        local nameLabel = Instance.new("TextLabel", frame)
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = targetPlayer.Name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        
        local distLabel = Instance.new("TextLabel", frame)
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        distLabel.TextScaled = true
        
        espData.billboard = billboard
        
        local line = Instance.new("Part")
        line.Name = "ESP_Line"
        line.Anchored = true
        line.CanCollide = false
        line.Material = Enum.Material.Neon
        line.Size = Vector3.new(0.1, 0.1, 1)
        line.Parent = Workspace
        espData.line = line
        
        espData.deathConnection = humanoid.Died:Connect(function() cleanupESP() end)

        espData.connection = RunService.RenderStepped:Connect(function()
            if not states.esp or not char or not humanoid or humanoid.Health <= 0 then 
                if billboard then billboard.Enabled = false end
                if line then line.Transparency = 1 end
                return 
            end
            
            if billboard then billboard.Enabled = true end
            if line then line.Transparency = 0 end
            
            local myRoot = getRoot()
            local theirRoot = char:FindFirstChild("HumanoidRootPart")
            
            if myRoot and theirRoot then
                local distance = (myRoot.Position - theirRoot.Position).Magnitude
                local distColor = getColorByDistance(distance)
                
                frame.BackgroundColor3 = distColor
                distLabel.Text = string.format("%.0fm", distance)
                
                local midPoint = (myRoot.Position + theirRoot.Position) / 2
                local lineLength = (myRoot.Position - theirRoot.Position).Magnitude
                
                line.Size = Vector3.new(0.1, 0.1, lineLength)
                line.CFrame = CFrame.new(midPoint, theirRoot.Position)
                line.Color = distColor
            end
        end)
    end
    
    if targetPlayer.Character then setupESP() end
    targetPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if states.esp then setupESP() end
    end)
    espObjects[targetPlayer] = espData
end

createToggle("2. ESP Joueurs", function(active)
    states.esp = active
    if active then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then createESPForPlayer(p) end
        end
        connections["ESPPlayerAdded"] = Players.PlayerAdded:Connect(function(p)
            if states.esp then task.wait(1) createESPForPlayer(p) end
        end)
    else
        if connections["ESPPlayerAdded"] then connections["ESPPlayerAdded"]:Disconnect() end
        if connections["ESPPlayerRemoving"] then connections["ESPPlayerRemoving"]:Disconnect() end
        clearESP()
    end
end)

-- --- FLY ---
createToggle("3. Fly Mode", function(active)
    states.fly = active
    local root = getRoot()
    
    if active and root then
        flyBodyGyro = Instance.new("BodyGyro", root)
        flyBodyGyro.P = 9e4
        flyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.cframe = root.CFrame
        
        flyBodyVelocity = Instance.new("BodyVelocity", root)
        flyBodyVelocity.velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        
        connections["FlyLoop"] = RunService.RenderStepped:Connect(function()
            if not states.fly or not root then return end
            
            local speed = 50
            local camCF = camera.CFrame
            local moveDir = Vector3.zero
            
            -- Simulation de contrôle simple (avance tout droit si on touche l'écran)
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                 -- Sur mobile, on simplifie : on avance vers où on regarde si on touche l'écran
                 moveDir = moveDir + camCF.LookVector
            end
            
            flyBodyGyro.cframe = camCF
            flyBodyVelocity.velocity = moveDir * speed
        end)
    else
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if connections["FlyLoop"] then connections["FlyLoop"]:Disconnect() end
    end
end)

-- --- GODMODE ---
createToggle("4. God Mode", function(active)
    states.godmode = active
    local hum = getHum()
    if hum and active then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
        connections["GodLoop"] = RunService.Stepped:Connect(function()
            if hum then hum.Health = math.huge end
        end)
    else
        if connections["GodLoop"] then connections["GodLoop"]:Disconnect() end
        if hum then hum.MaxHealth = 100 hum.Health = 100 end
    end
end)

-- --- AIMBOT AUTO-LOCK ---
createToggle("5. Admin Auto-Lock", function(active)
    states.aimbot = active
    
    if active then
        connections["AimbotLoop"] = RunService.RenderStepped:Connect(function()
            if not states.aimbot then return end
            
            -- Activation : Clic Droit maintenu (Sur PC) OU Touche écran maintenue (Sur Mobile)
            local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) 
                             or UserInputService:GetMouseButtonsPressed()[1] -- Check si on touche l'écran
            
            if isAiming then
                local char = getChar()
                local root = getRoot()
                if not char or not root then return end

                local targetPart = nil
                local shortestDistance = math.huge
                local MAX_DISTANCE = 500

                -- 1. SCAN DES JOUEURS
                for _, otherPlayer in pairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local otherHead = otherPlayer.Character:FindFirstChild("Head")
                        local otherHum = otherPlayer.Character:FindFirstChild("Humanoid")
                        
                        if otherHead and otherHum and otherHum.Health > 0 then
                            local distance = (root.Position - otherHead.Position).Magnitude
                            if distance <= MAX_DISTANCE and distance < shortestDistance then
                                shortestDistance = distance
                                targetPart = otherHead
                            end
                        end
                    end
                end

                -- Verrouillage caméra
                if targetPart then
                    local targetCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
                    camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.5)
                end
            end
        end)
    else
        if connections["AimbotLoop"] then connections["AimbotLoop"]:Disconnect() end
    end
end)

-- --- AUTRES ---
createToggle("6. Vitesse Éclair", function(active)
    local hum = getHum()
    if hum then hum.WalkSpeed = active and 100 or 16 end
end)

createToggle("7. Saut Infini", function(active)
    states.infjump = active
    connections["InfJump"] = UserInputService.JumpRequest:Connect(function()
        if states.infjump then
            local hum = getHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    if not active and connections["InfJump"] then connections["InfJump"]:Disconnect() end
end)

createToggle("8. X-Ray (Murs)", function(active)
    states.xray = active
    if active then
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Parent:FindFirstChild("Humanoid") then
                xrayOriginals[part] = part.Transparency
                part.Transparency = 0.5
            end
        end
    else
        for part, trans in pairs(xrayOriginals) do
            if part then part.Transparency = trans end
        end
        xrayOriginals = {}
    end
end)

createToggle("9. Full Bright", function(active)
    if active then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.Brightness = 1
    end
end)
