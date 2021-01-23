

	-- draw FG clouds
	fillp(0b0101101001011010.1)
	local cc = 7
	for i=0,#clouds/2 do
		local c = clouds[i]
		local s = c.s * 1.5
		local x = c.x % (128 + s) - s / 2
		local y = 129
		clip(x - s / 2, y - s / 2, s, s / 2)
		circfill(x, y, s / 3, cc)
		if (i % 2 == 0) then
			circfill(x - s / 3, y, s / 5, cc)
		end
		if (i % 2 == 0) then
			circfill(x + s / 3, y, s / 6, cc)
		end
		c.x += (4 - i % 4) * 0.25
	end
	clip(0,0,128,128)
	fillp()