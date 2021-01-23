player = {}
player.tile = 2
player.base = object
player.jump_grace = 0
player.jump_grace_y = 0
player.t_var_jump = 0
player.var_jump_speed = 0

player.state = 0
player.frame = 0

player.init = function(self)
	self.spr = self.tile
	self.hit_x = -3
	self.hit_y = -6
	self.hit_w = 6
	self.hit_h = 6
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
		if (on_ground) then
			self.speed_x = approach(self.speed_x, input_x * 2, 0.6)
		elseif (input_x != 0) then
			self.speed_x = approach(self.speed_x, input_x * 2, 0.3)
		else
			self.speed_x = approach(self.speed_x, 0, 0.1)
		end

		-- gravity
		if (not on_ground) then
			self.speed_y = min(self.speed_y + 0.8, 6)
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
			self.jump_grace = 0
			self:move_y(self.jump_grace_y - self.y)
			self.t_var_jump = 4
			self.var_jump_speed = self.speed_y
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
	if (sign(target) == input_x and self:corner_correct(input_x, 0, 2, 1, -1)) then
		return
	end

	object.on_collide_x(self, moved, target)
end

player.on_collide_y = function(self, moved, target)
	if (target < 0 and self:corner_correct(0, -1, 2, 1, input_x)) then
		return
	end

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
end

setmetatable(player, lookup)
add(types, player)