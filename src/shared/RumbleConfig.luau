-- Brainrot Rumble: every tuning number for the whole arena, in one place.
-- Server and client both read this, so a balance tweak never means
-- hunting through services. Nothing here touches a player; it only
-- describes the numbers the services agree on.

local RumbleConfig = {}

-- The arena floor the world is built on.
RumbleConfig.ArenaSize = Vector3.new(220, 2, 150)
RumbleConfig.ArenaCenter = Vector3.new(0, 0, 0)

-- The belt the brainrots march along, west to east.
RumbleConfig.BeltFrom = Vector3.new(-58, 1, 0)
RumbleConfig.BeltTo = Vector3.new(58, 1, 0)
RumbleConfig.BeltWidth = 6
RumbleConfig.MarchSpeed = 5 -- studs per second
RumbleConfig.SpawnEvery = 5 -- seconds between spawns
RumbleConfig.BeltCapacity = 8 -- brainrots on the belt at once

-- Where players arrive.
RumbleConfig.SpawnPad = Vector3.new(-72, 1, 0)

-- A player's home plot: 8 pens in a 2 by 5 grid (10 pen markers exist;
-- Base Expansion unlocks pens 9 and 10). MaxPens is the hard cap.
RumbleConfig.PensPerBase = 8
RumbleConfig.MaxPens = 10
RumbleConfig.PenGap = 5
RumbleConfig.PenSize = Vector3.new(4.5, 0.2, 4.5)

-- Base plots around the belt (centre, colour). Four plots, one per player.
RumbleConfig.Plots = {
	{ Center = Vector3.new(-32, 1.5, 28), Color = Color3.fromRGB(90, 160, 255) },
	{ Center = Vector3.new(32, 1.5, 28), Color = Color3.fromRGB(255, 110, 110) },
	{ Center = Vector3.new(-32, 1.5, -28), Color = Color3.fromRGB(120, 220, 120) },
	{ Center = Vector3.new(32, 1.5, -28), Color = Color3.fromRGB(190, 110, 255) },
}

-- The base lock: paid, timed protection against thieves and stealers.
RumbleConfig.LockPrice = 600
RumbleConfig.LockSeconds = 75

-- Si Cilok Nakal, the thief NPC.
RumbleConfig.ThiefEvery = 80 -- seconds between visits
RumbleConfig.ThiefChannel = 7 -- seconds he needs, uninterrupted, to steal

-- The giant noodle tsunami.
RumbleConfig.TsunamiEvery = 160 -- seconds between waves
RumbleConfig.TsunamiWarning = 15 -- seconds of warning first
RumbleConfig.TsunamiShove = 60 -- studs the wave throws a player

-- The meteor noodle shower.
RumbleConfig.MeteorEvery = 200 -- seconds between showers
RumbleConfig.MeteorCount = 5
RumbleConfig.MeteorCash = 800 -- base cash per meteor noodle picked up

-- The boss: a Secret brainrot may arrive wearing a crown and twice as big.
RumbleConfig.BossChance = 0.05 -- of Secret spawns
RumbleConfig.BossScale = 2

-- Rebirth: wipe cash, brainrots and mission progress for a permanent
-- income multiplier. It costs nothing in cash — the wipe IS the price —
-- but it is gated: you must have earned $100,000 in your lifetime, or
-- finished all 10 missions. Each rebirth adds +50% $/s, stacking up to
-- a x5 multiplier (8 rebirths); the mission chain restarts after each
-- rebirth, so the chain bonus can be earned again.
RumbleConfig.RebirthBoost = 0.50 -- +50% $/s per rebirth
RumbleConfig.RebirthMax = 8 -- rebirths; 1 + 8 x 0.50 = x5 multiplier cap
RumbleConfig.RebirthMinLifetime = 100000 -- lifetime $ earned to qualify

-- Shop upgrades. Each has a price, a cap, and what one level does.
-- Four levelled tracks: every level costs Price * (level + 1).
-- Expansion adds one pen per level (base is 8 pens, max 10).
RumbleConfig.Upgrades = {
	Boots = { Price = 1000, Max = 5, WalkBonus = 0.30, Label = "Speed Boots" },
	Magnet = { Price = 2500, Max = 5, IncomeBonus = 0.12, Label = "Money Magnet" },
	Glove = { Price = 5000, Max = 5, CooldownCut = 0.20, Label = "Golden Glove" },
	Expansion = { Price = 8000, Max = 2, Pens = 1, Label = "Base Expansion" },
}

-- Golden Hour: a positive event on a timer. Income x2 and mutation
-- rolls get 4 tries (the best one wins) while it lasts.
RumbleConfig.GoldenHourEvery = 240 -- seconds between Golden Hours
RumbleConfig.GoldenHourDuration = 60 -- seconds each one lasts
RumbleConfig.GoldenHourIncome = 2 -- income multiplier during it
RumbleConfig.GoldenHourMutationRolls = 4 -- mutation re-rolls during it

-- The carry: a bought brainrot rides in your hands, not in your pocket.
-- Carrying is heavy (walk slower) but delivering pays a bonus by tier —
-- the rarer the catch, the slower you run and the more the delivery pays.
RumbleConfig.CarrySlow = 0.8 -- walk-speed scale while carrying
RumbleConfig.DeliveryBonus = {
	Common = 0,
	Rare = 50,
	Epic = 200,
	Legendary = 500,
	Mythic = 1000,
	Secret = 2500,
	Divine = 5000,
}

-- The combo: buy brainrots in quick succession and the streak builds.
-- Each buy within the window raises the combo a tier (x1 -> x5); the
-- brainrot you just bought earns at that tier for a minute once it is
-- penned. Delivering refreshes the window (the carry itself does not
-- eat the streak); stop buying for a whole window and it resets, and
-- the tsunami breaks it outright.
RumbleConfig.ComboWindow = 12 -- seconds between buys to keep the streak
RumbleConfig.ComboMax = 5 -- combo tiers: x1, x2, x3, x4, x5
RumbleConfig.ComboBonusDuration = 60 -- seconds a bought brainrot keeps its combo rate

-- The mission chain: finish all 10 missions for the chain bonus.
RumbleConfig.ChainBonusCash = 25000
RumbleConfig.ChainBonusIncome = 0.25 -- permanent +25% $/s once the chain is done

-- The Index collection: finish a whole tier for a bonus, all 40 for a fortune.
RumbleConfig.TierCollectionBonus = 3000
RumbleConfig.FullCollectionBonus = 50000

-- Selling: a brainrot sells for 70% of what it cost to buy.
RumbleConfig.SellFraction = 0.7

-- Weapons. Keys 1, 2, 3. Cooldowns in seconds, ranges in studs.
RumbleConfig.Weapons = {
	Slap = { Key = Enum.KeyCode.One, Cooldown = 3, Reach = 9, Shove = 28, Label = "Slap Glove" },
	Freeze = { Key = Enum.KeyCode.Two, Cooldown = 9, Reach = 22, FreezeTime = 3, Label = "Freeze Ray" },
	Pull = { Key = Enum.KeyCode.Three, Cooldown = 12, Reach = 40, Label = "Brainrot Magnet" },
}

-- Stealing from another player's base.
RumbleConfig.StealChannel = 5 -- seconds holding still beside a brainrot
RumbleConfig.StealRange = 7 -- studs from the target brainrot

-- The lucky spin wheel.
RumbleConfig.SpinEvery = 120 -- seconds between free spins
RumbleConfig.SpinBoostSeconds = 60 -- how long the 2x income prize lasts

-- Starting cash for a fresh player.
RumbleConfig.StartCash = 150

return RumbleConfig
