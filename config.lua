-- config.lua

Config = {}

-- Pilih framework yang digunakan: 'QBCore' atau 'ESX'
Config.Framework = 'QBCore' -- Ubah menjadi 'ESX' jika menggunakan ESX

-- Model dan Lokasi NPC
Config.NPC = {
    model = "s_m_y_dealer_01", -- Model NPC
    location = vector3(-707.75, -914.89, 19.21) -- Lokasi NPC
}

-- Item yang dibutuhkan untuk memulai pencurian
Config.RequiredItem = "lockpick"

-- Pengaturan hadiah untuk pencurian
Config.Rewards = {
    cash = { min = 500, max = 1000 },
    items = {
        { name = "lockpick", chance = 50 },
        { name = "scrap_metal", chance = 30 }
    }
}

-- Cooldown dalam detik untuk pencurian berikutnya
Config.RobberyCooldown = 600

-- Peluang keberhasilan pencurian (dalam persen)
Config.SuccessChance = 75

-- Pengaturan kendaraan yang muncul saat pencurian dimulai
Config.RobberyVehicle = {
    model = "sultan",
    spawnLocation = vector3(-711.0, -915.0, 19.0),
    heading = 180.0
}

-- Lokasi Pengantaran
Config.DeliveryLocation = {
    coords = vector3(-42.4, -1097.5, 26.4),
    radius = 5.0
}

-- Blip untuk polisi
Config.Blip = {
    sprite = 161,
    color = 1,
    scale = 1.0,
    location = Config.NPC.location
}

-- Job yang dapat melihat blip pencurian
Config.PoliceJobName = "police"
