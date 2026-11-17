-- Brainrot Bay: WorldBuilder builds the whole 3D world at runtime.
-- A sunny bay island: a central conveyor belt down the middle, four
-- player base plots around it, a spawn plaza, palm trees, clouds and
-- a golden statue of Brainrot Prime. Everything is plain Parts, so
-- the place stays small and Rojo builds it in a blink.

local WorldBuilder = {}

local function part(name: string, size: Vector3, pos: Vector3, color: Color3, parent: Instance, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- A blocky palm tree: trunk + three leaf slabs.
local function palmTree(parent: Instance, pos: Vector3)
	local tree = Instance.new("Model")
	tree.Name = "PalmTree"
	part("Trunk", Vector3.new(1, 8, 1), pos + Vector3.new(0, 4, 0), Color3.fromRGB(150, 105, 60), tree, Enum.Material.Wood)
	part("Leaf1", Vector3.new(7, 0.6, 2), pos + Vector3.new(0, 8.5, 0), Color3.fromRGB(70, 180, 90), tree, Enum.Material.Grass)
	part("Leaf2", Vector3.new(2, 0.6, 7), pos + Vector3.new(0, 8.5, 0), Color3.fromRGB(60, 165, 80), tree, Enum.Material.Grass)
	part("Coconut", Vector3.new(1.4, 1.4, 1.4), pos + Vector3.new(1, 7.6, 0), Color3.fromRGB(110, 75, 40), tree)
	tree.Parent = parent
	return tree
end

-- A fluffy blocky cloud that drifts slowly (anchored; the drift is
-- cosmetic and handled by a tiny loop in init.server).
local function cloud(parent: Instance, pos: Vector3)
	local model = Instance.new("Model")
	model.Name = "Cloud"
	part("Puff1", Vector3.new(8, 3, 5), pos, Color3.fromRGB(255, 255, 255), model)
	part("Puff2", Vector3.new(5, 2.5, 4), pos + Vector3.new(3, 1, 0), Color3.fromRGB(245, 245, 250), model)
	part("Puff3", Vector3.new(4, 2, 4), pos + Vector3.new(-3.5, 0.8, 0), Color3.fromRGB(245, 245, 250), model)
	model.Parent = parent
	return model
end

-- One player base plot: a coloured pad, a fence, 8 slot markers in a
-- 2 x 4 grid, a sign with the owner's name, and a lock gate.
function WorldBuilder.buildBase(parent: Instance, plotIndex: number, center: Vector3, padColor: Color3): Model
	local base = Instance.new("Model")
	base.Name = "BasePlot" .. plotIndex

	-- The pad itself.
	part("Pad", Vector3.new(26, 1, 20), center + Vector3.new(0, 0.5, 0), padColor, base, Enum.Material.Grass)
	-- A low fence around three sides (the front stays open).
	for _, side in ipairs({ -1, 1 }) do
		part("Fence", Vector3.new(0.6, 2.5, 20), center + Vector3.new(side * 13, 1.75, 0), Color3.fromRGB(240, 240, 240), base)
	end
	part("FenceBack", Vector3.new(26, 2.5, 0.6), center + Vector3.new(0, 1.75, -10), Color3.fromRGB(240, 240, 240), base)

	-- The 8 slot markers: glowing pads where bought brainrots stand.
	for slot = 1, 8 do
		local col = (slot - 1) % 4
		local row = math.floor((slot - 1) / 4)
		local slotPos = center + Vector3.new((col - 1.5) * 6, 1.05, (row - 0.5) * 7)
		local marker = part("Slot" .. slot, Vector3.new(4.5, 0.2, 4.5), slotPos, Color3.fromRGB(255, 255, 255), base, Enum.Material.Neon)
		marker.Transparency = 0.55
	end

	-- The lock gate: a red barrier that appears while the base is locked.
	local gate = part("LockGate", Vector3.new(26, 4, 0.8), center + Vector3.new(0, 3, 10), Color3.fromRGB(220, 40, 40), base, Enum.Material.Neon)
	gate.Transparency = 1 -- hidden until ThreatService locks the base
	gate.CanCollide = false

	-- The owner's sign.
	local sign = part("Sign", Vector3.new(8, 3, 0.5), center + Vector3.new(0, 6, -10.5), Color3.fromRGB(60, 60, 80), base)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "BASE " .. plotIndex
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	base.Parent = parent
	return base
end

-- The conveyor: a long belt down the middle of the island, with
-- rollers, side rails and a spawn gate at the west end.
function WorldBuilder.buildConveyor(parent: Instance): Model
	local belt = Instance.new("Model")
	belt.Name = "Conveyor"
	part("Belt", Vector3.new(116, 1, 6), Vector3.new(0, 1, 0), Color3.fromRGB(70, 70, 85), belt, Enum.Material.Metal)
	-- Rollers: lighter stripes across the belt.
	for x = -55, 55, 5 do
		part("Roller", Vector3.new(1, 1.1, 6), Vector3.new(x, 1, 0), Color3.fromRGB(140, 140, 155), belt, Enum.Material.Metal)
	end
	-- Side rails.
	part("RailNorth", Vector3.new(116, 1, 0.6), Vector3.new(0, 2, 3.2), Color3.fromRGB(255, 200, 60), belt, Enum.Material.Neon)
	part("RailSouth", Vector3.new(116, 1, 0.6), Vector3.new(0, 2, -3.2), Color3.fromRGB(255, 200, 60), belt, Enum.Material.Neon)
	-- The spawn gate the brainrots walk out of.
	part("GateLeft", Vector3.new(1, 8, 1), Vector3.new(-58, 5, 3), Color3.fromRGB(255, 200, 60), belt)
	part("GateRight", Vector3.new(1, 8, 1), Vector3.new(-58, 5, -3), Color3.fromRGB(255, 200, 60), belt)
	part("GateTop", Vector3.new(1, 2, 8), Vector3.new(-58, 9, 0), Color3.fromRGB(255, 200, 60), belt)
	belt.Parent = parent
	return belt
end

-- The spawn plaza at the west end, where players arrive.
function WorldBuilder.buildSpawn(parent: Instance): Model
	local plaza = Instance.new("Model")
	plaza.Name = "SpawnPlaza"
	part("Plaza", Vector3.new(16, 1, 16), Vector3.new(-70, 0.5, 0), Color3.fromRGB(200, 200, 210), plaza)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(-70, 1, 0)
	spawn.Color = Color3.fromRGB(120, 220, 120)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = plaza
	plaza.Parent = parent
	return plaza
end

-- The golden statue of Brainrot Prime on the east hill, plus the
-- shop kiosk where upgrades are bought.
function WorldBuilder.buildLandmarks(parent: Instance)
	local hill = part("Hill", Vector3.new(24, 4, 24), Vector3.new(72, 1, 0), Color3.fromRGB(120, 200, 100), parent, Enum.Material.Grass)
	hill.Name = "StatueHill"
	-- The statue: a big golden blocky figure.
	local statue = Instance.new("Model")
	statue.Name = "BrainrotPrimeStatue"
	part("StatueBody", Vector3.new(6, 8, 4), Vector3.new(72, 8, 0), Color3.fromRGB(255, 215, 0), statue, Enum.Material.Metal)
	part("StatueHead", Vector3.new(5, 5, 5), Vector3.new(72, 14.5, 0), Color3.fromRGB(255, 230, 90), statue, Enum.Material.Metal)
	part("StatueCrown", Vector3.new(6, 1.5, 6), Vector3.new(72, 17.8, 0), Color3.fromRGB(255, 60, 220), statue, Enum.Material.Metal)
	statue.Parent = parent

	-- The shop kiosk near the spawn plaza.
	local shop = Instance.new("Model")
	shop.Name = "ShopKiosk"
	part("KioskBase", Vector3.new(10, 1, 8), Vector3.new(-58, 0.5, -14), Color3.fromRGB(180, 120, 60), shop, Enum.Material.Wood)
	part("KioskRoof", Vector3.new(12, 1, 10), Vector3.new(-58, 6, -14), Color3.fromRGB(220, 40, 40), shop)
	part("KioskPost1", Vector3.new(0.8, 5, 0.8), Vector3.new(-62, 3.5, -17), Color3.fromRGB(180, 120, 60), shop, Enum.Material.Wood)
	part("KioskPost2", Vector3.new(0.8, 5, 0.8), Vector3.new(-54, 3.5, -17), Color3.fromRGB(180, 120, 60), shop, Enum.Material.Wood)
	shop.Parent = parent
end

-- Build the whole island. Returns the folder holding everything, so
-- the services can find the conveyor, the bases and the spawn.
function WorldBuilder.build(workspace: Workspace): Folder
	local world = Instance.new("Folder")
	world.Name = "BrainrotBay"
	world.Parent = workspace

	-- Sand-coloured island ground (the project already has a baseplate
	-- far below; this is the island the players actually walk on).
	part("Island", Vector3.new(180, 2, 120), Vector3.new(0, 0, 0), Color3.fromRGB(240, 220, 160), world, Enum.Material.Sand)

	WorldBuilder.buildConveyor(world)
	WorldBuilder.buildSpawn(world)
	WorldBuilder.buildLandmarks(world)

	-- Four base plots: two north, two south of the conveyor.
	local plotColors = {
		Color3.fromRGB(90, 160, 255),
		Color3.fromRGB(255, 110, 110),
		Color3.fromRGB(120, 220, 120),
		Color3.fromRGB(190, 110, 255),
	}
	local plotCenters = {
		Vector3.new(-30, 1, 26),
		Vector3.new(30, 1, 26),
		Vector3.new(-30, 1, -26),
		Vector3.new(30, 1, -26),
	}
	for i, center in ipairs(plotCenters) do
		WorldBuilder.buildBase(world, i, center, plotColors[i])
	end

	-- Palm trees around the edges.
	for _, pos in ipairs({
		Vector3.new(-80, 1, 20), Vector3.new(-80, 1, -20),
		Vector3.new(60, 1, 40), Vector3.new(-60, 1, 40),
		Vector3.new(60, 1, -40), Vector3.new(80, 1, 20),
		Vector3.new(80, 1, -20), Vector3.new(-45, 1, -40),
	}) do
		palmTree(world, pos)
	end

	-- Clouds drifting overhead.
	for _, pos in ipairs({
		Vector3.new(-40, 45, -30), Vector3.new(20, 50, 25),
		Vector3.new(60, 42, -20), Vector3.new(-10, 55, 40),
	}) do
		cloud(world, pos)
	end

	return world
end

return WorldBuilder
