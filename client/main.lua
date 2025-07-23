local QBCore = exports['qb-core']:GetCoreObject()

-- Functie om politie te waarschuwen met 75% kans via ps-dispatch export
local function TryDispatchAlert()
    if math.random() <= 0.75 then
        exports['ps-dispatch']:DrugSale()
    end
end

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

-- Verkoop items aan server doorgeven + trigger dispatch alert via export
RegisterNUICallback("sellItems", function(data, cb)
    if data and data.items then
        TriggerServerEvent("drago-plugv2:sellItems", data.items)
        -- Probeer politie te waarschuwen via ps-dispatch export
        TryDispatchAlert()
    end
    cb("ok")
end)

-- Optionele NUI callback om stats op te vragen vanuit de UI (bijv. in de stats tab)
RegisterNUICallback("requestStats", function(_, cb)
    QBCore.Functions.TriggerCallback("drago-plugv2:getStats", function(stats)
        cb(stats)
    end)
end)

-- Helper functies om gender en straat te krijgen (indien nog niet aanwezig)

function GetPlayerGender()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    if model == GetHashKey("mp_m_freemode_01") then
        return "male"
    elseif model == GetHashKey("mp_f_freemode_01") then
        return "female"
    else
        return "unknown"
    end
end

function GetStreetAndZone(coords)
    local streetName, zone = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetLabel = GetStreetNameFromHashKey(streetName)
    local zoneLabel = GetNameOfZone(coords.x, coords.y, coords.z)
    return streetLabel .. ", " .. zoneLabel
end
