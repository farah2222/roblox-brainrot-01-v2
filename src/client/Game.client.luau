-- Brainrot Rumble: the client for input and effects. Keys: E buys the
-- nearest brainrot on the belt, F steals from a base you stand next to,
-- 1/2/3 fire the slap glove, freeze ray and brainrot magnet, L locks
-- your base, R rebirths, Q spins the wheel. This script never moves
-- money or brainrots itself: every key press is one RemoteEvent, and the
-- server decides whether it worked. Effects here are purely visual:
-- particle bursts on a buy, confetti on a rebirth, camera shake on a
-- wave or a hit, and floating cash popups over your base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RumbleRemotes")
local camera = workspace.CurrentCamera

-- The nearest conveyor brainrot model to the player, within a range.
local function nearestBeltBrainrot(range)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local arena = workspace:FindFirstChild("RumbleArena")
	if not arena then
		return nil
	end
	local best = nil
	local bestDist = range
	for _, model in ipairs(arena:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("Uid") then
			local dist = (model:GetPivot().Position - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = model
			end
		end
	end
	return best
end

-- The nearest owned brainrot model (someone's pen) to the player.
local function nearestPenBrainrot(range)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local folder = workspace:FindFirstChild("OwnedBrainrots")
	if not folder then
		return nil
	end
	local best = nil
	local bestDist = range
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local dist = (model:GetPivot().Position - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = model
			end
		end
	end
	return best
end

local function bindKey(name, key, fn)
	ContextActionService:BindAction(name, function(_, state, _)
		if state == Enum.UserInputState.Begin then
			fn()
		end
	end, false, key)
end

bindKey("RumbleBuy", Enum.KeyCode.E, function()
	local model = nearestBeltBrainrot(14)
	if model then
		remotes.BuyBrainrot:FireServer(model:GetAttribute("Uid"))
	end
end)

bindKey("RumbleSteal", Enum.KeyCode.F, function()
	local model = nearestPenBrainrot(9)
	if model then
		remotes.StealStart:FireServer(model:GetPivot().Position)
	end
end)

bindKey("RumbleSlap", Enum.KeyCode.One, function()
	remotes.UseWeapon:FireServer("Slap")
end)

bindKey("RumbleFreeze", Enum.KeyCode.Two, function()
	remotes.UseWeapon:FireServer("Freeze")
end)

bindKey("RumblePull", Enum.KeyCode.Three, function()
	remotes.UseWeapon:FireServer("Pull")
end)

bindKey("RumbleLock", Enum.KeyCode.L, function()
	remotes.LockBase:FireServer()
end)

bindKey("RumbleRebirth", Enum.KeyCode.R, function()
	remotes.Rebirth:FireServer()
end)

bindKey("RumbleSpin", Enum.KeyCode.Q, function()
	remotes.SpinWheel:FireServer()
end)

-- A burst of particles at a position: coloured sparks that rise and fade.
local function burst(position, color)
	local emitter = Instance.new("Part")
	emitter.Name = "Burst"
	emitter.Size = Vector3.new(0.2, 0.2, 0.2)
	emitter.Transparency = 1
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.Position = position
	emitter.Parent = workspace
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(color)
	particles.Size = NumberSequence.new(0.6)
	particles.Speed = NumberRange.new(8, 16)
	particles.Lifetime = NumberRange.new(0.5, 0.9)
	particles.Rate = 60
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = emitter
	task.delay(1, function()
		emitter:Destroy()
	end)
end

-- Confetti: forty bright squares that rain from above the player.
local function confetti()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local colors = {
		Color3.fromRGB(255, 90, 110), Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 220, 120),
		Color3.fromRGB(190, 110, 255),
	}
	for _ = 1, 40 do
		local piece = Instance.new("Part")
		piece.Size = Vector3.new(0.5, 0.1, 0.5)
		piece.Color = colors[math.random(1, #colors)]
		piece.Anchored = false
		piece.CanCollide = false
		piece.Position = root.Position + Vector3.new(math.random(-12, 12), math.random(14, 22), math.random(-12, 12))
		piece.Parent = workspace
		task.delay(3, function()
			piece:Destroy()
		end)
	end
end

-- Camera shake: a short random offset that decays.
local shakeTime = 0
local shakePower = 0
local function shake(power, seconds)
	shakePower = power
	shakeTime = seconds
end

RunService.RenderStepped:Connect(function()
	if shakeTime > 0 then
		shakeTime = shakeTime - 1 / 60
		local offset = Vector3.new(
			(math.random() - 0.5) * shakePower,
			(math.random() - 0.5) * shakePower,
			0
		)
		camera.CFrame = camera.CFrame * CFrame.new(offset)
		if shakeTime <= 0 then
			shakePower = 0
		end
	end
end)

-- A floating "+$123" popup that rises and fades above a spot.
local function cashPopup(position, text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 120, 0, 30)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.Text = text
	label.TextColor3 = Color3.fromRGB(140, 255, 140)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Position = position
	anchor.Parent = workspace
	gui.Parent = anchor
	local goal = { StudsOffset = Vector3.new(0, 7, 0) }
	TweenService:Create(gui, TweenInfo.new(1.2), goal):Play()
	task.delay(1.3, function()
		anchor:Destroy()
	end)
end

remotes.BrainrotBought.OnClientEvent:Connect(function(name, mutation, _slot)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		burst(root.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 215, 0))
	end
end)

remotes.RebirthDone.OnClientEvent:Connect(function()
	confetti()
	shake(1.2, 0.6)
end)

remotes.TsunamiHit.OnClientEvent:Connect(function()
	shake(2.5, 1.2)
end)

remotes.WeaponHit.OnClientEvent:Connect(function()
	shake(1.5, 0.5)
end)

remotes.StealDone.OnClientEvent:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		burst(root.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 90, 110))
	end
end)

-- Cash popups: every few seconds, float the income above the player.
local lastIncome = 0
remotes.HudUpdate.OnClientEvent:Connect(function(snapshot)
	lastIncome = snapshot.Income or 0
end)
task.spawn(function()
	while true do
		task.wait(3)
		if lastIncome > 0 then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				cashPopup(root.Position, "+$" .. tostring(lastIncome * 3))
			end
		end
	end
end)
