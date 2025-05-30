local jpi = {}

jpi.BROADCAST = 65535
jpi.modem = false
jpi.myID = os.getComputerID()
jpi.myLabel = os.getComputerLabel()

function initNetwork()
	jpi.modem = peripheral.find("modem")
	if not jpi.modem then return end
	
	jpi.modem.closeAll()
	jpi.modem.open(jpi.BROADCAST)
	jpi.modem.open(jpi.myID)
end

function deinitNetwork()
	if jpi.modem then 
		jpi.modem.close(jpi.BROADCAST)
		jpi.modem.close(jpi.myID)
		jpi.modem = false
	end
end

--Basic network packet format:
--protocol
--payload (protocol specific)
	--ARP:
	--receiverLabel
	--senderLabel
	
	--Ping:
	--ack

local function printPacket(receiverID, senderID, packet, distance)
	print("New packet:")
	print("distance", distance)
	print("receiverID", receiverID)
	print("senderID", senderID)
	for key,val in pairs(packet) do
		if type(val) == "table" then
			for key2,val2 in pairs(val) do
				print(key2,val2)
			end
		else
			print(key,val)
		end
	end
	print("")
end

local arpCache = {}

local function handleARP(receiverID, senderID, packet)
	if receiverID == jpi.BROADCAST then
		--If receiverID is BROADCAST, then this is an arp request
		--Respond to the request
		local newReceiverID = senderID
		local newSenderID = jpi.myID
		local newPacket = {}
		newPacket.protocol = "arp"
		newPacket.payload = {}
		newPacket.payload.receiverLabel = packet.payload.senderLabel
		newPacket.payload.senderLabel = jpi.myLabel
		jpi.modem.transmit(newReceiverID, newSenderID, newPacket)
		
		--Also cache this ID/Label pair
		arpCache[packet.payload.senderLabel] = senderID
	else
		--If receiverID is filled in, then this is an arp reply
		--Put this in event queue for the program to handle
		os.queueEvent("jpi_arp", senderID)
	end
end

local function handlePing(receiverID, senderID, packet, distance)
	if packet.payload.ack then
		--If ack is true, then this is a ping reply
		os.queueEvent("jpi_ping", distance)
	else
		--If ack is false, we need to reply
		local newReceiverID = senderID
		local newSenderID = jpi.myID
		local newPacket = {}
		newPacket.protocol = "ping"
		newPacket.payload = {}
		newPacket.payload.ack = true
		jpi.modem.transmit(newReceiverID, newSenderID, newPacket)
	end
end

local function handleMsg(receiverID, senderID, packet)
	os.queueEvent("jpi_msg", senderID, packet.payload)
end

function handleEvents()
	while true do
		local _,_,receiverID,senderID,packet,distance 
			= os.pullEvent("modem_message")
			
		--printPacket(receiverID, senderID, packet, distance)
			
		if packet.protocol and packet.payload then
			if packet.protocol == "arp"
			and packet.payload.receiverLabel == jpi.myLabel then
				handleARP(receiverID, senderID, packet)
			elseif packet.protocol == "ping" then
				handlePing(receiverID, senderID, packet, distance)
			elseif packet.protocol == "msg" then
				handleMsg(receiverID, senderID, packet)
			end
		end
	end
end

function jpi.arp(targetLabel)
	if not jpi.modem then return nil end

	--Check the cache before making a broadcast
	if arpCache[targetLabel] then
		return arpCache[targetLabel]
	end
	
	local receiverID = jpi.BROADCAST
	local senderID = jpi.myID
	local packet = {}
	packet.protocol = "arp"
	packet.payload = {}
	packet.payload.receiverLabel = targetLabel
	packet.payload.senderLabel = jpi.myLabel
	jpi.modem.transmit(receiverID, senderID, packet)
	
	local targetID = nil
	local function getReply()
		_,targetID = os.pullEvent("jpi_arp")
	end
	parallel.waitForAny(getReply, function() os.sleep(5) end)
	
	if targetID then
		--update cache
		arpCache[targetLabel] = targetID
		return targetID
	else
		return nil
	end
end

function jpi.ping(targetID)
	if not jpi.modem then return nil end
	
	local receiverID = targetID
	local senderID = jpi.myID
	local packet = {}
	packet.protocol = "ping"
	packet.payload = {}
	packet.payload.ack = false
	jpi.modem.transmit(receiverID, senderID, packet)
	
	local distance = nil
	local function getReply()
		_,distance = os.pullEvent("jpi_ping")
	end
	parallel.waitForAny(getReply, function() os.sleep(5) end)
	
	return distance
end

function jpi.send(targetID, payload)
	if not jpi.modem then return nil end
	
	local receiverID = targetID
	local senderID = jpi.myID
	local packet = {}
	packet.protocol = "msg"
	packet.payload = payload
	jpi.modem.transmit(receiverID, senderID, packet)
	
	return true
end

function jpi.receive( --[[optional]] timeout )
	if not jpi.modem then return nil end
	
	local payload = nil
	local senderID = nil
	local rx = function()
		_,senderID,payload = os.pullEvent("jpi_msg")
	end
	
	if timeout then
		parallel.waitForAny(rx, function() os.sleep(timeout) end)
	else
		rx()
	end
	
	return senderID,payload
end

function jpi.getArpCache()
	return arpCache
end

function jpi.clearArpCache()
	arpCache = {}
end

return jpi