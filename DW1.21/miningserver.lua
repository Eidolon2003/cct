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

local turtles = {}

local STATUS_HOMING = "homing"
local STATUS_UNLOAD = "unloading"
local STATUS_MINING = "mining"
local STATUS_IDLE = "idle"
local STATUS_NEW = "new"
local MSG_HOME = "home"
local MSG_MINE = "mine"
local MSG_IDLE = "idle"

local function sendMessage(id, msg, data)
	local str = "send to " .. id .. ", " .. msg
	if data and type(data) == "table" then
		str = str .. ", " .. data:tostring()
	end
	jpi.dbg(str)

	x = {}
	x.msg = msg
	x.data = data
	jpi.send(id, x)
end

local function handleMessage(senderID, msg)
	--If we get a message from someone other than a turtle,
	-- assume it's from someone querying stats
	if not turtles[senderID] then
		local payload = {}
		payload.turtles = sizeof(turtles)
		payload.progress = getProgress()
		payload.idle = idleCount
		jpi.send(senderID, payload)
		return
	end

	local str = "received from " .. senderID
	if msg then
		if type(msg) == "table" then
			str = str .. ", " .. dataToVec(msg):tostring()
		else
			str = str .. ", " .. msg
		end
	end
	jpi.dbg(str)

	local oldStatus	= turtles[senderID]
	
	local newMine = function()
		local nextCoord = getNextCoordinate()
		local msg = nil
		if nextCoord then
			msg = MSG_MINE
			turtles[senderID] = STATUS_MINING
			inProgress[senderID] = nextCoord
		else
			msg = MSG_IDLE
			turtles[senderID] = STATUS_IDLE
			nextCoord = vector.new(2, 0, idleCount)
			idleCount = idleCount + 1
		end
		sendMessage(senderID, msg, nextCoord)
	end
	
	if oldStatus == STATUS_HOMING then
		if inProgress[senderID] then
			turtles[senderID] = STATUS_MINING
			sendMessage(
				senderID,
				MSG_MINE,
				inProgress[senderID]
			)
		else
			newMine()
		end
	elseif oldStatus == STATUS_UNLOAD then
		newMine()
	elseif oldStatus == STATUS_MINING then
		turtles[senderID] = STATUS_UNLOAD
		local v = dataToVec(msg)
		removeByValue(inProgress, v)
	end
	
	writeFile()
end

local function main()
	--Wait a hot sec for turtles to connect
	os.sleep(5)

	turtles = {}
	readFile()
	
	while true do
		local arp = jpi.getArpCache()
		
		--Make sure all our turtles are still here
		for key,val in pairs(arp) do
			if not jpi.ping(val) then
				turtles[val] = nil
				arp[key] = nil
			end
		end
		
		--Pick up any new turtles
		-- Or old turtles that reconnected
		for key,val in pairs(arp) do
			if string.find(key, "mt_")
			and not turtles[val] then
				turtles[val] = STATUS_NEW
				jpi.dbg(key .. " (" .. val .. ") connected")
			end
		end
		
		--Only allow one turtle to home at a time
		--Start with the nearest one
		local homeBusy = false
		for id,status in pairs(turtles) do
			if status == STATUS_HOMING then
				homeBusy = true
			end
		end
		
		if not homeBusy then
			local lowestDistance = nil
			local lowestID = nil
		
			for id,status in pairs(turtles) do
				if status == STATUS_NEW then
					d = jpi.ping(id)
				
					if not lowestDistance
					or d < lowestDistance then
						lowestDistance = d
						lowestID = id
					end
				end
			end
			
			if lowestID then
				turtles[lowestID] = STATUS_HOMING
				sendMessage(lowestID, MSG_HOME)
			end
		end
			
		while true do
			senderID, msg = jpi.receive(nil, 3)
			if senderID == nil then break end
			handleMessage(senderID, msg)
		end
	end
end

main()