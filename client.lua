-- client.lua

local isPolice = false
local robberyBlip = nil
local npcSpawned = false
local npcEntity = nil
local robberyVehicle = nil
local isInRobbery = false
local isLockpicking = false

-- Fungsi untuk menampilkan pesan bantuan
function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Fungsi untuk membuat NPC
function spawnRobberyNPC()
    local model = GetHashKey(Config.NPC.model)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Citizen.Wait(100)
    end

    npcEntity = CreatePed(4, model, Config.NPC.location.x, Config.NPC.location.y, Config.NPC.location.z - 1, 0.0, false, true)
    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    FreezeEntityPosition(npcEntity, true)
    npcSpawned = true
end

-- Fungsi untuk menampilkan mini-game lockpicking
function startLockpickingGame()
    isLockpicking = true
    DisplayHelpText("Tekan tombol yang benar untuk membuka kunci!")

    Citizen.CreateThread(function()
        local success = true
        local steps = 3

        for i = 1, steps do
            local requiredKey = math.random(1, 4)
            local pressedKey = nil
            DisplayHelpText("Tekan tombol " .. getDirectionText(requiredKey))

            local start = GetGameTimer()
            while true do
                Citizen.Wait(0)
                if IsControlJustPressed(0, 172) then pressedKey = 1
                elseif IsControlJustPressed(0, 173) then pressedKey = 2
                elseif IsControlJustPressed(0, 174) then pressedKey = 3
                elseif IsControlJustPressed(0, 175) then pressedKey = 4
                end

                if pressedKey == requiredKey then
                    break
                elseif pressedKey then
                    success = false
                    break
                end

                if GetGameTimer() - start > 5000 then
                    success = false
                    break
                end
            end

            if not success then
                break
            end
        end

        isLockpicking = false
        if success then
            TriggerEvent("carrobbery:startRobbery")
        else
            DisplayHelpText("Lockpicking gagal! Coba lagi nanti.")
        end
    end)
end

-- Fungsi bantuan untuk menampilkan arah tombol
function getDirectionText(direction)
    if direction == 1 then
        return "atas"
    elseif direction == 2 then
        return "bawah"
    elseif direction == 3 then
        return "kiri"
    elseif direction == 4 then
        return "kanan"
    end
end

-- Fungsi untuk spawn kendaraan saat pencurian dimulai
function spawnRobberyVehicle()
    local vehicleModel = GetHashKey(Config.RobberyVehicle.model)
    RequestModel(vehicleModel)

    while not HasModelLoaded(vehicleModel) do
        Citizen.Wait(100)
    end

    if robberyVehicle then
        DeleteEntity(robberyVehicle)
    end

    robberyVehicle = CreateVehicle(vehicleModel, Config.RobberyVehicle.spawnLocation, Config.RobberyVehicle.heading, true, false)
    SetVehicleDoorsLocked(robberyVehicle, 1)
    SetVehicleAlarm(robberyVehicle, true)
    SetEntityAsMissionEntity(robberyVehicle, true, true)
end

-- Fungsi untuk membuat blip pencurian hanya untuk polisi
function createRobberyBlip()
    if robberyBlip == nil and isPolice then
        robberyBlip = AddBlipForCoord(Config.Blip.location.x, Config.Blip.location.y, Config.Blip.location.z)
        SetBlipSprite(robberyBlip, Config.Blip.sprite)
        SetBlipColour(robberyBlip, Config.Blip.color)
        SetBlipScale(robberyBlip, Config.Blip.scale)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Lokasi Pencurian Mobil")
        EndTextCommandSetBlipName(robberyBlip)
    end
end

-- Fungsi untuk menghapus blip pencurian
function removeRobberyBlip()
    if robberyBlip ~= nil then
        RemoveBlip(robberyBlip)
        robberyBlip = nil
    end
end

-- Mengecek pekerjaan pemain setiap beberapa detik
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)

        if Config.Framework == 'QBCore' then
            local PlayerData = QBCore.Functions.GetPlayerData()
            if PlayerData and PlayerData.job and PlayerData.job.name == Config.PoliceJobName then
                isPolice = true
                createRobberyBlip()
            else
                isPolice = false
                removeRobberyBlip()
            end
        elseif Config.Framework == 'ESX' then
            ESX.TriggerServerCallback('esx:getPlayerData', function(playerData)
                if playerData.job and playerData.job.name == Config.PoliceJobName then
                    isPolice = true
                    createRobberyBlip()
                else
                    isPolice = false
                    removeRobberyBlip()
                end
            end)
        end
    end
end)

-- Bersihkan blip ketika pemain keluar dari game
AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        removeRobberyBlip()
    end
end)

-- Thread untuk memeriksa interaksi pemain dengan NPC dan mengantarkan kendaraan
Citizen.CreateThread(function()
    spawnRobberyNPC()

    while true do
        Citizen.Wait(0)
        
        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)
        local npcCoords = Config.NPC.location
        local distance = #(playerCoords - npcCoords)

        if distance < 2.0 and not isInRobbery and not isLockpicking then
            DisplayHelpText("Tekan ~INPUT_CONTEXT~ untuk berbicara dengan dealer pencurian.")
            
            if IsControlJustPressed(0, 38) then
                startLockpickingGame()
            end
        end

        if isInRobbery then
            local deliveryCoords = Config.DeliveryLocation.coords
            DrawMarker(1, deliveryCoords.x, deliveryCoords.y, deliveryCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.DeliveryLocation.radius * 2, Config.DeliveryLocation.radius * 2, 1.0, 255, 0, 0, 100, false, true, 2, nil, nil, false)

            local deliveryDistance = #(playerCoords - Config.DeliveryLocation.coords)
            if deliveryDistance < Config.DeliveryLocation.radius and IsPedInVehicle(player, robberyVehicle, false) then
                DisplayHelpText("Tekan ~INPUT_CONTEXT~ untuk mengantarkan kendaraan dan mendapatkan hadiah.")

                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent("carrobbery:completeRobbery")

                    DeleteEntity(robberyVehicle)
                    robberyVehicle = nil
                    isInRobbery = false
                end
            end
        end
    end
end)

RegisterNetEvent("carrobbery:startRobbery")
AddEventHandler("carrobbery:startRobbery", function()
    spawnRobberyVehicle()
    isInRobbery = true
end)
