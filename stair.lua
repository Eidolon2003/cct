args = {...}
num = args[1]
for i = 1,num do
	while turtle.dig() do end
	turtle.forward()
	turtle.digUp()
	turtle.digDown()
	turtle.down()
end
print(turtle.getFuelLevel())