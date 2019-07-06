local _, data = ...

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
local rare_ids = {
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
}

local rare_ids_set = Set(rare_ids)

local rare_names_localized = {}
rare_names_localized["enUS"] = {}
rare_names_localized["enUS"][151934] = "Arachnoid Harvester"
rare_names_localized["enUS"][155060] = "Doppel Ganger"
rare_names_localized["enUS"][152113] = "The Kleptoboss"
rare_names_localized["enUS"][154225] = "The Rusty Prince"
rare_names_localized["enUS"][151625] = "The Scrap King"
rare_names_localized["enUS"][151940] = "Uncle T'Rogg"
rare_names_localized["enUS"][150394] = "Armored Vaultbot"
rare_names_localized["enUS"][153200] = "Boilburn"
rare_names_localized["enUS"][151308] = "Boggac Skullbash"
rare_names_localized["enUS"][152001] = "Bonepicker"
rare_names_localized["enUS"][154739] = "Caustic Mechaslime"
rare_names_localized["enUS"][149847] = "Crazed Trogg (1)"
rare_names_localized["enUS"][152569] = "Crazed Trogg (2)"
rare_names_localized["enUS"][152570] = "Crazed Trogg (3)"
rare_names_localized["enUS"][151569] = "Deepwater Maw"
rare_names_localized["enUS"][150342] = "Earthbreaker Gulroc"
rare_names_localized["enUS"][154153] = "Enforcer KX-T57"
rare_names_localized["enUS"][151202] = "Foul Manifestation"
rare_names_localized["enUS"][151884] = "Fungarian Furor"
rare_names_localized["enUS"][153228] = "Gear Checker Cogstar"
rare_names_localized["enUS"][153205] = "Gemicide"
rare_names_localized["enUS"][154701] = "Gorged Gear-Cruncher"
rare_names_localized["enUS"][151684] = "Jawbreaker"
rare_names_localized["enUS"][152007] = "Killsaw"
rare_names_localized["enUS"][151933] = "Malfunctioning Beastbot"
rare_names_localized["enUS"][151124] = "Mechagonian Nullifier"
rare_names_localized["enUS"][151672] = "Mecharantula"
rare_names_localized["enUS"][151627] = "Mr. Fixthis"
rare_names_localized["enUS"][151296] = "OOX-Avenger/MG"
rare_names_localized["enUS"][153206] = "Ol' Big Tusk"
rare_names_localized["enUS"][152764] = "Oxidized Leachbeast"
rare_names_localized["enUS"][151702] = "Paol Pondwader"
rare_names_localized["enUS"][150575] = "Rumblerocks"
rare_names_localized["enUS"][152182] = "Rustfeather"
rare_names_localized["enUS"][155583] = "Scrapclaw"
rare_names_localized["enUS"][150937] = "Seaspit"
rare_names_localized["enUS"][153000] = "Sparkqueen P'Emp"
rare_names_localized["enUS"][153226] = "Steel Singer Freza"

data.rare_ids = rare_ids
data.rare_ids_set = rare_ids_set
data.rare_names_localized = rare_names_localized