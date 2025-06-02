--Pokes down to bedrock and collects any adjacent ores
--Fuel assumed to be in slot 1
--Only works in mining dim without caves

--List non-ores we still want to pick up
nonores = {
	"minecraft:andesite",
	"xycraft_world:kivi",
}

count = 0

local function fuel()
	while turtle.getFuelLevel() < 100 do
		turtle.refuel(1)
	end
end

local function inventoryFull()
	return turtle.getItemDetail(16)
end

local function isOre()
	local a,b = turtle.inspect()
	if not a then return false end
	
	local flag = false
	for key,val in pairs(nonores) do
		if b.name == val then 
			flag = true 
			break
		end
	end
	
	return flag or b.tags["c:ores"]
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

--search inventory for cobble or deepslate to place below self
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

unload()

--get in position for next dig
turtle.forward()
turtle.forward()
turtle.turnLeft()
turtle.forward()
turtle.turnRight()