# esx-vehiclekeys

ESX Legacy port of [`qbcore-framework/qb-vehiclekeys`](https://github.com/qbcore-framework/qb-vehiclekeys). It keeps the original vehicle key gameplay loop while replacing QBCore framework calls with ESX equivalents.

## Features

- Vehicle key tracking with optional ESX metadata persistence.
- `/givekeys`, `/addkeys`, and `/removekeys` commands.
- Lock/unlock/engine toggles and draggable keyfob NUI.
- Lockpick and advanced lockpick usable item hooks.
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

## Compatibility notes

This port intentionally does not depend on `qb-core`, `qb-inventory`, `qb-minigames`, or `progressbar`. Lockpicking uses a dependency-free timed progress fallback and configurable success chances. If you want a fancy minigame, wire your minigame export into `UseLockpick` in `client.lua`; the integration point is deliberately small so you do not have to surgically extract QBCore spaghetti with barbecue tongs.

Persistent keys use `xPlayer.getMeta('vehicleKeys')` / `xPlayer.setMeta('vehicleKeys', keys)` when available. If your ESX build or inventory replaces metadata behavior, set `Config.PersistentKeys = false` or adapt `GetPersistentKeys` and `SetPersistentKeys` in `server.lua`.

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
