levels = {
    {
        offset = 0,
        width = 96,
        height = 16,
		camera_mode = 1,
		music = 38,
    },
    {
		offset = 341,
        width = 32,
        height = 32,
        camera_mode = 2,
		music = 36,
		fogmode = 1,
		clouds = 0,
		columns = 1
    },
    {
		offset = 677,
        width = 128,
        height = 22,
        camera_mode = 3,
        camera_barriers_x = { 38 },
        camera_barrier_y = 6,
        music = 2,
		title = "trailhead"
    },
    {
        offset = 1311,
        width = 128,
        height = 32,
        camera_mode = 4,
        music = 2,
		title = "10 km marker",
		pal = function() pal(2, 12) pal(5, 2) end,
		columns = 1
    },
    {
		offset = 2408,
        width = 128,
        height = 16,
        camera_mode = 5,
        music = 2,
		title = "20 km marker",
		pal = function() pal(2, 14) pal(5, 2) end,
		bg = 13,
		clouds = 15,
		fogmode = 2
    },
    {
		offset = 2632,
        width = 128,
        height = 16,
        camera_mode = 6,
        camera_barriers_x = { 105 },
        music = 2,
		pal = function() pal(2, 14) pal(5, 2) end,
		bg = 13,
		clouds = 15,
		fogmode = 2
    },
    {
		offset = 2864,
        width = 128,
        height = 16,
        camera_mode = 7,
        music = 2,
		pal = function() pal(2, 12) pal(5, 2) end,
		bg = 13,
		clouds = 7,
		fogmode = 2,
    },
    {
		offset = 0,
        width = 16,
        height = 62,
        camera_mode = 8,
        music = 2,
		pal = function() pal(2, 12) pal(5, 2) end,
		bg = 13,
		clouds = 7,
        fogmode = 2,
        right_edge = true
    }
}

camera_x_barrier = function(tile_x, px, py)
    local bx = tile_x * 8
    if px < bx - 8 then
        camera_target_x = min(camera_target_x, bx - 128)
    elseif px > bx + 8 then
        camera_target_x = max(camera_target_x, bx)
    end
end

c_offset = 0
c_flag = false
camera_modes = {

    -- 1: Intro
    function(px, py)
        if px < 42 then
            camera_target_x = 0
        else
            camera_target_x = max(40, min(level.width * 8 - 128, px - 48))
        end
    end,

    -- 2: Intro 2
    function(px, py)
        if px < 120 then
            camera_target_x = 0
        elseif px > 136 then
            camera_target_x = 128
        else
            camera_target_x = px - 64
        end
        camera_target_y = max(0, min(level.height * 8 - 128, py - 64))
    end,

    -- 3: Level 1
    function(px, py)
        camera_target_x = max(0, min(level.width * 8 - 128, px - 56))
        for i,b in ipairs(level.camera_barriers_x) do
            camera_x_barrier(b, px, py)
        end

        if py < level.camera_barrier_y * 8 + 3 then
            camera_target_y = 0
        else
            camera_target_y = level.camera_barrier_y * 8
        end
    end,

    -- 4: Level 2
    function(px, py)
        if px % 128 > 8 and px % 128 < 120 then
            px = flr(px / 128) * 128 + 64
        end
        if py % 128 > 4 and py % 128 < 124 then
            py = flr(py / 128) * 128 + 64
        end
        camera_target_x = max(0, min(level.width * 8 - 128, px - 64))
        camera_target_y = max(0, min(level.height * 8 - 128, py - 64))
    end,

    -- 5: Level 3-1 and 3-3
    function(px, py)
        camera_target_x = max(0, min(level.width * 8 - 128, px - 32))
    end,

    -- 6: Level 3-2
    function(px, py)
        if px > 848 then
            c_offset = 48
        elseif px < 704 then
            c_offset = 32
        elseif px > 808 then
            c_flag = true
            c_offset = 96
        end

        camera_target_x = max(0, min(level.width * 8 - 128, px - c_offset))

        for i,b in ipairs(level.camera_barriers_x) do
            camera_x_barrier(b, px, py)
        end

        if c_flag then
            camera_target_x = max(camera_target_x, 672)
        end
    end,

    --7: Level 3-3
    function (px, py)
        if px > 420 then
            if px < 436 then
                c_offset = 32 + (px - 420)
            else
                c_offset = 48
            end
        else
            c_offset = 32
        end
        camera_target_x = max(0, min(level.width * 8 - 128, px - c_offset))
    end,

    --8: End
    function (px, py)
        camera_target_y = max(0, min(level.height * 8 - 128, py - 32))
    end
}

snap_camera = function()
    camera_x = camera_target_x
    camera_y = camera_target_y
    camera(camera_x, camera_y)
end

tile_y = function(py)
    return max(0, min(flr(py / 8), level.height - 1))
end

function goto_level(index)

	-- set level
	level = levels[index]
	level_index = index
	level_checkpoint = nil

	if level.title and not standalone then
		level_intro = 60
	end

	if level_index == 2 then 
		psfx(17, 8, 16)
	end

	-- load into ram
	local function vget(x, y) return peek(0x4300 + (x % 128) + y * 128) end
	local function vset(x, y, v) return poke(0x4300 + (x % 128) + y * 128, v) end
	px9_decomp(0, 0, 0x1000 + level.offset, vget, vset)

	-- start music
	if current_music != level.music and level.music then
		current_music = level.music
		music(level.music)
	end
	
	-- load level contents
    restart_level()
end

function next_level()
	level_index += 1
	if standalone then
		load("celeste2/" .. level_index .. ".p8")
	else
		goto_level(level_index)
	end
end

function restart_level()
	camera_x = 0
	camera_y = 0
    camera_target_x = 0
	camera_target_y = 0
	objects = {}
	infade = 0
	have_grapple = level_index > 2
	sfx_timer = 0

	for i = 0,level.width-1 do
		for j = 0,level.height-1 do
			for t in all(types) do
				if level_checkpoint == nil or t != player then
					if tile_at(i, j) == t.spr and not collected[id(i, j)] then
						create(t, i * 8, j * 8)
					end
				end
			end
		end
	end
end

-- gets the tile at the given location from the loaded level
function tile_at(x, y)
	if (x < 0 or y < 0 or x >= level.width or y >= level.height) then return 0 end

	if standalone then
		return mget(x, y)
	else
		return peek(0x4300 + (x % 128) + y * 128)
	end
end