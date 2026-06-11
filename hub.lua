local HttpService = game:GetService("HttpService")

-- Ссылка на твой JSON-файл
local JSON_URL = "https://raw.githubusercontent.com/Mishik111/scripts/refs/heads/main/scripts.json"

-- Загрузка библиотеки Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Загрузка данных с GitHub
local success, result = pcall(function()
    return game:HttpGet(JSON_URL)
end)

if not success then
    warn("Не удалось загрузить список скриптов: " .. tostring(result))
    return
end

-- Декодирование JSON
local scriptList = {}
local decodeSuccess, decodeResult = pcall(function()
    return HttpService:JSONDecode(result)
end)

if decodeSuccess then
    scriptList = decodeResult
else
    warn("Ошибка парсинга JSON!")
    return
end

-- Создаем главное окно
local Window = Fluent:CreateWindow({
    Title = "Mishik Hub",
    SubTitle = "by Mishik111",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Автоматическое определение правильного метода для создания вкладки
local Tabs = {}
if Window.NewTab then
    Tabs.Scripts = Window:NewTab({ Title = "Игры / Скрипты", Icon = "gamepad" })
elseif Window.CreateTab then
    Tabs.Scripts = Window:CreateTab({ Title = "Игры / Скрипты", Icon = "gamepad" })
else
    warn("Критическая ошибка: Не найден метод создания вкладок в этой версии Fluent!")
    return
end

-- Функция запуска выбранного скрипта
local function launchScript(scriptUrl)
    -- Закрываем UI
    if Fluent.Destroy then
        Fluent:Destroy()
    elseif Window.Destroy then
        Window:Destroy()
    end
    
    -- Выполняем код
    task.spawn(function()
        local runSuccess, runError = pcall(function()
            loadstring(game:HttpGet(scriptUrl))()
        end)
        if not runSuccess then
            warn("Ошибка при выполнении скрипта: " .. tostring(runError))
        end
    end)
end

-- Безопасно выбираем первую вкладку
pcall(function() Window:SelectTab(1) end)

-- Создаем кнопки для каждой игры
local count = 0
for gameName, scriptUrl in pairs(scriptList) do
    count = count + 1
    Tabs.Scripts:AddButton({
        Title = gameName,
        Description = "Запустить скрипт для " .. gameName,
        Callback = function()
            launchScript(scriptUrl)
        end
    })
end

if count == 0 then
    Tabs.Scripts:AddParagraph({
        Title = "Пусто",
        Content = "В файле scripts.json нет доступных скриптов."
    })
end

-- Уведомление
Fluent:Notify({
    Title = "Mishik Hub",
    Content = "Скрипты успешно загружены!",
    Duration = 5
})
