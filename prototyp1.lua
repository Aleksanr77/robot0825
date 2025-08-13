-- Инициализация основных параметров
local config = {
    instrument = "SBER",      -- торговый инструмент
    lotSize = 1,             -- размер лота
    account = "NL0011100043", -- номер счета
    stopLoss = 10,           -- стоп-лосс в пунктах
    takeProfit = 20,         -- тейк-профит в пунктах
    checkInterval = 1000     -- интервал проверки в мс
}

-- Глобальные переменные
local position = 0           -- текущая позиция
local entryPrice = 0         -- цена входа
local isRunning = false      -- флаг работы робота

-- Функция инициализации
function init()
    isRunning = true
    -- Подписываемся на обновление котировок
    subscribeQuotes(config.instrument)
    -- Запускаем таймер проверки
    createTimer(checkMarket, config.checkInterval)
    return true
end

-- Функция обработки котировок
function processQuotes(class_code, sec_code, bid, ask)
    if not isRunning then return end

    -- Простая логика входа в позицию
    if position == 0 and ask < getSignalPrice() then
        openPosition("BUY", config.lotSize, ask)
    elseif position > 0 and bid > getSignalPrice() then
        closePosition("SELL", config.lotSize, bid)
    end
end

-- Функция проверки рынка
function checkMarket()
    if not isRunning then return end

    -- Проверка стоп-лоссов и тейк-профитов
    if position > 0 then
        local currentPrice = getCurrentPrice()
        if currentPrice < entryPrice - config.stopLoss then
            closePosition("SELL", config.lotSize, currentPrice)
        elseif currentPrice > entryPrice + config.takeProfit then
            closePosition("SELL", config.lotSize, currentPrice)
        end
    end
end

-- Функция открытия позиции
function openPosition(action, lot, price)
    if not isRunning then return end

    local trans_id = createTransaction(
        "TRADE_TRANSACTION_SEND_BUY_REQUEST",
        config.account,
        config.instrument,
        lot,
        price
    )

    if trans_id > 0 then
        position = lot
        entryPrice = price
    end
end

-- Функция закрытия позиции
function closePosition(action, lot, price)
    if not isRunning then return end

    local trans_id = createTransaction(
        "TRADE_TRANSACTION_SEND_SELL_REQUEST",
        config.account,
        config.instrument,
        lot,
        price
    )

    if trans_id > 0 then
        position = 0
        entryPrice = 0
    end
end

-- Функция получения сигнальной цены
function getSignalPrice()
    -- Здесь должна быть ваша логика расчета сигнальной цены
    return getAveragePrice()
end

-- Функция получения средней цены
function getAveragePrice()
    local bid, ask = getQuotes(config.instrument)
    return (bid + ask) / 2
end

-- Функция получения текущей цены
function getCurrentPrice()
    local bid, ask = getQuotes(config.instrument)
    return (bid + ask) / 2
end

-- Функция получения котировок
function getQuotes(sec_code)
    local class_code = "TQBR"
    local bid = getParamEx(class_code, sec_code, "BEST_BID")
    local ask = getParamEx(class_code, sec_code, "BEST_ASK")
    return bid, ask
end

-- Функция создания транзакции
function createTransaction(trans_type, account, instrument, lot, price)
    return execute_trade_request(
        trans_type,
        account,
        "TQBR",
        instrument,
        lot,
        price,
        0,
        0,
        0,
        0
    )
end

-- Функция подписки на котировки
function subscribeQuotes(sec_code)
    create_market_data_feed("TQBR", sec_code)
end

-- Функция создания таймера
function createTimer(func, interval)
    on_every(interval, func)
end

-- Функция остановки робота
function stop()
    isRunning = false
    unsubscribe
