args = {...}
length = args[1]
startFuel = turtle.getFuelLevel()
facing = "f"
if startFuel < (length * 4) then
	error("not enough fuel")
end

local function face(goal)
	--print("face",goal)
	if facing == goal then return end
	if goal == "f" then
		if facing == "l" then
			turtle.turnRight()
		elseif facing == "r" then
			turtle.turnLeft()
		elseif facing =="b" then
			turtle.turnLeft() turtle.turnLeft()
		end
	elseif goal == "l" then
		if facing == "f" then
			turtle.turnLeft()
		elseif facing == "b" then
			turtle.turnRight()
		elseif facing == "r" then
			turtle.turnLeft() turtle.turnLeft()
		end
	elseif goal == "r" then
		if facing == "f" then
			turtle.turnRight()
		elseif facing == "b" then
			turtle.turnLeft()
		elseif facing == "l" then
			turtle.turnLeft() turtle.turnLeft()
		end
	elseif goal == "b" then
		if facing == "l" then
			turtle.turnLeft()
		elseif facing == "r" then
			turtle.turnRight()
		elseif facing == "f" then
			turtle.turnLeft() turtle.turnLeft()
		end
	end
	facing = goal
end

local function check(list)
	--test up
	--print("test u")
	a,b = turtle.inspectUp()
	if a and b.tags["forge:ores"] then
		--print("ore found u")
		repeat until not turtle.digUp()
		turtle.up()
		list[#list+1] = "u"
		check(list)
	end
	
	--test down
	--print("test d")
	a,b = turtle.inspectDown()
	if a and b.tags["forge:ores"] then
		--print("ore found d")
		turtle.digDown()
		turtle.down()
		list[#list+1] = "d"
		check(list)
	end
	
	--test left
	face("l")
	--print("test l")
	a,b = turtle.inspect()
	if a and b.tags["forge:ores"] then
		--print("ore found l")
		repeat until not turtle.dig()
		turtle.forward()
		list[#list+1] = "l"
		check(list)
	end
	
	--test backward
	face("b")
	--print("test b")
	a,b = turtle.inspect()
	if a and b.tags["forge:ores"] then
		--print("ore found b")
		repeat until not turtle.dig()
		turtle.forward()
		list[#list+1] = "b"
		check(list)
	end
	
	--test right
	face("r")
	--print("test r")
	a,b = turtle.inspect()
	if a and b.tags["forge:ores"] then
		--print("ore found r")
		repeat until not turtle.dig()
		turtle.forward()
		list[#list+1] = "r"
		check(list)
	end
	
	--test forward
	face("f")
	--print("test f")
	a,b = turtle.inspect()
	if a and b.tags["forge:ores"] then
		--print("ore found f")
		repeat until not turtle.dig()
		turtle.forward()
		list[#list+1] = "f"
		check(list)
	end
	
	--none found, backtrack until finished
	--print("all clear")
	if list[#list] then
		local temp = table.remove(list,#list)
		if temp == "u" then
			turtle.down()
		elseif temp == "d" then
			turtle.up()
		elseif temp == "l" then
			face("r")
			turtle.forward()
		elseif temp == "r" then 
			face("l")
			turtle.forward()
		elseif temp == "f" then
			face("b")
			turtle.forward()
		elseif temp == "b" then
			face("f")
			turtle.forward()
		end
	end		
end

for i = 1,length do
	face("f")
	--print("move forward")
	repeat until not turtle.dig()
	turtle.forward()
	check({})
end

face("b")
--print("return")
for i = 1,length do
	turtle.dig()	--shouldn't be needed, but ran into a natural cobble generator in one branch which blocked the way back
	turtle.forward()
end
print("Consumed",startFuel-turtle.getFuelLevel(),"fuel")