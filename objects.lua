crate = new_type()
crate.tile = 19
crate.base = object
crate.geom = g_solid
crate.init = function(self)
	self.spr = self.tile
end
crate.update = function(self) 
	self:move_y(1)
end

grapple = new_type()
grapple.tile = 20
grapple.base = object
grapple.draw = function(self)
	spr(self.tile, self.x, self.y + sin(time()) * 2, 1, 1, not self.right)
end

spike_v = new_type()
spike_v.tile = 36
spike_v.base = object
spike_v.hazard = true
spike_v.init = function(self)
	self.spr = self.tile
	if (self:check_solid(0, -1)) then
		self.flip_y = true
	else
		self.hit_y = 5
	end
	self.hit_h = 3
end

spike_h = new_type()
spike_h.tile = 37
spike_h.base = object
spike_h.hazard = true
spike_h.init = function(self)
	self.spr = self.tile
	if (self:check_solid(-1, 0)) then
		self.flip_x = true
	else
		self.hit_x = 5
	end
	self.hit_w = 3
end