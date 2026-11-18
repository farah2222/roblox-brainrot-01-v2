-- Brainrot Rumble: one player's state, in one place. The server owns this
-- table; the client only ever sees a snapshot of it. Every service reads
-- and writes through the helpers here so the shape of a player never
-- drifts between modules.

local RumbleConfig = require(script.Parent.RumbleConfig)
local BrainrotCatalog = require(script.Parent.BrainrotCatalog)

local GameState = {}

-- A fresh player: starting cash, no brainrots, no rebirths, no upgrades.
function GameState.NewPlayer()
	return {
		Cash = RumbleConfig.StartCash,
		TotalEarned = 0,
		Rebirths = 0,
		Multiplier = 1,
		LockUntil = 0,
		Upgrades = { Boots = 0, Magnet = 0, Glove = 0 },
		Brainrots = {}, -- { DefId, Mutation, Slot }
		NextSpinAt = 0,
		BoostUntil = 0,
		PlotIndex = 0,
	}
end

-- The $/s of everything a player owns, before their personal multiplier.
function GameState.BaseIncome(state)
	local total = 0
	for _, owned in ipairs(state.Brainrots) do
		local def = BrainrotCatalog.Get(owned.DefId)
		if def then
			total = total + BrainrotCatalog.EffectiveRate(def, owned.Mutation)
		end
	end
	return total
end

-- The full $/s: base income times rebirth multiplier, magnet upgrade,
-- and a spin boost while it lasts.
function GameState.IncomePerSecond(state, now)
	local income = GameState.BaseIncome(state)
	income = income * state.Multiplier
	income = income * (1 + state.Upgrades.Magnet * RumbleConfig.Upgrades.Magnet.IncomeBonus)
	if now < state.BoostUntil then
		income = income * 2
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
	for slot = 1, RumbleConfig.PensPerBase do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

-- Add a brainrot to a free pen. Returns the slot, or nil when full.
function GameState.AddBrainrot(state, defId, mutation)
	local slot = GameState.FreeSlot(state)
	if not slot then
		return nil
	end
	table.insert(state.Brainrots, { DefId = defId, Mutation = mutation, Slot = slot })
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

-- Rebirth price for the NEXT rebirth.
function GameState.RebirthPrice(state)
	return RumbleConfig.RebirthBasePrice * (RumbleConfig.RebirthPriceGrowth ^ state.Rebirths)
end

-- Apply a rebirth: cash and brainrots reset, multiplier grows.
function GameState.ApplyRebirth(state)
	state.Cash = RumbleConfig.StartCash
	state.Brainrots = {}
	state.Rebirths = state.Rebirths + 1
	state.Multiplier = 1 + state.Rebirths * RumbleConfig.RebirthBoost
end

-- A small snapshot for the client: no server-only fields leak through.
function GameState.Snapshot(state, now)
	local owned = {}
	for _, entry in ipairs(state.Brainrots) do
		table.insert(owned, { DefId = entry.DefId, Mutation = entry.Mutation, Slot = entry.Slot })
	end
	return {
		Cash = state.Cash,
		Income = GameState.IncomePerSecond(state, now),
		Rebirths = state.Rebirths,
		Multiplier = state.Multiplier,
		LockLeft = GameState.LockLeft(state, now),
		Upgrades = { Boots = state.Upgrades.Boots, Magnet = state.Upgrades.Magnet, Glove = state.Upgrades.Glove },
		Brainrots = owned,
		SpinReadyIn = math.max(0, math.floor(state.NextSpinAt - now)),
		BoostLeft = math.max(0, math.floor(state.BoostUntil - now)),
		PlotIndex = state.PlotIndex,
	}
end

return GameState
