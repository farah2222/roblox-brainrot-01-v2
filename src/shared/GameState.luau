-- Brainrot Rumble: one player's state, in one place. The server owns this
-- table; the client only ever sees a snapshot of it. Every service reads
-- and writes through the helpers here so the shape of a player never
-- drifts between modules.

local RumbleConfig = require(script.Parent.RumbleConfig)
local BrainrotCatalog = require(script.Parent.BrainrotCatalog)
local MissionCatalog = require(script.Parent.MissionCatalog)
local MoneyFormat = require(script.Parent.MoneyFormat)

local GameState = {}

-- A fresh player: starting cash, no brainrots, no rebirths, no upgrades.
function GameState.NewPlayer()
	return {
		Cash = RumbleConfig.StartCash,
		TotalEarned = 0,
		Rebirths = 0,
		Multiplier = 1,
		LockUntil = 0,
		Upgrades = { Boots = 0, Magnet = 0, Glove = 0, Expansion = 0 },
		Brainrots = {}, -- { DefId, Mutation, Slot }
		NextSpinAt = 0,
		BoostUntil = 0,
		GoldenHourUntil = 0,
		PlotIndex = 0,
		Discovered = {}, -- DefId -> true (ever owned; drives the Index)
		MissionStats = { Buys = 0, Locks = 0, Spins = 0, Bonks = 0, TsunamisSurvived = 0 },
		MissionsDone = {}, -- mission Id -> true
		ChainBonus = false, -- true once all 10 missions are done (+25% $/s forever)
		CollectionRewards = {}, -- rarity tier -> true (tier collection paid)
		AllCollected = false, -- true once all 40 brainrots are discovered
		Carrying = nil, -- { DefId, Mutation, ComboMult, ComboUntil } while a bought brainrot is carried home
		ComboCount = 0, -- current buy streak tier (0 = no streak)
		ComboUntil = 0, -- os.time() the streak window ends
		RebirthMissionBase = 0, -- Rebirths when the mission chain last restarted (the rebirth mission needs one more)
	}
end

-- How many pens this player can use: base pens plus Base Expansion levels.
function GameState.PenCap(state)
	return RumbleConfig.PensPerBase + (state.Upgrades.Expansion or 0) * (RumbleConfig.Upgrades.Expansion.Pens or 1)
end

-- Remember a brainrot the player has owned (the Index shows it, not "???").
function GameState.MarkDiscovered(state, defId)
	state.Discovered[defId] = true
end

-- The $/s of everything a player owns, before their personal multiplier.
-- A brainrot bought on a combo streak earns at its stamped combo tier
-- (x1..x5) while the stamp lasts (60s from the buy); after that it
-- earns its normal rate. Owned entries without a stamp just earn normal.
function GameState.BaseIncome(state, now)
	local total = 0
	for _, owned in ipairs(state.Brainrots) do
		local def = BrainrotCatalog.Get(owned.DefId)
		if def then
			local rate = BrainrotCatalog.EffectiveRate(def, owned.Mutation)
			if owned.ComboMult and owned.ComboMult > 1 and owned.ComboUntil and now and now < owned.ComboUntil then
				rate = rate * owned.ComboMult
			end
			total = total + rate
		end
	end
	return total
end

-- The full $/s: base income times rebirth multiplier, magnet upgrade,
-- a spin boost while it lasts, Golden Hour (income x2) while it lasts,
-- and the mission-chain bonus (+25%) once the whole chain is done.
function GameState.IncomePerSecond(state, now)
	local income = GameState.BaseIncome(state, now)
	income = income * state.Multiplier
	income = income * (1 + state.Upgrades.Magnet * RumbleConfig.Upgrades.Magnet.IncomeBonus)
	if now < state.BoostUntil then
		income = income * 2
	end
	if now < state.GoldenHourUntil then
		income = income * RumbleConfig.GoldenHourIncome
	end
	if state.ChainBonus then
		income = income * (1 + RumbleConfig.ChainBonusIncome)
	end
	return math.floor(income)
end

-- Walk speed: base 16, plus boots.
function GameState.WalkSpeed(state)
	return 16 * (1 + state.Upgrades.Boots * RumbleConfig.Upgrades.Boots.WalkBonus)
end

-- Weapon cooldown scale: golden gloves shorten every cooldown.
function GameState.CooldownScale(state)
	return 1 - state.Upgrades.Glove * RumbleConfig.Upgrades.Glove.CooldownCut
end

function GameState.HasCash(state, amount)
	return state.Cash >= amount
end

function GameState.Spend(state, amount)
	if not GameState.HasCash(state, amount) then
		return false
	end
	state.Cash = state.Cash - amount
	return true
end

function GameState.AddCash(state, amount)
	state.Cash = state.Cash + amount
	state.TotalEarned = state.TotalEarned + amount
end

-- Is this player's base locked right now?
function GameState.IsLocked(state, now)
	return now < state.LockUntil
end

-- Seconds of lock left, or 0.
function GameState.LockLeft(state, now)
	if now >= state.LockUntil then
		return 0
	end
	return math.floor(state.LockUntil - now)
end

-- First free pen slot on this player's base, or nil when full.
function GameState.FreeSlot(state)
	local used = {}
	for _, owned in ipairs(state.Brainrots) do
		used[owned.Slot] = true
	end
	for slot = 1, GameState.PenCap(state) do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

-- Add a brainrot to a free pen. Returns the slot, or nil when full.
-- comboMult / comboUntil stamp a buy-streak bonus on the brainrot (its
-- income is multiplied while the stamp lasts); plain adds pass none.
function GameState.AddBrainrot(state, defId, mutation, comboMult, comboUntil)
	local slot = GameState.FreeSlot(state)
	if not slot then
		return nil
	end
	table.insert(state.Brainrots, { DefId = defId, Mutation = mutation, Slot = slot, ComboMult = comboMult or 1, ComboUntil = comboUntil or 0 })
	return slot
end

-- Remove one owned brainrot by its slot. Returns it, or nil.
function GameState.RemoveBrainrot(state, slot)
	for i, owned in ipairs(state.Brainrots) do
		if owned.Slot == slot then
			table.remove(state.Brainrots, i)
			return owned
		end
	end
	return nil
end

-- The richest brainrot a player owns (what a thief wants). Returns it or nil.
function GameState.RichestBrainrot(state)
	local best = nil
	local bestRate = -1
	for _, owned in ipairs(state.Brainrots) do
		local def = BrainrotCatalog.Get(owned.DefId)
		if def then
			local rate = BrainrotCatalog.EffectiveRate(def, owned.Mutation)
			if rate > bestRate then
				bestRate = rate
				best = owned
			end
		end
	end
	return best
end

-- Can this player rebirth right now? Returns true, or false + the
-- short reason the HUD shows. Rebirth is gated, not priced: you need
-- $100,000 earned in your lifetime, or all 10 missions done — and you
-- cannot rebirth past the x5 multiplier cap (8 rebirths).
function GameState.CanRebirth(state)
	if state.Rebirths >= RumbleConfig.RebirthMax then
		return false, "MAXED x5"
	end
	if state.TotalEarned >= RumbleConfig.RebirthMinLifetime then
		return true, ""
	end
	if GameState.MissionsDoneCount(state) >= #MissionCatalog.Missions then
		return true, ""
	end
	return false, "need " .. MoneyFormat.Cash(RumbleConfig.RebirthMinLifetime)
end

-- Apply a rebirth: cash, brainrots and mission progress reset (the
-- mission chain restarts, so the chain bonus can be earned again), and
-- the permanent income multiplier grows +50% a rebirth, capped at x5.
-- Upgrades, the Index and lifetime earnings survive — they are the
-- progress that makes the next run faster. The rebirth mission is
-- re-armed: it needs one more rebirth after this one.
function GameState.ApplyRebirth(state)
	state.Cash = RumbleConfig.StartCash
	state.Brainrots = {}
	state.Carrying = nil
	state.MissionsDone = {}
	state.MissionStats = { Buys = 0, Locks = 0, Spins = 0, Bonks = 0, TsunamisSurvived = 0 }
	state.ChainBonus = false
	state.LockUntil = 0
	state.ComboCount = 0
	state.ComboUntil = 0
	state.Rebirths = state.Rebirths + 1
	state.RebirthMissionBase = state.Rebirths
	state.Multiplier = math.min(1 + state.Rebirths * RumbleConfig.RebirthBoost, 1 + RumbleConfig.RebirthMax * RumbleConfig.RebirthBoost)
end

-- Drop the buy streak (the tsunami breaks it, and so does rebirth).
function GameState.ResetCombo(state)
	state.ComboCount = 0
	state.ComboUntil = 0
end

-- Check every mission against this player's state. Newly completed ones
-- pay their cash reward here and are returned (so the server can announce
-- them). Call it once a second from the money tick; it is cheap and it
-- catches every kind of progress (buys, earnings, locks, spins, rebirths,
-- collections, bonks, survivals).
-- Finishing the whole chain pays the chain bonus on top: a lump of cash
-- and a permanent +25% $/s, returned as a final entry.
function GameState.CheckMissions(state)
	local completed = {}
	for _, mission in ipairs(MissionCatalog.Missions) do
		if not state.MissionsDone[mission.Id] then
			local progress = mission.Check(state)
			if progress >= mission.Goal then
				state.MissionsDone[mission.Id] = true
				GameState.AddCash(state, mission.Reward)
				table.insert(completed, mission)
			end
		end
	end
	if #completed > 0 and not state.ChainBonus then
		local allDone = true
		for _, mission in ipairs(MissionCatalog.Missions) do
			if not state.MissionsDone[mission.Id] then
				allDone = false
				break
			end
		end
		if allDone then
			state.ChainBonus = true
			GameState.AddCash(state, RumbleConfig.ChainBonusCash)
			table.insert(completed, {
				Id = "chain-bonus",
				Title = "MISSION CHAIN COMPLETE!",
				Reward = RumbleConfig.ChainBonusCash,
			})
		end
	end
	return completed
end

-- Check the Index collection: a whole rarity tier discovered pays a
-- bonus, and all 40 brainrots pays a fortune. Returns the newly
-- completed collections (so the server can announce them).
function GameState.CheckCollection(state)
	local completed = {}
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		if not state.CollectionRewards[rarity.Name] then
			local found = 0
			local total = 0
			for _, def in ipairs(BrainrotCatalog.Characters) do
				if def.Rarity == rarity.Name then
					total = total + 1
					if state.Discovered[def.Id] then
						found = found + 1
					end
				end
			end
			if total > 0 and found >= total then
				state.CollectionRewards[rarity.Name] = true
				GameState.AddCash(state, RumbleConfig.TierCollectionBonus)
				table.insert(completed, {
					Title = "COLLECTION: " .. rarity.Name .. " " .. found .. "/" .. total,
					Reward = RumbleConfig.TierCollectionBonus,
				})
			end
		end
	end
	if not state.AllCollected then
		local found = 0
		for _ in pairs(state.Discovered) do
			found = found + 1
		end
		if found >= #BrainrotCatalog.Characters then
			state.AllCollected = true
			GameState.AddCash(state, RumbleConfig.FullCollectionBonus)
			table.insert(completed, {
				Title = "COLLECTION: ALL 40 BRAINROTS!",
				Reward = RumbleConfig.FullCollectionBonus,
			})
		end
	end
	return completed
end

-- How many collection tiers this player has finished.
function GameState.CollectionDoneCount(state)
	local count = 0
	for _ in pairs(state.CollectionRewards) do
		count = count + 1
	end
	return count
end

-- How many missions this player has finished.
function GameState.MissionsDoneCount(state)
	local count = 0
	for _ in pairs(state.MissionsDone) do
		count = count + 1
	end
	return count
end

-- A small snapshot for the client: no server-only fields leak through.
function GameState.Snapshot(state, now)
	local owned = {}
	for _, entry in ipairs(state.Brainrots) do
		table.insert(owned, { DefId = entry.DefId, Mutation = entry.Mutation, Slot = entry.Slot })
	end
	local discovered = {}
	for defId in pairs(state.Discovered) do
		table.insert(discovered, defId)
	end
	local missionCurrent = nil
	local nextMission = MissionCatalog.NextIncomplete(state)
	if nextMission then
		missionCurrent = {
			Title = nextMission.Title,
			Desc = nextMission.Desc,
			Progress = math.min(nextMission.Check(state), nextMission.Goal),
			Goal = nextMission.Goal,
		}
	end
	local carrying = nil
	if state.Carrying then
		carrying = { DefId = state.Carrying.DefId, Mutation = state.Carrying.Mutation }
	end
	local rebirthReady, rebirthHint = GameState.CanRebirth(state)
	return {
		Cash = state.Cash,
		Income = GameState.IncomePerSecond(state, now),
		Rebirths = state.Rebirths,
		Multiplier = state.Multiplier,
		RebirthReady = rebirthReady,
		RebirthHint = rebirthHint,
		LockLeft = GameState.LockLeft(state, now),
		Upgrades = { Boots = state.Upgrades.Boots, Magnet = state.Upgrades.Magnet, Glove = state.Upgrades.Glove, Expansion = state.Upgrades.Expansion or 0 },
		Brainrots = owned,
		SpinReadyIn = math.max(0, math.floor(state.NextSpinAt - now)),
		BoostLeft = math.max(0, math.floor(state.BoostUntil - now)),
		GoldenHourLeft = math.max(0, math.floor(state.GoldenHourUntil - now)),
		PlotIndex = state.PlotIndex,
		PenCap = GameState.PenCap(state),
		Discovered = discovered,
		MissionsDone = GameState.MissionsDoneCount(state),
		MissionTotal = #MissionCatalog.Missions,
		MissionCurrent = missionCurrent,
		ChainBonus = state.ChainBonus,
		CollectionDone = GameState.CollectionDoneCount(state),
		CollectionTotal = #BrainrotCatalog.Rarities,
		AllCollected = state.AllCollected,
		Carrying = carrying,
		ComboCount = state.ComboCount,
		ComboLeft = math.max(0, state.ComboUntil - now),
	}
end

return GameState
