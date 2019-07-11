local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

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
	--155060, -- "Doppel Ganger"
	152113, -- "The Kleptoboss"
	154225, -- "The Rusty Prince (F)"
	151625, -- "The Scrap King"
	151940, -- "Uncle T'Rogg"
	150394, -- "Armored Vaultbot"
	153200, -- "Boilburn"
	151308, -- "Boggac Skullbash"
	152001, -- "Bonepicker"
	154739, -- "Caustic Mechaslime"
	149847, -- "Crazed Trogg (Orange)"
	152569, -- "Crazed Trogg (Green)"
	152570, -- "Crazed Trogg (Blue)"
	151569, -- "Deepwater Maw"
	150342, -- "Earthbreaker Gulroc"
	154153, -- "Enforcer KX-T57"
	151202, -- "Foul Manifestation"
	151884, -- "Fungarian Furor"
	153228, -- "Gear Checker Cogstar"
	153205, -- "Gemicide"
	154701, -- "Gorged Gear-Cruncher"
	151684, -- "Jawbreaker"
	152007, -- "Killsaw"
	151933, -- "Malfunctioning Beastbot"
	151124, -- "Mechagonian Nullifier"
	151672, -- "Mecharantula"
	151627, -- "Mr. Fixthis"
	151296, -- "OOX-Avenger/MG"
	153206, -- "Ol' Big Tusk"
	152764, -- "Oxidized Leachbeast"
	151702, -- "Paol Pondwader"
	150575, -- "Rumblerocks"
	152182, -- "Rustfeather"
	155583, -- "Scrapclaw"
	150937, -- "Seaspit"
	153000, -- "Sparkqueen P'Emp"
	153226, -- "Steel Singer Freza"
	--524, -- "Boar"
}

RTM.rare_ids_set = Set(RTM.rare_ids)

RTM.rare_names_localized = {}
RTM.rare_names_localized["enUS"] = {}
RTM.rare_names_localized["enUS"][151934] = "Arachnoid Harvester"
RTM.rare_names_localized["enUS"][154342] = "Arachnoid Harvester (F)"
RTM.rare_names_localized["enUS"][155060] = "Doppel Ganger"
RTM.rare_names_localized["enUS"][152113] = "The Kleptoboss"
RTM.rare_names_localized["enUS"][154225] = "The Rusty Prince (F)"
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
RTM.rare_names_localized["enUS"][151884] = "Fungarian Furor"
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
RTM.rare_names_localized["enUS"][524] = "Boar"
--RTM.rare_names_localized["enUS"][153293] = "Rustwing Scavenger"