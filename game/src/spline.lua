--
-- spline.lua
--

local Vector = require 'src/Vector'

local function catmullRom( p1, p2, p3, p4, t )
	assert(0 <= t and t <= 1)

	local vto = Vector.to
	local vmulnv = Vector.mulnv
	local vadd = Vector.add
	local vmadvnv = Vector.madvnv

	local f1 = 2*t^3 - 3*t^2 +1
	local f2 = t^3 - 2*t^2 + t
	local f3 = -2*t^3 + 3*t^2
	local f4 = t^3 - t^2

	local m1 = vto(p1, p3)
	-- m1:mulvn(m1, 0.5)
	local m2 = vto(p2, p4)
	-- m2:mulvn(m2, 0.5)

	local result = Vector.new { x = 0, y = 0 }

	vmulnv(result, f1, p2)
	vmadvnv(result, m1, f2, result)
	vmadvnv(result, p3, f3, result)
	vmadvnv(result, m2, f4, result)

	return result
end

local function catmullRomLinearise( points, tolerance )
	assert(#points >= 4)

	local result = {}

	local disp = Vector.to(points[2], points[1])
	disp:add(disp, points[1])

	for t = 0, 0.9, 0.1 do
		result[#result+1] = catmullRom(disp, points[1], points[2], points[3], t)
	end

	for i = 1, #points-3 do
		for t = 0, 0.9, 0.1 do
			local p1 = points[i]
			local p2 = points[i+1]
			local p3 = points[i+2]
			local p4 = points[i+3]
			result[#result+1] = catmullRom(p1, p2, p3, p4, t)
		end
	end

	local disp = Vector.to(points[#points-1], points[#points])
	disp:add(points[#points], disp)

	for t = 0, 1, 0.1 do
		local l = #points
		result[#result+1] = catmullRom(points[l-2], points[l-1], points[l], disp, t)
	end

	return result
end

return {
	catmullRom = catmullRom,
	catmullRomLinearise = catmullRomLinearise,
}
