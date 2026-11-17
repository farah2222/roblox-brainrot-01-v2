-- Brainrot Bay: the client. It draws the HUD (cash, $/s, rebirths,
-- lock status, wave timer, shop and rebirth buttons), shows toast
-- popups, and plays the effects: particles on a buy, cash popups over
-- the base, screen shake when the wave hits, confetti on a rebirth.
-- The client never owns state -- every number on screen comes from
-- the server's CashUpdate snapshots over RemoteEvents.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("BrainrotBayRemotes")
local CashUpdate = remotes:WaitForChild("CashUpdate")
local BoughtBrainrot = remotes:WaitForChild("BoughtBrainrot")
local WaveWarning = remotes:WaitForChild("WaveWarning")
local WaveHit = remotes:WaitForChild("WaveHit")
local ThiefAlert = remotes:WaitForChild("ThiefAlert")
local LockUpdate = remotes:WaitForChild("LockUpdate")
local RebirthDone = remotes:WaitForChild("RebirthDone")
local Popup = remotes:WaitForChild("Popup")
local BuyLock = remotes:WaitForChild("BuyLock")
local Rebirth = remotes:WaitForChild("Rebirth")
local BuyUpgrade = remotes:WaitForChild("BuyUpgrade")

-- The whole HUD, one ScreenGui. Roblox's own menu buttons sit over
-- the top-left corner, so the money bar lives top-centre instead.
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent: Instance, name: string, pos: UDim2, size: UDim2, text: string, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = pos
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, pos: UDim2, size: UDim2, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = pos
	button.Size = size
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

-- Top-centre money bar: cash, $/s, rebirths.
local moneyBar = Instance.new("Frame")
moneyBar.Name = "MoneyBar"
moneyBar.AnchorPoint = Vector2.new(0.5, 0)
moneyBar.Position = UDim2.new(0.5, 0, 0, 12)
moneyBar.Size = UDim2.fromOffset(460, 64)
moneyBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
moneyBar.BackgroundTransparency = 0.15
moneyBar.BorderSizePixel = 0
moneyBar.Parent = gui
local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 14)
moneyCorner.Parent = moneyBar

local cashLabel = makeLabel(moneyBar, "Cash", UDim2.new(0, 12, 0, 4), UDim2.new(0.6, 0, 0.55, 0), "$100", 28, Color3.fromRGB(140, 255, 140))
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
local perSecondLabel = makeLabel(moneyBar, "PerSecond", UDim2.new(0.6, 0, 0, 8), UDim2.new(0.4, -12, 0.5, 0), "+$0/s", 20, Color3.fromRGB(255, 255, 255))
perSecondLabel.TextXAlignment = Enum.TextXAlignment.Right
local rebirthLabel = makeLabel(moneyBar, "Rebirths", UDim2.new(0, 12, 0.55, 0), UDim2.new(1, -24, 0.4, 0), "Rebirths: 0  |  Base: 0/8", 16, Color3.fromRGB(200, 200, 220))
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left

-- The wave timer, under the money bar; hidden until a wave is coming.
local waveLabel = makeLabel(gui, "WaveTimer", UDim2.new(0.5, 0, 0, 84), UDim2.fromOffset(460, 36), "", 22, Color3.fromRGB(255, 210, 90))
waveLabel.AnchorPoint = Vector2.new(0.5, 0)
waveLabel.Visible = false

-- The alert line for thief news, top-right.
local alertLabel = makeLabel(gui, "Alert", UDim2.new(1, -380, 0, 12), UDim2.fromOffset(368, 60), "", 18, Color3.fromRGB(255, 90, 90))
alertLabel.TextWrapped = true
alertLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Bottom-right shop panel: lock, rebirth, upgrades.
local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.AnchorPoint = Vector2.new(1, 1)
shop.Position = UDim2.new(1, -16, 1, -16)
shop.Size = UDim2.fromOffset(250, 250)
shop.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
shop.BackgroundTransparency = 0.15
shop.BorderSizePixel = 0
shop.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 14)
shopCorner.Parent = shop
makeLabel(shop, "ShopTitle", UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 28), "SHOP", 20, Color3.fromRGB(255, 255, 255))
local lockButton = makeButton(shop, "LockButton", UDim2.new(0, 12, 0, 40), UDim2.new(1, -24, 0, 40), "🔒 Lock Base ($500)", Color3.fromRGB(200, 60, 60))
local rebirthButton = makeButton(shop, "RebirthButton", UDim2.new(0, 12, 0, 88), UDim2.new(1, -24, 0, 40), "✨ Rebirth ($25K)", Color3.fromRGB(150, 90, 255))
local bootsButton = makeButton(shop, "BootsButton", UDim2.new(0, 12, 0, 136), UDim2.new(1, -24, 0, 40), "👟 Speed Boots ($1K)", Color3.fromRGB(90, 140, 255))
local magnetButton = makeButton(shop, "MagnetButton", UDim2.new(0, 12, 0, 184), UDim2.new(1, -24, 0, 40), "🧲 Money Magnet ($2.5K)", Color3.fromRGB(90, 200, 120))
local lockStatus = makeLabel(shop, "LockStatus", UDim2.new(0, 12, 0, 222), UDim2.new(1, -24, 0, 22), "Base: UNLOCKED", 15, Color3.fromRGB(255, 120, 120))

-- Toast popups, centre screen, fading out on their own.
local toast = makeLabel(gui, "Toast", UDim2.new(0.5, 0, 0.35, 0), UDim2.fromOffset(560, 40), "", 22, Color3.fromRGB(255, 255, 255))
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Visible = false

local function showToast(text: string, color: Color3?)
	toast.Text = text
	toast.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	toast.Visible = true
	task.delay(3, function()
		toast.Visible = false
	end)
end

-- HUD updates from the server, once a second.
local latestPerSecond = 0
CashUpdate.OnClientEvent:Connect(function(snapshot)
	latestPerSecond = snapshot.PerSecond
	cashLabel.Text = BrainrotDefs.formatMoney(snapshot.Cash)
	perSecondLabel.Text = "+" .. BrainrotDefs.formatMoney(snapshot.PerSecond) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. snapshot.Rebirths .. "  |  Base: " .. snapshot.OwnedCount .. "/" .. snapshot.BaseSlots
	rebirthButton.Text = "✨ Rebirth (" .. BrainrotDefs.formatMoney(snapshot.RebirthCost) .. ")"
	if snapshot.Locked then
		lockStatus.Text = "Base: LOCKED (" .. snapshot.LockLeft .. "s)"
		lockStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
		lockButton.Text = "🔒 Locked!"
	else
		lockStatus.Text = "Base: UNLOCKED"
		lockStatus.TextColor3 = Color3.fromRGB(255, 120, 120)
		lockButton.Text = "🔒 Lock Base ($500)"
	end
end)

Popup.OnClientEvent:Connect(function(text: string)
	showToast(text)
end)

ThiefAlert.OnClientEvent:Connect(function(text: string)
	alertLabel.Text = text
	task.delay(6, function()
		alertLabel.Text = ""
	end)
end)

LockUpdate.OnClientEvent:Connect(function(playerName: string, locked: boolean)
	if locked then
		showToast(playerName .. " locked their base!", Color3.fromRGB(140, 255, 140))
	end
end)

-- Buy fanfare: a burst of particles at the buyer's base + a toast.
BoughtBrainrot.OnClientEvent:Connect(function(buyerName: string, brainrotName: string, rarity: string, mutation: string)
	showToast(buyerName .. " bought " .. brainrotName .. "!", BrainrotDefs.RarityColors[rarity])
end)

-- Rebirth confetti: coloured parts raining from the sky over the
-- whole map, plus a toast.
local function confetti()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local focus = camera.Focus.Position
	for _ = 1, 80 do
		local piece = Instance.new("Part")
		piece.Size = Vector3.new(0.6, 0.2, 0.6)
		piece.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		piece.Material = Enum.Material.Neon
		piece.Anchored = false
		piece.CanCollide = false
		piece.Position = focus + Vector3.new(math.random(-30, 30), 30 + math.random(0, 15), math.random(-30, 30))
		piece.Parent = workspace
		task.delay(4, function()
			piece:Destroy()
		end)
	end
end

RebirthDone.OnClientEvent:Connect(function(playerName: string, rebirths: number)
	confetti()
	showToast(playerName .. " REBIRTHED! Now x" .. rebirths .. " (+25% $/s each)", Color3.fromRGB(190, 110, 255))
end)

-- The wave: a countdown, then screen shake when it hits.
local shakeUntil = 0
WaveWarning.OnClientEvent:Connect(function(seconds: number)
	waveLabel.Visible = true
	task.spawn(function()
		for left = seconds, 1, -1 do
			waveLabel.Text = "🌊 NOODLE TSUNAMI IN " .. left .. "s — RUN HOME!"
			task.wait(1)
		end
		waveLabel.Visible = false
	end)
end)

WaveHit.OnClientEvent:Connect(function()
	shakeUntil = os.clock() + 1.2
	showToast("🌊 THE NOODLE TSUNAMI SWEPT THE CONVEYOR!", Color3.fromRGB(255, 210, 90))
end)

-- Screen shake: jitter the camera while the wave is hitting.
RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera or os.clock() > shakeUntil then
		return
	end
	local offset = Vector3.new(math.random(-1, 1) * 0.6, math.random(-1, 1) * 0.6, 0)
	camera.CFrame = camera.CFrame + offset
end)

-- Shop buttons talk to the server.
lockButton.MouseButton1Click:Connect(function()
	BuyLock:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	Rebirth:FireServer()
end)
bootsButton.MouseButton1Click:Connect(function()
	BuyUpgrade:FireServer("SpeedBoots")
end)
magnetButton.MouseButton1Click:Connect(function()
	BuyUpgrade:FireServer("MoneyMagnet")
end)

-- Cash popups: every few seconds, a floating "+$X" rises over the
-- player's own base, so the money ticking is visible in the world.
task.spawn(function()
	while true do
		task.wait(3)
		local character = player.Character
		if not character then
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local popup = Instance.new("BillboardGui")
			popup.Size = UDim2.fromOffset(120, 30)
			popup.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
			popup.AlwaysOnTop = true
			popup.Parent = root
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = "+" .. BrainrotDefs.formatMoney(latestPerSecond)
			label.TextColor3 = Color3.fromRGB(140, 255, 140)
			label.TextSize = 20
			label.Font = Enum.Font.GothamBold
			label.Parent = popup
			task.delay(1.5, function()
				popup:Destroy()
			end)
		end
	end
end)
