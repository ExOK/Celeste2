player = {}
player.tile = 2
player.base = object
player.init = function(self)
	self.spr = self.tile
end
player.update = function(self) 
	if (not solid_at(self.x, self.y + 1, 8, 8)) then
		self.move_y(self, 0.5)
	end
end
setmetatable(player, lookup)