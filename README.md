# esx-vehiclekeys

ESX Legacy port of [`qbcore-framework/qb-vehiclekeys`](https://github.com/qbcore-framework/qb-vehiclekeys). It keeps the original vehicle key gameplay loop while replacing QBCore framework calls with ESX equivalents.

## Features

- Vehicle key tracking with optional ESX metadata persistence.
- `/givekeys`, `/addkeys`, and `/removekeys` commands.
- Lock/unlock/engine toggles and draggable keyfob NUI.
- Lockpick and advanced lockpick usable item hooks.
- Animated lockpicking with progressbar/help-notification fallback.
- Hotwiring, NPC vehicle locking, carjacking, police alerts, and shared job keys.
- QB event aliases for common integration compatibility.

## Install

1. Place this folder in your server resources as `esx-vehiclekeys`.
2. Ensure `es_extended` starts before this resource.
3. Add this to `server.cfg`:

```cfg
ensure es_extended
ensure esx-vehiclekeys
```

4. Add `lockpick` and `advancedlockpick` to your ESX inventory item table if your inventory requires static item definitions.
5. Review `config.lua`, especially `Config.PoliceJobs`, `Config.SharedKeys`, and persistence settings.

## QS inventory and hotbar notes

This ESX build can ship with `Config.CustomInventory = 'qs'`, and its QS bridge may call `exports['qs-inventory']:CreateUsableItem(...)` from `ESX.RegisterUsableItem`. Some QS inventory builds do not provide that export.

`Config.RegisterLockpickUsableItems = 'auto'` now still attempts `ESX.RegisterUsableItem`, but wraps registration in `pcall` so a missing QS export does not crash the resource. This is intentional: QS hotbar usage may rely on ESX's usable item callback table, and skipping registration entirely can produce the QS UI message `Cannot use this item from the hotbar`.

If you wire QS items directly, use one of these events:

```lua
TriggerClientEvent('esx_vehiclekeys:client:UseLockpick', source, false) -- normal lockpick
TriggerClientEvent('esx_vehiclekeys:client:UseLockpick', source, true)  -- advanced lockpick
```

Or, from a server-side item event:

```lua
TriggerEvent('esx_vehiclekeys:server:UseLockpickItem', source, false) -- normal lockpick
TriggerEvent('esx_vehiclekeys:server:UseLockpickItem', source, true)  -- advanced lockpick
```

`esx_vehiclekeys:client:LockpickVehicle` remains as a compatibility alias and runs the same animated `UseLockpick` flow.

## Lockpicking and key search flow

Successful lockpicking unlocks the vehicle and marks that plate as searchable instead of immediately granting keys. The driver must enter the vehicle and use the `[H] - Search for Keys` interaction to receive keys, controlled by `Config.RequireLockpickForSearchKeys` and `Config.LockpickedSearchGuaranteesKeys`. Failed lockpicks do not enable the search prompt.

The in-vehicle search prompt is drawn every frame while active, which avoids flickering caused by showing frame-bound text from a slow loop. Lockpicking/search progress tries `ESX.Progressbar` first if `esx_progressbar` is installed; otherwise it falls back to `ESX.ShowHelpNotification`, not a noisy feed notification or 3D hover text.

Lockpicking plays a configurable mechanic-style animation (`Config.LockpickAnimation`) while timed lockpick progress runs. The default animation uses `anim@amb@clubhouse@tutorial@bkr_tut_ig3@` / `machinic_loop_mechandplayer` with flag `49`; tweak that config if your server prefers a different animation.

## General compatibility notes

This port intentionally does not depend on `qb-core`, `qb-inventory`, `qb-minigames`, or QBCore `progressbar`. Lockpicking uses a dependency-free timed progress fallback and configurable success chances. If you want a fancy minigame, wire your minigame export into `UseLockpick` in `client.lua`; the integration point is deliberately small so you do not have to surgically extract QBCore spaghetti with barbecue tongs.

Persistent keys match the current ESX metadata API shape from `server/classes/player.lua`: reads use `xPlayer.getMeta()` first so missing `vehicleKeys` does not explode under `Config.EnableDebug`, adds use `xPlayer.setMeta('vehicleKeys', plate, true)`, and removals use `xPlayer.clearMeta('vehicleKeys', plate)` when available. The table-write fallback is still there for older/custom ESX builds, because FiveM resources age like milk in a hot car.

## Exports

Server:

```lua
exports['esx-vehiclekeys']:GiveKeys(playerId, plate)
exports['esx-vehiclekeys']:RemoveKeys(playerId, plate)
exports['esx-vehiclekeys']:HasKeys(playerId, plate)
```

Client:

```lua
exports['esx-vehiclekeys']:HasKeys(plate)
exports['esx-vehiclekeys']:addNoLockVehicles(model)
exports['esx-vehiclekeys']:removeNoLockVehicles(model)
```

## Branch

Created as local git branch `feature/esx-port`.
