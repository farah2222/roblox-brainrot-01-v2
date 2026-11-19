-- Brainrot Rumble: EconomyService owns the money. Every second it pays
-- each player their $/s and sends a fresh HUD snapshot to the client. It
-- also handles the three things a player spends on: the base lock, the
-- shop upgrades, and rebirth. The client never moves money itself; every
-- spend arrives here as a RemoteEvent and is validated against GameState.

local RumbleConfig = require(game:GetService("ReplicatedStorage").Shared.RumbleConfig)
local BrainrotCatalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)
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
	state.MissionStats.Locks = state.MissionStats.Locks + 1
	local gate = context.World.Gates[state.PlotIndex]
	if gate then
		gate.Transparency = 0.35
		gate.CanCollide = true
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
	local ready, _hint = GameState.CanRebirth(state)
	if not ready then
		if state.Rebirths >= RumbleConfig.RebirthMax then
			context.Remotes.Toast:FireClient(player, "Rebirth MAXED — income is already x5!")
		else
			context.Remotes.Toast:FireClient(player, "Rebirth needs " .. MoneyFormat.Cash(RumbleConfig.RebirthMinLifetime) .. " lifetime earned, or all 10 missions done!")
		end
		return
	end
	-- A rebirth wipes the run, including whatever you are carrying: the
	-- reset knocks it out of your hands first, so no brainrot survives
	-- the wipe as a dangling carry.
	if state.Carrying then
		context.Conveyor.DropCarry(player, state)
	end
	GameState.ApplyRebirth(state)
	context.Conveyor.ClearAllPens()
	context.Remotes.RebirthDone:FireClient(player, state.Rebirths, state.Multiplier)
	context.Remotes.Toast:FireClient(player, "REBIRTH #" .. state.Rebirths .. "! Income x" .. string.format("%.2f", state.Multiplier))
	pushSnapshot(player)
end

-- Sell one of your own brainrots: stand next to its pen and press V.
-- The client sends the pen position; the server works out which of YOUR
-- pens that is, removes the brainrot, and pays 70% of its cost (times
-- its mutation multiplier). Selling is how you cash out a duplicate or
-- free a pen for something better.
local function sellBrainrot(player, penPos)
	local state = context.States[player]
	if not state or typeof(penPos) ~= "Vector3" then
		return
	end
	local WorldBuilder = require(script.Parent.WorldBuilder)
	local slot = nil
	for s = 1, GameState.PenCap(state) do
		local pos = WorldBuilder.PenPosition(state.PlotIndex, s)
		if (pos - penPos).Magnitude < 4 then
			slot = s
			break
		end
	end
	if not slot then
		return
	end
	local owned = nil
	for _, entry in ipairs(state.Brainrots) do
		if entry.Slot == slot then
			owned = entry
			break
		end
	end
	if not owned then
		return
	end
	local def = BrainrotCatalog.Get(owned.DefId)
	if not def then
		return
	end
	-- Selling pays 70% of what you paid for it — the mutation is an
	-- income bonus, not a resale bonus. (Paying the mutation multiplier
	-- here used to refund up to 8.4x the buy price: buy a Glitch brainrot
	-- cheap, sell it for a fortune. That money printer is gone.)
	local price = math.floor(def.Cost * RumbleConfig.SellFraction)
	GameState.RemoveBrainrot(state, slot)
	context.Conveyor.ClearPen(state, slot)
	GameState.AddCash(state, price)
	context.Remotes.Toast:FireClient(player, "Sold " .. def.Name .. " for " .. MoneyFormat.Cash(price) .. "!")
	pushSnapshot(player)
end

function EconomyService.Start(ctx)
	context = ctx
	context.Remotes.LockBase.OnServerEvent:Connect(lockBase)
	context.Remotes.BuyUpgrade.OnServerEvent:Connect(buyUpgrade)
	context.Remotes.Rebirth.OnServerEvent:Connect(rebirth)
	context.Remotes.SellBrainrot.OnServerEvent:Connect(sellBrainrot)

	-- The money tick: once a second, pay everyone, check their missions
	-- (newly finished ones pay their reward and get announced), and
	-- refresh their HUD.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for player, state in pairs(context.States) do
				local income = GameState.IncomePerSecond(state, now)
				if income > 0 then
					GameState.AddCash(state, income)
				end
				local completed = GameState.CheckMissions(state)
				for _, mission in ipairs(completed) do
					context.Remotes.MissionDone:FireClient(player, mission.Title, mission.Reward)
					context.Remotes.Toast:FireClient(player, "MISSION COMPLETE: " .. mission.Title .. " +$" .. mission.Reward .. "!")
				end
				local collections = GameState.CheckCollection(state)
				for _, collection in ipairs(collections) do
					context.Remotes.MissionDone:FireClient(player, collection.Title, collection.Reward)
					context.Remotes.Toast:FireClient(player, collection.Title .. " +$" .. collection.Reward .. "!")
				end
				-- A lock that ran out hides its gate again.
				if state.LockUntil > 0 and now >= state.LockUntil then
					state.LockUntil = 0
					local gate = context.World.Gates[state.PlotIndex]
					if gate then
						gate.Transparency = 1
						gate.CanCollide = false
					end
				end
				pushSnapshot(player)
			end
		end
	end)
end

return EconomyService
