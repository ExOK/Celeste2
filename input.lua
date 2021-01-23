input_x = 0
input_y = 0
input_x_turned = false
input_y_turned = false
input_jump = false
input_jump_pressed = 0
input_grapple = false
input_grapple_pressed = 0

function update_input()
    -- input_x
	local prev_x = input_x
	if (btn(0)) then
		if (btn(1)) then
			if (input_x_turned) then
				input_x = prev_x
			else
				input_x = -prev_x
				input_x_turned = true
			end
		else
			input_x = -1
			input_x_turned = false
		end
	elseif (btn(1)) then
		input_x = 1
		input_x_turned = false
	else
		input_x = 0
		input_x_turned = false
	end

	-- input_y
	local prev_y = input_y
	if (btn(2)) then
		if (btn(3)) then
			if (input_y_turned) then
				input_y = prev_y
			else
				input_y = -prev_y
				input_y_turned = true
			end
		else
			input_y = -1
			input_y_turned = false
		end
	elseif (btn(3)) then
		input_y = 1
		input_y_turned = false
	else
		input_y = 0
		input_y_turned = false
	end

	-- input_jump
	local jump = btn(4)
	if (jump and not input_jump) then		
		input_jump_pressed = 4
	elseif (jump) then
		input_jump_pressed = max(0, input_jump_pressed - 1)
	else
		input_jump_pressed = 0
	end
	input_jump = jump

	-- input_grapple
	local grapple = btn(5)
	if (grapple and not input_grapple) then
		input_grapple_pressed = 4
	elseif (grapple) then
		input_grapple_pressed = max(0, input_grapple_pressed - 1)
	else
		input_grapple_pressed = 0
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