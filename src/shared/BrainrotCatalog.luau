-- Brainrot Rumble: the cast. Thirty original absurd characters, five per
-- rarity tier, each with a name, a money-per-second rate, a price, colours,
-- a body shape and an accessory. Nothing here is copied from any other
-- brainrot game: every one of these was invented for this arena, most of
-- them out of Indonesian street food that refused to stay on the plate.

local BrainrotCatalog = {}

-- Rarity ladder, cheapest first. Weight is the share of spawns.
BrainrotCatalog.Rarities = {
	{ Name = "Common", Weight = 45, Color = Color3.fromRGB(150, 200, 120) },
	{ Name = "Rare", Weight = 28, Color = Color3.fromRGB(90, 160, 255) },
	{ Name = "Epic", Weight = 15, Color = Color3.fromRGB(190, 110, 255) },
	{ Name = "Legendary", Weight = 8, Color = Color3.fromRGB(255, 200, 60) },
	{ Name = "Mythic", Weight = 3, Color = Color3.fromRGB(255, 90, 110) },
	{ Name = "Secret", Weight = 1, Color = Color3.fromRGB(40, 40, 45) },
}

-- Mutations that can roll on any spawn. Multiplier applies to $/s.
BrainrotCatalog.Mutations = {
	{ Name = "Normal", Multiplier = 1, Chance = 89.4 },
	{ Name = "Golden", Multiplier = 2, Chance = 8 },
	{ Name = "Rainbow", Multiplier = 5, Chance = 2 },
	{ Name = "Diamond", Multiplier = 10, Chance = 0.6 },
}

-- One entry per character. Colours are 0-255 RGB triples.
-- Shape: "box", "tall", "wide" or "round". Accessory: "tophat", "crown",
-- "sunglasses", "chefhat", "cape", "sombrero" or "none".
BrainrotCatalog.Characters = {
	-- Common: the everyday absurd.
	{ Id = "ayam-geprek", Name = "Ayam Geprek Terbang", Rarity = "Common", Rate = 2, Cost = 60,
		Body = { 235, 180, 90 }, Head = { 250, 210, 120 }, Accent = { 200, 40, 40 }, Shape = "tall", Accessory = "chefhat",
		Blurb = "A smashed fried chicken that learned to fly and never landed." },
	{ Id = "es-teh", Name = "Es Teh Manis Menangis", Rarity = "Common", Rate = 3, Cost = 90,
		Body = { 200, 120, 60 }, Head = { 230, 170, 90 }, Accent = { 90, 160, 255 }, Shape = "tall", Accessory = "none",
		Blurb = "Sweet iced tea, crying, because someone drank its best friend." },
	{ Id = "sendal", Name = "Sendal Jepit Sakti", Rarity = "Common", Rate = 1, Cost = 30,
		Body = { 60, 120, 220 }, Head = { 90, 160, 250 }, Accent = { 255, 220, 60 }, Shape = "wide", Accessory = "none",
		Blurb = "One magic flip-flop. The other one is still missing." },
	{ Id = "kucing-oren", Name = "Kucing Oren Ngamuk", Rarity = "Common", Rate = 5, Cost = 150,
		Body = { 255, 140, 30 }, Head = { 255, 170, 60 }, Accent = { 30, 30, 30 }, Shape = "box", Accessory = "none",
		Blurb = "An orange cat. Angry. About everything. Especially Mondays." },
	{ Id = "bakso-beranak", Name = "Bakso Beranak", Rarity = "Common", Rate = 8, Cost = 240,
		Body = { 180, 120, 80 }, Head = { 210, 150, 100 }, Accent = { 120, 200, 90 }, Shape = "round", Accessory = "none",
		Blurb = "A meatball that had a baby meatball. The baby charges rent." },
	-- Rare: the street-food regulars.
	{ Id = "indomie-goreng", Name = "Indomie Goreng Raksasa", Rarity = "Rare", Rate = 15, Cost = 600,
		Body = { 240, 210, 130 }, Head = { 250, 230, 160 }, Accent = { 200, 40, 40 }, Shape = "wide", Accessory = "chefhat",
		Blurb = "A giant plate of fried noodles. It seasoned itself." },
	{ Id = "kopi-susu", Name = "Kopi Susu Gula Aren", Rarity = "Rare", Rate = 12, Cost = 500,
		Body = { 120, 80, 50 }, Head = { 160, 110, 70 }, Accent = { 240, 200, 150 }, Shape = "tall", Accessory = "none",
		Blurb = "Palm-sugar milk coffee. Too sweet to fight, too strong to sleep." },
	{ Id = "tahu-bulat", Name = "Tahu Bulat Terbang", Rarity = "Rare", Rate = 18, Cost = 750,
		Body = { 240, 220, 180 }, Head = { 250, 235, 200 }, Accent = { 255, 200, 60 }, Shape = "round", Accessory = "sombrero",
		Blurb = "Round tofu, fried on a moving truck, now flying solo." },
	{ Id = "cilok", Name = "Cilok Kenyal Abadi", Rarity = "Rare", Rate = 22, Cost = 900,
		Body = { 220, 180, 140 }, Head = { 240, 205, 165 }, Accent = { 220, 60, 60 }, Shape = "round", Accessory = "none",
		Blurb = "Chewy forever. Dentists fear it. Children worship it." },
	{ Id = "gorengan", Name = "Gorengan Hangat Pagi", Rarity = "Rare", Rate = 30, Cost = 1200,
		Body = { 230, 170, 80 }, Head = { 245, 200, 110 }, Accent = { 255, 120, 40 }, Shape = "box", Accessory = "tophat",
		Blurb = "Warm morning fritters in a top hat. Still warm. Always warm." },
	-- Epic: the full meals.
	{ Id = "nasi-padang", Name = "Nasi Padang Rendang Raja", Rarity = "Epic", Rate = 50, Cost = 2500,
		Body = { 200, 140, 60 }, Head = { 230, 180, 90 }, Accent = { 255, 215, 0 }, Shape = "wide", Accessory = "crown",
		Blurb = "King of rendang rice. Its gravy has its own gravy." },
	{ Id = "sate-ayam", Name = "Sate Ayam Bakar Api", Rarity = "Epic", Rate = 65, Cost = 3200,
		Body = { 190, 90, 50 }, Head = { 220, 120, 70 }, Accent = { 255, 120, 30 }, Shape = "tall", Accessory = "cape",
		Blurb = "Fire-grilled satay. The skewer is its sword." },
	{ Id = "martabak", Name = "Martabak Manis Coklat Keju", Rarity = "Epic", Rate = 80, Cost = 4000,
		Body = { 220, 180, 90 }, Head = { 240, 205, 120 }, Accent = { 120, 80, 200 }, Shape = "wide", Accessory = "crown",
		Blurb = "Sweet martabak, half chocolate, half cheese, all chaos." },
	{ Id = "gado-gado", Name = "Gado-Gado Pelangi", Rarity = "Epic", Rate = 95, Cost = 4800,
		Body = { 120, 200, 120 }, Head = { 160, 230, 160 }, Accent = { 255, 90, 160 }, Shape = "box", Accessory = "sombrero",
		Blurb = "Rainbow salad with peanut sauce. It contains multitudes." },
	{ Id = "soto-ayam", Name = "Soto Ayam Kuning Kilat", Rarity = "Epic", Rate = 120, Cost = 6000,
		Body = { 250, 200, 60 }, Head = { 255, 220, 100 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "none",
		Blurb = "Lightning-yellow chicken soup. It arrived before you ordered." },
	-- Legendary: the royalty of the food court.
	{ Id = "mie-ayam", Name = "Raja Mie Ayam Bakso", Rarity = "Legendary", Rate = 200, Cost = 12000,
		Body = { 240, 210, 130 }, Head = { 250, 230, 160 }, Accent = { 255, 215, 0 }, Shape = "wide", Accessory = "crown",
		Blurb = "King of chicken noodles and meatballs. Bow before the bowl." },
	{ Id = "es-campur", Name = "Dewa Es Campur Pelangi", Rarity = "Legendary", Rate = 250, Cost = 15000,
		Body = { 150, 90, 200 }, Head = { 180, 130, 230 }, Accent = { 255, 120, 200 }, Shape = "tall", Accessory = "cape",
		Blurb = "God of rainbow iced dessert. It melts hearts, never itself." },
	{ Id = "sate-padang", Name = "Sultan Sate Padang", Rarity = "Legendary", Rate = 300, Cost = 18000,
		Body = { 200, 100, 40 }, Head = { 230, 140, 70 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "tophat",
		Blurb = "Sultan of Padang satay. His sauce is a state secret." },
	{ Id = "nasi-goreng", Name = "Kaisar Nasi Goreng", Rarity = "Legendary", Rate = 380, Cost = 23000,
		Body = { 220, 150, 70 }, Head = { 240, 180, 100 }, Accent = { 255, 60, 60 }, Shape = "box", Accessory = "crown",
		Blurb = "Emperor of fried rice. Fried at 3 AM, feared at all hours." },
	{ Id = "rujak", Name = "Ratu Rujak Buah", Rarity = "Legendary", Rate = 450, Cost = 27000,
		Body = { 90, 200, 110 }, Head = { 130, 230, 150 }, Accent = { 255, 90, 90 }, Shape = "tall", Accessory = "crown",
		Blurb = "Queen of fruit salad. Her chili sauce stings like gossip." },
	-- Mythic: the legends.
	{ Id = "naga-indomie", Name = "Naga Indomie Kuah Pedas", Rarity = "Mythic", Rate = 700, Cost = 50000,
		Body = { 230, 60, 40 }, Head = { 255, 90, 60 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "cape",
		Blurb = "A spicy soup noodle dragon. Its breath is extra chili." },
	{ Id = "phoenix-ayam", Name = "Phoenix Ayam Bakar Madu", Rarity = "Mythic", Rate = 900, Cost = 65000,
		Body = { 240, 140, 60 }, Head = { 255, 180, 90 }, Accent = { 255, 120, 40 }, Shape = "wide", Accessory = "cape",
		Blurb = "A honey grilled chicken phoenix. It rebirths before you do." },
	{ Id = "titan-bakso", Name = "Titan Bakso Urat Raksasa", Rarity = "Mythic", Rate = 1200, Cost = 85000,
		Body = { 180, 120, 80 }, Head = { 210, 150, 100 }, Accent = { 90, 160, 255 }, Shape = "round", Accessory = "tophat",
		Blurb = "A giant tendon meatball titan. It bounces. The ground objects." },
	{ Id = "dewi-es-teh", Name = "Dewi Es Teh Jumbo", Rarity = "Mythic", Rate = 1500, Cost = 110000,
		Body = { 200, 120, 60 }, Head = { 230, 170, 90 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "crown",
		Blurb = "Goddess of jumbo iced tea. One sip and your wallet levitates." },
	{ Id = "kura-indomie", Name = "Kura-Kura Indomie Abadi", Rarity = "Mythic", Rate = 1000, Cost = 75000,
		Body = { 120, 180, 100 }, Head = { 160, 210, 140 }, Accent = { 255, 200, 60 }, Shape = "wide", Accessory = "sombrero",
		Blurb = "An eternal noodle turtle. Slow. Rich. Unbothered since 1998." },
	-- Secret: the ones nobody believes exist.
	{ Id = "mie-godzilla", Name = "Mie Godzilla Berapi", Rarity = "Secret", Rate = 3000, Cost = 250000,
		Body = { 220, 60, 40 }, Head = { 250, 90, 60 }, Accent = { 255, 80, 40 }, Shape = "tall", Accessory = "cape",
		Blurb = "A flaming noodle Godzilla. It eats cities. It tips the waiter." },
	{ Id = "kucing-dewa", Name = "Kucing Oren Dewa Semesta", Rarity = "Secret", Rate = 5000, Cost = 400000,
		Body = { 255, 140, 30 }, Head = { 255, 180, 80 }, Accent = { 255, 215, 0 }, Shape = "box", Accessory = "crown",
		Blurb = "The orange cat god of the universe. It knocked your money off the table. On purpose." },
	{ Id = "nasi-padang-abadi", Name = "Nasi Padang Abadi", Rarity = "Secret", Rate = 4000, Cost = 320000,
		Body = { 200, 140, 60 }, Head = { 235, 185, 95 }, Accent = { 255, 215, 0 }, Shape = "wide", Accessory = "tophat",
		Blurb = "Eternal Padang rice. It has been on the table since forever. It will outlive us all." },
	{ Id = "kentongan", Name = "Kentongan Sakti Tengah Malam", Rarity = "Secret", Rate = 6500, Cost = 550000,
		Body = { 140, 90, 50 }, Head = { 180, 120, 70 }, Accent = { 120, 200, 255 }, Shape = "tall", Accessory = "none",
		Blurb = "A magic slit-drum that only sounds at midnight. When it sounds, everyone pays." },
	{ Id = "gong-gede", Name = "Gong Gede Misterius", Rarity = "Secret", Rate = 8000, Cost = 700000,
		Body = { 255, 215, 0 }, Head = { 255, 230, 90 }, Accent = { 200, 40, 40 }, Shape = "round", Accessory = "crown",
		Blurb = "A mysterious giant gong. Strike it and the whole arena gets rich. Or scared." },
}

-- Lookups built once from the table above.
local ById = {}
for _, def in ipairs(BrainrotCatalog.Characters) do
	ById[def.Id] = def
end
local RarityColor = {}
for _, rarity in ipairs(BrainrotCatalog.Rarities) do
	RarityColor[rarity.Name] = rarity.Color
end

function BrainrotCatalog.Get(id)
	return ById[id]
end

function BrainrotCatalog.RarityColor(name)
	return RarityColor[name] or Color3.fromRGB(255, 255, 255)
end

-- Roll a rarity by weight. Returns the rarity name.
function BrainrotCatalog.RollRarity()
	local total = 0
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		total = total + rarity.Weight
	end
	local roll = math.random() * total
	local running = 0
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		running = running + rarity.Weight
		if roll <= running then
			return rarity.Name
		end
	end
	return "Common"
end

-- Roll a mutation by chance. Returns the mutation name.
function BrainrotCatalog.RollMutation()
	local roll = math.random() * 100
	local running = 0
	for _, mutation in ipairs(BrainrotCatalog.Mutations) do
		running = running + mutation.Chance
		if roll <= running then
			return mutation.Name
		end
	end
	return "Normal"
end

-- The $/s multiplier of a mutation.
function BrainrotCatalog.MutationMultiplier(name)
	for _, mutation in ipairs(BrainrotCatalog.Mutations) do
		if mutation.Name == name then
			return mutation.Multiplier
		end
	end
	return 1
end

-- Pick a random character of a given rarity.
function BrainrotCatalog.RandomOfRarity(rarityName)
	local pool = {}
	for _, def in ipairs(BrainrotCatalog.Characters) do
		if def.Rarity == rarityName then
			table.insert(pool, def)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.Characters[1]
	end
	return pool[math.random(1, #pool)]
end

-- The effective $/s of a character with a mutation.
function BrainrotCatalog.EffectiveRate(def, mutation)
	return def.Rate * BrainrotCatalog.MutationMultiplier(mutation)
end

return BrainrotCatalog
