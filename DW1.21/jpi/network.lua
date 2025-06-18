--Basic network packet format:
--protocol
--payload (protocol specific)
	--ARP:
	--receiverLabel
	--senderLabel
	
	--Ping:
	--ack

return function(jpi)
	local BROADCAST = 65535
	local ARP = "arp"
	local PING = "ping"
	local MSG = "msg"
	local ACK = "ack"
	
	local myID = os.getComputerID()
	local myLabel = os.getComputerLabel()
	local arpCache = {}
	local eventQueue = {}

	jpi.dbg("initializing network")
	local modem = peripheral.find("modem")
	if not modem then
		error("no modem connected")
	end
	modem.open(BROADCAST)
	modem.open(myID)
	
	local deinitNetwork = function()
		jpi.dbg("deinitializing network")
		modem.close(BROADCAST)
		modem.close(myID)
		modem = nil
	end
	
	local function queueEvent(e, id, opt)
		local tbl = {}
		tbl.e = e
		tbl.id = id
		tbl.opt = opt
		
		--insert at end
		table.insert(eventQueue, tbl)
	end
	
	local function pullEvent(e, id)
		local tbl = nil
		local idx = nil
		
		while true do
			for i,v in ipairs(eventQueue) do
				if v.e == e and (v.id == id or id == nil) then
					idx = i
					break
				end
			end
			
			if idx then
				tbl = table.remove(eventQueue, idx)
				break
			end
			
			os.pullEvent("jpi_new_message")
		end
		
		return tbl.e, tbl.id, tbl.opt
	end
	
	local function printPacket(receiverID, senderID, packet, distance)
		if not jpi.isDebug then return end
	
		if packet.protocol == ARP
		and packet.payload.receiverLabel == myLabel then
			if receiverID == BROADCAST then
				jpi.dbg(
					string.format("received arp request: to %s, from %d(%s)", 
					packet.payload.receiverLabel, senderID, packet.payload.senderLabel)
				)
			else
				jpi.dbg(
					string.format("received arp reply: to %d, from %d(%s)",
					receiverID, senderID, packet.payload.senderLabel)
				)
			end
			
		elseif packet.protocol == PING then
			if packet.payload.ack then
				jpi.dbg(
					string.format("received ping reply: to %d, from %d, %dm away",
					receiverID, senderID, distance)
				)
			else
				jpi.dbg(
					string.format("received ping request: to %d, from %d",
					receiverID, senderID)
				)
			end
		
		elseif packet.protocol == MSG then
			local msg = tostring(packet.payload)
			
			jpi.dbg(
				string.format("received message: to %d, from %d, %s",
				receiverID, senderID, msg)
			)
			
		elseif packet.protocol == ACK then
			jpi.dbg(
				string.format("received ack: to %d, from %d",
				receiverID, senderID)
			)
		end
	end
	
	local function handleArp(receiverID, senderID, packet)
		if receiverID == BROADCAST then
			--If rid is BROADCAST, then this is an arp request
			local newReceiverID = senderID
			local newSenderID = myID
			local newPacket = {}
			newPacket.protocol = ARP
			newPacket.payload = {}
			newPacket.payload.receiverLabel = packet.payload.senderLabel
			newPacket.payload.senderLabel = myLabel
			modem.transmit(newReceiverID, newSenderID, newPacket)
			
			--Also cache this ID/Label pair
			arpCache[packet.payload.senderLabel] = senderID
		else
			--If rid is filled in, this is an arp reply
			queueEvent(ARP, senderID, packet.payload.senderLabel)
		end
	end
	
	local function handlePing(receiverID, senderID, packet, distance)
		if packet.payload.ack then
			--If ack is true, then this is a ping reply
			queueEvent(PING, senderID, distance)
		else
			--Otherwise this is a request we should reply to
			local newReceiverID = senderID
			local newSenderID = myID
			local newPacket = {}
			newPacket.protocol = PING
			newPacket.payload = {}
			newPacket.payload.ack = true
			modem.transmit(newReceiverID, newSenderID, newPacket)
		end
	end
	
	local function handleMsg(receiverID, senderID, packet)
		queueEvent(MSG, senderID, packet.payload)
		
		--Send an ack back to the sender
		local rid = senderID
		local sid = myID
		local p = {}
		p.protocol = ACK
		p.payload = true
		modem.transmit(rid, sid, p)
	end
	
	local function handleAck(receiverID, senderID, packet)
		queueEvent(ACK, senderID)
	end
	
	local networkHandler = function()
		while true do
			local _,_,rid,sid,p,d = os.pullEvent("modem_message")
			
			if p.protocol then
				printPacket(rid, sid, p, d)
				
				if p.protocol == ARP then
					if p.payload.receiverLabel == myLabel then
						handleArp(rid, sid, p)
					end
				
				elseif p.protocol == PING then
					handlePing(rid, sid, p, d)
					
				elseif p.protocol == MSG then
					handleMsg(rid, sid, p)
					
				elseif p.protocol == ACK then
					handleAck(rid, sid, p)
				
				else
					error("unidentified packet")
				end
				
				os.queueEvent("jpi_new_message")
			end
		end
	end
	
	--Send an arp request, to resolve a label to an ID
	--targetLabel: The label of the computer we want to query
	--timeout (default=1): The number of seconds to wait for a reply
	--retryCount (default=5): The number of times to retry before returning nil
	jpi.arp = function(targetLabel, timeout, retryCount)
		if not targetLabel
		or type(targetLabel) ~= "string" then
			error("invalid targetLabel argument")
		end
	
		timeout = timeout or 1
		retryCount = retryCount or 5
		
		if arpCache[targetLabel] then
			return arpCache[targetLabel]
		end
		
		repeat
			jpi.dbg("sending arp: to " .. targetLabel)
			local rid = BROADCAST
			local sid = myID
			local p = {}
			p.protocol = ARP
			p.payload = {}
			p.payload.receiverLabel = targetLabel
			p.payload.senderLabel = myLabel
			modem.transmit(rid, sid, p)
			
			local targetID = nil
			local function getReply()
				while true do
					local _,id,lbl = pullEvent(ARP)
					
					if lbl == targetLabel then
						targetID = id
						return
					end
					
					queueEvent(ARP, id, lbl)
				end
			end
			parallel.waitForAny(getReply, function() os.sleep(timeout) end)
			
			if targetID then
				arpCache[targetLabel] = targetID
				return targetID
			end
			
			retryCount = retryCount - 1
		until retryCount <= 0
		
		return nil
	end
	
	--Send a ping request, receive the distance away from targetID
	--targetID: The target of the computer to ping
	--timeout (default=1): The number of seconds to wait for a reply
	--retryCount (default=5): The number of times to retry before returning nil
	--Note: returns -1 if target is in another dimension
	jpi.ping = function(targetID, timeout, retryCount)
		if not targetID
		or type(targetID) ~= "number" then
			error("invalid targetID argument")
		end
		
		timeout = timeout or 1
		retryCount = retryCount or 5
		
		repeat
			jpi.dbg("sending ping: to " .. targetID)
			local rid = targetID
			local sid = myID
			local p = {}
			p.protocol = PING
			p.payload = {}
			p.payload.ack = false
			modem.transmit(rid, sid, p)
			
			local success = false
			local distance = nil
			local function getReply()
				success,_,distance = pullEvent(PING, targetID)
			end
			parallel.waitForAny(getReply, function() os.sleep(timeout) end)
			
			if success then
				if not distance then
					return nil
				else
					return distance
				end
			end
			
			retryCount = retryCount - 1
		until retryCount <= 0
		
		return nil
	end
	
	--Send a message, return true if successful
	--targetID: The target of the computer to message
	--payload: The message to send (can be nil)
	--timeout (default=1): The number of seconds to wait for a reply
	--retryCount (default=5): The number of times to retry before returning nil
	jpi.send = function(targetID, payload, timeout, retryCount)
		if not targetID
		or type(targetID) ~= "number" then
			error("invalid targetID argument")
		end
		
		timeout = timeout or 1
		retryCount = retryCount or 5
	
		repeat
			jpi.dbg("sending message: to " .. targetID .. ", " .. tostring(payload))
			local rid = targetID
			local sid = myID
			local p = {}
			p.protocol = MSG
			p.payload = payload
			modem.transmit(rid, sid, p)
			
			local success = false
			local function getReply()
				success,_ = pullEvent(ACK, targetID)
			end
			parallel.waitForAny(getReply, function() os.sleep(timeout) end)
			
			if success then return true end
			
			retryCount = retryCount - 1
		until retryCount <= 0
		
		return false
	end
	
	--Wait to receive a message, return senderID and payload
	--filterID (optional): Filter for messages from a particular ID
	--timeout (optional): return nil after this many seconds
	jpi.receive = function(filterID, timeout)
		local payload = nil
		local senderID = nil
		
		local function rx()
			_,senderID,payload = pullEvent(MSG, filterID)
		end
		
		if timeout then
			parallel.waitForAny(rx, function() os.sleep(timeout) end)
		else
			rx()
		end
		
		return senderID, payload
	end
	
	jpi.getArpCache = function()
		return arpCache
	end
	
	jpi.clearArpCache = function()
		arpCache = {}
	end
	
	return deinitNetwork,networkHandler
end