-- Brainrot Rumble: the cast. Forty original absurd characters, five per
-- rarity tier (plus five more across the tiers and a seventh Divine tier), each with a name, a money-per-second rate, a price, colours,
-- a body shape and an accessory. Nothing here is copied from any other
-- brainrot game: every one of these was invented for this arena, most of
-- them out of Indonesian street food that refused to stay on the plate.

local BrainrotCatalog = {}

-- Rarity ladder, cheapest first. Weight is the share of spawns.
BrainrotCatalog.Rarities = {
	{ Name = "Common", Weight = 44.5, Color = Color3.fromRGB(150, 200, 120) },
	{ Name = "Rare", Weight = 28, Color = Color3.fromRGB(90, 160, 255) },
	{ Name = "Epic", Weight = 15, Color = Color3.fromRGB(190, 110, 255) },
	{ Name = "Legendary", Weight = 8, Color = Color3.fromRGB(255, 200, 60) },
	{ Name = "Mythic", Weight = 3, Color = Color3.fromRGB(255, 90, 110) },
	{ Name = "Secret", Weight = 1, Color = Color3.fromRGB(40, 40, 45) },
	{ Name = "Divine", Weight = 0.5, Color = Color3.fromRGB(255, 240, 190) },
}

-- Mutations that can roll on any spawn. Multiplier applies to $/s.
BrainrotCatalog.Mutations = {
	{ Name = "Normal", Multiplier = 1, Chance = 87.9 },
	{ Name = "Golden", Multiplier = 2, Chance = 8 },
	{ Name = "Lava", Multiplier = 4, Chance = 1.2 },
	{ Name = "Rainbow", Multiplier = 5, Chance = 2 },
	{ Name = "Diamond", Multiplier = 10, Chance = 0.6 },
	{ Name = "Glitch", Multiplier = 12, Chance = 0.3 },
}

-- One entry per character. Colours are 0-255 RGB triples.
-- Shape: "box", "tall", "wide" or "round". Accessory: "tophat", "crown",
-- "sunglasses", "chefhat", "cape", "sombrero" or "none".
BrainrotCatalog.Characters = {
	-- Common: the everyday absurd.
	{ Id = "ayam-geprek", Name = "Ayam Geprek Terbang", Rarity = "Common", Rate = 2, Cost = 60,
		Body = { 235, 180, 90 }, Head = { 250, 210, 120 }, Accent = { 200, 40, 40 }, Shape = "tall", Accessory = "chefhat",
		Blurb = "A smashed fried chicken that learned to fly and never landed.",
		Quote = "I can fly! I just... choose to waddle." },
	{ Id = "es-teh", Name = "Es Teh Manis Menangis", Rarity = "Common", Rate = 3, Cost = 90,
		Body = { 200, 120, 60 }, Head = { 230, 170, 90 }, Accent = { 90, 160, 255 }, Shape = "tall", Accessory = "none",
		Blurb = "Sweet iced tea, crying, because someone drank its best friend.",
		Quote = "I am not crying, you are crying. Sweetly." },
	{ Id = "sendal", Name = "Sendal Jepit Sakti", Rarity = "Common", Rate = 1, Cost = 30,
		Body = { 60, 120, 220 }, Head = { 90, 160, 250 }, Accent = { 255, 220, 60 }, Shape = "wide", Accessory = "none",
		Blurb = "One magic flip-flop. The other one is still missing.",
		Quote = "One flip-flop to rule them all." },
	{ Id = "kucing-oren", Name = "Kucing Oren Ngamuk", Rarity = "Common", Rate = 5, Cost = 150,
		Body = { 255, 140, 30 }, Head = { 255, 170, 60 }, Accent = { 30, 30, 30 }, Shape = "box", Accessory = "none",
		Blurb = "An orange cat. Angry. About everything. Especially Mondays.",
		Quote = "Meow means no. In every language." },
	{ Id = "bakso-beranak", Name = "Bakso Beranak", Rarity = "Common", Rate = 8, Cost = 300,
		Body = { 180, 120, 80 }, Head = { 210, 150, 100 }, Accent = { 120, 200, 90 }, Shape = "round", Accessory = "none",
		Blurb = "A meatball that had a baby meatball. The baby charges rent.",
		Quote = "I brought my baby to work. It charges rent." }, -- r8: was $240 — the clear best Common, every early player bought it first and ignored the rest of the tier; $300 keeps the tier a real choice
	-- Rare: the street-food regulars.
	{ Id = "indomie-goreng", Name = "Indomie Goreng Raksasa", Rarity = "Rare", Rate = 15, Cost = 600,
		Body = { 240, 210, 130 }, Head = { 250, 230, 160 }, Accent = { 200, 40, 40 }, Shape = "wide", Accessory = "chefhat",
		Blurb = "A giant plate of fried noodles. It seasoned itself.",
		Quote = "Two minutes to cook. Forever to forget." },
	{ Id = "kopi-susu", Name = "Kopi Susu Gula Aren", Rarity = "Rare", Rate = 12, Cost = 500,
		Body = { 120, 80, 50 }, Head = { 160, 110, 70 }, Accent = { 240, 200, 150 }, Shape = "tall", Accessory = "none",
		Blurb = "Palm-sugar milk coffee. Too sweet to fight, too strong to sleep.",
		Quote = "I am 10% coffee, 90% sugar rush." },
	{ Id = "tahu-bulat", Name = "Tahu Bulat Terbang", Rarity = "Rare", Rate = 18, Cost = 750,
		Body = { 240, 220, 180 }, Head = { 250, 235, 200 }, Accent = { 255, 200, 60 }, Shape = "round", Accessory = "sombrero",
		Blurb = "Round tofu, fried on a moving truck, now flying solo.",
		Quote = "Fried on a truck, flying ever since." },
	{ Id = "cilok", Name = "Cilok Kenyal Abadi", Rarity = "Rare", Rate = 22, Cost = 900,
		Body = { 220, 180, 140 }, Head = { 240, 205, 165 }, Accent = { 220, 60, 60 }, Shape = "round", Accessory = "none",
		Blurb = "Chewy forever. Dentists fear it. Children worship it.",
		Quote = "Chew me once, shame on you. Chew me twice..." },
	{ Id = "gorengan", Name = "Gorengan Hangat Pagi", Rarity = "Rare", Rate = 30, Cost = 1200,
		Body = { 230, 170, 80 }, Head = { 245, 200, 110 }, Accent = { 255, 120, 40 }, Shape = "box", Accessory = "tophat",
		Blurb = "Warm morning fritters in a top hat. Still warm. Always warm.",
		Quote = "Still warm. Always warm. Never cold." },
	-- Epic: the full meals.
	{ Id = "nasi-padang", Name = "Nasi Padang Rendang Raja", Rarity = "Epic", Rate = 50, Cost = 2500,
		Body = { 200, 140, 60 }, Head = { 230, 180, 90 }, Accent = { 255, 215, 0 }, Shape = "wide", Accessory = "crown",
		Blurb = "King of rendang rice. Its gravy has its own gravy.",
		Quote = "My gravy has its own gravy." },
	{ Id = "sate-ayam", Name = "Sate Ayam Bakar Api", Rarity = "Epic", Rate = 65, Cost = 3200,
		Body = { 190, 90, 50 }, Head = { 220, 120, 70 }, Accent = { 255, 120, 30 }, Shape = "tall", Accessory = "cape",
		Blurb = "Fire-grilled satay. The skewer is its sword.",
		Quote = "The skewer is my sword. The peanut sauce is my shield." },
	{ Id = "martabak", Name = "Martabak Manis Coklat Keju", Rarity = "Epic", Rate = 80, Cost = 4000,
		Body = { 220, 180, 90 }, Head = { 240, 205, 120 }, Accent = { 120, 80, 200 }, Shape = "wide", Accessory = "crown",
		Blurb = "Sweet martabak, half chocolate, half cheese, all chaos.",
		Quote = "Half chocolate, half cheese, all chaos." },
	{ Id = "gado-gado", Name = "Gado-Gado Pelangi", Rarity = "Epic", Rate = 95, Cost = 4800,
		Body = { 120, 200, 120 }, Head = { 160, 230, 160 }, Accent = { 255, 90, 160 }, Shape = "box", Accessory = "sombrero",
		Blurb = "Rainbow salad with peanut sauce. It contains multitudes.",
		Quote = "I contain multitudes. And peanut sauce." },
	{ Id = "soto-ayam", Name = "Soto Ayam Kuning Kilat", Rarity = "Epic", Rate = 120, Cost = 6000,
		Body = { 250, 200, 60 }, Head = { 255, 220, 100 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "none",
		Blurb = "Lightning-yellow chicken soup. It arrived before you ordered.",
		Quote = "I arrived before you ordered. That is fast." },
	-- Legendary: the royalty of the food court.
	{ Id = "mie-ayam", Name = "Raja Mie Ayam Bakso", Rarity = "Legendary", Rate = 200, Cost = 12000,
		Body = { 240, 210, 130 }, Head = { 250, 230, 160 }, Accent = { 255, 215, 0 }, Shape = "wide", Accessory = "crown",
		Blurb = "King of chicken noodles and meatballs. Bow before the bowl.",
		Quote = "Bow before the bowl." },
	{ Id = "es-campur", Name = "Dewa Es Campur Pelangi", Rarity = "Legendary", Rate = 250, Cost = 15000,
		Body = { 150, 90, 200 }, Head = { 180, 130, 230 }, Accent = { 255, 120, 200 }, Shape = "tall", Accessory = "cape",
		Blurb = "God of rainbow iced dessert. It melts hearts, never itself.",
		Quote = "I melt hearts. Never myself." },
	{ Id = "sate-padang", Name = "Sultan Sate Padang", Rarity = "Legendary", Rate = 300, Cost = 18000,
		Body = { 200, 100, 40 }, Head = { 230, 140, 70 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "tophat",
		Blurb = "Sultan of Padang satay. His sauce is a state secret.",
		Quote = "My sauce recipe is a state secret." },
	{ Id = "nasi-goreng", Name = "Kaisar Nasi Goreng", Rarity = "Legendary", Rate = 380, Cost = 23000,
		Body = { 220, 150, 70 }, Head = { 240, 180, 100 }, Accent = { 255, 60, 60 }, Shape = "box", Accessory = "crown",
		Blurb = "Emperor of fried rice. Fried at 3 AM, feared at all hours.",
		Quote = "Fried at 3 AM. Feared at all hours." },
	{ Id = "rujak", Name = "Ratu Rujak Buah", Rarity = "Legendary", Rate = 450, Cost = 27000,
		Body = { 90, 200, 110 }, Head = { 130, 230, 150 }, Accent = { 255, 90, 90 }, Shape = "tall", Accessory = "crown",
		Blurb = "Queen of fruit salad. Her chili sauce stings like gossip.",
		Quote = "My chili sauce stings like gossip." },
	-- Mythic: the legends.
	{ Id = "naga-indomie", Name = "Naga Indomie Kuah Pedas", Rarity = "Mythic", Rate = 700, Cost = 50000,
		Body = { 230, 60, 40 }, Head = { 255, 90, 60 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "cape",
		Blurb = "A spicy soup noodle dragon. Its breath is extra chili.",
		Quote = "My breath is extra chili. You are welcome." },
	{ Id = "phoenix-ayam", Name = "Phoenix Ayam Bakar Madu", Rarity = "Mythic", Rate = 900, Cost = 65000,
		Body = { 240, 140, 60 }, Head = { 255, 180, 90 }, Accent = { 255, 120, 40 }, Shape = "wide", Accessory = "cape",
		Blurb = "A honey grilled chicken phoenix. It rebirths before you do.",
		Quote = "I rebirth before you do. Every time." },
	{ Id = "titan-bakso", Name = "Titan Bakso Urat Raksasa", Rarity = "Mythic", Rate = 1200, Cost = 85000,
		Body = { 180, 120, 80 }, Head = { 210, 150, 100 }, Accent = { 90, 160, 255 }, Shape = "round", Accessory = "tophat",
		Blurb = "A giant tendon meatball titan. It bounces. The ground objects.",
		Quote = "I bounce. The ground objects." },
	{ Id = "dewi-es-teh", Name = "Dewi Es Teh Jumbo", Rarity = "Mythic", Rate = 1500, Cost = 110000,
		Body = { 200, 120, 60 }, Head = { 230, 170, 90 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "crown",
		Blurb = "Goddess of jumbo iced tea. One sip and your wallet levitates.",
		Quote = "One sip and your wallet levitates." },
	{ Id = "kura-indomie", Name = "Kura-Kura Indomie Abadi", Rarity = "Mythic", Rate = 1000, Cost = 75000,
		Body = { 120, 180, 100 }, Head = { 160, 210, 140 }, Accent = { 255, 200, 60 }, Shape = "wide", Accessory = "sombrero",
		Blurb = "An eternal noodle turtle. Slow. Rich. Unbothered since 1998.",
		Quote = "Slow. Rich. Unbothered since 1998." },
	-- Secret: the ones nobody believes exist.
	{ Id = "mie-godzilla", Name = "Mie Godzilla Berapi", Rarity = "Secret", Rate = 3000, Cost = 250000,
		Body = { 220, 60, 40 }, Head = { 250, 90, 60 }, Accent = { 255, 80, 40 }, Shape = "tall", Accessory = "cape",
		Blurb = "A flaming noodle Godzilla. It eats cities. It tips the waiter.",
		Quote = "I eat cities. I tip the waiter." },
	{ Id = "kucing-dewa", Name = "Kucing Oren Dewa Semesta", Rarity = "Secret", Rate = 5000, Cost = 400000,
		Body = { 255, 140, 30 }, Head = { 255, 180, 80 }, Accent = { 255, 215, 0 }, Shape = "box", Accessory = "crown",
		Blurb = "The orange cat god of the universe. It knocked your money off the table. On purpose.",
		Quote = "I knocked your money off the table. On purpose." },
	{ Id = "nasi-padang-abadi", Name = "Nasi Padang Abadi", Rarity = "Secret", Rate = 4000, Cost = 320000,
		Body = { 200, 140, 60 }, Head = { 235, 185, 95 }, Accent = { 255, 215, 0 }, Shape = "wide", Accessory = "tophat",
		Blurb = "Eternal Padang rice. It has been on the table since forever. It will outlive us all.",
		Quote = "I have been on the table since forever." },
	{ Id = "kentongan", Name = "Kentongan Sakti Tengah Malam", Rarity = "Secret", Rate = 6500, Cost = 550000,
		Body = { 140, 90, 50 }, Head = { 180, 120, 70 }, Accent = { 120, 200, 255 }, Shape = "tall", Accessory = "none",
		Blurb = "A magic slit-drum that only sounds at midnight. When it sounds, everyone pays.",
		Quote = "When I sound at midnight, everyone pays." },
	{ Id = "gong-gede", Name = "Gong Gede Misterius", Rarity = "Secret", Rate = 9000, Cost = 600000,
		Body = { 255, 215, 0 }, Head = { 255, 230, 90 }, Accent = { 200, 40, 40 }, Shape = "round", Accessory = "crown",
		Blurb = "A mysterious giant gong. Strike it and the whole arena gets rich. Or scared.",
		Quote = "Strike me and the arena gets rich. Or scared." }, -- r8: was $700K / 8,000/s — the slowest payback in the game, stalling the climb right before Divine; $600K / 9,000/s keeps the top of the ladder moving
	-- One more per tier, plus the seventh tier: Divine.
	{ Id = "krupuk", Name = "Krupuk Pecah Berisik", Rarity = "Common", Rate = 4, Cost = 120,
		Body = { 240, 200, 140 }, Head = { 250, 220, 170 }, Accent = { 255, 60, 60 }, Shape = "box", Accessory = "none",
		Blurb = "A cracked cracker that never stops crunching. It crunches in its sleep.",
		Quote = "KRUPUK! KRUPUK! Did you hear that? That was me." },
	{ Id = "es-cendol", Name = "Es Cendol Segar", Rarity = "Rare", Rate = 26, Cost = 1000,
		Body = { 120, 200, 120 }, Head = { 160, 230, 160 }, Accent = { 255, 255, 255 }, Shape = "tall", Accessory = "none",
		Blurb = "Fresh cendol, green and cool, judging your life choices.",
		Quote = "I am 90% coconut milk and 10% judgment." },
	{ Id = "ayam-penyet", Name = "Ayam Penyet Sambal", Rarity = "Epic", Rate = 110, Cost = 5500,
		Body = { 200, 120, 60 }, Head = { 230, 160, 90 }, Accent = { 255, 60, 40 }, Shape = "wide", Accessory = "cape",
		Blurb = "Smashed chicken drowned in sambal. It fights back.",
		Quote = "The sambal chose me. I did not choose the sambal." },
	{ Id = "bubur-ayam", Name = "Sultan Bubur Ayam", Rarity = "Legendary", Rate = 420, Cost = 25000,
		Body = { 240, 220, 180 }, Head = { 250, 235, 200 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "tophat",
		Blurb = "Sultan of chicken porridge. His crackers are solid gold.",
		Quote = "Porridge is a lifestyle, not a breakfast." },
	{ Id = "sate-taichan", Name = "Phoenix Sate Taichan", Rarity = "Mythic", Rate = 1300, Cost = 95000,
		Body = { 240, 180, 80 }, Head = { 255, 200, 110 }, Accent = { 255, 120, 40 }, Shape = "wide", Accessory = "cape",
		Blurb = "A taichan satay phoenix, grilled without sauce, reborn in chili.",
		Quote = "No peanut sauce. No mercy. Just fire." },
	-- Divine: the five gods of the food court.
	{ Id = "nasi-uduk", Name = "Dewa Nasi Uduk", Rarity = "Divine", Rate = 12000, Cost = 750000,
		Body = { 240, 230, 200 }, Head = { 250, 240, 220 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "crown",
		Blurb = "God of coconut rice. Every grain is a blessing.",
		Quote = "I am the rice. The rice is me. Bow." }, -- r8: was $900K / 10,000/s — the first Divine sat behind a wall most of a session could not reach; $750K / 12,000/s makes the endgame reachable in one good run without trivialising it
	{ Id = "gudeg", Name = "Kaisar Gudeg Jogja", Rarity = "Divine", Rate = 12000, Cost = 1100000,
		Body = { 120, 80, 50 }, Head = { 160, 110, 70 }, Accent = { 255, 215, 0 }, Shape = "wide", Accessory = "crown",
		Blurb = "Emperor of Yogyakarta gudeg. Sweet, slow, unstoppable.",
		Quote = "I took 24 hours to cook. Worth every second." },
	{ Id = "es-doger", Name = "Ratu Es Doger", Rarity = "Divine", Rate = 14000, Cost = 1300000,
		Body = { 255, 150, 200 }, Head = { 255, 180, 220 }, Accent = { 255, 255, 255 }, Shape = "tall", Accessory = "cape",
		Blurb = "Queen of es doger. Pink, cold, and absolutely royal.",
		Quote = "Pink is not a color. It is a rank." },
	{ Id = "soto-betawi", Name = "Naga Soto Betawi", Rarity = "Divine", Rate = 16000, Cost = 1500000,
		Body = { 240, 200, 120 }, Head = { 250, 220, 150 }, Accent = { 255, 215, 0 }, Shape = "tall", Accessory = "cape",
		Blurb = "A Betawi soto dragon, swimming in coconut milk.",
		Quote = "My soup could end wars. Or start them." },
	{ Id = "rendang", Name = "Titan Rendang Sapi", Rarity = "Divine", Rate = 20000, Cost = 2000000,
		Body = { 120, 60, 40 }, Head = { 160, 90, 60 }, Accent = { 255, 215, 0 }, Shape = "round", Accessory = "crown",
		Blurb = "A rendang beef titan. The world's best food, now the world's biggest.",
		Quote = "I am the #1 food on Earth. Google it." },
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
-- rerolls (default 1) rolls that many times and keeps the best multiplier:
-- Golden Hour calls this with 4, so rare mutations show up far more often.
function BrainrotCatalog.RollMutation(rerolls)
	local tries = rerolls or 1
	local best = "Normal"
	local bestMult = 1
	for _ = 1, tries do
		local roll = math.random() * 100
		local running = 0
		for _, mutation in ipairs(BrainrotCatalog.Mutations) do
			running = running + mutation.Chance
			if roll <= running then
				if mutation.Multiplier > bestMult then
					best = mutation.Name
					bestMult = mutation.Multiplier
				end
				break
			end
		end
	end
	return best
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
