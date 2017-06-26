--
-- Jumpflood.lua
--

local Jumpflood = {}
Jumpflood.__index = Jumpflood

local shaders = nil

local function loadShader( filepath )
	local code, size = love.filesystem.read(filepath)

	return love.graphics.newShader(code)
end

function Jumpflood.new( w, h )
	if not shaders then
		shaders = {
			init = loadShader('resource/jumpfloodinit.frag'),
			step = loadShader('resource/jumpfloodstep.frag'),
			final = loadShader('resource/jumpfloodfinal.frag'),
			finalFabulous = loadShader('resource/jumpfloodfinalfabulous.frag'),
			finalNoire = loadShader('resource/jumpfloodfinalnoire.frag'),
		}
	end

	local result = {
		w = w,
		h = h,
		-- canvas1 = love.graphics.newCanvas(w, h, 'rgba16f'),
		-- canvas2 = love.graphics.newCanvas(w, h, 'rgba16f'),
		canvas1 = love.graphics.newCanvas(w, h, 'rg16f'),
		canvas2 = love.graphics.newCanvas(w, h, 'rg16f'),
		final = nil
	}

	setmetatable(result, Jumpflood)

	return result
end

function Jumpflood:process( source )
	local start = love.timer.getTime()

	--local numSteps = math.floor(math.log(math.max(self.w, self.h), 2))
	local numSteps = math.ceil(math.log(math.max(self.w, self.h), 2))

	love.graphics.setCanvas(self.canvas1)
	love.graphics.setShader(shaders.init)
	love.graphics.draw(source)

	love.graphics.setShader(shaders.step)

	local front = self.canvas1
	local back = self.canvas2

	-- We add two steps to force two extra runs with step size 1
	for i = 1, numSteps+2 do
		local step = math.max(1, 2 ^ (numSteps - (i-1)))
		print(i, 'step', step)
		shaders.step:sendInt('step', step)

		love.graphics.setCanvas(back)
		love.graphics.draw(front)

		front, back = back, front
	end

	self.final = front

	love.graphics.setCanvas()
	love.graphics.setShader()

	local finish = love.timer.getTime()
	printf('jfa process %.2fms', 1000*(finish-start))
end

function Jumpflood:renderFinal( cutoff, blur )
	love.graphics.setShader(shaders.final)
	shaders.final:send('cutoff', cutoff)
	shaders.final:send('blur', blur)
	love.graphics.draw(self.final)
	love.graphics.setShader()
end

function Jumpflood:renderFinalFabulous( time, cutoff, blur, centreCoord, radius )
	love.graphics.setShader(shaders.finalFabulous)
	shaders.finalFabulous:send('time', time * 0.5)
	shaders.finalFabulous:send('cutoff', cutoff)
	shaders.finalFabulous:send('blur', blur)
	shaders.finalFabulous:send('centreCoord', { centreCoord.x, centreCoord.y })
	shaders.finalFabulous:send('radius', radius)
	love.graphics.draw(self.final)
	love.graphics.setShader()
end

function Jumpflood:renderFinalNoire( time, cutoff, blur, centreCoord, radius )
	love.graphics.setShader(shaders.finalNoire)
	shaders.finalNoire:send('time', time * 0.5)
	shaders.finalNoire:send('cutoff', cutoff)
	shaders.finalNoire:send('blur', blur)
	shaders.finalNoire:send('centreCoord', { centreCoord.x, centreCoord.y })
	shaders.finalNoire:send('radius', radius)
	love.graphics.draw(self.final)
	love.graphics.setShader()
end

return Jumpflood
