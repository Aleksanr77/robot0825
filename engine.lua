-- engine.lua
local Engine = {}

-- Флаг подключения
Engine.isConnected = false

-- Обработчик подключения
function Engine:onConnected()
    self.isConnected = true
    print("Подключение к серверу установлено")

    -- После подключения подписываемся на данные
    self:subscribeData()
    self:initStrategy()
end

-- Обработчик отключения
function Engine:onDisconnected()
    self.isConnected = false
    print("Отключено от сервера")

    -- Отменяем все подписки
    self:unsubscribeData()
    -- Отменяем все ордера
    self:cancelAllOrders()
end

function Engine:onError(error_code, error_desc)
    print("Произошла ошибка: " .. error_desc)

    if error_code == SOME_ERROR_CODE then
        -- Логика обработки конкретной ошибки
    end

-- Функция подписки на данные
function Engine:subscribeData()
    -- Здесь логика подписки на рыночные данные
end

-- Регистрация обработчиков
function Engine:registerHandlers()
    set_handler("OnConnected", self.onConnected)
    set_handler("OnDisconnected", self.onDisconnected)
	set_handler("OnError", self.onError)
end

function Engine:init()
    -- инициализация движка
	self:registerHandlers()
	data:subscribe()
	data_utils:init_storage()

end

function Engine:start()
    -- запуск основного цикла
end

function Engine:update()
	local current_data = data:get_current_data()
	data_utils:process_data(current_data)
end

return Engine

