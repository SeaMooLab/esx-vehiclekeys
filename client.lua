-----------------------
----   Variables   ----
-----------------------
local ESX = exports['es_extended']:getSharedObject()
local KeysList = {}
local isPlayerLoaded = false
local isTakingKeys = false
local isCarjacking = false
local canCarjack = true
local alertSent = false
local lastPickedVehicle = nil
local isHotwiring = false
local trunkClose = true
local progressActive = false

local function Trim(value)
    return value and value:match('^%s*(.-)%s*$') or value
end

local function Notify(message, notifyType)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(message, notifyType or 'info')
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

local function GetPlate(vehicle)
    if not vehicle or vehicle == 0 then return nil end
    return Trim(GetVehicleNumberPlateText(vehicle))
end

local function ServerCallback(name, cb, ...)
    if ESX and ESX.TriggerServerCallback then
        ESX.TriggerServerCallback(name, cb, ...)
        return
    end

    cb(nil)
end

local function IsLoaded()
    if ESX and ESX.IsPlayerLoaded then
        local ok, loaded = pcall(ESX.IsPlayerLoaded)
        if ok then return loaded end
    end

    return isPlayerLoaded
end

local function GetPlayerJob()
    if ESX and ESX.PlayerData and ESX.PlayerData.job then
        return ESX.PlayerData.job
    end

    return {}
end

local function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        if not handle or handle == -1 then return end

        local success = true
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success

        EndFindVehicle(handle)
    end)
end

local function GetClosestVehicle(coords)
    coords = coords or GetEntityCoords(PlayerPedId())

    if ESX and ESX.Game and ESX.Game.GetClosestVehicle then
        local vehicle = ESX.Game.GetClosestVehicle(coords)
        if vehicle and vehicle ~= 0 then return vehicle end
    end

    local closestVehicle = 0
    local closestDistance = -1
    for vehicle in EnumerateVehicles() do
        local distance = #(coords - GetEntityCoords(vehicle))
        if closestDistance == -1 or distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end

    return closestVehicle
end

local function GetClosestPlayer()
    if ESX and ESX.Game and ESX.Game.GetClosestPlayer then
        local player, distance = ESX.Game.GetClosestPlayer()
        if player and player ~= -1 then return player, distance end
    end

    local players = GetActivePlayers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer = -1
    local closestDistance = -1

    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local distance = #(playerCoords - GetEntityCoords(targetPed))
            if closestDistance == -1 or distance < closestDistance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

local function Progress(label, duration, animation, onDone, onCancel)
    if progressActive then return end

    progressActive = true
    local ped = PlayerPedId()
    local canceled = false

    if animation and animation.dict and animation.name then
        loadAnimDict(animation.dict)
        TaskPlayAnim(ped, animation.dict, animation.name, 8.0, -8.0, -1, animation.flags or 16, 0, false, false, false)
    end

    CreateThread(function()
        local endTime = GetGameTimer() + duration
        while progressActive and GetGameTimer() < endTime do
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 75, true)
            DrawText3D(GetEntityCoords(ped).x, GetEntityCoords(ped).y, GetEntityCoords(ped).z + 0.85, label)
            if IsEntityDead(ped) then
                canceled = true
                break
            end
        end

        progressActive = false
        if animation and animation.dict and animation.name then
            StopAnimTask(ped, animation.dict, animation.name, 1.0)
        end

        if canceled then
            if onCancel then onCancel() end
            return
        end

        if onDone then onDone() end
    end)
end

-----------------------
---- Client Events ----
-----------------------
RegisterKeyMapping('togglelocks', Lang:t('info.tlock'), 'keyboard', 'L')
RegisterCommand('togglelocks', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        ToggleVehicleLocksWithoutNui(GetVehicle())
    elseif Config.UseKeyfob then
        OpenMenu()
    else
        ToggleVehicleLocksWithoutNui(GetVehicle())
    end
end, false)

RegisterKeyMapping('engine', Lang:t('info.engine'), 'keyboard', 'G')
RegisterCommand('engine', function()
    local vehicle = GetVehicle()
    if not vehicle then return end
    if not IsPedInVehicle(PlayerPedId(), vehicle, false) then return end

    ToggleEngine(vehicle)
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(500)
    if ESX and ESX.GetPlayerData then
        ESX.PlayerData = ESX.GetPlayerData()
    end
    if IsLoaded() then
        isPlayerLoaded = true
        GetKeys()
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    isPlayerLoaded = true
    GetKeys()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    isPlayerLoaded = false
    KeysList = {}
end)

RegisterNetEvent('esx:playerLogout', function()
    isPlayerLoaded = false
    KeysList = {}
end)

RegisterNetEvent('esx:setJob', function(job)
    ESX.PlayerData = ESX.PlayerData or {}
    ESX.PlayerData.job = job
end)

RegisterNetEvent('esx_vehiclekeys:client:Notify', function(message, notifyType)
    Notify(message, notifyType)
end)

RegisterNetEvent('esx_vehiclekeys:client:AddKeys', function(plate)
    KeysList[plate] = true
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local vehiclePlate = GetPlate(vehicle)
    if plate ~= vehiclePlate then return end

    SetVehicleEngineOn(vehicle, false, false, false)
end)

RegisterNetEvent('esx_vehiclekeys:client:RemoveKeys', function(plate)
    KeysList[plate] = nil
end)

RegisterNetEvent('esx_vehiclekeys:client:ToggleEngine', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if vehicle == 0 then return end

    local engineOn = GetIsVehicleEngineRunning(vehicle)
    if HasKeys(GetPlate(vehicle)) then
        SetVehicleEngineOn(vehicle, not engineOn, false, true)
    end
end)

RegisterNetEvent('esx_vehiclekeys:client:GiveKeys', function(id)
    local targetVehicle = GetVehicle()
    if not targetVehicle then return end

    local targetPlate = GetPlate(targetVehicle)
    if not HasKeys(targetPlate) then
        Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    if id and type(id) == 'number' then
        GiveKeys(id, targetPlate)
    elseif IsPedSittingInVehicle(PlayerPedId(), targetVehicle) then
        local otherOccupants = GetOtherPlayersInVehicle(targetVehicle)
        for p = 1, #otherOccupants do
            TriggerServerEvent('esx_vehiclekeys:server:GiveVehicleKeys', GetPlayerServerId(NetworkGetPlayerIndexFromPed(otherOccupants[p])), targetPlate)
        end
    else
        local closestPlayer, distance = GetClosestPlayer()
        if closestPlayer == -1 or not distance or distance > 1.5 then
            Notify(Lang:t('notify.nonear'), 'error')
            return
        end

        GiveKeys(GetPlayerServerId(closestPlayer), targetPlate)
    end
end)


-- Backwards-compatible QB client event aliases.
RegisterNetEvent('qb-vehiclekeys:client:AddKeys', function(plate)
    TriggerEvent('esx_vehiclekeys:client:AddKeys', plate)
end)

RegisterNetEvent('qb-vehiclekeys:client:RemoveKeys', function(plate)
    TriggerEvent('esx_vehiclekeys:client:RemoveKeys', plate)
end)

RegisterNetEvent('qb-vehiclekeys:client:ToggleEngine', function()
    TriggerEvent('esx_vehiclekeys:client:ToggleEngine')
end)

RegisterNetEvent('qb-vehiclekeys:client:GiveKeys', function(id)
    TriggerEvent('esx_vehiclekeys:client:GiveKeys', id)
end)

RegisterNetEvent('esx_vehiclekeys:client:UseLockpick', function(isAdvanced)
    UseLockpick(isAdvanced)
end)

RegisterNetEvent('lockpicks:UseLockpick', function(isAdvanced)
    UseLockpick(isAdvanced)
end)

RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate)
    TriggerServerEvent('esx_vehiclekeys:server:AcquireVehicleKeys', plate)
end)

-----------------------
----   Main Loop   ----
-----------------------
CreateThread(function()
    while true do
        local sleep = 1000

        if IsLoaded() then
            sleep = 250
            local ped = PlayerPedId()
            local entering = GetVehiclePedIsTryingToEnter(ped)

            if entering ~= 0 and not isBlacklistedVehicle(entering) then
                sleep = 1000
                HandleVehicleEntry(entering)
            end

            if IsPedInAnyVehicle(ped, false) and not isHotwiring then
                sleep = 500
                HandleHotwirePrompt(ped)
            end

            if Config.CarJackEnable and canCarjack then
                sleep = 250
                HandleCarjackPrompt(ped)
            end
        end

        Wait(sleep)
    end
end)

-----------------------
----   Functions   ----
-----------------------
function HandleVehicleEntry(entering)
    local plate = GetPlate(entering)
    if not plate then return end

    local driver = GetPedInVehicleSeat(entering, -1)
    local carIsImmune = false
    for _, veh in ipairs(Config.ImmuneVehicles) do
        if GetEntityModel(entering) == joaat(veh) then
            carIsImmune = true
            break
        end
    end

    if driver ~= 0 and not IsPedAPlayer(driver) and not HasKeys(plate) and not carIsImmune then
        if IsEntityDead(driver) then
            if isTakingKeys then return end
            isTakingKeys = true
            TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
            Progress(Lang:t('progress.takekeys'), 2500, nil, function()
                TriggerServerEvent('esx_vehiclekeys:server:AcquireVehicleKeys', plate)
                isTakingKeys = false
            end, function()
                isTakingKeys = false
            end)
        elseif Config.LockNPCDrivingCars then
            TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 2)
        else
            TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
            TriggerServerEvent('esx_vehiclekeys:server:AcquireVehicleKeys', plate)

            local pedsInVehicle = GetPedsInVehicle(entering)
            for _, pedInVehicle in pairs(pedsInVehicle) do
                if pedInVehicle ~= GetPedInVehicleSeat(entering, -1) then
                    MakePedFlee(pedInVehicle)
                end
            end
        end
    elseif driver == 0 and entering ~= lastPickedVehicle and not HasKeys(plate) and not isTakingKeys then
        ServerCallback('esx_vehiclekeys:server:checkPlayerOwned', function(playerOwned)
            if playerOwned then return end
            if Config.LockNPCParkedCars then
                TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 2)
            else
                TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(entering), 1)
            end
        end, plate)
    end
end

function HandleHotwirePrompt(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return end

    local plate = GetPlate(vehicle)
    if not plate then return end

    if GetPedInVehicleSeat(vehicle, -1) == ped and not HasKeys(plate) and not isBlacklistedVehicle(vehicle) and not AreKeysJobShared(vehicle) then
        local vehiclePos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.0, 0.5)
        DrawText3D(vehiclePos.x, vehiclePos.y, vehiclePos.z, Lang:t('info.skeys'))
        SetVehicleEngineOn(vehicle, false, false, true)

        if IsControlJustPressed(0, 74) then
            Hotwire(vehicle, plate)
        end
    end
end

function HandleCarjackPrompt(ped)
    local aiming, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if not aiming or not target or target == 0 then return end
    if not DoesEntityExist(target) or not IsPedInAnyVehicle(target, false) or IsEntityDead(target) or IsPedAPlayer(target) then return end

    local targetVehicle = GetVehiclePedIsIn(target, false)
    local carIsImmune = false
    for _, veh in ipairs(Config.ImmuneVehicles) do
        if GetEntityModel(targetVehicle) == joaat(veh) then
            carIsImmune = true
            break
        end
    end

    if GetPedInVehicleSeat(targetVehicle, -1) ~= target or IsBlacklistedWeapon() then return end
    if #(GetEntityCoords(ped, true) - GetEntityCoords(target, true)) >= 5.0 or carIsImmune then return end

    CarjackVehicle(target)
end

function isBlacklistedVehicle(vehicle)
    local isBlacklisted = false
    for _, model in ipairs(Config.NoLockVehicles) do
        if joaat(model) == GetEntityModel(vehicle) then
            isBlacklisted = true
            break
        end
    end

    if Entity(vehicle).state.ignoreLocks or GetVehicleClass(vehicle) == 13 then
        isBlacklisted = true
    end

    return isBlacklisted
end

function addNoLockVehicles(model)
    Config.NoLockVehicles[#Config.NoLockVehicles + 1] = model
end

exports('addNoLockVehicles', addNoLockVehicles)

function removeNoLockVehicles(model)
    for k, v in pairs(Config.NoLockVehicles) do
        if v == model then
            Config.NoLockVehicles[k] = nil
        end
    end
end

exports('removeNoLockVehicles', removeNoLockVehicles)

function OpenMenu()
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, Config.LockAnimSound, 0.3)
    SendNUIMessage({ casemenue = 'open' })
    SetNuiFocus(true, true)
end

function ToggleEngine(veh)
    if not veh or veh == 0 then return end
    if isBlacklistedVehicle(veh) then return end
    if not HasKeys(GetPlate(veh)) and not AreKeysJobShared(veh) then return end

    SetVehicleEngineOn(veh, not GetIsVehicleEngineRunning(veh), true, true)
end

function ToggleVehicleLocksWithoutNui(veh)
    if not veh or veh == 0 then
        Notify(Lang:t('notify.vehclose'), 'error')
        return
    end

    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    if not HasKeys(GetPlate(veh)) and not AreKeysJobShared(veh) then
        Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    local ped = PlayerPedId()
    local lockStatus = GetVehicleDoorLockStatus(veh)
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    local object = 0

    if currentVehicle == 0 then
        if Config.LockToggleAnimation.Prop then
            object = CreateObject(joaat(Config.LockToggleAnimation.Prop), 0.0, 0.0, 0.0, true, true, true)
            while not DoesEntityExist(object) do Wait(1) end
            AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, Config.LockToggleAnimation.PropBone), 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        end

        loadAnimDict(Config.LockToggleAnimation.AnimDict)
        TaskPlayAnim(ped, Config.LockToggleAnimation.AnimDict, Config.LockToggleAnimation.Anim, 8.0, -8.0, -1, 52, 0, false, false, false)
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5.0, Config.LockAnimSound, 0.5)
    end

    CreateThread(function()
        if currentVehicle == 0 then Wait(Config.LockToggleAnimation.WaitTime) end
        if IsEntityPlayingAnim(ped, Config.LockToggleAnimation.AnimDict, Config.LockToggleAnimation.Anim, 3) then
            StopAnimTask(ped, Config.LockToggleAnimation.AnimDict, Config.LockToggleAnimation.Anim, 8.0)
        end
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 5.0, Config.LockToggleSound, 0.3)

        if object ~= 0 and DoesEntityExist(object) then
            DeleteObject(object)
        end
    end)

    NetworkRequestControlOfEntity(veh)
    if lockStatus == 1 or lockStatus == 0 then
        TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 2)
        Notify(Lang:t('notify.vlock'), 'info')
    else
        TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        Notify(Lang:t('notify.vunlock'), 'success')
    end

    FlashVehicleLights(veh)
    ClearPedTasks(ped)
end

function GiveKeys(id, plate)
    local targetPlayer = GetPlayerFromServerId(id)
    if targetPlayer == -1 then
        Notify(Lang:t('notify.nonear'), 'error')
        return
    end

    local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(GetPlayerPed(targetPlayer)))
    if distance <= 0.0 or distance >= 1.5 then
        Notify(Lang:t('notify.nonear'), 'error')
        return
    end

    TriggerServerEvent('esx_vehiclekeys:server:GiveVehicleKeys', id, plate)
end

function GetKeys()
    ServerCallback('esx_vehiclekeys:server:GetVehicleKeys', function(keysList)
        KeysList = keysList or {}
    end)
end

function HasKeys(plate)
    return plate and KeysList[plate] == true
end

exports('HasKeys', HasKeys)

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(0)
    end
end

function GetVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and vehicle ~= 0 then return vehicle end

    local pos = GetEntityCoords(ped)
    vehicle = GetClosestVehicle(pos)
    if not vehicle or vehicle == 0 then return nil end
    if #(pos - GetEntityCoords(vehicle)) > Config.LockToggleDist then return nil end
    if not IsEntityAVehicle(vehicle) then return nil end

    return vehicle
end

function AreKeysJobShared(veh)
    local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    local vehiclePlate = GetPlate(veh)
    local job = GetPlayerJob()
    local shared = Config.SharedKeys[job.name or '']
    if not shared then return false end

    local onDuty = job.onDuty
    if onDuty == nil then onDuty = job.onduty end
    if onDuty == nil then onDuty = job.duty end
    if shared.requireOnduty and not onDuty then return false end

    for _, vehicle in pairs(shared.vehicles) do
        if string.upper(vehicle) == string.upper(vehicleName) then
            if not HasKeys(vehiclePlate) then
                TriggerServerEvent('esx_vehiclekeys:server:AcquireVehicleKeys', vehiclePlate)
            end
            return true
        end
    end

    return false
end

function ToggleVehicleLocks(veh)
    ToggleVehicleLocksWithoutNui(veh)
end

function ToggleVehicleunLocks(veh)
    if not veh or veh == 0 then return end
    if isBlacklistedVehicle(veh) then
        TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
        return
    end

    if not HasKeys(GetPlate(veh)) and not AreKeysJobShared(veh) then
        Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    NetworkRequestControlOfEntity(veh)
    TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
    Notify(Lang:t('notify.vunlock'), 'success')
    FlashVehicleLights(veh)
end

function ToggleVehicleTrunk(veh)
    if not veh or veh == 0 then return end
    if isBlacklistedVehicle(veh) then return end
    if not HasKeys(GetPlate(veh)) and not AreKeysJobShared(veh) then
        Notify(Lang:t('notify.ydhk'), 'error')
        return
    end

    local boot = GetEntityBoneIndexByName(veh, 'boot')
    if boot == -1 or not DoesEntityExist(veh) then return end

    FlashVehicleLights(veh)
    if trunkClose then
        SetVehicleDoorOpen(veh, 5, false, false)
    else
        SetVehicleDoorShut(veh, 5, false)
    end
    trunkClose = not trunkClose
    ClearPedTasks(PlayerPedId())
end

function GetOtherPlayersInVehicle(vehicle)
    local otherPeds = {}
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if IsPedAPlayer(pedInSeat) and pedInSeat ~= PlayerPedId() then
            otherPeds[#otherPeds + 1] = pedInSeat
        end
    end
    return otherPeds
end

function GetPedsInVehicle(vehicle)
    local otherPeds = {}
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
        if not IsPedAPlayer(pedInSeat) and pedInSeat ~= 0 then
            otherPeds[#otherPeds + 1] = pedInSeat
        end
    end
    return otherPeds
end

function IsBlacklistedWeapon()
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    if not weapon then return false end

    for _, blockedWeapon in pairs(Config.NoCarjackWeapons) do
        if weapon == joaat(blockedWeapon) then
            return true
        end
    end

    return false
end

function Hotwire(vehicle, plate)
    if isHotwiring then return end

    local hotwireTime = math.random(Config.minHotwireTime, Config.maxHotwireTime)
    isHotwiring = true
    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, hotwireTime)

    Progress(Lang:t('progress.hskeys'), hotwireTime, {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        name = 'machinic_loop_mechandplayer',
        flags = 16,
    }, function()
        if math.random() <= Config.HotwireChance then
            TriggerServerEvent('esx_vehiclekeys:server:AcquireVehicleKeys', plate)
        else
            Notify(Lang:t('notify.fvlockpick'), 'error')
        end

        Wait(Config.TimeBetweenHotwires)
        isHotwiring = false
    end, function()
        isHotwiring = false
    end)

    SetTimeout(10000, function()
        AttemptPoliceAlert('steal')
    end)
end

function CarjackVehicle(target)
    if not Config.CarJackEnable or isCarjacking then return end

    isCarjacking = true
    canCarjack = false
    loadAnimDict('mp_am_hold_up')

    local vehicle = GetVehiclePedIsUsing(target)
    local occupants = GetPedsInVehicle(vehicle)
    for p = 1, #occupants do
        local ped = occupants[p]
        CreateThread(function()
            TaskPlayAnim(ped, 'mp_am_hold_up', 'holdup_victim_20s', 8.0, -8.0, -1, 49, 0, false, false, false)
            PlayPain(ped, 6, 0)
            FreezeEntityPosition(vehicle, true)
            SetVehicleUndriveable(vehicle, true)
        end)
        Wait(math.random(200, 500))
    end

    CreateThread(function()
        while isCarjacking do
            local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(target))
            if IsPedDeadOrDying(target, true) or distance > 7.5 then
                FreezeEntityPosition(vehicle, false)
                SetVehicleUndriveable(vehicle, false)
                isCarjacking = false
                canCarjack = true
            end
            Wait(100)
        end
    end)

    Progress(Lang:t('progress.acjack'), Config.CarjackingTime, nil, function()
        local hasWeapon, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
        if not hasWeapon or not isCarjacking then return end

        local carjackChance = Config.CarjackChance[tostring(GetWeapontypeGroup(weaponHash))] or 0.5
        if math.random() <= carjackChance then
            local plate = GetPlate(vehicle)
            for p = 1, #occupants do
                local ped = occupants[p]
                CreateThread(function()
                    FreezeEntityPosition(vehicle, false)
                    SetVehicleUndriveable(vehicle, false)
                    TaskLeaveVehicle(ped, vehicle, 0)
                    PlayPain(ped, 6, 0)
                    Wait(1250)
                    ClearPedTasksImmediately(ped)
                    PlayPain(ped, math.random(7, 8), 0)
                    MakePedFlee(ped)
                end)
            end
            TriggerServerEvent('esx_vehiclekeys:server:AcquireVehicleKeys', plate)
        else
            Notify(Lang:t('notify.cjackfail'), 'error')
            FreezeEntityPosition(vehicle, false)
            SetVehicleUndriveable(vehicle, false)
            MakePedFlee(target)
        end

        isCarjacking = false
        Wait(2000)
        AttemptPoliceAlert('carjack')
        Wait(Config.DelayBetweenCarjackings)
        canCarjack = true
    end, function()
        MakePedFlee(target)
        isCarjacking = false
        Wait(Config.DelayBetweenCarjackings)
        canCarjack = true
    end)
end

function UseLockpick(isAdvanced)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(pos)

    if not vehicle or vehicle == 0 then return end
    local plate = GetPlate(vehicle)
    if HasKeys(plate) then return end
    if #(pos - GetEntityCoords(vehicle)) > 2.5 then return end
    if GetVehicleDoorLockStatus(vehicle) <= 0 then return end

    local duration = isAdvanced and Config.AdvancedLockpickTime or Config.LockpickTime
    local successChance = isAdvanced and Config.AdvancedLockpickSuccessChance or Config.LockpickSuccessChance
    local itemName = isAdvanced and 'advancedlockpick' or 'lockpick'

    Progress(Lang:t('progress.picklock'), duration, nil, function()
        local success = math.random() <= successChance
        local chance = math.random()

        if success then
            lastPickedVehicle = vehicle
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                TriggerServerEvent('esx_vehiclekeys:server:AcquireVehicleKeys', plate)
            else
                Notify(Lang:t('notify.vlockpick'), 'success')
                TriggerServerEvent('esx_vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), 1)
            end
        else
            AttemptPoliceAlert('steal')
        end

        local threshold = isAdvanced and Config.RemoveLockpickAdvanced or Config.RemoveLockpickNormal
        if chance <= threshold then
            TriggerServerEvent('esx_vehiclekeys:server:breakLockpick', itemName)
        end
    end)
end

function AttemptPoliceAlert(alertType)
    if alertSent then return end

    local chance = Config.PoliceAlertChance
    local hour = GetClockHours()
    if hour >= 1 and hour <= 6 then
        chance = Config.PoliceNightAlertChance
    end

    if math.random() <= chance then
        TriggerServerEvent('esx_vehiclekeys:server:PoliceAlert', Lang:t('info.palert') .. alertType)
    end

    alertSent = true
    SetTimeout(Config.AlertCooldown, function()
        alertSent = false
    end)
end

function MakePedFlee(ped)
    SetPedFleeAttributes(ped, 0, 0)
    TaskReactAndFleePed(ped, PlayerPedId())
end

function FlashVehicleLights(veh)
    SetVehicleLights(veh, 2)
    Wait(250)
    SetVehicleLights(veh, 1)
    Wait(200)
    SetVehicleLights(veh, 0)
    Wait(300)
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-----------------------
----   NUICallback ----
-----------------------
RegisterNUICallback('closui', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('unlock', function(_, cb)
    ToggleVehicleunLocks(GetVehicle())
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('lock', function(_, cb)
    ToggleVehicleLocks(GetVehicle())
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('trunk', function(_, cb)
    ToggleVehicleTrunk(GetVehicle())
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('engine', function(_, cb)
    ToggleEngine(GetVehicle())
    SetNuiFocus(false, false)
    cb({ ok = true })
end)
