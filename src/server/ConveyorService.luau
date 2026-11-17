-- Brainrot Bay: ConveyorService runs the heart of the game loop.
-- It spawns brainrots on the west end of the conveyor, walks them
-- east along the belt, and sells them: a player who walks up and
-- holds E on a brainrot buys it, and the brainrot waddles off to a
-- free slot on that player's base, where it starts earning $/s.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local GameState = require(ReplicatedStorage.Shared.GameState)

local ConveyorService = {}

-- Build one blocky brainrot character from its definition. The model
-- is a Model with a PrimaryPart (Body), a Head, two eyes and the
-- accessory its def names, plus a name label and a buy prompt.
local function buildBrainrotModel(def, mutation: string): Model
	local model = Instance.new("Model")
	model.Name = def.Name .. " (" .. mutation .. ")"

	local bodySize = Vector3.new(3, 3, 3)
	if def.Shape == "tall" then
		bodySize = Vector3.new(2.6, 4.2, 2.6)
	elseif def.Shape == "wide" then
		bodySize = Vector3.new(4.4, 2.6, 3)
	elseif def.Shape == "round" then
		bodySize = Vector3.new(3.4, 3.4, 3.4)
	end

	local mutationColor = BrainrotDefs.Mutations[mutation].Color
	local bodyColor = def.Body
	if mutation ~= "Normal" then
		-- Mutations tint the body toward their colour.
		bodyColor = bodyColor:Lerp(mutationColor, 0.45)
	end

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = bodySize
	body.Color = bodyColor
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.4, 2.2, 2.4)
	head.Color = def.Head
	head.Anchored = true
	head.CanCollide = false
	head.Position = body.Position + Vector3.new(0, bodySize.Y / 2 + 1.1, 0)
	head.Parent = model

	-- Two eyes on the walking face (+X, the direction of travel).
	for _, side in ipairs({ -0.6, 0.6 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.3, 0.6, 0.5)
		eye.Color = Color3.fromRGB(20, 20, 20)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = head.Position + Vector3.new(1.25, 0.3, side)
		eye.Parent = model
	end

	-- The accessory named in the definition.
	if def.Accessory == "tophat" then
		local hat = Instance.new("Part")
		hat.Name = "TopHat"
		hat.Size = Vector3.new(1.8, 2, 1.8)
		hat.Color = Color3.fromRGB(25, 25, 25)
		hat.Anchored = true
		hat.CanCollide = false
		hat.Position = head.Position + Vector3.new(0, 2, 0)
		hat.Parent = model
		local brim = Instance.new("Part")
		brim.Name = "HatBrim"
		brim.Size = Vector3.new(3, 0.3, 3)
		brim.Color = Color3.fromRGB(25, 25, 25)
		brim.Anchored = true
		brim.CanCollide = false
		brim.Position = head.Position + Vector3.new(0, 1.1, 0)
		brim.Parent = model
	elseif def.Accessory == "crown" then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(2.6, 0.9, 2.6)
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Material = Enum.Material.Metal
		crown.Anchored = true
		crown.CanCollide = false
		crown.Position = head.Position + Vector3.new(0, 1.5, 0)
		crown.Parent = model
	elseif def.Accessory == "sunglasses" then
		local shades = Instance.new("Part")
		shades.Name = "Sunglasses"
		shades.Size = Vector3.new(0.3, 0.5, 2)
		shades.Color = Color3.fromRGB(15, 15, 15)
		shades.Anchored = true
		shades.CanCollide = false
		shades.Position = head.Position + Vector3.new(1.25, 0.4, 0)
		shades.Parent = model
	elseif def.Accessory == "chefhat" then
		local chef = Instance.new("Part")
		chef.Name = "ChefHat"
		chef.Size = Vector3.new(2.4, 1.6, 2.4)
		chef.Color = Color3.fromRGB(255, 255, 255)
		chef.Anchored = true
		chef.CanCollide = false
		chef.Position = head.Position + Vector3.new(0, 1.8, 0)
		chef.Parent = model
	elseif def.Accessory == "cape" then
		local cape = Instance.new("Part")
		cape.Name = "Cape"
		cape.Size = Vector3.new(0.4, 3.4, 2.8)
		cape.Color = def.Accent
		cape.Anchored = true
		cape.CanCollide = false
		cape.Position = body.Position + Vector3.new(-bodySize.X / 2 - 0.2, 0.2, 0)
		cape.Parent = model
	end

	-- The floating label: name, rarity and $/s, coloured by rarity.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.fromOffset(220, 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = def.Rarity .. (mutation ~= "Normal" and (" " .. mutation) or "")
	rarityLabel.TextColor3 = BrainrotDefs.RarityColors[def.Rarity]
	rarityLabel.TextSize = 16
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = billboard
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Position = UDim2.new(0, 0, 0.7, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = BrainrotDefs.formatMoney(def.Rate) .. "/s  -  " .. BrainrotDefs.formatMoney(def.Cost)
	rateLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	rateLabel.TextSize = 16
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = billboard

	return model
end

-- The world position of a base slot for a plot centre.
local function slotPosition(plotCenter: Vector3, slot: number): Vector3
	local col = (slot - 1) % 4
	local row = math.floor((slot - 1) / 4)
	return plotCenter + Vector3.new((col - 1.5) * 6, 2.2, (row - 0.5) * 7)
end

-- Start the service. deps: { States, Plots, Remotes, Workspace }.
-- States maps Player -> GameState; Plots maps Player -> plot centre.
function ConveyorService.start(deps)
	local states = deps.States
	local plots = deps.Plots
	local remotes = deps.Remotes
	local workspace = deps.Workspace

	local conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "ConveyorBrainrots"
	conveyorFolder.Parent = workspace

	local active = {} -- models currently walking the belt
	local lastSpawn = 0

	-- Sell the brainrot on the belt to the player who held E.
	local function onBuyPrompt(player: Player, model: Model, def, mutation: string)
		local state = states[player]
		if not state then
			return
		end
		if not table.find(active, model) then
			return -- already bought, or washed away by the wave
		end
		if not GameState.canAfford(state, def.Cost) then
			remotes.Popup:FireClient(player, "Not enough cash for " .. def.Name .. "!")
			return
		end
		local slot = GameState.freeSlot(state)
		if not slot then
			remotes.Popup:FireClient(player, "Your base is full! Rebirth or wait for a slot.")
			return
		end
		GameState.spend(state, def.Cost)
		GameState.placeBrainrot(state, def.Id, mutation)
		table.remove(active, table.find(active, model))

		-- Move the model onto the base slot and strip its buy prompt.
		local plotCenter = plots[player]
		model:PivotTo(CFrame.new(slotPosition(plotCenter, slot)))
		local prompt = model.Body:FindFirstChild("BuyPrompt")
		if prompt then
			prompt:Destroy()
		end
		local label = model.Body:FindFirstChild("BrainrotLabel")
		if label then
			label.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
		end
		model.Parent = conveyorFolder

		remotes.BoughtBrainrot:FireAllClients(player.Name, def.Name, def.Rarity, mutation, slot)
		remotes.Popup:FireClient(player, "Bought " .. def.Name .. " for " .. BrainrotDefs.formatMoney(def.Cost) .. "!")
	end

	-- Spawn one brainrot at the west gate and put it on the belt.
	local function spawnBrainrot()
		if #active >= Config.MaxOnConveyor then
			return
		end
		local def, mutation = BrainrotDefs.rollSpawn()
		local model = buildBrainrotModel(def, mutation)
		model:PivotTo(CFrame.new(Config.ConveyorStart + Vector3.new(0, 2.6, 0)))
		model.Parent = conveyorFolder
		table.insert(active, model)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyPrompt"
		prompt.ActionText = "Buy " .. def.Name
		prompt.ObjectText = BrainrotDefs.formatMoney(def.Cost) .. "  |  " .. BrainrotDefs.formatMoney(def.Rate) .. "/s"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.Parent = model.Body
		prompt.Triggered:Connect(function(player: Player)
			onBuyPrompt(player, model, def, mutation)
		end)
	end

	-- Walk every brainrot east; despawn any that reach the east end.
	local RunService = game:GetService("RunService")
	RunService.Heartbeat:Connect(function(dt: number)
		if os.clock() - lastSpawn >= Config.SpawnInterval then
			lastSpawn = os.clock()
			spawnBrainrot()
		end
		for i = #active, 1, -1 do
			local model = active[i]
			if not model.Parent then
				table.remove(active, i)
			else
				local pos = model.PrimaryPart.Position
				local nextX = pos.X + Config.ConveyorWalkSpeed * dt
				if nextX >= Config.ConveyorEnd.X then
					-- Reached the end unbought: it falls off the belt.
					model:Destroy()
					table.remove(active, i)
				else
					model:PivotTo(CFrame.new(Vector3.new(nextX, pos.Y, pos.Z)))
				end
			end
		end
	end)

	-- The wave event washes the belt clean: every unbought brainrot
	-- is swept away. ThreatService calls this when the wave hits.
	function ConveyorService.clearBelt()
		for _, model in ipairs(active) do
			model:Destroy()
		end
		table.clear(active)
	end

	-- A stolen brainrot is gone from the base for good.
	function ConveyorService.removeOwnedModel(plotCenter: Vector3, slot: number)
		for _, model in ipairs(conveyorFolder:GetChildren()) do
			if model:IsA("Model") and model.PrimaryPart then
				local pos = model.PrimaryPart.Position
				local target = slotPosition(plotCenter, slot)
				if (pos - target).Magnitude < 1 then
					model:Destroy()
					return
				end
			end
		end
	end

	return ConveyorService
end

return ConveyorService
