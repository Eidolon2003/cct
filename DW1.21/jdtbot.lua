--false if input is below
local dir = false

local function air()
	if dir then
		turtle.suckUp(1)
	else
		turtle.suckDown(1)
	end
	turtle.place()
end

local function done()
	turtle.dig()
	if dir then
		turtle.dropDown()
	else
		turtle.dropUp()
	end
	air()
end

while true do
	a,b = turtle.inspect()
	
	if not a then
		air()
	elseif string.find(b.name, "dire") then
		done()
	end
	
	turtle.turnLeft()
ende