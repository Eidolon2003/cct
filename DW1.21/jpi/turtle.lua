return function(jpi)
	jpi.fuelThreshold = 1000
	
	local pos = vector.new()
	local facing = vector.new(0, 0, 1)
	
	local function checkFuel()
		if turtle.getFuelLevel() > jpi.fuelThreshold then return end
	
		local selected = turtle.getSelectedSlot()
		turtle.select(1)
		repeat
			jpi.dbg("refueling")
			if not turtle.refuel(1) then
				jpi.dbgPrint("warning: turtle out of fuel")
			end
		until turtle.getFuelLevel() > jpi.fuelThreshold
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
	
	jpi.getPos = function()
		return pos
	end
	
	jpi.getFacing = function()
		return facing
	end
	
	jpi.setOrigin = function()
		pos = vector.new()
		facing = vector.new(0, 0, 1)
	end
	
	jpi.up = function()
		checkFuel()
		repeat until turtle.up()
		pos = pos + vector.new(0, 1, 0)
	end
	
	jpi.down = function()
		checkFuel()
		repeat until turtle.down()
		pos = pos + vector.new(0, -1, 0)
	end

	jpi.forward = function()
		checkFuel()
		repeat until turtle.forward()
		pos = pos + facing
	end

	jpi.back = function()
		checkFuel()
		repeat until turtle.back()
		pos = pos - facing
	end

	jpi.turnRight = function()
		turtle.turnRight()
		facing = rotVecRight(facing)
	end

	jpi.turnLeft = function()
		turtle.turnLeft()
		facing = rotVecLeft(facing)
	end
	
	jpi.face = function(vec)
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
	
	jpi.move = function(vec)
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
			local vecX = vector.new(vec.x/math.abs(vec.x), 0, 0)
			jpi.face(vecX)
			repeat
				jpi.forward()
			until pos.x == targetPos.x
		end
		
		--z
		if vec.z ~= 0 then
			local vecZ = vector.new(0, 0, vec.z/math.abs(vec.z))
			jpi.face(vecZ)
			repeat
				jpi.forward()
			until pos.z == targetPos.z
		end
		
		assert(pos == targetPos)
	end
	
	jpi.moveto = function(vec)
		jpi.move(vec - pos)
	end
end