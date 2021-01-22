player = {}
player.tile = 2
player.base = object

player.state = 0
player.frame = 0

player.init = function(self)
	self.spr = self.tile
end

player.update = function(self) 

	local on_ground = self:check_solid(0, 1)

	-- hacky sprite stuff
	if (input_x != 0) then
		self.right = input_x > 0
		self.frame += 0.25
	else
		self.frame = 0
	end
	self.spr = self.tile + flr(self.frame) % 2

	-- gravity
	if (not on_ground) then
		self.speed_y = min(self.speed_y + 10, 20)
	end

	-- running
	self.speed_x += input_x

	-- jumping
	if (on_ground and input_jump_pressed) then
		self.speed_y = -20
	end

	-- apply
	self:move_x(self.speed_x)
	self:move_y(self.speed_y)

end

player.draw = function(self)
	
	-- draw sprite
	object.draw(self)
end

setmetatable(player, lookup)
add(types, player)