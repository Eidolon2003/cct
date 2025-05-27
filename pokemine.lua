check = 7
counter = 0
turtle.digDown()
while turtle.down() do
	print(turtle.getFuelLevel())
	for i = 1,4 do
		flag = false
		for j = 1,check do
			turtle.select(j)
			if not flag then flag = turtle.compare() end
		end
		if not flag then 
			print("Foreign material detected")
			while turtle.dig() do end
		end
		turtle.turnRight()
	end
	counter = counter + 1
	turtle.digDown()
end
for i = 1,counter do
	turtle.up()
	print(turtle.getFuelLevel())
end
print("Task complete. Mined down", counter, "blocks.")
