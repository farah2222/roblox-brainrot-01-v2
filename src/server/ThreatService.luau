-- Brainrot Bay: ThreatService runs the two things that make the
-- player dash home. (1) Sticky-Fingers Stan, an NPC thief who visits
-- every ~75 seconds, walks to a random unlocked base and needs 6
-- uninterrupted seconds to steal a brainrot -- a player who touches
-- him shoos him away. (2) The Noodle Tsunami: every ~150 seconds a
-- 15-second warning sounds, then a giant noodle wave sweeps the
-- conveyor (unbought brainrots wash away) and knocks every player
-- backwards. A locked base is safe from Stan, never from the wave.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local GameState = require(ReplicatedStorage.Shared.GameState)

local ThreatService = {}

-- Build Stan: a shifty blocky thief in a striped shirt and a mask.
local function buildThief(): Model
	local model = Instance.new("Model")
	model.Name = "StickyFingersStan"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3.4, 2.4)
	body.Color = Color3.fromRGB(40, 40, 45)
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.4, 2.2, 2.4)
	head.Color = Color3.fromRGB(230, 190, 150)
	head.Anchored = true
	head.CanCollide = false
	head.Position = body.Position + Vector3.new(0, 2.8, 0)
	head.Parent = model
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(0.3, 0.6, 2)
	mask.Color = Color3.fromRGB(15, 15, 15)
	mask.Anchored = true
	mask.CanCollide = false
	mask.Position = head.Position + Vector3.new(1.25, 0.4, 0)
	mask.Parent = model
	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Size = Vector3.new(2, 2.4, 1.6)
	sack.Color = Color3.fromRGB(150, 110, 60)
	sack.Anchored = true
	sack.CanCollide = false
	sack.Position = body.Position + Vector3.new(-1.9, 0.5, 0)
	sack.Parent = model
	-- The label above his head, so everyone knows who he is.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ThiefLabel"
	billboard.Size = UDim2.fromOffset(200, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "STICKY-FINGERS STAN"
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
	return model
end

-- Build the wave: a huge wall of noodle-yellow water.
local function buildWave(): Model
	local model = Instance.new("Model")
	model.Name = "NoodleTsunami"
	local wall = Instance.new("Part")
	wall.Name = "Wave"
	wall.Size = Vector3.new(8, 40, 130)
	wall.Color = Color3.fromRGB(250, 210, 90)
	wall.Material = Enum.Material.Water
	wall.Anchored = true
	wall.CanCollide = false
	wall.Transparency = 0.25
	wall.Parent = model
	model.PrimaryPart = wall
	-- Noodle strands on the crest.
	for i = -3, 3 do
		local noodle = Instance.new("Part")
		noodle.Name = "Noodle"
		noodle.Size = Vector3.new(2, 3, 6)
		noodle.Color = Color3.fromRGB(240, 190, 60)
		noodle.Anchored = true
		noodle.CanCollide = false
		noodle.Position = Vector3.new(0, 21, i * 18)
		noodle.Parent = model
	end
	return model
end

-- Start the service. deps: { States, Plots, Remotes, Workspace, Conveyor }.
function ThreatService.start(deps)
	local states = deps.States
	local plots = deps.Plots
	local remotes = deps.Remotes
	local workspace = deps.Workspace
	local Players = game:GetService("Players")

	local thiefFolder = Instance.new("Folder")
	thiefFolder.Name = "Thieves"
	thiefFolder.Parent = workspace

	-- Stan's visit: pick a random player with an unlocked base that
	-- actually holds a brainrot, walk Stan to it, and steal unless a
	-- player touches him first (touching = tagged = shooed away).
	local function thiefVisit()
		local candidates = {}
		for player, state in pairs(states) do
			if #state.Owned > 0 and not GameState.isLocked(state) and plots[player] then
				table.insert(candidates, player)
			end
		end
		if #candidates == 0 then
			return
		end
		local victim = candidates[math.random(1, #candidates)]
		local state = states[victim]
		local plotCenter = plots[victim]
		local stan = buildThief()
		stan:PivotTo(CFrame.new(Vector3.new(-70, 3.5, 0)))
		stan.Parent = thiefFolder
		remotes.ThiefAlert:FireAllClients(victim.Name .. " is being robbed by Sticky-Fingers Stan!")

		local shooed = false
		-- Any player who touches Stan shoos him off.
		local touch = stan.Body.Touched:Connect(function(hit: BasePart)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				shooed = true
			end
		end)

		-- Walk Stan to the victim's base, one stud at a time.
		local target = plotCenter + Vector3.new(0, 2.5, 8)
		local pos = stan.PrimaryPart.Position
		while (Vector3.new(target.X, pos.Y, target.Z) - pos).Magnitude > 2 and not shooed do
			local dir = (target - pos)
			dir = Vector3.new(dir.X, 0, dir.Z).Unit
			pos += dir * 6 * 0.1
			stan:PivotTo(CFrame.new(Vector3.new(pos.X, 3.5, pos.Z)))
			task.wait(0.1)
		end

		if not shooed then
			-- Stan channels the steal for 6 seconds; a touch breaks it.
			local stealUntil = os.clock() + Config.ThiefStealTime
			while os.clock() < stealUntil and not shooed do
				task.wait(0.2)
			end
			if not shooed and #state.Owned > 0 then
				-- He grabs the richest brainrot on the base.
				local richest = state.Owned[1]
				for _, owned in ipairs(state.Owned) do
					if owned.DefId > richest.DefId then
						richest = owned
					end
				end
				GameState.removeFromSlot(state, richest.Slot)
				deps.Conveyor.removeOwnedModel(plotCenter, richest.Slot)
				remotes.ThiefAlert:FireAllClients("Stan stole a brainrot from " .. victim.Name .. "'s base!")
				remotes.Popup:FireClient(victim, "Stan stole one of your brainrots! Lock your base!")
			end
		else
			remotes.ThiefAlert:FireAllClients("Someone shooed Sticky-Fingers Stan away!")
		end
		touch:Disconnect()
		stan:Destroy()
	end

	-- The wave: warn, then sweep the conveyor and knock players back.
	local function waveEvent()
		remotes.WaveWarning:FireAllClients(Config.WaveWarning)
		task.wait(Config.WaveWarning)

		local wave = buildWave()
		wave:PivotTo(CFrame.new(Vector3.new(-70, 20, 0)))
		wave.Parent = workspace
		-- Sweep east across the island.
		for x = -70, 90, 4 do
			wave:PivotTo(CFrame.new(Vector3.new(x, 20, 0)))
			task.wait(0.05)
		end
		-- Wash the belt clean and knock every player backwards.
		deps.Conveyor.clearBelt()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				root.AssemblyLinearVelocity = Vector3.new(40, 25, 0)
				task.delay(0.6, function()
					if humanoid.Parent then
						humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
			end
		end
		remotes.WaveHit:FireAllClients()
		task.wait(1)
		wave:Destroy()
	end

	-- The two threat loops, forever.
	task.spawn(function()
		while true do
			task.wait(Config.ThiefInterval)
			thiefVisit()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.WaveInterval)
			waveEvent()
		end
	end)

	return ThreatService
end

return ThreatService
