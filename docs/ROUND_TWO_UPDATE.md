# Round two engineering update

Room for Tomorrow now has 120 solution-verified commissions across twelve chapters. Sixty new rooms use actual L-shaped, courtyard, stepped, gallery, alcove and cross-hall floor masks. The mask owns drawing, placement bounds and entrance flood-fill, so a missing corner cannot be furnished or crossed. The original sixty commission definitions remain unchanged.

All 140 supplied Furniture Kit models are represented with their four original directional PNGs: 560 unchanged art files in total. New identifiers are namespaced to preserve all twelve original furniture/save keys. The decoration palette has categories, and every model also occurs in a commission. Explicit new footprints come from measured model geometry; legacy grid footprint conventions remain for existing drafts. SOURCE_MAP.json records pack/model provenance and footprint/access policy. Kenney's CC0 license is retained.

## What “usable fronts” means

A usable access tile must connect to the green doorway through cardinal, empty walking tiles. It is not enough for the tile to look empty: another piece or a column can isolate it. One connected tile along the relevant edge is sufficient; the entire edge need not be clear.

Desks, chairs, storage and appliances use the highlighted operating edge, which rotates with the footprint. Beds can be reached along either long side. Tables and corner units accept a reachable adjacent perimeter tile. Decorative lamps/plants and structural pieces have no invented operating front; they still obey footprint/door collision, and reading-light distance remains required. Rugs, floor surfaces and open doorframes are explicitly walkable. This corrects false negatives from forcing every decorative object or a bed's foot to face a path, while retaining blocked/disconnected-front failures.

Select a piece to see its footprint and exact rule. Paths shows green connected access tiles, red blocked tiles and amber empty-but-disconnected tiles. Plan tip names the failing furniture and explains whether its edge is blocked/outside or disconnected. Undo/reset and ordinary planning remain free.

## Verification and continuity

Godot 4.5.1 disposable-data tests passed: model 1,579/1,579 including all 120 recorded solutions, all 120 optional wishes, alternative arrangements and normal placement validation; round-two catalogue/floor/front/save checks 1,037/1,037; ordinary UI 155/155 including portrait controls for all 120 rooms; new paired-input UI 15/15 headless and 20/20 in an actual offscreen Compatibility viewport. Test stderr was empty. Actual phone/tablet-shaped new-room, failed-front and category views were inspected; they are synthetic desktop development fixtures, not native/store captures or physical-device proof.

Version-one saves keep legacy banked progress, identifiers and drafts. New commission IDs, model options and expanded decoration layouts roundtrip through the same bounded sanitizer. Existing achievement/service IDs and already earned unlocks remain; the old sixty-home achievement now explicitly describes the original sixty homes. Earned-hint callback handling and native services are unchanged.

Android/Web rebuilds, native SDK/Back/save/offline regression, fresh native screenshot packaging and native review of the updated artwork remain pending with the coordinator. Preserved original APK/native records are historical and do not verify this revision. Production IDs, physical devices, audible output, interactive Web and human content/balance acceptance remain unverified. Pages stays disabled.

## Illustrated branding and collection

A new cozy illustrated app icon and full-title feature graphic replace the original branding. All 20 achievement and 3 leaderboard badges were generated individually with distinct catalogue subjects, retained originals/prompts, and standard Godot resize to 512px. Their 512px outputs and 64px thumbnails were visually inspected. Runtime catalogue links now show the actual images beside milestone progress and leaderboard controls; service IDs, thresholds and progress are unchanged. Marketing source art remains outside runtime exports.

The actual Compatibility journal fixture passed 67/67 checks with empty stderr: ordinary paired Journal input, all 23 full 512px textures, non-intercepting art, unchanged typed synthetic progress and phone/two-tablet scroll/width presentation. Actual rendered collection views were inspected. This is isolated desktop development evidence; updated native captures remain pending.
