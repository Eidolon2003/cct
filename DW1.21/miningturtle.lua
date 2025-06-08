local DEBUG = false

local MSG_HOME = "home"
local MSG_MINE = "mine"
local MSG_IDLE = "idle"

local serverID = jpi.arp("MiningServer")
if DEBUG then print("arp") end
while not serverID do
	if DEBUG then print("arp") end
	serverID = jpi.arp("MiningServer")
end

local mineVector = vector.new()

local function dropOff()
	jpi.moveto(vector.new(0, 0, 0))
	jpi.face(vector.new(0, 0, -1))
	for i = 2,16 do
		turtle.select(i)
		turtle.drop()
	end
	
	jpi.up()
	turtle.select(1)
	turtle.suck(64 - turtle.getItemCount())
end
	
local function home()
	local dist = jpi.ping(serverID)
	local oldDist
	
	local fg = function(f)
		repeat
			oldDist = dist
			repeat until f()
			dist = jpi.ping(serverID)
		until dist > oldDist
	end
	
	local fge = function(f)
		repeat
			oldDist = dist
			f()
			dist = jpi.ping(serverID)
		until dist >= oldDist
	end
	
	--Find top of computer
	fge(turtle.down)
	if jpi.ping(serverID) == 1 then
		goto skip
	end
	fg(turtle.up)
	fg(turtle.forward)
	turtle.turnLeft()
	turtle.turnLeft()
	fg(turtle.forward)
	turtle.turnLeft()
	turtle.turnLeft()
	turtle.forward()
	turtle.turnLeft()
	fg(turtle.forward)
	turtle.turnLeft()
	turtle.turnLeft()
	fg(turtle.forward)
	turtle.turnLeft()
	turtle.turnLeft()
	turtle.forward()
::skip::
	
	--face opposite dropoff chest
	repeat until turtle.up()
	local a,b = turtle.inspect()
	while not a
	or string.find(b.name, "turtle") do
		turtle.turnLeft()
		a,b = turtle.inspect()
	end
	turtle.turnRight()
	turtle.turnRight()
	
	jpi.setOrigin()
	dropOff()
	jpi.send(serverID, 0)
	return
end

local function isOre()
	local a,b = turtle.inspect()
	if not a then return false end
	
	local nonores = {
		"xycraft_world:kivi",
		"minecraft:clay",
	}
	
	local flag = false
	for key,val in pairs(nonores) do
		if b.name == val then 
			flag = true 
			break
		end
	end
	
	return flag or b.tags["c:ores"]
end

local function mine()
	--goto mine
	jpi.move(mineVector)
	local block,data = turtle.inspectDown()
	while not block 
	or string.find(data.name, "turtle") do
		jpi.down()
		block,data = turtle.inspectDown()
	end
	
	--mine
	while turtle.digDown() do
		repeat until not turtle.digDown()
		jpi.down()

		for i = 1,4 do
			if isOre() then
				turtle.dig()
			end
			jpi.turnRight()
		end
		
		if turtle.getItemDetail(16) then
			local p = jpi.getPos()
			dropOff()
			jpi.move(mineVector)
			jpi.moveto(p)
		end
	end
	
	jpi.moveto(vector.new(mineVector.x, -3, mineVector.z))
	for i = 2,16 do
		x = turtle.getItemDetail(i)
		if not x then break end
		
		if x.name == "minecraft:cobblestone"
		or x.name == "minecraft:cobbled_deepslate"
		then
			turtle.select(i)
			turtle.placeDown()
			break
		end
	end
	
	jpi.send(serverID, mineVector)
	dropOff()
	jpi.send(serverID, 0)
end

local function dataToVec(data)
	return vector.new(data.x, data.y, data.z)
end

local function handleMessage(msg, data)
	if msg == MSG_HOME then
		if DEBUG then print("home") end
		home()
	elseif msg == MSG_MINE then
		mineVector = dataToVec(data)
		if DEBUG then print("mine", mineVector) end
		mine()
	elseif msg == MSG_IDLE then
		jpi.move(dataToVec(data))
		jpi.move(vector.new(0, -4, 0))
		jpi.face(vector.new(0, 0, 1))
	end
end

local function main()
	while true do
		senderID, msg = jpi.receive()
		if senderID == serverID then
			handleMessage(msg.msg, msg.data)
		end
	end
end

main()
