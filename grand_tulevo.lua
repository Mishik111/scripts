-- // Глобальные настройки
local Settings = {
    Aimbot = false,
    AimSort = "Cursor", -- Варианты: Cursor, Distance, Health
    AimOnButton = false,
    TeamCheck = true,
    WallCheck = true,
    FOV = 150,
    ESPBox = false,
    ESPTracer = false,
    HitboxScale = 1,    -- От 1 до 5
    BrightnessMode = 1, -- Цикл режимов яркости
    WorldColorMode = 1  -- Цикл цветов мира
}

-- // Сервисы Roblox
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // Сохранение дефолтных настроек игры для корректного сброса
local DefaultBrightness = Lighting.Brightness
local DefaultAmbient = Lighting.Ambient

-- // Кэш для отрисовки линий (Tracers)
local CacheTracers = {}

-- // Создание FOV Круга
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Color = Color3.fromRGB(0, 255, 204)
    FOVCircle.Thickness = 1
    FOVCircle.Filled = false
    FOVCircle.Visible = false
end)

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end)

-- // Wall Check (Проверка препятствий)
local function IsVisible(targetPart)
    local Character = LocalPlayer.Character
    if not Character then return false end
    
    local Origin = Camera.CFrame.Position
    local Direction = (targetPart.Position - Origin).Unit * (targetPart.Position - Origin).Magnitude
    
    local RaycastParamsEx = RaycastParams.new()
    RaycastParamsEx.FilterDescendantsInstances = {Character, targetPart.Parent}
    RaycastParamsEx.FilterType = Enum.RaycastFilterType.Exclude
    
    local Result = workspace:Raycast(Origin, Direction, RaycastParamsEx)
    return Result == nil
end

-- // Функция умной сортировки целей для Aimbot
local function GetClosestPlayer()
    local ClosestTarget = nil
    local MinValue = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            if Settings.TeamCheck and player.Team == LocalPlayer.Team and LocalPlayer.Team ~= nil then continue end
            if Settings.WallCheck and not IsVisible(player.Character.Head) then continue end
            
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            
            if OnScreen then
                local MousePosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local MouseDist = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MousePosition).Magnitude
                
                if MouseDist < Settings.FOV then
                    -- Сортировка: Ближайший к прицелу (2D)
                    if Settings.AimSort == "Cursor" then
                        if MouseDist < MinValue then
                            MinValue = MouseDist
                            ClosestTarget = player
                        end
                    -- Сортировка: Ближайший по карте (3D расстояние)
                    elseif Settings.AimSort == "Distance" then
                        local Distance3D = (player.Character.Head.Position - Camera.CFrame.Position).Magnitude
                        if Distance3D < MinValue then
                            MinValue = Distance3D
                            ClosestTarget = player
                        end
                    -- Сортировка: Самый Лоу-ХП
                    elseif Settings.AimSort == "Health" then
                        local Health = player.Character.Humanoid.Health
                        if Health < MinValue then
                            MinValue = Health
                            ClosestTarget = player
                        end
                    end
                end
            end
        end
    end
    return ClosestTarget
end

-- // Логика зажатия кнопки для Aim On Button (ПКМ)
local IsAimButtonHeld = false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAimButtonHeld = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAimButtonHeld = false
    end
end)

-- // ГЛАВНЫЙ ИГРОВОЙ ЦИКЛ
RunService.RenderStepped:Connect(function()
    -- Обновление FOV
    if FOVCircle then
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Visible = Settings.Aimbot
    end
    
    -- Работа Аимбота
    if Settings.Aimbot then
        local CanAim = true
        if Settings.AimOnButton and not IsAimButtonHeld then
            CanAim = false
        end
        
        if CanAim then
            local Target = GetClosestPlayer()
            if Target and Target.Character and Target.Character:FindFirstChild("Head") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Character.Head.Position)
            end
        end
    end

    -- Обработка визуалов и хитбоксов для каждого игрока
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- 1. Элемент ESP Box (Highlight)
            local Highlight = player.Character:FindFirstChild("1337Highlight")
            if Settings.ESPBox then
                if not Highlight then
                    Highlight = Instance.new("Highlight")
                    Highlight.Name = "1337Highlight"
                    Highlight.Parent = player.Character
                    Highlight.FillTransparency = 0.6
                    Highlight.OutlineTransparency = 0
                end
                if player.Team == LocalPlayer.Team and LocalPlayer.Team ~= nil then
                    Highlight.FillColor = Color3.fromRGB(0, 255, 100)
                else
                    Highlight.FillColor = Color3.fromRGB(255, 50, 50)
                end
            else
                if Highlight then Highlight:Destroy() end
            end

            -- 2. Элемент ESP Tracer (Линии)
            if Settings.ESPTracer and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                if not CacheTracers[player] then
                    pcall(function()
                        local Line = Drawing.new("Line")
                        Line.Thickness = 1.5
                        Line.Transparency = 0.7
                        CacheTracers[player] = Line
                    end)
                end
                
                local Line = CacheTracers[player]
                if Line then
                    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                    if OnScreen then
                        Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Из низа экрана
                        Line.To = Vector2.new(ScreenPos.X, ScreenPos.Y)
                        if player.Team == LocalPlayer.Team and LocalPlayer.Team ~= nil then
                            Line.Color = Color3.fromRGB(0, 255, 100)
                        else
                            Line.Color = Color3.fromRGB(255, 50, 50)
                        end
                        Line.Visible = true
                    else
                        Line.Visible = false
                    end
                end
            else
                if CacheTracers[player] then CacheTracers[player].Visible = false end
            end

            -- 3. Hitbox Expander (Увеличение голов)
            if player.Character:FindFirstChild("Head") then
                local Head = player.Character.Head
                if Settings.HitboxScale > 1 then
                    Head.Size = Vector3.new(2 * Settings.HitboxScale, 2 * Settings.HitboxScale, 2 * Settings.HitboxScale)
                    Head.CanCollide = false
                    Head.Transparency = 0.5 -- Слегка прозрачные, чтобы видеть реальный размер
                else
                    Head.Size = Vector3.new(2, 2, 1) -- Дефолт
                    Head.Transparency = 0
                end
            end
        end
    end
end)

-- Очистка линий при выходе игроков
Players.PlayerRemoving:Connect(function(p)
    if CacheTracers[p] then
        CacheTracers[p]:Destroy()
        CacheTracers[p] = nil
    end
end)

-- ====================================================================
-- // ИНТЕРФЕЙС И АНИМАЦИИ
-- ====================================================================

if PlayerGui:FindFirstChild("Cheat1337GUI") then
    PlayerGui.Cheat1337GUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Cheat1337GUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- Функция скругления углов
local function ApplyCorner(obj, r)
    local C = Instance.new("UICorner") C.CornerRadius = UDim.new(0, r or 6) C.Parent = obj
end

-- Функция обводки
local function ApplyStroke(obj, col, t)
    local S = Instance.new("UIStroke") S.Color = col S.Thickness = t or 1.5 S.Parent = obj
end

-- --------------------------------------------------------------------
-- [АНИМАЦИЯ ЗАПУСКА / ИНТРО]
-- --------------------------------------------------------------------
local IntroFrame = Instance.new("Frame")
IntroFrame.Size = UDim2.new(0, 300, 0, 120)
IntroFrame.Position = UDim2.new(0.5, -150, 0.4, -60)
IntroFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
IntroFrame.BackgroundTransparency = 1
ApplyCorner(IntroFrame, 12)
ApplyStroke(IntroFrame, Color3.fromRGB(0, 255, 204), 2)
IntroFrame.UIStroke.Transparency = 1
IntroFrame.Parent = ScreenGui

local IntroTitle = Instance.new("TextLabel")
IntroTitle.Size = UDim2.new(1, 0, 0.5, 0)
IntroTitle.Text = "1337"
IntroTitle.Font = Enum.Font.GothamBold
IntroTitle.TextSize = 28
IntroTitle.TextColor3 = Color3.fromRGB(0, 255, 204)
IntroTitle.BackgroundTransparency = 1
IntroTitle.TextTransparency = 1
IntroTitle.Parent = IntroFrame

local IntroSub = Instance.new("TextLabel")
IntroSub.Size = UDim2.new(1, 0, 0.5, 0)
IntroSub.Position = UDim2.new(0, 0, 0.5, 0)
IntroSub.Text = "добро пожаловать"
IntroSub.Font = Enum.Font.Gotham
IntroSub.TextSize = 16
IntroSub.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroSub.BackgroundTransparency = 1
IntroSub.TextTransparency = 1
IntroSub.Parent = IntroFrame

-- Воспроизведение интро анимации
task.spawn(function()
    local TInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(IntroFrame, TInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(IntroFrame.UIStroke, TInfo, {Transparency = 0}):Play()
    TweenService:Create(IntroTitle, TInfo, {TextTransparency = 0}):Play()
    TweenService:Create(IntroSub, TInfo, {TextTransparency = 0}):Play()
    
    task.wait(2.2) -- Время показа
    
    local TFade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(IntroFrame, TFade, {BackgroundTransparency = 1}):Play()
    TweenService:Create(IntroFrame.UIStroke, TFade, {Transparency = 1}):Play()
    TweenService:Create(IntroTitle, TFade, {TextTransparency = 1}):Play()
    TweenService:Create(IntroSub, TFade, {TextTransparency = 1}):Play()
    
    task.wait(0.5)
    IntroFrame:Destroy()
end)

-- --------------------------------------------------------------------
-- [ГЛАВНОЕ МЕНЮ]
-- --------------------------------------------------------------------
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextButton") -- Сделано кнопкой для красивого сворачивания

MainFrame.Name = "MenuFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 27)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 520) -- Размер увеличен под новые функции
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.ClipsDescendants = true -- Критично для анимации закрытия!
ApplyCorner(MainFrame, 10)
ApplyStroke(MainFrame, Color3.fromRGB(0, 255, 204), 1.5)

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(32, 32, 35)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "1337"
Title.TextColor3 = Color3.fromRGB(0, 255, 204)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
ApplyCorner(Title, 10)

-- Отрисовка контейнера под кнопки (для удобной анимации)
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -45)
ContentContainer.Position = UDim2.new(0, 0, 0, 45)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Шаблон для стильных кнопок-переключателей
local function CreateButton(name, text, defaultState, yPos, callback)
    local Btn = Instance.new("TextButton")
    Btn.Name = name
    Btn.Parent = ContentContainer
    Btn.Position = UDim2.new(0.05, 0, 0, yPos)
    Btn.Size = UDim2.new(0.9, 0, 0, 28)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.BorderSizePixel = 0
    ApplyCorner(Btn, 6)
    
    local function updateVisual(state)
        if state then
            Btn.Text = text .. ": ON"
            Btn.BackgroundColor3 = Color3.fromRGB(0, 160, 100)
        else
            Btn.Text = text .. ": OFF"
            Btn.BackgroundColor3 = Color3.fromRGB(43, 43, 48)
        end
    end
    
    updateVisual(defaultState)
    Btn.MouseButton1Click:Connect(function()
        callback(Btn, updateVisual)
    end)
    return Btn
end

-- Отрисовка функционала
CreateButton("AimbotBtn", "Aimbot", Settings.Aimbot, 15, function(b, update)
    Settings.Aimbot = not Settings.Aimbot update(Settings.Aimbot)
end)

local SortBtn = CreateButton("SortBtn", "Aim Sort: Cursor", true, 50, function(b, update)
    if Settings.AimSort == "Cursor" then
        Settings.AimSort = "Distance" b.Text = "Aim Sort: Distance"
    elseif Settings.AimSort == "Distance" then
        Settings.AimSort = "Health" b.Text = "Aim Sort: Health"
    else
        Settings.AimSort = "Cursor" b.Text = "Aim Sort: Cursor"
    end
end) SortBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 120)

CreateButton("OnBtn", "Aim On Button (ПКМ)", Settings.AimOnButton, 85, function(b, update)
    Settings.AimOnButton = not Settings.AimOnButton update(Settings.AimOnButton)
end)

CreateButton("TeamBtn", "Team Check", Settings.TeamCheck, 120, function(b, update)
    Settings.TeamCheck = not Settings.TeamCheck update(Settings.TeamCheck)
end)

CreateButton("WallBtn", "Wall Check", Settings.WallCheck, 155, function(b, update)
    Settings.WallCheck = not Settings.WallCheck update(Settings.WallCheck)
end)

CreateButton("BoxBtn", "ESP Box", Settings.ESPBox, 195, function(b, update)
    Settings.ESPBox = not Settings.ESPBox update(Settings.ESPBox)
end)

CreateButton("TracerBtn", "ESP Tracer", Settings.ESPTracer, 230, function(b, update)
    Settings.ESPTracer = not Settings.ESPTracer update(Settings.ESPTracer)
    if not Settings.ESPTracer then
        for _, l in pairs(CacheTracers) do l.Visible = false end
    end
end)

-- Слайдер хитбоксов (кликер-слайдер)
local HitboxBtn = CreateButton("HitboxBtn", "Hitbox Expand: 1x", false, 270, function(b, update)
    Settings.HitboxScale = Settings.HitboxScale + 1
    if Settings.HitboxScale > 5 then Settings.HitboxScale = 1 end
    b.Text = "Hitbox Expand: " .. tostring(Settings.HitboxScale) .. "x"
    b.BackgroundColor3 = Settings.HitboxScale > 1 and Color3.fromRGB(130, 80, 20) or Color3.fromRGB(43, 43, 48)
end) HitboxBtn.Text = "Hitbox Expand: 1x"

-- Модификаторы мира
local BrightBtn = CreateButton("BrightBtn", "Brightness: Default", false, 310, function(b, update)
    Settings.BrightnessMode = Settings.BrightnessMode + 1
    if Settings.BrightnessMode > 3 then Settings.BrightnessMode = 1 end
    if Settings.BrightnessMode == 1 then Lighting.Brightness = DefaultBrightness b.Text = "Brightness: Default"
    elseif Settings.BrightnessMode == 2 then Lighting.Brightness = 6 b.Text = "Brightness: Medium"
    local FullBright = 12 elseif Settings.BrightnessMode == 3 then Lighting.Brightness = 15 b.Text = "Brightness: Max (Full)" end
end) BrightBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 90)

local ColorWorldBtn = CreateButton("ColorWorldBtn", "World Color: Default", false, 345, function(b, update)
    Settings.WorldColorMode = Settings.WorldColorMode + 1
    if Settings.WorldColorMode > 4 then Settings.WorldColorMode = 1 end
    if Settings.WorldColorMode == 1 then Lighting.Ambient = DefaultAmbient b.Text = "World Color: Default"
    elseif Settings.WorldColorMode == 2 then Lighting.Ambient = Color3.fromRGB(255, 50, 50) b.Text = "World Color: Cyber Red"
    elseif Settings.WorldColorMode == 3 then Lighting.Ambient = Color3.fromRGB(0, 255, 255) b.Text = "World Color: Neon Cyan"
    elseif Settings.WorldColorMode == 4 then Lighting.Ambient = Color3.fromRGB(130, 50, 200) b.Text = "World Color: Purple Night" end
end) ColorWorldBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 90)

-- FOV Элементы
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Parent = ContentContainer FOVLabel.BackgroundTransparency = 1 FOVLabel.Position = UDim2.new(0.05, 0, 0, 385)
FOVLabel.Size = UDim2.new(0.9, 0, 0, 20) FOVLabel.Font = Enum.Font.Gotham FOVLabel.Text = "FOV Radius: " .. tostring(Settings.FOV)
FOVLabel.TextColor3 = Color3.fromRGB(200, 200, 200) FOVLabel.TextSize = 13

local FOVMinus = Instance.new("TextButton")
FOVMinus.Parent = ContentContainer FOVMinus.BackgroundColor3 = Color3.fromRGB(140, 50, 50) FOVMinus.BorderSizePixel = 0
FOVMinus.Position = UDim2.new(0.05, 0, 0, 410) FOVMinus.Size = UDim2.new(0.42, 0, 0, 28) FOVMinus.Text = "-50"
FOVMinus.TextColor3 = Color3.fromRGB(255, 255, 255) FOVMinus.Font = Enum.Font.GothamBold FOVMinus.TextSize = 13 ApplyCorner(FOVMinus, 6)

FOVMinus.MouseButton1Click:Connect(function()
    if Settings.FOV > 50 then Settings.FOV = Settings.FOV - 50 FOVLabel.Text = "FOV Radius: " .. tostring(Settings.FOV) end
end)

local FOVPlus = Instance.new("TextButton")
FOVPlus.Parent = ContentContainer FOVPlus.BackgroundColor3 = Color3.fromRGB(50, 130, 80) FOVPlus.BorderSizePixel = 0
FOVPlus.Position = UDim2.new(0.53, 0, 0, 410) FOVPlus.Size = UDim2.new(0.42, 0, 0, 28) FOVPlus.Text = "+50"
FOVPlus.TextColor3 = Color3.fromRGB(255, 255, 255) FOVPlus.Font = Enum.Font.GothamBold FOVPlus.TextSize = 13 ApplyCorner(FOVPlus, 6)

FOVPlus.MouseButton1Click:Connect(function()
    if Settings.FOV < 800 then Settings.FOV = Settings.FOV + 50 FOVLabel.Text = "FOV Radius: " .. tostring(Settings.FOV) end
end)

local Footer = Instance.new("TextLabel")
Footer.Parent = ContentContainer Footer.BackgroundTransparency = 1 Footer.Position = UDim2.new(0, 0, 0, 445)
Footer.Size = UDim2.new(1, 0, 0, 20) Footer.Font = Enum.Font.Gotham Footer.Text = "Press [DEL] to Toggle Menu"
Footer.TextColor3 = Color3.fromRGB(100, 100, 105) Footer.TextSize = 11

-- --------------------------------------------------------------------
-- [АНИМАЦИЯ ЗАКРЫТИЯ И ОТКРЫТИЯ НА DEL]
-- --------------------------------------------------------------------
local MenuOpen = true
local TInter = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Delete then
        if MenuOpen then
            -- Сворачивание (Закрытие)
            TweenService:Create(MainFrame, TInter, {Size = UDim2.new(0, 230, 0, 45)}):Play()
            ContentContainer.Visible = false
            MenuOpen = false
        else
            -- Разворачивание (Открытие)
            TweenService:Create(MainFrame, TInter, {Size = UDim2.new(0, 230, 0, 520)}):Play()
            task.wait(0.1) -- Показываем контент чуть раньше окончания разворота для красоты
            ContentContainer.Visible = true
            MenuOpen = true
        end
    end
end)
