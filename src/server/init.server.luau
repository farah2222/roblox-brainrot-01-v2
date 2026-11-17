-- Brainrot Bay: the server entry point. It builds the world, creates
-- the RemoteEvents the client talks through, and starts the three
-- services -- ConveyorService (the buy loop), EconomyService (the
-- money) and ThreatService (the thief and the wave). State lives in
-- one place: the States table of GameState player states.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilder = require(script.Parent.WorldBuilder)
local ConveyorService = require(script.Parent.ConveyorService)
local EconomyService = require(script.Parent.EconomyService)
local ThreatService = require(script.Parent.ThreatService)

-- The RemoteEvents, one folder in ReplicatedStorage. The client only
-- ever receives through these; the server is authoritative.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BrainrotBayRemotes"
remotesFolder.Parent = ReplicatedStorage

local function remoteEvent(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotesFolder
	return event
end

local Remotes = {
	CashUpdate = remoteEvent("CashUpdate"), -- server -> client, HUD snapshot, 1/s
	BoughtBrainrot = remoteEvent("BoughtBrainrot"), -- server -> all, buy fanfare
	WaveWarning = remoteEvent("WaveWarning"), -- server -> all, wave countdown
	WaveHit = remoteEvent("WaveHit"), -- server -> all, the wave just hit
	ThiefAlert = remoteEvent("ThiefAlert"), -- server -> all, Stan news
	LockUpdate = remoteEvent("LockUpdate"), -- server -> all, a base locked
	RebirthDone = remoteEvent("RebirthDone"), -- server -> all, confetti time
	Popup = remoteEvent("Popup"), -- server -> one client, a toast message
	BuyLock = remoteEvent("BuyLock"), -- client -> server, buy a base lock
	Rebirth = remoteEvent("Rebirth"), -- client -> server, rebirth me
	BuyUpgrade = remoteEvent("BuyUpgrade"), -- client -> server, buy a shop upgrade
}

-- One shared state table: Player -> GameState player state.
local States = {}

-- The four base plots, matched to the centres WorldBuilder used.
local PlotCenters = {
	Vector3.new(-30, 1, 26),
	Vector3.new(30, 1, 26),
	Vector3.new(-30, 1, -26),
	Vector3.new(30, 1, -26),
}
local PlotsTaken = { false, false, false, false }
local Plots = {} -- Player -> plot centre

-- Build the island.
local world = WorldBuilder.build(workspace)

-- Start the services. The conveyor starts first: it needs the
-- States/Plots tables the economy fills in as players join.
local Conveyor = ConveyorService.start({
	States = States,
	Plots = Plots,
	Remotes = Remotes,
	Workspace = workspace,
})
EconomyService.start({
	States = States,
	Plots = Plots,
	PlotCenters = PlotCenters,
	PlotsTaken = PlotsTaken,
	Remotes = Remotes,
	Workspace = workspace,
	Conveyor = Conveyor,
})
ThreatService.start({
	States = States,
	Plots = Plots,
	Remotes = Remotes,
	Workspace = workspace,
	Conveyor = Conveyor,
})

-- Re-apply Speed Boots on respawn (the upgrade survives death).
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local state = States[player]
		if state and state.Upgrades.SpeedBoots then
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.WalkSpeed = 16 * 1.3
			end
		end
	end)
end)

-- The clouds drift slowly across the sky, for life.
task.spawn(function()
	while true do
		task.wait(1)
		for _, cloud in ipairs(world:GetChildren()) do
			if cloud.Name == "Cloud" and cloud:IsA("Model") then
				local cf = cloud:GetPivot()
				cloud:PivotTo(cf + Vector3.new(0.4, 0, 0))
				if cf.Position.X > 120 then
					cloud:PivotTo(CFrame.new(Vector3.new(-120, cf.Position.Y, cf.Position.Z)))
				end
			end
		end
	end
end)

print("[Brainrot Bay] Server started: island built, conveyor running, threats armed.")
