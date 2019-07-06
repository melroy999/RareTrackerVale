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
	153293,
	153294,
	153269
}

local rare_ids_set = Set(rare_ids)

local rare_names_localized = {}
rare_names_localized["enUS"] = {}
rare_names_localized["enUS"][153293] = "Rustwing Scavenger"
rare_names_localized["enUS"][153294] = "Dead Mechagnome"
rare_names_localized["enUS"][153269] = "Rustwing Raven"

data.rare_ids = rare_ids
data.rare_ids_set = rare_ids_set
data.rare_names_localized = rare_names_localized