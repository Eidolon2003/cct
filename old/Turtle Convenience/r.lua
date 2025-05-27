args = {...}
iNum = args[1]
if not iNum then
	iNum = 1
end 
turtle.turnRight()
for iCount = 1,iNum do
	if turtle.forward() then
		print(turtle.getFuelLevel())
	else
		print("Path Obstructed")
	end
end
turtle.turnLeft()
