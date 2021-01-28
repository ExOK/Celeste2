level_index = 0
level_intro = 0

function game_start()
	
	-- reset state
	snow = {}
	clouds = {}
	freeze_time = 0
	frames = 0
	seconds = 0
	minutes = 0
	shake = 0
	sfx_timer = 0
	berry_count = 0
	death_count = 0
	collected = {}
	camera_x = 0
	camera_y = 0
	show_score = 0
	titlescreen_flash = nil

	for i=0,25 do 
		snow[i] = { x = rnd(132), y = rnd(132) } 
		clouds[i] = { x = rnd(132), y = rnd(132), s = 16 + rnd(32) }
	end

	-- goto titlescreen or level
	if level_index == 0 then
		current_music = 38
		music(current_music)
	else
		goto_level(level_index)
	end
end

function _init()
	game_start()
end

function _update()

	-- titlescreen
	if level_index == 0 then
		if titlescreen_flash then
			titlescreen_flash-= 1
			if titlescreen_flash < -30 then goto_level(1) end
		elseif btn(4) or btn(5) then
			titlescreen_flash = 50
			sfx(22, 3)
		end
	
	-- level intro card
	elseif level_intro > 0 then
		level_intro -= 1
		if level_intro == 0 then psfx(17, 24, 9) end

	-- normal level
	else
		-- timers
		sfx_timer = max(sfx_timer - 1)
		shake = max(shake - 1)
		infade = min(infade + 1, 60)
		if level_index != 8 then frames += 1 end
		if frames == 30 then seconds += 1 frames = 0 end
		if seconds == 60 then minutes += 1 seconds = 0 end

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
	end
end

function _draw()

	pal()

	if level_index == 0 then

		cls(0)
		
		if titlescreen_flash then
			local c=10
			if titlescreen_flash>10 then
				if titlescreen_flash%10<5 then c=7 end
			elseif titlescreen_flash>5 then c=2
			elseif titlescreen_flash>0 then c=1
			else c=0 end
			if c<10 then for i=1,16 do pal(i,c) end end
		end

		sspr(72, 32, 56, 32, 36, 32)
		rect(0,0,127,127,7)
		print_center("lANI'S tREK", 64, 68, 14)
		print_center("a game by", 64, 80, 1)
		print_center("maddy thorson", 64, 87, 5)
		print_center("noel berry", 64, 94, 5)
		print_center("lena raine", 64, 101, 5)
		draw_snow()
		return
	end

	if level_intro > 0 then
		cls(0)
		camera(0, 0)
		draw_time(4, 4)
		if level_index != 8 then
			print_center("level " .. (level_index - 2), 64, 64 - 8, 7)
		end
		print_center(level.title, 64, 64, 7)
		return
	end

	local camera_x = peek2(0x5f28)
	local camera_y = peek2(0x5f2a)

	if shake > 0 then
		camera(camera_x - 2 + rnd(5), camera_y - 2 + rnd(5))
	end

	-- clear screen
	cls(level and level.bg and level.bg or 0)

	-- draw clouds
	draw_clouds(1, 0, 0, 1, 1, level.clouds or 13, #clouds)

	-- columns
	if level.columns then
		fillp(0b0000100000000010.1)
		local x = 0
		while x < level.width do
			local tx = x * 8 + camera_x * 0.1
			rectfill(tx, 0, tx + (x % 2) * 8 + 8, level.height * 8, level.columns)
			x += 1 + x % 7
		end
		fillp()
	end

	-- draw tileset
	for x = mid(0, flr(camera_x / 8), level.width),mid(0, flr((camera_x + 128) / 8), level.width) do
		for y = mid(0, flr(camera_y / 8), level.height),mid(0, flr((camera_y + 128) / 8), level.height) do
			local tile = tile_at(x, y)
			if level.pal and fget(tile, 7) then level.pal() end
			if tile != 0 and fget(tile, 0) then spr(tile, x * 8, y * 8) end
			pal() palt()
		end
	end

	-- score
	if show_score > 105 then
		rectfill(34,392,98, 434, 1)
		rectfill(32,390,96, 432, 0)
		rect(32,390,96, 432, 7)
		spr(21, 44, 396)
		print("X "..berry_count, 56, 398, 7)
		spr(72, 44, 408)
		draw_time(56, 408)
		spr(71, 44, 420)
		print("X "..death_count, 56, 421, 7)
	end

	-- draw objects
	local p = nil
	for o in all(objects) do
		if o.base == player then p = o else o:draw() end
	end
	if p then p:draw() end

	-- draw snow
	draw_snow()

	-- draw FG clouds
	if level.fogmode then
		if level.fogmode == 1 then fillp(0b0101101001011010.1) end
		draw_clouds(1.25, 0, level.height * 8 + 1, 1, 0, 7, #clouds - 10)
		fillp()
	end

	-- screen wipes
	-- very similar functions ... can they be compressed into one?
	if p ~= nil and p.wipe_timer > 5 then
		local e = (p.wipe_timer - 5) / 12
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
	--[[
	for o in all(objects) do
		rect(o.x + o.hit_x, o.y + o .hit_y, o.x + o.hit_x + o.hit_w - 1, o.y + o.hit_y + o.hit_h - 1, 8)
	end

	camera(0, 0)
	print("cpu: " .. flr(stat(1) * 100) .. "/100", 9, 9, 8)
	print("mem: " .. flr(stat(0)) .. "/2048", 9, 15, 8)
	print("idx: " .. level.offset, 9, 21, 8)
	]]

	camera(camera_x, camera_y)
end

function draw_time(x,y)
	local m = minutes % 60
	local h = flr(minutes / 60)
	
	rectfill(x,y,x+32,y+6,0)
	print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(seconds<10 and "0"..seconds or seconds),x+1,y+1,7)
end

function draw_clouds(scale, ox, oy, sx, sy, color, count)
	for i=0,count do
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

function draw_snow()
	for i=1,#snow do
		local s = snow[i]
		circfill(camera_x + (s.x - camera_x * 0.5) % 132 - 2, camera_y + (s.y - camera_y * 0.5) % 132, i % 2, 7)
		s.x += (4 - i % 4)
		s.y += sin(time() * 0.25 + i * 0.1)
	end
end

function print_center(text, x, y, c)
	x -= (#text * 4 - 1) / 2
	print(text, x, y, c)
end

function approach(x, target, max_delta)
	return x < target and min(x + max_delta, target) or max(x - max_delta, target)
end

function psfx(id, off, len, lock)
	if sfx_timer <= 0 or lock then
		sfx(id, 3, off, len)
		if lock then sfx_timer = lock end
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
		pset(ax, ay + 1, 1)
		pset(ax, ay, col)

		this_y = ay
		while abs(ay - last_y) > 1 do
			ay -= sgn(this_y - last_y)
			pset(ax - x_sign, ay + 1, 1)
			pset(ax - x_sign, ay, col)
		end
		last_y = this_y
	end
end