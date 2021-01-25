
## Classic Celeste 2
Made in 3 days for [Celeste's](https://celestegame.com) 3rd anniversary.
A sequel to [Celeste Classic](https://mattmakesgames.itch.io/celesteclassic)

## Files
 - `celeste2.p8`: The final cartridge that gets published
 - `core.p8`: Used for adding content (gfx/sfx) and prototyping gameplay.
 - `1.p8`,`2.p8`,N: Individual levels
 - `_packer.p8`: Takes all the individual levels, compresses them, and places them in `celeste2`
 - `_updater.p8`: Takes the gfx/sfx from `core` and places them into `celeste2` and each level cartridge
 - `sfx.txt`: Sound FX information

After modifying a level and running the `_packer`, you must update the respective level offset in `gamestate.lua` for it to load from the main cartridge correctly. this could be automated but we ran out of time!

## Credits
 - [Maddy Thorson](https://twitter.com/maddythorson) (level design, coding)
 - [Noel Berry](https://twitter.com/noelfb) (art, coding)
 - [Lena Raine](https://twitter.com/kuraine) (sound, music)
 - [Kevin Regamey](https://twitter.com/regameyk) (testing)