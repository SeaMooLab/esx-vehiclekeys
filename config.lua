Config = {}

-- Key System Settings
Config.PersistentKeys = true -- Uses ESX xPlayer metadata when available.

-- Vehicle lock settings
Config.LockToggleAnimation = {
    AnimDict = 'anim@mp_player_intmenu@key_fob@',
    Anim = 'fob_click',
    Prop = 'prop_cuff_keys_01',
    PropBone = 57005,
    WaitTime = 500,
}
Config.LockAnimSound = 'keys'
Config.LockToggleSound = 'lock'
Config.LockToggleDist = 8.0
Config.UseKeyfob = false

-- NPC Vehicle Lock States
Config.LockNPCDrivingCars = true
Config.LockNPCParkedCars = true

-- Lockpick Settings
-- 'auto' skips ESX.RegisterUsableItem when this ESX build is using the qs-inventory bridge,
-- because that bridge calls qs-inventory:CreateUsableItem and some QS builds do not export it.
-- Use 'esx' to force ESX.RegisterUsableItem, or false to disable automatic registration.
Config.RegisterLockpickUsableItems = 'auto'
Config.RemoveLockpickNormal = 0.5
Config.RemoveLockpickAdvanced = 0.2
Config.LockpickSuccessChance = 0.55
Config.AdvancedLockpickSuccessChance = 0.75
Config.LockpickTime = 7500
Config.AdvancedLockpickTime = 4500
Config.LockpickAnimation = {
    dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    name = 'machinic_loop_mechandplayer',
    flags = 49,
}
Config.UseESXProgressbar = true
Config.RequireLockpickForSearchKeys = true
Config.LockpickedSearchGuaranteesKeys = true

-- Carjack Settings
Config.CarJackEnable = true
Config.CarjackingTime = 7500
Config.DelayBetweenCarjackings = 10000
Config.CarjackChance = {
    ['2685387236'] = 0.0,
    ['416676503'] = 0.5,
    ['-957766203'] = 0.75,
    ['860033945'] = 0.90,
    ['970310034'] = 0.90,
    ['1159398588'] = 0.99,
    ['3082541095'] = 0.99,
    ['2725924767'] = 0.99,
    ['1548507267'] = 0.0,
    ['4257178988'] = 0.0,
}

-- Hotwire Settings
Config.HotwireChance = 0.5
Config.TimeBetweenHotwires = 5000
Config.minHotwireTime = 20000
Config.maxHotwireTime = 40000

-- Police Alert Settings
Config.AlertCooldown = 10000
Config.PoliceAlertChance = 0.75
Config.PoliceNightAlertChance = 0.50
Config.PoliceJobs = {
    police = true,
    sheriff = true,
}

-- Job Settings
Config.SharedKeys = {
    police = {
        requireOnduty = false,
        vehicles = {
            'police',
            'police2',
        }
    },

    mechanic = {
        requireOnduty = false,
        vehicles = {
            'towtruck',
        }
    }
}

-- These vehicles cannot be jacked
Config.ImmuneVehicles = {
    'stockade'
}

-- These vehicles will never lock
Config.NoLockVehicles = {}

-- These weapons cannot be used for carjacking
Config.NoCarjackWeapons = {
    'WEAPON_UNARMED',
    'WEAPON_Knife',
    'WEAPON_Nightstick',
    'WEAPON_HAMMER',
    'WEAPON_Bat',
    'WEAPON_Crowbar',
    'WEAPON_Golfclub',
    'WEAPON_Bottle',
    'WEAPON_Dagger',
    'WEAPON_Hatchet',
    'WEAPON_KnuckleDuster',
    'WEAPON_Machete',
    'WEAPON_Flashlight',
    'WEAPON_SwitchBlade',
    'WEAPON_Poolcue',
    'WEAPON_Wrench',
    'WEAPON_Battleaxe',
    'WEAPON_Grenade',
    'WEAPON_StickyBomb',
    'WEAPON_ProximityMine',
    'WEAPON_BZGas',
    'WEAPON_Molotov',
    'WEAPON_FireExtinguisher',
    'WEAPON_PetrolCan',
    'WEAPON_Flare',
    'WEAPON_Ball',
    'WEAPON_Snowball',
    'WEAPON_SmokeGrenade',
}
