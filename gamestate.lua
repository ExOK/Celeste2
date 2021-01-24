levels = {

    {
        width = 768,
        height = 128,
        camera_mode = 2
    }

}

camera_modes = {

    -- 1: Basic Horizontal Mode
    function(px, py)
        camera(max(0, min(level.width - 128, px - 56)), 0)
    end,

    -- 2: Intro Mode
    function(px, py)
        if (px < 32) then
            camera(0, 0)
        else
            camera(max(32, min(level.width - 128, px - 48)), 0)
        end
    end

}

have_grapple = true
level = levels[1]
camera_x = 0
camera_y = 0
camera_target_x = 0
camera_target_y = 0

start_level = function(index)
    level = levels[index]

    level.camera_mode(0, 0)
    camera_x = camera_target_x
    camera_y = camera_target_y
end

snap_camera = function()
    camera_x = camera_target_x
    camera_y = camera_target_y
    camera(camera_x, camera_y)
end

tile_y = function(py)
    return max(0, min(flr(py / 8), level.height / 8 - 1))
end