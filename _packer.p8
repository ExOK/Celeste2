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

		-- load level map into our cart
		reload(0x1000, 0x2000, 0x1000, index .. ".p8")

		-- pretty tall!
		if lvl.height > 32 then
			reload(0x2000, 0x1000, 0x1000, index .. ".p8")
		end

		-- compress data, store over sprite data
		local function at(x, y) return peek(0x1000 + x + y * 128) end
		clen = px9_comp(0, 0, lvl.width, lvl.height, 0x0000, at)

		if clen > 0x1000 then
			print("level " .. index .. " is too big!")
		else
			-- store that packed data into the main cart
			cstore(0x1000 + offset, 0x0000, clen, "celeste2.p8")
			print("packed ".. index .." at " .. offset)
		end

		-- move along
		offset += clen
		index += 1
	end
end
