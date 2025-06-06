local function shellRunner()
	shell.run("monitor left clear")
	shell.run("monitor left shell")
end

local function messageHandler()
	while true do
		id,payload = jpi.receive()
		os.queueEvent(payload.event, payload.first, payload.second)
	end
end

parallel.waitForAny(messageHandler, shellRunner)