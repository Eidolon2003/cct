args = {...}
num = args[1]
if turtle.getFuelLevel() < (num * 2) then error("not enough fuel") end
check = args[2]
for i = 1,num do
	repeat until not turtle.dig()
	turtle.forward()
	turtle.turnLeft()
	flagfront = false
	flagup = false
	flagdown = false
	for j = 1,check do
		turtle.select(j)
		if not flagfront then flagfront = turtle.compare() end
		if not flagup then flagup = turtle.compareUp() end
		if not flagdown then flagdown = turtle.compareDown() end
	end
	if not flagfront then
		turtle.dig()
	end
	if not flagup then
		turtle.digUp()
	end
	if not flagdown then
		turtle.digDown()
	end
	turtle.turnLeft() turtle.turnLeft()
	flagfront = false
	for j = 1,check do
		turtle.select(j)
		if not flagfront then flagfront = turtle.compare() end
	end
	if not flagfront then
		turtle.dig()
	end
	turtle.turnLeft()
end
turtle.turnLeft() turtle.turnLeft()
for i = 1,num do
	turtle.forward()
end
print(turtle.getFuelLevel())