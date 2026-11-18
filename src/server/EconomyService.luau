-- Brainrot Rumble: EconomyService owns the money. Every second it pays
-- each player their $/s and sends a fresh HUD snapshot to the client. It
-- also handles the three things a player spends on: the base lock, the
-- shop upgrades, and rebirth. The client never moves money itself; every
-- spend arrives here as a RemoteEvent and is validated against GameState.

local RumbleConfig = require(game:GetService("ReplicatedStorage").Shared.RumbleConfig)
local GameState = require(game:GetService("ReplicatedStorage").Shared.GameState)
local MoneyFormat = require(game:GetService("ReplicatedStorage").Shared.MoneyFormat)

local EconomyService = {}

local context = nil

-- Send one player their fresh snapshot.
local function pushSnapshot(player)
	local state = context.States[player]
	if not state then
		return
	end
	context.Remotes.HudUpdate:FireClient(player, GameState.Snapshot(state, os.time()))
end

local function lockBase(player)
	local state = context.States[player]
	if not state then
		return
	end
	local now = os.time()
	if GameState.IsLocked(state, now) then
		context.Remotes.Toast:FireClient(player, "Your base is already locked!")
		return
	end
	if not GameState.Spend(state, RumbleConfig.LockPrice) then
		context.Remotes.Toast:FireClient(player, "Lock costs " .. MoneyFormat.Cash(RumbleConfig.LockPrice) .. "!")
		return
	end
	state.LockUntil = now + RumbleConfig.LockSeconds
	local gate = context.World.Gates[state.PlotIndex]
	if gate then
		gate.Visible = true
	end
	context.Remotes.Toast:FireClient(player, "Base locked for " .. RumbleConfig.LockSeconds .. "s!")
	pushSnapshot(player)
end

local function buyUpgrade(player, name)
	local state = context.States[player]
	if not state then
		return
	end
	local upgrade = RumbleConfig.Upgrades[name]
	if not upgrade then
		return
	end
	local level = state.Upgrades[name] or 0
	if level >= upgrade.Max then
		context.Remotes.Toast:FireClient(player, upgrade.Label .. " is maxed out!")
		return
	end
	local price = upgrade.Price * (level + 1)
	if not GameState.Spend(state, price) then
		context.Remotes.Toast:FireClient(player, upgrade.Label .. " costs " .. MoneyFormat.Cash(price) .. "!")
		return
	end
	state.Upgrades[name] = level + 1
	context.Remotes.Toast:FireClient(player, upgrade.Label .. " upgraded to level " .. (level + 1) .. "!")
	pushSnapshot(player)
end

local function rebirth(player)
	local state = context.States[player]
	if not state then
		return
	end
	local price = GameState.RebirthPrice(state)
	if not GameState.HasCash(state, price) then
		context.Remotes.Toast:FireClient(player, "Rebirth costs " .. MoneyFormat.Cash(price) .. "!")
		return
	end
	GameState.ApplyRebirth(state)
	context.Conveyor.ClearAllPens()
	context.Remotes.RebirthDone:FireClient(player, state.Rebirths, state.Multiplier)
	context.Remotes.Toast:FireClient(player, "REBIRTH #" .. state.Rebirths .. "! Income x" .. string.format("%.2f", state.Multiplier))
	pushSnapshot(player)
end

function EconomyService.Start(ctx)
	context = ctx
	context.Remotes.LockBase.OnServerEvent:Connect(lockBase)
	context.Remotes.BuyUpgrade.OnServerEvent:Connect(buyUpgrade)
	context.Remotes.Rebirth.OnServerEvent:Connect(rebirth)

	-- The money tick: once a second, pay everyone and refresh their HUD.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for player, state in pairs(context.States) do
				local income = GameState.IncomePerSecond(state, now)
				if income > 0 then
					GameState.AddCash(state, income)
				end
				-- A lock that ran out hides its gate again.
				if state.LockUntil > 0 and now >= state.LockUntil then
					state.LockUntil = 0
					local gate = context.World.Gates[state.PlotIndex]
					if gate then
						gate.Visible = false
					end
				end
				pushSnapshot(player)
			end
		end
	end)
end

return EconomyService
