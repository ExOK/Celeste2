pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

#include gamestate.lua

function _init()
	cls()

	-- copy gfx data over
	reload(0x0, 0x0, 0x1000, "core.p8")
	cstore(0x0, 0x0, 0x1000, "celeste2.p8")

	index = 1
	for lvl in all(levels) do
		cstore(0x0, 0x0, 0x1000, index .. ".p8")
		print("updated gfx in lvl "..index)
		index += 1
	end

	-- copy flags / song / sfx
	reload(0x3000, 0x3000, 0x4300 - 0x3000, "core.p8")
	cstore(0x3000, 0x3000, 0x4300 - 0x3000, "celeste2.p8")

	index = 1
	for lvl in all(levels) do
		cstore(0x3000, 0x3000, 0x4300 - 0x3000, index .. ".p8")
		print("updated sfx in lvl "..index)
		index += 1
	end

	print("done!")

end
