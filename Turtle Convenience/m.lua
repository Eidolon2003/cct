args = {...}
charDir = args[1]
if charDir == "f" or not charDir then
	if turtle.dig() then
		print("Block terminated")
	else
		print("No block detected")
	end
end
if charDir == "d" then
	if turtle.digDown() then
		print("Block terminated")
	else
		print("No block detected")
	end
end
if charDir == "u" then
	if turtle.digUp() then
		print("Block terminated")
	else
		print("No block detected")
	end
end