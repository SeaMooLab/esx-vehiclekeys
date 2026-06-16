from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LUA_FILES = [ROOT / 'client.lua', ROOT / 'server.lua', ROOT / 'config.lua', ROOT / 'locales' / 'en.lua']
TEXT_FILES = LUA_FILES + [ROOT / 'fxmanifest.lua', ROOT / 'NUI' / 'script.js', ROOT / 'NUI' / 'index.html']

FORBIDDEN = [
    'exports[\'qb-core\']',
    'exports["qb-core"]',
    'QBCore.Functions',
    'QBCore.Commands',
    'qb-inventory',
    'qb-minigames',
    'QBCore:Notify',
    'PlayerData.citizenid',
]

REQUIRED = {
    'fxmanifest.lua': ['dependency \'es_extended\'', "client_script 'client.lua'", "server_script 'server.lua'"],
    'client.lua': ["exports['es_extended']:getSharedObject()", 'ESX.TriggerServerCallback', 'RegisterNetEvent(\'esx:playerLoaded\''],
    'server.lua': ["exports['es_extended']:getSharedObject()", 'ESX.RegisterServerCallback', 'ShouldRegisterUsableLockpickItems', "ESX.GetConfig('CustomInventory')", "xPlayer.getMeta()", "xPlayer.setMeta('vehicleKeys', plate, true)", "xPlayer.clearMeta('vehicleKeys', plate)"],
    'NUI/script.js': ['GetParentResourceName()', "postAction('closui')"],
    'config.lua': ["Config.RegisterLockpickUsableItems = 'auto'"],
}



def main() -> None:
    combined = '\n'.join(path.read_text(encoding='utf-8') for path in TEXT_FILES)
    for forbidden in FORBIDDEN:
        assert forbidden not in combined, f'Forbidden QBCore artifact remained: {forbidden}'

    for relative, needles in REQUIRED.items():
        text = (ROOT / relative).read_text(encoding='utf-8')
        for needle in needles:
            assert needle in text, f'Missing required marker in {relative}: {needle}'

    for path in LUA_FILES:
        text = path.read_text(encoding='utf-8')
        assert text.count('function') >= text.count('RegisterNetEvent'), f'{path}: suspiciously few function blocks'
        assert text.count('(') == text.count(')'), f'{path}: unbalanced parentheses'

    print('static checks passed')


if __name__ == '__main__':
    main()
