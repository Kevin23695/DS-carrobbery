-- server.lua

if Config.Framework == 'QBCore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'ESX' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

local lastRobberyTime = {}

function giveReward(player)
    local rewardCash = math.random(Config.Rewards.cash.min, Config.Rewards.cash.max)
    if Config.Framework == 'QBCore' then
        player.Functions.AddMoney('cash', rewardCash)
    elseif Config.Framework == 'ESX' then
        player.addMoney(rewardCash)
    end
    
    for _, item in pairs(Config.Rewards.items) do
        if math.random(1, 100) <= item.chance then
            if Config.Framework == 'QBCore' then
                player.Functions.AddItem(item.name, 1)
            elseif Config.Framework == 'ESX' then
                player.addInventoryItem(item.name, 1)
            end
        end
    end
end

RegisterServerEvent("carrobbery:attemptRobbery")
AddEventHandler("carrobbery:attemptRobbery", function()
    local source = source
    local xPlayer = Config.Framework == 'QBCore' and QBCore.Functions.GetPlayer(source) or ESX.GetPlayerFromId(source)
    local currentTime = os.time()

    if lastRobberyTime[source] and (currentTime - lastRobberyTime[source]) < Config.RobberyCooldown then
        TriggerClientEvent('chat:addMessage', source, { args = { "Robbery", "Anda harus menunggu sebelum melakukan pencurian lagi." } })
        return
    end

    local hasRequiredItem = Config.Framework == 'QBCore' and xPlayer.Functions.GetItemByName(Config.RequiredItem) or xPlayer.getInventoryItem(Config.RequiredItem).count > 0

    if hasRequiredItem then
        lastRobberyTime[source] = currentTime
        TriggerClientEvent('chat:addMessage', source, { args = { "Robbery", "Pencurian dimulai, bawa kendaraan ke lokasi pengantaran!" } })
    else
        TriggerClientEvent('chat:addMessage', source, { args = { "Robbery", "Anda membutuhkan item: " .. Config.RequiredItem } })
    end
end)

RegisterServerEvent("carrobbery:completeRobbery")
AddEventHandler("carrobbery:completeRobbery", function()
    local source = source
    local xPlayer = Config.Framework == 'QBCore' and QBCore.Functions.GetPlayer(source) or ESX.GetPlayerFromId(source)
    giveReward(xPlayer)
end)
