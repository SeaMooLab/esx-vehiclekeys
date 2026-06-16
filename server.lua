-----------------------
----   Variables   ----
-----------------------
local ESX = exports['es_extended']:getSharedObject()
local VehicleList = {}

local function Trim(value)
    return value and value:match('^%s*(.-)%s*$') or value
end

local function Notify(source, message, notifyType)
    TriggerClientEvent('esx_vehiclekeys:client:Notify', source, message, notifyType or 'info')
end

local function GetIdentifier(xPlayer)
    if not xPlayer then return nil end
    if xPlayer.getIdentifier then return xPlayer.getIdentifier() end
    return xPlayer.identifier
end

local function CloneTable(source)
    local clone = {}
    if type(source) ~= 'table' then return clone end

    for key, value in pairs(source) do
        clone[key] = value
    end

    return clone
end

local function GetPersistentKeys(xPlayer)
    if not Config.PersistentKeys or not xPlayer or not xPlayer.getMeta then return {} end

    -- This ESX build supports xPlayer.getMeta() with no args, which safely returns
    -- the whole metadata table without tripping Config.EnableDebug on missing keys.
    local okMeta, metadata = pcall(function()
        return xPlayer.getMeta()
    end)

    if okMeta and type(metadata) == 'table' and type(metadata.vehicleKeys) == 'table' then
        return CloneTable(metadata.vehicleKeys)
    end

    local okKeys, keys = pcall(function()
        return xPlayer.getMeta('vehicleKeys')
    end)

    if okKeys and type(keys) == 'table' then
        return CloneTable(keys)
    end

    return {}
end

local function SetPersistentKeys(xPlayer, keys)
    if not Config.PersistentKeys or not xPlayer or not xPlayer.setMeta then return end

    pcall(function()
        xPlayer.setMeta('vehicleKeys', keys or {})
    end)
end

local function AddPersistentKey(xPlayer, plate)
    if not Config.PersistentKeys or not xPlayer or not plate then return end

    if xPlayer.setMeta then
        local ok = pcall(function()
            xPlayer.setMeta('vehicleKeys', plate, true)
        end)

        if ok then return end
    end

    local keys = GetPersistentKeys(xPlayer)
    keys[plate] = true
    SetPersistentKeys(xPlayer, keys)
end

local function RemovePersistentKey(xPlayer, plate)
    if not Config.PersistentKeys or not xPlayer or not plate then return end

    if xPlayer.clearMeta then
        local ok = pcall(function()
            xPlayer.clearMeta('vehicleKeys', plate)
        end)

        if ok then return end
    end

    local keys = GetPersistentKeys(xPlayer)
    keys[plate] = nil
    SetPersistentKeys(xPlayer, keys)
end

local function GetPlayer(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then return xPlayer end
    return nil
end

local function IsAdmin(source)
    if source == 0 then return true end
    if IsPlayerAceAllowed(source, 'command.addkeys') or IsPlayerAceAllowed(source, 'command.removekeys') then return true end

    local xPlayer = GetPlayer(source)
    if not xPlayer or not xPlayer.getGroup then return false end

    local group = xPlayer.getGroup()
    return group == 'admin' or group == 'superadmin' or group == 'owner'
end

local function HandleGiveVehicleKeys(giver, receiver, plate, forceGive)
    if forceGive or giver == 0 or HasKeys(giver, plate) then
        Notify(giver, Lang:t('notify.vgkeys'), 'success')
        if type(receiver) == 'table' then
            for _, target in ipairs(receiver) do
                GiveKeys(target, plate)
            end
        else
            GiveKeys(receiver, plate)
        end
    else
        Notify(giver, Lang:t('notify.ydhk'), 'error')
    end
end

local function GetVehicleKeysForPlayer(source)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return {} end

    local identifier = GetIdentifier(xPlayer)
    local keysList = {}
    for plate, identifiers in pairs(VehicleList) do
        if identifier and identifiers[identifier] then
            keysList[plate] = true
        end
    end

    for plate in pairs(GetPersistentKeys(xPlayer)) do
        keysList[plate] = true
    end

    return keysList
end

local function GetESXCustomInventory()
    if not ESX.GetConfig then return nil end

    local ok, customInventory = pcall(function()
        return ESX.GetConfig('CustomInventory')
    end)

    if ok then return customInventory end
    return nil
end

local function ShouldRegisterUsableLockpickItems()
    local mode = Config.RegisterLockpickUsableItems
    if mode == false or mode == 'disabled' or mode == 'none' then return false end
    if not ESX.RegisterUsableItem then return false end

    local customInventory = GetESXCustomInventory()
    if mode == 'auto' and customInventory == 'qs' then
        print("[esx-vehiclekeys] ESX CustomInventory qs detected; skipping ESX.RegisterUsableItem because this es_extended bridge calls qs-inventory:CreateUsableItem, which is missing in some QS builds. Configure QS item usage to trigger esx_vehiclekeys:client:UseLockpick instead, or set Config.RegisterLockpickUsableItems = 'esx' to force it.")
        return false
    end

    return true
end

local function RegisterUsableLockpickItem(itemName, isAdvanced)
    local ok, err = pcall(function()
        ESX.RegisterUsableItem(itemName, function(source)
            TriggerClientEvent('esx_vehiclekeys:client:LockpickVehicle', source, isAdvanced)
        end)
    end)

    if not ok then
        print(('[esx-vehiclekeys] Failed to register usable item %s: %s'):format(itemName, tostring(err)))
    end
end

local function RegisterUsableLockpickItems()
    if not ShouldRegisterUsableLockpickItems() then return end

    RegisterUsableLockpickItem('lockpick', false)
    RegisterUsableLockpickItem('advancedlockpick', true)
end

-----------------------
---- Server Events ----
-----------------------
RegisterNetEvent('esx_vehiclekeys:server:GiveVehicleKeys', function(receiver, plate, forceGive)
    HandleGiveVehicleKeys(source, receiver, plate, forceGive)
end)

RegisterNetEvent('esx_vehiclekeys:server:AcquireVehicleKeys', function(plate)
    GiveKeys(source, plate)
end)

RegisterNetEvent('esx_vehiclekeys:server:RemoveVehicleKeys', function(plate)
    local src = source
    if not HasKeys(src, plate) then return end

    RemoveKeys(src, plate)
end)

RegisterNetEvent('esx_vehiclekeys:server:breakLockpick', function(itemName)
    local src = source
    local xPlayer = GetPlayer(src)
    if not xPlayer then return end
    if itemName ~= 'lockpick' and itemName ~= 'advancedlockpick' then return end

    xPlayer.removeInventoryItem(itemName, 1)
    Notify(src, Lang:t('notify.broke_lockpick'), 'error')
end)

RegisterNetEvent('esx_vehiclekeys:server:UseLockpickItem', function(firstArg, secondArg)
    local target = source
    local isAdvanced = firstArg == true

    if type(firstArg) == 'number' then
        target = firstArg
        isAdvanced = secondArg == true
    end

    if not target or target <= 0 then return end
    TriggerClientEvent('esx_vehiclekeys:client:LockpickVehicle', target, isAdvanced)
end)

RegisterNetEvent('esx_vehiclekeys:server:setVehLockState', function(vehNetId, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    if vehicle and vehicle ~= 0 then
        SetVehicleDoorsLocked(vehicle, state)
    end
end)

RegisterNetEvent('esx_vehiclekeys:server:PoliceAlert', function(message)
    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xPlayer = GetPlayer(playerId)
        local job = xPlayer and xPlayer.getJob and xPlayer.getJob()
        if job and Config.PoliceJobs[job.name] then
            Notify(playerId, message, 'error')
        end
    end
end)

-- Backwards-compatible QB event aliases for resources that already call qb-vehiclekeys.
RegisterNetEvent('qb-vehiclekeys:server:GiveVehicleKeys', function(receiver, plate, forceGive)
    HandleGiveVehicleKeys(source, receiver, plate, forceGive)
end)

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    GiveKeys(source, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:RemoveVehicleKeys', function(plate)
    local src = source
    if not HasKeys(src, plate) then return end

    RemoveKeys(src, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:breakLockpick', function(itemName)
    local src = source
    local xPlayer = GetPlayer(src)
    if not xPlayer then return end
    if itemName ~= 'lockpick' and itemName ~= 'advancedlockpick' then return end

    xPlayer.removeInventoryItem(itemName, 1)
    Notify(src, Lang:t('notify.broke_lockpick'), 'error')
end)

RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(vehNetId, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    if vehicle and vehicle ~= 0 then
        SetVehicleDoorsLocked(vehicle, state)
    end
end)

-----------------------
----   Callbacks   ----
-----------------------
ESX.RegisterServerCallback('esx_vehiclekeys:server:GetVehicleKeys', function(source, cb)
    cb(GetVehicleKeysForPlayer(source))
end)

ESX.RegisterServerCallback('esx_vehiclekeys:server:checkPlayerOwned', function(_, cb, plate)
    cb(VehicleList[plate] ~= nil)
end)

ESX.RegisterServerCallback('qb-vehiclekeys:server:GetVehicleKeys', function(source, cb)
    cb(GetVehicleKeysForPlayer(source))
end)

ESX.RegisterServerCallback('qb-vehiclekeys:server:checkPlayerOwned', function(_, cb, plate)
    cb(VehicleList[plate] ~= nil)
end)

-----------------------
----   Functions   ----
-----------------------
function GiveKeys(id, plate)
    id = tonumber(id)
    if not id then return end

    local xPlayer = GetPlayer(id)
    if not xPlayer then return end

    if not plate then
        local ped = GetPlayerPed(id)
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            plate = Trim(GetVehicleNumberPlateText(vehicle))
        else
            return
        end
    end

    plate = Trim(plate)
    if not plate or plate == '' then return end

    local identifier = GetIdentifier(xPlayer)
    if not identifier then return end

    if not VehicleList[plate] then VehicleList[plate] = {} end
    VehicleList[plate][identifier] = true

    AddPersistentKey(xPlayer, plate)

    Notify(id, Lang:t('notify.vgetkeys'), 'success')
    TriggerClientEvent('esx_vehiclekeys:client:AddKeys', id, plate)
end

exports('GiveKeys', GiveKeys)

function RemoveKeys(id, plate)
    id = tonumber(id)
    if not id or not plate then return end

    local xPlayer = GetPlayer(id)
    if not xPlayer then return end

    plate = Trim(plate)
    local identifier = GetIdentifier(xPlayer)
    if not identifier then return end

    if VehicleList[plate] and VehicleList[plate][identifier] then
        VehicleList[plate][identifier] = nil
    end

    RemovePersistentKey(xPlayer, plate)

    TriggerClientEvent('esx_vehiclekeys:client:RemoveKeys', id, plate)
end

exports('RemoveKeys', RemoveKeys)

function HasKeys(id, plate)
    id = tonumber(id)
    if not id or not plate then return false end

    local xPlayer = GetPlayer(id)
    if not xPlayer then return false end

    plate = Trim(plate)
    local identifier = GetIdentifier(xPlayer)
    if not identifier then return false end

    if VehicleList[plate] and VehicleList[plate][identifier] then
        return true
    end

    local persistentKeys = GetPersistentKeys(xPlayer)
    return persistentKeys[plate] == true
end

exports('HasKeys', HasKeys)

-----------------------
----   Commands    ----
-----------------------
RegisterCommand('givekeys', function(source, args)
    TriggerClientEvent('esx_vehiclekeys:client:GiveKeys', source, tonumber(args[1]))
end, false)

RegisterCommand('addkeys', function(source, args)
    if not IsAdmin(source) then
        Notify(source, Lang:t('notify.no_permission'), 'error')
        return
    end

    if not args[1] or not args[2] then
        Notify(source, Lang:t('notify.fpid'), 'error')
        return
    end

    GiveKeys(tonumber(args[1]), args[2])
end, false)

RegisterCommand('removekeys', function(source, args)
    if not IsAdmin(source) then
        Notify(source, Lang:t('notify.no_permission'), 'error')
        return
    end

    if not args[1] or not args[2] then
        Notify(source, Lang:t('notify.fpid'), 'error')
        return
    end

    RemoveKeys(tonumber(args[1]), args[2])
end, false)

RegisterUsableLockpickItems()
