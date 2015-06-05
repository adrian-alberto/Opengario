Blob = class()
Blobs = List.new()

function Blob:init(pos, volume, id)
	local numVertices = 64
	self.id = id
	self.pos = pos
	self.velocity = Vector2.new()
	self.volume = volume
	self.radius = math.sqrt(volume/math.pi) * 10
	self.vertices = {}
	self.tweenedVertices = {}
	self.controlVec = Vector2.new()

	--Distances from center
	for i = 1, numVertices do
		self.vertices[i] = self.radius
		self.tweenedVertices[i] = self.radius
	end

	Blobs:add(self)
end

function Blob:update(dt)
	local force = self.controlVec:unit() * 10000

	--Check if can be devoured
	for _, other in pairs(Blobs:get()) do
		local distance = (other.pos - self.pos).magnitude
		local minDist = other.radius + self.radius
		if other ~= self and distance < minDist then
			if self.radius * 1.2 < other.radius then
				local squishDist = ((distance*distance - other.radius*other.radius + self.radius*self.radius) / (2*distance))
				if distance < (distance - squishDist) then
					Blobs:removeValue(self)
					other:setVolume(other.volume + self.volume)
					return
				end
			elseif other.radius * 1.2 > self.radius then
				--apply force
				force = force + ((self.pos - other.pos):unit() * (minDist^2 - distance^2))
			end
		end
	end

	--Phyics
	force = force + self.velocity * -(self.radius*2*math.pi)/20 --friction
	self.velocity = self.velocity + (force / (self.volume*10))
	self.pos = self.pos + self.velocity * dt

	self:deformShape()
end

function Blob:draw(camera)
	love.graphics.setColor(255,255,255,150)
	local poly = {}
	for i = 1, #self.tweenedVertices do
		local theta = math.pi*2*i/#self.tweenedVertices
		local distance = self.tweenedVertices[i]

		--Smooth out blob shape
		local avgsum = 0
		local avgcount = 0
		local avgwidth = math.floor(#self.tweenedVertices * 0.1)
		for j = -avgwidth, avgwidth do
			local k = j
			if i + j < 1 then
				k = j + #self.tweenedVertices
			elseif i + j > #self.tweenedVertices then
				k = j - #self.tweenedVertices
			end
			avgsum = avgsum + self.tweenedVertices[i + k]*(avgwidth + 1 - math.abs(j))
			avgcount = avgcount + (avgwidth + 1 - math.abs(j))
		end
		distance = math.min(distance, avgsum/avgcount)

		poly[2*i - 1] = math.cos(theta) * distance + self.pos.x
		poly[2*i] = math.sin(theta) * distance + self.pos.y
	end
	love.graphics.polygon("fill", poly)
	love.graphics.setColor(255,255,255,255)
	love.graphics.setLineWidth(5)
	love.graphics.polygon("line", poly)

	love.graphics.setColor(255,255,255,50)
	--love.graphics.circle("line", self.pos.x, self.pos.y, self.radius)
end

function Blob:setVolume(volume)
	self.volume = volume
	self.radius = math.sqrt(volume/math.pi) * 10
end

function Blob:deformShape()
	--Maximize blob radius
	for i, d in pairs(self.vertices) do
		self.vertices[i] = self.radius
	end

	--Calculate blob deformation
	for _, other in pairs(Blobs:get()) do
		if other ~= self then
			local distance = (other.pos - self.pos).magnitude
			local minDist = other.radius + self.radius
			local overlap = math.abs(other.radius + self.radius - distance)
			if distance < minDist then
				local squishDist = ((distance*distance - other.radius*other.radius + self.radius*self.radius) / (2*distance))
				local angleOfSquish = math.acos(squishDist/self.radius)
				local directionOfSquish = math.atan2(other.pos.y - self.pos.y, other.pos.x - self.pos.x)

				if distance > (distance - squishDist) then
				--if self.radius > overlap/2 and other.radius > overlap/2 then
					--Things get weird if trying to draw something that is practically engulfed by another blob.
					for i, d in pairs(self.vertices) do
						local theta = math.pi*2*i/#self.vertices
						local thetaOffset = ((directionOfSquish - theta) + math.pi) % (math.pi*2) - math.pi
						if math.abs(thetaOffset) <= angleOfSquish then
							--squishDist = distance - overlap/2
							self.vertices[i] = math.min(self.vertices[i], self.radius, squishDist/math.cos(thetaOffset))
						end
					end
				end
				
			end
		end
	end

	--Tween blob for drawing (Rewrite later?)
	for i, d in pairs(self.vertices) do
		self.tweenedVertices[i] = math.min(d, (self.tweenedVertices[i]*20 + d)/21)
	end
end