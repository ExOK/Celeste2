levels = {
    {
        width = 96,
        height = 16,
		camera_mode = 1,
		music = 38,
        offset = 0
    },
    {
        width = 32,
        height = 32,
        camera_mode = 2,
		music = 36,
		fog = true,
		clouds = 0,
		offset = 308,
		columns = 13
    },
    {
        width = 128,
        height = 22,
        camera_mode = 3,
        camera_barriers_x = { 38 },
        camera_barrier_y = 6,
        music = 2,
		offset = 644,
		title = "trailhead"
    },
    {
        width = 128,
        height = 32,
        camera_mode = 4,
        music = 2,
        offset = 1278,
		title = "10 km marker",
		spal = function() pal(2, 12) end,
		columns = 1,
		fog = true
    },
    {
        width = 128,
        height = 16,
        camera_mode = 5,
        music = 2,
		offset = 644,
		title = "20 km marker"
    }
}

camera_modes = {

    -- 1: Intro
    function(px, py, g)
        if px < 42 then
            camera_target_x = 0
        else
            camera_target_x = max(40, min(level.width * 8 - 128, px - 48))
        end
    end,

    -- 2: Intro 2
    function(px, py, g)
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
    function(px, py, g)
        camera_target_x = max(0, min(level.width * 8 - 128, px - 56))
        for i,b in ipairs(level.camera_barriers_x) do
            local bx = b * 8
            if px < bx - 8 then
                camera_target_x = min(camera_target_x, bx - 128)
            elseif px > bx + 8 then
                camera_target_x = max(camera_target_x, bx)
            end
        end

        if py < level.camera_barrier_y * 8 + 3 then
            camera_target_y = 0
        else
            camera_target_y = level.camera_barrier_y * 8
        end
    end,

    -- 4: Level 2
    function(px, py, g)
        if px % 128 > 8 and px % 128 < 120 then
            px = flr(px / 128) * 128 + 64
        end
        if py % 128 > 4 and py % 128 < 124 then
            py = flr(py / 128) * 128 + 64
        end
        camera_target_x = max(0, min(level.width * 8 - 128, px - 64))
        camera_target_y = max(0, min(level.height * 8 - 128, py - 64))
    end,

    -- 5: Level 3
    function(px, py, g)
        camera_target_x = max(0, min(level.width * 8 - 128, px - 32))
    end,

    -- Basic Horizontal
    function(px, py, g)
        camera_target_x = max(0, min(level.width * 8 - 128, px - 56))
    end,

    -- Basic Freeform
    function(px, py, g)
        camera_target_x = max(0, min(level.width * 8 - 128, px - 64))
        camera_target_y = max(0, min(level.height * 8 - 128, py - 64))
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
		sfx(17, 3, 8, 16)
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