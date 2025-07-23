local QBCore = exports['qb-core']:GetCoreObject()

-- Maak dealer ped en target zone
CreateThread(function()
    local model = Config.DealerPed.model
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local coords = Config.DealerPed.coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1, coords.w, false, true)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                icon = "fas fa-cash-register",
                label = "Verkoop Drugs / Statistieken",
                action = function()
                    -- Haal eerst inventory items op met prijzen
                    QBCore.Functions.TriggerCallback("drago-plugv2:getInventoryItems", function(items)
                        -- Haal daarna stats op (leaderboard + persoonlijke stats)
                        QBCore.Functions.TriggerCallback("drago-plugv2:getStats", function(stats)
                            if stats then
                                -- Open NUI menu met data
                                SetNuiFocus(true, true)
                                SendNUIMessage({
                                    action = "open",
                                    tab = "verkoop", -- start tab
                                    items = items,
                                    stats = stats
                                })
                            else
                                QBCore.Functions.Notify("Kon statistieken niet ophalen.", "error")
                            end
                        end)
                    end)
                end
            }
        },
        distance = 2.0
    })
end)

-- Sluit het NUI menu
RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Verkoop items aan server doorgeven
RegisterNUICallback("sellItems", function(data, cb)
    if data and data.items then
        TriggerServerEvent("drago-plugv2:sellItems", data.items)
    end
    cb("ok")
end)

-- Optionele NUI callback om stats op te vragen vanuit de UI (bijv. in de stats tab)
RegisterNUICallback("requestStats", function(_, cb)
    QBCore.Functions.TriggerCallback("drago-plugv2:getStats", function(stats)
        cb(stats)
    end)
end)
