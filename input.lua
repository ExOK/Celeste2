input_x = 0
input_y = 0
input_jump = false
input_jump_pressed = 0
input_grapple = false
input_grapple_pressed = 0

axis = {}
axis.update = function(self)
    local prev_x = self.value
	if btn(self.negative) then
		if btn(self.positive) then
            if self.turned then
                self.value = prev_x
				return prev_x
			else
                self.turned = true
                self.value = -prev_x
                return -prev_x
			end
		else
            self.turned = false
            self.value = -1
            return -1
		end
	elseif btn(self.positive) then
        self.turned = false
        self.value = 1
        return 1
	else
        self.turned = false
        self.value = 0
        return 0
    end
end

axis_x = {}
setmetatable(axis_x, axis)
axis_x.value = 0
axis_x.turned = false
axis_x.positive = 1
axis_x.negative = 0

axis_y = {}
setmetatable(axis_y, axis)
axis_y.value = 0
axis_y.turned = false
axis_y.positive = 2
axis_y.negative = 3

function update_input()
    -- axes
    input_x = axis.update(axis_x)
    input_y = axis.update(axis_y)

	-- input_jump
	local jump = btn(4)
	if jump and not input_jump then		
		input_jump_pressed = 4
	elseif jump then
		input_jump_pressed = max(0, input_jump_pressed - 1)
	else
		input_jump_pressed = 0
	end
	input_jump = jump

	-- input_grapple
	local grapple = btn(5)
	if grapple and not input_grapple then
		input_grapple_pressed = 4
	elseif grapple then
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