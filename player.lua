player = {}
player.tile = 2
player.base = object

player.jump_grace = 0
player.jump_grace_y = 0
player.t_var_jump = 0
player.var_jump_speed = 0
player.grapple_x = 0
player.grapple_y = 0
player.grapple_dir_x = 0
player.grapple_dir_y = 0
player.grapple_hit = nil
player.grapple_wave = 0

player.state = 0
player.frame = 0

player.init = function(self)
	self.spr = self.tile
	self.hit_x = -3
	self.hit_y = -6
	self.hit_w = 6
	self.hit_h = 6
end

player.start_grapple = function(self)
	self.state = 1

	self.speed_x = 0
	self.speed_y = 0
	self.remainder_x = 0
	self.remainder_y = 0
	self.grapple_x = self.x
	self.grapple_y = self.y - 3	
	self.grapple_wave = 0

	if (input_y != 0) then
		self.grapple_dir_x = 0
		self.grapple_dir_y = input_y
	elseif (input_x != 0) then
		self.grapple_dir_x = input_x
		self.grapple_dir_y = 0
	else
		if (self.right) then
			self.grapple_dir_x = 1
		else
			self.grapple_dir_x = -1
		end
		self.grapple_dir_y = 0
	end
end

player.grapple_check = function(self, x, y)
	if (fget(room_tile_at(flr(x / 8), flr(y / 8)), 1)) then
		self.grapple_hit = nil
		return true
	end

	for i=1,#objects do
		local o = objects[i]
		if (o.geom == g_solid and o:contains(x, y)) then
			self.grapple_hit = on_collide_x
			return true
		end
	end

	return false
end

player.draw_grapple = function(self)

	if (self.grapple_wave == 0) then
		line(self.x, self.y - 3, self.grapple_x, self.grapple_y, 7)
	else
		if (self.grapple_dir_x != 0) then
			--horizontal
			draw_sine_h(self.x, self.grapple_x, self.y - 3, 7, 3 * self.grapple_wave, 20, 0.08, 6)
		else
			--vertical
			draw_sine_v(self.y - 3, self.grapple_y, self.x, 7, 3 * self.grapple_wave, 20, 0.08, 6)
		end
	end

end

player.update = function(self) 
	local on_ground = self:check_solid(0, 1)
	if (on_ground) then
		self.jump_grace = 4
		self.jump_grace_y = self.y
	else
		self.jump_grace = max(0, self.jump_grace - 1)
	end

	if (self.state == 0) then
		-- normal state

		-- running
		if (abs(self.speed_x) > 2 and input_x == sgn(self.speed_x)) then
			self.speed_x = approach(self.speed_x, input_x * 2, 0.1)
		elseif (on_ground) then
			self.speed_x = approach(self.speed_x, input_x * 2, 0.6)
		elseif (input_x != 0) then
			self.speed_x = approach(self.speed_x, input_x * 2, 0.4)
		else
			self.speed_x = approach(self.speed_x, 0, 0.1)
		end

		-- gravity
		if (not on_ground) then
			local max = 5
			if (input_jump) then
				max = 4
			end

			if (abs(self.speed_y) < 0.2) then
				self.speed_y = min(self.speed_y + 0.4, max)
			else
				self.speed_y = min(self.speed_y + 0.8, max)
			end
		end

		-- variable jumping
		if (self.t_var_jump > 0) then
			if (input_jump) then
				self.speed_y = self.var_jump_speed
				self.t_var_jump -= 1
			else
				self.t_var_jump = 0
			end
		end		

		-- jumping
		if (self.jump_grace > 0 and consume_jump_press()) then
			self.speed_y = -4
			self.speed_x += input_x * 0.2
			self.var_jump_speed = self.speed_y
			self.t_var_jump = 4
			self.jump_grace = 0
			self:move_y(self.jump_grace_y - self.y)
		end

		-- throw grapple
		if (consume_grapple_press()) then
			self:start_grapple()
		end

	elseif (self.state == 1) then
		-- throw grapple state

		-- grapple moves
		if (self.grapple_dir_x != 0) then
			local sign = sgn(self.grapple_dir_x)
			for i = 1, 12 do
				if (self:grapple_check(self.grapple_x + sign, self.grapple_y)) then
					self.state = 2
					self.grapple_wave = 1.5
				else
					self.grapple_x += sign
				end
			end
		else
			local sign = sgn(self.grapple_dir_y)
			for i = 1, 12 do
				if (self:grapple_check(self.grapple_x, self.grapple_y + sign)) then
					self.state = 2
					self.grapple_wave = 1.5
				else
					self.grapple_y += sign
				end
			end
		end

		-- grapple wave
		self.grapple_wave = approach(self.grapple_wave, 1, 0.2)

		-- release
		if (not input_grapple) then
			self.state = 0
		end

	elseif (self.state == 2) then
		-- grapple attached state

		-- grapple wave
		self.grapple_wave = approach(self.grapple_wave, 0, 0.3)

		-- release
		if (not input_grapple) then
			self.state = 0
		end

	end

	-- apply
	self:move_x(self.speed_x)
	self:move_y(self.speed_y)

	-- hacky sprite stuff
	if (input_x != 0) then
		self.right = input_x > 0
		self.frame += 0.25
	else
		self.frame = 0
	end
	self.spr = self.tile + flr(self.frame) % 2

end

player.on_collide_x = function(self, moved, target)
	if (sgn(target) == input_x and self:corner_correct(input_x, 0, 2, 1, -1)) then
		return
	end

	object.on_collide_x(self, moved, target)
end

player.on_collide_y = function(self, moved, target)
	if (target < 0 and self:corner_correct(0, -1, 2, 1, input_x)) then
		return
	end

	t_var_jump = 0
	object.on_collide_y(self, moved, target)
end

player.draw = function(self)
	
	local facing = 1
	for i=0,3 do
		local tx = self.x - facing * 4 - facing * i * 1
		local ty = self.y - 4 + sin(i * 0.25 + time() * 2)
		rect(tx, ty, tx, ty, 10)
	end

	-- draw sprite
	spr(self.spr, self.x - 4, self.y - 8, 1, 1, not self.right)

	-- draw grapple
	if (self.state != 0) then
		self:draw_grapple()
	end
end

setmetatable(player, lookup)
add(types, player)