--
-- src/render.lua
--

local Vector = require 'src/Vector'

local function clock( x, y, radius, theta )
	local r = radius * 0.8
	local rx = x + (r * math.sin(theta))
	local ry = y + (r * math.cos(theta))

	love.graphics.push()
	
	love.graphics.setLineWidth(6)
	-- love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.circle('line', x, y, radius)
	love.graphics.line(x, y, rx, ry)

	love.graphics.setLineWidth(3)
	-- love.graphics.setColor(0, 0, 0, 255)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.circle('line', x, y, radius)
	love.graphics.line(x, y, rx, ry)	

	love.graphics.pop()
end

local function graph( graph )
	for edge, endverts in pairs(graph.edges) do
		love.graphics.line(endverts[1].x, endverts[1].y, endverts[2].x, endverts[2].y)
	end

	for vertex, peers in pairs(graph.vertices) do
		love.graphics.circle('line', vertex.x, vertex.y, 10)
	end
end

local function line( points )
	local flattened = {}

	for i = 1, #points do
		flattened[#flattened+1] = points[i].x
		flattened[#flattened+1] = points[i].y
	end

	love.graphics.setLineJoin('bevel')
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle('smooth')

	love.graphics.line(flattened)		
end

local function smoothLine( points, width, colour )
	width = width or 5
	colour = colour or { 255, 255, 255, 255 }

	local flattened = {}

	for i = 1, #points do
		flattened[#flattened+1] = points[i].x
		flattened[#flattened+1] = points[i].y
	end

	love.graphics.setLineJoin('bevel')
	love.graphics.setLineWidth(width)
	love.graphics.setColor(colour[1], colour[2], colour[3], colour[4])
	love.graphics.setLineStyle('smooth')

	love.graphics.line(flattened)

	for i = 1, #points do
		local point = points[i]
		love.graphics.circle('fill', point.x, point.y, 0.5 * width)
	end	
end

local function smoothLineUptoWithSpare( points, width, colour, uptoIndex, spare )
	width = width or 5
	colour = colour or { 255, 255, 255, 255 }
	uptoIndex = math.min(uptoIndex or #points, #points)
	spare = spare or 0

	local flattened = {}

	for i = 1, uptoIndex do
		flattened[#flattened+1] = points[i].x
		flattened[#flattened+1] = points[i].y
	end

	if spare > 0 and uptoIndex < #points then
		local uptoPoint = points[uptoIndex]
		local delta = Vector.to(uptoPoint, points[uptoIndex+1])

		local f = clampf(spare / delta:length(), 0, 1)
		flattened[#flattened+1] = uptoPoint.x + delta.x * f
		flattened[#flattened+1] = uptoPoint.y + delta.y * f
	end


	love.graphics.setLineJoin('bevel')
	love.graphics.setLineWidth(width)
	love.graphics.setColor(colour[1], colour[2], colour[3], colour[4])
	love.graphics.setLineStyle('smooth')

	if #flattened >= 4 then
		love.graphics.line(flattened)
	end

	for i = 1, #flattened, 2 do
		love.graphics.circle('fill', flattened[i], flattened[i+1], 0.5 * width)
	end	
end

return {
	clock = clock,
	graph = graph,
	line = line,
	smoothLine = smoothLine,
	smoothLineUptoWithSpare = smoothLineUptoWithSpare
}
