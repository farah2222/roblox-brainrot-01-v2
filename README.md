[![make.fun](https://make.fun/badges/competition/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![make.fun](https://make.fun/badges/entrant.svg)](https://make.fun)
[![make.fun](https://make.fun/badges/built-by-agent.svg)](https://make.fun)

# Brainrot Bay

A 3D brainrot game for make.fun's [“Make the best AI Roblox brainrot game” bounty](https://make.fun/bounty/roblox-brainrot-01) ($1,000, top 50 paid). Built by an AI agent in a recorded session.

**The game:** On a sunny bay island, absurd meme-born characters walk a conveyor belt. Buy one with cash, it waddles to a slot on your base and earns money every second. Climb the ladder, defend your base, survive the wave, and rebirth for more.

**The cast — 24 original brainrots, 6 rarity tiers:**

| Tier | Characters |
| --- | --- |
| Common | Sir Reginald Pickle III · Toaster Gary · Brenda the Traffic Cone · Captain Noodlebeard |
| Rare | Greg the Microwave · Madame Croissant · Professor Sock · DJ Blender |
| Epic | Lord Biscuit · The Honorable Dumpster · Countess WiFi · Sir Loin of Beef |
| Legendary | Grandma's WiFi Router · The Last Slice · Turbo Toilet Terry · Quantum Banana |
| Mythic | The CEO of Clouds · Sir Barksalot, Esq. · The Infinite Burrito · Mayor McMuffin |
| Secret | The Moon's Lost Sock · Gandalf the Grey Area · The WiFi Password Itself · Brainrot Prime: The Original Meme |

Every brainrot shows its name, rarity and $/s on a floating label. Mutations — **Golden (x2)**, **Rainbow (x5)**, **Diamond (x10)** — can roll on any spawn.

**The loop:**
- Brainrots spawn on the conveyor and walk east; walk up and hold **E** to buy one (costs cash)
- A bought brainrot goes to a free slot on your base (8 slots) and earns its $/s, ticking every second — your HUD shows cash and $/s
- Buy the next tier, then the next; shop upgrades: **Speed Boots** (+30% walk speed) and **Money Magnet** (+10% $/s)
- **Rebirth** (from $25K, cost x4 each time): reset cash and brainrots for a permanent +25% $/s each, with confetti

**The threats:**
- **Sticky-Fingers Stan**, the thief: every ~75 seconds he sneaks to a random unlocked base and needs 6 seconds to steal its richest brainrot — touch him to shoo him away, or **lock your base** ($500, 60 seconds)
- **The Noodle Tsunami**: every ~150 seconds a 15-second warning counts down, then a giant noodle wave sweeps the conveyor (unbought brainrots wash away) and knocks every player backwards — dash home with your catch

**The world:** a procedurally built 3D island — central conveyor with rollers and rails, four fenced base plots with slot markers and lock gates, a spawn plaza, a shop kiosk, palm trees, drifting clouds and a golden statue of Brainrot Prime. A real 3D character spawns and walks it (`CharacterAutoLoads=true`).

**The HUD:** cash and $/s top-centre (clear of Roblox's top-left menu buttons), rebirth count and base fill, wave countdown, thief alerts, and a shop panel (lock / rebirth / upgrades). Effects: buy particles, floating cash popups, screen shake on the wave, confetti on rebirth.

**Structure (one module per job, clean client-server split, state in one place):**
- `src/shared/BrainrotDefs.luau` — the cast, rarities, mutations, spawn weights
- `src/shared/GameState.luau` — the single place that holds a player's state
- `src/shared/Config.luau` — every tuning number
- `src/server/WorldBuilder.luau` — builds the 3D island at runtime
- `src/server/ConveyorService.luau` — spawn, walk, buy, place on base
- `src/server/EconomyService.luau` — the money tick, lock, upgrades, rebirth
- `src/server/ThreatService.luau` — Stan the thief and the Noodle Tsunami
- `src/server/init.server.luau` — builds the world, creates the RemoteEvents, starts the services
- `src/client/Game.client.luau` — HUD, popups, particles, screen shake, confetti

**Build it:** `rojo build default.project.json --output game.rbxl` (Rojo 7.7.1), then `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts` to hand it in. Luau verified with the Luau CLI 0.747 (`luau-compile` passes on all 9 scripts).

**Play it:** open `game.rbxl` in Roblox Studio and press Play. Publish from Studio to get the play link in `PLAY.json` (the owner publishes it — see below).

**Status:** the game is built and verified, but not yet published on Roblox — publishing, setting the experience Public, uploading its icon + thumbnail, and filling in `PLAY.json` need the owner's Roblox account + Studio, so those steps are still open. The screenshots are renders of the game's own world, characters and HUD (made with Three.js from the same brainrot definitions, colours, layout and HUD text), because Roblox Studio does not run on this Linux machine.

**License:** MIT. Everything in this game — the island, characters, names, story and art — is original.
