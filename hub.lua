local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Ссылка на твой JSON-файл
local JSON_URL = "https://raw.githubusercontent.com/Mishik111/scripts/refs/heads/main/scripts.json"

-- Загрузка библиотеки интерфейса (Fluent)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Получаем данные с GitHub
local success, result = pcall(function()
    return game:HttpGet(JSON_URL)
end)

if not success then
    warn("Не удалось загрузить список скриптов: " .. tostring(result))
    return
end

-- Декодируем JSON в таблицу Lua
local scriptList = {}
local decodeSuccess, decodeResult = pcall(function()
    return HttpService:JSONDecode(result)
end)

if decodeSuccess then
    scriptList = decodeResult
else
    warn("Ошибка парсинга JSON. Проверь синтаксис файла!")
    return
end

-- Создаем главное окно хаба
local Window = Fluent:CreateWindow({
    Title = "Mishik Hub",
    SubTitle = "by Mishik111",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Добавляем вкладку для скриптов
local Tabs = {
    Scripts = Window:CreateTab({
        Title = "Игры / Скрипты",
        Icon = "gamepad"
    })
}

-- Функция для красивого закрытия хаба и запуска скрипта
local function launchScript(scriptUrl)
    -- Закрываем и полностью удаляем интерфейс Fluent
    Fluent:Destroy()
    
    -- Запускаем выбранный скрипт
    local runSuccess, runError = pcall(function()
        loadstring(game:HttpGet(scriptUrl))()
    end)
    
    if not runSuccess then
        warn("Ошибка при запуске скрипта: " .. tostring(runError))
    end
end

-- Динамически создаем кнопки на основе твоего JSON
Window:SelectTab(Tabs.Scripts)

local count = 0
for gameName, scriptUrl in pairs(scriptList) do
    count = count + 1
    Tabs.Scripts:AddButton({
        Title = gameName,
        Description = "Нажми, чтобы запустить скрипт для " .. gameName,
        Callback = function()
            launchScript(scriptUrl)
        end
    })
end

-- Если JSON оказался пустым
if count == 0 then
    Tabs.Scripts:AddParagraph({
        Title = "Пусто",
        Content = "В файле scripts.json нет доступных скриптов."
    })
end

-- Уведомление об успешном запуске хаба
Fluent:Notify({
    Title = "Mishik Hub",
    Content = "Список скриптов успешно загружен!",
    Duration = 5
})
