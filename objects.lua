grapple_pickup = new_type(20)
grapple_pickup.draw = function(self)
	spr(self.spr, self.x, self.y + sin(time()) * 2, 1, 1, not self.right)
end

spike_v = new_type(36)
spike_v.init = function(self)
	if not self:check_solid(0, 1) then
		self.flip_y = true
		self.hazard = 3
	else
		self.hit_y = 5
		self.hazard = 2
	end
	self.hit_h = 3
end

spike_h = new_type(37)
spike_h.init = function(self)
	if self:check_solid(-1, 0) then
		self.flip_x = true
		self.hazard = 4
	else
		self.hit_x = 5
		self.hazard = 5
	end
	self.hit_w = 3
end

snowball = new_type(62)
snowball.grapple_mode = 3
snowball.holdable = true
snowball.thrown_timer = 0
snowball.hp = 6
snowball.update = function(self)
	if not self.held then
		self.thrown_timer -= 1

		--speed
		if self.speed_x != 0 then
			self.speed_x = approach(self.speed_x, sgn(self.speed_x) * 2, 0.1)
		end

		--gravity
		if not self:check_solid(0, 1) then
			self.speed_y = approach(self.speed_y, 4, 0.4)
		end

		--apply
		self:move_x(self.speed_x, self.on_collide_x)
		self:move_y(self.speed_y, self.on_collide_y)

		--bounds
		if self.y > level.height * 8 + 24 then
			self.destroyed = true
		end
	end
end
snowball.on_collide_x = function(self, moved, total)
	if self:corner_correct(sgn(self.speed_x), 0, 2, 2, 1) then
		return false
	end

	if self:hurt() then
		return true
	end

	self.speed_x *= -1
	self.remainder_x = 0
	self.freeze = 1
	psfx(17, 0, 2)
	return true
end
snowball.on_collide_y = function(self, moved, total)
	if self.speed_y < 0 then
		self.speed_y = 0
		self.remainder_y = 0
		return true
	end

	if self.speed_y >= 4 then
		self.speed_y = -2
		psfx(17, 0, 2)
	elseif self.speed_y >= 1 then
		self.speed_y = -1
		psfx(17, 0, 2)
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
snowball.hurt = function(self)
	self.hp -= 1
	if self.hp <= 0 then
		self.destroyed = true
		return true
	end
	return false
end
snowball.bounce_overlaps = function(self, o)
	if self.speed_x != 0 then
		self.hit_w = 12
		self.hit_x = -2
		local ret = self:overlaps(o)
		self.hit_w = 8
		self.hit_x = 0
		return ret
	else
		return self:overlaps(o)
	end
end

springboard = new_type(11)
springboard.grapple_mode = 3
springboard.holdable = true
springboard.thrown_timer = 0
springboard.update = function(self)
	if not self.held then
		self.thrown_timer -= 1

		--friction and gravity	
		if self:check_solid(0, 1) then
			self.speed_x = approach(self.speed_x, 0, 1)
		else
			self.speed_x = approach(self.speed_x, 0, 0.2)
			self.speed_y = approach(self.speed_y, 4, 0.4)
		end

		--apply
		self:move_x(self.speed_x, self.on_collide_x)
		self:move_y(self.speed_y, self.on_collide_y)

		if self.player != nil then
			self.player:move_y(self.speed_y)
		end

		self.destroyed = self.y > level.height * 8 + 24
	end
end
springboard.on_collide_x = function(self, moved, total)
	self.speed_x *= -0.2
	self.remainder_x = 0
	self.freeze = 1
	return true
end
springboard.on_collide_y = function(self, moved, total)
	if self.speed_y < 0 then
		self.speed_y = 0
		self.remainder_y = 0
		return true
	end

	if self.speed_y >= 2 then
		self.speed_y *= -0.4
	else
		self.speed_y = 0
	end
	self.remainder_y = 0
	self.speed_x *= 0.5
	return true
end
springboard.on_release = function(self, thrown)
	if thrown then
		self.thrown_timer = 5
	end
end

grappler = new_type(46)
grappler.grapple_mode = 2
grappler.hit_x = -1
grappler.hit_y = -1
grappler.hit_w = 10
grappler.hit_h = 10

bridge = new_type(63)
bridge.update = function(self)
	self.y += self.falling and 3 or 0
end

berry = new_type(21)
berry.update = function(self)
	if self.collected then
		self.timer += 1
		self.y -= 0.2 * (self.timer > 5 and 1 or 0)
		self.destroyed = self.timer > 30
	elseif self.player then
		self.x += (self.player.x - self.x) / 8
		self.y += (self.player.y - 4 - self.y) / 8
		self.flash -= 1

		if self.player:check_solid(0, 1) or self.player.x > level.width * 8 - 16 then
			psfx(8, 8, 8, 20)
			collected[self.id] = true
			berry_count += 1
			self.collected = true
			self.timer = 0
			self.draw = score
		end
	end
end
berry.collect = function(self, player)
	if not self.player then
		self.player = player
		self.flash = 5
		psfx(7, 12, 4)
	end
end
berry.draw = function(self)
	if (self.timer or 0) < 5 then
		grapple_pickup.draw(self)
		if (self.flash or 0) > 0 then
			circ(self.x + 4, self.y + 4, self.flash * 3, 7)
			circfill(self.x + 4, self.y + 4, 5, 7)
		end
	else
		print("1000", self.x - 4, self.y + 1, 8)
		print("1000", self.x - 4, self.y, self.timer % 4 < 2 and 7 or 14)
	end
end

crumble = new_type(19)
crumble.solid = true
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
		if self.time > 90 then
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
	object.draw(self)
	if self.time > 2 then
		fillp(0b1010010110100101.1)
		rectfill(self.x, self.y, self.x + 7, self.y + 7, 1)
		fillp()
	end
end

checkpoint = new_type(13)
checkpoint.init = function(self)
	if level_checkpoint == self.id then
		create(player, self.x, self.y)
	end
end
checkpoint.draw = function(self)
	if level_checkpoint == self.id then
		sspr(104, 0, 1, 8, self.x, self.y)
		pal(2, 11)
		for i=1,7 do
			sspr(104 + i, 0, 1, 8, self.x + i, self.y + sin(-time() * 2 + i * 0.25) * (i - 1) * 0.2)
		end
		pal()
	else
		object.draw(self)
	end
end

snowball_spawner_r = new_type(14)
snowball_spawner_r.init = function(self)
	self.timer = (self.x / 8) % 32
	self.spr = -1
end
snowball_spawner_r.update = function(self)
	self.timer += 1
	if self.timer >= 32 and abs(self.x - 64 - camera_x) < 128 then
		self.timer = 0
		local snowball = create(snowball, self.x, self.y - 8)
		snowball.speed_x = 2
		snowball.speed_y = 4
	end
end

snowball_spawner_l = new_type(15)
snowball_spawner_l.init = function(self)
	self.timer = (self.x / 8) % 32
	self.spr = -1
end
snowball_spawner_l.update = function(self)
	self.timer += 1
	if self.timer >= 32 and abs(self.x - 64 - camera_x) < 128 then
		self.timer = 0
		local snowball = create(snowball, self.x, self.y - 8)
		snowball.speed_x = -2
		snowball.speed_y = 4
	end
end