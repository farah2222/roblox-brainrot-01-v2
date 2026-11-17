-- Brainrot Bay: GameState is the single place that holds a player's
-- state. The server owns it; the client only ever sees snapshots the
-- server sends over RemoteEvents. Nothing else in the game keeps its
-- own copy of cash, brainrots, rebirths or locks.

local Config = require(script.Parent.Config)
local BrainrotDefs = require(script.Parent.BrainrotDefs)

local GameState = {}

-- A fresh player: $100 starting cash, an empty base, no rebirths.
function GameState.newPlayerState(player: Player)
	return {
		Player = player,
		Cash = 100,
		Rebirths = 0,
		-- Owned brainrots: { DefId, Mutation, Slot } in base-slot order.
		Owned = {},
		LockUntil = 0, -- os.clock() timestamp; 0 means unlocked
		Upgrades = { SpeedBoots = false, MoneyMagnet = false },
		TotalEarned = 0,
		TotalBought = 0,
	}
end

-- The permanent $/s bonus from rebirths (+25% each).
function GameState.rebirthBonus(state): number
	return state.Rebirths * Config.RebirthBonusPerLevel
end

-- The player's total $/s right now, across every owned brainrot.
function GameState.incomePerSecond(state): number
	local bonus = state.Rebirths * Config.RebirthBonusPerLevel
	local magnet = state.Upgrades.MoneyMagnet and 1.1 or 1
	local total = 0
	for _, owned in ipairs(state.Owned) do
		local def = BrainrotDefs.getById(owned.DefId)
		if def then
			total += BrainrotDefs.effectiveRate(def, owned.Mutation, bonus) * magnet
		end
	end
	return math.floor(total + 0.5)
end

-- First free base slot (1..8), or nil when the base is full.
function GameState.freeSlot(state): number?
	for slot = 1, Config.BaseSlots do
		local taken = false
		for _, owned in ipairs(state.Owned) do
			if owned.Slot == slot then
				taken = true
				break
			end
		end
		if not taken then
			return slot
		end
	end
	return nil
end

-- Is the base locked right now?
function GameState.isLocked(state): boolean
	return os.clock() < state.LockUntil
end

-- Seconds of lock left (0 when unlocked).
function GameState.lockSecondsLeft(state): number
	return math.max(0, state.LockUntil - os.clock())
end

-- Can this player afford this amount of cash?
function GameState.canAfford(state, amount: number): boolean
	return state.Cash >= amount
end

-- Spend cash; returns false (and spends nothing) when unaffordable.
function GameState.spend(state, amount: number): boolean
	if state.Cash < amount then
		return false
	end
	state.Cash -= amount
	return true
end

-- Add cash (from the money tick or a sale); tracks lifetime earnings.
function GameState.addCash(state, amount: number)
	state.Cash += amount
	state.TotalEarned += amount
end

-- Put a bought brainrot on the base; returns the slot or nil if full.
function GameState.placeBrainrot(state, defId: number, mutation: string): number?
	local slot = GameState.freeSlot(state)
	if not slot then
		return nil
	end
	table.insert(state.Owned, { DefId = defId, Mutation = mutation, Slot = slot })
	state.TotalBought += 1
	return slot
end

-- Remove the brainrot in a slot (the thief steals it); returns it or nil.
function GameState.removeFromSlot(state, slot: number)
	for i, owned in ipairs(state.Owned) do
		if owned.Slot == slot then
			table.remove(state.Owned, i)
			return owned
		end
	end
	return nil
end

-- Rebirth cost for the NEXT rebirth.
function GameState.rebirthCost(state): number
	return Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ state.Rebirths)
end

-- Rebirth: pay the cost, reset cash and brainrots, keep the multiplier.
-- Returns false when the player cannot afford it yet.
function GameState.rebirth(state): boolean
	local cost = GameState.rebirthCost(state)
	if state.Cash < cost then
		return false
	end
	state.Cash = 100
	state.Owned = {}
	state.Rebirths += 1
	state.LockUntil = 0
	return true
end

-- The small snapshot the client HUD needs, sent once a second.
function GameState.snapshot(state)
	return {
		Cash = math.floor(state.Cash + 0.5),
		PerSecond = GameState.incomePerSecond(state),
		Rebirths = state.Rebirths,
		OwnedCount = #state.Owned,
		BaseSlots = Config.BaseSlots,
		Locked = GameState.isLocked(state),
		LockLeft = math.floor(GameState.lockSecondsLeft(state) + 0.5),
		RebirthCost = GameState.rebirthCost(state),
		TotalEarned = math.floor(state.TotalEarned + 0.5),
	}
end

return GameState
