-- Brainrot Rumble: the HUD. It builds the whole ScreenGui (money bar,
-- wave timer, thief alert, weapon bar, shop panel, spin wheel, toasts,
-- steal progress) and keeps it fresh from the snapshots the server sends
-- every second. Buttons here fire the same RemoteEvents the keys do.
-- Nothing in this script moves money: it only shows what the server says.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RumbleConfig = require(ReplicatedStorage.Shared.RumbleConfig)
local BrainrotCatalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
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
alertLabel.Visible = false

-- Mission banner, under the wave timer: the next mission in the chain.
local missionLabel = text(gui, "MissionBanner", UDim2.new(0, 560, 0, 24), UDim2.new(0.5, -280, 0, 122), 16, Color3.fromRGB(255, 215, 0))
missionLabel.TextXAlignment = Enum.TextXAlignment.Center
missionLabel.Text = "MISSION 1/10: First Catch"

-- Carry banner: what you are carrying, and where it has to go.
local carryLabel = text(gui, "CarryBanner", UDim2.new(0, 560, 0, 28), UDim2.new(0.5, -280, 0, 150), 19, Color3.fromRGB(255, 160, 60))
carryLabel.TextXAlignment = Enum.TextXAlignment.Center
carryLabel.Visible = false

-- Golden Noodle Hour banner: the noodle gods smile.
local goldenLabel = text(gui, "GoldenHourBanner", UDim2.new(0, 560, 0, 28), UDim2.new(0.5, -280, 0, 182), 20, Color3.fromRGB(255, 230, 120))
goldenLabel.TextXAlignment = Enum.TextXAlignment.Center
goldenLabel.Visible = false

-- The rarity + mutation ladder, always on screen (top-left, under the
-- Roblox menu buttons). Every tier and every mutation, with its
-- multiplier — the whole ladder is visible in every screenshot.
local ladder = panel(gui, "Ladder", UDim2.new(0, 200, 0, 252), UDim2.new(0, 12, 0, 76), Color3.fromRGB(25, 25, 40))
local ladderTitle = text(ladder, "Title", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 4), 15, Color3.fromRGB(255, 255, 255))
ladderTitle.TextXAlignment = Enum.TextXAlignment.Center
ladderTitle.Text = "RARITY LADDER"
local ladderY = 26
for _, rarity in ipairs(BrainrotCatalog.Rarities) do
	local row = text(ladder, "Tier" .. rarity.Name, UDim2.new(1, -12, 0, 16), UDim2.new(0, 8, 0, ladderY), 13, BrainrotCatalog.RarityColor(rarity.Name))
	row.Text = "◆ " .. rarity.Name
	ladderY = ladderY + 16
end
local mutTitle = text(ladder, "MutTitle", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, ladderY + 2), 14, Color3.fromRGB(255, 255, 255))
mutTitle.TextXAlignment = Enum.TextXAlignment.Center
mutTitle.Text = "MUTATIONS"
ladderY = ladderY + 22
for _, mutation in ipairs(BrainrotCatalog.Mutations) do
	local multText = "x" .. tostring(mutation.Multiplier)
	local row = text(ladder, "Mut" .. mutation.Name, UDim2.new(1, -12, 0, 16), UDim2.new(0, 8, 0, ladderY), 13, Color3.fromRGB(220, 220, 230))
	row.Text = "✦ " .. mutation.Name .. " " .. multText
	ladderY = ladderY + 16
end
local indexBtn = button(ladder, "IndexBtn", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 0, ladderY + 4), Color3.fromRGB(90, 140, 255), "INDEX [I] — 40 brainrots", 14)

-- Toasts, centre, under the banners.
local toastLabel = text(gui, "Toast", UDim2.new(0, 560, 0, 28), UDim2.new(0.5, -280, 0, 214), 20, Color3.fromRGB(255, 255, 255))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Visible = false
local toastUntil = 0

-- Steal progress bar, centre screen.
local stealFrame = panel(gui, "StealFrame", UDim2.new(0, 300, 0, 44), UDim2.new(0.5, -150, 0, 252), Color3.fromRGB(25, 25, 40))
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
local spinLabel = text(gui, "SpinResult", UDim2.new(0, 560, 0, 40), UDim2.new(0.5, -280, 0, 310), 26, Color3.fromRGB(255, 215, 0))
spinLabel.TextXAlignment = Enum.TextXAlignment.Center
spinLabel.Visible = false

-- Mission-complete banner, centre, above the spin result.
local missionDoneLabel = text(gui, "MissionDone", UDim2.new(0, 640, 0, 34), UDim2.new(0.5, -320, 0, 360), 22, Color3.fromRGB(255, 215, 0))
missionDoneLabel.TextXAlignment = Enum.TextXAlignment.Center
missionDoneLabel.Visible = false

-- Weapon bar, bottom-centre.
local weaponBar = panel(gui, "WeaponBar", UDim2.new(0, 420, 0, 64), UDim2.new(0.5, -210, 1, -80), Color3.fromRGB(25, 25, 40))
local slapBtn = button(weaponBar, "Slap", UDim2.new(0, 128, 0, 48), UDim2.new(0, 10, 0, 8), Color3.fromRGB(200, 60, 60), "Slap [1]", 17)
local freezeBtn = button(weaponBar, "Freeze", UDim2.new(0, 128, 0, 48), UDim2.new(0, 146, 0, 8), Color3.fromRGB(90, 160, 255), "Freeze [2]", 17)
local pullBtn = button(weaponBar, "Pull", UDim2.new(0, 128, 0, 48), UDim2.new(0, 282, 0, 8), Color3.fromRGB(90, 200, 120), "Magnet [3]", 17)
slapBtn.MouseButton1Click:Connect(function() remotes.UseWeapon:FireServer("Slap") end)
freezeBtn.MouseButton1Click:Connect(function() remotes.UseWeapon:FireServer("Freeze") end)
pullBtn.MouseButton1Click:Connect(function() remotes.UseWeapon:FireServer("Pull") end)

-- Shop panel, bottom-right. Four levelled upgrade tracks (Boots, Magnet,
-- Glove, Base Expansion) plus lock, rebirth and spin.
local shop = panel(gui, "Shop", UDim2.new(0, 250, 0, 392), UDim2.new(1, -266, 1, -408), Color3.fromRGB(25, 25, 40))
local shopTitle = text(shop, "Title", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 6), 20, Color3.fromRGB(255, 255, 255))
shopTitle.TextXAlignment = Enum.TextXAlignment.Center
shopTitle.Text = "SHOP"
local lockBtn = button(shop, "Lock", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 38), Color3.fromRGB(200, 60, 60), "Lock Base (" .. MoneyFormat.Cash(RumbleConfig.LockPrice) .. ") [L]", 16)
local rebirthBtn = button(shop, "Rebirth", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 86), Color3.fromRGB(150, 90, 255), "Rebirth [R]", 16)
local bootsBtn = button(shop, "Boots", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 134), Color3.fromRGB(90, 140, 255), "Speed Boots LV 0/5", 16)
local magnetBtn = button(shop, "Magnet", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 182), Color3.fromRGB(90, 200, 120), "Money Magnet LV 0/5", 16)
local gloveBtn = button(shop, "Glove", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 230), Color3.fromRGB(255, 180, 40), "Golden Glove LV 0/5", 16)
local expansionBtn = button(shop, "Expansion", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 278), Color3.fromRGB(120, 220, 220), "Base Expansion LV 0/2", 16)
local spinBtn = button(shop, "Spin", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 326), Color3.fromRGB(255, 120, 200), "SPIN THE WHEEL [Q]", 16)
local lockStatus = text(shop, "LockStatus", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 370), 15, Color3.fromRGB(255, 120, 120))
lockStatus.Text = "Base: UNLOCKED"
lockBtn.MouseButton1Click:Connect(function() remotes.LockBase:FireServer() end)
rebirthBtn.MouseButton1Click:Connect(function() remotes.Rebirth:FireServer() end)
bootsBtn.MouseButton1Click:Connect(function() remotes.BuyUpgrade:FireServer("Boots") end)
magnetBtn.MouseButton1Click:Connect(function() remotes.BuyUpgrade:FireServer("Magnet") end)
gloveBtn.MouseButton1Click:Connect(function() remotes.BuyUpgrade:FireServer("Glove") end)
expansionBtn.MouseButton1Click:Connect(function() remotes.BuyUpgrade:FireServer("Expansion") end)
spinBtn.MouseButton1Click:Connect(function() remotes.SpinWheel:FireServer() end)

-- Controls hint, bottom-left.
local hint = text(gui, "Hint", UDim2.new(0, 330, 0, 84), UDim2.new(0, 12, 1, -96), 14, Color3.fromRGB(220, 220, 230))
hint.Text = "E buy  |  F steal  |  1/2/3 weapons\nL lock  |  R rebirth  |  Q spin\nI index  |  V sell brainrot"

-- The Index: every brainrot in the game, with its funny quote. Press I
-- (or the INDEX button) to open it. Discovered brainrots show in colour
-- with their quote; ones you have never owned show as "???".
local discoveredSet = {}
local indexCells = {}

local indexPanel = panel(gui, "IndexPanel", UDim2.new(0, 740, 0, 540), UDim2.new(0.5, -370, 0.5, -270), Color3.fromRGB(20, 20, 34))
indexPanel.Visible = false
local indexTitle = text(indexPanel, "Title", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 8), 24, Color3.fromRGB(255, 255, 255))
indexTitle.TextXAlignment = Enum.TextXAlignment.Center
indexTitle.Text = "BRAINROT INDEX"
local indexSub = text(indexPanel, "Sub", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 40), 14, Color3.fromRGB(200, 200, 210))
indexSub.TextXAlignment = Enum.TextXAlignment.Center
indexSub.Text = "Found 0/40  ·  Tiers 0/7"
local indexClose = button(indexPanel, "Close", UDim2.new(0, 36, 0, 30), UDim2.new(1, -44, 0, 8), Color3.fromRGB(200, 60, 60), "X", 18)
local indexScroll = Instance.new("ScrollingFrame")
indexScroll.Name = "List"
indexScroll.Size = UDim2.new(1, -24, 1, -76)
indexScroll.Position = UDim2.new(0, 12, 0, 66)
indexScroll.BackgroundTransparency = 1
indexScroll.BorderSizePixel = 0
indexScroll.ScrollBarThickness = 6
indexScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
indexScroll.Parent = indexPanel
local indexGrid = Instance.new("UIGridLayout")
indexGrid.CellSize = UDim2.new(0, 220, 0, 76)
indexGrid.CellPadding = UDim2.new(0, 8, 0, 8)
indexGrid.SortOrder = Enum.SortOrder.LayoutOrder
indexGrid.Parent = indexScroll

-- One cell per brainrot, built once; refreshIndex recolours them.
for i, def in ipairs(BrainrotCatalog.Characters) do
	local cell = Instance.new("Frame")
	cell.Name = def.Id
	cell.Size = UDim2.new(0, 220, 0, 76)
	cell.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
	cell.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = cell
	cell.LayoutOrder = i
	cell.Parent = indexScroll
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -12, 0, 18)
	nameLabel.Position = UDim2.new(0, 6, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = BrainrotCatalog.RarityColor(def.Rarity)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = cell
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "Info"
	infoLabel.Size = UDim2.new(1, -12, 0, 16)
	infoLabel.Position = UDim2.new(0, 6, 0, 24)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 12
	infoLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = cell
	local quoteLabel = Instance.new("TextLabel")
	quoteLabel.Name = "Quote"
	quoteLabel.Size = UDim2.new(1, -12, 0, 28)
	quoteLabel.Position = UDim2.new(0, 6, 0, 42)
	quoteLabel.BackgroundTransparency = 1
	quoteLabel.Font = Enum.Font.Gotham
	quoteLabel.TextSize = 11
	quoteLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	quoteLabel.TextXAlignment = Enum.TextXAlignment.Left
	quoteLabel.TextWrapped = true
	quoteLabel.Parent = cell
	indexCells[def.Id] = { Cell = cell, Name = nameLabel, Info = infoLabel, Quote = quoteLabel, Def = def }
end

local function refreshIndex()
	local found = 0
	local tiersDone = 0
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		local tierTotal = 0
		local tierFound = 0
		for _, def in ipairs(BrainrotCatalog.Characters) do
			if def.Rarity == rarity.Name then
				tierTotal = tierTotal + 1
				if discoveredSet[def.Id] then
					tierFound = tierFound + 1
				end
			end
		end
		if tierTotal > 0 and tierFound >= tierTotal then
			tiersDone = tiersDone + 1
		end
	end
	for _, def in ipairs(BrainrotCatalog.Characters) do
		local entry = indexCells[def.Id]
		if entry then
			if discoveredSet[def.Id] then
				found = found + 1
				entry.Name.Text = def.Name
				entry.Name.TextColor3 = BrainrotCatalog.RarityColor(def.Rarity)
				entry.Info.Text = def.Rarity .. "  ·  " .. MoneyFormat.Short(def.Rate) .. "/s"
				entry.Info.TextColor3 = Color3.fromRGB(140, 255, 140)
				entry.Quote.Text = '"' .. (def.Quote or "") .. '"'
				entry.Cell.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
			else
				entry.Name.Text = "???"
				entry.Name.TextColor3 = Color3.fromRGB(120, 120, 130)
				entry.Info.Text = def.Rarity
				entry.Info.TextColor3 = Color3.fromRGB(120, 120, 130)
				entry.Quote.Text = "Not discovered yet — buy one!"
				entry.Cell.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
			end
		end
	end
	indexSub.Text = "Found " .. found .. "/40  ·  Tiers " .. tiersDone .. "/7  ·  Finish a tier: +$3,000  ·  All 40: +$50,000"
end
refreshIndex()

local function toggleIndex()
	indexPanel.Visible = not indexPanel.Visible
	if indexPanel.Visible then
		refreshIndex()
	end
end
indexClose.MouseButton1Click:Connect(toggleIndex)
indexBtn.MouseButton1Click:Connect(toggleIndex)
local ContextActionService = game:GetService("ContextActionService")
ContextActionService:BindAction("RumbleIndex", function(_, state, _)
	if state == Enum.UserInputState.Begin then
		toggleIndex()
	end
end, false, Enum.KeyCode.I)

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

-- The snapshot refresh: cash, income, rebirths, base fill, lock, spin,
-- upgrade levels, mission banner, carry banner, golden hour, Index.
local latestUpgrades = nil
local function upgradeButtonText(btn, key)
	local upgrade = RumbleConfig.Upgrades[key]
	local level = 0
	if latestUpgrades then
		level = latestUpgrades[key] or 0
	end
	if level >= upgrade.Max then
		btn.Text = upgrade.Label .. " LV " .. level .. "/" .. upgrade.Max .. " MAXED"
	else
		local price = upgrade.Price * (level + 1)
		btn.Text = upgrade.Label .. " LV " .. level .. "/" .. upgrade.Max .. " (" .. MoneyFormat.Cash(price) .. ")"
	end
end
remotes.HudUpdate.OnClientEvent:Connect(function(snapshot)
	latestUpgrades = snapshot.Upgrades
	cashLabel.Text = MoneyFormat.Cash(snapshot.Cash)
	perSecondLabel.Text = "+" .. MoneyFormat.Short(snapshot.Income) .. "/s"
	local boost = ""
	if snapshot.BoostLeft and snapshot.BoostLeft > 0 then
		boost = "  |  2x " .. snapshot.BoostLeft .. "s"
	end
	local chain = ""
	if snapshot.ChainBonus then
		chain = "  |  CHAIN +25%"
	end
	local comboText = ""
	if snapshot.ComboCount and snapshot.ComboCount >= 2 then
		comboText = "  |  COMBO x" .. snapshot.ComboCount .. " (" .. (snapshot.ComboLeft or 0) .. "s)"
	end
	local penCap = snapshot.PenCap or 8
	subLabel.Text = "Rebirths: " .. snapshot.Rebirths .. "  |  Base: " .. #snapshot.Brainrots .. "/" .. penCap .. "  |  x" .. string.format("%.2f", snapshot.Multiplier) .. boost .. chain .. comboText
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
	-- Rebirth button: ready state, or what is still missing.
	if snapshot.RebirthReady then
		rebirthBtn.Text = "REBIRTH READY! [R]"
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(190, 110, 255)
	else
		rebirthBtn.Text = "Rebirth: " .. (snapshot.RebirthHint or "") .. " [R]"
		rebirthBtn.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
	end
	upgradeButtonText(bootsBtn, "Boots")
	upgradeButtonText(magnetBtn, "Magnet")
	upgradeButtonText(gloveBtn, "Glove")
	upgradeButtonText(expansionBtn, "Expansion")
	-- The mission chain banner.
	if snapshot.MissionCurrent then
		local current = snapshot.MissionCurrent
		missionLabel.Text = "MISSION " .. (snapshot.MissionsDone + 1) .. "/" .. snapshot.MissionTotal .. ": " .. current.Title .. " — " .. current.Desc .. " (" .. current.Progress .. "/" .. current.Goal .. ")"
		missionLabel.Visible = true
	elseif snapshot.ChainBonus then
		missionLabel.Text = "ALL MISSIONS DONE! Chain bonus +25% income active."
		missionLabel.Visible = true
	else
		missionLabel.Visible = false
	end
	-- The carry banner.
	if snapshot.Carrying then
		local def = BrainrotCatalog.Get(snapshot.Carrying.DefId)
		local name = def and def.Name or "a brainrot"
		carryLabel.Text = "CARRYING: " .. name .. " — RUN TO YOUR BASE!"
		carryLabel.Visible = true
	else
		carryLabel.Visible = false
	end
	-- Golden Noodle Hour.
	if snapshot.GoldenHourLeft and snapshot.GoldenHourLeft > 0 then
		goldenLabel.Text = "GOLDEN NOODLE HOUR! Income x2, rare mutations rain — " .. snapshot.GoldenHourLeft .. "s left"
		goldenLabel.Visible = true
	else
		goldenLabel.Visible = false
	end
	-- The Index: remember what this player has discovered.
	if snapshot.Discovered then
		local changed = false
		for _, defId in ipairs(snapshot.Discovered) do
			if not discoveredSet[defId] then
				discoveredSet[defId] = true
				changed = true
			end
		end
		if changed and indexPanel.Visible then
			refreshIndex()
		end
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
	alertLabel.Visible = true
	task.delay(8, function()
		alertLabel.Text = ""
		alertLabel.Visible = false
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

remotes.MissionDone.OnClientEvent:Connect(function(title, reward)
	missionDoneLabel.Text = "★ " .. title .. "  +$" .. tostring(reward) .. "!"
	missionDoneLabel.Visible = true
	task.delay(4, function()
		missionDoneLabel.Visible = false
	end)
end)

remotes.GoldenHour.OnClientEvent:Connect(function(seconds)
	goldenLabel.Text = "GOLDEN NOODLE HOUR! Income x2, rare mutations rain — " .. seconds .. "s left"
	goldenLabel.Visible = true
	showToast("GOLDEN NOODLE HOUR! Income x2 for 60s!")
end)
