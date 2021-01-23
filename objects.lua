crate = {}
crate.tile = 19
crate.base = object
crate.geom = g_solid
crate.init = function(self)
	self.spr = self.tile
end
crate.update = function(self) 
	self:move_y(1)
end

setmetatable(crate, lookup)
add(types, crate)

grapple = {}
grapple.tile = 20
grapple.base = object
grapple.draw = function(self)
	spr(self.tile, self.x, self.y + sin(time()) * 2, 1, 1, not self.right)
end

setmetatable(grapple, lookup)
add(types, grapple)