local MSG_HOME = "home"
local MSG_MINE = "mine"
local MSG_IDLE = "idle"

local serverID = nil
local mineVector = vector.new()
	
local function home()
	os.sleep(0.5)
	jpi.dbgPrint("finished homing")
	jpi.send(serverID, MSG_HOME)
	return
end

local function mine()
	os.sleep(0.5)
	jpi.dbgPrint("finished mining " .. mineVector:tostring())
	jpi.dbgPrint("finished unloading")
	jpi.send(serverID, MSG_MINE)
end

local function dataToVec(data)
	return vector.new(data.x, data.y, data.z)
end

local function handleMessage(msg, data)
	if msg == MSG_HOME then
		jpi.dbgPrint("home")
		home()
	elseif msg == MSG_MINE then
		mineVector = dataToVec(data)
		jpi.dbgPrint("mine " .. mineVector:tostring())
		mine()
	elseif msg == MSG_IDLE then
		jpi.dbgPrint("idle")
	end
end

local function main()
	while true do
		if serverID and not jpi.ping(serverID) then
			jpi.dbgPrint("MiningServer disconnected")
			serverID = nil
		end
	
		if not serverID then
			jpi.clearArpCache()
			repeat
				serverID = jpi.arp("MiningServer")
			until serverID
		end
	
		local s,msg = jpi.receive(serverID, 30)
		if s then handleMessage(msg.msg, msg.data) end
	end
end

main()
