local Translations = {
    notify = {
        ydhk = 'You don\'t have keys to this vehicle.',
        nonear = 'There is nobody nearby to hand keys to.',
        vlock = 'Vehicle locked!',
        vunlock = 'Vehicle unlocked!',
        vlockpick = 'You managed to pick the door lock open!',
        fvlockpick = 'You fail to find the keys and get frustrated.',
        vgkeys = 'You hand over the keys.',
        vgetkeys = 'You get keys to the vehicle!',
        fpid = 'Fill out the player ID and Plate arguments.',
        cjackfail = 'Carjacking failed!',
        vehclose = 'There\'s no close vehicle!',
        no_permission = 'You do not have permission to use this command.',
        broke_lockpick = 'Your lockpick broke.',
    },
    progress = {
        takekeys = 'Taking keys from body...',
        hskeys = 'Searching for the car keys...',
        acjack = 'Attempting Carjacking...',
        picklock = 'Lockpicking vehicle...',
    },
    info = {
        skeys = '~g~[H]~w~ - Search for Keys',
        tlock = 'Toggle Vehicle Locks',
        palert = 'Vehicle theft in progress. Type: ',
        engine = 'Toggle Engine',
    },
    addcom = {
        givekeys = 'Hand over the keys to someone. If no ID, gives to closest person or everyone in the vehicle.',
        givekeys_id = 'id',
        givekeys_id_help = 'Player ID',
        addkeys = 'Adds keys to a vehicle for someone.',
        addkeys_id = 'id',
        addkeys_id_help = 'Player ID',
        addkeys_plate = 'plate',
        addkeys_plate_help = 'Plate',
        rkeys = 'Remove keys to a vehicle for someone.',
        rkeys_id = 'id',
        rkeys_id_help = 'Player ID',
        rkeys_plate = 'plate',
        rkeys_plate_help = 'Plate',
    },
}

local function translate(path)
    local node = Translations
    for part in string.gmatch(path, '[^%.]+') do
        if type(node) ~= 'table' then return path end
        node = node[part]
        if node == nil then return path end
    end
    return node
end

Lang = Lang or {}
function Lang:t(path)
    return translate(path)
end
