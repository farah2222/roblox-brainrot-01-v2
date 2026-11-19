-- Brainrot Rumble: ConveyorService runs the heart of the loop. It spawns
-- brainrots at the west gate, marches them east along the belt, and sells
-- them: a player who walks up and presses E buys one, and it waddles to
-- a free pen on their home plot and starts earning. Unbought brainrots
-- that reach the east gate fall off and despawn.

local BrainrotCatalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)
local RumbleConfig = require(game:GetService("ReplicatedStorage").Shared.RumbleConfig)
local GameState = require(game:GetService("ReplicatedStorage").Shared.GameState)
local MoneyFormat = require(game:GetService("ReplicatedStorage").Shared.MoneyFormat)
local WorldBuilder = require(script.Parent.WorldBuilder)

local ConveyorService = {}

local active = {} -- uid -> { Model, Def, Mutation, Price, Boss }
local nextUid = 1
local context = nil

local MUTATION_TINTS = {
	Golden = Color3.fromRGB(255, 215, 0),
	Lava = Color3.fromRGB(255, 90, 30),
	Rainbow = Color3.fromRGB(255, 120, 220),
	Diamond = Color3.fromRGB(140, 230, 255),
	Glitch = Color3.fromRGB(180, 60, 255),
}

local function colorFrom(def, which)
	local triple = def[which]
	return Color3.fromRGB(triple[1], triple[2], triple[3])
end

-- Build the blocky model for one brainrot. Shape picks the body size,
-- the mutation tints the body, a boss gets twice the scale and a crown.
function ConveyorService.BuildModel(def, mutation, boss)
	local scale = 1
	if boss then
		scale = RumbleConfig.BossScale
	end
	local model = Instance.new("Model")
	model.Name = def.Name

	local bodySize = Vector3.new(3, 3, 3)
	if def.Shape == "tall" then
		bodySize = Vector3.new(2.6, 4.2, 2.6)
	elseif def.Shape == "wide" then
		bodySize = Vector3.new(4.4, 2.6, 3)
	elseif def.Shape == "round" then
		bodySize = Vector3.new(3.4, 3.4, 3.4)
	end
	bodySize = bodySize * scale

	local bodyColor = colorFrom(def, "Body")
	if mutation ~= "Normal" and MUTATION_TINTS[mutation] then
		bodyColor = bodyColor:Lerp(MUTATION_TINTS[mutation], 0.45)
	end

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = bodySize
	body.Color = bodyColor
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body

	local headSize = Vector3.new(2.4, 2.2, 2.4) * scale
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = headSize
	head.Color = colorFrom(def, "Head")
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, (bodySize.Y / 2) + (headSize.Y / 2), 0)
	head.Parent = model

	local eyeSize = Vector3.new(0.3, 0.6, 0.5) * scale
	for _, z in ipairs({ 0.6, -0.6 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = eyeSize
		eye.Color = Color3.fromRGB(20, 20, 20)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = Vector3.new(headSize.X / 2, (bodySize.Y / 2) + (headSize.Y / 2) + 0.3 * scale, z * scale)
		eye.Parent = model
	end

	local accessory = def.Accessory
	if boss then
		accessory = "crown"
	end
	local topY = (bodySize.Y / 2) + headSize.Y
	if accessory == "tophat" then
		local hat = Instance.new("Part")
		hat.Name = "TopHat"
		hat.Size = Vector3.new(1.8, 2, 1.8) * scale
		hat.Color = Color3.fromRGB(25, 25, 25)
		hat.Anchored = true
		hat.CanCollide = false
		hat.Position = Vector3.new(0, topY + (1 * scale), 0)
		hat.Parent = model
	elseif accessory == "crown" then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(2.6, 0.9, 2.6) * scale
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Anchored = true
		crown.CanCollide = false
		crown.Position = Vector3.new(0, topY + (0.45 * scale), 0)
		crown.Parent = model
	elseif accessory == "sunglasses" then
		local shades = Instance.new("Part")
		shades.Name = "Sunglasses"
		shades.Size = Vector3.new(0.3, 0.5, 2) * scale
		shades.Color = Color3.fromRGB(15, 15, 15)
		shades.Anchored = true
		shades.CanCollide = false
		shades.Position = Vector3.new(headSize.X / 2, (bodySize.Y / 2) + (headSize.Y / 2) + 0.4 * scale, 0)
		shades.Parent = model
	elseif accessory == "chefhat" then
		local chef = Instance.new("Part")
		chef.Name = "ChefHat"
		chef.Size = Vector3.new(2.4, 1.6, 2.4) * scale
		chef.Color = Color3.fromRGB(255, 255, 255)
		chef.Anchored = true
		chef.CanCollide = false
		chef.Position = Vector3.new(0, topY + (0.8 * scale), 0)
		chef.Parent = model
	elseif accessory == "cape" then
		local cape = Instance.new("Part")
		cape.Name = "Cape"
		cape.Size = Vector3.new(0.4, 3.4, 2.8) * scale
		cape.Color = colorFrom(def, "Accent")
		cape.Anchored = true
		cape.CanCollide = false
		cape.Position = Vector3.new(-(bodySize.X / 2) - 0.2, bodySize.Y / 2, 0)
		cape.Parent = model
	elseif accessory == "sombrero" then
		local brim = Instance.new("Part")
		brim.Name = "Sombrero"
		brim.Size = Vector3.new(4.4, 0.3, 4.4) * scale
		brim.Color = Color3.fromRGB(240, 200, 90)
		brim.Anchored = true
		brim.CanCollide = false
		brim.Position = Vector3.new(0, topY + (0.2 * scale), 0)
		brim.Parent = model
	end

	return model
end

-- The floating label above a brainrot: name, rarity (+ mutation), $/s and price.
local function attachLabel(model, def, mutation, price, boss)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.new(0, 220, 0, 84)
	gui.StudsOffset = Vector3.new(0, 5.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local title = (boss and "BOSS " or "") .. def.Name
	if mutation ~= "Normal" then
		title = title .. " (" .. mutation .. ")"
	end
	local lines = {
		{ Text = title, Color = Color3.fromRGB(255, 255, 255), Size = 17 },
		{ Text = def.Rarity, Color = BrainrotCatalog.RarityColor(def.Rarity), Size = 15 },
		{ Text = MoneyFormat.Short(BrainrotCatalog.EffectiveRate(def, mutation)) .. "/s  -  " .. MoneyFormat.Cash(price), Color = Color3.fromRGB(140, 255, 140), Size = 15 },
	}
	for i, line in ipairs(lines) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 26)
		label.Position = UDim2.new(0, 0, 0, (i - 1) * 26)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = line.Size
		label.Text = line.Text
		label.TextColor3 = line.Color
		label.TextStrokeTransparency = 0.4
		label.Parent = gui
	end
end

-- Spawn one brainrot at the west gate and set it marching.
local function spawnOne()
	if #active >= RumbleConfig.BeltCapacity then
		return
	end
	local rarity = BrainrotCatalog.RollRarity()
	local def = BrainrotCatalog.RandomOfRarity(rarity)
	-- Golden Hour: roll the mutation several times, keep the best.
	local mutation = BrainrotCatalog.RollMutation()
	if context.Threat and context.Threat.IsGoldenHour() then
		mutation = BrainrotCatalog.RollMutation(RumbleConfig.GoldenHourMutationRolls)
	end
	local boss = rarity == "Secret" and math.random() < RumbleConfig.BossChance
	local price = def.Cost
	if boss then
		price = price * 2
	end

	local uid = nextUid
	nextUid = nextUid + 1
	local model = ConveyorService.BuildModel(def, mutation, boss)
	model:SetAttribute("Uid", uid)
	attachLabel(model, def, mutation, price, boss)
	local z = math.random(-150, 150) / 100
	model:PivotTo(CFrame.new(RumbleConfig.BeltFrom.X, RumbleConfig.BeltFrom.Y + 2, z))
	model.Parent = workspace.RumbleArena

	active[uid] = { Model = model, Def = def, Mutation = mutation, Price = price, Boss = boss, Uid = uid }
end

-- The nearest marching brainrot to a position, within a range, or nil.
function ConveyorService.Nearest(position, range)
	local best = nil
	local bestDist = range
	for _, entry in pairs(active) do
		local pivot = entry.Model:GetPivot().Position
		local dist = (pivot - position).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = entry
		end
	end
	return best
end

-- Pull the nearest marching brainrot to a spot (the magnet weapon).
function ConveyorService.PullNearest(position, range, target)
	local entry = ConveyorService.Nearest(position, range)
	if not entry then
		return nil
	end
	entry.Model:PivotTo(CFrame.new(target.X, RumbleConfig.BeltFrom.Y + 2, target.Z))
	return entry
end

-- Place a bought brainrot on a player's pen, as a permanent model.
-- Returns the slot, or nil when the base is full. comboMult / comboUntil
-- stamp a buy-streak bonus on it (see GameState.AddBrainrot).
function ConveyorService.PlaceOnBase(defId, mutation, state, world, comboMult, comboUntil)
	local def = BrainrotCatalog.Get(defId)
	if not def then
		return nil
	end
	local slot = GameState.AddBrainrot(state, defId, mutation, comboMult, comboUntil)
	if not slot then
		return nil
	end
	GameState.MarkDiscovered(state, defId)
	local model = ConveyorService.BuildModel(def, mutation, false)
	local pos = WorldBuilder.PenPosition(state.PlotIndex, slot)
	model:PivotTo(CFrame.new(pos.X, pos.Y + 2, pos.Z))
	local folder = workspace:FindFirstChild("OwnedBrainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "OwnedBrainrots"
		folder.Parent = workspace
	end
	model.Parent = folder
	local label = model:FindFirstChild("BrainrotLabel")
	if label then
		label:Destroy()
	end
	attachLabel(model, def, mutation, 0, false)
	return slot
end

-- The carry: when a player buys (or steals) a brainrot they CARRY it
-- home in their hands instead of it teleporting. The model rides in
-- front of them; when they reach their own plot with a free pen, it
-- walks itself into the pen. A weapon hit makes them drop it.
-- Carrying is heavy: you walk slower while loaded, but delivering pays
-- a bonus by tier — the rarer the catch, the slower you run and the
-- more the delivery pays.
function ConveyorService.RefreshWalkSpeed(player, state)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local speed = GameState.WalkSpeed(state)
	if state.Carrying then
		speed = speed * RumbleConfig.CarrySlow
	end
	humanoid.WalkSpeed = speed
end

-- comboMult / comboUntil stamp a buy-streak bonus on the carried
-- brainrot (it earns at that tier for a minute once it is penned).
-- Stolen brainrots carry no combo: the thief did not earn the streak.
function ConveyorService.StartCarry(player, defId, mutation, state, fromVictim, comboMult, comboUntil)
	if state.Carrying then
		return false
	end
	if not GameState.FreeSlot(state) then
		return false
	end
	local def = BrainrotCatalog.Get(defId)
	if not def then
		return false
	end
	local model = ConveyorService.BuildModel(def, mutation, false)
	model:SetAttribute("CarriedBy", player.Name)
	attachLabel(model, def, mutation, 0, false)
	model.Parent = workspace
	state.Carrying = { DefId = defId, Mutation = mutation, Model = model, FromVictim = fromVictim, ComboMult = comboMult or 1, ComboUntil = comboUntil or 0 }
	ConveyorService.RefreshWalkSpeed(player, state)
	return true
end

-- Drop the brainrot a player is carrying (a weapon hit did this).
-- The brainrot is lost: it despawns with a puff.
function ConveyorService.DropCarry(player, state)
	local carrying = state.Carrying
	if not carrying then
		return nil
	end
	state.Carrying = nil
	if carrying.Model and carrying.Model.Parent then
		carrying.Model:Destroy()
	end
	local def = BrainrotCatalog.Get(carrying.DefId)
	local name = def and def.Name or "a brainrot"
	if context and context.Remotes then
		context.Remotes.Toast:FireClient(player, "You dropped " .. name .. "!")
	end
	ConveyorService.RefreshWalkSpeed(player, state)
	return carrying.DefId
end

-- Is this player carrying a brainrot right now?
function ConveyorService.IsCarrying(state)
	return state.Carrying ~= nil
end

-- Wash the belt: destroy every marching brainrot (the tsunami's doing).
function ConveyorService.WashBelt()
	for uid, entry in pairs(active) do
		entry.Model:Destroy()
		active[uid] = nil
	end
end

-- Remove a brainrot's model from a pen (stolen, or rebirth wipe).
function ConveyorService.ClearPen(state, slot)
	local folder = workspace:FindFirstChild("OwnedBrainrots")
	if not folder then
		return
	end
	local pos = WorldBuilder.PenPosition(state.PlotIndex, slot)
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local pivot = model:GetPivot().Position
			if (pivot - pos).Magnitude < 3 then
				model:Destroy()
			end
		end
	end
end

-- Wipe every owned model (rebirth).
function ConveyorService.ClearAllPens()
	local folder = workspace:FindFirstChild("OwnedBrainrots")
	if folder then
		folder:ClearAllChildren()
	end
end

local function buyBrainrot(player, uid)
	local state = context.States[player]
	if not state then
		return
	end
	local entry = active[uid]
	if not entry then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local pivot = entry.Model:GetPivot().Position
	if (pivot - root.Position).Magnitude > 14 then
		context.Remotes.Toast:FireClient(player, "Too far from that brainrot!")
		return
	end
	if not GameState.Spend(state, entry.Price) then
		context.Remotes.Toast:FireClient(player, "Not enough cash for " .. entry.Def.Name .. "!")
		return
	end
	if state.Carrying then
		GameState.AddCash(state, entry.Price)
		context.Remotes.Toast:FireClient(player, "You are already carrying a brainrot! Take it home first.")
		return
	end
	if not GameState.FreeSlot(state) then
		GameState.AddCash(state, entry.Price)
		context.Remotes.Toast:FireClient(player, "Your base is full! Rebirth to clear it.")
		return
	end
	state.MissionStats.Buys = state.MissionStats.Buys + 1
	-- The combo: buy again within the window and the streak climbs a
	-- tier (x1 -> x5). The brainrot you just bought earns at that tier
	-- for a minute once it is penned. The streak only advances on a
	-- real purchase, so work it out here and commit it after the pickup.
	local now = os.time()
	local prevCombo = state.ComboCount
	local comboTier = 1
	if prevCombo > 0 and now <= state.ComboUntil then
		comboTier = math.min(prevCombo + 1, RumbleConfig.ComboMax)
	end
	local comboUntil = now + RumbleConfig.ComboBonusDuration
	if not ConveyorService.StartCarry(player, entry.Def.Id, entry.Mutation, state, nil, comboTier, comboUntil) then
		GameState.AddCash(state, entry.Price)
		context.Remotes.Toast:FireClient(player, "Could not pick up " .. entry.Def.Name .. "!")
		return
	end
	state.ComboCount = comboTier
	state.ComboUntil = now + RumbleConfig.ComboWindow
	entry.Model:Destroy()
	active[uid] = nil
	context.Remotes.BrainrotBought:FireClient(player, entry.Def.Name, entry.Mutation, 0)
	context.Remotes.Toast:FireClient(player, "Bought " .. entry.Def.Name .. " for " .. MoneyFormat.Cash(entry.Price) .. "! Carry it home to your base!")
	if comboTier > prevCombo and comboTier >= 2 then
		context.Remotes.Toast:FireClient(player, "COMBO x" .. comboTier .. "! This brainrot earns x" .. comboTier .. " for 60s — buy again within " .. RumbleConfig.ComboWindow .. "s to climb!")
	end
end

function ConveyorService.Start(ctx)
	context = ctx
	context.Remotes.BuyBrainrot.OnServerEvent:Connect(buyBrainrot)

	-- The march: every heartbeat, step each brainrot east; despawn at the gate.
	local RunService = game:GetService("RunService")
	RunService.Heartbeat:Connect(function(dt)
		for uid, entry in pairs(active) do
			local pivot = entry.Model:GetPivot()
			local nextX = pivot.Position.X + RumbleConfig.MarchSpeed * dt
			if nextX >= RumbleConfig.BeltTo.X then
				entry.Model:Destroy()
				active[uid] = nil
			else
				entry.Model:PivotTo(CFrame.new(nextX, pivot.Position.Y, pivot.Position.Z))
			end
		end
		-- The carry: each carried brainrot rides in front of its player,
		-- and walks itself into a free pen when the player reaches home.
		for player, playerState in pairs(context.States) do
			local carrying = playerState.Carrying
			if carrying and carrying.Model and carrying.Model.Parent then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					local look = root.CFrame.LookVector
					local bob = math.sin(os.clock() * 6) * 0.4
					local pos = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 3.4 + Vector3.new(0, 2.5 + bob, 0)
					-- The model's face is +X; turn it to face where the player faces.
					local yaw = math.atan2(-look.Z, look.X)
					carrying.Model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, yaw, 0))
					-- Home? A free pen on this player's plot takes it.
					local plot = RumbleConfig.Plots[playerState.PlotIndex]
					if plot then
						local dx = root.Position.X - plot.Center.X
						local dz = root.Position.Z - plot.Center.Z
						if dx * dx + dz * dz < 14 * 14 and GameState.FreeSlot(playerState) then
							local defId = carrying.DefId
							local mutation = carrying.Mutation
							local comboMult = carrying.ComboMult or 1
							local comboUntil = carrying.ComboUntil or 0
							carrying.Model:Destroy()
							playerState.Carrying = nil
							ConveyorService.RefreshWalkSpeed(player, playerState)
							local slot = ConveyorService.PlaceOnBase(defId, mutation, playerState, context.World, comboMult, comboUntil)
							if slot then
								-- Delivering refreshes the combo window: the
								-- carry itself does not eat the streak, only
								-- the walk back to the belt does.
								if playerState.ComboCount > 0 then
									playerState.ComboUntil = os.time() + RumbleConfig.ComboWindow
								end
								local def = BrainrotCatalog.Get(defId)
								local bonus = def and (RumbleConfig.DeliveryBonus[def.Rarity] or 0) or 0
								local message = "Delivered " .. (def and def.Name or "a brainrot") .. " to your base!"
								if bonus > 0 then
									GameState.AddCash(playerState, bonus)
									message = message .. " Delivery bonus +" .. MoneyFormat.Cash(bonus) .. "!"
								end
								context.Remotes.Toast:FireClient(player, message)
							end
						end
					end
				end
			end
		end
	end)

	-- The spawner.
	task.spawn(function()
		while true do
			task.wait(RumbleConfig.SpawnEvery)
			spawnOne()
		end
	end)
	spawnOne()
	spawnOne()
end

return ConveyorService
