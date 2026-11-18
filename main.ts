// Brainrot Rumble — a roblox-brainrot-01 entry (Node 22, standard library only):
// a 3D brainrot game built by an AI agent in a recorded session. The game is
// this directory's Rojo project, built into game.rbxl with
// `rojo build default.project.json --output game.rbxl`, and this program
// hands it in. It copies game.rbxl, src/, screenshots/ and PLAY.json from
// beside this file to /output and writes /output/dossier.json, the summary
// the judge reads, with the vendored make.fun library.
//
// The game: 30 original absurd brainrots (Ayam Geprek Terbang, Kucing Oren
// Ngamuk, Naga Indomie Kuah Pedas, Mie Godzilla Berapi, ...) march down a
// glowing belt in a neon night-market arena. Buy one with cash, it waddles
// to a pen on your base and earns $/s; climb 6 rarity tiers, roll
// Golden/Rainbow/Diamond mutations, fight with a slap glove, a freeze ray
// and a brainrot magnet, steal from rivals, lock your base against
// Si Cilok Nakal, survive the giant noodle tsunami and the meteor shower,
// spin the lucky wheel, and rebirth for a permanent +30% $/s. The 3D arena
// (belt, home plots, kiosk, noodle-bowl statue, sambal trees, spin wheel)
// is built procedurally by src/server/WorldBuilder.luau; the loop lives in
// ConveyorService, EconomyService, CombatService, ThreatService and
// SpinService, with all state in one place (src/shared/GameState.luau)
// and the cast in src/shared/BrainrotCatalog.luau. screenshots/ holds four
// renders of the game's own world and characters (the first by name is the
// cover and the game's Roblox thumbnail); PLAY.json names the published
// place once its owner publishes it from Roblox Studio.
//
// Every name under /output starts with a letter, a digit or _ and holds only
// letters, digits, . _ and -: the grader fails an entry whose output holds
// any other, so a file such as .gitkeep or .DS_Store copied in fails it.
// So src/ and screenshots/ are copied without any name that starts with a
// dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Skip every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const skipDotted = (path: string): boolean => !basename(path).startsWith('.');

function handIn() {
  copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
  copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
  cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: skipDotted });
  mkdirSync(join(out, 'screenshots'), { recursive: true });
  if (existsSync(join(here, 'screenshots'))) {
    cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: skipDotted });
  }
  // The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes;
  // the others refuse an entry the scorer would refuse (more than 4 screenshots or one
  // over 256 KiB; a place of more than 500000 instances, whose scripts' sources come to
  // over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
  writeFileSync(
    join(out, 'dossier.json'),
    buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
  );
}

handIn();
