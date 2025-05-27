if turtle.dig() then
	turtle.forward()
	while turtle.digUp() do
		turtle.up()
	end
	while turtle.down() do end
	print("Tree terminated")
else
	print("No tree detected")
end
