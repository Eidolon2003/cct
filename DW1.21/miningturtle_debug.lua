local MSG_HOME = "home"
local MSG_MINE = "mine"
local MSG_IDLE = "idle"

local serverID = jpi.arp("MiningServer")
while not serverID do
	serverID = jpi.arp("MiningServer")
end

local mineVector = vector.new()
	
local function home()
	os.sleep(0.5)
 jpi.dbg("finished homing")
	repeat until jpi.send(serverID, MSG_HOME)
	return
end

local function mine()
	os.sleep(0.5)
 jpi.dbg("finished mining " .. mineVector:tostring())
	jpi.dbg("finished unloading")
	repeat until jpi.send(serverID, MSG_MINE)
end

local function dataToVec(data)
	return vector.new(data.x, data.y, data.z)
end

local function handleMessage(msg, data)
	if msg == MSG_HOME then
		jpi.dbg("home")
		home()
	elseif msg == MSG_MINE then
		mineVector = dataToVec(data)
		jpi.dbg("mine " .. mineVector:tostring())
		mine()
	elseif msg == MSG_IDLE then
		jpi.dbg("idle")
	end
end

local function main()
	while true do
		senderID, msg = jpi.receive()
		if senderID == serverID then
			handleMessage(msg.msg, msg.data)
		end
	end
end

main()
