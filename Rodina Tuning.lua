require "lib.moonloader"
local dlstatus = require('moonloader').download_status
local ffi = require "ffi"
local requests = require "lib.requests"
local keys = require "vkeys"
local s = require 'lib.samp.events'

local script_tag = string.format("{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V%d{FFFFFF}]", script_vers_text) 

update_state = false

local script_vers = 3
local script_vers_text = "0.3"

local update_url = "https://raw.githubusercontent.com/KostyaBrazer/scripts/main/update.ini"
local update_path = getWorkingDirectory().."/update.ini"

local script_url = ""
local script_path = thisScript.path

function getserial()
    ffi.cdef([[
        int __stdcall GetVolumeInformationA(
        const char* lpRootPathName,
        char* lpVolumeNameBuffer,
        uint32_t nVolumeNameSize,
        uint32_t* lpVolumeSerialNumber,
        uint32_t* lpMaximumComponentLength,
        uint32_t* lpFileSystemFlags,
        char* lpFileSystemFlags,
        uint32_t nFileSystemNameSize
        );
    ]])

    local slot0_a1129 = ffi.new("unsigned long[1]", 0)

    ffi.C.GetVolumeInformationA(nil, nil, 0, slot0_a1129, nil, nil, nil, 0)

    return slot0_a1129[0]
end

local inicfg = require 'inicfg'
local directIni = "Rodina Tuning {7FFF00}V0.2.ini"
local mainIni = inicfg.load({
    config = {
        type="All (Sport and Sport+)",
        mode="Руками",
        delay=0,
        delaybuy=0
    }
}, directIni)

link = "https://docs.google.com/spreadsheets/d/1vH8s5FK5CFaDlQH--bP-HbvFJZHylIpzJ6AiZGKfLT8/gviz/tq"

detail = ""

garagelovlya = false

timelovlya = 0
timewait = 0

delaytune = 0

tuningsport = {"СПОРТ: Чип", "СПОРТ: Коленвал", "СПОРТ: Распредвал", "СПОРТ: Турбо-Компрессор", "СПОРТ: Нагнетатель", "СПОРТ: Сцепление", "СПОРТ: КПП", "СПОРТ: Дифференциал", "СПОРТ: Подвеска", "СПОРТ: Тормоза"}
tuningsportplus = {"СПОРТ+: Чип", "СПОРТ+: Коленвал", "СПОРТ+: Распредвал", "СПОРТ+: Турбо-Компрессор", "СПОРТ+: Нагнетатель", "СПОРТ+: Сцепление", "СПОРТ+: КПП", "СПОРТ+: Дифференциал", "СПОРТ+: Подвеска", "СПОРТ+: Тормоза"}

function secondsToTime(seconds)
    local years = math.floor(seconds / (24 * 3600))
    local days = math.floor(seconds / (24 * 3600))
    local hours = math.floor((seconds % (24 * 3600)) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
  
    return days, hours, minutes, remainingSeconds
  end

function main()
	while not isSampAvailable() do wait(100) end
    local r = requests.get(link)
    local j = decodeJson(r.text:gmatch('google%.visualization%.Query.setResponse%((.+)%);')())
    auth = false

    sampRegisterChatCommand('treload', function()
        sampAddChatMessage(script_tag.." {86fbe5}Reloaded.", -1)
        thisScript():reload()
    end)

    for k,v in pairs(j.table.rows) do
        if (v.c[1].v) == getserial() then
            if (v.c[3].v) < os.time() then
                sampAddChatMessage(script_tag.." Лицензия {ff4040}истекла{ffffff}, что бы продлить напишите в TG: {86fbe5}@yakvom", -1)
            elseif (v.c[3].v) > os.time() then

                downloadUrlToFile(update_url, update_file, function(id, status)
                    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                        updateIni = inicfg.load(nil, update_path)
                        if tonumber(updateIni.info.vers) > script_vers then
                            sampAddChatMessage(script_tag.." Доступно обновление! V"..inicfg.info.vers_text)
                            update_state = true
                        else
                            sampAddChatMessage(script_tag.."Обновлений не обнаружено! V"..inicfg.info.vers_text)
                        end
                    end
                end)

                auth = true
                sampAddChatMessage(script_tag.." by {86fbe5}cturbo {FFFFFF}загружен!", -1)
                sampAddChatMessage(script_tag.." Активация {86fbe5}/tmenu{FFFFFF}.", -1)
                sampAddChatMessage(script_tag.." TG: {86fbe5}@yakvom{FFFFFF}.", -1)
                local days, hours, minutes, seconds = secondsToTime(((v.c[3].v)-os.time()))
                local licenseactive = ""
                if days >= 360 then
                    licenseactive = "{ff4040}Навсегда"
                elseif days > 0 then
                    licenseactive = string.format("{ff4040}%d {FFFFFF}дн. {ff4040}%d {FFFFFF}ч. {ff4040}%d {FFFFFF}мин. {ff4040}%d {FFFFFF}сек.", days, hours, minutes, seconds)
                elseif days <= 0 then
                    licenseactive = string.format("{ff4040}%d {FFFFFF}ч. {ff4040}%d {FFFFFF}мин. {ff4040}%d {FFFFFF}сек.", hours, minutes, seconds)
                elseif hours <= 0 then
                    licenseactive = string.format("{ff4040}%d {FFFFFF}мин. {ff4040}%d {FFFFFF}сек.", minutes, seconds)
                elseif minutes <= 0 then
                    licenseactive = string.format("{ff4040}%d {FFFFFF}сек.", seconds)
                end
                sampAddChatMessage(string.format(script_tag.." Лицензия: {86fbe5}%d{FFFFFF}.", getserial()), -1)
                sampAddChatMessage(string.format(script_tag.." %s", licenseactive), -1)
                sampRegisterChatCommand('tmenu', menu)
            end
        end
    end

    if auth == false then
        sampRegisterChatCommand('tlic', function()
            sampAddChatMessage(script_tag.." Activation Key: {86fbe5}"..tostring(getserial())..".", -1)
        end)
    end

	while true do wait(0)
        result, button, list, input = sampHasDialogRespond(25000)
        result1, button1, list1, input1 = sampHasDialogRespond(25001)
        result2, button2, list2, input2 = sampHasDialogRespond(25002)
        result3, button3, list3, input3 = sampHasDialogRespond(25003)
        if auth == true then
            if result and button == 1 and list == 0 then
                active = not active
                print(active)
                menu()
            elseif result and button == 1 and list == 1 then
                mainIni.config.type = mainIni.config.type == "All (Sport and Sport+)" and "Sport+" or mainIni.config.type == "Sport+" and "Sport" or "All (Sport and Sport+)"
                printString(mainIni.config.type, 1500)
                inicfg.save(mainIni, directIni)
                menu()
            elseif result and button == 1 and list == 2 then
                sampShowDialog(25001, '{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V0.2{FFFFFF}]', "{00BFFF}Введите задержку в мс (от 0 до 700)", 'Выбрать', 'Назад', 1)
            elseif result and button == 1 and list == 3 then
                sampShowDialog(25003, '{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V0.2{FFFFFF}]', "{00BFFF}Введите задержку в мс (от 0 до 1500)", 'Выбрать', 'Назад', 1)
            elseif result and button == 1 and list == 4 then
                garagelovlya = not garagelovlya
                printString(garagelovlya and "Enabled!" or "Disabled!", 1500)
                menu()
            elseif result and button == 1 and list == 5 then
                mainIni.config.mode = mainIni.config.mode == "Автоматически" and "Руками" or "Автоматически"
                printString("Mode = " .. (mainIni.config.mode == "Автоматически" and "auto" or "hand"), 1500)
                inicfg.save(mainIni, directIni)
                menu()
            elseif result and button == 1 and list == 6 then
                sampShowDialog(25002, "{FFFFFF}[{d3b8f3}Лог покупок{FFFFFF}]", updatelog(), "Выбрать", "Назад", 0)
            elseif result1 and button1 == 1 and input1 ~= nil then
                if not tonumber(input1) then
                    printString("Error: enter a number", 1500)
                    sampShowDialog(25001, '{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V0.2{FFFFFF}]', "{00BFFF}Ошибка! Нельзя использовать буквы или символы!\nВведите задержку в мс (от 0 до 700)", 'Выбрать', 'Назад', 1)
                else
                    delay = tonumber(input1)
                    if delay >= 0 and delay <= 700 then
                        mainIni.config.delay = delay
                        printString("Delay: "..delay, 1500)
                        inicfg.save(mainIni, directIni)
                        menu()
                    else
                        printString("Error: min: 0, max: 700", 1500)
                        sampShowDialog(25001, '{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V0.2{FFFFFF}]', "{00BFFF}Ошибка!\nВведите задержку в мс (от 0 до 700)", 'Выбрать', 'Назад', 1)
                    end
                end
            elseif result3 and button3 == 1 and input3 ~= nil then
                if not tonumber(input3) then
                    printString("Error: enter a number", 1500)
                    sampShowDialog(25003, '{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V0.2{FFFFFF}]', "{00BFFF}Ошибка! Нельзя использовать буквы или символы!\nВведите задержку в мс (от 0 до 1500)", 'Выбрать', 'Назад', 1)
                else
                    delaybuy = tonumber(input3)
                    if delaybuy >= 0 and delaybuy <= 1500 then
                        mainIni.config.delaybuy = delaybuy
                        printString("Delay: "..delaybuy, 1500)
                        inicfg.save(mainIni, directIni)
                        menu()
                    else
                        printString("Error: min: 0, max: 1500", 1500)
                        sampShowDialog(25003, '{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V0.2{FFFFFF}]', "{00BFFF}Ошибка!\nВведите задержку в мс (от 0 до 1500)", 'Выбрать', 'Назад', 1)
                    end
                end
            elseif result1 and button1 == 0 then
                menu()
            elseif result2 and button2 == 0 or result2 and button2 == 1 then
                menu()
            elseif result3 and button3 == 0 then
                menu()
            end
        end
	end
end

function s.onCreate3DText(idObject, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, textObject)
    if textObject:find("Идёт процесс загрузки") and textObject:find("1 секунд") and not textObject:find("(%d)1 секунд") then
        timewait = 1000
        lua_thread.create(press_key)
    end
end

function press_key()
    time = os.time()+1
    while os.time() ~= time do
        wait(0)
        setGameKeyState(18, -256)
    end
    return
end

function menu()
    sampShowDialog(25000, '{FFFFFF}[{d3b8f3}Rodina Tuning {7FFF00}V0.2{FFFFFF}]', "Статус: {86fbe5}"..(active and "{19e619}включен" or "{dc143c}выключен").."\n{FFFFFF}Тип тюнинга: {86fbe5}"..mainIni.config.type.."\n{FFFFFF}Задержка: {86fbe5}"..mainIni.config.delay.."\n{FFFFFF}Задержка покупки: {86fbe5}"..mainIni.config.delaybuy.."\n{FFFFFF}Авто Гараж: {86fbe5}"..(garagelovlya and "{19e619}включен" or "{dc143c}выключен").."\n{FFFFFF}Оплата: {86fbe5}"..mainIni.config.mode.."\n{FFFFFF}Лог покупок", 'Выбрать', 'Отмена', 2)
end

time = 0

function onReceivePacket(id, bs) 
    if id == 220 and auth and active then
        raknetBitStreamIgnoreBits(bs, 8)
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32)
            local str = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
            if string.find(str, "vue.set%('tuning'%)%;") then
                lua_thread.create(function()
                    sendMenu()
                    wait(timewait-1000)
                    wait(50)
                    if mainIni.config.type == "All (Sport and Sport+)" then
                        for i = 1, 30 do
                            for _, packetType in ipairs({chipSport2, chipSportplus2, tcompSport2, nagnetatelSport2, tcompSportplus2, nagnetatelSportplus2, kolenvalSport2, kolenvalSportplus2, raspredvalSport2, raspredvalSportplus2, scepSport2, scepSportplus2, kppSport2, kppSportplus2, difSport2, difSportplus2, podvesSport2, podvesSportplus2, tormozaSport2, tormozaSportplus2}) do
                                wait(delaytune)
                                sendPacket1(packetType[1])
                                sendPacket2(packetType[2])
                                wait(mainIni.config.delay)
                            end
                        end
                    elseif mainIni.config.type == "Sport+" then
                        for i = 1, 30 do
                            for i, packetType in ipairs({chipSportplus2, kolenvalSportplus2, raspredvalSportplus2, tcompSportplus2, nagnetatelSportplus2, scepSportplus2, kppSportplus2, difSportplus2, podvesSportplus2, tormozaSportplus2}) do
                                wait(delaytune)
                                sendPacket1(packetType[1])
                                sendPacket2(packetType[2])
                                wait(mainIni.config.delay)
                            end
                        end
                    elseif mainIni.config.type == "Sport" then
                        for i = 1, 30 do
                            for _, packetType in ipairs({chipSport2, kolenvalSport2, raspredvalSport2, tcompSport2, nagnetatelSport2, scepSport2, kppSport2, difSport2, podvesSport2, tormozaSport2}) do
                                wait(delaytune)
                                sendPacket1(packetType[1])
                                sendPacket2(packetType[2])
                                wait(mainIni.config.delay)
                            end
                        end
                    end
                    return
                end)
            end
            if string.find(str, '"cartCount":') ~= nil and mainIni.config.mode == "Автоматически" then
                if tonumber(string.match(str, '"cartCount":(%d+)', 0)) ~= 0 then
                    delaytune = mainIni.config.delaybuy
                    lua_thread.create(buydetail)
                end
            end
        end
    end
end

function buydetail()
    local cash = getPlayerMoney(PLAYER_HANDLE)
    packetbuy()
    wait(delaytune/2)
    local cash2 = getPlayerMoney(PLAYER_HANDLE)
    if cash2 < cash then
        local timenow = os.time()
        local datetime = os.date("*t", timenow)
        local dateStr = string.format("%02d.%02d.%02d", datetime.day, datetime.month, datetime.year % 100)
        local timeStr = string.format("%02d:%02d:%02d", datetime.hour, datetime.min, datetime.sec)
        printStyledString("COMPLETE", 1500, 1)
        file = io.open("moonloader\\Tuning_Log.txt", "a")
        file:write("["..dateStr.."] | ["..timeStr.."]: Detail: ["..detail.."], Time: "..os.time()-(timelovlya-0.2)..", Price: "..cash-cash2.."$, Balance: "..cash2.."$\n")
        file:flush()
        file:close()
    end
    delaytune = 0
    return
end

kolenvalSport2 = {"5", "2" }

kolenvalSportplus2 = {"5", "3" }

raspredvalSport2 = {"6", "5" }

raspredvalSportplus2 = {"6", "6" }

tcompSport2 = {"7", "9" }

nagnetatelSport2 = {"7", "10" }

tcompSportplus2 = {"7", "11" }

nagnetatelSportplus2 = {"7", "12" }

chipSport2 = {"8", "14" }

chipSportplus2 = {"8", "15" }

scepSport2 = {"9", "17" }

scepSportplus2 = {"9", "18" }

kppSport2 = {"10", "20" }

kppSportplus2 = {"10", "21" }

difSport2 = {"11", "23" }

difSportplus2 = {"11", "24" }

podvesSport2 = {"12", "26" }

podvesSportplus2 = {"12", "27" }

tormozaSport2 = {"13", "29" }

tormozaSportplus2 = {"13", "30" }


filename = "moonloader\\Tuning_Log.txt"

startLine = 0
endLine = 0

function updatelog()
    local file = io.open(filename, "r")
    if file then
        local content = ""
        local currentLine = -1
        local countline = 0

        for line in file:lines() do
            countline = countline + 1
        end

        file:close()

        startLine = countline - 25
        endLine = countline

        local file = io.open(filename, "r")

        for line in file:lines() do
            if currentLine >= startLine and currentLine <= endLine then
                content = content .. line .. "\n"
            end

            if currentLine >= endLine then
                break
            end

            currentLine = currentLine + 1
        end

        file:close()
        print(content)
        return content
    else
        print("Ошибка при открытии файла: " .. filename)
        return nil
    end
end

showmenu = {"17", "0", "0", "0", "0", "18", "0", "0", "0", "118", "117", "101", "46", "115", "101", "116", "40", "39", "116", "117", "110", "105", "110", "103", "39", "41", "59", "1", "0", "0", "0", "0", "0", "41", "0", "0", "0"}

function sendMenu()
    local bs = raknetNewBitStream()
    for k, v in pairs(showmenu) do
        raknetBitStreamWriteInt8(bs, v)
    end
    raknetBitStreamWriteInt16(bs, 1)
    raknetBitStreamWriteInt8(bs, 0)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

function sendPacket1(category)
    local str = string.format('@7, updateCategory, %d', category)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt32(bs, string.len(str))
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt16(bs, 1)
    raknetBitStreamWriteInt8(bs, 0)
    raknetSendBitStreamEx(bs, 2, 9, 6)
    raknetDeleteBitStream(bs)
end

function sendPacket2(detail)
    local str = string.format('@7, cart, add, %d', detail)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt32(bs, string.len(str))
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt16(bs, 1)
    raknetBitStreamWriteInt8(bs, 0)
    raknetSendBitStreamEx(bs, 2, 9, 6)
    raknetDeleteBitStream(bs)
end

function packetbuy()
    str = "@7, popupResponse, 2, 0"
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt32(bs, string.len(str))
    raknetBitStreamWriteString(bs, str)
	raknetBitStreamWriteInt16(bs, 1)
	raknetBitStreamWriteInt8(bs, 0)
    raknetSendBitStreamEx(bs, 2, 9, 6)
	raknetDeleteBitStream(bs)
end