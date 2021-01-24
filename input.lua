input_x = 0
input_jump = false
input_jump_pressed = 0
input_grapple = false
input_grapple_pressed = 0
axis_x_value = 0
axis_x_turned = false

function update_input()
    -- axes
	local prev_x = axis_x_value
	if btn(0) then
		if btn(1) then
            if axis_x_turned then
                axis_x_value = prev_x
				input_x = prev_x
			else
                axis_x_turned = true
                axis_x_value = -prev_x
                input_x = -prev_x
			end
		else
            axis_x_turned = false
            axis_x_value = -1
            input_x = -1
		end
	elseif btn(1) then
        axis_x_turned = false
        axis_x_value = 1
        input_x = 1
	else
        axis_x_turned = false
        axis_x_value = 0
        input_x = 0
    end

	-- input_jump
	local jump = btn(4)
	if jump and not input_jump then		
		input_jump_pressed = 4
	else
		input_jump_pressed = jump and max(0, input_jump_pressed - 1) or 0
	end
	input_jump = jump

	-- input_grapple
	local grapple = btn(5)
	if grapple and not input_grapple then
		input_grapple_pressed = 4
	else
		input_grapple_pressed = grapple and max(0, input_grapple_pressed - 1) or 0
	end
	input_grapple = grapple
end

function consume_jump_press()
	local val = input_jump_pressed > 0
	input_jump_pressed = 0
	return val
end

function consume_grapple_press()
	local val = input_grapple_pressed > 0
	input_grapple_pressed = 0
	return val
end