function love.load()
	require "oop"
	require "vector"
	require "blobs"
	print("Hello, world!")

	TestBlob = Blob.new(Vector2.new(400,250), 300)
	TestBlob2 = Blob.new(Vector2.new(220,300), 250)
	TestBlob3 = Blob.new(Vector2.new(600,600), 100)
end

function love.update(dt)
	TestBlob.controlVec = Vector2.new((love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0), (love.keyboard.isDown("s") and 1 or 0) - (love.keyboard.isDown("w") and 1 or 0))
	for _, blob in pairs(Blobs:get()) do
		blob:update(dt)
	end
end

function love.draw()
	love.graphics.print("Hello, world", 10, 10)
	for _, blob in pairs(Blobs:get()) do
		blob:draw()
	end
end
