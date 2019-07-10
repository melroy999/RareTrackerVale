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
	151934,
	155060,
	152113,
	154225,
	151625,
	151940,
	150394,
	153200,
	151308,
	152001,
	154739,
	149847,
	152569,
	152570,
	151569,
	150342,
	154153,
	151202,
	151884,
	153228,
	153205,
	154701,
	151684,
	152007,
	151933,
	151124,
	151672,
	151627,
	151296,
	153206,
	152764,
	151702,
	150575,
	152182,
	155583,
	150937,
	153000,
	153226,
	154342,
	153293 -- Testing
}

RTM.rare_ids_set = Set(RTM.rare_ids)

RTM.rare_names_localized = {}
RTM.rare_names_localized["enUS"] = {}
RTM.rare_names_localized["enUS"][154342] = "Arachnoid Harvester (Future)"
RTM.rare_names_localized["enUS"][151934] = "Arachnoid Harvester"
RTM.rare_names_localized["enUS"][155060] = "Doppel Ganger"
RTM.rare_names_localized["enUS"][152113] = "The Kleptoboss"
RTM.rare_names_localized["enUS"][154225] = "The Rusty Prince"
RTM.rare_names_localized["enUS"][151625] = "The Scrap King"
RTM.rare_names_localized["enUS"][151940] = "Uncle T'Rogg"
RTM.rare_names_localized["enUS"][150394] = "Armored Vaultbot"
RTM.rare_names_localized["enUS"][153200] = "Boilburn"
RTM.rare_names_localized["enUS"][151308] = "Boggac Skullbash"
RTM.rare_names_localized["enUS"][152001] = "Bonepicker"
RTM.rare_names_localized["enUS"][154739] = "Caustic Mechaslime"
RTM.rare_names_localized["enUS"][149847] = "Crazed Trogg (Orange)"
RTM.rare_names_localized["enUS"][152569] = "Crazed Trogg (2)"
RTM.rare_names_localized["enUS"][152570] = "Crazed Trogg (3)"
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
RTM.rare_names_localized["enUS"][153293] = "Rustwing Scavenger"