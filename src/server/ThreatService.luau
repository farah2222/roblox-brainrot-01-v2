-- Brainrot Rumble: ThreatService runs the three things that make the
-- player dash home. (1) Si Cilok Nakal, an NPC thief who visits on a
-- timer, walks to a random unlocked base and needs seconds to steal its
-- richest brainrot — touch him to shoo him away. (2) The giant noodle
-- tsunami: a warning counts down, then a noodle wall sweeps the belt,
-- washing away every unbought brainrot and shoving players backwards.
-- (3) A meteor noodle shower: flaming noodles rain down and leave
-- pickups worth cash where they land.

local RumbleConfig = require(game:GetService("ReplicatedStorage").Shared.RumbleConfig)
local BrainrotCatalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)
local GameState = require(game:GetService("ReplicatedStorage").Shared.GameState)
local MoneyFormat = require(game:GetService("ReplicatedStorage").Shared.MoneyFormat)

local ThreatService = {}

local context = nil

-- The thief currently in the arena (nil when none). Weapons bonk him
-- through TryBonkThief; touching him does the same.
local currentThief = nil -- { Model, Shooed, Victim }

-- Golden Hour: the noodle gods smile. While it lasts, income is x2 and
-- mutation rolls get extra tries. The server marks every player.
local goldenHourUntil = 0

function ThreatService.IsGoldenHour()
	return os.time() < goldenHourUntil
end

-- Bonk Si Cilok Nakal away with a weapon. Returns true when the bonk
-- landed (he is close enough to the swing). Counts for the mission.
function ThreatService.TryBonkThief(player, position, range)
	if not currentThief or not currentThief.Model or not currentThief.Model.Parent then
		return false
	end
	if currentThief.Shooed then
		return false
	end
	local pivot = currentThief.Model:GetPivot().Position
	if (pivot - position).Magnitude > range then
		return false
	end
	currentThief.Shooed = true
	local state = context.States[player]
	if state then
		state.MissionStats.Bonks = state.MissionStats.Bonks + 1
	end
	context.Remotes.ToastAll:FireAllClients(player.Name .. " BONKED Si Cilok Nakal away!")
	return true
end

-- Build Si Cilok Nakal: a red-hatted vendor with a very suspicious grin.
local function buildThief()
	local model = Instance.new("Model")
	model.Name = "SiCilokNakal"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3.5, 2)
	body.Color = Color3.fromRGB(220, 60, 60)
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.4, 2.2, 2.4)
	head.Color = Color3.fromRGB(240, 200, 150)
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 2.85, 0)
	head.Parent = model
	local hat = Instance.new("Part")
	hat.Name = "Hat"
	hat.Size = Vector3.new(4, 0.6, 4)
	hat.Color = Color3.fromRGB(255, 215, 0)
	hat.Anchored = true
	hat.CanCollide = false
	hat.Position = Vector3.new(0, 4.2, 0)
	hat.Parent = model
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 7
	humanoid.Parent = model
	local label = Instance.new("BillboardGui")
	label.Name = "ThiefLabel"
	label.Size = UDim2.new(0, 220, 0, 30)
	label.StudsOffset = Vector3.new(0, 5.5, 0)
	label.AlwaysOnTop = true
	label.Parent = model
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 18
	text.Text = "SI CILOK NAKAL!"
	text.TextColor3 = Color3.fromRGB(255, 90, 90)
	text.TextStrokeTransparency = 0.4
	text.Parent = label
	return model
end

-- One thief visit: pick a random unlocked base with brainrots, walk
-- there, channel, steal the richest one, and waddle back out.
local function thiefVisit()
	local players = game:GetService("Players"):GetPlayers()
	local candidates = {}
	for _, player in ipairs(players) do
		local state = context.States[player]
		if state and #state.Brainrots > 0 and not GameState.IsLocked(state, os.time()) then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		return
	end
	local victim = candidates[math.random(1, #candidates)]
	local victimState = context.States[victim]
	local thief = buildThief()
	thief:PivotTo(CFrame.new(-100, 3, 40))
	thief.Parent = workspace
	currentThief = { Model = thief, Shooed = false, Victim = victim }
	context.Remotes.ToastAll:FireAllClients("Si Cilok Nakal is sneaking toward " .. victim.Name .. "'s base! Touch him to shoo him — or bonk him with a weapon!")
	context.Remotes.ThiefComing:FireAllClients(victim.Name)

	local plotCenter = RumbleConfig.Plots[victimState.PlotIndex].Center
	-- Touching him shooes him (and counts as a bonk for the mission).
	local touched = thief.PrimaryPart.Touched:Connect(function(hit)
		local hitter = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
		if hitter and currentThief and not currentThief.Shooed then
			currentThief.Shooed = true
			local hitterState = context.States[hitter]
			if hitterState then
				hitterState.MissionStats.Bonks = hitterState.MissionStats.Bonks + 1
			end
			context.Remotes.ToastAll:FireAllClients(hitter.Name .. " shooed Si Cilok Nakal away!")
		end
	end)

	-- Walk to the base, one step at a time, checking for a shoo.
	local target = Vector3.new(plotCenter.X, 3, plotCenter.Z + 12)
	local steps = 0
	while steps < 400 and currentThief and not currentThief.Shooed do
		steps = steps + 1
		local pivot = thief:GetPivot().Position
		local delta = target - pivot
		delta = Vector3.new(delta.X, 0, delta.Z)
		if delta.Magnitude < 2 then
			break
		end
		local step = delta.Unit * math.min(7 * 0.1, delta.Magnitude)
		thief:PivotTo(CFrame.new(pivot + step))
		task.wait(0.1)
	end
	touched:Disconnect()
	if not currentThief then
		thief:Destroy()
		return
	end
	if currentThief.Shooed then
		context.Remotes.ToastAll:FireAllClients("Someone shooed Si Cilok Nakal away!")
		currentThief = nil
		thief:Destroy()
		return
	end
	if GameState.IsLocked(victimState, os.time()) then
		context.Remotes.ToastAll:FireAllClients("Si Cilok Nakal found the base locked and left!")
		currentThief = nil
		thief:Destroy()
		return
	end
	-- The channel: 7 seconds, interrupted if anyone touches or bonks him.
	local channelTouch = thief.PrimaryPart.Touched:Connect(function(hit)
		local hitter = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
		if hitter and currentThief and not currentThief.Shooed then
			currentThief.Shooed = true
			local hitterState = context.States[hitter]
			if hitterState then
				hitterState.MissionStats.Bonks = hitterState.MissionStats.Bonks + 1
			end
		end
	end)
	local waited = 0
	while waited < RumbleConfig.ThiefChannel and currentThief and not currentThief.Shooed do
		task.wait(0.25)
		waited = waited + 0.25
	end
	channelTouch:Disconnect()
	if not currentThief or currentThief.Shooed then
		context.Remotes.ToastAll:FireAllClients("Someone shooed Si Cilok Nakal mid-steal!")
		currentThief = nil
		thief:Destroy()
		return
	end
	local richest = GameState.RichestBrainrot(victimState)
	if richest then
		GameState.RemoveBrainrot(victimState, richest.Slot)
		context.Conveyor.ClearPen(victimState, richest.Slot)
		local def = BrainrotCatalog.Get(richest.DefId)
		local name = def and def.Name or "a brainrot"
		context.Remotes.ToastAll:FireAllClients("Si Cilok Nakal stole " .. name .. " from " .. victim.Name .. "!")
	end
	currentThief = nil
	thief:Destroy()
end

-- The tsunami: warn, then sweep a giant curling noodle wall down the
-- belt. Bigger than before, with a foamy crest and a second wall behind
-- it — and a clear RUN HOME banner on every screen.
local function tsunami()
	context.Remotes.TsunamiWarning:FireAllClients(RumbleConfig.TsunamiWarning)
	-- Five seconds out, warn the clients to shake and flash: the wave
	-- is about to hit. (The warning is 15s; if it were ever shortened,
	-- the imminent signal fires at once instead of going negative.)
	local imminentIn = math.max(0, RumbleConfig.TsunamiWarning - 5)
	task.wait(imminentIn)
	context.Remotes.TsunamiImminent:FireAllClients()
	task.wait(RumbleConfig.TsunamiWarning - imminentIn)
	-- Everyone in the arena when the wave comes survives it (mission).
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local state = context.States[player]
		if state then
			state.MissionStats.TsunamisSurvived = state.MissionStats.TsunamisSurvived + 1
		end
	end
	-- The wave is a Model so the whole wall, crest and noodles sweep together.
	local waveModel = Instance.new("Model")
	waveModel.Name = "TsunamiWall"
	local wave = Instance.new("Part")
	wave.Name = "Wall"
	wave.Size = Vector3.new(10, 30, 150)
	wave.Color = Color3.fromRGB(250, 210, 90)
	wave.Material = Enum.Material.SmoothPlastic
	wave.Transparency = 0.15
	wave.Anchored = true
	wave.CanCollide = false
	wave.Position = Vector3.new(-70, 15, 0)
	wave.Parent = waveModel
	waveModel.PrimaryPart = wave
	-- A foamy crest curling over the top of the wall.
	for _, z in ipairs({ -60, -45, -30, -15, 0, 15, 30, 45, 60 }) do
		local foam = Instance.new("Part")
		foam.Name = "WaveCrest"
		foam.Shape = Enum.PartType.Ball
		foam.Size = Vector3.new(8, 8, 8)
		foam.Color = Color3.fromRGB(255, 240, 180)
		foam.Material = Enum.Material.SmoothPlastic
		foam.Transparency = 0.1
		foam.Anchored = true
		foam.CanCollide = false
		foam.Position = Vector3.new(-70, 30, z)
		foam.Parent = waveModel
	end
	-- A second, shorter wall trailing behind for depth.
	local backWall = Instance.new("Part")
	backWall.Name = "TsunamiBackWall"
	backWall.Size = Vector3.new(6, 18, 150)
	backWall.Color = Color3.fromRGB(240, 180, 60)
	backWall.Material = Enum.Material.SmoothPlastic
	backWall.Transparency = 0.35
	backWall.Anchored = true
	backWall.CanCollide = false
	backWall.Position = Vector3.new(-76, 9, 0)
	backWall.Parent = waveModel
	for _, n in ipairs({ -60, -40, -20, 0, 20, 40, 60 }) do
		local noodle = Instance.new("Part")
		noodle.Name = "NoodleChunk"
		noodle.Size = Vector3.new(2, 3, 6)
		noodle.Color = Color3.fromRGB(240, 190, 60)
		noodle.Anchored = true
		noodle.CanCollide = false
		noodle.Position = Vector3.new(-70, 31, n)
		noodle.Parent = waveModel
	end
	waveModel.Parent = workspace
	context.Remotes.TsunamiHit:FireAllClients()
	-- The wave knocks carried brainrots out of everyone's hands and
	-- breaks every buy streak: run home BEFORE the wave, or lose the
	-- catch and the combo with it.
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local state = context.States[player]
		if state then
			if state.Carrying then
				context.Conveyor.DropCarry(player, state)
			end
			GameState.ResetCombo(state)
		end
	end
	-- Sweep east, washing the belt clean and shoving players.
	local x = -70
	while x < 70 do
		x = x + 2
		waveModel:PivotTo(CFrame.new(x, 15, 0))
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and math.abs(root.Position.X - x) < 6 then
				root.AssemblyLinearVelocity = Vector3.new(RumbleConfig.TsunamiShove, 14, 0)
			end
		end
		task.wait(0.05)
	end
	waveModel:Destroy()
	context.Conveyor.WashBelt()
	context.Remotes.ToastAll:FireAllClients("The tsunami swept the belt clean!")
end

-- Golden Noodle Hour: the noodle gods smile on the arena. Income x2 and
-- rare mutations rain for a minute. Themed to our world — golden noodles,
-- not a generic timer.
local function goldenHour()
	local now = os.time()
	goldenHourUntil = now + RumbleConfig.GoldenHourDuration
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local state = context.States[player]
		if state then
			state.GoldenHourUntil = goldenHourUntil
		end
	end
	context.Remotes.GoldenHour:FireAllClients(RumbleConfig.GoldenHourDuration)
	context.Remotes.ToastAll:FireAllClients("GOLDEN NOODLE HOUR! The noodle gods smile — income x2, rare mutations rain for 60s!")
end

-- The meteor shower: flaming noodles rain down and leave cash pickups.
local function meteorShower()
	context.Remotes.ToastAll:FireAllClients("Meteor noodles incoming! Grab the glowing pickups!")
	for _ = 1, RumbleConfig.MeteorCount do
		local x = math.random(-80, 80)
		local z = math.random(-50, 50)
		local meteor = Instance.new("Part")
		meteor.Name = "MeteorNoodle"
		meteor.Size = Vector3.new(2, 2, 4)
		meteor.Color = Color3.fromRGB(255, 120, 40)
		meteor.Material = Enum.Material.Neon
		meteor.Anchored = true
		meteor.CanCollide = false
		meteor.Position = Vector3.new(x, 60, z)
		meteor.Parent = workspace
		task.spawn(function()
			local y = 60
			while y > 2 do
				y = y - 3
				if meteor.Parent then
					meteor.Position = Vector3.new(x, y, z)
				end
				task.wait(0.05)
			end
			if not meteor.Parent then
				return
			end
			meteor.Color = Color3.fromRGB(255, 215, 0)
			meteor.Size = Vector3.new(3, 1, 3)
			meteor.Position = Vector3.new(x, 1.5, z)
			local cashValue = RumbleConfig.MeteorCash
			local touchConn
			touchConn = meteor.Touched:Connect(function(hit)
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local state = context.States[player]
				if not state then
					return
				end
				GameState.AddCash(state, cashValue)
				context.Remotes.Toast:FireClient(player, "Meteor noodle! +" .. MoneyFormat.Cash(cashValue))
				touchConn:Disconnect()
				meteor:Destroy()
			end)
			task.delay(20, function()
				if meteor.Parent then
					if touchConn then
						touchConn:Disconnect()
					end
					meteor:Destroy()
				end
			end)
		end)
		task.wait(0.7)
	end
end

function ThreatService.Start(ctx)
	context = ctx
	task.spawn(function()
		while true do
			task.wait(RumbleConfig.ThiefEvery)
			thiefVisit()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(RumbleConfig.TsunamiEvery)
			tsunami()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(RumbleConfig.MeteorEvery)
			meteorShower()
		end
	end)
	-- Golden Noodle Hour: the first one comes quickly so players see it,
	-- then on its regular timer.
	task.spawn(function()
		task.wait(45)
		while true do
			goldenHour()
			task.wait(RumbleConfig.GoldenHourEvery)
		end
	end)
end

return ThreatService
