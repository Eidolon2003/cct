local jpi = {}

--The coordinate system is defined as so:
--Y remains the vertical direction as in Minecraft
--The turtle stars at the origin (0,0,0)
--Positive Z extends ahead of the turtle
--Positive X extends to the right of the turtle

FUEL_THRESHOLD = 1000
pos = vector.new()
facing = vector.new(0, 0, 1)

local function checkFuel()
	if turtle.getFuelLevel() > FUEL_THRESHOLD then return end
	
	local selected = turtle.getSelectedSlot()
	turtle.select(1)
	repeat 
		if not turtle.refuel(1) then
			error("Turtle out of fuel!")
		end
	until turtle.getFuelLevel() > FUEL_THRESHOLD
	turtle.select(selected)
end

local function rotVecRight(vec) 
	return vector.new(
		vec.z,
		vec.y,
		-vec.x
	)
end

local function rotVecLeft(vec) 
	return vector.new(
		-vec.z,
		vec.y,
		vec.x
	)
end

function jpi.getPos()
	return pos
end

function jpi.getFacing()
	return facing
end

function jpi.setOrigin()
	pos = vector.new()
	facing = vector.new(0, 0, 1)
end

function jpi.up()
	checkFuel()
	repeat until turtle.up()
	pos = pos + vector.new(0, 1, 0)
end

function jpi.down()
	checkFuel()
	repeat until turtle.down()
	pos = pos + vector.new(0, -1, 0)
end

function jpi.forward()
	checkFuel()
	repeat until turtle.forward()
	pos = pos + facing
end

function jpi.back()
	checkFuel()
	repeat until turtle.back()
	pos = pos - facing
end

function jpi.turnRight()
	turtle.turnRight()
	facing = rotVecRight(facing)
end

function jpi.turnLeft()
	turtle.turnLeft()
	facing = rotVecLeft(facing)
end

function jpi.face(vec)
	if vec == facing then return end
	
	if vec == -facing then
		jpi.turnRight()
		jpi.turnRight()
		assert(vec == facing)
		return
	end
	
	if vec == rotVecLeft(facing) then
		jpi.turnLeft()
	else
		jpi.turnRight()
	end
	assert(vec == facing)
end

function jpi.move(vec)
	local targetPos = pos + vec
	
	--y
	if vec.y < 0 then
		for i = 1,math.abs(vec.y) do
			jpi.down()
		end
	else
		for i = 1,vec.y do
			jpi.up()
		end
	end
	
	--x
	if vec.x ~= 0 then
		local vecX = vector.new(vec.x, 0, 0)
		jpi.face(vecX:normalize())
		repeat
			jpi.forward()
		until pos.x == targetPos.x
	end
	
	--z
	if vec.z ~= 0 then
		local vecZ = vector.new(0, 0, vec.z)
		jpi.face(vecZ:normalize())
		repeat
			jpi.forward()
		until pos.z == targetPos.z
	end
	
	assert(pos == targetPos)
end

function jpi.moveto(vec)
	jpi.move(vec - pos)
end

return jpi