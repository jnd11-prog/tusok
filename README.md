# tusok
# TUSOK! — TAFT CART / Complete rebuild

**Ate Bebang went to buy ice. She said *saglit lang*. The DLSU after-class crowd is already here, and you are the only vendor.**

This is a ground-up, **solo-vendor** rework of the original TUSOK! prototype. It deliberately replaces job systems, separate prep stations, egg peeling, and broad tycoon management with a compact Taft-style cart, one hot fryer, sauce bottles, a tray, and a physical cash drawer.

## Quick start (Mac or Windows)

1. Download `TUSOK_TAFT_CART_REBUILT.rbxlx` (or extract it from the ZIP).
2. Open **Roblox Studio → File → Open from File** and select that `.rbxlx`.
3. **Press Play (F5)**. The 3D environment is *already saved* and should also be visible in Edit mode. No code needs pasting.
4. Click **BUKAS NA / START SHIFT**.
5. Order #1: **kwek-kwek, suka, ₱25, tendered ₱50**.
6. Click **KWEK-KWEK** in the bottom dock (or click the food tray in the 3D cart). The oil panel appears.
7. Click **DROP IN OIL**, wait **at least 1.5 seconds**, then **FLIP / BALIKTAD**.
8. At **4.8–6.9 seconds**, click **LIFT / SALUKIN**. Don't lift before 4 seconds or leave it past 9.
9. Click **DRAIN / PATULUIN** twice. The cooked batch moves to the ready tray.
10. Choose **SUKA** and click **SERVE / SUKLI**.
11. Count **₱20 + ₱5** by clicking the denomination buttons, then **IBIGAY ANG SUKLI**.
12. Repeat for all 8 customers. You can batch-cook ahead and purchase 3 more raw portions for ₱28 in the inventory card.

### What the customer actually cares about

- It must be the ordered food, present on your ready tray.
- It must be fried long enough not to be raw or burnt.
- Pick the **correct sawsawan**. Wrong sauce is rejected and must be corrected.
- Pay exact sukli **using coins/bills actually available** in the cash drawer.
- Don't let the patience bar expire.

## Visual direction

The art palette comes from color sampling the supplied Taft/street-food moodboard:

| Color | Approximate sample | Intended use |
|---|---|---|
| Kwek orange | `#E16E27` | appetizing food, fry state, main typography |
| Fried batter rust | `#C34115` | hot oil / weathering accents |
| Oxide red | `#92180D` | fading tarpaulin, worn signage |
| Aged stainless / slate | `#637C89` | cart, containers, metal |
| Sun-faded blue | `#27507D` | condiment caps, cash tub |
| Weathered paper | `#D8C19F` | signage, small UI information |
| Brown shadow | `#5F492D` | cooking and gritty street elements |
| Acid school poster | `#C7D612` | a *rare* local poster/cement highlight |

**Design constraints:** a single 12.8-stud-wide stall; a real Taft curb, green University Belt fence, LRT girders, parked jeepney and photocopy shops behind it. Sauce jars, food display trays, receipts, barya box, hoses and propane are all grouped onto one service counter. The UI is a custom Luau HUD with smoky translucent panels, order slip, stock card, frying timer and cash interaction, not a premade Roblox template.

**Visual fidelity limitation:** this is custom built from Roblox primitive geometry and native materials, *not a rendered photorealistic mesh scene*. It uses moodboard-derived composition/color, but won't match the fully photoreal concept mockup without importing handcrafted textured meshes (Blender / PBR) and testing the scene lighting in Roblox. No external assets or unlicensed Toolbox models are needed to load the place.

## Engineering

```
TUSOK_TAFT_REBUILD/
├── TUSOK_TAFT_CART_REBUILT.rbxlx       # fully saved editor-visible map + embedded scripts
├── build_place.py                     # deterministic map creator; rerunning overwrites .rbxlx!
├── default.project.json               # Rojo project for source iteration
├── src/
│   ├── ReplicatedStorage/
│   │   ├── CartConfig.lua              # prices, shift, customer lines, timing
│   │   └── CartRules.lua               # pure, independently tested financial/cooking rules
│   ├── ServerScriptService/
│   │   ├── CartServer.server.lua       # authoritative cooking, payments and stock
│   │   └── CartSelfTest.server.lua     # Studio-only rules self-tests
│   └── StarterPlayer/StarterPlayerScripts/
│       └── CartClient.client.lua       # new UI and fixed cart-facing camera
├── tests/
│   ├── test_rules.lua
│   ├── run_offline.py
│   ├── check_syntax.py
│   └── verify_place.py
└── DESIGN.md
```

The server validates the food, cooking timer, flip state, prepared inventory, sauce, order ID, customer timeout, and change drawer. It never trusts a local progress bar or client-reported earnings. No yield happens between settlement validation and marking an order paid. Client sends denominations as a packed list because Roblox remote-serialization of numeric-keyed sparse dictionaries is unreliable.

### Run offline verification (optional)

Requires Python 3, `lxml` and a Lua TeX interpreter (`texlua`, `texluac`). From this directory:

```
python build_place.py
python tests/check_syntax.py
python tests/run_offline.py
python tests/verify_place.py
```

Offline tests cover incorrect timing, double flipping, phantom money, exact-denomination settlement, expired orders, duplicate payout guards, and restocking. The Lua syntax parser is *not a Roblox Luau compiler*, and **passing these tests does not prove the game runs in Studio**.

### Critical Studio checks

Open **View → Output** before pressing Play. Look for `[TUSOK SELF TEST] passed ... rules checks` and no red errors. Confirm all eight sales manually, multiple consecutive cooked batches, both wrong and correct sauce choices, deliberately mistimed fryer, repeated Serve clicks, restocking, and mobile controls. Play a **single player**—max players should be set to 1 in Game Settings / Creator Dashboard when publishing.

**Not implemented:** cross-session saving, NPC walking/pathfinding, hand animation, photogrammetric/PBR textures, ambient audio, or paid assets. This is a gameplay candidate awaiting real Roblox Studio playtesting, not a published or in-engine QA-certified experience.

### If it opens to an empty sky

Explorer → Workspace → TaftCart → Scene → 03 / Ate Bebang one cart, select `Steel counter surface` and press **F** to frame it. Press **Play**, which uses the intentionally locked vendor-facing camera. If any click is ignored, send the exact **View → Output** error, the button/step, and a screenshot.

## Portfolios / hiring

This project can show state machines, validation of untrusted network requests, transaction atomicity, finite inventory, exact monetary accounting and responsive interface implementation. Do not claim Roblox playtests or production launch before carrying them out.

## Art references included

- `references/USER_MOODBOARD.png`: the exact uploaded reference collage, included so palette and cultural texture stay grounded.
- `references/VISUAL_TARGET_CONCEPT_NOT_GAMEPLAY.png`: the earlier generated *concept image*. This is **not** a screenshot of this Roblox place and is not automatically used as an in-game texture. It is a target for later mesh/texture production.
