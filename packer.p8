pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

#include gamestate.lua
#include px9_comp.lua

function _init()
	cls()
	offset = 0
	index = 1

	-- pack each level
	for lvl in all(levels) do

		-- load level map into our map
		reload(0x2000, 0x2000, 0x1000, index .. ".p8")

		-- compress data, store in ram
		clen = px9_comp(0, 0, lvl.width, lvl.height, 0x4300, mget)

		-- store that packed data into the main cart
		cstore(0x1000 + offset, 0x4300, clen, "celeste2.p8")

		-- move along
		print("packed ".. index .." at " .. offset)
		offset += clen
		index += 1
	end
end
