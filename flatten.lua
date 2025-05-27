args = {...}
turtle.select(1)
if not args[1] then error("no size specified") end

for x = 1,args[1] do
	turtle.placeDown()
	for y = 1,args[1]-1 do
		turtle.dig()
		turtle.forward()
		turtle.placeDown()
		while turtle.digUp() do turtle.up() end
		repeat until not turtle.down()
	end
	if x%2 == 1 then
		turtle.turnRight()
		turtle.dig()
		turtle.forward()
		turtle.turnRight()
	else
		turtle.turnLeft()
		turtle.dig()
		turtle.forward()
		turtle.turnLeft()
	end
end