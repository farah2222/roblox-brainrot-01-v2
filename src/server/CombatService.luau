-- Brainrot Rumble: CombatService runs the fight. Three weapons on keys
-- 1, 2 and 3, plus stealing from other players' bases. Every weapon has
-- a server-side cooldown (shortened by Golden Glove upgrades), and every
-- hit is validated here: the client only ever says "I swung", the server
-- decides what it hit. A weapon hit on a thief interrupts their steal.

local RumbleConfig = require(game:GetService("ReplicatedStorage").Shared.RumbleConfig)
local GameState = require(game:GetService("ReplicatedStorage").Shared.GameState)
local WorldBuilder = require(script.Parent.WorldBuilder)

local CombatService = {}

local context = nil
local lastUsed = {} -- player -> { Slap = clock, Freeze = clock, Pull = clock }
local channels = {} -- thief player -> { Victim, Slot, EndsAt }

-- The nearest other player to a position, within a range, or nil.
local function nearestRival(player, range)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best = nil
	local bestDist = range
	for _, other in ipairs(game:GetService("Players"):GetPlayers()) do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local dist = (otherRoot.Position - root.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					best = other
				end
			end
		end
	end
	return best
end

-- Cancel a thief's steal channel, with a reason for the toast.
local function cancelChannel(thief, reason)
	local channel = channels[thief]
	if not channel then
		return
	end
	channels[thief] = nil
	context.Remotes.StealStopped:FireClient(thief, reason)
end

-- Any weapon hit on a player interrupts their steal.
function CombatService.Interrupt(player)
	cancelChannel(player, "Your steal was interrupted!")
end

-- A weapon swing near Si Cilok Nakal bonks him away (and counts for the
-- "Thief Buster" mission). Returns true when a bonk landed.
local function tryBonkThief(player, position, range)
	if context.Threat and context.Threat.TryBonkThief then
		return context.Threat.TryBonkThief(player, position, range)
	end
	return false
end

-- A weapon hit on a carrier makes them drop what they are carrying.
local function dropCarried(player)
	local state = context.States[player]
	if not state then
		return
	end
	if context.Conveyor and context.Conveyor.IsCarrying(state) then
		context.Conveyor.DropCarry(player, state)
	end
end

-- Shove a player's character along a direction.
local function shove(player, direction, power)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.AssemblyLinearVelocity = direction * power + Vector3.new(0, 12, 0)
end

local function swingSlap(player)
	local weapon = RumbleConfig.Weapons.Slap
	local state = context.States[player]
	if not state then
		return
	end
	local now = os.clock()
	local used = lastUsed[player]
	if not used then
		used = {}
		lastUsed[player] = used
	end
	local cooldown = weapon.Cooldown * GameState.CooldownScale(state)
	if used.Slap and now - used.Slap < cooldown then
		return
	end
	used.Slap = now
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local rival = nearestRival(player, weapon.Reach)
	if not rival then
		local bonked = tryBonkThief(player, root.Position, weapon.Reach)
		context.Remotes.WeaponSwung:FireClient(player, "Slap", bonked)
		return
	end
	local direction = (rival.Character.HumanoidRootPart.Position - root.Position).Unit
	shove(rival, direction, weapon.Shove)
	CombatService.Interrupt(rival)
	dropCarried(rival)
	context.Remotes.WeaponSwung:FireClient(player, "Slap", true)
	context.Remotes.WeaponHit:FireClient(rival, "Slap")
	context.Remotes.Toast:FireClient(rival, player.Name .. " slapped you away!")
end

local function fireFreeze(player)
	local weapon = RumbleConfig.Weapons.Freeze
	local state = context.States[player]
	if not state then
		return
	end
	local now = os.clock()
	local used = lastUsed[player]
	if not used then
		used = {}
		lastUsed[player] = used
	end
	local cooldown = weapon.Cooldown * GameState.CooldownScale(state)
	if used.Freeze and now - used.Freeze < cooldown then
		return
	end
	used.Freeze = now
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return
	end
	local rival = nearestRival(player, weapon.Reach)
	if not rival then
		local bonked = tryBonkThief(player, myRoot.Position, weapon.Reach)
		context.Remotes.WeaponSwung:FireClient(player, "Freeze", bonked)
		return
	end
	local humanoid = rival.Character and rival.Character:FindFirstChildOfClass("Humanoid")
	local root = rival.Character and rival.Character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end
	CombatService.Interrupt(rival)
	dropCarried(rival)
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	local ice = Instance.new("Part")
	ice.Name = "FreezeBlock"
	ice.Size = Vector3.new(4, 6, 4)
	ice.Color = Color3.fromRGB(140, 230, 255)
	ice.Material = Enum.Material.Ice
	ice.Transparency = 0.4
	ice.Anchored = true
	ice.CanCollide = false
	ice.CFrame = root.CFrame
	ice.Parent = workspace
	context.Remotes.WeaponSwung:FireClient(player, "Freeze", true)
	context.Remotes.WeaponHit:FireClient(rival, "Freeze")
	context.Remotes.Toast:FireClient(rival, player.Name .. " froze you solid!")
	task.delay(weapon.FreezeTime, function()
		ice:Destroy()
		if humanoid.Parent then
			local victimState = context.States[rival]
			if victimState and context.Conveyor and context.Conveyor.RefreshWalkSpeed then
				-- RefreshWalkSpeed re-applies the carry slow, so a
				-- frozen carrier does not thaw at full speed.
				context.Conveyor.RefreshWalkSpeed(rival, victimState)
			elseif victimState then
				humanoid.WalkSpeed = GameState.WalkSpeed(victimState)
			else
				humanoid.WalkSpeed = 16
			end
			humanoid.JumpPower = 50
		end
	end)
end

local function pullBrainrot(player)
	local weapon = RumbleConfig.Weapons.Pull
	local state = context.States[player]
	if not state then
		return
	end
	local now = os.clock()
	local used = lastUsed[player]
	if not used then
		used = {}
		lastUsed[player] = used
	end
	local cooldown = weapon.Cooldown * GameState.CooldownScale(state)
	if used.Pull and now - used.Pull < cooldown then
		return
	end
	used.Pull = now
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local target = root.Position + root.CFrame.LookVector * 6
	local entry = context.Conveyor.PullNearest(root.Position, weapon.Reach, target)
	if entry then
		context.Remotes.WeaponSwung:FireClient(player, "Pull", true)
		context.Remotes.Toast:FireClient(player, "Magnet pulled " .. entry.Def.Name .. " to you!")
	else
		local bonked = tryBonkThief(player, root.Position, weapon.Reach)
		context.Remotes.WeaponSwung:FireClient(player, "Pull", bonked)
	end
end

-- Start a steal. The client sends the pen position it is standing next
-- to; the server works out whose pen that is and which slot, then checks
-- everything: not your own base, not locked, a brainrot really there,
-- your base not full, and you close enough to reach it.
local function startSteal(thief, penPos)
	local thiefState = context.States[thief]
	if not thiefState or typeof(penPos) ~= "Vector3" then
		return
	end
	if channels[thief] then
		return
	end
	if context.Conveyor and context.Conveyor.IsCarrying(thiefState) then
		context.Remotes.Toast:FireClient(thief, "You are already carrying a brainrot! Take it home first.")
		return
	end
	local victim = nil
	local victimState = nil
	local slot = nil
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player ~= thief then
			local state = context.States[player]
			if state then
				for s = 1, RumbleConfig.PensPerBase do
					local pos = WorldBuilder.PenPosition(state.PlotIndex, s)
					if (pos - penPos).Magnitude < 4 then
						victim = player
						victimState = state
						slot = s
						break
					end
				end
			end
			if victim then
				break
			end
		end
	end
	if not victim or not victimState or not slot then
		return
	end
	if GameState.IsLocked(victimState, os.time()) then
		context.Remotes.Toast:FireClient(thief, victim.Name .. "'s base is LOCKED!")
		return
	end
	local owned = nil
	for _, entry in ipairs(victimState.Brainrots) do
		if entry.Slot == slot then
			owned = entry
			break
		end
	end
	if not owned then
		return
	end
	if not GameState.FreeSlot(thiefState) then
		context.Remotes.Toast:FireClient(thief, "Your base is full!")
		return
	end
	local thiefRoot = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	if not thiefRoot then
		return
	end
	local penPosition = WorldBuilder.PenPosition(victimState.PlotIndex, slot)
	if (penPosition - thiefRoot.Position).Magnitude > RumbleConfig.StealRange + 4 then
		context.Remotes.Toast:FireClient(thief, "Get closer to steal that brainrot!")
		return
	end
	channels[thief] = { Victim = victim, Slot = slot, EndsAt = os.clock() + RumbleConfig.StealChannel }
	context.Remotes.StealStarted:FireClient(thief, victim.Name, RumbleConfig.StealChannel)
	context.Remotes.Toast:FireClient(victim, thief.Name .. " is stealing from your base!")
end

-- The channel watcher: finish steals whose timer ran out, cancel ones
-- whose thief wandered off or whose victim locked up mid-steal.
local function watchChannels()
	while true do
		task.wait(0.2)
		local now = os.clock()
		for thief, channel in pairs(channels) do
			local thiefState = context.States[thief]
			local victimState = context.States[channel.Victim]
			local alive = thiefState and victimState and thief.Character
			local root = alive and thief.Character:FindFirstChild("HumanoidRootPart")
			if not alive or not root then
				channels[thief] = nil
			elseif GameState.IsLocked(victimState, os.time()) then
				cancelChannel(thief, "They locked their base mid-steal!")
			else
				local penPos = WorldBuilder.PenPosition(victimState.PlotIndex, channel.Slot)
				if (penPos - root.Position).Magnitude > RumbleConfig.StealRange + 6 then
					cancelChannel(thief, "You moved too far — steal cancelled.")
				elseif now >= channel.EndsAt then
					channels[thief] = nil
					local stolen = GameState.RemoveBrainrot(victimState, channel.Slot)
					if stolen then
						context.Conveyor.ClearPen(victimState, channel.Slot)
						-- The thief carries it home (and can be bonked on the way).
						if context.Conveyor.IsCarrying(thiefState) or not GameState.FreeSlot(thiefState) then
							-- The brainrot stays put: pen it back on the
							-- victim's base. (PlaceOnBase adds the state
							-- entry itself — adding it here too used to
							-- duplicate the brainrot, paying double income
							-- for a model that did not exist.) Keep its
							-- combo stamp, if it had one.
							local slot = context.Conveyor.PlaceOnBase(stolen.DefId, stolen.Mutation, victimState, context.World, stolen.ComboMult, stolen.ComboUntil)
							if not slot then
								GameState.AddBrainrot(victimState, stolen.DefId, stolen.Mutation, stolen.ComboMult, stolen.ComboUntil)
							end
							context.Remotes.Toast:FireClient(thief, "Your hands are full — the brainrot stays put!")
						elseif context.Conveyor.StartCarry(thief, stolen.DefId, stolen.Mutation, thiefState, channel.Victim) then
							context.Remotes.StealDone:FireClient(thief, stolen.DefId)
							context.Remotes.Toast:FireClient(thief, "You stole a brainrot! Carry it home — fast!")
							context.Remotes.Toast:FireClient(channel.Victim, thief.Name .. " stole your brainrot!")
						else
							local slot = context.Conveyor.PlaceOnBase(stolen.DefId, stolen.Mutation, victimState, context.World, stolen.ComboMult, stolen.ComboUntil)
							if not slot then
								GameState.AddBrainrot(victimState, stolen.DefId, stolen.Mutation, stolen.ComboMult, stolen.ComboUntil)
							end
						end
					end
				end
			end
		end
	end
end

function CombatService.Start(ctx)
	context = ctx
	context.Remotes.UseWeapon.OnServerEvent:Connect(function(player, weaponName)
		if weaponName == "Slap" then
			swingSlap(player)
		elseif weaponName == "Freeze" then
			fireFreeze(player)
		elseif weaponName == "Pull" then
			pullBrainrot(player)
		end
	end)
	context.Remotes.StealStart.OnServerEvent:Connect(startSteal)
	task.spawn(watchChannels)
end

return CombatService
