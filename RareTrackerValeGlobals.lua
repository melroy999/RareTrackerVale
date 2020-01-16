-- Redefine often used functions locally.
local GetLocale = GetLocale

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The zones in which the addon is active.
RTV.target_zones = {
    [1530] = true
}
RTV.parent_zone = 1530

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
RTV.banned_NPC_ids = {
    [154297] = true,
    [150202] = true,
    [154304] = true,
    [152108] = true,
    [151300] = true,
    [151310] = true,
    [69792] = true,
    [62821] = true,
    [62822] = true,
    [32639] = true,
    [32638] = true,
    [89715] = true,
}

-- Simulate a set data structure for efficient existence lookups.
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- The ids of the rares the addon monitors.
RTV.rare_ids = {
    160825, -- "Amber-Shaper Esh'ri"
    157466, -- "Anh-De the Loyal"
    154447, -- "Brother Meller"
    160878, -- "Buh'gzaki the Blasphemous"
    160893, -- "Captain Vor'lek"
    154467, -- "Chief Mek-mek"
    157183, -- "Coagulated Anima"
    154559, -- "Deeplord Zrihj"
    160872, -- "Destroyer Krox'tazar"
    157287, -- "Dokani Obliterator"
    160874, -- "Drone Keeper Ak'thet"
    160876, -- "Enraged Amber Elemental"
    157267, -- "Escaped Mutation"
    157153, -- "Ha-Li"
    160810, -- "Harbinger Il'koxik"
    160868, -- "Harrier Nir'verash"
    157171, -- "Heixi the Stonelord"
    160826, -- "Hive-Guard Naz'ruzek"
    157160, -- "Houndlord Ren"
    160930, -- "Infused Amber Ooze"
    160968, -- "Jade Colossus"
    157290, -- "Jade Watcher"
    160920, -- "Kal'tik the Blight"
    157266, -- "Kilxl the Gaping Maw"
    160867, -- "Kzit'kovok"
    160922, -- "Needler Zhesalla"
    154106, -- "Quid"
    157162, -- "Rei Lun"
    154490, -- "Rijz'x the Devourer"
    156083, -- "Sanguifang"
    157291, -- "Spymaster Hul'ach"
    157279, -- "Stormhowl"
    156424, -- "Tashara"
    154600, -- "Teng the Awakened"
    157176, -- "The Forgotten"
    157468, -- "Tisiphon"
    154394, -- "Veskan the Fallen"
    154332, -- "Voidtender Malketh"
    154495, -- "Will of N'Zoth"
    157443, -- "Xiln the Mountain"
    154087, -- "Zror'um the Infinite"
}

-- Create a table, such that we can look up a rare in constant time.
RTV.rare_ids_set = Set(RTV.rare_ids)

-- Group rares by the assaults they are active in.
-- Notes: used the values found in the HandyNotes_VisionsOfNZoth addon.
RTV.assault_rare_ids = {
    [3155826] = Set({ -- West (MAN)
        160825,
        160878,
        160893,
        160872,
        160874,
        160876,
        160810,
        160868,
        160826,
        160930,
        160920,
        160867,
        160922,
        157468,
    }),
    [3155832] = Set({ -- Mid (MOG)
        157466,
        157183,
        157287,
        157153,
        157171,
        157160,
        160968,
        157290,
        157162,
        156083,
        157291,
        157279,
        156424,
        154600,
        157468,
        157443,
    }),
    [3155841] = Set({ -- East (EMP)
        154447,
        154467,
        154559,
        157267,
        157266,
        154106,
        154490,
        157176,
        157468,
        154394,
        154332,
        154495,
        154087,
    })
}

-- Get the rare names in the correct localization.
RTV.localization = GetLocale()
RTV.rare_names = {}

-- The names to be displayed in the frames and general chat messages for the English localizations.
RTV.rare_names = {
    [160825] = "Amber-Shaper Esh'ri",
    [157466] = "Anh-De the Loyal",
    [154447] = "Brother Meller",
    [160878] = "Buh'gzaki the Blasphemous",
    [160893] = "Captain Vor'lek",
    [154467] = "Chief Mek-mek",
    [157183] = "Coagulated Anima",
    [154559] = "Deeplord Zrihj",
    [160872] = "Destroyer Krox'tazar",
    [157287] = "Dokani Obliterator",
    [160874] = "Drone Keeper Ak'thet",
    [160876] = "Enraged Amber Elemental",
    [157267] = "Escaped Mutation",
    [157153] = "Ha-Li",
    [160810] = "Harbinger Il'koxik",
    [160868] = "Harrier Nir'verash",
    [157171] = "Heixi the Stonelord",
    [160826] = "Hive-Guard Naz'ruzek",
    [157160] = "Houndlord Ren",
    [160930] = "Infused Amber Ooze",
    [160968] = "Jade Colossus",
    [157290] = "Jade Watcher",
    [160920] = "Kal'tik the Blight",
    [157266] = "Kilxl the Gaping Maw",
    [160867] = "Kzit'kovok",
    [160922] = "Needler Zhesalla",
    [154106] = "Quid",
    [157162] = "Rei Lun",
    [154490] = "Rijz'x the Devourer",
    [156083] = "Sanguifang",
    [157291] = "Spymaster Hul'ach",
    [157279] = "Stormhowl",
    [156424] = "Tashara",
    [154600] = "Teng the Awakened",
    [157176] = "The Forgotten",
    [157468] = "Tisiphon",
    [154394] = "Veskan the Fallen",
    [154332] = "Voidtender Malketh",
    [154495] = "Will of N'Zoth",
    [157443] = "Xiln the Mountain",
    [154087] = "Zror'um the Infinite",
}

-- Overrides for display names of rares that are too long.
local rare_display_name_overwrites = {}

rare_display_name_overwrites["enUS"] = {}
rare_display_name_overwrites["enGB"] = {}
rare_display_name_overwrites["itIT"] = {}
rare_display_name_overwrites["frFR"] = {}
rare_display_name_overwrites["zhCN"] = {}
rare_display_name_overwrites["zhTW"] = {}
rare_display_name_overwrites["koKR"] = {}
rare_display_name_overwrites["deDE"] = {}
rare_display_name_overwrites["esES"] = {}
rare_display_name_overwrites["esMX"] = rare_display_name_overwrites["esES"]
rare_display_name_overwrites["ptPT"] = {}
rare_display_name_overwrites["ptBR"] = rare_display_name_overwrites["ptPT"]
rare_display_name_overwrites["ruRU"] = {}

RTV.rare_display_names = {}
for key, value in pairs(RTV.rare_names) do
    if rare_display_name_overwrites[RTV.localization][key] then
        RTV.rare_display_names[key] = rare_display_name_overwrites[RTV.localization][key]
    else
        RTV.rare_display_names[key] = value
    end
end

-- The quest ids that indicate that the rare has been killed already.
RTV.completion_quest_ids = {
    [160825] = 58300, -- "Amber-Shaper Esh'ri"
    [157466] = 57363, -- "Anh-De the Loyal"
    [154447] = 56237, -- "Brother Meller"
    [160878] = 58307, -- "Buh'gzaki the Blasphemous"
    [160893] = 58308, -- "Captain Vor'lek"
    [154467] = 56255, -- "Chief Mek-mek"
    [157183] = 58296, -- "Coagulated Anima"
    [154559] = 56323, -- "Deeplord Zrihj"
    [160872] = 58304, -- "Destroyer Krox'tazar"
    [157287] = 57349, -- "Dokani Obliterator"
    [160874] = 58305, -- "Drone Keeper Ak'thet"
    [160876] = 58306, -- "Enraged Amber Elemental"
    [157267] = 57343, -- "Escaped Mutation"
    [157153] = 57344, -- "Ha-Li"
    [160810] = 58299, -- "Harbinger Il'koxik"
    [160868] = 58303, -- "Harrier Nir'verash"
    [157171] = 57347, -- "Heixi the Stonelord"
    [160826] = 58301, -- "Hive-Guard Naz'ruzek"
    [157160] = 57345, -- "Houndlord Ren"
    [160930] = 58312, -- "Infused Amber Ooze"
    [160968] = 58295, -- "Jade Colossus"
    [157290] = 57350, -- "Jade Watcher"
    [160920] = 58310, -- "Kal'tik the Blight"
    [157266] = 57341, -- "Kilxl the Gaping Maw"
    [160867] = 58302, -- "Kzit'kovok"
    [160922] = 58311, -- "Needler Zhesalla"
    [154106] = 56094, -- "Quid"
    [157162] = 57346, -- "Rei Lun"
    [154490] = 56302, -- "Rijz'x the Devourer"
    [156083] = 56954, -- "Sanguifang"
    [157291] = 57351, -- "Spymaster Hul'ach"
    [157279] = 57348, -- "Stormhowl"
    [156424] = 58507, -- "Tashara"
    [154600] = 56332, -- "Teng the Awakened"
    [157176] = 57342, -- "The Forgotten"
    [157468] = 57364, -- "Tisiphon"
    [154394] = 56213, -- "Veskan the Fallen"
    [154332] = 56183, -- "Voidtender Malketh"
    [154495] = 56303, -- "Will of N'Zoth"
    [157443] = 57358, -- "Xiln the Mountain"
    [154087] = 56084, -- "Zror'um the Infinite"
}

RTV.completion_quest_inverse = {
    [58300] = {160825}, -- "Amber-Shaper Esh'ri"
    [57363] = {157466}, -- "Anh-De the Loyal"
    [56237] = {154447}, -- "Brother Meller"
    [58307] = {160878}, -- "Buh'gzaki the Blasphemous"
    [58308] = {160893}, -- "Captain Vor'lek"
    [56255] = {154467}, -- "Chief Mek-mek"
    [58296] = {157183}, -- "Coagulated Anima"
    [56323] = {154559}, -- "Deeplord Zrihj"
    [58304] = {160872}, -- "Destroyer Krox'tazar"
    [57349] = {157287}, -- "Dokani Obliterator"
    [58305] = {160874}, -- "Drone Keeper Ak'thet"
    [58306] = {160876}, -- "Enraged Amber Elemental"
    [57343] = {157267}, -- "Escaped Mutation"
    [57344] = {157153}, -- "Ha-Li"
    [58299] = {160810}, -- "Harbinger Il'koxik"
    [58303] = {160868}, -- "Harrier Nir'verash"
    [57347] = {157171}, -- "Heixi the Stonelord"
    [58301] = {160826}, -- "Hive-Guard Naz'ruzek"
    [57345] = {157160}, -- "Houndlord Ren"
    [58312] = {160930}, -- "Infused Amber Ooze"
    [58295] = {160968}, -- "Jade Colossus"
    [57350] = {157290}, -- "Jade Watcher"
    [58310] = {160920}, -- "Kal'tik the Blight"
    [57341] = {157266}, -- "Kilxl the Gaping Maw"
    [58302] = {160867}, -- "Kzit'kovok"
    [58311] = {160922}, -- "Needler Zhesalla"
    [56094] = {154106}, -- "Quid"
    [57346] = {157162}, -- "Rei Lun"
    [56302] = {154490}, -- "Rijz'x the Devourer"
    [56954] = {156083}, -- "Sanguifang"
    [57351] = {157291}, -- "Spymaster Hul'ach"
    [57348] = {157279}, -- "Stormhowl"
    [58507] = {156424}, -- "Tashara"
    [56332] = {154600}, -- "Teng the Awakened"
    [57342] = {157176}, -- "The Forgotten"
    [57364] = {157468}, -- "Tisiphon"
    [56213] = {154394}, -- "Veskan the Fallen"
    [56183] = {154332}, -- "Voidtender Malketh"
    [56303] = {154495}, -- "Will of N'Zoth"
    [57358] = {157443}, -- "Xiln the Mountain"
    [56084] = {154087}, -- "Zror'um the Infinite"
}

-- Certain npcs have yell emotes to announce their arrival.
local yell_announcing_rares = {}

-- Concert the ids above to the names.
RTV.yell_announcing_rares = {}
for key, value in pairs(yell_announcing_rares) do
    RTV.yell_announcing_rares[RTV.rare_names[key]] = value
end

-- A set of placeholder icons, which will be used if the rare location is not yet known.
RTV.rare_coordinates = {

}