
function compress(level)
	local w = level.width
	local h = level.height
	cls()
	print("compressing..",5)
	flip()
	raw_size = (w*h+1)/2
	clen = px9_comp(0,0,w,h,0x2000 + 2048 + 256,mget)
	cstore()
end