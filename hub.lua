local HttpService = game:GetService("HttpService")

-- Ссылка на твой JSON-файл
local JSON_URL = "https://raw.githubusercontent.com/Mishik111/scripts/refs/heads/main/scripts.json"

-- Загрузка библиотеки Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
local Window = Rayfield:CreateWindow({
    Name = "Mishik Hub",
    LoadingTitle = "Загрузка хаба...",
    LoadingSubtitle = "by Mishik111",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false -- Ключ не нужен
})

-- Создаем вкладку для скриптов
local ScriptTab = Window:CreateTab("Игры / Скрипты", 4483362458) -- Иконка gamepad

-- Функция для закрытия хаба и запуска выбранного скрипта
local function launchScript(scriptUrl)
    -- Полностью уничтожаем интерфейс хаба
    Rayfield:Destroy()
    
    -- Запускаем скрипт в отдельном потоке, чтобы ничего не зависло
    task.spawn(function()
        local runSuccess, runError = pcall(function()
            loadstring(game:HttpGet(scriptUrl))()
        end)
        
        if not runSuccess then
            warn("Ошибка при запуске скрипта игры: " .. tostring(runError))
        end
    end)
end

-- Динамически создаем кнопки на основе твоего JSON
local count = 0
for gameName, scriptUrl in pairs(scriptList) do
    count = count + 1
    ScriptTab:CreateButton({
        Name = gameName,
        Callback = function()
            launchScript(scriptUrl)
        end,
    })
end

-- Если JSON пустой
if count == 0 then
    ScriptTab:CreateLabel("В файле scripts.json нет доступных скриптов.")
end

-- Уведомление об успешном старте
Rayfield:Notify({
    Title = "Mishik Hub",
    Content = "Все скрипты успешно загружены с GitHub!",
    Duration = 5,
    Image = 4483362458,
})
