-- ������������� �������� ����������
local config = {
    instrument = "SBER",      -- �������� ����������
    lotSize = 1,             -- ������ ����
    account = "NL0011100043", -- ����� �����
    stopLoss = 10,           -- ����-���� � �������
    takeProfit = 20,         -- ����-������ � �������
    checkInterval = 1000     -- �������� �������� � ��
}

-- ���������� ����������
local position = 0           -- ������� �������
local entryPrice = 0         -- ���� �����
local isRunning = false      -- ���� ������ ������

-- ������� �������������
function init()
    isRunning = true
    -- ������������� �� ���������� ���������
    subscribeQuotes(config.instrument)
    -- ��������� ������ ��������
    createTimer(checkMarket, config.checkInterval)
    return true
end

-- ������� ��������� ���������
function processQuotes(class_code, sec_code, bid, ask)
    if not isRunning then return end

    -- ������� ������ ����� � �������
    if position == 0 and ask < getSignalPrice() then
        openPosition("BUY", config.lotSize, ask)
    elseif position > 0 and bid > getSignalPrice() then
        closePosition("SELL", config.lotSize, bid)
    end
end

-- ������� �������� �����
function checkMarket()
    if not isRunning then return end

    -- �������� ����-������ � ����-��������
    if position > 0 then
        local currentPrice = getCurrentPrice()
        if currentPrice < entryPrice - config.stopLoss then
            closePosition("SELL", config.lotSize, currentPrice)
        elseif currentPrice > entryPrice + config.takeProfit then
            closePosition("SELL", config.lotSize, currentPrice)
        end
    end
end

-- ������� �������� �������
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

-- ������� �������� �������
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

-- ������� ��������� ���������� ����
function getSignalPrice()
    -- ����� ������ ���� ���� ������ ������� ���������� ����
    return getAveragePrice()
end

-- ������� ��������� ������� ����
function getAveragePrice()
    local bid, ask = getQuotes(config.instrument)
    return (bid + ask) / 2
end

-- ������� ��������� ������� ����
function getCurrentPrice()
    local bid, ask = getQuotes(config.instrument)
    return (bid + ask) / 2
end

-- ������� ��������� ���������
function getQuotes(sec_code)
    local class_code = "TQBR"
    local bid = getParamEx(class_code, sec_code, "BEST_BID")
    local ask = getParamEx(class_code, sec_code, "BEST_ASK")
    return bid, ask
end

-- ������� �������� ����������
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

-- ������� �������� �� ���������
function subscribeQuotes(sec_code)
    create_market_data_feed("TQBR", sec_code)
end

-- ������� �������� �������
function createTimer(func, interval)
    on_every(interval, func)
end

-- ������� ��������� ������
function stop()
    isRunning = false
    unsubscribe
