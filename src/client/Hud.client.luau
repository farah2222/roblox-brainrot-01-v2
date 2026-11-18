-- Brainrot Rumble: the HUD. It builds the whole ScreenGui (money bar,
-- wave timer, thief alert, weapon bar, shop panel, spin wheel, toasts,
-- steal progress) and keeps it fresh from the snapshots the server sends
-- every second. Buttons here fire the same RemoteEvents the keys do.
-- Nothing in this script moves money: it only shows what the server says.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RumbleConfig = require(ReplicatedStorage.Shared.RumbleConfig)
local MoneyFormat = require(ReplicatedStorage.Shared.MoneyFormat)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("RumbleRemotes")

local gui = Instance.new("ScreenGui")
gui.Name = "RumbleHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function panel(parent, name, size, position, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

local function text(parent, name, size, position, fontSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = fontSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function button(parent, name, size, position, color, labelText, fontSize)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = fontSize
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = labelText
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn
	btn.Parent = parent
	return btn
end

-- Money bar, top-centre (clear of Roblox's top-left menu buttons).
local moneyBar = panel(gui, "MoneyBar", UDim2.new(0, 460, 0, 64), UDim2.new(0.5, -230, 0, 12), Color3.fromRGB(25, 25, 40))
local cashLabel = text(moneyBar, "Cash", UDim2.new(0, 260, 0, 30), UDim2.new(0, 14, 0, 4), 28, Color3.fromRGB(140, 255, 140))
local perSecondLabel = text(moneyBar, "PerSecond", UDim2.new(0, 160, 0, 26), UDim2.new(1, -170, 0, 8), 20, Color3.fromRGB(255, 255, 255))
perSecondLabel.TextXAlignment = Enum.TextXAlignment.Right
local subLabel = text(moneyBar, "Sub", UDim2.new(1, -28, 0, 20), UDim2.new(0, 14, 0, 36), 15, Color3.fromRGB(216, 216, 224))
subLabel.Text = "Rebirths: 0  |  Base: 0/8"

-- Wave timer, under the money bar.
local waveLabel = text(gui, "WaveTimer", UDim2.new(0, 460, 0, 28), UDim2.new(0.5, -230, 0, 88), 22, Color3.fromRGB(255, 210, 90))
waveLabel.TextXAlignment = Enum.TextXAlignment.Center
waveLabel.Visible = false

-- Thief alert, top-right.
local alertLabel = text(gui, "ThiefAlert", UDim2.new(0, 368, 0, 28), UDim2.new(1, -380, 0, 12), 18, Color3.fromRGB(255, 90, 90))
alertLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Toasts, centre, stacked under the wave timer.
local toastLabel = text(gui, "Toast", UDim2.new(0, 560, 0, 28), UDim2.new(0.5, -280, 0, 130), 20, Color3.fromRGB(255, 255, 255))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Visible = false
local toastUntil = 0

-- Steal progress bar, centre screen.
local stealFrame = panel(gui, "StealFrame", UDim2.new(0, 300, 0, 44), UDim2.new(0.5, -150, 0, 200), Color3.fromRGB(25, 25, 40))
stealFrame.Visible = false
local stealTitle = text(stealFrame, "Title", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 4), 16, Color3.fromRGB(255, 255, 255))
stealTitle.TextXAlignment = Enum.TextXAlignment.Center
local stealBar = Instance.new("Frame")
stealBar.Name = "Bar"
stealBar.Size = UDim2.new(0, 0, 0, 12)
stealBar.Position = UDim2.new(0, 10, 0, 26)
stealBar.BackgroundColor3 = Color3.fromRGB(255, 90, 110)
stealBar.BorderSizePixel = 0
stealBar.Parent = stealFrame

-- Spin result banner, centre.
local spinLabel = text(gui, "SpinResult", UDim2.new(0, 560, 0, 40), UDim2.new(0.5, -280, 0, 300), 26, Color3.fromRGB(255, 215, 0))
spinLabel.TextXAlignment = Enum.TextXAlignment.Center
spinLabel.Visible = false

-- Weapon bar, bottom-centre.
local weaponBar = panel(gui, "WeaponBar", UDim2.new(0, 420, 0, 64), UDim2.new(0.5, -210, 1, -80), Color3.fromRGB(25, 25, 40))
local slapBtn = button(weaponBar, "Slap", UDim2.new(0, 128, 0, 48), UDim2.new(0, 10, 0, 8), Color3.fromRGB(200, 60, 60), "Slap [1]", 17)
local freezeBtn = button(weaponBar, "Freeze", UDim2.new(0, 128, 0, 48), UDim2.new(0, 146, 0, 8), Color3.fromRGB(90, 160, 255), "Freeze [2]", 17)
local pullBtn = button(weaponBar, "Pull", UDim2.new(0, 128, 0, 48), UDim2.new(0, 282, 0, 8), Color3.fromRGB(90, 200, 120), "Magnet [3]", 17)
slapBtn.MouseButton1Click:Connect(function() remotes.UseWeapon:FireServer("Slap") end)
freezeBtn.MouseButton1Click:Connect(function() remotes.UseWeapon:FireServer("Freeze") end)
pullBtn.MouseButton1Click:Connect(function() remotes.UseWeapon:FireServer("Pull") end)

-- Shop panel, bottom-right.
local shop = panel(gui, "Shop", UDim2.new(0, 250, 0, 320), UDim2.new(1, -266, 1, -336), Color3.fromRGB(25, 25, 40))
local shopTitle = text(shop, "Title", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 6), 20, Color3.fromRGB(255, 255, 255))
shopTitle.TextXAlignment = Enum.TextXAlignment.Center
shopTitle.Text = "SHOP"
local lockBtn = button(shop, "Lock", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 38), Color3.fromRGB(200, 60, 60), "Lock Base (" .. MoneyFormat.Cash(RumbleConfig.LockPrice) .. ") [L]", 16)
local rebirthBtn = button(shop, "Rebirth", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 86), Color3.fromRGB(150, 90, 255), "Rebirth (" .. MoneyFormat.Short(RumbleConfig.RebirthBasePrice) .. ") [R]", 16)
local bootsBtn = button(shop, "Boots", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 134), Color3.fromRGB(90, 140, 255), "Speed Boots (" .. MoneyFormat.Cash(RumbleConfig.Upgrades.Boots.Price) .. ")", 16)
local magnetBtn = button(shop, "Magnet", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 182), Color3.fromRGB(90, 200, 120), "Money Magnet (" .. MoneyFormat.Cash(RumbleConfig.Upgrades.Magnet.Price) .. ")", 16)
local gloveBtn = button(shop, "Glove", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 230), Color3.fromRGB(255, 180, 40), "Golden Glove (" .. MoneyFormat.Cash(RumbleConfig.Upgrades.Glove.Price) .. ")", 16)
local spinBtn = button(shop, "Spin", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 278), Color3.fromRGB(255, 120, 200), "SPIN THE WHEEL [Q]", 16)
local lockStatus = text(shop, "LockStatus", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 296), 15, Color3.fromRGB(255, 120, 120))
lockStatus.Text = "Base: UNLOCKED"
lockBtn.MouseButton1Click:Connect(function() remotes.LockBase:FireServer() end)
rebirthBtn.MouseButton1Click:Connect(function() remotes.Rebirth:FireServer() end)
bootsBtn.MouseButton1Click:Connect(function() remotes.BuyUpgrade:FireServer("Boots") end)
magnetBtn.MouseButton1Click:Connect(function() remotes.BuyUpgrade:FireServer("Magnet") end)
gloveBtn.MouseButton1Click:Connect(function() remotes.BuyUpgrade:FireServer("Glove") end)
spinBtn.MouseButton1Click:Connect(function() remotes.SpinWheel:FireServer() end)

-- Controls hint, bottom-left.
local hint = text(gui, "Hint", UDim2.new(0, 330, 0, 60), UDim2.new(0, 12, 1, -72), 14, Color3.fromRGB(220, 220, 230))
hint.Text = "E buy  |  F steal  |  1/2/3 weapons\nL lock  |  R rebirth  |  Q spin"

-- Toast queue: one at a time, each visible for 3 seconds.
local function showToast(message)
	toastLabel.Text = message
	toastLabel.Visible = true
	toastUntil = os.clock() + 3
end
task.spawn(function()
	while true do
		task.wait(0.25)
		if toastLabel.Visible and os.clock() > toastUntil then
			toastLabel.Visible = false
		end
	end
end)

-- The snapshot refresh: cash, income, rebirths, base fill, lock, spin.
remotes.HudUpdate.OnClientEvent:Connect(function(snapshot)
	cashLabel.Text = MoneyFormat.Cash(snapshot.Cash)
	perSecondLabel.Text = "+" .. MoneyFormat.Short(snapshot.Income) .. "/s"
	local boost = ""
	if snapshot.BoostLeft and snapshot.BoostLeft > 0 then
		boost = "  |  2x " .. snapshot.BoostLeft .. "s"
	end
	subLabel.Text = "Rebirths: " .. snapshot.Rebirths .. "  |  Base: " .. #snapshot.Brainrots .. "/8  |  x" .. string.format("%.2f", snapshot.Multiplier) .. boost
	if snapshot.LockLeft and snapshot.LockLeft > 0 then
		lockStatus.Text = "Base: LOCKED (" .. snapshot.LockLeft .. "s)"
		lockStatus.TextColor3 = Color3.fromRGB(140, 255, 140)
		lockBtn.Text = "LOCKED! (" .. snapshot.LockLeft .. "s)"
	else
		lockStatus.Text = "Base: UNLOCKED"
		lockStatus.TextColor3 = Color3.fromRGB(255, 120, 120)
		lockBtn.Text = "Lock Base (" .. MoneyFormat.Cash(RumbleConfig.LockPrice) .. ") [L]"
	end
	if snapshot.SpinReadyIn and snapshot.SpinReadyIn > 0 then
		spinBtn.Text = "SPIN IN " .. snapshot.SpinReadyIn .. "s"
	else
		spinBtn.Text = "SPIN THE WHEEL [Q]"
	end
end)

remotes.Toast.OnClientEvent:Connect(showToast)
remotes.ToastAll.OnClientEvent:Connect(showToast)

remotes.TsunamiWarning.OnClientEvent:Connect(function(seconds)
	waveLabel.Text = "GIANT NOODLE TSUNAMI IN " .. seconds .. "s — RUN HOME!"
	waveLabel.Visible = true
	task.delay(seconds, function()
		waveLabel.Visible = false
	end)
end)

remotes.ThiefComing.OnClientEvent:Connect(function(victimName)
	alertLabel.Text = "Si Cilok Nakal is near " .. victimName .. "'s base!"
	task.delay(8, function()
		alertLabel.Text = ""
	end)
end)

remotes.StealStarted.OnClientEvent:Connect(function(victimName, seconds)
	stealTitle.Text = "Stealing from " .. victimName .. "..."
	stealFrame.Visible = true
	stealBar.Size = UDim2.new(0, 0, 0, 12)
	local start = os.clock()
	task.spawn(function()
		while stealFrame.Visible do
			local done = (os.clock() - start) / seconds
			if done >= 1 then
				break
			end
			stealBar.Size = UDim2.new(0, 280 * done, 0, 12)
			task.wait(0.05)
		end
	end)
end)

remotes.StealStopped.OnClientEvent:Connect(function(reason)
	stealFrame.Visible = false
	showToast(reason)
end)

remotes.StealDone.OnClientEvent:Connect(function()
	stealFrame.Visible = false
	showToast("Steal complete!")
end)

remotes.SpinResult.OnClientEvent:Connect(function(prizeLabel)
	spinLabel.Text = "WHEEL: " .. prizeLabel .. "!"
	spinLabel.Visible = true
	task.delay(4, function()
		spinLabel.Visible = false
	end)
end)

remotes.BrainrotBought.OnClientEvent:Connect(function(name, mutation)
	showToast("Bought " .. name .. (mutation ~= "Normal" and " (" .. mutation .. ")" or "") .. "!")
end)

remotes.RebirthDone.OnClientEvent:Connect(function(count, multiplier)
	showToast("REBIRTH #" .. count .. "! Income x" .. string.format("%.2f", multiplier))
end)
