-- Brainrot Rumble: the server entry point. It builds the arena, creates
-- the RemoteEvents the client talks through, hands each player a plot and
-- a fresh state, and starts the five services: ConveyorService (the buy
-- loop), EconomyService (the money), CombatService (weapons and steals),
-- ThreatService (thief, tsunami, meteors) and SpinService (the wheel).
-- The client never moves money or brainrots itself; every action arrives
-- here as a RemoteEvent and is validated by the service that owns it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilder = require(script.WorldBuilder)
local ConveyorService = require(script.ConveyorService)
local EconomyService = require(script.EconomyService)
local CombatService = require(script.CombatService)
local ThreatService = require(script.ThreatService)
local SpinService = require(script.SpinService)
local GameState = require(ReplicatedStorage.Shared.GameState)

-- The arena, built once.
local world = WorldBuilder.Build()

-- The RemoteEvents, one folder, one per action or broadcast.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "RumbleRemotes"
remotesFolder.Parent = ReplicatedStorage
local remoteNames = {
	"BuyBrainrot", "LockBase", "BuyUpgrade", "Rebirth", "UseWeapon",
	"StealStart", "SpinWheel", "HudUpdate", "Toast", "ToastAll",
	"BrainrotBought", "RebirthDone", "WeaponSwung", "WeaponHit",
	"StealStarted", "StealStopped", "StealDone", "SpinResult",
	"ThiefComing", "TsunamiWarning", "TsunamiHit",
}
local remotes = {}
for _, name in ipairs(remoteNames) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	remotes[name] = remote
end

-- One state per player, plus the plot each one owns.
local states = {}
local freePlots = { 1, 2, 3, 4 }

local function givePlot()
	if #freePlots > 0 then
		return table.remove(freePlots, 1)
	end
	return 1 -- arena full: share plot 1 rather than refuse a player
end

local function onPlayerAdded(player)
	local state = GameState.NewPlayer()
	state.PlotIndex = givePlot()
	states[player] = state
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = GameState.WalkSpeed(state)
	end)
	remotes.Toast:FireClient(player, "Welcome to Brainrot Rumble! Buy brainrots, defend your base, spin the wheel!")
end

local function onPlayerRemoving(player)
	local state = states[player]
	if state and state.PlotIndex >= 1 and state.PlotIndex <= 4 then
		table.insert(freePlots, state.PlotIndex)
	end
	states[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- The shared context every service gets.
local context = {
	Remotes = remotes,
	States = states,
	World = world,
	Conveyor = ConveyorService,
	Combat = CombatService,
}

ConveyorService.Start(context)
EconomyService.Start(context)
CombatService.Start(context)
ThreatService.Start(context)
SpinService.Start(context)

print("Brainrot Rumble server ready: arena built, " .. #remoteNames .. " remotes live.")
