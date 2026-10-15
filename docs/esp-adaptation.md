# ESP detector replacement — v1.2

Detection identifiers come from the user-selected [serpo222/minecraftGIPIO](https://github.com/serpo222/minecraftGIPIO/tree/d5d7a90c3e5f719c74fe5d30ab157b8d3178a04d) revision `d5d7a90c3e5f719c74fe5d30ab157b8d3178a04d`, inspected on 15 October 2026. The reference medal scripts credit SaidBr. Their identifiers and detection approach are integrated into the panel's own maintained detector and renderer; the repository's main script, external UI, notifications, and other features are not loaded.

| Category | Identifier | Reference |
| --- | --- | --- |
| Common chest | Mesh ID `10779253534` | [Common script](https://github.com/serpo222/minecraftGIPIO/blob/d5d7a90c3e5f719c74fe5d30ab157b8d3178a04d/Common%20Chest%20Esp%201500) |
| Rare chest | Mesh ID `10788852296` | [Rare script](https://github.com/serpo222/minecraftGIPIO/blob/d5d7a90c3e5f719c74fe5d30ab157b8d3178a04d/Rare%20Chest%20Esp%201500) |
| Legendary chest | Mesh ID `10798559852` | [Legendary script](https://github.com/serpo222/minecraftGIPIO/blob/d5d7a90c3e5f719c74fe5d30ab157b8d3178a04d/Legendary%20Chest%20Esp%201500) |
| Mythic chest | Mesh ID `10811929054` | [Mythic script](https://github.com/serpo222/minecraftGIPIO/blob/d5d7a90c3e5f719c74fe5d30ab157b8d3178a04d/Mythical%20Chest%20Esp%201500) |
| Black Leg medal | Effects child `BlackLeg Medal` | [Black Leg script](https://github.com/serpo222/minecraftGIPIO/blob/d5d7a90c3e5f719c74fe5d30ab157b8d3178a04d/BlackLeg%20Medal%20Esp) |
| Other styles | `Rokushiki Medal`, `Fishman Karate Medal`, `Vampire Medal` | Corresponding medal scripts in the reference repository |
| All medals | Effects child name contains `Medal` | Medal toggle in the reference main script |

The old panel's item-name chest detection and spawn-event/beam medal detection have been replaced. Trainer handling remains separate.

## Fixes in the adaptation

- One marker per root pickup rather than one BillboardGui per nested child.
- Watches Effects insertion/removal, root names, and mesh identities. It does not scan every RenderStepped or create extra connections on each toggle.
- Supports absent or replaced Effects folders and parts arriving after their containing model.
- Checks all relevant MeshParts, rather than only whichever MeshPart is found first. Conflicting known rarity meshes are left unclassified.
- Cleans up after pickup collection, streaming out, unload, and re-execution. Deferred callbacks cannot recreate markers after unload.
- Uses the same independent toggles, range settings, nearest-object limits, distance labels, and overlap suppression as the panel.
- Uses valid Highlight properties and a bounded pool of 20 reusable outlines instead of creating an unbounded Highlight per child.
- Avoids global `ESP` names colliding with another script, undefined toggle variables, and yielding waits inside RenderStepped callbacks.
- Gives labels fixed readable pixel sizes rather than giant scale-based BillboardGuis and TextScaled labels.
- Corrects the reference Common script's inconsistent second-pass Rare mesh ID by using its Common detection ID consistently.
- Loads no third-party code at runtime. These identifiers are static and may need updating if the live game's assets change.

Validation: 30 core tests and 19 isolated detector lifecycle tests pass; all production and test sources compile with Luau 0.740. Studio was closed, so this revision is not claimed as live-game or Potassium-runtime tested.
