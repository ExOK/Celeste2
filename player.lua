player = {}
player.tile = 2
player.base = object

player.state = 0

player.init = function(self)
	self.spr = self.tile
end

player.update = function(self) 
	
	-- gravity
	if (not self:check_solid(0, 1)) then
		self.speed_y = min(self.speed_y + 10, 20)
	end

	-- apply
	self:move_y(self.speed_y)

end

setmetatable(player, lookup)
add(types, player)