player = {}
player.tile = 2
player.base = object
player.init = function(self)
	self.spr = self.tile
end
player.update = function(self) 
	if (not self:check_solid(0, 1)) then
		self:move_y(0.5)
	end
end

setmetatable(player, lookup)
add(types, player)