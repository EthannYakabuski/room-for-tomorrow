# Room for Tomorrow

## Ad-load ownership follow-up: native retest pending

The source now owns pending and completed ad-loader lifetimes through shutdown and deferred SDK release. Vendor code, earned-only callbacks, gameplay, saves and service values are unchanged. Windows validation passed 92 lifecycle, 167 UI/callback and 15 Round Two UI checks plus the platform smoke suite, with zero suite diagnostics.

A rebuilt Android/Web pair and native shutdown retest are still required. Preserved ABA/331 binaries, archives and screenshots remain older evidence; native earned hints and the separate VAO diagnostic remain unverified. See [the engineering follow-up](docs/ROUND_TWO_UPDATE.md) for the ownership diagnosis and test limits.

## Reviewed hint-return successor and qualified native handoff

Runtime `331b83cac2384ea0c1960335471f1923e28a5378` has accepted Android/Web outputs in `build/round-two-331b83ca-a1/`. APK SHA256 `ABA522F7DA08D4AC16E64B484AD273427A8AAE5BBED53CE5152BE9E1EC85114A`. See HANDOFF.txt for HTML/PCK identities. The no-earned feedback/stale-callback repair passed 167 UI and 15 Round Two UI strict checks. Its actual current-APK unearned return passed: after one presented/dismissed ad the screen read "No hint was unlocked. Your room is unchanged." No earned event or hint was observed; all 22 save groups, drafts and bank 295/175 stayed unchanged. Earned native hints remain UNVERIFIED. All 18 final raw views and bounded cold/save/restoration checks are recorded below. Qualified 7D critical gameplay/ad/offline records remain predecessor evidence; shutdown diagnostics and slow offline render are not dismissed or attributed to a cause.

Make a small room work beautifully.

A cozy spatial puzzle about furniture, usable space and clear doorways. Complete 120 commissions across twelve chapters, try daily rooms and arrange a decoration space of your own.

## Play

Select furniture, rotate it and place it on the room grid. Read each household request, keep useful walking routes clear and try another arrangement with free undo/reset. Complete commissions to earn planner experience and open new chapters. New L-shaped, stepped, courtyard and cross-hall floors share the same placement and route rules. All 140 supplied Furniture Kit models are available through directional artwork and a categorized decoration palette.

Portrait touch/mouse controls and local offline saves. Native ads and Play Games are optional services; Web keeps gameplay and progress functional when they are unavailable. Optional ad benefits require the actual native earned-reward callback. No browser simulation grants an ad reward.

## Continue this project

This game folder is the canonical Git working copy for [Room for Tomorrow](https://github.com/EthannYakabuski/room-for-tomorrow). Open this folder as its own Codex project and use one focused task per update. Read `AGENTS.md`, `HANDOFF.txt` and `docs/PLATFORM_SETUP.md` first; a new task must recover context from these files rather than assume access to an earlier chat. Check existing user changes before editing.

Verified pre-consolidation public baseline: `6359e64705dd7c3a84d59e0aac16d027a8173edf`.
[Hosted build/test run](https://github.com/EthannYakabuski/room-for-tomorrow/actions/runs/39526924268): **PASS** on that exact commit.
Later documentation commits require their own CI result; this dated result does not verify later binaries.

`game/catalog.json` defines 20 achievements and 3 leaderboards. `platform/config.json` maps their symbolic keys to owner-supplied console IDs; the numeric Play Games game ID must also match `export_presets.cfg`. See native setup for the separate AdMob manifest setting and the development test-ID rules.

## Build and test

Use Godot **4.5.1 Compatibility**, matching export templates, Java17 and the Android SDK. Android test package: `com.ethannyakabuski.roomfortomorrow`, minimumAPI24/targetAPI35. Android texture import is enabled; the initial Android shader-cache guard avoids an observed old-emulator driver fault. Android remote-run is disabled in the preset so headless exports do not shut down the ADB server; command-line export still works. See [native setup](docs/PLATFORM_SETUP.md) and the game/tests reports for exact test entrypoints.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_ad_load_lifetime.gd
godot --headless --path . --script platform/tests/services_smoke.gd
godot --headless --path . --export-release Web build/local-next-update/web/index.html
godot --headless --path . --install-android-build-template --export-debug Android build/local-next-update/android/room-for-tomorrow-debug.apk
```

Create new unused output folders first; preserve old and accepted artifacts. These commands assume a `godot` executable on PATH; on Windows substitute the installed Godot executable, using PowerShell's `&` call operator for a quoted path. No Windows desktop build is supplied.

## Native services

AdMob uses Google's official test app/unit IDs. Main menus offer a banner, every two completed rounds create a natural interstitial opportunity, and valuable optional hints require an earned native reward. Consent/error/unavailable paths preserve ordinary play. Play Games is wired with symbolic achievement/leaderboard mappings and production configuration disabled pending owner console IDs and configuration. All required owner configuration points are documented in platform/config.json and docs/PLATFORM_SETUP.md.

## Source and delivery

Original code is Apache-2.0. Developer: [EthannYakabuski](https://github.com/EthannYakabuski). Third-party assets/plugins retain their supplied licenses and required notices. Hosted CI runs game/service tests and exports Android/Web; Pages deployment remains explicitly disabled. Build artifacts, caches and keys are excluded from source. See HANDOFF.txt for actual results and blockers; file/workflow presence alone does not establish verification.

Marketing assets, store/web copy, icons and screenshot provenance belong under marketing/. Human-owned next steps include final backend IDs/account setup, release signing, current Play eligibility checks, production service tests, human playtesting and Play publication. The first package is test-configured and must not be treated as Play-ready.

## Round two

See [the engineering update](docs/ROUND_TWO_UPDATE.md) for the exact access rules, content additions and verified tests. Illustrated app/feature art and all 20 achievement/3 leaderboard badges are integrated. Successor exports and actual unearned hint-return feedback are verified; all 18 final raw views and bounded cold/save/restoration checks are recorded below. Original and 7D critical native evidence remain tied to their dated APKs.

## Future content

Above the Bakery: attic/apartment commissions with sloping-wall restrictions and warm furniture variants.

## Licenses

See [the complete accompanying notices](LICENSES/INDEX.txt) for the engine,
fonts, plugins and assets. Keep the `LICENSES` directory with every redistributed
Android or Web build; original-code Apache licensing does not replace third-party
terms. CI copies these notices beside both exports and includes them with the
Android artifact.

## Public source and deployment status

The public repository contains source, assets, notices and sanitized verification summaries. Original local QA APKs, raw SDK logs, real saves, signing material and private evidence stay outside tracked public content. Local restored build outputs remain ignored. Hosted export artifacts are separate binaries from the APK named in HANDOFF.txt and have not received that original native QA.

Pages remains disabled; no live deployment, Library action or Google Play publication is part of this handoff. Keep the complete third-party notices with redistributed source and builds.

## Screenshot verification

Public screenshot metadata records PNG-relative filenames, SHA256 digests, dimensions and the original visual qualifications. Compare files in `marketing/screenshots/` and its `raw/` directory against `capture-manifest.json` with a SHA256 utility; matching hashes verify unchanged image bytes. These public summaries are not internal capture-validator receipts and do not create new device acceptance.

## Service configuration caution

`admob.app_id` in JSON is a reference value: the Android manifest uses Godot Project Settings `admob/general/android/app_id`. The Services `test_mode` flag changes status wording; it does not turn production ad unit IDs into test requests. Keep Google sample IDs for development, or configure real test devices separately before production-ID testing.

The final set contains 18 distinct unmodified actual current-APK captures: six each at phone 1080x1920@420dpi, logical 7-inch 1200x1920@320dpi and logical 10-inch 1600x2560@300dpi. Root independently accepted every full view and verified raw hashes/dimensions. See marketing/screenshots-round-two/capture-manifest.json for exact names, contexts and hashes. The 10-inch catalogue view shows All pieces/bathroom models and the genuine saved rotated bunk, not the Bedroom filter. Black/reconnection frames and duplicate padding are excluded. These are logical emulator profiles, not physical-tablet tests. Original nine-view records remain historical. In-game Back/Home saving and hardware Back launcher exit remain distinct. Earned native hints remain UNVERIFIED after two predecessor and one successor unearned returns.

Source publication: runtime `331b83cac2384ea0c1960335471f1923e28a5378` passed [its hosted CI](https://github.com/EthannYakabuski/room-for-tomorrow/actions/runs/39719181068). Final handoff/screenshot commit `58e74c8a919dd04f518b0f400d19fb6426dbddec` is public and passed [its exact CI run](https://github.com/EthannYakabuski/room-for-tomorrow/actions/runs/39733960316). These dated runs do not validate the newer loader-ownership binary. Pages/Library/Play settings are unchanged.

One normal successor update succeeded. The independently read full installed APK hash matched accepted ABA, and all 22 save groups (bank 295/175) were byte-exact unchanged before first launch, without restoration, clearing or completed-reward replay. Final cold/closing observations are recorded separately below.


After capture sessions, one normal cold launch at the restored original phone profile rendered Home at the 22.1-second observation without an observed ANR. All 22 save groups (906-byte profile, bank 295 coins/175 XP) stayed byte-exact unchanged; clears 0/1/13 and the rotated bunk remained. Final stop completed with the process absent and a full backup whose embedded main save matched. Original 1080x1920@420dpi with no overrides, airplane off, Wi-Fi/mobile data on and actual default Wi-Fi connectivity were verified restored. No rewards or claims were replayed. This is a bounded cold/save/restoration observation, not a general performance pass.

The older predecessor log did not name its five resources. A later ordinary-Back trace from the preserved ABA APK identified InterstitialAdLoader, InterstitialAdLoadCallback, RewardedAdLoader, RewardedAdLoadCallback and MobileSingletonPlugin. The new source ownership fix is verified by isolated Windows fixtures only; rebuilt-APK shutdown verification remains pending. The separate VAO diagnostic has no established cause, and no native active-audio exit or earned-hint pass is claimed. An informational guest date command was unsupported (exit 1); no clock change was made and no full command/log-clean claim is made.

The current force-stop closing log slice contained zero listed script/fatal/error/ObjectDB/resource/VAO terms. That limited slice does not erase the earlier system-Back shutdown diagnostics or make the whole native run clean.
