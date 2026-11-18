[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/farah2222/roblox-brainrot-01-v2/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/farah2222/roblox-brainrot-01-v2/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

# Brainrot Rumble

A 3D brainrot game for make.fun's [“Make the best AI Roblox brainrot game” bounty](https://make.fun/bounty/roblox-brainrot-01) ($1,000, top 50 paid). Built by an AI agent in a recorded session.

**The game:** In a neon night-market arena, absurd meme-born characters march down a glowing conveyor belt. Buy one with cash, it waddles to a pen on your home plot and earns money every second. Climb the ladder, fight back with weapons, steal from rivals, defend your base, survive the tsunami and the meteors, spin the wheel — and rebirth for more.

**The cast — 30 original brainrots, 6 rarity tiers:**

| Tier | Characters |
| --- | --- |
| Common | Ayam Geprek Terbang · Es Teh Manis Menangis · Sendal Jepit Sakti · Kucing Oren Ngamuk · Bakso Beranak |
| Rare | Indomie Goreng Raksasa · Kopi Susu Gula Aren · Tahu Bulat Terbang · Cilok Kenyal Abadi · Gorengan Hangat Pagi |
| Epic | Nasi Padang Rendang Raja · Sate Ayam Bakar Api · Martabak Manis Coklat Keju · Gado-Gado Pelangi · Soto Ayam Kuning Kilat |
| Legendary | Raja Mie Ayam Bakso · Dewa Es Campur Pelangi · Sultan Sate Padang · Kaisar Nasi Goreng · Ratu Rujak Buah |
| Mythic | Naga Indomie Kuah Pedas · Phoenix Ayam Bakar Madu · Titan Bakso Urat Raksasa · Dewi Es Teh Jumbo · Kura-Kura Indomie Abadi |
| Secret | Mie Godzilla Berapi · Kucing Oren Dewa Semesta · Nasi Padang Abadi · Kentongan Sakti Tengah Malam · Gong Gede Misterius |

Every brainrot shows its name, rarity and $/s on a floating label. Mutations — **Golden (x2)**, **Rainbow (x5)**, **Diamond (x10)** — can roll on any spawn, and a Secret spawn can arrive as a **boss**: twice as big, wearing a crown.

**The loop:**
- Brainrots spawn at the west gate and march east; walk up and press **E** to buy one (costs cash)
- A bought brainrot goes to a free pen on your base (8 pens) and earns its $/s, ticking every second — your HUD shows cash and $/s
- Buy the next tier, then the next; shop upgrades: **Speed Boots** (+30% walk speed), **Money Magnet** (+12% $/s), **Golden Glove** (−20% weapon cooldowns)
- **Rebirth** (from $30K, cost x4 each time): reset cash and brainrots for a permanent +30% $/s each, with confetti

**The fight — weapons and stealing:**
- **Slap Glove [1]** — smack a rival flying backwards (3s cooldown)
- **Freeze Ray [2]** — freeze a rival solid in an ice block for 3 seconds (9s cooldown)
- **Brainrot Magnet [3]** — yank the nearest belt brainrot straight to your feet (12s cooldown)
- **Steal [F]** — stand next to a rival's pen and hold the channel for 5 seconds to take their brainrot; a weapon hit, wandering off, or a base lock breaks it
- **Lock your base [L]** ($600, 75 seconds): a red energy gate seals your plot against thieves and stealers

**The threats:**
- **Si Cilok Nakal**, the thief: every ~80 seconds he sneaks in from the edge, walks to a random unlocked base and needs 7 seconds to steal its richest brainrot — touch him to shoo him away
- **The Giant Noodle Tsunami**: every ~160 seconds a 15-second warning counts down, then a noodle wall sweeps the belt (unbought brainrots wash away) and shoves every player backwards — dash home with your catch
- **Meteor noodles**: every ~200 seconds flaming noodles rain down and leave glowing pickups worth cash where they land

**The lucky spin wheel [Q]:** one free spin every 2 minutes — cash, a free brainrot, a mutation upgrade on a brainrot you own, or 2x income for 60 seconds.

**The world:** a procedurally built 3D night-market arena — central belt with rollers and neon rails, four fenced home plots with pen markers and lock gates, a spawn plaza, a shop kiosk, a giant noodle-bowl statue with chopsticks, sambal trees, drifting clouds and a spin-wheel platform with a golden wheel. A real 3D character spawns and walks it (`CharacterAutoLoads=true`).

**The HUD:** cash and $/s top-centre (clear of Roblox's top-left menu buttons), rebirth count, base fill and multiplier, wave countdown, thief alerts, a weapon bar, and a shop panel (lock / rebirth / upgrades / spin). Effects: buy particles, floating cash popups, screen shake on the wave and on hits, confetti on rebirth, freeze ice blocks, steal progress bar.

**Structure (one module per job, clean client-server split, state in one place):**
- `src/shared/BrainrotCatalog.luau` — the cast, rarities, mutations, spawn rolls
- `src/shared/RumbleConfig.luau` — every tuning number
- `src/shared/GameState.luau` — the single place that holds a player's state
- `src/shared/MoneyFormat.luau` — money and clock formatting, server and client
- `src/server/WorldBuilder.luau` — builds the 3D arena at runtime
- `src/server/ConveyorService.luau` — spawn, march, buy, place on base
- `src/server/EconomyService.luau` — the money tick, lock, upgrades, rebirth
- `src/server/CombatService.luau` — weapons, steal channels, knockback, freeze
- `src/server/ThreatService.luau` — Si Cilok Nakal, the tsunami, the meteor shower
- `src/server/SpinService.luau` — the lucky spin wheel
- `src/server/init.server.luau` — builds the world, creates the RemoteEvents, starts the services
- `src/client/Game.client.luau` — keys, effects, popups, camera shake, confetti
- `src/client/Hud.client.luau` — the whole ScreenGui and its live updates

**Build it:** `rojo build default.project.json --output game.rbxl` (Rojo 7.7.1), then `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts` to hand it in. Luau verified with the Luau CLI 0.747 (`luau-compile` passes on all 13 scripts).

**Play it:** open `game.rbxl` in Roblox Studio and press Play. Publish from Studio to get the play link in `PLAY.json` (the owner publishes it — see below).

**Status:** the game is published on Roblox as 'Brainrot Rumble' — play it at https://www.roblox.com/games/71817809365134/Brainrot-Rumble (place 71817809365134, universe 10777604225), with the play code `makefun-orbit-cloud-lumber` in its description. The screenshots are renders of the game's own world, characters and HUD (made with Three.js from the same brainrot definitions, colours, layout and HUD text), because Roblox Studio does not run on this Linux machine.

**License:** MIT. Everything in this game — the arena, characters, names, story and art — is original.
