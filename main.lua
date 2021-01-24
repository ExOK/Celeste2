-- globals
level_index = 0
objects = {}
snow = {}
clouds = {}
infade = 0
freeze_time = 0
frames = 0
shake = 0

function game_start()
	
	for i=0,25 do snow[i] = { x = rnd(132), y = rnd(132) } end
	for i=0,25 do clouds[i] = { x = rnd(132), y = rnd(132), s = 16 + rnd(32) } end

	-- reset state
	frames = 0
	berry_count = 0
	collected = {}
	for lvl in all(levels) do
		add(collected, {})
	end

	goto_level(level_index)
end

function _init()
	game_start()
end

function _update()

	-- timers
	frames += 1

	-- screenshake
	shake -= 1

	update_input()

	--freeze
	if freeze_time > 0 then
		freeze_time -= 1
	else
		--objects
		for o in all(objects) do
			if o.freeze > 0 then
				o.freeze -= 1
			else
				o:update()
			end

			if o.destroyed then
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
	draw_clouds(1, 0, 0, 1, 1, 13)

	-- draw tileset
	for x = mid(0, flr(camera_x / 8), level.width),mid(0, flr((camera_x + 128) / 8), level.width) do
		for y = mid(0, flr(camera_y / 8), level.height),mid(0, flr((camera_y + 128) / 8), level.height) do
			local tile = tile_at(x, y)
			if tile != 0 and fget(tile, 0) then
				spr(tile, x * 8, y * 8)
			end
		end
	end

	-- draw objects
	local p = nil
	for o in all(objects) do
		if o.base == player then p = o else o:draw() end
	end
	if p then p:draw() end

	-- draw snow
	for i=1,#snow do
		local s = snow[i]
		circfill(camera_x + (s.x - camera_x * 0.5) % 132 - 2, camera_y + (s.y - camera_y * 0.5) % 132, i % 2, 7)
		s.x += (4 - i % 4)
		s.y += sin(time() * 0.25 + i * 0.1)
	end

	-- draw FG clouds
	if level.fog then
		fillp(0b0101101001011010.1)
		draw_clouds(1.5, 0, level.height * 8 + 1, 1, 0, 7)
		fillp()
	end

	-- screen wipes
	-- very similar functions ... can they be compressed into one?
	if p ~= nil and p.dead_timer > 5 then
		local e = (p.dead_timer - 5) / 12
		for i=0,127 do
			s = (127 + 64) * e - 32 + sin(i * 0.2) * 16 + (127 - i) * 0.25
			rectfill(camera_x,camera_y+i,camera_x+s,camera_y+i,0)
		end
	end

	if infade < 15 then
		local e = infade / 12
		for i=0,127 do
			s = (127 + 64) * e - 32 + sin(i * 0.2) * 16 + (127 - i) * 0.25
			rectfill(camera_x+s,camera_y+i,camera_x+128,camera_y+i,0)
		end
	end

	-- game timer
	if infade < 45 then
		draw_time(camera_x + 4, camera_y + 4)
	end

	-- debug
	if false then
		for o in all(objects) do
			rect(o.x + o.hit_x, o.y + o .hit_y, o.x + o.hit_x + o.hit_w - 1, o.y + o.hit_y + o.hit_h - 1, 8)
		end

		camera(0, 0)
		print("cpu: " .. flr(stat(1) * 100) .. "/100", 9, 9, 8)
		print("mem: " .. flr(stat(0)) .. "/2048", 9, 15, 8)
		print("idx: " .. level.offset, 9, 21, 8)
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

function draw_clouds(scale, ox, oy, sx, sy, color)
	for i=0,#clouds do
		local c = clouds[i]
		local s = c.s * scale
		local x = ox + (camera_x + (c.x - camera_x * 0.9) % (128 + s) - s / 2) * sx
		local y = oy + (camera_y + (c.y - camera_y * 0.9) % (128 + s / 2)) * sy
		clip(x - s / 2 - camera_x, y - s / 2 - camera_y, s, s / 2)
		circfill(x, y, s / 3, color)
		if i % 2 == 0 then
			circfill(x - s / 3, y, s / 5, color)
		end
		if i % 2 == 0 then
			circfill(x + s / 3, y, s / 6, color)
		end
		c.x += (4 - i % 4) * 0.25
	end
	clip(0,0,128,128)
end

function approach(x, target, max_delta)
	if x < target then
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
		
		if i <= fade_x_dist then
			fade = i / (fade_x_dist + 1)
		elseif i > x_max - fade_x_dist + 1 then
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