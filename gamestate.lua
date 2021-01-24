levels = {
    {
        width = 96,
        height = 16,
        camera_mode = 2,
		music = 0,
		offset = 0
	},
	{
        width = 128,
        height = 16,
        camera_mode = 1,
		music = 0,
		offset = 312
    }
}

camera_modes = {

    -- 1: Basic Horizontal Mode
    function(px, py)
        camera_target_x = max(0, min(level.width * 8 - 128, px - 56))
    end,

    -- 2: Intro Mode
    function(px, py)
        if (px < 42) then
            camera_target_x = 0
        else
            camera_target_x = max(40, min(level.width * 8 - 128, px - 48))
        end
    end

}

have_grapple = true
camera_x = 0
camera_y = 0
camera_target_x = 0
camera_target_y = 0

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

	-- load into ram
	local function vget(x, y) return peek(0x4300 + (x % 128) + y * 128) end
	local function vset(x, y, v) return poke(0x4300 + (x % 128) + y * 128, v)end
	px9_decomp(0, 0, 0x1000 + level.offset, vget, vset)

	-- start music
	music(level.music)
	
	-- load level contents
    restart_level()
end

function next_level()
	goto_level(level_index + 1)
end

function restart_level()
    camera_target_x = 0
	camera_target_y = 0
	objects = {}
	infade = 0
	camera(0, 0)

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