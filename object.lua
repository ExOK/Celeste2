objects = {}
types = {}

lookup = {}
lookup.__index = function(self, i) return self.base[i] end

g_none = 0
g_solid = 1
g_jumptrhu = 2

object = {}
object.speed_x = 0;
object.speed_y = 0;
object.remainder_x = 0;
object.remainder_y = 0;
object.hit_x = 0
object.hit_y = 0
object.hit_w = 8
object.hit_h = 8
object.geom = g_none
object.actor = true

object.move_x = function(self, x)
	local mx = 0;
	self.remainder_x += x;
	if (self.remainder_x < 0) then
		mx = flr(self.remainder_x - 0.5)
	else
		mx = flr(self.remainder_x + 0.5)
	end

	self.remainder_x -= mx;

	local mxs = sign(mx)
	while (mx != 0)
	do
		if (self:check_solid(mxs)) then
			break
		else
			self.x += mxs
			mx -= mxs
		end
	end
end

object.move_y = function(self, y)
	local my = 0;	
	self.remainder_y += y;
	if (self.remainder_y < 0) then
		my = flr(self.remainder_y - 0.5)
	else
		my = flr(self.remainder_y + 0.5)
	end

	self.remainder_y -= my;
	
	local mys = sign(my)
	while (my != 0)
	do
		if (self:check_solid(mys)) then
			break
		else
			self.y += mys
			my -= mys
		end
	end
end

object.draw = function(self)
	if (self.spr != nil) then
		spr(self.spr, self.x, self.y)
	end
end

object.overlaps = function(self, b, ox, oy)
	if (ox == nil) then ox = 0 end
	if (oy == nil) then oy = 0 end
	return
		ox + self.x + self.hit_x + self.hit_w > b.x + b.hit_x and
		oy + self.y + self.hit_y + self.hit_h > b.y + b.hit_y and
		ox + self.x + self.hit_x < b.x + b.hit_x + b.hit_w and
		oy + self.y + self.hit_y < b.y + b.hit_y + b.hit_h
end

object.check_solid = function(self, ox, oy)
	if (ox == nil) then ox = 0 end
	if (oy == nil) then oy = 0 end

	for i = flr((ox + self.x + self.hit_x) / 8),flr((ox + self.x + self.hit_x + self.hit_w) / 8) do
		for j = flr((oy + self.y + self.hit_y) / 8),flr((oy + self.y + self.hit_y + self.hit_h) / 8) do
			if (fget(room_tile_at(i, j), 1)) then
				return true
			end
		end
	end

	for i=1,#objects do
		local o = objects[i]
		if (o.geom == g_solid and o != self and self:overlaps(o, ox, oy)) then
			return true
		end
	end

	return false
end

function create(type, x, y)
	local obj = {}
	obj.base = type
	obj.x = x
	obj.y = y
	setmetatable(obj, lookup)
	add(objects, obj)
	if (obj.init) then obj.init(obj) end
	return obj
end