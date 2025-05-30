local jpi = {}

local modem = nil
local myID = os.getComputerID()
local myLabel = os.getComputerLabel()

function initNetwork()
	modem = peripheral.find("modem")
	if not modem then return end
	
	modem.closeAll()
	modem.open(65535)
	modem.open(myID)
end

function deinitNetwork()
	if modem then 
		modem.closeAll()
		modem = nil
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

local function handleARP(receiverID, senderID, packet)
	if receiverID == 65535 then
		--If receiverID is BROADCAST, then this is an arp request
		--Respond to the request
		local newReceiverID = senderID
		local newSenderID = myID
		local newPacket = {}
		newPacket.protocol = "arp"
		newPacket.payload = {}
		newPacket.payload.receiverLabel = packet.payload.senderLabel
		newPacket.payload.senderLabel = myLabel
		modem.transmit(newReceiverID, newSenderID, newPacket)
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
		local newSenderID = myID
		local newPacket = {}
		newPacket.protocol = "ping"
		newPacket.payload = {}
		newPacket.payload.ack = true
		modem.transmit(newReceiverID, newSenderID, newPacket)
	end
end

local function handleMsg(receiverID, senderID, packet)
	os.queueEvent("jpi_msg", packet.payload)
end

function handleEvents()
	while true do
		local _,_,receiverID,senderID,packet,distance 
			= os.pullEvent("modem_message")
			
		--printPacket(receiverID, senderID, packet, distance)
			
		if packet.protocol and packet.payload then
			if packet.protocol == "arp"
			and packet.payload.receiverLabel == myLabel then
				handleARP(receiverID, senderID, packet)
			elseif packet.protocol == "ping" then
				handlePing(receiverID, senderID, packet, distance)
			elseif packet.protocol == "msg" then
				handleMsg(receiverID, senderID, packet)
			end
		end
	end
end

local arpCache = {}
function jpi.arp(targetLabel)
	if not modem then return nil end

	--Check the cache before making a broadcast
	if arpCache[targetLabel] then
		return arpCache[targetLabel]
	end
	
	local receiverID = 65535
	local senderID = myID
	local packet = {}
	packet.protocol = "arp"
	packet.payload = {}
	packet.payload.receiverLabel = targetLabel
	packet.payload.senderLabel = myLabel
	modem.transmit(receiverID, senderID, packet)
	
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
	if not modem then return nil end
	
	local receiverID = targetID
	local senderID = myID
	local packet = {}
	packet.protocol = "ping"
	packet.payload = {}
	packet.payload.ack = false
	modem.transmit(receiverID, senderID, packet)
	
	local distance = nil
	local function getReply()
		_,distance = os.pullEvent("jpi_ping")
	end
	parallel.waitForAny(getReply, function() os.sleep(5) end)
	
	return distance
end

function jpi.send(targetID, payload)
	if not modem then return nil end
	
	local receiverID = targetID
	local senderID = myID
	local packet = {}
	packet.protocol = "msg"
	packet.payload = payload
	modem.transmit(receiverID, senderID, packet)
	
	return true
end

function jpi.receive()
	if not modem then return nil end
	_,payload = os.pullEvent("jpi_msg")
	return payload
end

return jpi