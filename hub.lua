local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Ссылка на твой JSON-файл
local JSON_URL = "https://raw.githubusercontent.com/Mishik111/scripts/refs/heads/main/scripts.json"

-- Безопасно загружаем данные с твоего GitHub
local success, result = pcall(function()
    return game:HttpGet(JSON_URL)
end)

if not success then
    warn("Не удалось загрузить список скриптов: " .. tostring(result))
    return
end

-- Декодируем JSON
local scriptList = {}
local decodeSuccess, decodeResult = pcall(function()
    return HttpService:JSONDecode(result)
end)

if decodeSuccess then
    scriptList = decodeResult
else
    warn("Ошибка в синтаксисе JSON файла на GitHub!")
    return
end

-- Создаем интерфейс
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MishikHub_Custom"
ScreenGui.ResetOnSpawn = false

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 380, 0, 280)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -40, 0, 45)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Mishik Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Кнопка закрытия
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0, 7)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(150, 150, 160)
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = MainFrame

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Зона прокрутки
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Name = "ScriptList"
ScrollingFrame.Size = UDim2.new(1, -20, 1, -65)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 55)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
ScrollingFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollingFrame

-- ИСПРАВЛЕННАЯ ФУНКЦИЯ ЗАПУСКА С ЗАЩИТОЙ И ЛОГИРОВАНИЕМ
local function launchScript(url)
    ScreenGui:Destroy() -- Скрываем меню сразу, как просил
    
    task.spawn(function()
        -- 1. Проверяем скачивание кода скрипта
        local getSuccess, scriptCode = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not getSuccess or not scriptCode or scriptCode == "" or string.match(scriptCode, "404: Not Found") then
            warn("🚨 ХАБ ОШИБКА: Не удалось скачать скрипт! Проверь ссылку в JSON. Ссылка: " .. tostring(url))
            return
        end
        
        -- 2. Проверяем компиляцию (синтаксис кода)
        local func, compileError = loadstring(scriptCode)
        if not func then
            warn("🚨 ХАБ ОШИБКА СИНТАКСИСА: В самом чите по ссылке есть ошибка кода! Текст ошибки: " .. tostring(compileError))
            return
        end
        
        -- 3. Если всё ок — запускаем
        local runSuccess, runError = pcall(func)
        if not runSuccess then
            warn("🚨 ХАБ ОШИБКА ВНУТРИ СКРИПТА: Чит запустился, но сломался во время работы: " .. tostring(runError))
        end
    end)
end

-- Создаем кнопки для игр
for gameName, scriptUrl in pairs(scriptList) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -6, 0, 38)
    Button.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
    Button.Text = "  " .. gameName
    Button.TextColor3 = Color3.fromRGB(240, 240, 245)
    Button.TextSize = 14
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Font = Enum.Font.GothamMedium
    Button.Parent = ScrollingFrame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button

    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 65)}):Play()
    end)
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(42, 42, 48)}):Play()
    end)

    Button.MouseButton1Click:Connect(function()
        launchScript(scriptUrl)
    end)
end

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 5)
end)

-- Система перетаскивания (Drag)
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
