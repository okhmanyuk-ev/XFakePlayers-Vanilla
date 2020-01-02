Vec3 = {}
Vec3.__index = Vec3

function Vec3.New(X, Y, Z)
  return setmetatable({X = X or 0, Y = Y or 0, Z = Z or 0}, Vec3)
end

function Vec3.__eq(A, B)
	if type(A) == 'number' then
		return A == B.X and A == B.Y and A == B.Z
	elseif type(B) == 'number' then
		return A.X == B and A.Y == B and A.Z == B
	else
		return A.X == B.X and A.Y == B.Y and A.Z == B.Z
	end
end

function Vec3.__add(A, B)
	if type(A) == 'number' then
		return Vec3.New(A + B.X, A + B.Y, A + B.Z)
	elseif type(B) == 'number' then
		return Vec3.New(A.X + B, A.Y + B, A.Z + B)
	else
		return Vec3.New(A.X + B.X, A.Y + B.Y, A.Z + B.Z)
	end
end

function Vec3.__sub(A, B)
	if type(A) == 'number' then
		return Vec3.New(A - B.X, A - B.Y, A - B.Z)
	elseif type(B) == 'number' then
		return Vec3.New(A.X - B, A.Y - B, A.Z - B)
	else
		return Vec3.New(A.X - B.X, A.Y - B.Y, A.Z - B.Z)
	end
end

function Vec3.__mul(A, B)
	if type(A) == 'number' then
		return Vec3.New(A * B.X, A * B.Y, A * B.Z)
	elseif type(B) == 'number' then
		return Vec3.New(A.X * B, A.Y * B, A.Z * B)
	else
		return Vec3.New(A.X * B.X, A.Y * B.Y, A.Z * B.Z)
	end
end

function Vec3.__div(A, B)
	if type(A) == 'number' then
		return Vec3.New(A / B.X, A / B.Y, A / B.Z)
	elseif type(B) == 'number' then
		return Vec3.New(A.X / B, A.Y / B, A.Z / B)
	else
		return Vec3.New(A.X / B.X, A.Y / B.Y, A.Z / B.Z)
	end
end

function Vec3.__tostring(A)
	return('X: ' .. math.floor(A.X) .. ', Y: ' .. math.floor(A.Y) .. ', Z: ' .. math.floor(A.Z))
end

function Vec3:DotProduct(A)
  return((self.X * A.X) + (self.Y * A.Y) + (self.Z * A.Z))
end

function Vec3:Length()
	return math.sqrt(self:DotProduct(self))
end

function Vec3:Distance(A)
	return math.abs((A - self):Length())
end

function Vec3:Unpack()
	return self.X, self.Y, self.Z
end

Vec2 = {}
Vec2.__index = Vec2

function Vec2.New(X, Y)
	return setmetatable({X = X or 0, Y = Y or 0}, Vec2)
end

function Vec2.__eq(A, B)
	if type(A) == 'number' then
		return A == B.X and A == B.Y
	elseif type(B) == 'number' then
		return A.X == B and A.Y == B
	else
		return A.X == B.X and A.Y == B.Y
	end
end

function Vec2.__add(A, B)
	if type(A) == 'number' then
		return Vec2.New(A + B.X, A + B.Y)
	elseif type(B) == 'number' then
		return Vec2.New(A.X + B, A.Y + B)
	else
		return Vec2.New(A.X + B.X, A.Y + B.Y)
	end
end

function Vec2.__sub(A, B)
	if type(A) == 'number' then
		return Vec2.New(A - B.X, A - B.Y)
	elseif type(B) == 'number' then
		return Vec2.New(B.X - A, B.Y - A)
	else
		return Vec2.New(A.X - B.X, A.Y - B.Y)
	end
end

function Vec2.__mul(A, B)
	if type(A) == 'number' then
		return Vec2.New(A * B.X, A * B.Y)
	elseif type(B) == 'number' then
		return Vec2.New(A.X * B, A.Y * B)
	else
		return Vec2.New(A.X * B.X, A.Y * B.Y)
	end
end

function Vec2.__div(A, B)
	if type(A) == 'number' then
		return Vec2.New(A / B.X, A / B.Y)
	elseif type(B) == 'number' then
		return Vec2.New(A.X / B, A.Y / B)
	else
		return Vec2.New(A.X / B.X, A.Y / B.Y)
	end
end

function Vec2.__tostring(A)
	return('X: ' .. math.floor(A.X) .. ', Y: ' .. math.floor(A.Y))
end

function Vec2:Length()
	return math.sqrt((self.X * self.X) + (self.Y * self.Y))
end

Vec3Line = {}
Vec3Line.__index = Vec3Line

function Vec3Line.New(HiX, HiY, HiZ, LoX, LoY, LoZ)
	return setmetatable({HiX = HiX or 0, HiY = HiY or 0, HiZ = HiZ or 0, LoX = LoX or 0, LoY = LoY or 0, LoZ = LoZ or 0}, Vec3Line)
end

function Vec3Line.__tostring(A)
	return('Hi: [X: ' .. A.HiX .. ', Y: ' .. A.HiY .. ', Z: ' .. A.HiZ .. '], Lo [X: ' .. A.LoX .. ', Y: ' .. A.LoY .. ', Z: ' .. A.LoZ .. ']') 
end

function Vec3Line:Center()
	local Lo = Vec3.New(self.LoX, self.LoY, self.LoZ)
	local Hi = Vec3.New(self.HiX, self.HiY, self.HiZ)
	
	return (Lo + Hi) / 2
end

function Vec3Line:IsIntersect2D(A)
	local ADX = self.LoX - self.HiX
	local ADY = self.LoY - self.HiY
	
	local BDX = A.LoX - A.HiX
	local BDY = A.LoY - A.HiY
	
	local F1 = ADX * (A.HiY - self.HiY) - ADY * (A.HiX - self.HiX)
	local F2 = ADX * (A.LoY - self.HiY) - ADY * (A.LoX - self.HiX)
	local F3 = BDX * (self.HiY - A.HiY) - BDY * (self.HiX - A.HiX)
	local F4 = BDX * (self.LoY - A.HiY) - BDY * (self.LoX - A.HiX)

	return (F1 * F2 < 0) and (F3 * F4 < 0)
end

Vec2Line = {}
Vec2Line.__index = Vec2Line

function Vec2Line.New(HiX, HiY, LoX, LoY)
	return setmetatable({HiX = HiX or 0, HiY = HiY or 0, LoX = LoX or 0, LoY = LoY or 0}, Vec2Line)
end

function Vec2Line.__tostring(A)
	return('Hi: [X: ' .. A.HiX .. ', Y: ' .. A.HiY .. '], Lo [X: ' .. A.LoX .. ', Y: ' .. A.LoY .. ']') 
end