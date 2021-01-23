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
object.right = true

object.move_x = function(self, x)	
	self.remainder_x += x
	local mx = flr(self.remainder_x + 0.5)
	self.remainder_x -= mx

	local total = mx
	local mxs = sign(mx)
	while (mx != 0)
	do
		if (self:check_solid(mxs, 0)) then
			self:on_collide_x(total - mx, total)
			break
		else
			self.x += mxs
			mx -= mxs
		end
	end
end

object.move_y = function(self, y)
	self.remainder_y += y
	local my = flr(self.remainder_y + 0.5)
	self.remainder_y -= my
	
	local total = my
	local mys = sign(my)
	while (my != 0)
	do
		if (self:check_solid(0, mys)) then
			self:on_collide_y(total - my, total)
			break
		else
			self.y += mys
			my -= mys
		end
	end
end

object.on_collide_x = function(self, moved, target)
	self.remainder_x = 0
	self.speed_x = 0
end

object.on_collide_y = function(self, moved, target)
	self.remainder_y = 0
	self.speed_y = 0
end

object.draw = function(self)
	if (self.spr != nil) then
		spr(self.spr, self.x, self.y, 1, 1, not self.right)
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

object.contains = function(self, px, py)
	return
		px >= self.x + self.hit_x and
		px < self.x + self.hit_x + self.hit_w and
		py >= self.y + self.hit_y and
		py < self.y + self.hit_y + self.hit_h
end

object.check_solid = function(self, ox, oy)
	if (ox == nil) then ox = 0 end
	if (oy == nil) then oy = 0 end

	for i = flr((ox + self.x + self.hit_x) / 8),flr((ox + self.x + self.hit_x + self.hit_w - 1) / 8) do
		for j = flr((oy + self.y + self.hit_y) / 8),flr((oy + self.y + self.hit_y + self.hit_h - 1) / 8) do
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

object.corner_correct = function(self, dir_x, dir_y, side_dist, look_ahead, only_sign)
	if (look_ahead == nil) then look_ahead = 1 end
	if (only_sign == nil) then only_sign = 0 end

	if (dir_x ~= 0) then
		for i = 1, side_dist do
			for s = 1, -2, -2 do
				if (s == -only_sign) then
					goto continue_x
				end

				if (not self:check_solid(dir_x, i * s)) then
					self.x += dir_x
					self.y += i * s
					return true
				end

				::continue_x::
			end
		end
	elseif (dir_y ~= 0) then
		for i = 1, side_dist do
			for s = 1, -1, -2 do
				if (s == -only_sign) then
					goto continue_y
				end

				if (not self:check_solid(i * s, dir_y)) then
					self.x += i * s
					self.y += dir_y
					return true
				end

				::continue_y::
			end
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