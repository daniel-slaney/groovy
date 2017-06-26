--
-- src/GameMode.lua
--

local schema, GameMode = require 'src/mode' { 'GameMode' }
local Vector = require 'src/Vector'
local AABB = require 'src/AABB'
local roomgen = require 'src/roomgen'
local render = require 'src/render'
local graph2D = require 'src/graph2D'
local Jumpflood = require 'src/Jumpflood'
local spline = require 'src/spline'

local function shadowf( align, x, y, ... )
	love.graphics.setColor(0, 0, 0, 255)

	local font = love.graphics.getFont()

	local text = string.format(...)

	local hh = font:getHeight() * 0.5
	local hw = font:getWidth(text) * 0.5

	local tx, ty = 0, 0

	if align == 'cc' then
		tx = x - hw
		ty = y - hh
	end

	love.graphics.print(text, tx-1, ty-1)
	love.graphics.print(text, tx-1, ty+1)
	love.graphics.print(text, tx+1, ty-1)
	love.graphics.print(text, tx+1, ty+1)

	love.graphics.setColor(192, 192, 192, 255)

	love.graphics.print(text, tx, ty)
end

function GameMode:enter( reason )
	-- printf('GameMode:enter(%s)', reason)

	self.time = 0

	local w, h = love.graphics.getDimensions()

	self.trailCanvas = love.graphics.newCanvas(w, h, 'rgba8')
	self.bgJfa = Jumpflood.new(w, h)
	self.countdown = 0
	self.cursor = {
		index = 1,
		total = 0,
		spare = 0,
	}
	self.dir = Vector.new { x = 0, y = 0 }

	self.debugRender = false;

	self.flow = 0

	self:_gen()
end

local MAX_DEPTH = 5

function GameMode:_gen()
	-- local margin = 75
	-- easy mode for Ruby
	local margin = 75
	local w, h = love.graphics.getDimensions()

	local bbox = AABB.new {
		xmin = 0,
		ymin = 0,
		xmax = w,
		ymax = h
	}

	bbox = bbox:shrink(margin)

	local points, graph, overlay = roomgen.random(bbox, margin)

	local walk = {}

	for i = 1, 10 do
		local candidateWalk = graph2D.randomWalk(graph)
		if #candidateWalk > #walk then
			walk = candidateWalk
		end
	end

	-- local subdividedWalk = {}
	-- local maxLength = 2
	-- for i = 1, #walk-1 do
	-- 	local from = walk[i]
	-- 	local to = walk[i+1]

	-- 	local delta = Vector.to(from, to)

	-- 	local numLengths = math.ceil(delta:length() / maxLength)

	-- 	if numLengths > 1 then
	-- 		subdividedWalk[#subdividedWalk+1] = from

	-- 		for i = 1, numLengths-1 do
	-- 			subdividedWalk[#subdividedWalk+1] = Vector.new {
	-- 				x = from.x + i * (delta.x / numLengths),
	-- 				y = from.y + i * (delta.y / numLengths),
	-- 			}	
	-- 		end			
	-- 	else
	-- 		subdividedWalk[#subdividedWalk+1] = from
	-- 		subdividedWalk[#subdividedWalk+1] = to
	-- 	end
	-- end

	self.points = points
	self.graph = graph
	-- self.walk = subdividedWalk
	self.walk = walk

	self.spline = spline.catmullRomLinearise(self.walk)
	self.walk = self.spline

	love.graphics.setCanvas(self.trailCanvas)
	love.graphics.clear(0, 0, 0, 255)
	render.smoothLine(self.walk)
	love.graphics.setCanvas()

	self.bgJfa:process(self.trailCanvas)

	self.cursor = {
		index = 1,
		total = 0,
		spare = 0,
	}
	self.finished = false
	self.score = 0
end

function GameMode:_tip()
	local walk = self.walk
	local index = self.cursor.index
	local spare = self.cursor.spare

	if index >= #walk then
		return Vector.new(walk[#walk])
	end

	local uptoPoint = walk[index]
	local delta = Vector.to(uptoPoint, walk[index+1])

	local f = clampf(spare / delta:length(), 0, 1)
	return Vector.new {
		x = uptoPoint.x + delta.x * f,
		y = uptoPoint.y + delta.y * f
	}
end

function GameMode:update( dt )
	self.time = self.time + dt
	self.countdown = self.countdown - dt

	if self.finished and self.countdown < 0 then
		self:_gen()
	end

	local start = love.timer.getTime()

	local deadzone = 0.15

	-- self.bgJfa:process(self.trailCanvas)

	if self.dir:length() > deadzone and not self.finished then
		local pps = 200
		local capacity = pps * dt
		local cursor = self.cursor
		local walk = self.walk
		local finished = false

		local flow = 0

		while capacity > 0 do
			assert(cursor.index < #walk)

			local currentPoint = walk[cursor.index]
			local nextPoint = walk[cursor.index+1]
			local delta = Vector.to(currentPoint, nextPoint)
			local tangent = delta:normal()

			local deltaLength = delta:length()
			local proj = Vector.dot(tangent, self.dir)

			if proj < 0 then
				proj = 0
			else
				local ndir = self.dir:normal()
				local ndot = Vector.dot(ndir, tangent)
				flow = math.max(ndot, flow)
			end

			local movement = clampf(proj * dt * pps, 0, capacity)

			local needed = deltaLength - cursor.spare

			-- print(energy, proj, dt, pps, deltaLength, cursor.spare, movement, needed)

			if movement < needed then
				cursor.spare = cursor.spare + movement
				capacity = 0
			else
				cursor.index = cursor.index + 1

				if cursor.index == #walk then
					finished = true
					break
				end

				-- Could be working off stored energy
				if needed > 0 then
					capacity = capacity - needed
				end

				cursor.spare = 0				
			end
		end

		if flow > self.flow then
			self.flow = math.min(flow, self.flow + dt * 0.5)
		else
			self.flow = math.max(flow, self.flow - dt * 0.5)
		end

		if finished then
			self.finished = true
			-- self.countdown = 4
			self.countdown = 0
		end
	else
		self.flow = math.max(0, self.flow - dt * 0.5)
	end

	self.score = self.score + self.flow * dt

	local finish = love.timer.getTime()
	-- printf('update %.2fs', finish-start)
end

function GameMode:draw()
	love.graphics.push()

	love.graphics.setColor(255, 255, 255, 255)

	-- local cutoff = 25 * self.flow
	-- local cutoff = lerpf(math.sin(self.time / math.pi)^2, 0, 1, 10, 100) * self.flow
	local cutoff = 20 + 20* ((self.time * 1.5) % 1)^2
	local blur = 10
	local centre = self:_tip()
	local radius = lerpf(self.flow, 0, 1, 4, 9)

	if not self.debugRender then
		if self.flow > 0.85 then
			love.graphics.setColor(255, 255, 255, 255)
			self.bgJfa:renderFinalFabulous(self.time, cutoff, blur, centre, radius)
		else
			local f = lerpf(self.flow, 0, 0.85, 128, 255)
			love.graphics.setColor(f, f, f, 255)
			self.bgJfa:renderFinalFabulous(self.time, cutoff, blur, centre, radius)
			-- self.bgJfa:renderFinal(cutoff, blur)
		end
	elseif self.debugRender == 'noire' then
	if self.flow > 0.85 then
			love.graphics.setColor(255, 255, 255, 255)
			self.bgJfa:renderFinalNoire(self.time, cutoff, blur, centre, radius)
		else
			local f = lerpf(self.flow, 0, 0.85, 128, 255)
			love.graphics.setColor(f, f, f, 255)
			self.bgJfa:renderFinalNoire(self.time, cutoff, blur, centre, radius)
			-- self.bgJfa:renderFinal(cutoff, blur)
		end
	elseif self.debugRender == 'graph' then
		love.graphics.setColor(255, 255, 255, 255)

		love.graphics.setLineJoin('none')
		love.graphics.setLineStyle('rough')
		love.graphics.setLineWidth(2)

		render.graph(self.graph)

		love.graphics.setLineJoin('bevel')
		love.graphics.setLineStyle('smooth')
		love.graphics.setLineWidth(10)

		render.line(self.walk)
	elseif self.debugRender == 'trailCanvas' then
		love.graphics.draw(self.trailCanvas)
	elseif self.debugRender == 'bgJfaFinal' then
		-- local cutoff = 25 * lerpf(math.sin(self.time * 2), -1, 1, 0, 1)
		local cutoff = 25 * self.flow
		local blur = 5
		self.bgJfa:renderFinal(cutoff, 5)
	elseif self.debugRender == 'bgJfaFinalFabulous' then
		love.graphics.setColor(255, 255, 255, 255)
		local cutoff = 25
		local blur = 5
		local centre = self:_tip()
		local radius = 20
		self.bgJfa:renderFinalFabulous(self.time, cutoff, blur, centre, radius)
	elseif self.debugRender == 'spline' then
		render.line(self.spline)
	end

	render.smoothLineUptoWithSpare(self.walk, 3, { 0, 0, 0, 255 }, self.cursor.index, self.cursor.spare)
	local tip = self:_tip()
	love.graphics.circle('fill', tip.x, tip.y, radius - 1)

	love.graphics.pop()

	shadowf('lt', 60, 40, '%shz %s flow:%.02f score:%.2f', love.timer.getFPS(), not self.debugRender and ' ' or self.debugRender, self.flow, self.score)
end

function GameMode:keypressed( key, is_repeat )
	if key == 'space' then
		self:_gen()
	elseif key == 'd' then
		local options = { false, 'noire', 'graph', 'trailCanvas', 'bgJfaFinal', 'bgJfaFinalFabulous', 'spline' }

		for i, option in ipairs(options) do
			if self.debugRender == option then
				self.debugRender = options[i+1 <= #options and i+1 or 1]
				break
			end
		end
	end
end

function GameMode:gamepadaxis(joystick, axis, value)
	if axis == 'leftx' then
		self.dir.x = value
	elseif axis == 'lefty' then
		self.dir.y = value
	end
end
