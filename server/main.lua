local QBCore = exports['qb-core']:GetCoreObject()
local currentPrices = {}

-- Functie om prijzen te updaten (tussen 80% en 120% van basisprijs)
local function UpdatePrices()
    for itemName, info in pairs(Config.Items) do
        local basePrice = info.price
        local minPrice = math.floor(basePrice * 0.8)
        local maxPrice = math.ceil(basePrice * 1.2)
        currentPrices[itemName] = math.random(minPrice, maxPrice)
    end
    print("Dealer prijzen geüpdatet!")
end

-- Init prijzen bij serverstart en update elk uur automatisch
Citizen.CreateThread(function()
    UpdatePrices()
    while true do
        Citizen.Wait(3600000) -- 1 uur in milliseconden
        UpdatePrices()
    end
end)

-- Callback voor inventory items met dynamische prijs
QBCore.Functions.CreateCallback("drago-plugv2:getInventoryItems", function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local items = {}

    for itemName, info in pairs(Config.Items) do
        local invItem = Player.Functions.GetItemByName(itemName)
        if invItem and invItem.amount > 0 then
            items[#items + 1] = {
                name = itemName,
                label = info.label,
                amount = invItem.amount,
                price = currentPrices[itemName] or info.price,
                image = info.image
            }
        end
    end

    cb(items)
end)

-- Server event om items te verkopen tegen dynamische prijs en loggen
RegisterServerEvent("drago-plugv2:sellItems", function(sellItems)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local total = 0

    for _, item in pairs(sellItems) do
        local price = currentPrices[item.name] or (Config.Items[item.name] and Config.Items[item.name].price)
        if price then
            local removed = Player.Functions.RemoveItem(item.name, item.amount)
            if removed then
                local itemTotal = item.amount * price
                total = total + itemTotal

                -- Verkoop loggen in database
                exports.oxmysql:execute('INSERT INTO plug_sales_log (citizenid, item_name, amount, total_price) VALUES (?, ?, ?, ?)', {
                    Player.PlayerData.citizenid,
                    item.name,
                    item.amount,
                    itemTotal
                })
            end
        end
    end

    if total > 0 then
        Player.Functions.AddMoney("cash", total)
        TriggerClientEvent('QBCore:Notify', src, "Je hebt €" .. total .. " ontvangen.", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Geen geld ontvangen.", "error")
    end
end)

-- Callback voor leaderboard en persoonlijke statistieken (met spelersnaam)
QBCore.Functions.CreateCallback("drago-plugv2:getStats", function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return cb(nil) end

    local citizenid = Player.PlayerData.citizenid

    local stats = {
        leaderboard = {},
        personal = { sales = 0, earned = 0 }
    }

    -- Top 3 leaderboard ophalen inclusief naam uit charinfo
    exports.oxmysql:execute([[
        SELECT l.citizenid, p.charinfo, SUM(l.total_price) as earned 
        FROM plug_sales_log l
        JOIN players p ON l.citizenid = p.citizenid
        GROUP BY l.citizenid
        ORDER BY earned DESC
        LIMIT 3
    ]], {}, function(leaderboard)
        if leaderboard then
            for i, entry in ipairs(leaderboard) do
                local charinfo = json.decode(entry.charinfo)
                local playerName = charinfo and (charinfo.firstname .. " " .. charinfo.lastname) or entry.citizenid
                leaderboard[i].playerName = playerName
            end
            stats.leaderboard = leaderboard
        else
            stats.leaderboard = {}
        end

        -- Persoonlijke statistieken ophalen
        exports.oxmysql:execute('SELECT COUNT(*) as sales, COALESCE(SUM(total_price), 0) as earned FROM plug_sales_log WHERE citizenid = ?', { citizenid }, function(personal)
            if personal and personal[1] then
                stats.personal.sales = personal[1].sales or 0
                stats.personal.earned = personal[1].earned or 0
            end

            cb(stats)
        end)
    end)
end)

-- Admin commando om prijzen handmatig te updaten
QBCore.Commands.Add("updateprices", "Update dealer prijzen (admin only)", {}, false, function(source, args)
    if source == 0 or QBCore.Functions.HasPermission(source, "admin") then
        UpdatePrices()
        TriggerClientEvent('QBCore:Notify', source, "Dealer prijzen zijn geüpdatet!", "success")
    else
        TriggerClientEvent('QBCore:Notify', source, "Geen toestemming", "error")
    end
end)
