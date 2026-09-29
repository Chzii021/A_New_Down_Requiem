# Asset credits

## Tree Collection — NicolasBrueckner

Collection: https://poly.pizza/bundle/Tree-Collection-zdry8l7ugJ

License: Creative Commons Attribution 3.0 Unported (CC BY 3.0)
https://creativecommons.org/licenses/by/3.0/

- Simple Tree: https://poly.pizza/m/WgTSzX9vyk
- Stylized Tree: https://poly.pizza/m/iF4wZr2dWd
- Birch Tree: https://poly.pizza/m/5vv8rSYAv1
- Pine Tree: https://poly.pizza/m/Y4G4XmtNbt

Models are bundled as native Godot scenes in `models/trees/`, with embedded
meshes and ImageTextures to avoid external import dependencies. This demo adjusts their
placement, rotation, scale, and material tint in Godot. Mesh geometry and texture artwork are retained; the storage format is converted. NicolasBrueckner does not endorse
this adaptation.

## Worker — Quaternius

https://poly.pizza/m/Yg2bQZO6Hj

License: CC0 / public domain, as listed on the source page.
https://creativecommons.org/publicdomain/zero/1.0/

The Worker skeleton and locomotion clips are retained as the motion source.
CharacterV2 builds new faceted character and weapon geometry in `VikramRig.gd`;
the source body meshes are hidden at runtime. Arm poses use analytic two-bone IK
with separate rifle and pistol grip targets. Locomotion clips have looping enabled,
and shooting recoil is layered over locomotion. See `Vikram.tscn`.

## Village scenery

Terrain, road, distant mountains, sky setup, rice fields, bamboo fences, houses,
props, and wind effects were created for this demo. Character appearance is based
on the reference supplied by the user.


## NPC and interface additions

The four villagers, grandmother variant, woven motifs, baskets, scarf, shoulder bag, procedural animations, spirit release effect and Isan HUD were built as native Godot geometry and UI for this demo using the user-provided character image as visual reference. The NPC geometry reuses procedural mesh helpers from VikramRig.gd; it does not use the Worker skeleton.

## Pixel UI font

Pixelify Sans by The Pixelify Sans Project Authors:
https://github.com/google/fonts/tree/main/ofl/pixelifysans

Licensed under the SIL Open Font License 1.1. The license is bundled at `fonts/OFL.txt`.
The font is used for Latin headings and HUD numbers.

GNU Unifont 17.0.04 by the GNU Unifont contributors supplies pixel-style Thai glyphs:
https://ftp.gnu.org/gnu/unifont/unifont-17.0.04/

Licensed under the SIL Open Font License 1.1. The license is bundled at
`fonts/Unifont-OFL-1.1.txt`. `PixelFont.gd` uses it as the Thai fallback font.

## Audio

The seven `*_original.wav` files in `audio/` are original procedural audio created for this demo. The music, gunshot, villager-hit, spirit-release, reload and anvil MP3 files were supplied by the user. `gunshot_custom.wav` and `hit_custom.wav` trim the delayed starts of their source MP3s. `reload_custom.wav` is timed to the one-second animation. `craft_custom.wav` contains only the first anvil strike. Licensing of the supplied audio was not independently verified. See `audio/README.md` for replacement filenames.
