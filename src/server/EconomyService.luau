-- Brainrot Bay: EconomyService owns the money.
-- Every second it adds each player's $/s to their cash, then sends
-- the HUD snapshot to the client. It also handles the three things
-- cash buys outside the conveyor: the base lock, shop upgrades and
-- rebirth. All state lives in GameState; this service just moves it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local GameState = require(ReplicatedStorage.Shared.GameState)

local EconomyService = {}

-- Start the service. deps: { States, Remotes }.
function EconomyService.start(deps)
	local states = deps.States
	local remotes = deps.Remotes
	local Players = game:GetService("Players")

	-- The money tick: once a second, every player earns their $/s.
	task.spawn(function()
		while true do
			task.wait(Config.TickInterval)
			for player, state in pairs(states) do
				local income = GameState.incomePerSecond(state)
				if income > 0 then
					GameState.addCash(state, income)
				end
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local cashValue = leaderstats:FindFirstChild("Cash")
					if cashValue then
						cashValue.Value = math.floor(state.Cash + 0.5)
					end
				end
				remotes.CashUpdate:FireClient(player, GameState.snapshot(state))
			end
		end
	end)

	-- Lock the base: costs cash, keeps Sticky-Fingers Stan out for
	-- Config.LockDuration seconds.
	remotes.BuyLock.OnServerEvent:Connect(function(player: Player)
		local state = states[player]
		if not state then
			return
		end
		if GameState.isLocked(state) then
			remotes.Popup:FireClient(player, "Your base is already locked!")
			return
		end
		if not GameState.spend(state, Config.LockCost) then
			remotes.Popup:FireClient(player, "Lock costs " .. BrainrotDefs.formatMoney(Config.LockCost) .. "!")
			return
		end
		state.LockUntil = os.clock() + Config.LockDuration
		remotes.LockUpdate:FireAllClients(player.Name, true, Config.LockDuration)
		remotes.Popup:FireClient(player, "Base locked for " .. Config.LockDuration .. "s! Stan can't touch you.")
	end)

	-- Rebirth: reset cash and brainrots for a permanent +25% $/s.
	remotes.Rebirth.OnServerEvent:Connect(function(player: Player)
		local state = states[player]
		if not state then
			return
		end
		local cost = GameState.rebirthCost(state)
		if not GameState.rebirth(state) then
			remotes.Popup:FireClient(player, "Rebirth costs " .. BrainrotDefs.formatMoney(cost) .. "!")
			return
		end
		-- Clear the bought brainrot models off the base.
		local conveyor = deps.Workspace:FindFirstChild("ConveyorBrainrots")
		if conveyor then
			local plotCenter = deps.Plots[player]
			if plotCenter then
				for slot = 1, Config.BaseSlots do
					deps.Conveyor.removeOwnedModel(plotCenter, slot)
				end
			end
		end
		remotes.RebirthDone:FireAllClients(player.Name, state.Rebirths)
		remotes.Popup:FireClient(player, "REBIRTH " .. state.Rebirths .. "! +25% $/s forever!")
	end)

	-- Shop upgrades: Speed Boots (+30% walk speed) and Money Magnet.
	remotes.BuyUpgrade.OnServerEvent:Connect(function(player: Player, upgradeName: string)
		local state = states[player]
		if not state then
			return
		end
		local upgrade = Config.Upgrades[upgradeName]
		if not upgrade then
			return
		end
		if state.Upgrades[upgradeName] then
			remotes.Popup:FireClient(player, "You already own " .. upgrade.Name .. "!")
			return
		end
		if not GameState.spend(state, upgrade.Cost) then
			remotes.Popup:FireClient(player, upgrade.Name .. " costs " .. BrainrotDefs.formatMoney(upgrade.Cost) .. "!")
			return
		end
		state.Upgrades[upgradeName] = true
		if upgradeName == "SpeedBoots" then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16 * 1.3
			end
		end
		remotes.Popup:FireClient(player, "Bought " .. upgrade.Name .. "! " .. upgrade.Description)
	end)

	-- New player: fresh state, a leaderstat, and a base plot.
	Players.PlayerAdded:Connect(function(player: Player)
		states[player] = GameState.newPlayerState(player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		local cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Value = 100
		cashValue.Parent = leaderstats
		local rebirthValue = Instance.new("IntValue")
		rebirthValue.Name = "Rebirths"
		rebirthValue.Value = 0
		rebirthValue.Parent = leaderstats
		leaderstats.Parent = player
		-- Hand out the first free plot.
		for i, taken in ipairs(deps.PlotsTaken) do
			if not taken then
				deps.PlotsTaken[i] = player
				deps.Plots[player] = deps.PlotCenters[i]
				break
			end
		end
		remotes.CashUpdate:FireClient(player, GameState.snapshot(states[player]))
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
		for i, taken in ipairs(deps.PlotsTaken) do
			if taken == player then
				deps.PlotsTaken[i] = false
			end
		end
		deps.Plots[player] = nil
	end)

	return EconomyService
end

return EconomyService
