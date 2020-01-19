-- Redefine often used functions locally.
local GetLocale = GetLocale

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The zones in which the addon is active.
RTV.target_zones = {
    [1530] = true,
    [1579] = true,
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
    159087, -- "Corrupted Bonestripper"
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
    160906, -- "Skiver"
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
        160906, -- "Skiver"
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
        160906, -- "Skiver"
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
        159087, -- "Corrupted Bonestripper"
        160906, -- "Skiver"
    })
}

-- Get the rare names in the correct localization.
RTV.localization = GetLocale()
RTV.rare_names = {}

if RTV.localization == "frFR" then
    -- The names to be displayed in the frames and general chat messages for the French localization.
    RTV.rare_names = {
        [160825] = "Sculpte-ambre Esh'ri",
        [157466] = "Anh De le Loyal",
        [154447] = "Frère Meller",
        [160878] = "Buh'gzaki le Blasphémateur",
        [160893] = "Capitaine Vor'lek",
        [154467] = "Chef Mek-mek",
        [157183] = "Anima coagulée",
        [159087] = "Gratte-les-os corrompu",
        [154559] = "Seigneur des profondeurs Zrihj",
        [160872] = "Destructeur Krox'tazar",
        [157287] = "Oblitérateur dokani",
        [160874] = "Garde-bourdons Ak'thet",
        [160876] = "Elémentaire d'ambre enragé",
        [157267] = "Mutant évadé",
        [157153] = "Ha Li",
        [160810] = "Messager Il'koxik",
        [160868] = "Traqueur Nir'verash",
        [157171] = "Heixi le Seigneur de pierre",
        [160826] = "Garde-ruche Naz'ruzek",
        [157160] = "Grand-veneur Ren",
        [160930] = "Limon d'ambre imprégné",
        [160968] = "Colosse de jade",
        [157290] = "Guetteur de jade",
        [160920] = "Kal'tik le Chancre",
        [157266] = "Kilxl la Gueule béante",
        [160867] = "Kzit'kovok",
        [160922] = "Piqueur Zhesalla",
        [154106] = "Quid",
        [157162] = "Rei Lun",
        [154490] = "Rijz'x le Dévoreur",
        [156083] = "Croc-Sanglant",
        [160906] = "Cossard",
        [157291] = "Maître-espion Hul'ach",
        [157279] = "Tempête-hurlante",
        [156424] = "Tashara",
        [154600] = "Teng l'Eveillé",
        [157176] = "L'Oubliée",
        [157468] = "Tisiphon",
        [154394] = "Veskan le Déchu",
        [154332] = "Porteur du Vide Malketh",
        [154495] = "Volonté de N'Zoth",
        [157443] = "Xiln la Montagne",
        [154087] = "Zror'um l'Infini",
    }
elseif RTV.localization == "deDE" then
    -- The names to be displayed in the frames and general chat messages for the German localization.
    RTV.rare_names = {
        [160825] = "Bernformer Esh'ri",
        [157466] = "Anh-De der Loyale",
        [154447] = "Bruder Meller",
        [160878] = "Buh'gzaki der Blasphemiker",
        [160893] = "Hauptmann Vor'lek",
        [154467] = "Häuptling Mek-mek",
        [157183] = "Geronnene Anima",
        [159087] = "Verderbter Knochenhäuter",
        [154559] = "Tiefenfürst Zrihj",
        [160872] = "Zerstörer Krox'tazar",
        [157287] = "Auslöscher der Dokani",
        [160874] = "Drohnenhüter Ak'thet",
        [160876] = "Wütender Bernelementar",
        [157267] = "Entflohene Mutation",
        [157153] = "Ha-Li",
        [160810] = "Herold Il'koxik",
        [160868] = "Hetzer Nir'verash",
        [157171] = "Heixi der Steinfürst",
        [160826] = "Stockwache Naz'ruzek",
        [157160] = "Hundmeister Ren",
        [160930] = "Durchströmter Bernschlamm",
        [160968] = "Jadekoloss",
        [157290] = "Jadebeobachter",
        [160920] = "Kal'tik der Veröder",
        [157266] = "Kilxl das Klaffende Maul",
        [160867] = "Kzit'kovok",
        [160922] = "Nadler Zhesalla",
        [154106] = "Kwall",
        [157162] = "Rei Lun",
        [154490] = "Rijz'x der Verschlinger",
        [156083] = "Sanguifang",
        [160906] = "Schlitzer",
        [157291] = "Meisterspion Hul'ach",
        [157279] = "Sturmgeheul",
        [156424] = "Tashara",
        [154600] = "Teng der Erweckte",
        [157176] = "Die Vergessenen",
        [157468] = "Tisiphon",
        [154394] = "Veskan der Gefallene",
        [154332] = "Leerenhüter Malketh",
        [154495] = "Wille von N'Zoth",
        [157443] = "Xiln der Berg",
        [154087] = "Zror'um der Unendliche",
    }
else
    -- The names to be displayed in the frames and general chat messages for the English localizations.
    RTV.rare_names = {
        [160825] = "Amber-Shaper Esh'ri",
        [157466] = "Anh-De the Loyal",
        [154447] = "Brother Meller",
        [160878] = "Buh'gzaki the Blasphemous",
        [160893] = "Captain Vor'lek",
        [154467] = "Chief Mek-mek",
        [157183] = "Coagulated Anima",
        [159087] = "Corrupted Bonestripper",
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
        [160906] = "Skiver",
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
end

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
    [159087] = 57834, -- "Corrupted Bonestripper"
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
    [160906] = 58309, -- "Skiver"
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
    [57834] = {159087}, -- "Corrupted Bonestripper"
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
    [58309] = {160906}, -- "Skiver"
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
    [160825] = {["x"] = 20, ["y"] = 75}, -- "Amber-Shaper Esh'ri"
    [157466] = {["x"] = 34, ["y"] = 68}, -- "Anh-De the Loyal"
    [154447] = {["x"] = 57, ["y"] = 41}, -- "Brother Meller"
    [160878] = {["x"] = 6, ["y"] = 70}, -- "Buh'gzaki the Blasphemous"
    [160893] = {["x"] = 6, ["y"] = 64}, -- "Captain Vor'lek"
    [154467] = {["x"] = 81, ["y"] = 65}, -- "Chief Mek-mek"
    [157183] = {["x"] = 19, ["y"] = 68}, -- "Coagulated Anima"
    -- [159087], -- Corrupted Bonestripper
    [154559] = {["x"] = 67, ["y"] = 68}, -- "Deeplord Zrihj"
    [160872] = {["x"] = 27, ["y"] = 67}, -- "Destroyer Krox'tazar"
    [157287] = {["x"] = 42, ["y"] = 57}, -- "Dokani Obliterator"
    [160874] = {["x"] = 12, ["y"] = 41}, -- "Drone Keeper Ak'thet"
    [160876] = {["x"] = 10, ["y"] = 41}, -- "Enraged Amber Elemental"
    [157267] = {["x"] = 45, ["y"] = 45}, -- "Escaped Mutation"
    [157153] = {["x"] = 30, ["y"] = 38}, -- "Ha-Li"
    [160810] = {["x"] = 29, ["y"] = 53}, -- "Harbinger Il'koxik"
    [160868] = {["x"] = 13, ["y"] = 51}, -- "Harrier Nir'verash"
    [157171] = {["x"] = 28, ["y"] = 40}, -- "Heixi the Stonelord"
    [160826] = {["x"] = 20, ["y"] = 61}, -- "Hive-Guard Naz'ruzek"
    [157160] = {["x"] = 12, ["y"] = 31}, -- "Houndlord Ren"
    [160930] = {["x"] = 18, ["y"] = 66}, -- "Infused Amber Ooze"
    [160968] = {["x"] = 17, ["y"] = 12}, -- "Jade Colossus"
    [157290] = {["x"] = 27, ["y"] = 11}, -- "Jade Watcher"
    [160920] = {["x"] = 18, ["y"] = 9}, -- "Kal'tik the Blight"
    [157266] = {["x"] = 46, ["y"] = 59}, -- "Kilxl the Gaping Maw"
    [160867] = {["x"] = 26, ["y"] = 38}, -- "Kzit'kovok"
    [160922] = {["x"] = 15, ["y"] = 37}, -- "Needler Zhesalla"
    [154106] = {["x"] = 90, ["y"] = 46}, -- "Quid"
    [157162] = {["x"] = 22, ["y"] = 12}, -- "Rei Lun"
    [154490] = {["x"] = 64, ["y"] = 52}, -- "Rijz'x the Devourer"
    [156083] = {["x"] = 46, ["y"] = 57}, -- "Sanguifang"
    [160906] = {["x"] = 27, ["y"] = 43}, -- "Skiver"
    [157291] = {["x"] = 18, ["y"] = 38}, -- "Spymaster Hul'ach"
    [157279] = {["x"] = 26, ["y"] = 75}, -- "Stormhowl"
    [156424] = {["x"] = 29, ["y"] = 22}, -- "Tashara"
    [154600] = {["x"] = 47, ["y"] = 64}, -- "Teng the Awakened"
    [157176] = {["x"] = 52, ["y"] = 42}, -- "The Forgotten"
    [157468] = {["x"] = 10, ["y"] = 67}, -- "Tisiphon"
    [154394] = {["x"] = 87, ["y"] = 42}, -- "Veskan the Fallen"
    [154332] = {["x"] = 67, ["y"] = 28}, -- "Voidtender Malketh"
    [154495] = {["x"] = 53, ["y"] = 62}, -- "Will of N'Zoth"
    [157443] = {["x"] = 54, ["y"] = 49}, -- "Xiln the Mountain"
    [154087] = {["x"] = 71, ["y"] = 41}, -- "Zror'um the Infinite"
}