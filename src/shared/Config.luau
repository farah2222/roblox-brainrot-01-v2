-- Brainrot Bay: tuning constants for the whole game.
-- One place for every number the other modules share, so a balance
-- tweak never means hunting through server and client scripts.

local Config = {}

-- The conveyor the brainrots walk along.
Config.ConveyorStart = Vector3.new(-56, 1, 0)
Config.ConveyorEnd = Vector3.new(56, 1, 0)
Config.ConveyorWalkSpeed = 4 -- studs per second
Config.SpawnInterval = 6 -- seconds between brainrot spawns
Config.MaxOnConveyor = 8

-- The player's base: 8 slots in a 2 x 4 grid.
Config.BaseSlots = 8
Config.BaseSlotSpacing = 6

-- The base lock: timed protection against the thief.
Config.LockCost = 500
Config.LockDuration = 60 -- seconds

-- The thief: Sticky-Fingers Stan.
Config.ThiefInterval = 75 -- seconds between thief visits
Config.ThiefStealTime = 6 -- seconds Stan needs, uninterrupted, to steal

-- The Noodle Tsunami wave event.
Config.WaveInterval = 150 -- seconds between waves
Config.WaveWarning = 15 -- seconds of warning before the wave hits
Config.WaveKnockback = 60 -- studs the wave shoves a player

-- Rebirth: reset cash and brainrots for a permanent multiplier.
Config.RebirthBaseCost = 25000
Config.RebirthCostGrowth = 4 -- each rebirth costs 4x the last
Config.RebirthBonusPerLevel = 0.25 -- +25% $/s per rebirth

-- Upgrades sold in the shop.
Config.Upgrades = {
	SpeedBoots = { Name = "Speed Boots", Cost = 1000, Description = "+30% walk speed" },
	MoneyMagnet = { Name = "Money Magnet", Cost = 2500, Description = "+10% $/s forever" },
}

-- Money tick: the server adds each brainrot's $/s every tick.
Config.TickInterval = 1 -- second

-- Mutation roll: most brainrots are Normal; a lucky few are not.
Config.MutationChances = {
	{ Name = "Diamond", Chance = 0.01, Multiplier = 10 },
	{ Name = "Rainbow", Chance = 0.03, Multiplier = 5 },
	{ Name = "Golden", Chance = 0.10, Multiplier = 2 },
}

return Config
