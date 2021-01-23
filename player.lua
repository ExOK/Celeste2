player = new_type()
player.tile = 2
player.base = object

player.t_jump_grace = 0
player.jump_grace_y = 0
player.t_var_jump = 0
player.var_jump_speed = 0
player.grapple_x = 0
player.grapple_y = 0
player.grapple_dir = 0
player.grapple_hit = nil
player.grapple_wave = 0
player.grapple_boost = false
player.t_grapple_cooldown = 0
player.grapple_ice_timer = 0

player.state = 0
player.frame = 0

-- Grapple Functions

player.start_grapple = function(self)
	self.state = 1

	self.speed_x = 0
	self.speed_y = 0
	self.remainder_x = 0
	self.remainder_y = 0
	self.grapple_x = self.x
	self.grapple_y = self.y - 3	
	self.grapple_wave = 0
	self.t_grapple_cooldown = 6
	self.t_var_jump = 0

	if (input_x != 0) then
		self.grapple_dir = input_x
	else
		self.grapple_dir = self.facing
	end
	self.facing = self.grapple_dir

end

-- 0 = nothing, 1 = solid, 2 = ice
player.grapple_check = function(self, x, y)
	local tile = room_tile_at(flr(x / 8), flr(y / 8))
	if (fget(tile, 1)) then
		self.grapple_hit = nil
		return fget(tile, 2) and 2 or 1
	end

	for i=1,#objects do
		local o = objects[i]
		if (o.geom == g_solid and o:contains(x, y)) then
			self.grapple_hit = on_collide_x
			return 1
		end
	end

	return 0
end

-- Jumps

player.wall_jump = function(self, dir)
	consume_jump_press()
	self.speed_y = -3
	self.speed_x = 3 * dir
	self.var_jump_speed = self.speed_y
	self.t_var_jump = 4
	self.facing = dir
end

-- Events

player.init = function(self)
	self.spr = self.tile
	self.hit_x = -3
	self.hit_y = -6
	self.hit_w = 6
	self.hit_h = 6

	self.scarf = {}
	for i = 0,4 do
		add(self.scarf, { x = self.x, y = self.y })
	end
end

player.update = function(self)
	local on_ground = self:check_solid(0, 1)
	if (on_ground) then
		self.t_jump_grace = 4
		self.jump_grace_y = self.y
	else
		self.t_jump_grace = max(0, self.t_jump_grace - 1)
	end

	if (self.t_grapple_cooldown > 0 and self.state < 1) then
		self.t_grapple_cooldown -= 1
	end

	if (self.state == 0) then
		-- normal state

		-- facing
		if (input_x ~= 0) then
			self.facing = input_x
		end

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
			if (abs(self.speed_y) < 0.2) then
				self.speed_y = min(self.speed_y + 0.4, 4.5)
			else
				self.speed_y = min(self.speed_y + 0.8, 4.5)
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
		if (input_jump_pressed > 0) then
			if (self.t_jump_grace > 0) then
				consume_jump_press()
				self.speed_y = -4
				self.speed_x += input_x * 0.2
				self.var_jump_speed = self.speed_y
				self.t_var_jump = 4
				self.t_jump_grace = 0
				self:move_y(self.jump_grace_y - self.y)
			elseif (self:check_solid(2, 0)) then
				self:wall_jump(-1)
			elseif (self:check_solid(-2, 0)) then
				self:wall_jump(1)
			end
		end

		-- throw grapple
		if (self.t_grapple_cooldown <= 0 and consume_grapple_press()) then
			self:start_grapple()
		end

		self.grapple_x = self.x

	elseif (self.state == 1) then
		-- throw grapple state

		-- grapple movement
		for i = 1, 12 do
			local hit = self:grapple_check(self.grapple_x + self.grapple_dir, self.grapple_y)
			if (hit == 0) then
				self.grapple_x += self.grapple_dir
			elseif (hit == 1) then
				self.state = 2
				self.grapple_wave = 2
				self.grapple_boost = false
				freeze_time = 2
			else
				self.grapple_ice_timer = 0
				self.state = 3
			end
		end

		-- grapple wave
		self.grapple_wave = approach(self.grapple_wave, 1, 0.2)
		self.frame = 1

		-- release
		if (not input_grapple) then
			self.state = 0
		end

	elseif (self.state == 2) then
		-- grapple attached state
		
		if (not self.grapple_boost) then
			self.grapple_boost = true
			self.speed_x = self.grapple_dir * 8
		end

		-- acceleration
		self.speed_x = approach(self.speed_x, self.grapple_dir * 5, 0.25)
		self.speed_y = approach(self.speed_y, 0, 0.4)

		if (self:check_solid(self.grapple_dir, 0)) then
			self.frame = 2
			if (consume_jump_press()) then
				self.state = 0
				self:wall_jump(-self.grapple_dir)
			end
		end

		-- grapple wave
		self.grapple_wave = approach(self.grapple_wave, 0, 0.6)

		-- release
		if (not input_grapple) then
			self.state = 0
			self.facing *= -1
			if (abs(self.speed_x) > 5) then
				self.speed_x = sgn(self.speed_x) * 5
			end
		end
	
	-- grapple hit ice 
	elseif (self.state == 3) then
		self.grapple_ice_timer += 1
		self.grapple_wave = 3
		if (self.grapple_ice_timer > 5) then
			self.state = 0
		end
	end

	-- apply
	self:move_x(self.speed_x)
	self:move_y(self.speed_y)

	-- sprite
	if (self.state != 2 and self.state != 1) then
		if (input_x != 0) then
			self.frame += 0.25
			self.frame = self.frame % 2
		else
			self.frame = 0
		end
	end
	self.spr = self.tile + self.frame

	camera(max(0, min(128, self.x - 64)), 0)
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

	-- scarf
	local last = { x = self.x - self.facing,y = self.y - 3 }
	for i=1,#self.scarf do
		local s = self.scarf[i]

		-- approach last pos with an offset
		s.x += (last.x - s.x - self.facing) / 1.5
		s.y += ((last.y - s.y) + sin(i * 0.25 + time()) * i * 0.25) / 2

		-- don't let it get too far
		local dx = s.x - last.x
		local dy = s.y - last.y
		local dist = sqrt(dx * dx + dy * dy)
		if (dist > 1.5) then
			local nx = (s.x - last.x) / dist
			local ny = (s.y - last.y) / dist
			s.x = last.x + nx * 1.5
			s.y = last.y + ny * 1.5
		end

		-- fill
		rectfill(s.x, s.y, s.x, s.y, 10)
		rectfill((s.x + last.x) / 2, (s.y + last.y) / 2, (s.x + last.x) / 2, (s.y + last.y) / 2, 10)
		last = s
	end

	-- grapple
	if (self.state != 0) then
		if (self.grapple_wave == 0) then
			line(self.x, self.y - 3, self.grapple_x, self.grapple_y, 7)
		else
			draw_sine_h(self.x, self.grapple_x, self.y - 3, 7, 2 * self.grapple_wave, 6, 0.08, 6)
		end
	end

	-- sprite
	spr(self.spr, self.x - 4, self.y - 8, 1, 1, self.facing ~= 1)
end