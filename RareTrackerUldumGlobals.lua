-- Redefine often used functions locally.
local GetLocale = GetLocale

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The zones in which the addon is active.
RTU.target_zones = {
    [1527] = true
}

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
RTU.banned_NPC_ids = {
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
RTU.rare_ids = {
    157170, -- "Acolyte Taspu",
    158557, -- "Actiss the Deceiver",
    151883, -- "Anaua",
    155703, -- "Anq'uri the Titanic",
    154578, -- "Aqir Flayer",
    154576, -- "Aqir Titanus",
    162172, -- "Aqir Warcaster",
    162370, -- "Armagedillo",
    152757, -- "Atekhramun",
    162171, -- "Captain Dunewalker",
    162147, -- "Corpse Eater",
    158594, -- "Doomsayer Vathiris",
    158491, -- "Falconer Amenophis",
    157120, -- "Fangtaker Orsa",
    158633, -- "Gaze of N'Zoth",
    158597, -- "High Executor Yothrim",
    158528, -- "High Guard Reshef",
    162163, -- "High Priest Ytaessis",
    151995, -- "Hik-Ten the Taskmaster",
    160623, -- "Hungering Miasma",
    155531, -- "Infested Wastewander Captain",
    157134, -- "Ishak of the Four Winds",
    156655, -- "Korzaran the Slaughterer",
    154604, -- "Lord Aj'qirai",
    156078, -- "Magus Rehleth",
    157157, -- "Muminah the Incandescent",
    152677, -- "Nebet the Ascended",
    162196, -- "Obsidian Annihilator",
    162142, -- "Qho",
    156299, -- "R'khuzj the Unfathomable",
    162173, -- "R'krox the Runt",
    157146, -- "Rotfeaster",
    152040, -- "Scoutmaster Moswen",
    151948, -- "Senbu the Pridefather",
    161033, -- "Shadowmaw",
    156654, -- "Shol'thoss the Doomspeaker",
    160532, -- "Shoth the Darkened",
    162140, -- "Skikx'traz",
    162372, -- "Spirit of Cyrus the Black",
    162352, -- "Spirit of Dark Ritualist Zakahn",
    151878, -- "Sun King Nahkotep",
    151897, -- "Sun Priestess Nubitt",
    151609, -- "Sun Prophet Epaphos",
    152657, -- "Tat the Bonechewer",
    158636, -- "The Grand Executor",
    162170, -- "Warcaster Xeshro",
    151852, -- "Watcher Rehu",
    157164, -- "Zealot Tekem",
    162141, -- "Zuythiz",
}

-- Create a table, such that we can look up a rare in constant time.
RTU.rare_ids_set = Set(RTU.rare_ids)

-- Get the rare names in the correct localization.
RTU.localization = GetLocale()
RTU.rare_names = {}

-- The names to be displayed in the frames and general chat messages for the English localizations.
RTU.rare_names = {
    [157170] = "Acolyte Taspu",
    [158557] = "Actiss the Deceiver",
    [151883] = "Anaua",
    [155703] = "Anq'uri the Titanic",
    [154578] = "Aqir Flayer",
    [154576] = "Aqir Titanus",
    [162172] = "Aqir Warcaster",
    [162370] = "Armagedillo",
    [152757] = "Atekhramun",
    [162171] = "Captain Dunewalker",
    [162147] = "Corpse Eater",
    [158594] = "Doomsayer Vathiris",
    [158491] = "Falconer Amenophis",
    [157120] = "Fangtaker Orsa",
    [158633] = "Gaze of N'Zoth",
    [158597] = "High Executor Yothrim",
    [158528] = "High Guard Reshef",
    [162163] = "High Priest Ytaessis",
    [151995] = "Hik-Ten the Taskmaster",
    [160623] = "Hungering Miasma",
    [155531] = "Infested Wastewander Captain",
    [157134] = "Ishak of the Four Winds",
    [156655] = "Korzaran the Slaughterer",
    [154604] = "Lord Aj'qirai",
    [156078] = "Magus Rehleth",
    [157157] = "Muminah the Incandescent",
    [152677] = "Nebet the Ascended",
    [162196] = "Obsidian Annihilator",
    [162142] = "Qho",
    [156299] = "R'khuzj the Unfathomable",
    [162173] = "R'krox the Runt",
    [157146] = "Rotfeaster",
    [152040] = "Scoutmaster Moswen",
    [151948] = "Senbu the Pridefather",
    [161033] = "Shadowmaw",
    [156654] = "Shol'thoss the Doomspeaker",
    [160532] = "Shoth the Darkened",
    [162140] = "Skikx'traz",
    [162372] = "Spirit of Cyrus the Black",
    [162352] = "Spirit of Dark Ritualist Zakahn",
    [151878] = "Sun King Nahkotep",
    [151897] = "Sun Priestess Nubitt",
    [151609] = "Sun Prophet Epaphos",
    [152657] = "Tat the Bonechewer",
    [158636] = "The Grand Executor",
    [162170] = "Warcaster Xeshro",
    [151852] = "Watcher Rehu",
    -- [157473] = "Yiphrim the Will Ravager",
    [157164] = "Zealot Tekem",
    [162141] = "Zuythiz",
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

RTU.rare_display_names = {}
for key, value in pairs(RTU.rare_names) do
    if rare_display_name_overwrites[RTU.localization][key] then
        RTU.rare_display_names[key] = rare_display_name_overwrites[RTU.localization][key]
    else
        RTU.rare_display_names[key] = value
    end
end

-- The quest ids that indicate that the rare has been killed already.
RTU.completion_quest_ids = {
    [157170] = 57281, -- "Acolyte Taspu"
    [158557] = 57669, -- "Actiss the Deceiver"
    [151883] = 55468, -- "Anaua"
    [155703] = 56834, -- "Anq'uri the Titanic"
    [154578] = 58612, -- "Aqir Flayer"
    [154576] = 58614, -- "Aqir Titanus"
    [162172] = 58694, -- "Aqir Warcaster"
    [162370] = 58718, -- "Armagedillo"
    [152757] = 55710, -- "Atekhramun"
    [162171] = 58699, -- "Captain Dunewalker"
    [162147] = 58696, -- "Corpse Eater"
    [158594] = 57672, -- "Doomsayer Vathiris"
    [158491] = 57662, -- "Falconer Amenophis"
    [157120] = 57258, -- "Fangtaker Orsa"
    [158633] = 57680, -- "Gaze of N'Zoth"
    [158597] = 57675, -- "High Executor Yothrim"
    [158528] = 57664, -- "High Guard Reshef"
    [162163] = 58701, -- "High Priest Ytaessis"
    [151995] = 55502, -- "Hik-Ten the Taskmaster"
    [160623] = 58206, -- "Hungering Miasma"
    [155531] = 56823, -- "Infested Wastewander Captain"
    [157134] = 57259, -- "Ishak of the Four Winds"
    [156655] = 57433, -- "Korzaran the Slaughterer"
    [154604] = 56340, -- "Lord Aj'qirai"
    [156078] = 56952, -- "Magus Rehleth"
    [157157] = 57277, -- "Muminah the Incandescent"
    [152677] = 55684, -- "Nebet the Ascended"
    [162196] = 58681, -- "Obsidian Annihilator"
    [162142] = 58693, -- "Qho"
    [156299] = 57430, -- "R'khuzj the Unfathomable"
    [162173] = 58864, -- "R'krox the Runt"
    [157146] = 57273, -- "Rotfeaster"
    [152040] = 55518, -- "Scoutmaster Moswen"
    [151948] = 55496, -- "Senbu the Pridefather"
    [161033] = 58333, -- "Shadowmaw"
    [156654] = 57432, -- "Shol'thoss the Doomspeaker"
    [160532] = 58169, -- "Shoth the Darkened"
    [162140] = 58697, -- "Skikx'traz"
    [162372] = 58715, -- "Spirit of Cyrus the Black"
    [162352] = 58716, -- "Spirit of Dark Ritualist Zakahn"
    [151878] = 58613, -- "Sun King Nahkotep"
    [151897] = 55479, -- "Sun Priestess Nubitt"
    [151609] = 55353, -- "Sun Prophet Epaphos"
    [152657] = 55682, -- "Tat the Bonechewer"
    [158636] = 57688, -- "The Grand Executor"
    [162170] = 58702, -- "Warcaster Xeshro"
    [151852] = 55461, -- "Watcher Rehu"
    -- [157473] = ? -- "Yiphrim the Will Ravager"
    [157164] = 57279, -- "Zealot Tekem"
    [162141] = 58695, -- "Zuythiz"
}

RTU.completion_quest_inverse = {
    --[55512] = {151934},
    [57281] = {157170}, -- "Acolyte Taspu"
    [57669] = {158557}, -- "Actiss the Deceiver"
    [55468] = {151883}, -- "Anaua"
    [56834] = {155703}, -- "Anq'uri the Titanic"
    [58612] = {154578}, -- "Aqir Flayer"
    [58614] = {154576}, -- "Aqir Titanus"
    [58694] = {162172}, -- "Aqir Warcaster"
    [58718] = {162370}, -- "Armagedillo"
    [55710] = {152757}, -- "Atekhramun"
    [58699] = {162171}, -- "Captain Dunewalker"
    [58696] = {162147}, -- "Corpse Eater"
    [57672] = {158594}, -- "Doomsayer Vathiris"
    [57662] = {158491}, -- "Falconer Amenophis"
    [57258] = {157120}, -- "Fangtaker Orsa"
    [57680] = {158633}, -- "Gaze of N'Zoth"
    [57675] = {158597}, -- "High Executor Yothrim"
    [57664] = {158528}, -- "High Guard Reshef"
    [58701] = {162163}, -- "High Priest Ytaessis"
    [55502] = {151995}, -- "Hik-Ten the Taskmaster"
    [58206] = {160623}, -- "Hungering Miasma"
    [56823] = {155531}, -- "Infested Wastewander Captain"
    [57259] = {157134}, -- "Ishak of the Four Winds"
    [57433] = {156655}, -- "Korzaran the Slaughterer"
    [56340] = {154604}, -- "Lord Aj'qirai"
    [56952] = {156078}, -- "Magus Rehleth"
    [57277] = {157157}, -- "Muminah the Incandescent"
    [55684] = {152677}, -- "Nebet the Ascended"
    [58681] = {162196}, -- "Obsidian Annihilator"
    [58693] = {162142}, -- "Qho"
    [57430] = {156299}, -- "R'khuzj the Unfathomable"
    [58864] = {162173}, -- "R'krox the Runt"
    [57273] = {157146}, -- "Rotfeaster"
    [55518] = {152040}, -- "Scoutmaster Moswen"
    [55496] = {151948}, -- "Senbu the Pridefather"
    [58333] = {161033}, -- "Shadowmaw"
    [57432] = {156654}, -- "Shol'thoss the Doomspeaker"
    [58169] = {160532}, -- "Shoth the Darkened"
    [58697] = {162140}, -- "Skikx'traz"
    [58715] = {162372}, -- "Spirit of Cyrus the Black"
    [58716] = {162352}, -- "Spirit of Dark Ritualist Zakahn"
    [58613] = {151878}, -- "Sun King Nahkotep"
    [55479] = {151897}, -- "Sun Priestess Nubitt"
    [55353] = {151609}, -- "Sun Prophet Epaphos"
    [55682] = {152657}, -- "Tat the Bonechewer"
    [57688] = {158636}, -- "The Grand Executor"
    [58702] = {162170}, -- "Warcaster Xeshro"
    [55461] = {151852}, -- "Watcher Rehu"
    [57279] = {157164}, -- "Zealot Tekem"
    [58695] = {162141}, -- "Zuythiz"
}

-- Certain npcs have yell emotes to announce their arrival.
local yell_announcing_rares = {}

-- Concert the ids above to the names.
RTU.yell_announcing_rares = {}
for key, value in pairs(yell_announcing_rares) do
    RTU.yell_announcing_rares[RTU.rare_names[key]] = value
end

-- Link drill codes to their respective entities.
RTU.drill_announcing_rares = {}

-- A set of placeholder icons, which will be used if the rare location is not yet known.
RTU.rare_coordinates = {
    -- [157170] = {["x"] = -1, ["y"] = -1}, -- "Acolyte Taspu"
    -- [158557] = {["x"] = -1, ["y"] = -1}, -- "Actiss the Deceiver"
    -- [151883] = {["x"] = -1, ["y"] = -1}, -- "Anaua"
    -- [155703] = {["x"] = -1, ["y"] = -1}, -- "Anq'uri the Titanic"
    -- [154578] = {["x"] = -1, ["y"] = -1}, -- "Aqir Flayer"
    -- [154576] = {["x"] = -1, ["y"] = -1}, -- "Aqir Titanus"
    -- [162172] = {["x"] = -1, ["y"] = -1}, -- "Aqir Warcaster"
    -- [162370] = {["x"] = -1, ["y"] = -1}, -- "Armagedillo"
    -- [152757] = {["x"] = -1, ["y"] = -1}, -- "Atekhramun"
    -- [162171] = {["x"] = -1, ["y"] = -1}, -- "Captain Dunewalker"
    -- [162147] = {["x"] = -1, ["y"] = -1}, -- "Corpse Eater"
    -- [158594] = {["x"] = -1, ["y"] = -1}, -- "Doomsayer Vathiris"
    -- [158491] = {["x"] = -1, ["y"] = -1}, -- "Falconer Amenophis"
    -- [157120] = {["x"] = -1, ["y"] = -1}, -- "Fangtaker Orsa"
    -- [158633] = {["x"] = -1, ["y"] = -1}, -- "Gaze of N'Zoth"
    -- [158597] = {["x"] = -1, ["y"] = -1}, -- "High Executor Yothrim"
    -- [158528] = {["x"] = -1, ["y"] = -1}, -- "High Guard Reshef"
    -- [162163] = {["x"] = -1, ["y"] = -1}, -- "High Priest Ytaessis"
    -- [151995] = {["x"] = -1, ["y"] = -1}, -- "Hik-Ten the Taskmaster"
    -- [160623] = {["x"] = -1, ["y"] = -1}, -- "Hungering Miasma"
    -- [155531] = {["x"] = -1, ["y"] = -1}, -- "Infested Wastewander Captain"
    -- [157134] = {["x"] = -1, ["y"] = -1}, -- "Ishak of the Four Winds"
    -- [156655] = {["x"] = -1, ["y"] = -1}, -- "Korzaran the Slaughterer"
    -- [154604] = {["x"] = -1, ["y"] = -1}, -- "Lord Aj'qirai"
    -- [156078] = {["x"] = -1, ["y"] = -1}, -- "Magus Rehleth"
    -- [157157] = {["x"] = -1, ["y"] = -1}, -- "Muminah the Incandescent"
    -- [152677] = {["x"] = -1, ["y"] = -1}, -- "Nebet the Ascended"
    -- [162196] = {["x"] = -1, ["y"] = -1}, -- "Obsidian Annihilator"
    -- [162142] = {["x"] = -1, ["y"] = -1}, -- "Qho"
    -- [156299] = {["x"] = -1, ["y"] = -1}, -- "R'khuzj the Unfathomable"
    -- [162173] = {["x"] = -1, ["y"] = -1}, -- "R'krox the Runt"
    -- [157146] = {["x"] = -1, ["y"] = -1}, -- "Rotfeaster"
    -- [152040] = {["x"] = -1, ["y"] = -1}, -- "Scoutmaster Moswen"
    -- [151948] = {["x"] = -1, ["y"] = -1}, -- "Senbu the Pridefather"
    -- [161033] = {["x"] = -1, ["y"] = -1}, -- "Shadowmaw"
    -- [156654] = {["x"] = -1, ["y"] = -1}, -- "Shol'thoss the Doomspeaker"
    -- [160532] = {["x"] = -1, ["y"] = -1}, -- "Shoth the Darkened"
    -- [162140] = {["x"] = -1, ["y"] = -1}, -- "Skikx'traz"
    -- [162372] = {["x"] = -1, ["y"] = -1}, -- "Spirit of Cyrus the Black"
    -- [162352] = {["x"] = -1, ["y"] = -1}, -- "Spirit of Dark Ritualist Zakahn"
    -- [151878] = {["x"] = -1, ["y"] = -1}, -- "Sun King Nahkotep"
    -- [151897] = {["x"] = -1, ["y"] = -1}, -- "Sun Priestess Nubitt"
    -- [151609] = {["x"] = -1, ["y"] = -1}, -- "Sun Prophet Epaphos"
    -- [152657] = {["x"] = -1, ["y"] = -1}, -- "Tat the Bonechewer"
    -- [158636] = {["x"] = -1, ["y"] = -1}, -- "The Grand Executor"
    -- [162170] = {["x"] = -1, ["y"] = -1}, -- "Warcaster Xeshro"
    -- [151852] = {["x"] = -1, ["y"] = -1}, -- "Watcher Rehu"
    -- [157164] = {["x"] = -1, ["y"] = -1}, -- "Zealot Tekem"
    -- [162141] = {["x"] = -1, ["y"] = -1}, -- "Zuythiz"
}