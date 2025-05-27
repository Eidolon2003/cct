--poke miner version 1
--fuel assumed to be in slot 1
--only works in mining dim without caves

count = 0

local function fuel()
	while turtle.getFuelLevel() < 100 do
		turtle.refuel()
	end
end

local function inventoryFull()
	return turtle.getItemDetail(16)
end

local function isOre()
	local a,b = turtle.inspect()
	return a and b.tags["c:ores"]
end

local function toSurface()
	for i = 1,count do
		repeat until not turtle.digUp()
		repeat until turtle.up()
		fuel()
	end
end

local function toBottom()
	repeat fuel() until not turtle.down()
end

local function unload()
	turtle.turnRight()
	turtle.turnRight()
	for i = 2,16 do
		turtle.select(i)
		turtle.drop()
	end
	turtle.turnRight()
	turtle.turnRight()
	turtle.select(1)
end

while turtle.digDown() do
	repeat until not turtle.digDown()
	turtle.down()
	fuel()
	count = count + 1
	for i = 1,4 do
		if isOre() then
			turtle.dig()
		end
		turtle.turnRight()
	end
	if inventoryFull() then
		toSurface()
		unload()
		toBottom()
	end
end
toSurface()
unload()