args = {...}
charDir = args[1]
turtle.select(1)
if charDir == "f" or not charDir then
	if turtle.place() then
		print("Block placed successfully")
	elseif turtle.getItemCount() > 0 then
		print ("Unable to place block")
	else
		print ("No block detected")
	end
end
if charDir == "d" then
	if turtle.placeDown() then
		print("Block placed successfully")
	elseif turtle.getItemCount() > 0 then
		print ("Unable to place block")
	else
		print ("No block detected")
	end
end
if charDir == "u" then
	if turtle.placeUp() then
		print("Block placed successfully")
	elseif turtle.getItemCount() > 0 then
		print ("Unable to place block")
	else
		print ("No block detected")
	end
end
