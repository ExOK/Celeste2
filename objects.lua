grapple_pickup = new_type()
grapple_pickup.tile = 20
grapple_pickup.base = object
grapple_pickup.draw = function(self)
	spr(self.tile, self.x, self.y + sin(time()) * 2, 1, 1, not self.right)
end

spike_v = new_type()
spike_v.tile = 36
spike_v.base = object
spike_v.init = function(self)
	self.spr = self.tile
	if self:check_solid(0, -1) then
		self.flip_y = true
		self.hazard = 3
	else
		self.hit_y = 5
		self.hazard = 2
	end
	self.hit_h = 3
end

spike_h = new_type()
spike_h.tile = 37
spike_h.base = object
spike_h.hazard = true
spike_h.init = function(self)
	self.spr = self.tile
	if self:check_solid(-1, 0) then
		self.flip_x = true
		self.hazard = 4
	else
		self.hit_x = 5
		self.hazard = 5
	end
	self.hit_w = 3
end

snowball = new_type()
snowball.tile = 62
snowball.spr = 62
snowball.base = object
snowball.grapple_mode = 3
snowball.holdable = true
snowball.state = 0
snowball.thrown_timer = 0
snowball.update = function(self)
	if not self.held then
		if self.thrown_timer > 0 then
			self.thrown_timer -= 1
		end

		--speed
		if self.speed_x != 0 then
			self.speed_x = approach(self.speed_x, sgn(self.speed_x) * 2, 0.1)
		end

		--gravity
		local on_ground = self:check_solid(0, 1)
		if not on_ground then
			self.speed_y = approach(self.speed_y, 4, 0.4)
		end

		--apply
		self:move_x(self.speed_x, self.on_collide_x)
		self:move_y(self.speed_y, self.on_collide_y)

		if self.y > level.height * 8 + 24 then
			self.destroyed = true
		end
	end
end
snowball.on_collide_x = function(self, moved, total)
	self.speed_x *= -1
	self.freeze = 1
	return true
end
snowball.on_collide_y = function(self, moved, total)
	if self.speed_y >= 4 then
		self.speed_y = -2
	elseif self.speed_y >= 1 then
		self.speed_y = -1
	else
		self.speed_y = 0
	end
	self.remainder_y = 0
	return true
end
snowball.on_release = function(self, thrown)
	if thrown then
		self.thrown_timer = 5
	end
end

grappler = new_type()
grappler.tile = 46
grappler.spr = 46
grappler.base = object
grappler.grapple_mode = 2
grappler.hit_x = -1
grappler.hit_y = -1
grappler.hit_w = 10
grappler.hit_h = 10

bridge = new_type()
bridge.tile = 63
bridge.spr = bridge.tile
bridge.base = object
bridge.falling = false
bridge.update = function(self)
	self.y += 3 * (self.falling and 1 or 0)
end

berry = new_type()
berry.tile = 21
berry.base = object
berry.draw = grapple_pickup.draw
berry.collect = function(self)
	set_collected(flr(self.x / 8), flr(self.y / 8))
	berry_count += 1
	self.destroyed = true
end

crumble = new_type()
crumble.tile = 19
crumble.geom = g_solid
crumble.base = object
crumble.grapple_mode = 1
crumble.init = function(self)
	self.time = 0
	self.breaking = false
	self.ox = self.x
	self.oy = self.y
end
crumble.update = function(self)
	if self.breaking then
		self.time += 1
		if self.time > 10 then
			self.x = -32
			self.y = -32
		end
		if self.time > 60 then
			self.x = self.ox
			self.y = self.oy

			local can_respawn = true
			for o in all(objects) do
				if self:overlaps(o) then can_respawn = false break end
			end

			if can_respawn then
				self.breaking = false
				self.time = 0
			else
				self.x = -32
				self.y = -32
			end
		end
	end
end
crumble.draw = function(self)
	spr(self.tile, self.x, self.y)
	if self.time > 2 then
		fillp(0b1010010110100101.1)
		rectfill(self.x, self.y, self.x + 7, self.y + 7, 1)
		fillp()
	end
end
crumble.fall = function(self)
	self.breaking = true
end