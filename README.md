# GPO Field Kit for Potassium

A standalone client script. No Studio installation, developer account, allowlist, or server component is required. Studio was used to inspect the supplied GPO Game HUB copy and test fixtures. This repository contains the original panel code, not the copied game scripts.

## Execute

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Zytrm/gpo-potassium-panel/main/bootstrap.luau"))()
```

Run once after joining the experience. Re-running unloads the previous instance. The bootstrap resolves the latest `main` commit when Potassium's `request` API is available, then loads that revision. `main.luau` is self-contained.

The implementation uses Roblox APIs plus Potassium's `game:HttpGet`, `loadstring`, `getgenv`, and optional filesystem functions. It does not require Drawing, function hooks, hidden-property APIs, or custom HTTP libraries. Actual injection in Potassium has **not** been tested from this environment; compatibility is based on the API surface used by the existing Anime Mine Potassium script.

## Controls

| Control | Behavior |
| --- | --- |
| F6 | Toggle forward motion, initially 30 studs/second. |
| F7 | Anchor/release your character at its current position. |
| Right Shift | Show/hide the panel while keeping enabled overlays active. |
| Header | Drag the panel. `–` collapses it; `×` unloads and restores modified properties. |
| Settings | Reassign keys, save, inspect the latest medal event, or unload. |

All toggles start off on a fresh configuration. Safe display preferences and swim preference restore on subsequent runs. Forward movement, Anchor, and stat application always require fresh activation.

### ESP

- Legendary and mythic chest categories use exact item identities verified in `ToolDesc` / `FruitChestOdds`, excluding blueprints, inventory items, held items, and opening effects. Labels show distance. **Live spawned chest-model classification is unverified**: there were no chest objects in the supplied copy. `LuckyChestV1`/`LuckyChestV2` are deliberately not assigned a rarity because no authoritative mapping was available.
- **Black Leg medals**, **all fighting-style medals and spawn beams**, and **other medallions** have independent controls. The script listens to the observed `matchEvents` actions `spawnfs` and `spawnMedal`, following the pickup instance supplied by the game. Black Leg is recognized from an explicit `BlackLeg` identity in the pickup name, string metadata, or prompt text. Unidentified styles remain generic; beam colors are not guessed.
- Existing `Workspace.Effects.medalPiller` models with the observed two-cylinder structure are labeled as temporary fighting-style **spawn beams**, rather than as confirmed uncollected pickups. The game's effect lasts 21 seconds. An event-tracked pickup stays marked until it leaves Workspace. The distinction prevents the disappearing visual effect from being presented as the full pickup lifetime.
- Trainer ESP is separate and uses exact identities from the game's dialogue modules. Yome appears here as a trainer; he is not the Black Leg medal.
- One initial scan plus descendant events maintains the registry. A shared update runs about 6 times/second, limits visible labels, prioritizes nearby objects, and suppresses overlapping marker labels.
- A client script cannot detect objects that have never replicated or streamed in. Spawn events received after loading can provide an instance; missing instance payloads are recorded in Settings. Historical unseen pickup locations cannot be recovered. No forced map streaming or server registry is claimed.

### Movement and players

- Forward motion has a numeric field, slider, character/camera direction, and a keybind. It is horizontal, frame-rate independent, limited to 1–150 studs/second, and uses a blocking shape cast. Long frame stalls are capped to prevent a large jump. It adds displacement independently of WalkSpeed.
- Anchor saves/restores the root's original Anchored state and the Humanoid's AutoRotate state. Anchor and forward motion turn each other off. Death, character replacement, teleport, unloading, and GUI destruction stop disruptive motion.
- Native Roblox swimming receives 10% over the current WalkSpeed baseline while in the native Swimming state. It does not compound and respects external baseline changes. **GPO's custom `_G.swimming` movement controller is missing from the supplied copy.** If only that custom state is active, the panel explicitly reports that no boost was applied.
- Health and fruit overlays toggle independently. Health follows Humanoid changes; fruit reads the verified `ReplicatedStorage.Stats<player>.Stats.DF` field. Missing data shows `Unknown`, an empty known field shows `None`. Player/character events recreate labels, and only the nearest 20 eligible overlays are displayed.

### Stat profiles

Create, edit, rename, duplicate, capture current allocations, and delete up to 24 named profiles. Fields follow the game's `Leveling.statValues` catalogue, including legacy style stat names when present. Only numeric fields actually replicated for the current character participate in application. Nonzero targets for missing fields are rejected.

Preview shows current/target values, available/allocated/required points, and reset cost. Applying uses the same calls observed in the Statistics UI:

```lua
ReplicatedStorage.Events.stats:FireServer(statName, nil, amount)
ReplicatedStorage.Events.stats:FireServer("BattleRoyaleSPReset")
```

The second call requires a confirmed **1 SP Reset Essence** cost. The panel reads the inventory format used by the game's `GameUtils`, asks for confirmation, requests one reset, waits for replicated zeroed allocations/restored point totals, and then applies each allocation once. It never prompts a Robux purchase or writes stat values locally.

Each request waits for exact replicated stat and unspent-point confirmation. Changed previews, insufficient totals, missing data, rejection/timeouts, and character changes stop the operation. Partial confirmed allocations remain applied; there is no retry or invented rollback. The live server decides additional stat caps, stun restrictions, and other eligibility. Those server handlers are absent from the supplied client copy, so their rules cannot be fully reconstructed or certified here.

### Settings

Settings and profiles save automatically to `GPOFieldKit/config-<game-id>-<user-id>.json` in Potassium's workspace. If file APIs are unavailable, the panel works for the current session and reports the limitation. Invalid saved values are sanitized. Key conflicts are rejected and hotkeys ignore focused text boxes.

## Validation

- Luau 0.740: main, bootstrap, and test scripts compile.
- **21 pure Luau tests pass**: numerical validation, total point conservation, reset planning, saved settings, conflicting bindings, exact identity matching, and movement at 15/30/60/144/240 FPS.
- **39 Roblox Studio client fixture checks pass**: startup, all tabs, collapse/expand, motion, wall collision, midair Anchor, cleanup, chest/trainer/medal lifecycle, unknown-style handling, stat preview, sequential allocation, reset essence consumption, native swim baseline changes/nonstacking/restoration, death and unload.
- UI preview inspected visually; `manage_ui.check` reports zero findings.

The stat test server is a deliberately simple test double using the observed remote protocol, **not the real GPO server**. Actual live chest spawns, medal metadata, multiplayer health/fruit changes, custom swimming, teleporting, filesystem access in Potassium, and live stat acceptance remain to be verified in-game. Fixture reports are in [docs](docs/).

## Source and rebuilding

Edit `src/Core.luau`, `src/UI.luau`, or `src/Runtime.luau`, then run `./build.ps1` to regenerate `main.luau`. Tests are in `tests/`; only `main.luau` and `bootstrap.luau` are needed to execute.

See [hitbox feasibility](docs/hitbox-feasibility.md) for the requested reach investigation.
