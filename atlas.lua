--[[
Atlas
stores coordinates in integer-based grid
includes the grid tile width

stores quad and assigns address?


]]
local images = {}
function img(filename)
	if not filename then return end
	if images[filename] then
		return images[filename]
	elseif love.filesystem.exists("resources/textures/"..filename) then
		images[filename] = love.graphics.newImage("resources/textures/"..filename)
		images[filename]:setFilter("nearest","nearest")
		images[filename]:setWrap("repeat","clamp")
		return images[filename]
	end
end

Atlas = class()

function Atlas:init(filename, cellSizeX, cellSizeY, addresses)
	local texture = img(filename)
	self.quadMap = {}
	self.cx = cellSizeX
	self.cy = cellSizeY
	if texture then
		self.texture = texture
		local width, height = texture:getDimensions()
		self.mx = math.floor(width/cellSizeX)
		self.my = math.floor(height/cellSizeY)
		for x = 1, math.floor(width/cellSizeX) do
			self.quadMap[x] = {}
			for y = 1, math.floor(height/cellSizeY) do
				self.quadMap[x][y] = love.graphics.newQuad((x-1)*cellSizeX, (y-1)*cellSizeY, cellSizeX, cellSizeY, width, height)
			end
		end
	end
	self.addresses = addresses
end

function Atlas:getXY(x, y)
	return self.quadMap[x] and self.quadMap[x][y] or false
end

function Atlas:get(key)
	--local length = self.quadMap[1] and self.quadMap[1].size or error("No quad values in atlas")
	return self:getXY(self.addresses:get(key, self.mx)) or error("No quad at key '" .. key .. "'")
end

function Atlas:draw(key, x, y, r, sx, sy, ox, oy, kx, ky)
	if self.texture then
		love.graphics.draw(self.texture, self:get(key), x, y, r, sx, sy, ox, oy, kx, ky)
	else
		print("no texture")
		--default texture?
	end
end




AddressBook = class()

function AddressBook:init(filename, sub, overrideWidth, offsetRow, offsetCol)
	self.values = {}
	self.ow = overrideWidth
	self.ox = offsetRow or 0
	self.oy = offsetCol or 0
	if love.filesystem.exists("resources/data/"..filename) then
		local f = love.filesystem.newFile("resources/data/"..filename, "r")
		local str = f:read()
		f:close()

		if sub then
			for x in string.gmatch(str, "%w+:.-;") do
				local tag = string.match(x, "^(%w+)")

				if tag == sub then
					str = string.match(x, ":(.-);")
				end
			end
		end

		local index = 0
		for key in string.gmatch(str, "%w+") do
			index = index + 1
			self.values[key] = index
		end
	else
		error("Missing spritesheet atlas 'resources/data/" .. filename .. "'")
	end
end

function AddressBook:get(key, rowLength)
	rowLength = self.ow or rowLength
	if self.values[key] then
		if rowLength then
			return ((self.values[key]-1) % (rowLength))+1 + self.ox, math.floor(self.values[key] / (rowLength + .5)) + 1 + self.oy
		else
			return self.values[key], 1
		end
	end
	return -1, -1
end
