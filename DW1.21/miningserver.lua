--These variables are file backed:
local currentCell = vector.new(0,0,0)
local miningQueue = {}
local inProgress = {}
local idleCount = 0

--These are not:
local FILENAME = "mine.dat"

local function sizeof(tbl)
	local x = 0
	for k,v in pairs(tbl) do
		x = x + 1
	end
	return x
end

local function readVector(file)
	local x = file.read()
	local y = file.read()
	local z = file.read()
	return vector.new(x,y,z)
end

local function readFile()
	local file = fs.open(FILENAME, "rb")
	if not file then return nil end
	
	currentCell = readVector(file)
	
	local miningQueueSize = file.read()
	for i = 1,miningQueueSize do
		local v = readVector(file)
		table.insert(miningQueue, v)
	end
	
	local inProgressSize = file.read()
	for i = 1,inProgressSize do
		local id = file.read()
		local v = readVector(file)
		inProgress[id] = v
	end
	
	idleCount = file.read()
	
	file.close()
	return true
end

local function writeVector(file, v)
	file.write(v.x)
	file.write(v.y)
	file.write(v.z)
end

local function writeFile()
	local file = fs.open(FILENAME, "w+b")
	
	writeVector(file, currentCell)
	
	file.write(sizeof(miningQueue))
	for i,v in ipairs(miningQueue) do
		writeVector(file, v)
	end
	
	file.write(sizeof(inProgress))
	for i,v in pairs(inProgress) do
		file.write(i)
		writeVector(file, v)
	end
	
	file.write(idleCount)
	
	file.close()
end

local function getNextCell()
	local nextCell = currentCell + vector.new(0,0,1)
	if nextCell.z == 16 then
		nextCell.z = 0
		nextCell = nextCell + vector.new(1,0,0)
	end
	return nextCell
end

local function getNextCoordinate()
	if #miningQueue == 0 then
		
		if currentCell.x >= 16 then return nil end
		
		--"knight's move" pattern
		local offsets = {
			vector.new(0,0,1),
			vector.new(1,0,4),
			vector.new(2,0,2),
			vector.new(3,0,5),
			vector.new(4,0,3),
		}
		
		for i,offset in ipairs(offsets) do
			table.insert(
				miningQueue,
				offset + (currentCell * 5)
			)
		end
		
		currentCell = getNextCell()
	end
	
	return table.remove(miningQueue, 1)
end

local function dataToVec(data)
	return vector.new(data.x, data.y, data.z)
end

local function removeByValue(tbl, val)
	for k,v in pairs(tbl) do
		if val == v then
			tbl[k] = nil
			return
		end
	end
end

local function getProgress()
	return currentCell.x * 16 + currentCell.z
end

local homeBusy = false
local activeTurtles = {}

local MSG_HOME = "home"
local MSG_MINE = "mine"
local MSG_IDLE = "idle"

local function sendMessage(id, msg, data)
	local str = "send to " .. id .. ", " .. msg
	if data and type(data) == "table" then
		str = str .. ", " .. data:tostring()
	end
	jpi.dbgPrint(str)

	x = {}
	x.msg = msg
	x.data = data
	jpi.send(id, x)
end

local function handleMessage(senderID, msg)
	--If we get a message from someone other than a turtle,
	-- assume it's from someone querying stats
	if not activeTurtles[senderID] then
		local payload = {}
		payload.turtles = sizeof(inProgress)
		payload.progress = getProgress()
		payload.idle = idleCount
		jpi.send(senderID, payload)
		return
	end
	
	local newMine = function()
		local msg = nil
		local nextCoord = inProgress[senderID] or getNextCoordinate()
		if nextCoord then
			msg = MSG_MINE
			inProgress[senderID] = nextCoord
		else
			msg = MSG_IDLE
			inProgress[senderID] = nil
			nextCoord = vector.new(2, 0, idleCount)
			idleCount = idleCount + 1
		end
		sendMessage(senderID, msg, nextCoord)
	end
	
	if msg == MSG_HOME then
		jpi.dbgPrint(senderID .. " home")
		homeBusy = false
		newMine()
	elseif msg == MSG_MINE then
		jpi.dbgPrint(senderID .. " finished mining")
		inProgress[senderID] = nil
		newMine()
	else
		error("bad things have happened")
	end
	
	writeFile()
end

local function main()
	local function keyGetter()
		os.pullEvent("key")
		print("Deleting " .. FILENAME)
		fs.delete(FILENAME)
	end
	local function timer()
		print("Starting in five seconds.\nPress any key to delete " .. FILENAME)
		os.sleep(5)
		print("Reading " .. FILENAME)
		readFile()
	end
	parallel.waitForAny(keyGetter, timer)
	
	while true do
		local arp = jpi.getArpCache()
		
		--Deactivate any turtles that don't respond to pings
		for key,val in pairs(activeTurtles) do
			if not jpi.ping(key) then
				jpi.dbgPrint(key .. " disconnected")
				activeTurtles[key] = nil
			end
		end
		
		--Get list of available, inactive turtles
		for key,val in pairs(arp) do
			if activeTurtles[val]
			or not string.find(key, "mt_")
			or not jpi.ping(val)
			then
				arp[key] = nil
			end
		end
		
		if sizeof(arp) > 0 and not homeBusy then
			local lowestDistance = nil
			local lowestID = nil
		
			for key,val in pairs(arp) do
				local d = jpi.ping(val)
			
				if not lowestDistance
				or d < lowestDistance then
					lowestDistance = d
					lowestID = val
				end
			end
			
			if lowestID then
				homeBusy = true
				activeTurtles[lowestID] = true
				sendMessage(lowestID, MSG_HOME)
			end
		end
			
		while true do
			local senderID, msg = jpi.receive(nil, 3)
			if senderID == nil then break end
			handleMessage(senderID, msg)
		end
	end
end

main()