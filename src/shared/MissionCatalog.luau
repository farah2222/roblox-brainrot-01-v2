-- Brainrot Rumble: the mission list. Ten chained missions, each with a
-- cash reward. The server checks them every second (GameState.CheckMissions)
-- against the player's counters and totals; the client shows the next
-- incomplete one as "MISSION n/10" in the HUD. Nothing here touches a
-- player; it only describes the missions.

local MissionCatalog = {}

-- One entry per mission. Check is a function of (state) -> progress, goal.
-- Progress is a number; the mission completes when progress >= goal.
MissionCatalog.Missions = {
	{
		Id = "first-buy",
		Title = "First Catch",
		Desc = "Buy your first brainrot",
		Goal = 1,
		Reward = 200,
		Check = function(state)
			return state.MissionStats.Buys
		end,
	},
	{
		Id = "earn-1k",
		Title = "Cash Flow",
		Desc = "Earn $1,000 in total",
		Goal = 1000,
		Reward = 300,
		Check = function(state)
			return state.TotalEarned
		end,
	},
	{
		Id = "earn-10k",
		Title = "Big Spender",
		Desc = "Earn $10,000 in total",
		Goal = 10000,
		Reward = 1000,
		Check = function(state)
			return state.TotalEarned
		end,
	},
	{
		Id = "lock-once",
		Title = "Lock It Down",
		Desc = "Lock your base once",
		Goal = 1,
		Reward = 500,
		Check = function(state)
			return state.MissionStats.Locks
		end,
	},
	{
		Id = "spin-once",
		Title = "Spin Doctor",
		Desc = "Spin the wheel once",
		Goal = 1,
		Reward = 400,
		Check = function(state)
			return state.MissionStats.Spins
		end,
	},
	{
		Id = "survive-tsunami",
		Title = "Tsunami Survivor",
		Desc = "Survive a giant noodle tsunami",
		Goal = 1,
		Reward = 800,
		Check = function(state)
			return state.MissionStats.TsunamisSurvived
		end,
	},
	{
		Id = "rebirth-once",
		Title = "Rebirth!",
		Desc = "Rebirth once",
		Goal = 1,
		Reward = 2000,
		Check = function(state)
			return state.Rebirths
		end,
	},
	{
		Id = "collector-5",
		Title = "Collector",
		Desc = "Own 5 brainrots at once",
		Goal = 5,
		Reward = 1500,
		Check = function(state)
			return #state.Brainrots
		end,
	},
	{
		Id = "bonk-thief",
		Title = "Thief Buster",
		Desc = "Bonk Si Cilok Nakal away",
		Goal = 1,
		Reward = 1000,
		Check = function(state)
			return state.MissionStats.Bonks
		end,
	},
	{
		Id = "secret-hunter",
		Title = "Secret Hunter",
		Desc = "Own a Secret or Divine brainrot",
		Goal = 1,
		Reward = 5000,
		Check = function(state)
			local BrainrotCatalog = require(script.Parent.BrainrotCatalog)
			for _, owned in ipairs(state.Brainrots) do
				local def = BrainrotCatalog.Get(owned.DefId)
				if def and (def.Rarity == "Secret" or def.Rarity == "Divine") then
					return 1
				end
			end
			return 0
		end,
	},
}

-- The first mission the player has not finished yet, or nil when all done.
function MissionCatalog.NextIncomplete(state)
	for _, mission in ipairs(MissionCatalog.Missions) do
		if not state.MissionsDone[mission.Id] then
			return mission
		end
	end
	return nil
end

return MissionCatalog
