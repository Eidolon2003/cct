local function shellRunner()
	leftMon = peripheral.wrap("left")
	
	leftMon.setTextScale(1)
	leftMon.clear()
	leftMon.setCursorPos(1,1)
	shell.run("monitor left shell")
end

local function displayRunner()
	--use os.run so I can pass jpi in env
	env = getfenv()
	os.run(env, "display.lua")
end

local function messageHandler()
	while true do
		--Only listen to messages from pocket computers
		local sleepFlag = true
		local arp = jpi.getArpCache()
		for k,v in pairs(arp) do
			if string.find(string.upper(k), "POCKET") then
				sleepFlag = false
				local id,payload = jpi.receive(v, 1)
				
				if id then
					os.queueEvent(
						payload.event,
						payload.first,
						payload.second
					)
				end
			end
		end
		
		if sleepFlag then
			os.sleep(1)
		end
	end
end

parallel.waitForAny(messageHandler, shellRunner, displayRunner)