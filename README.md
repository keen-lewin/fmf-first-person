# Flesh Made Fear - First Person Mod

By [heuristickhorana](https://www.nexusmods.com/profile/heuristickhorana).

Replaces the game's fixed/locked camera angles with a first-person camera at the character's head; the view follows the direction the character faces (mouse turns the character, as usual in this fixed-camera game). Toggle with **F** (configurable). Look up/down with **PageUp**/**PageDown** (10° per press, clamped to ±45°. The game swallows the mouse's vertical axis, so no mouse-look is possible). Works on the PC (Windows/Proton) Release Edition via [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases) (game runs Unreal Engine 5.4; requires the `experimental-latest` UE4SS build, tested with `UE4SS_v3.0.1-1140-gf58e8f84`).

## Install

1. Download `UE4SS_v3.0.1-1140-gf58e8f84.zip` from the *experimental-latest* release at the link above.
   (The stable v3.0.1 build fails to signature-scan this game; the experimental build works.)
2. From the **UE4SS zip**, copy `UE4SS.dll`, `dwmapi.dll` and `UE4SS-settings.ini` into `<game>/Flesh_Made_Fear/Binaries/Win64/`.
3. From the **UE4SS zip**, copy the `Mods` folder into `<game>/Flesh_Made_Fear/Binaries/Win64/` too (UE4SS looks for mods next to the DLL on this game).
4. From the **mod zip** (`FirstPerson_v*.zip`), copy the `FirstPerson` folder into `<game>/Flesh_Made_Fear/Binaries/Win64/Mods/`.
5. Add this line to `<game>/Flesh_Made_Fear/Binaries/Win64/Mods/mods.txt`:
   ```
   FirstPerson : 1
   ```
6. Launch the game.

Your `Binaries/Win64` should end up looking like this:

```
<game>/Flesh_Made_Fear/Binaries/Win64/
├── Flesh_Made_Fear-Win64-Shipping.exe
├── UE4SS.dll                       (from the UE4SS zip)
├── dwmapi.dll                      (from the UE4SS zip)
├── UE4SS-settings.ini              (from the UE4SS zip)
└── Mods/
    ├── mods.txt                    (add: FirstPerson : 1)
    ├── shared/ …                   (from the UE4SS zip)
    └── FirstPerson/                (this mod)
        ├── settings.txt
        └── Scripts/
            └── main.lua
```

### Linux / Proton

Wine ships `dwmapi` as a builtin and ignores the local proxy DLL unless told otherwise. In Steam: right-click the game → Properties → Launch Options:

```
WINEDLLOVERRIDES="dwmapi=n,b" %command%
```

## Configuration

Edit `Mods/FirstPerson/settings.txt` (restart the game, or press `Ctrl+R` in-game if hot reload is on in `UE4SS-settings.ini`):

| Setting | Default | Meaning |
|---|---|---|
| `ToggleKey` | `F` | Key that toggles first/third person (any UE4SS `Key.*` name, e.g. `G`, `TAB`, `Q`) |
| `EyeHeight` | `90` | Camera height above the pawn, in cm |
| `ForwardOffset` | `45` | Pushes the camera in front of the head so hair/face doesn't block the view, in cm |
| `FieldOfView` | `95` | FOV in degrees |
| `StartFirstPerson` | `1` | `1` = first person on load, `0` = game's normal camera on load |
| `PitchUpKey` | `PAGE_UP` | Key that tilts the view up 10° per press (any UE4SS `Key.*` name) |
| `PitchDownKey` | `PAGE_DOWN` | Key that tilts the view down 10° per press (any UE4SS `Key.*` name) |

## Caveats

- The game was designed around fixed camera positions, so some things may not work or may look off in first person.
- Cutscenes also play in first person, so you may miss things the developers intended to show you through carefully framed camera angles.
- Blood loss is not visible in first person: the game shows bleeding by the character model visibly losing blood, and you can't see your own body in first person.

## Uninstall

Remove the `FirstPerson` folder and its line in `mods.txt`. Remove the UE4SS files to fully revert; nothing else is modified.
