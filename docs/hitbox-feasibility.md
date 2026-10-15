# Increased hit range: investigation

**Finding:** increasing the client's geometric hit-selection range is technically feasible in the observed client architecture. Whether that causes actual damage at a greater distance in the live game is **unproven**. The decisive server combat handlers are absent from the saved copy. The panel does not enable or advertise an untested hitbox extender.

## Evidence in the connected game copy

1. `StarterPlayer.StarterPlayerScripts.ClientMain` assigns `ReplicatedStorage.Modules.Hitbox` to `_G.hitbox`.
2. `Modules.Hitbox.start` accepts a character, a size vector, duration, offset, and callbacks. It creates a local attack part; hit detection uses `RotatedRegion3` and the eligible targets returned by `_G.getTargets`. Its client update is driven by RenderStepped. The visible part is not itself proof of server damage.
3. `Modules.SharedGlobals._G.getTargets` gathers eligible character parts and applies target eligibility such as alive/force-field/party checks. Ordinary character cases use HumanoidRootPart, with some model-hitbox exceptions. `getTargetByPart` maps query results back to characters.
4. `Modules.SwordHandle.Swords["Festival Lancer"].Skill2` contains an observed Festival Crash example with size `Vector3.new(8,5,12)` and offset `CFrame.new(0,0,-3)`. On a local hit, its callback reports the character CFrame and selected target through a per-skill server event obtained from `Events.Skill`. This confirms a client-detected candidate is submitted for server processing; it does not establish how that server validates range.
5. `Modules.HitboxManager` provides another overlap path using `workspace:GetPartsInPart` and an inclusion filter for `Workspace.PlayerCharacters`. Therefore a change to one hitbox path need not cover every move or weapon.
6. `workspace.VisualHitboxDebug` can make the Hitbox module's local attack volume visible. It changes visualization, not authoritative damage or reach.

The source is decompiled and may differ from the current live revision. No conclusion about every M1 attack is warranted from the Festival Crash example alone.

## Possibilities considered

| Approach | Local feasibility | Does it prove longer-distance damage? |
| --- | --- | --- |
| Expand the attack query's forward depth / offset | Strong candidate for attacks using the observed Hitbox path. Explicit query geometry determines which local targets overlap. | No. The server can independently reject the target or attacker position. |
| Enlarge an enemy's local root/body hitbox | Can affect local overlap tests when that part is included in the target model. Different moves may use different parts. | No. Client size changes do not establish the server's geometry or accepted range. |
| Enlarge a weapon's visible Handle | Does not change the explicit size vector supplied to the observed region-based attack. | No; cosmetic geometry is insufficient for that path. |
| Change HitboxManager overlap parts | A separate local path; effectiveness depends on the specific attack using it. | No; still requires the server to accept the result. |
| Widen projectile/raycast selection | Relevant only to moves whose actual targeting implementation uses that query. | No; this is not automatically a melee extender. |
| Submit a farther target through a skill event | The observed callback sends a target; the missing server decides eligibility. | Unknown. The saved client cannot show acceptance or enforcement thresholds. |
| Synthesize touch/contact events | The observed Hitbox module uses region queries and callbacks instead of a touch-driven damage trigger. | No evidence this applies to the inspected attack path. |
| Move/replicate the attacker's character closer | Can change actual attacker position where client movement is accepted. | It does not meet the requested behavior of remaining farther back. |
| Change debug visuals | Can display the query volume. | No damage effect by itself. |
| Change authoritative server reach | Deterministically possible when editing the combat server. | Outside this standalone executor implementation and not available in the supplied copy. |

## Geometry-only experiment

A temporary isolated Part at 13 studs ahead of the fixture origin was queried in Studio, using the observed Festival Crash box orientation and offset:

- Normal `8 × 5 × 12` attack box: no overlap.
- Extended `8 × 5 × 20` attack box: overlap.
- Normal attack box with the target's local depth enlarged from 2 to 10: overlap.

This establishes the geometric mechanism. The fixture was destroyed immediately and no combat remote or damage function was invoked. It does **not** establish extra reach on the live server.

## What would establish the remaining claim

A live, controlled two-player test needs to compare unchanged and enlarged local query results at measured separations while separately observing replicated target health, with the same attack, timing, line of sight, and combat state. Local hit callbacks or animations alone are insufficient evidence. Each desired M1/weapon/skill path must be checked separately. No such live PvP result was available in this session.

Roblox's [client/server boundary guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary) explains why servers should validate hit positions, obstructions, firing rate, and player state. The [instance streaming documentation](https://create.roblox.com/docs/workspace/streaming) explains why an unreplicated target also cannot participate in a normal local spatial query. These are platform constraints; whether this particular live game enforces the relevant checks remains unknown.
