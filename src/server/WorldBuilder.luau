-- Brainrot Rumble: WorldBuilder raises the whole arena at runtime.
-- A neon night market arena, not an island: a dark floor, a glowing
-- central belt, four coloured home plots, a spawn plaza, a shop kiosk,
-- a giant noodle-bowl statue, sambal trees, drifting clouds and a spin
-- wheel platform. Everything is Anchored Parts built from code, so the
-- place file stays small and the world is exactly reproducible.
--
-- ARENA HEIGHT NOTE (r7 fix, 2026-11-19): the arena is built around y=0
-- (ArenaFloor top y=0, belt/spawn pad just above it), so it sits exactly
-- on the Baseplate TOP, which must be y=0. The live place Baseplate is
-- 512x20x512, so it must sit at Position (0,-10,0) for its top to be y=0.
-- If the Baseplate is at (0,0,0) instead, its top is y=10 and the whole
-- arena is buried 10 studs underneath it — the player spawns on an empty
-- studded floor and sees nothing.

local RumbleConfig = require(game:GetService("ReplicatedStorage").Shared.RumbleConfig)

local WorldBuilder = {}

-- One part, parented to the given folder, with the given properties.
local function part(parent, name, className, size, position, color, extra)
	local inst = Instance.new(className or "Part")
	inst.Name = name
	inst.Size = size
	inst.Position = position
	inst.Color = color
	inst.Anchored = true
	inst.CanCollide = true
	if extra then
		for key, value in pairs(extra) do
			inst[key] = value
		end
	end
	inst.Parent = parent
	return inst
end

-- Pen positions on a plot: 10 pens in a 2 by 5 grid.
function WorldBuilder.PenPosition(plotIndex, slot)
	local plot = RumbleConfig.Plots[plotIndex]
	local col = (slot - 1) % 5
	local row = math.floor((slot - 1) / 5)
	return Vector3.new(
		plot.Center.X + (col - 2) * RumbleConfig.PenGap,
		plot.Center.Y + 1,
		plot.Center.Z + (row - 0.5) * 7
	)
end

function WorldBuilder.Build()
	local world = Instance.new("Folder")
	world.Name = "RumbleArena"
	world.Parent = workspace

	local plots = {}
	local gates = {}
	local pens = {}

	-- The arena floor and its neon rim.
	part(world, "ArenaFloor", "Part", Vector3.new(220, 2, 150), Vector3.new(0, -1, 0), Color3.fromRGB(38, 38, 52), { Material = Enum.Material.SmoothPlastic })
	part(world, "RimNorth", "Part", Vector3.new(220, 3, 1), Vector3.new(0, 1, 75), Color3.fromRGB(255, 200, 60), { Material = Enum.Material.Neon })
	part(world, "RimSouth", "Part", Vector3.new(220, 3, 1), Vector3.new(0, 1, -75), Color3.fromRGB(255, 200, 60), { Material = Enum.Material.Neon })
	part(world, "RimWest", "Part", Vector3.new(1, 3, 150), Vector3.new(-110, 1, 0), Color3.fromRGB(255, 90, 160), { Material = Enum.Material.Neon })
	part(world, "RimEast", "Part", Vector3.new(1, 3, 150), Vector3.new(110, 1, 0), Color3.fromRGB(255, 90, 160), { Material = Enum.Material.Neon })

	-- The central belt: dark slab, rollers, glowing rails, spawn gate.
	part(world, "BeltSlab", "Part", Vector3.new(116, 1, 6), Vector3.new(0, 0.5, 0), Color3.fromRGB(70, 70, 85))
	for x = -55, 55, 5 do
		part(world, "Roller", "Part", Vector3.new(1, 1.1, 6), Vector3.new(x, 0.6, 0), Color3.fromRGB(140, 140, 155))
	end
	part(world, "RailNorth", "Part", Vector3.new(116, 1, 0.6), Vector3.new(0, 1.5, 3.2), Color3.fromRGB(255, 200, 60), { Material = Enum.Material.Neon })
	part(world, "RailSouth", "Part", Vector3.new(116, 1, 0.6), Vector3.new(0, 1.5, -3.2), Color3.fromRGB(255, 200, 60), { Material = Enum.Material.Neon })
	part(world, "GatePostA", "Part", Vector3.new(1, 8, 1), Vector3.new(-58, 4, 3), Color3.fromRGB(255, 200, 60))
	part(world, "GatePostB", "Part", Vector3.new(1, 8, 1), Vector3.new(-58, 4, -3), Color3.fromRGB(255, 200, 60))
	part(world, "GateTop", "Part", Vector3.new(1, 2, 8), Vector3.new(-58, 8, 0), Color3.fromRGB(255, 200, 60))

	-- Spawn plaza at the west end.
	part(world, "SpawnPlaza", "Part", Vector3.new(16, 1, 16), Vector3.new(-72, 0, 0), Color3.fromRGB(200, 200, 210))
	part(world, "SpawnPad", "Part", Vector3.new(10, 1, 10), Vector3.new(-72, 0.6, 0), Color3.fromRGB(120, 220, 120))
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "RumbleSpawn"
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = Vector3.new(-72, 1, 0)
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.Parent = world

	-- The four home plots: coloured pads, fences, pen markers, lock gates.
	for i, plot in ipairs(RumbleConfig.Plots) do
		local center = plot.Center
		part(world, "PlotPad" .. i, "Part", Vector3.new(26, 1, 20), Vector3.new(center.X, 0.6, center.Z), plot.Color, { Transparency = 0.25 })
		part(world, "FenceW" .. i, "Part", Vector3.new(0.6, 2.5, 20), Vector3.new(center.X - 13, 1.8, center.Z), Color3.fromRGB(240, 240, 240))
		part(world, "FenceE" .. i, "Part", Vector3.new(0.6, 2.5, 20), Vector3.new(center.X + 13, 1.8, center.Z), Color3.fromRGB(240, 240, 240))
		part(world, "FenceN" .. i, "Part", Vector3.new(26, 2.5, 0.6), Vector3.new(center.X, 1.8, center.Z - 10), Color3.fromRGB(240, 240, 240))
		local penList = {}
		for slot = 1, RumbleConfig.MaxPens do
			local pos = WorldBuilder.PenPosition(i, slot)
			local marker = part(world, "PenMarker", "Part", RumbleConfig.PenSize, pos, Color3.fromRGB(255, 255, 255), { Transparency = 0.55, Material = Enum.Material.Neon })
			table.insert(penList, marker)
		end
		pens[i] = penList
		-- The lock gate: a red energy wall across the open side, hidden until locked.
		local gate = part(world, "LockGate" .. i, "Part", Vector3.new(26, 4, 0.8), Vector3.new(center.X, 2.5, center.Z + 10), Color3.fromRGB(220, 40, 40), { Transparency = 0.35, Material = Enum.Material.Neon, CanCollide = false })
		gate.Transparency = 1
		gates[i] = gate
		plots[i] = { Center = center, Color = plot.Color }
	end

	-- Shop kiosk near the spawn.
	part(world, "KioskBase", "Part", Vector3.new(10, 1, 8), Vector3.new(-58, 0, -16), Color3.fromRGB(180, 120, 60))
	part(world, "KioskRoof", "Part", Vector3.new(12, 1, 10), Vector3.new(-58, 5.5, -16), Color3.fromRGB(220, 40, 40))
	part(world, "KioskPostA", "Part", Vector3.new(0.8, 5, 0.8), Vector3.new(-62, 3, -19), Color3.fromRGB(180, 120, 60))
	part(world, "KioskPostB", "Part", Vector3.new(0.8, 5, 0.8), Vector3.new(-54, 3, -19), Color3.fromRGB(180, 120, 60))

	-- The giant noodle-bowl statue on its hill, east side.
	part(world, "StatueHill", "Part", Vector3.new(24, 4, 24), Vector3.new(74, 1, 0), Color3.fromRGB(120, 200, 100))
	part(world, "NoodleBowl", "Part", Vector3.new(10, 4, 10), Vector3.new(74, 5, 0), Color3.fromRGB(220, 40, 40))
	part(world, "NoodleSwirl", "Part", Vector3.new(8, 2, 8), Vector3.new(74, 8, 0), Color3.fromRGB(250, 210, 90))
	part(world, "ChopstickA", "Part", Vector3.new(0.8, 12, 0.8), Vector3.new(72, 13, 1), Color3.fromRGB(180, 120, 60), { Orientation = Vector3.new(0, 0, 20) })
	part(world, "ChopstickB", "Part", Vector3.new(0.8, 12, 0.8), Vector3.new(76, 13, -1), Color3.fromRGB(180, 120, 60), { Orientation = Vector3.new(0, 0, -20) })

	-- The lucky spin wheel platform, north-east.
	part(world, "SpinPlatform", "Part", Vector3.new(14, 1, 14), Vector3.new(58, 0.6, -52), Color3.fromRGB(150, 90, 255), { Material = Enum.Material.Neon, Transparency = 0.2 })
	part(world, "SpinPost", "Part", Vector3.new(1, 8, 1), Vector3.new(58, 4.5, -52), Color3.fromRGB(255, 215, 0))
	part(world, "SpinWheel", "Part", Vector3.new(6, 6, 0.6), Vector3.new(58, 8, -52), Color3.fromRGB(255, 215, 0), { Material = Enum.Material.Neon })

	-- The boss gate: a golden arch at the east end of the belt.
	part(world, "BossArchA", "Part", Vector3.new(1, 10, 1), Vector3.new(62, 5, 4), Color3.fromRGB(255, 215, 0))
	part(world, "BossArchB", "Part", Vector3.new(1, 10, 1), Vector3.new(62, 5, -4), Color3.fromRGB(255, 215, 0))
	part(world, "BossArchTop", "Part", Vector3.new(1, 2, 10), Vector3.new(62, 10, 0), Color3.fromRGB(255, 215, 0))

	-- Sambal trees: brown trunks, red canopies, a few coconuts of chili.
	local treeSpots = { { -84, 22 }, { -84, -22 }, { 62, 42 }, { -62, 42 }, { 62, -42 }, { 84, 22 }, { 84, -22 }, { -48, -42 } }
	for _, spot in ipairs(treeSpots) do
		local x, z = spot[1], spot[2]
		part(world, "Trunk", "Part", Vector3.new(1, 8, 1), Vector3.new(x, 4, z), Color3.fromRGB(150, 105, 60))
		part(world, "CanopyA", "Part", Vector3.new(7, 0.6, 2), Vector3.new(x, 8.5, z), Color3.fromRGB(220, 40, 40))
		part(world, "CanopyB", "Part", Vector3.new(2, 0.6, 7), Vector3.new(x, 8.5, z), Color3.fromRGB(200, 30, 30))
		part(world, "Chili", "Part", Vector3.new(1.4, 1.4, 1.4), Vector3.new(x + 1, 7.6, z), Color3.fromRGB(255, 60, 40))
	end

	-- Drifting clouds, high up.
	local cloudSpots = { { -40, 45, -30 }, { 20, 50, 25 }, { 60, 42, -20 }, { -10, 55, 40 } }
	for _, spot in ipairs(cloudSpots) do
		local x, y, z = spot[1], spot[2], spot[3]
		part(world, "Cloud", "Part", Vector3.new(8, 3, 5), Vector3.new(x, y, z), Color3.fromRGB(255, 255, 255), { CanCollide = false })
		part(world, "Cloud", "Part", Vector3.new(5, 2.5, 4), Vector3.new(x + 3, y + 1, z), Color3.fromRGB(245, 245, 250), { CanCollide = false })
	end

	return {
		Folder = world,
		Plots = plots,
		Gates = gates,
		Pens = pens,
		SpawnLocation = spawnLocation,
	}
end

return WorldBuilder
