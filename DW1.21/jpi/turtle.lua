local jpi = {}

--The coordinate system is defined as so:
--Y remains the vertical direction as in Minecraft
--The turtle stars at the origin (0,0,0)
--Positive Z extends ahead of the turtle
--Positive X extends to the right of the turtle

jpi.FUEL_THRESHOLD = 1000
jpi.pos = vector.new()
jpi.facing = vector.new(0, 0, 1)

local function checkFuel()
	if turtle.getFuelLevel() > jpi.FUEL_THRESHOLD then return end
	
	local selected = turtle.getSelectedSlot()
	turtle.select(1)
	repeat 
		if not turtle.refuel(1) then
			error("Turtle out of fuel!")
		end
	until turtle.getFuelLevel() > jpi.FUEL_THRESHOLD
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
	return jpi.pos
end

function jpi.getFacing()
	return jpi.facing
end

function jpi.setOrigin()
	jpi.pos = vector.new()
	jpi.facing = vector.new(0, 0, 1)
end

function jpi.up()
	checkFuel()
	repeat until turtle.up()
	jpi.pos = jpi.pos + vector.new(0, 1, 0)
end

function jpi.down()
	checkFuel()
	repeat until turtle.down()
	jpi.pos = jpi.pos + vector.new(0, -1, 0)
end

function jpi.forward()
	checkFuel()
	repeat until turtle.forward()
	jpi.pos = jpi.pos + jpi.facing
end

function jpi.back()
	checkFuel()
	repeat until turtle.back()
	jpi.pos = jpi.pos - jpi.facing
end

function jpi.turnRight()
	turtle.turnRight()
	jpi.facing = rotVecRight(jpi.facing)
end

function jpi.turnLeft()
	turtle.turnLeft()
	jpi.facing = rotVecLeft(jpi.facing)
end

function jpi.face(vec)
	if vec == jpi.facing then return end
	
	if vec == -jpi.facing then
		jpi.turnRight()
		jpi.turnRight()
		assert(vec == jpi.facing)
		return
	end
	
	if vec == rotVecLeft(jpi.facing) then
		jpi.turnLeft()
	else
		jpi.turnRight()
	end
	assert(vec == jpi.facing)
end

function jpi.move(vec)
	local targetPos = jpi.pos + vec
	
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
		local vecX = vector.new(vec.x/math.abs(vec.x), 0, 0)
		jpi.face(vecX)
		repeat
			jpi.forward()
		until jpi.pos.x == targetPos.x
	end
	
	--z
	if vec.z ~= 0 then
		local vecZ = vector.new(0, 0, vec.z/math.abs(vec.z))
		jpi.face(vecZ)
		repeat
			jpi.forward()
		until jpi.pos.z == targetPos.z
	end
	
	assert(jpi.pos == targetPos)
end

function jpi.moveto(vec)
	jpi.move(vec - jpi.pos)
end

return jpi