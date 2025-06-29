local function main(jpi)
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
			miningServerID = jpi.arp("MiningServer",1,1)
		end
		
		out.setCursorPos(1, line)
		out.write("MiningServer: ")
		
		if miningServerID and jpi.send(miningServerID, 1, 1) then
			out.setTextColor(colors.lime)
			out.write("Online")
			out.setTextColor(colors.white)
			line = line + 2
		
			local _,payload = jpi.receive(miningServerID)
			
			out.setCursorPos(1, line)
			out.write("  Active: "..payload.turtles)
			line = line + 1
			
			out.setCursorPos(1, line)
			out.write("  Idling: "..payload.idle)
			line = line + 2
			
			out.setCursorPos(1, line)
			out.write("  Progress: "..payload.progress.."/256")
			line = line + 1
			
			progressBar(payload.progress, 256, line)
			line = line + 3
		else
			out.setTextColor(colors.red)
			out.write("Offline")
			out.setTextColor(colors.white)
			line = line + 3
		end
		
		os.sleep(10)
	end
end

if jpi then
	main(jpi)
else
	require("jpi")(main)
end