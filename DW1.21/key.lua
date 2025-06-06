if not jpi then
	require("jpi").execute("key.lua")
else


local serverID = nil
repeat
	serverID = jpi.arp("MainServer")
until serverID

local function send(e,a,b)
	payload = {}
	payload.event = e
	payload.first = a
	payload.second = b
	jpi.send(serverID, payload)
end

local function keyHandler()
	while true do
		local e,k,h = os.pullEvent("key")
		send(e,k,h)
	end
end


local function keyUpHandler()
	while true do
		local e,k = os.pullEvent("key_up")
		send(e,k,h)
	end
end

local function charHandler()
	while true do
		local e,c = os.pullEvent("char")
		send(e,c)
	end
end

parallel.waitForAny(keyHandler, keyUpHandler, charHandler)


end