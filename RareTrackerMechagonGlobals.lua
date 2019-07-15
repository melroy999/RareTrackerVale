local _, data = ...

local RTM = data.RTM

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The zones in which the addon is active.
RTM.target_zones = {}
RTM.target_zones[1462] = true
RTM.target_zones[1522] = true

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
RTM.banned_NPC_ids = {}
RTM.banned_NPC_ids[154297] = true
RTM.banned_NPC_ids[150202] = true
RTM.banned_NPC_ids[154304] = true
RTM.banned_NPC_ids[152108] = true
RTM.banned_NPC_ids[151300] = true
RTM.banned_NPC_ids[151310] = true
RTM.banned_NPC_ids[69792] = true

-- Simulate a set data structure for efficient existence lookups.
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- The ids of the rares the addon monitors.
RTM.rare_ids = {
	151934, -- "Arachnoid Harvester"
	154342, -- "Arachnoid Harvester (F)"
	--150394, -- "Armored Vaultbot"
	151308, -- "Boggac Skullbash"
	153200, -- "Boilburn"
	152001, -- "Bonepicker"
	154739, -- "Caustic Mechaslime"
	152570, -- "Crazed Trogg (Blue)"
	152569, -- "Crazed Trogg (Green)"
	149847, -- "Crazed Trogg (Orange)"
	151569, -- "Deepwater Maw"
	--155060, -- "Doppel Ganger"
	150342, -- "Earthbreaker Gulroc"
	154153, -- "Enforcer KX-T57"
	151202, -- "Foul Manifestation"
	135497, -- "Fungarian Furor"
	153228, -- "Gear Checker Cogstar"
	153205, -- "Gemicide"
	154701, -- "Gorged Gear-Cruncher"
	151684, -- "Jawbreaker"
	152007, -- "Killsaw"
	151933, -- "Malfunctioning Beastbot"
	151124, -- "Mechagonian Nullifier"
	151672, -- "Mecharantula"
	151627, -- "Mr. Fixthis"
	153206, -- "Ol' Big Tusk"
	151296, -- "OOX-Avenger/MG"
	152764, -- "Oxidized Leachbeast"
	151702, -- "Paol Pondwader"
	150575, -- "Rumblerocks"
	152182, -- "Rustfeather"
	155583, -- "Scrapclaw"
	150937, -- "Seaspit"
	153000, -- "Sparkqueen P'Emp"
	153226, -- "Steel Singer Freza"
	152113, -- "The Kleptoboss"
	154225, -- "The Rusty Prince (F)"
	151623, -- "The Scrap King (M)"
	151625, -- "The Scrap King"
	151940, -- "Uncle T'Rogg"
}

-- Create a table, such that we can look up a rare in constant time.
RTM.rare_ids_set = Set(RTM.rare_ids)

-- The names to be displayed in the frames and general chat messages.
RTM.rare_names_localized = {}
RTM.rare_names_localized["enUS"] = {}
RTM.rare_names_localized["enUS"][151934] = "Arachnoid Harvester"
RTM.rare_names_localized["enUS"][154342] = "Arachnoid Harvester (F)"
RTM.rare_names_localized["enUS"][155060] = "Doppel Ganger"
RTM.rare_names_localized["enUS"][152113] = "The Kleptoboss"
RTM.rare_names_localized["enUS"][154225] = "The Rusty Prince (F)"
RTM.rare_names_localized["enUS"][151623] = "The Scrap King (M)"
RTM.rare_names_localized["enUS"][151625] = "The Scrap King"
RTM.rare_names_localized["enUS"][151940] = "Uncle T'Rogg"
RTM.rare_names_localized["enUS"][150394] = "Armored Vaultbot"
RTM.rare_names_localized["enUS"][153200] = "Boilburn"
RTM.rare_names_localized["enUS"][151308] = "Boggac Skullbash"
RTM.rare_names_localized["enUS"][152001] = "Bonepicker"
RTM.rare_names_localized["enUS"][154739] = "Caustic Mechaslime"
RTM.rare_names_localized["enUS"][149847] = "Crazed Trogg (Orange)"
RTM.rare_names_localized["enUS"][152569] = "Crazed Trogg (Green)"
RTM.rare_names_localized["enUS"][152570] = "Crazed Trogg (Blue)"
RTM.rare_names_localized["enUS"][151569] = "Deepwater Maw"
RTM.rare_names_localized["enUS"][150342] = "Earthbreaker Gulroc"
RTM.rare_names_localized["enUS"][154153] = "Enforcer KX-T57"
RTM.rare_names_localized["enUS"][151202] = "Foul Manifestation"
RTM.rare_names_localized["enUS"][135497] = "Fungarian Furor"
RTM.rare_names_localized["enUS"][153228] = "Gear Checker Cogstar"
RTM.rare_names_localized["enUS"][153205] = "Gemicide"
RTM.rare_names_localized["enUS"][154701] = "Gorged Gear-Cruncher"
RTM.rare_names_localized["enUS"][151684] = "Jawbreaker"
RTM.rare_names_localized["enUS"][152007] = "Killsaw"
RTM.rare_names_localized["enUS"][151933] = "Malfunctioning Beastbot"
RTM.rare_names_localized["enUS"][151124] = "Mechagonian Nullifier"
RTM.rare_names_localized["enUS"][151672] = "Mecharantula"
RTM.rare_names_localized["enUS"][151627] = "Mr. Fixthis"
RTM.rare_names_localized["enUS"][151296] = "OOX-Avenger/MG"
RTM.rare_names_localized["enUS"][153206] = "Ol' Big Tusk"
RTM.rare_names_localized["enUS"][152764] = "Oxidized Leachbeast"
RTM.rare_names_localized["enUS"][151702] = "Paol Pondwader"
RTM.rare_names_localized["enUS"][150575] = "Rumblerocks"
RTM.rare_names_localized["enUS"][152182] = "Rustfeather"
RTM.rare_names_localized["enUS"][155583] = "Scrapclaw"
RTM.rare_names_localized["enUS"][150937] = "Seaspit"
RTM.rare_names_localized["enUS"][153000] = "Sparkqueen P'Emp"
RTM.rare_names_localized["enUS"][153226] = "Steel Singer Freza"

-- The quest ids that indicate that the rare has been killed already.
RTM.completion_quest_ids = {}
RTM.completion_quest_ids[151934] = 55512 -- "Arachnoid Harvester"
RTM.completion_quest_ids[154342] = 55512 -- "Arachnoid Harvester (F)"
RTM.completion_quest_ids[155060] = 56419 -- "Doppel Ganger"
RTM.completion_quest_ids[152113] = 55858 -- "The Kleptoboss"
RTM.completion_quest_ids[154225] = 56182 -- "The Rusty Prince (F)"
RTM.completion_quest_ids[151623] = 55364 -- "The Scrap King (M)"
RTM.completion_quest_ids[151625] = 55364 -- "The Scrap King"
RTM.completion_quest_ids[151940] = 55538 -- "Uncle T'Rogg"
RTM.completion_quest_ids[150394] = 55546 -- "Armored Vaultbot"
RTM.completion_quest_ids[153200] = 55857 -- "Boilburn"
RTM.completion_quest_ids[151308] = 55539 -- "Boggac Skullbash"
RTM.completion_quest_ids[152001] = 55537 -- "Bonepicker"
RTM.completion_quest_ids[154739] = 56368 -- "Caustic Mechaslime"
RTM.completion_quest_ids[149847] = 55812 -- "Crazed Trogg (Orange)"
RTM.completion_quest_ids[152569] = 55812 -- "Crazed Trogg (Green)"
RTM.completion_quest_ids[152570] = 55812 -- "Crazed Trogg (Blue)"
RTM.completion_quest_ids[151569] = 55514 -- "Deepwater Maw"
RTM.completion_quest_ids[150342] = 55814 -- "Earthbreaker Gulroc"
RTM.completion_quest_ids[154153] = 56207 -- "Enforcer KX-T57"
RTM.completion_quest_ids[151202] = 55513 -- "Foul Manifestation"
RTM.completion_quest_ids[135497] = 55367 -- "Fungarian Furor"
RTM.completion_quest_ids[153228] = 55852 -- "Gear Checker Cogstar"
RTM.completion_quest_ids[153205] = 55855 -- "Gemicide"
RTM.completion_quest_ids[154701] = 56367 -- "Gorged Gear-Cruncher"
RTM.completion_quest_ids[151684] = 55399 -- "Jawbreaker"
RTM.completion_quest_ids[152007] = 55369 -- "Killsaw"
RTM.completion_quest_ids[151933] = 55544 -- "Malfunctioning Beastbot"
RTM.completion_quest_ids[151124] = 55207 -- "Mechagonian Nullifier"
RTM.completion_quest_ids[151672] = 55386 -- "Mecharantula"
RTM.completion_quest_ids[151627] = 55859 -- "Mr. Fixthis"
RTM.completion_quest_ids[151296] = 55515 -- "OOX-Avenger/MG"
RTM.completion_quest_ids[153206] = 55853 -- "Ol' Big Tusk"
RTM.completion_quest_ids[152764] = 55856 -- "Oxidized Leachbeast"
RTM.completion_quest_ids[151702] = 55405 -- "Paol Pondwader"
RTM.completion_quest_ids[150575] = 55368 -- "Rumblerocks"
RTM.completion_quest_ids[152182] = 55811 -- "Rustfeather"
RTM.completion_quest_ids[155583] = 56737 -- "Scrapclaw"
RTM.completion_quest_ids[150937] = 55545 -- "Seaspit"
RTM.completion_quest_ids[153000] = 55810 -- "Sparkqueen P'Emp"
RTM.completion_quest_ids[153226] = 55854 -- "Steel Singer Freza"