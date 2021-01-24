player = new_type()
player.tile = 2
player.base = object

player.t_jump_grace = 0
player.t_var_jump = 0
player.var_jump_speed = 0
player.grapple_x = 0
player.grapple_y = 0
player.grapple_dir = 0
player.grapple_hit = nil
player.grapple_wave = 0
player.grapple_boost = false
player.t_grapple_cooldown = 0
player.grapple_retract = false
player.holding = nil
player.dead_timer = 0
player.t_grapple_jump_grace = 0

player.state = 0
player.frame = 0

-- Grapple Functions

--[[
	object grapple modes:
		0 - no grapple
		1 - solid
		2 - solid centered
		2 - holdable
]]

player.start_grapple = function(self)
	self.state = 10

	self.speed_x = 0
	self.speed_y = 0
	self.remainder_x = 0
	self.remainder_y = 0
	self.grapple_x = self.x
	self.grapple_y = self.y - 3	
	self.grapple_wave = 0
	self.grapple_failed = false
	self.t_grapple_cooldown = 6
	self.t_var_jump = 0

	if (input_x != 0) then
		self.grapple_dir = input_x
	else
		self.grapple_dir = self.facing
	end
	self.facing = self.grapple_dir

end

-- 0 = nothing, 1 = hit!, 2 = fail
player.grapple_check = function(self, x, y)
	local tile = tile_at(flr(x / 8), tile_y(y))
	if (fget(tile, 1)) then
		self.grapple_hit = nil
		return fget(tile, 2) and 2 or 1
	end

	for o in all(objects) do
		if (o.grapple_mode != 0 and o:contains(x, y)) then
			self.grapple_hit = o
			return 1
		end
	end

	return 0
end

-- Helpers

player.jump = function(self)
	consume_jump_press()
	self.speed_y = -4
	self.var_jump_speed = -4
	self.speed_x += input_x * 0.2
	self.t_var_jump = 4
	self.t_jump_grace = 0
	self:move_y(self.jump_grace_y - self.y)
end

player.wall_jump = function(self, dir)
	consume_jump_press()
	self.state = 0
	self.speed_y = -3
	self.var_jump_speed = -3
	self.speed_x = 3 * dir	
	self.t_var_jump = 4
	self.facing = dir
	self:move_x(-dir * 3)
end

player.grapple_jump = function(self)
	consume_jump_press()
	self.state = 0
	self.t_grapple_jump_grace = 0
	self.state = 0
	self.speed_y = -3
	self.var_jump_speed = -3
	self.t_var_jump = 4
	if (abs(self.speed_x) > 4) then
		self.speed_x = sgn(self.speed_x) * 4
	end
	self:move_y(self.grapple_jump_grace_y - self.y)
end

player.die = function(self)
	self.state = 99
	freeze_time = 2
	shake = 5
end

--[[
	hazard types:
		0 - not a hazard
		1 - general hazard
		2 - up-spike
		3 - down-spike
		4 - right-spike
		5 - left-spike
]]

player.hazard_table = {
	[1] = function(self) return true end,
	[2] = function(self) return self.speed_y >= 0 end,
	[3] = function(self) return self.speed_y <= 0 end,
	[4] = function(self) return self.speed_x <= 0 end,
	[5] = function(self) return self.speed_x >= 0 end
}

player.hazard_check = function(self, ox, oy)
	if (ox == nil) then ox = 0 end
	if (oy == nil) then oy = 0 end

	for o in all(objects) do
		if (o.hazard != 0 and self:overlaps(o, ox, oy) and self.hazard_table[o.hazard](self)) then
			return true
		end
	end

	return false
end

player.correction_func = function(self, ox, oy)
	return not self:hazard_check(ox, oy)
end

-- Grappled Objects

pull_collide_x = function(self, moved, target)
	if (self:corner_correct(sgn(target), 0, 2, 2, 0)) then
		return false
	end
	return true
end

player.release_holding = function(self, obj, x, y, thrown)
	obj.held = false
	obj.speed_x = x
	obj.speed_y = y
	obj:on_release(thrown)
	self.holding = nil
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

	--camera
	camera_modes[level.camera_mode](self.x, self.y)
	camera_x = camera_target_x
	camera_y = camera_target_y
	camera(camera_x, camera_y)
end

player.update = function(self)
	local on_ground = self:check_solid(0, 1)
	if (on_ground) then
		self.t_jump_grace = 4
		self.jump_grace_y = self.y
	else
		self.t_jump_grace = max(0, self.t_jump_grace - 1)
	end

	if (self.t_grapple_jump_grace > 0) then
		self.t_grapple_jump_grace -= 1
	end

	if (self.t_grapple_cooldown > 0 and self.state < 1) then
		self.t_grapple_cooldown -= 1
	end

	-- grapple retract
	if (self.grapple_retract) then
		self.grapple_x = approach(self.grapple_x, self.x, 12)
		self.grapple_y = approach(self.grapple_y, self.y - 3, 6)

		if (self.grapple_x == self.x and self.grapple_y == self.y - 3) then
			self.grapple_retract = false
		end
	end

	--[[
		player states:
			0 	- normal
			1	- lift
			2 	- holding
			10 	- throw grapple
			11 	- grapple attached to solid
			12	- grapple pulling in holdable
			99 	- dead
	]]

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
				self:jump()
			elseif (self:check_solid(2, 0)) then
				self:wall_jump(-1)
			elseif (self:check_solid(-2, 0)) then
				self:wall_jump(1)
			elseif (self.t_grapple_jump_grace > 0) then
				self:grapple_jump()
			end
		end

		-- throw holding
		if (self.holding and not input_grapple) then
			self:release_holding(self.holding, 4 * self.facing, -3, true)
		end

		-- throw grapple
		if (have_grapple and not self.holding and self.t_grapple_cooldown <= 0 and consume_grapple_press()) then
			self:start_grapple()
		end

	elseif (self.state == 1) then
		-- lift state
		hold = self.grapple_hit

		hold.x = approach(hold.x, self.x - 4, 4)
		hold.y = approach(hold.y, self.y - 14, 4)

		if (hold.x == self.x - 4 and hold.y == self.y - 14) then
			self.state = 0
			self.holding = hold
		end

	elseif (self.state == 10) then
		-- throw grapple state

		-- grapple movement and hitting stuff
		local amount = min(64 - abs(self.grapple_x - self.x), 12)
		for i = 1, amount do
			local hit = self:grapple_check(self.grapple_x + self.grapple_dir, self.grapple_y)
			local mode = self.grapple_hit and self.grapple_hit.grapple_mode or 0

			if (hit == 0) then
				self.grapple_x += self.grapple_dir
			elseif (hit == 1) then
				if (mode == 2) then
					self.grapple_x = self.grapple_hit.x + 4
					self.grapple_y = self.grapple_hit.y + 4
				elseif (mode == 3) then
					self.grapple_hit.held = true
				end

				self.state = mode == 3 and 12 or 11
				self.grapple_wave = 2
				self.grapple_boost = false
				self.freeze = 2
			end

			if (hit == 2 or (hit == 0 and abs(self.grapple_x - self.x) >= 64)) then
				self.grapple_retract = true
				self.freeze = 2
				self.state = 0
			end
		end

		-- grapple wave
		self.grapple_wave = approach(self.grapple_wave, 1, 0.2)
		self.frame = 1

		-- release
		if (not input_grapple or abs(self.y - self.grapple_y) > 8) then
			self.state = 0
			self.grapple_retract = true
		end

	elseif (self.state == 11) then
		-- grapple attached state
		
		-- start boost
		if (not self.grapple_boost) then
			self.grapple_boost = true
			self.speed_x = self.grapple_dir * 8
		end

		-- acceleration
		self.speed_x = approach(self.speed_x, self.grapple_dir * 5, 0.25)
		self.speed_y = approach(self.speed_y, 0, 0.4)

		-- y-correction
		if (self.speed_y == 0) then
			if (self.y - 3 > self.grapple_y) then
				self:move_y(-0.5)
			elseif (self.y - 3 < self.grapple_y) then
				self:move_y(0.5)
			end
		end

		-- wall pose
		if (self:check_solid(self.grapple_dir, 0)) then
			self.frame = 2
		end

		-- jumps
		if (consume_jump_press()) then
			if (self:check_solid(self.grapple_dir * 2, 0)) then
				self:wall_jump(-self.grapple_dir)
			else
				self.grapple_jump_grace_y = self.y
				self:grapple_jump()
			end
		end

		-- grapple wave
		self.grapple_wave = approach(self.grapple_wave, 0, 0.6)

		-- release
		if (not input_grapple) then
			self.state = 0
			self.t_grapple_jump_grace = 2
			self.grapple_retract = true
			self.facing *= -1
			if (abs(self.speed_x) > 5) then
				self.speed_x = sgn(self.speed_x) * 5
			end
		end

		-- release if beyond grapple point
		if (sgn(self.x - self.grapple_x) == self.grapple_dir) then
			self.state = 0
			if (self.grapple_hit != nil and self.grapple_hit.grapple_mode == 2) then
				self.t_grapple_jump_grace = 3
				self.grapple_jump_grace_y = self.y
			end
			if (abs(self.speed_x) > 5) then
				self.speed_x = sgn(self.speed_x) * 5
			end
		end
	elseif (self.state == 12) then
		-- grapple pull state
		local obj = self.grapple_hit

		-- pull
		if (obj:move_x(-self.grapple_dir * 6, pull_collide_x)) then
			self.state = 0
			self.grapple_retract = true
			obj:on_release(-self.grapple_dir)
			return
		else
			self.grapple_x = approach(self.grapple_x, self.x, 6)
		end

		-- y-correct
		if (obj.y != self.y - 7) then
			obj:move_y(sgn(self.y - obj.y - 7) * 0.5)
		end

		-- grapple wave
		self.grapple_wave = approach(self.grapple_wave, 0, 0.6)

		-- hold
		if (self:overlaps(obj)) then
			self.state = 1
		end

		-- release
		if (not input_grapple or abs(obj.y - self.y + 7) > 8) then
			self.state = 0
			self.grapple_retract = true
			self:release_holding(obj, -self.grapple_dir * 5, 0, false)
		end

	elseif (self.state == 99) then
		-- dead state

		self.dead_timer += 1
		if (self.dead_timer > 20) then
			restart_level()
		end
		return
	end

	-- apply
	self:move_x(self.speed_x, self.on_collide_x)
	self:move_y(self.speed_y, self.on_collide_y)

	-- holding
	if (self.holding) then
		self.holding.x = self.x - 4
		self.holding.y = self.y - 14
	end

	-- sprite
	if (self.state != 11) then
		if (not on_ground) then
			self.frame = 1
		elseif (input_x != 0) then
			self.frame += 0.25
			self.frame = self.frame % 2
		else
			self.frame = 0
		end
	end
	self.spr = self.tile + self.frame

	-- object interactions
	for o in all(objects) do
		if (o.base == grapple_pickup and o.visible and self:overlaps(o)) then
			--grapple pickup
			o.destroyed = true
			have_grapple = true
		elseif (o.base == bridge and not o.falling and self:overlaps(o)) then
			--falling bridge tile
			o.falling = true
			self.freeze = 1
			shake = 2
		elseif (o.base == snowball and not o.held and self:overlaps(o)) then
			--snowball
			if (self.speed_y >= 0 and self.y - self.speed_y + o.speed_y < o.y + 2) then
				self.jump_grace_y = o.y
				self:jump()
				o.freeze = 1
				o.speed_y = -1
			elseif (o.speed_x != 0 and o.thrown_timer <= 0) then
				self:die()
				return
			end
		elseif (o.base == berry and self:overlaps(o)) then
			o:collect()
		elseif (o.base == crumble and self:overlaps(o, 0, 1)) then
			o:fall()
		end
	end

	-- death
	if (self.state != 99 and (self.y > level.height * 8 + 16 or self:hazard_check())) then
		self:die()
		return
	end

	-- bounds
	if (self.y < -16) then
		self.y = -16
		self.speed_y = 0
	end
	if (self.x < 3) then
		self.x = 3
		self.speed_x = 0
	elseif (self.x > level.width * 8 - 3) then
		self.x = level.width * 8 - 3
		self.speed_x = 0
	end

	-- camera
	camera_modes[level.camera_mode](self.x, self.y, on_ground)
	camera_x = approach(camera_x, camera_target_x, 5)
	camera_y = approach(camera_y, camera_target_y, 5)
	camera(camera_x, camera_y)
end

player.on_collide_x = function(self, moved, target)

	if (self.state == 0) then
		if (sgn(target) == input_x and self:corner_correct(input_x, 0, 2, 2, -1, self.correction_func)) then
			return false
		end
	elseif (self.state == 11) then
		if (self:corner_correct(self.grapple_dir, 0, 4, 2, 0, self.correction_func)) then
			return false
		end
	end

	return object.on_collide_x(self, moved, target)
end

player.on_collide_y = function(self, moved, target)
	if (target < 0 and self:corner_correct(0, -1, 2, 1, input_x, self.correction_func)) then
		return false
	end

	self.t_var_jump = 0
	return object.on_collide_y(self, moved, target)
end

player.draw = function(self)

	-- death fx
	if (self.state == 99) then
		local e = self.dead_timer / 10
		local dx = mid(camera_x, self.x, camera_x + 128)
		local dy = mid(camera_y, self.y - 4, camera_y + 128)
		if (e <= 1) then
			for i=0,7 do
				circfill(dx + cos(i / 8) * 32 * e, dy + sin(i / 8) * 32 * e, (1 - e) * 8, 10)
			end
		end
		return
	end

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

	-- failed grapple
	if (self.grapple_retract) then
		line(self.x, self.y - 3, self.grapple_x, self.grapple_y, 7)
	end

	-- sprite
	spr(self.spr, self.x - 4, self.y - 8, 1, 1, self.facing ~= 1)
end