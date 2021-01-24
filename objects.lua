grapple_pickup = new_type()
grapple_pickup.tile = 20
grapple_pickup.base = object
grapple_pickup.visible = true
grapple_pickup.draw = function(self)
	if (self.visible) then
		spr(self.tile, self.x, self.y + sin(time()) * 2, 1, 1, not self.right)
	end
end

spike_v = new_type()
spike_v.tile = 36
spike_v.base = object
spike_v.init = function(self)
	self.spr = self.tile
	if (self:check_solid(0, -1)) then
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
	if (self:check_solid(-1, 0)) then
		self.flip_x = true
		self.hazard = 4
	else
		self.hit_x = 5
		self.hazard = 5
	end
	self.hit_w = 3
end

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

snowball = new_type()
snowball.tile = 62
snowball.spr = 62
snowball.base = object
snowball.grapple_mode = 3
snowball.holdable = true
snowball.hit_w = 8
snowball.hit_h = 8

grappler = new_type()
grappler.tile = 46
grappler.spr = 46
grappler.base = object
grappler.grapple_mode = 2
grappler.hit_x = 1
grappler.hit_y = 1
grappler.hit_w = 6
grappler.hit_h = 6