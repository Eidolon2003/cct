if not jpi then
	require("jpi").execute("display.lua")
else


local mon = peripheral.wrap("right")
local out = term
if mon then
	mon.setTextScale(2)
	out = mon
end
out.clear()
out.setTextColor(colors.white)
out.setBackgroundColor(colors.black)

local sizeX, sizeY = out.getSize()

local miningServerID = nil

local function writeCentered(str, line)
	local x = (sizeX - string.len(str)) / 2
	out.setCursorPos(x, line)
	out.write(str)
end

local function progressBar(top, bot, line)
	out.setCursorPos(2, line)
	
	local length = sizeX - 2
	for i = 1, length do
		if (i / length) <= (top / bot) then
			out.setBackgroundColor(colors.cyan)
		else
			out.setBackgroundColor(colors.blue)
		end
		
		out.write(" ")
	end
	
	out.setBackgroundColor(colors.black)
end

while true do
	out.clear()
	local line = 1

	writeCentered("System Status:", line)
	line = line + 3
	
	if not miningServerID then
		miningServerID = jpi.arp("MiningServer")
	end
	
	--Make sure it's still there
	if miningServerID then
		if not jpi.ping(miningServerID) then
			miningServerID = nil
		end
	end
	
	out.setCursorPos(1, line)
	out.write("MiningServer: ")
	if not miningServerID then
		out.setTextColor(colors.red)
		out.write("Offline")
		out.setTextColor(colors.white)
		line = line + 3
	else
		out.setTextColor(colors.lime)
		out.write("Online")
		out.setTextColor(colors.white)
		line = line + 2
	
		repeat until jpi.send(miningServerID, 0)
		local id,payload = jpi.receive(miningServerID, 5)
		
		if id == miningServerID then
			out.setCursorPos(1, line)
			out.write("  Turtles: "..payload.turtles)
			line = line + 1
			
			out.setCursorPos(1, line)
			out.write("  Idle: "..payload.idle)
			line = line + 2
			
			out.setCursorPos(1, line)
			out.write("  Progress: "..payload.progress.."/256")
			line = line + 1
			
			progressBar(payload.progress, 256, line)
			line = line + 3
		end
	end
	
	os.sleep(10)
end


end