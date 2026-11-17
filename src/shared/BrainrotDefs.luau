-- Brainrot Bay: the cast. 24 original absurd characters on a 6-tier
-- rarity ladder. Every character is invented for this game -- none of
-- them is copied from Steal a Brainrot or any other brainrot game.
-- Each entry carries everything the server, the client and the
-- screenshot renderer need: name, rarity, $/s, cost, colours and a
-- simple blocky model spec (shape + accessory) the builders use.

local BrainrotDefs = {}

BrainrotDefs.Rarities = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
}

-- Rarity colours, as the HUD and the name labels show them.
BrainrotDefs.RarityColors = {
	Common = Color3.fromRGB(150, 200, 120),
	Rare = Color3.fromRGB(90, 160, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 200, 60),
	Mythic = Color3.fromRGB(255, 90, 110),
	Secret = Color3.fromRGB(40, 40, 45),
}

-- Mutation colours and $/s multipliers (see Config for the roll odds).
BrainrotDefs.Mutations = {
	Normal = { Multiplier = 1, Color = Color3.fromRGB(255, 255, 255) },
	Golden = { Multiplier = 2, Color = Color3.fromRGB(255, 215, 0) },
	Rainbow = { Multiplier = 5, Color = Color3.fromRGB(255, 120, 220) },
	Diamond = { Multiplier = 10, Color = Color3.fromRGB(140, 230, 255) },
}

-- shape: "box" | "tall" | "wide" | "round"
-- accessory: "tophat" | "crown" | "sunglasses" | "chefhat" | "cape" | "none"
BrainrotDefs.Characters = {
	-- Common
	{ Id = 1, Name = "Sir Reginald Pickle III", Rarity = "Common", Rate = 1, Cost = 25,
		Body = Color3.fromRGB(110, 180, 70), Head = Color3.fromRGB(140, 210, 90), Accent = Color3.fromRGB(30, 30, 30),
		Shape = "tall", Accessory = "tophat", Quirk = "A pickle in a top hat. Demands respect." },
	{ Id = 2, Name = "Toaster Gary", Rarity = "Common", Rate = 2, Cost = 50,
		Body = Color3.fromRGB(200, 200, 205), Head = Color3.fromRGB(230, 230, 235), Accent = Color3.fromRGB(255, 120, 40),
		Shape = "box", Accessory = "none", Quirk = "Screams every time the toast pops." },
	{ Id = 3, Name = "Brenda the Traffic Cone", Rarity = "Common", Rate = 3, Cost = 100,
		Body = Color3.fromRGB(255, 110, 30), Head = Color3.fromRGB(255, 140, 60), Accent = Color3.fromRGB(255, 255, 255),
		Shape = "tall", Accessory = "none", Quirk = "She directs traffic nobody asked for." },
	{ Id = 4, Name = "Captain Noodlebeard", Rarity = "Common", Rate = 5, Cost = 200,
		Body = Color3.fromRGB(240, 210, 130), Head = Color3.fromRGB(250, 230, 160), Accent = Color3.fromRGB(200, 40, 40),
		Shape = "box", Accessory = "chefhat", Quirk = "A spaghetti pirate. Sails the sauce seas." },

	-- Rare
	{ Id = 5, Name = "Greg the Microwave", Rarity = "Rare", Rate = 8, Cost = 400,
		Body = Color3.fromRGB(90, 90, 100), Head = Color3.fromRGB(120, 120, 135), Accent = Color3.fromRGB(90, 255, 160),
		Shape = "box", Accessory = "none", Quirk = "Beeps when he is done. He is never done." },
	{ Id = 6, Name = "Madame Croissant", Rarity = "Rare", Rate = 12, Cost = 800,
		Body = Color3.fromRGB(220, 170, 90), Head = Color3.fromRGB(240, 200, 120), Accent = Color3.fromRGB(255, 90, 160),
		Shape = "wide", Accessory = "crown", Quirk = "Flaky, buttery, and terribly French." },
	{ Id = 7, Name = "Professor Sock", Rarity = "Rare", Rate = 16, Cost = 1500,
		Body = Color3.fromRGB(140, 140, 220), Head = Color3.fromRGB(170, 170, 240), Accent = Color3.fromRGB(255, 255, 255),
		Shape = "tall", Accessory = "sunglasses", Quirk = "Holds a PhD in being lost in the dryer." },
	{ Id = 8, Name = "DJ Blender", Rarity = "Rare", Rate = 22, Cost = 2500,
		Body = Color3.fromRGB(60, 60, 70), Head = Color3.fromRGB(90, 90, 110), Accent = Color3.fromRGB(255, 60, 220),
		Shape = "box", Accessory = "sunglasses", Quirk = "Drops beats. Also drops smoothies." },

	-- Epic
	{ Id = 9, Name = "Lord Biscuit", Rarity = "Epic", Rate = 35, Cost = 5000,
		Body = Color3.fromRGB(190, 140, 80), Head = Color3.fromRGB(215, 170, 105), Accent = Color3.fromRGB(255, 215, 0),
		Shape = "round", Accessory = "crown", Quirk = "Crumbly nobility. Dunk with caution." },
	{ Id = 10, Name = "The Honorable Dumpster", Rarity = "Epic", Rate = 50, Cost = 9000,
		Body = Color3.fromRGB(60, 110, 70), Head = Color3.fromRGB(80, 140, 90), Accent = Color3.fromRGB(255, 200, 60),
		Shape = "wide", Accessory = "none", Quirk = "Elected by the raccoons. Twice." },
	{ Id = 11, Name = "Countess WiFi", Rarity = "Epic", Rate = 70, Cost = 15000,
		Body = Color3.fromRGB(120, 90, 200), Head = Color3.fromRGB(150, 120, 230), Accent = Color3.fromRGB(90, 255, 160),
		Shape = "tall", Accessory = "cape", Quirk = "Her signal reaches everywhere. Her password, nowhere." },
	{ Id = 12, Name = "Sir Loin of Beef", Rarity = "Epic", Rate = 95, Cost = 25000,
		Body = Color3.fromRGB(190, 90, 80), Head = Color3.fromRGB(220, 120, 105), Accent = Color3.fromRGB(255, 215, 0),
		Shape = "box", Accessory = "cape", Quirk = "Knighted for services to Sunday lunch." },

	-- Legendary
	{ Id = 13, Name = "Grandma's WiFi Router", Rarity = "Legendary", Rate = 140, Cost = 45000,
		Body = Color3.fromRGB(40, 40, 50), Head = Color3.fromRGB(60, 60, 75), Accent = Color3.fromRGB(90, 255, 160),
		Shape = "box", Accessory = "none", Quirk = "Blinking since 2009. Never once restarted." },
	{ Id = 14, Name = "The Last Slice", Rarity = "Legendary", Rate = 200, Cost = 80000,
		Body = Color3.fromRGB(240, 190, 80), Head = Color3.fromRGB(255, 210, 110), Accent = Color3.fromRGB(200, 40, 40),
		Shape = "wide", Accessory = "crown", Quirk = "Everyone wants it. Nobody dares take it." },
	{ Id = 15, Name = "Turbo Toilet Terry", Rarity = "Legendary", Rate = 280, Cost = 140000,
		Body = Color3.fromRGB(240, 240, 245), Head = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(90, 160, 255),
		Shape = "tall", Accessory = "sunglasses", Quirk = "Flushes at Mach 2. Plumbers fear him." },
	{ Id = 16, Name = "Quantum Banana", Rarity = "Legendary", Rate = 400, Cost = 250000,
		Body = Color3.fromRGB(255, 230, 60), Head = Color3.fromRGB(255, 240, 110), Accent = Color3.fromRGB(150, 90, 255),
		Shape = "tall", Accessory = "none", Quirk = "Both peeled and unpeeled until observed." },

	-- Mythic
	{ Id = 17, Name = "The CEO of Clouds", Rarity = "Mythic", Rate = 600, Cost = 450000,
		Body = Color3.fromRGB(235, 240, 250), Head = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(90, 160, 255),
		Shape = "wide", Accessory = "tophat", Quirk = "Runs the sky. Rain is just downsizing." },
	{ Id = 18, Name = "Sir Barksalot, Esq.", Rarity = "Mythic", Rate = 850, Cost = 750000,
		Body = Color3.fromRGB(170, 120, 70), Head = Color3.fromRGB(200, 150, 95), Accent = Color3.fromRGB(255, 215, 0),
		Shape = "box", Accessory = "tophat", Quirk = "A lawyer dog. Bills by the woof." },
	{ Id = 19, Name = "The Infinite Burrito", Rarity = "Mythic", Rate = 1200, Cost = 1200000,
		Body = Color3.fromRGB(200, 150, 90), Head = Color3.fromRGB(230, 180, 110), Accent = Color3.fromRGB(90, 200, 90),
		Shape = "wide", Accessory = "cape", Quirk = "Every bite reveals another burrito inside." },
	{ Id = 20, Name = "Mayor McMuffin", Rarity = "Mythic", Rate = 1700, Cost = 2000000,
		Body = Color3.fromRGB(230, 180, 90), Head = Color3.fromRGB(250, 205, 120), Accent = Color3.fromRGB(200, 40, 40),
		Shape = "round", Accessory = "tophat", Quirk = "Runs the town on breakfast and promises." },

	-- Secret
	{ Id = 21, Name = "The Moon's Lost Sock", Rarity = "Secret", Rate = 3000, Cost = 5000000,
		Body = Color3.fromRGB(220, 220, 235), Head = Color3.fromRGB(240, 240, 250), Accent = Color3.fromRGB(255, 215, 0),
		Shape = "tall", Accessory = "cape", Quirk = "It saw the moon landing. It stayed behind." },
	{ Id = 22, Name = "Gandalf the Grey Area", Rarity = "Secret", Rate = 5000, Cost = 10000000,
		Body = Color3.fromRGB(140, 140, 150), Head = Color3.fromRGB(170, 170, 180), Accent = Color3.fromRGB(150, 90, 255),
		Shape = "tall", Accessory = "tophat", Quirk = "Neither wizard nor loophole. Both, somehow." },
	{ Id = 23, Name = "The WiFi Password Itself", Rarity = "Secret", Rate = 9000, Cost = 25000000,
		Body = Color3.fromRGB(30, 30, 40), Head = Color3.fromRGB(50, 50, 65), Accent = Color3.fromRGB(90, 255, 160),
		Shape = "round", Accessory = "crown", Quirk = "Everyone seeks it. It changes every Tuesday." },
	{ Id = 24, Name = "Brainrot Prime: The Original Meme", Rarity = "Secret", Rate = 15000, Cost = 50000000,
		Body = Color3.fromRGB(255, 215, 0), Head = Color3.fromRGB(255, 230, 90), Accent = Color3.fromRGB(255, 60, 220),
		Shape = "round", Accessory = "crown", Quirk = "The first meme. All other memes are fan fiction." },
}

-- Look a character up by id; returns nil for an unknown id.
function BrainrotDefs.getById(id: number)
	for _, def in ipairs(BrainrotDefs.Characters) do
		if def.Id == id then
			return def
		end
	end
	return nil
end

-- All characters of one rarity tier, in ladder order.
function BrainrotDefs.getByRarity(rarity: string)
	local out = {}
	for _, def in ipairs(BrainrotDefs.Characters) do
		if def.Rarity == rarity then
			table.insert(out, def)
		end
	end
	return out
end

-- Weighted spawn pick: common brainrots show up constantly, secrets
-- almost never. Weights fall as the id (and price) climb.
function BrainrotDefs.rollSpawn(): (any, string)
	local weights = {}
	local total = 0
	for _, def in ipairs(BrainrotDefs.Characters) do
		local w = 1 / (def.Id * def.Id)
		table.insert(weights, w)
		total += w
	end
	local roll = math.random() * total
	for i, def in ipairs(BrainrotDefs.Characters) do
		roll -= weights[i]
		if roll <= 0 then
			return def, BrainrotDefs.rollMutation()
		end
	end
	return BrainrotDefs.Characters[1], "Normal"
end

-- Roll a mutation: Diamond 1%, Rainbow 3%, Golden 10%, else Normal.
function BrainrotDefs.rollMutation(): string
	local roll = math.random()
	if roll < 0.01 then
		return "Diamond"
	elseif roll < 0.04 then
		return "Rainbow"
	elseif roll < 0.14 then
		return "Golden"
	end
	return "Normal"
end

-- A brainrot's true $/s: base rate x mutation x the owner's rebirth bonus.
function BrainrotDefs.effectiveRate(def, mutation: string, rebirthBonus: number): number
	local mult = BrainrotDefs.Mutations[mutation].Multiplier
	return math.floor(def.Rate * mult * (1 + rebirthBonus) + 0.5)
end

-- Short money text: 1,500 -> "$1.5K", 2,500,000 -> "$2.5M".
function BrainrotDefs.formatMoney(amount: number): string
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	end
	return "$" .. tostring(math.floor(amount + 0.5))
end

return BrainrotDefs
