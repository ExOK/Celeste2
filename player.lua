player = {}
player.tile = 2
player.base = object
player.jump_grace = 0

player.state = 0

player.init = function(self)
	self.spr = self.tile
end

player.update = function(self) 
	
	local on_ground = self:check_solid(0, 1)
	if (on_ground) then
		self.jump_grace = 4
	elseif (self.jump_grace > 0) then
		self.jump_grace -= 1
	end

	if (self.state == 0) then
		-- normal state

		-- gravity
		if (not on_ground) then
			self.speed_y = min(self.speed_y + 0.8, 6)
		end

		-- running
		if (on_ground) then
			self.speed_x = approach(self.speed_x, input_x * 2, 0.6)
		elseif (input_x != 0) then
			self.speed_x = approach(self.speed_x, input_x * 2, 0.3)
		else
			self.speed_x = approach(self.speed_x, 0, 0.1)
		end

		-- jumping
		if (self.jump_grace > 0 and input_jump_pressed) then
			self.speed_y = -8
			self.jump_grace = 0
		end
	end

	-- apply
	self:move_x(self.speed_x)
	self:move_y(self.speed_y)

end

setmetatable(player, lookup)
add(types, player)