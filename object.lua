objects = {}
types = {}

lookup = {}
lookup.__index = function(self, i) return self.base[i] end

object = {}
object.speed_x = 0;
object.speed_y = 0;
object.remainder_x = 0;
object.remainder_y = 0;
object.move_x = function(self, x)
	local mx = 0;
	self.remainder_x += x;
	if (self.remainder_x < 0) then
		mx = flr(self.remainder_x - 0.5)
	else
		mx = flr(self.remainder_x + 0.5)
	end

	self.remainder_x -= mx;
	self.x += mx
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
	self.y += my
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