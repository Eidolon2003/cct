network = peripheral.find("modem")
server = 0
portFound = false

--Find an open channel
local function timer()
	sleep(1)
	portFound = true
end

local function checker()
	network.transmit(server,server,{protocol = "ping",ack = false})
	repeat
		local packet = {os.pullEvent("modem_message")}
	until packet[5].protocol == "ping" and packet[5].ack
end

repeat 
	network.close(server)
	server = server + 1
	network.open(server)
	parallel.waitForAny(timer,checker)
until portFound
client = server + 10000

--Open channel found, contact client
network.transmit(0,server,{
protocol = "init",
ack = false,
id = "wheat",
client = client
})

--Wait for acknowledgement
repeat
	packet = {os.pullEvent("modem_message")}
until packet[3] == server and packet[4] == client and packet[5].protocol == "init" and packet[5].ack

print("Established communication on port "..tostring(server)..","..tostring(client))

--Process ping packets
while true do
	local packet = {os.pullEvent("modem_message")}
	if packet[5].protocol == "ping" and not packet[5].ack then
		--print("ping")
		network.transmit(server,0,{protocol = "ping",ack = true})
	end
end