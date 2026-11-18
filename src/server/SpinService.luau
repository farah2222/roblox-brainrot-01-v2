-- Brainrot Rumble: SpinService runs the lucky spin wheel. One free spin
-- every two minutes. The wheel is honest: it rolls in the open, on the
-- server, and the prize is applied here, never on the client. Prizes are
-- cash, a free brainrot for your base, a mutation upgrade on a brainrot
-- you already own, or double income for a minute.

local RumbleConfig = require(game:GetService("ReplicatedStorage").Shared.RumbleConfig)
local BrainrotCatalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)
local GameState = require(game:GetService("ReplicatedStorage").Shared.GameState)
local MoneyFormat = require(game:GetService("ReplicatedStorage").Shared.MoneyFormat)

local SpinService = {}

local context = nil

local MUTATION_LADDER = { Normal = "Golden", Golden = "Rainbow", Rainbow = "Diamond", Diamond = "Diamond" }

-- Roll a prize. Returns a table describing it.
local function rollPrize(state)
	local roll = math.random(1, 100)
	if roll <= 30 then
		return { Kind = "Cash", Amount = 500, Label = "500 cash" }
	elseif roll <= 50 then
		return { Kind = "Cash", Amount = 2000, Label = "2,000 cash" }
	elseif roll <= 60 then
		return { Kind = "Cash", Amount = 10000, Label = "10,000 cash" }
	elseif roll <= 78 then
		local rarity = BrainrotCatalog.RollRarity()
		local def = BrainrotCatalog.RandomOfRarity(rarity)
		return { Kind = "Brainrot", DefId = def.Id, Mutation = BrainrotCatalog.RollMutation(), Label = def.Name }
	elseif roll <= 90 then
		return { Kind = "Boost", Seconds = RumbleConfig.SpinBoostSeconds, Label = "2x income for 60s" }
	else
		return { Kind = "Upgrade", Label = "Mutation upgrade" }
	end
end

local function spin(player)
	local state = context.States[player]
	if not state then
		return
	end
	local now = os.time()
	if now < state.NextSpinAt then
		local left = state.NextSpinAt - now
		context.Remotes.Toast:FireClient(player, "Next free spin in " .. left .. "s!")
		return
	end
	state.NextSpinAt = now + RumbleConfig.SpinEvery
	local prize = rollPrize(state)

	if prize.Kind == "Cash" then
		GameState.AddCash(state, prize.Amount)
		context.Remotes.SpinResult:FireClient(player, prize.Label)
		context.Remotes.Toast:FireClient(player, "Spin won " .. MoneyFormat.Cash(prize.Amount) .. "!")
	elseif prize.Kind == "Brainrot" then
		local slot = context.Conveyor.PlaceOnBase(prize.DefId, prize.Mutation, state, context.World)
		if slot then
			context.Remotes.SpinResult:FireClient(player, prize.Label)
			context.Remotes.Toast:FireClient(player, "Spin won " .. prize.Label .. "!")
		else
			GameState.AddCash(state, 5000)
			context.Remotes.SpinResult:FireClient(player, "5,000 cash (base was full)")
			context.Remotes.Toast:FireClient(player, "Base full — spin paid 5,000 cash instead!")
		end
	elseif prize.Kind == "Boost" then
		state.BoostUntil = now + prize.Seconds
		context.Remotes.SpinResult:FireClient(player, prize.Label)
		context.Remotes.Toast:FireClient(player, "Spin won 2x income for 60 seconds!")
	elseif prize.Kind == "Upgrade" then
		local owned = state.Brainrots
		if #owned == 0 then
			GameState.AddCash(state, 2000)
			context.Remotes.SpinResult:FireClient(player, "2,000 cash (no brainrot to upgrade)")
			context.Remotes.Toast:FireClient(player, "No brainrot to upgrade — spin paid 2,000 cash!")
		else
			local pick = owned[math.random(1, #owned)]
			pick.Mutation = MUTATION_LADDER[pick.Mutation] or "Golden"
			local def = BrainrotCatalog.Get(pick.DefId)
			local name = def and def.Name or "a brainrot"
			context.Remotes.SpinResult:FireClient(player, name .. " upgraded to " .. pick.Mutation .. "!")
			context.Remotes.Toast:FireClient(player, "Spin upgraded " .. name .. " to " .. pick.Mutation .. "!")
		end
	end
end

function SpinService.Start(ctx)
	context = ctx
	context.Remotes.SpinWheel.OnServerEvent:Connect(spin)
end

return SpinService
