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
	context.Remotes.ToastAll:FireAllClients("Si Cilok Nakal is sneaking toward " .. victim.Name .. "'s base! Touch him to shoo him!")
	context.Remotes.ThiefComing:FireAllClients(victim.Name)

	local plotCenter = RumbleConfig.Plots[victimState.PlotIndex].Center
	local shooed = false
	local touched = thief.PrimaryPart.Touched:Connect(function(hit)
		local hitter = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
		if hitter then
			shooed = true
		end
	end)

	-- Walk to the base, one step at a time, checking for a shoo.
	local target = Vector3.new(plotCenter.X, 3, plotCenter.Z + 12)
	local steps = 0
	while steps < 400 and not shooed do
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
	if shooed then
		context.Remotes.ToastAll:FireAllClients("Someone shooed Si Cilok Nakal away!")
		thief:Destroy()
		return
	end
	if GameState.IsLocked(victimState, os.time()) then
		context.Remotes.ToastAll:FireAllClients("Si Cilok Nakal found the base locked and left!")
		thief:Destroy()
		return
	end
	-- The channel: 7 seconds, interrupted if anyone touches him now.
	local channelDone = false
	local channelTouch = thief.PrimaryPart.Touched:Connect(function(hit)
		local hitter = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
		if hitter then
			shooed = true
		end
	end)
	local waited = 0
	while waited < RumbleConfig.ThiefChannel and not shooed do
		task.wait(0.25)
		waited = waited + 0.25
	end
	channelTouch:Disconnect()
	channelDone = not shooed
	if not channelDone then
		context.Remotes.ToastAll:FireAllClients("Someone shooed Si Cilok Nakal mid-steal!")
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
	thief:Destroy()
end

-- The tsunami: warn, then sweep a noodle wall down the belt.
local function tsunami()
	context.Remotes.TsunamiWarning:FireAllClients(RumbleConfig.TsunamiWarning)
	task.wait(RumbleConfig.TsunamiWarning)
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWall"
	wave.Size = Vector3.new(8, 22, 150)
	wave.Color = Color3.fromRGB(250, 210, 90)
	wave.Material = Enum.Material.SmoothPlastic
	wave.Transparency = 0.2
	wave.Anchored = true
	wave.CanCollide = false
	wave.Position = Vector3.new(-70, 11, 0)
	wave.Parent = workspace
	for _, n in ipairs({ -60, -40, -20, 0, 20, 40, 60 }) do
		local noodle = Instance.new("Part")
		noodle.Name = "NoodleChunk"
		noodle.Size = Vector3.new(2, 3, 6)
		noodle.Color = Color3.fromRGB(240, 190, 60)
		noodle.Anchored = true
		noodle.CanCollide = false
		noodle.Position = Vector3.new(-70, 23, n)
		noodle.Parent = wave
	end
	context.Remotes.TsunamiHit:FireAllClients()
	-- Sweep east, washing the belt clean and shoving players.
	local x = -70
	while x < 70 do
		x = x + 2
		wave.Position = Vector3.new(x, 11, 0)
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and math.abs(root.Position.X - x) < 6 then
				root.AssemblyLinearVelocity = Vector3.new(RumbleConfig.TsunamiShove, 14, 0)
			end
		end
		task.wait(0.05)
	end
	wave:Destroy()
	context.Conveyor.WashBelt()
	context.Remotes.ToastAll:FireAllClients("The tsunami swept the belt clean!")
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
end

return ThreatService
