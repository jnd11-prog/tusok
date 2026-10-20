# TUSOK! / Taft Cart — why this redesign exists

The player does **not** own a restaurant. There are no selectable Cook, Runner or Cashier roles. The player stands behind exactly one modest cart near DLSU Taft and must personally do everything while Ate Bebang buys ice.

## The real work, not theme-park food prep

The older build made players peel eggs and stir batter after every order. That is not an efficient way to simulate street vending during a merienda rush. In this build, ingredients are prepped. You're juggling fryer heat, flipping, draining, what the customer actually asked for, and a box of barya. A batch takes seconds and can be cooked slightly ahead of demand. Timing influences tip quality. Wrong sauce forces a correction. The drawer has a finite count of ₱1/₱5/₱10/₱20/₱50 denominations.

## Visual sources

The supplied moodboard contains orange battered kwek-kwek, old steel carts, blue/green plastic tubs, imperfect market-side signs and the awkward dry humor of everyday Filipino posting. It also has a jarring fluorescent chartreuse editorial graphic; that is treated as an *accent*, not the primary interface. The code samples/reference palette directly in `build_place.py` and `CartClient.client.lua`.

## Functional priorities

1. One readable action on screen: cook, flip, lift, drain, sauce, give change.
2. The UI must never allow generating revenue by fake RemoteEvents.
3. Player can finish eight orders while staying by the one physical cart.
4. The map stays editable in Studio and does not rely on remote Toolbox meshes or IDs.
5. One believable small cart with a close scene camera beats 200 decorative buildings.

## Honest art limitations

Real photorealistic Roblox rendering requires custom mesh modeling, authored PBR metal/oil/food textures, lighting iteration and actual Studio playback. The file embeds readable meshes-as-parts and moodboard-based UI, not photo textures. The earlier generated hero image is a *visual target*, not a screenshot from this game. All game code and geometry are packaged for iteration.
