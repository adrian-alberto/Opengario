ui = {}
function ui.padNum(num, leftN, rightN)
	local int = math.floor(num) .. ""
	local dec = num % 1 .. ""

	--left padding
	if leftN and string.len(int) < leftN then
		int = string.rep("0", leftN - string.len(int)) .. int
	end

	if rightN and string.len(dec) < rightN then
		dec = dec .. string.rep("0", rightN - string.len(dec))
	end

	if rightN and rightN > 0 then
		return int .. "." .. dec
	else
		return int
	end
end

UDim = class()
UDim.scale = Vector2.new()
UDim.offset = Vector2.new()

function UDim:init(sx, ox, sy, oy)
	self.scale = Vector2.new(sx, sy)
	self.offset = Vector2.new(ox, oy)
end

function UDim:absolute(vec, vec2)
	return self.scale * vec + self.offset + (vec2 or Vector2.new())
end


ScreenUI = class()
ScreenUI.size = UDim.new(1,0,1,0)
ScreenUI.pos = UDim.new(0,0,0,0)
ScreenUI.visible = true
ScreenUI.testBoxes = false
ScreenUI.textFocus = nil

function ScreenUI:init()
	self.pos = pos
	self.size = size
	self.absPos = self.pos:absolute(Vector2.new(love.window.getWidth(), love.window.getHeight()))
	self.absSize = self.size:absolute(Vector2.new(love.window.getWidth(), love.window.getHeight()))
	self.DRAWN = Event.new()
	self.MOUSEDOWN = Event.new()
	self.MOUSEUP = Event.new()
	self.CHANGED = Event.new()
	self.references = {}
end

function ScreenUI:draw()
	self.DRAWN:fire()
end

function ScreenUI:mouseDown(const)
	if not self.visible then
		return
	end
	self.clicked = false
	self.MOUSEDOWN:fire(love.mouse.getX(), love.mouse.getY(), const)
	if self.textFocus and self.clicked ~= self.textFocus then
		self.textFocus:unfocus()
	end
	return self.clicked
end

function ScreenUI:mouseUp(const)
	if not self.visible then
		return
	end
	self.MOUSEUP:fire(love.mouse.getX(), love.mouse.getY(), const)
end

function ScreenUI:setSize(size)
	self.size = size
	self.absSize = self.size:absolute(Vector2.new(love.window.getWidth(), love.window.getHeight()))
	self.CHANGED:fire()
end

function ScreenUI:setPos(pos)
	self.pos = pos
	self.absPos = self.pos:absolute(Vector2.new(love.window.getWidth(), love.window.getHeight()))
	self.CHANGED:fire()
end

function ScreenUI:get(ref)
	return self.references[ref] --or print("no reference to ui object: '" .. tostring(ref) .. "'")
end









BaseUI = class()
BaseUI.minPixelSize = 1
BaseUI.size = UDim.new()
BaseUI.pos = UDim.new()
BaseUI.visible = true
BaseUI.mouseActive = true
BaseUI.clipsDescendants = false
BaseUI.color = Color.new(255,255,255)

function BaseUI:init(parent, id, pos, size)
	if id and type(id) ~= "string" then
		error("bad ui id")
	end
	self.parent = parent or error("must have parent")
	self.id = id
	self.pos = pos
	self.size = size
	self.absPos = self.pos:absolute(self.parent.absSize, self.parent.absPos)
	self.absSize = self.size:absolute(self.parent.absSize)
	self.DRAWN = Event.new()
	self.MOUSEDOWN = Event.new()
	self.MOUSEUP = Event.new()
	self.CHANGED = Event.new()
	self.pressed = false

	if id then
		self:getScreen().references[id] = self
	end

	self.drawn_c = self.parent.DRAWN:connect(function()
		if self.visible then
			if self.clipsDescendants then
				love.graphics.setStencil(function()
					love.graphics.rectangle("fill", self.absPos.x, self.absPos.y, self.absSize.x, self.absSize.y)
				end)
				if self.draw then
					self:draw()
				end
				self.DRAWN:fire()
				love.graphics.setStencil()
			else
				if self.draw then
					self:draw()
				end
				self.DRAWN:fire()
			end
		end
	end)

	self.mousedown_c = self.parent.MOUSEDOWN:connect(function(mx, my, const)
		if not self.visible then
			return
		end
		if self.mouseDown and self:isMouseWithin(mx, my) then
			self:mouseDown(mx, my, const)
			self.pressed = true
			self:getScreen().clicked = self.mouseActive and self
		end
		self.MOUSEDOWN:fire(mx, my, const)
	end)

	self.mouseup_c = self.parent.MOUSEUP:connect(function(mx, my, const)
		if not self.visible then
			return
		end
		if self.mouseUp and self.pressed and self:isMouseWithin(mx, my) then
			self:mouseUp(mx, my, const)
		end
		self.pressed = false
		self.MOUSEUP:fire(mx, my, const)
	end)

	self.changed_c = self.parent.CHANGED:connect(function()
		self.absPos = self.pos:absolute(self.parent.absSize, self.parent.absPos)
		self.absSize = self.size:absolute(self.parent.absSize)
		self.CHANGED:fire()
	end)
end

function BaseUI:getScreen()
	local p = self.parent
	while not p.instanceOf(ScreenUI) do
		p = p.parent
	end
	return p
end

function BaseUI:isMouseWithin(mx, my)
	mx = mx or love.mouse.getX()
	my = my or love.mouse.getY()
	local topLeft = self.absPos
	local bottomRight = self.absPos + self.absSize
	if mx >= topLeft.x and mx <= bottomRight.x and my >= topLeft.y and my <= bottomRight.y then
		return true
	end
end

function BaseUI:setSize(size)
	self.size = size
	self.absSize = self.size:absolute(self.parent.absSize)
	self.CHANGED:fire()
end

function BaseUI:setPos(pos)
	self.pos = pos
	self.absPos = self.pos:absolute(self.parent.absSize, self.parent.absPos)
	self.CHANGED:fire()
end


function BaseUI:remove()
	if self.id then
		self:getScreen().references[self.id] = nil
	end
	self.drawn_c:disconnect()
	self.mousedown_c:disconnect()
	self.mouseup_c:disconnect()
end

function BaseUI:draw()
	self.color:set()
	love.graphics.setLineWidth(1)
	love.graphics.rectangle("line", self.absPos.x, self.absPos.y, self.absSize.x, self.absSize.y)
end

function BaseUI:outline(linewidth)
	self.color:set()
	love.graphics.setLineWidth(linewidth or 1)
	love.graphics.rectangle("line", self.absPos.x, self.absPos.y, self.absSize.x, self.absSize.y)
end

function BaseUI:fill(opacity)
	self.color:setAlpha(opacity or 255)
	love.graphics.rectangle("fill", self.absPos.x, self.absPos.y, self.absSize.x, self.absSize.y)
end

function BaseUI:mouseDown(mx, my, const)
	--[[
	if const == "l" then
		print(self.id .. " down: " .. const)
	end
	]]
end

function BaseUI:mouseUp(mx, my, const)
	--[[
	if const == "l" then
		print(self.id .. " up: " .. const)
	end
	]]
end


ContainerUI = class(BaseUI)
ContainerUI.borderWidth = 0
ContainerUI.fillOpacity = 255


function ContainerUI:draw()
	if self.fillOpacity > 0 then
		self:fill(self.fillOpacity)
	end
	if self.borderWidth > 0 then
		self:outline(self.borderWidth)
	end
end



TextUI = class(BaseUI)
TextUI.text = "textUI :)"
TextUI.font = nil
TextUI.align = "left"

function TextUI:init(parent, id, pos, size, label, align)
	BaseUI.init(self, parent, id, pos, size)
	self.text = label or id
	self.align = align
end

function TextUI:draw()
	if ScreenUI.testBoxes then
		BaseUI.draw(self)
	end
	self.color:set()
	if self.font then
		love.graphics.setFont(self.font)
	end
	love.graphics.printf(self.text, self.absPos.x, self.absPos.y, self.absSize.x, self.align)
end

TextBoxUI = class(TextUI)
TextBoxUI.text = ""
TextBoxUI.lastText = ""
TextBoxUI.align = "left"
TextBoxUI.idle = "_" --idle character
function TextBoxUI:init(parent, id, pos, size, label, clearOnFocus, wordWrap)
	TextUI.init(self, parent, id, pos, size, label)
	self.lastText = label
	self.clearOnFocus = clearOnFocus or false
	self.wordWrap = wordWrap or false
	self.isHidden = false

	self.TEXTCHANGED = Event.new() -- fires whenever text changes
	self.TEXTENTERED = Event.new() -- only fires when enter is pressed
end

function TextBoxUI:mouseDown(mx, my)
	self:focus()
end

function TextBoxUI:draw()
	local t = love.timer.getTime()
	if ScreenUI.testBoxes then
		BaseUI.draw(self)
	end
	self.color:set()
	if self.font then
		love.graphics.setFont(self.font)
	end

	love.graphics.setStencil(function()
		love.graphics.rectangle("fill", self.absPos.x, self.absPos.y, self.absSize.x, self.absSize.y)
	end)

	local offset = math.max(0, self.font:getWidth(self.text) - (self.absSize.x - 20))
	local displayText = self.isHidden and string.rep("*", #self.text) or self.text

	if self.wordWrap then
		if self:getScreen().textFocus == self and t % 1 < 0.5 then
			love.graphics.printf(displayText .. self.idle, self.absPos.x - offset, self.absPos.y, self.absSize.x, self.align)
		else
			love.graphics.printf(displayText, self.absPos.x - offset, self.absPos.y, self.absSize.x, self.align)
		end
	else
		if self:getScreen().textFocus == self and t % 1 < 0.5 then
			love.graphics.print(displayText .. self.idle, self.absPos.x - offset, self.absPos.y)
		else
			love.graphics.print(displayText, self.absPos.x - offset, self.absPos.y)
		end
	end

	love.graphics.setStencil()
end

function TextBoxUI:focus()
	local screen = self:getScreen()
	if self.clearOnFocus then
		self.text = ""
	end

	if screen.textFocus and screen.textFocus ~= self then
		screen.textFocus:unfocus()
	end

	screen.textFocus = self
end

function TextBoxUI:unfocus()
	local screen = self:getScreen()
	if screen.textFocus == self then
		screen.textFocus = nil
	end
	if self.lastText ~= self.text then
		self.TEXTCHANGED:fire(self.text)
		self.lastText = self.text
	end
end

function TextBoxUI:backspace()
	if string.len(self.text) > 0 then
		self.text = string.sub(self.text, 1, string.len(self.text) - 1)
		self.TEXTCHANGED:fire(self.text)
		self.lastText = self.text
	end
end

function TextBoxUI:enter()
	self:unfocus()
	self.TEXTENTERED:fire(self.text)
end

function TextBoxUI:paste()
	self.text = self.text .. love.system.getClipboardText()
end

function TextBoxUI:input(key)
	self.text = self.text .. key
	if self.lastText ~= self.text then
		self.TEXTCHANGED:fire(self.text)
		self.lastText = self.text
	end
end


ImageUI = class(BaseUI)
ImageUI.image = nil
ImageUI.stretch = true

function ImageUI:init(parent, id, pos, size, img)
	BaseUI.init(self, parent, id, pos, size)
	self.image = img
end


function ImageUI:draw()
	self.color:set()
	if self.image then
		if not self.stretch then
			love.graphics.draw(self.image, self.absPos.x, self.absPos.y)
		else
			love.graphics.draw(self.image, self.absPos.x, self.absPos.y, 0, self.absSize.x/self.image:getWidth(), self.absSize.y/self.image:getHeight())
		end
	end
end

SpriteUI = class(BaseUI)
SpriteUI.sprite = nil
SpriteUI.spritemap = nil

function SpriteUI:init(parent, id, pos, size, sprite, spritemap)
	BaseUI.init(self, parent, id, pos, size)
	self.sprite = sprite
	self.spritemap = spritemap
end

function SpriteUI:draw()
	self.color:set()
	if self.sprite and self.spritemap then
		self.spritemap:draw(self.sprite, self.absPos.x, self.absPos.y, 0, self.absSize.x/self.spritemap.cx, self.absSize.y/self.spritemap.cy)
	end
end



AttachedUI = class(ContainerUI)

function AttachedUI:init(parent, id, pos, size, adornee, camera)
	self.adornee = adornee or error("AttachedUI missing adornee")
	self.camera = camera or error("AttachedUI missing camera")
	BaseUI.init(self, parent, id, pos, size)
end

function AttachedUI:draw()
	if self.adornee and self.camera then
		local x, y, s = self.camera:getScreenPos(self.adornee.pos)
		self.absPos = self.pos:absolute(self.size.scale * s, self.parent.absPos) + Vector2.new(x, y)
		self.absSize = self.size.scale * s + self.size.offset
		self.CHANGED:fire()
		ContainerUI.draw(self)
	else
		self:remove()
	end
end

function AttachedUI:setSize(size)
	if not (self.adornee and self.camera) then
		self:remove()
		return
	end
	self.size = size
	local x, y, s = self.camera:getScreenPos(self.adornee.pos)
	self.absSize = self.size.scale * s + self.size.offset
	self.CHANGED:fire()
end

function AttachedUI:setPos(pos)
	if not (self.adornee and self.camera) then
		self:remove()
		return
	end
	self.pos = pos
	local x, y, s = self.camera:getScreenPos(self.adornee.pos)
	self.absPos = self.pos:absolute(self.size.scale * s, self.parent.absPos) + Vector2.new(x, y)
	self.CHANGED:fire()
end
