function class(inheritsFrom, ro)
	local c = {}
	local c_mt = {__index = c, __tostring = function(obj) if obj.tostring then return obj:tostring() end end}
	if ro then roClass(c, c_mt, ro) end
	function c.new(...)
		local obj = setmetatable({}, c_mt)
		if obj.init then obj:init(...) end
		return obj
	end
	function c.super()
		return inheritsFrom
	end
	function c.instanceOf(class)
		return c == class or inheritsFrom and inheritsFrom.instanceOf(class)
	end
	if inheritsFrom then
		if not inheritsFrom.instanceOf then error("Bad superclass.") end
		setmetatable(c, {__index = inheritsFrom})
	end
	return c
end



function roClass(c, c_mt, ro)
	c.readonly = ro
	c_mt.__index = function(tab, key)
		return tab.readonly[key] or (tab.super() or {})[key] or rawget(tab, key)
	end
	c_mt.__newindex = function(tab, key, val)
		if ro[key] then
			error("Cannot modify read-only value.")
		else
			rawset(tab, key, val)
		end
	end
end

Connection = class()

function Connection:init(event, func)
	if not func then
		error("No function to connect.")
	end
	self.event = event
	self.fire = func
end

function Connection:disconnect()
	for i, c in pairs(self.event.connections) do
		if c == self then
			table.remove(self.event.connections, i)
			return
		end
	end
end

Event = class()

function Event:init()
	self.connections = {}
end

function Event:fire(...)
	for i, c in pairs(self.connections) do
		c.fire(...)
	end
end

function Event:connect(func)
	local c = Connection.new(self, func)
	table.insert(self.connections, c)
	return c
end



List = class()

function List:init(isWeak)
	self.table = isWeak and setmetatable({}, {_mode = "kv"}) or {}
end

function List:get()
	return self.table
end

function List:add(...)
	table.insert(self.table, ...)
end

function List:remove(...)
	return table.remove(self.table, ...)
end

function List:removeValue(obj)
	for i = 1, #self.table do
		if self.table[i] == obj then
			return table.remove(self.table, i)
		end
	end
end


TaskScheduler = class()
TaskScheduler.timer = 0

function TaskScheduler:init()
	self.schedule = {}
end

--t is the time delayed, func is a function, additional arguments are called with the function.
function TaskScheduler:delay(t, func, ...)
	local t0 = self.timer
	if not self.schedule[t + t0] then
		self.schedule[t + t0] = {}
	end
	table.insert(self.schedule[t + t0], {func, {...}})
end

function TaskScheduler:update(s)
	self.timer = self.timer + s
	local t0 = self.timer
	for i, funcs in pairs(self.schedule) do
		if i <= t0 then
			for j, fpair in pairs(funcs) do
				fpair[1](unpack(fpair[2]))
			end
			self.schedule[i] = nil
		end
	end
end
