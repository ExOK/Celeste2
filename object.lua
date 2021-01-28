objects = {}
types = {}
lookup = {}
function lookup.__index(self, i) return self.base[i] end

object = {}
object.speed_x = 0;
object.speed_y = 0;
object.remainder_x = 0;
object.remainder_y = 0;
object.hit_x = 0
object.hit_y = 0
object.hit_w = 8
object.hit_h = 8
object.grapple_mode = 0
object.hazard = 0
object.facing = 1
object.freeze = 0

function object.move_x(self, x, on_collide)	
	self.remainder_x += x
	local mx = flr(self.remainder_x + 0.5)
	self.remainder_x -= mx

	local total = mx
	local mxs = sgn(mx)
	while mx != 0
	do
		if self:check_solid(mxs, 0) then
			if on_collide then
				return on_collide(self, total - mx, total)
			end
			return true
		else
			self.x += mxs
			mx -= mxs
		end
	end

	return false
end

function object.move_y(self, y, on_collide)
	self.remainder_y += y
	local my = flr(self.remainder_y + 0.5)
	self.remainder_y -= my
	
	local total = my
	local mys = sgn(my)
	while my != 0
	do
		if self:check_solid(0, mys) then
			if on_collide then
				return on_collide(self, total - my, total)
			end
			return true
		else
			self.y += mys
			my -= mys
		end
	end

	return false
end

function object.on_collide_x(self, moved, target)
	self.remainder_x = 0
	self.speed_x = 0
	return true
end

function object.on_collide_y(self, moved, target)
	self.remainder_y = 0
	self.speed_y = 0
	return true
end

function object.update() end
function object.draw(self)
	spr(self.spr, self.x, self.y, 1, 1, self.flip_x, self.flip_y)
end

function object.overlaps(self, b, ox, oy)
	if self == b then return false end
	ox = ox or 0
	oy = oy or 0
	return
		ox + self.x + self.hit_x + self.hit_w > b.x + b.hit_x and
		oy + self.y + self.hit_y + self.hit_h > b.y + b.hit_y and
		ox + self.x + self.hit_x < b.x + b.hit_x + b.hit_w and
		oy + self.y + self.hit_y < b.y + b.hit_y + b.hit_h
end

function object.contains(self, px, py)
	return
		px >= self.x + self.hit_x and
		px < self.x + self.hit_x + self.hit_w and
		py >= self.y + self.hit_y and
		py < self.y + self.hit_y + self.hit_h
end

function object.check_solid(self, ox, oy)
	ox = ox or 0
	oy = oy or 0

	for i = flr((ox + self.x + self.hit_x) / 8),flr((ox + self.x + self.hit_x + self.hit_w - 1) / 8) do
		for j = tile_y(oy + self.y + self.hit_y),tile_y(oy + self.y + self.hit_y + self.hit_h - 1) do
			if fget(tile_at(i, j), 1) then
				return true
			end
		end
	end

	for o in all(objects) do
		if o.solid and o != self and not o.destroyed and self:overlaps(o, ox, oy) then
			return true
		end
	end

	return false
end

function object.corner_correct(self, dir_x, dir_y, side_dist, look_ahead, only_sign, func)
	look_ahead = look_ahead or 1
	only_sign = only_sign or 1

	if dir_x ~= 0 then
		for i = 1, side_dist do
			for s = 1, -2, -2 do
				if s == -only_sign then
					goto continue_x
				end

				if not self:check_solid(dir_x, i * s) and (not func or func(self, dir_x, i * s)) then
					self.x += dir_x
					self.y += i * s
					return true
				end

				::continue_x::
			end
		end
	elseif dir_y ~= 0 then
		for i = 1, side_dist do
			for s = 1, -1, -2 do
				if s == -only_sign then
					goto continue_y
				end

				if not self:check_solid(i * s, dir_y) and (not func or func(self, i * s, dir_y)) then
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

function id(tx, ty) return level_index * 100 + flr(tx) + flr(ty) * 128 end

function create(type, x, y)
	local obj = {}
	obj.base = type
	obj.x = x
	obj.y = y
	obj.id = id(flr(x/8), flr(y/8))
	setmetatable(obj, lookup)
	add(objects, obj)
	if obj.init then obj.init(obj) end
	return obj
end

function new_type(spr)
	local obj = {}
	obj.spr = spr
	obj.base = object
	setmetatable(obj, lookup)
	types[spr] = obj
	return obj
end