-- globals
objects = {}
snow = {}
clouds = {}
infade = 0
freeze_time = 0
frames = 0
shake = 0

function _init()

	for i=0,25 do
		snow[i] = { x = rnd(132), y = rnd(132) }
	end
	for i=0,25 do
		clouds[i] = { x = rnd(132), y = rnd(132), s = 16 + rnd(32) }
	end

	on_start_level(1)
	load()
end

function _update()

	-- timers
	frames += 1

	-- screenshake
	shake -= 1

	update_input()

	--freeze
	if (freeze_time > 0) then
		freeze_time -= 1
	else
		--objects
		for o in all(objects) do
			o:update()
			if (o.destroyed) then
				del(objects, o)
			end
		end
	end

	infade += 1
end

function _draw()

	local camera_x = peek2(0x5f28)
	local camera_y = peek2(0x5f2a)

	if shake > 0 then
		camera(camera_x - 2 + rnd(5),camera_y - 2 + rnd(5))
	end

	-- clear screen
	cls(0)

	-- draw clouds
	local cc = 13
	for i=0,#clouds do
		local c = clouds[i]
		local x = camera_x + (c.x - camera_x * 0.9) % (128 + c.s) - c.s / 2
		local y = camera_y + (c.y - camera_y * 0.9) % (128 + c.s / 2)
		clip(x - c.s / 2 - camera_x, y - c.s / 2 - camera_y, c.s, c.s / 2)
		circfill(x, y, c.s / 3, cc)
		if (i % 2 == 0) then
			circfill(x - c.s / 3, y, c.s / 5, cc)
		end
		if (i % 2 == 0) then
			circfill(x + c.s / 3, y, c.s / 6, cc)
		end
		c.x += (4 - i % 4) * 0.25
	end
	clip(0,0,128,128)

	-- draw tileset
	for x=0,96 do
		for y=0,16 do
			local tile = tile_at(x, y)
			if (tile != 0 and fget(tile, 0)) then
				spr(tile, x * 8, y * 8)
			end
		end
	end

	-- draw objects
	local p = nil
	for o in all(objects) do
		if (o.base == player) then p = o else o:draw() end
	end
	if (p) then p:draw() end

	-- draw snow
	for i=1,#snow do
		local s = snow[i]
		circfill(camera_x + (s.x - camera_x * 0.5) % 132 - 2, camera_y + (s.y - camera_y * 0.5) % 132, i % 2, 7)
		s.x += (4 - i % 4)
		s.y += sin(time() * 0.25 + i * 0.1)
	end

	-- screen wipes
	-- very similar functions ... can they be compressed into one?
	if (p ~= nil and p.dead_timer > 5) then
		local e = (p.dead_timer - 5) / 12
		for i=0,127 do
			s = (127 + 64) * e - 32 + sin(i * 0.2) * 16 + (127 - i) * 0.25
			rectfill(camera_x,camera_y+i,camera_x+s,camera_y+i,0)
		end
	end

	if (infade < 15) then
		local e = infade / 12
		for i=0,127 do
			s = (127 + 64) * e - 32 + sin(i * 0.2) * 16 + (127 - i) * 0.25
			rectfill(camera_x+s,camera_y+i,camera_x+128,camera_y+i,0)
		end
	end

	-- game timer
	if (infade < 45) then
		draw_time(camera_x + 4, camera_y + 4)
	end

	-- debug
	if (false) do
		for o in all(objects) do
			rect(o.x + o.hit_x, o.y + o .hit_y, o.x + o.hit_x + o.hit_w - 1, o.y + o.hit_y + o.hit_h - 1, 8)
		end

		camera(0, 0)
		print("cpu: " .. flr(stat(1) * 100) .. "/100", 9, 9, 8)
		print("mem: " .. flr(stat(0)) .. "/2048", 9, 15, 8)
	end

	camera(camera_x, camera_y)
end

function draw_time(x,y)
	local ts = flr(frames / 30)
	local s = ts % 60
	local m = flr(ts / 60) % 60
	local h = flr(flr(ts / 60) / 60)
	
	rectfill(x,y,x+32,y+6,0)
	print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(s<10 and "0"..s or s),x+1,y+1,7)
end

-- gets the tile at the given location in the CURRENT room
function tile_at(x, y)
	if (raw_level) then
		return mget(x, y)
	else
		return peek(0x4300 + (x % 128) + y * 128)
	end
end

-- loads the given room
function load()
	on_restart_level()

	objects = {}
	infade = 0
	camera(0, 0)

	local function vget(x, y)
		return peek(0x4300 + (x % 128) + y * 128)
	end
	local function vset(x, y, v)
		return poke(0x4300 + (x % 128) + y * 128, v)
	end

	px9_decomp(0, 0, 0x2000, vget, vset)

	for i = 0,level.width-1 do
		for j = 0,level.height-1 do
			for n=1,#types do
				if (tile_at(i, j) == types[n].tile) then
					create(types[n], i * 8, j * 8)
				end
			end
		end
	end
end

function approach(x, target, max_delta)
	if (x < target) then
		return min(x + max_delta, target)
	else
		return max(x - max_delta, target)
	end
end

function draw_sine_h(x0, x1, y, col, amplitude, time_freq, x_freq, fade_x_dist)
	pset(x0, y, col)
	pset(x1, y, col)

	local x_sign = sgn(x1 - x0)
	local x_max = abs(x1 - x0) - 1
	local last_y = y
	local this_y = 0
	local ax = 0
	local ay = 0
	local fade = 1

	for i = 1, x_max do
		
		if (i <= fade_x_dist) then
			fade = i / (fade_x_dist + 1)
		elseif (i > x_max - fade_x_dist + 1) then
			fade = (x_max + 1 - i) / (fade_x_dist + 1)
		else
			fade = 1
		end

		ax = x0 + i * x_sign
		ay = y + sin(time() * time_freq + i * x_freq) * amplitude * fade
		pset(ax, ay, col)

		this_y = ay
		while (abs(ay - last_y) > 1) do
			ay -= sgn(this_y - last_y)
			pset(ax - x_sign, ay, col)
		end
		last_y = this_y
	end
end