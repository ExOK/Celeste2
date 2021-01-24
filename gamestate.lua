levels = {

    {
        width = 96,
        height = 16,
        camera_mode = 2,
        music = 0
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
level = levels[1]
camera_x = 0
camera_y = 0
camera_target_x = 0
camera_target_y = 0

on_restart_level = function()
    camera_target_x = 0
    camera_target_y = 0
end

on_start_level = function(index)
    level = levels[index]
    music(level.music)
    on_restart_level()
end

snap_camera = function()
    camera_x = camera_target_x
    camera_y = camera_target_y
    camera(camera_x, camera_y)
end

tile_y = function(py)
    return max(0, min(flr(py / 8), level.height - 1))
end