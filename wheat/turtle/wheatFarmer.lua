args = {...}
dim = {x = args[1],y = args[2]}
if not dim.x then dim.x = 9 end
if not dim.y then dim.y = 9 end

term.setCursorBlink(false)
wheat = paintutils.loadImage("pictures/wheat.nfp")
upTime = 0
counter = 0
console = {"","","","","","",""}
eventQueue = {}
coord = {x=1,y=0}
facing = "f"

--Establish network connection

network = peripheral.find("modem")
network.open(0)
repeat
	packet = {os.pullEvent("modem_message")}
until packet[5].protocol == "init" and packet[5].id == "wheat"
network.close(0)
server = packet[4]
client = packet[5].client
network.open(client)

network.transmit(server,client,{
protocol = "init",
ack = true
})

print("Established communication on port "..tostring(server)..","..tostring(client))

local function timeString()
	local seconds = upTime%3600%60%60
	local minutes = math.floor(upTime%3600/60)
	local hours = math.floor(upTime/3600)
	
	if seconds < 10 then
		seconds = "0"..tostring(seconds)
	else
		seconds = tostring(seconds)
	end
	
	if minutes < 10 then
		minutes = "0"..tostring(minutes)
	else
		minutes = tostring(minutes)
	end
	
	hours = tostring(hours)
	
	return hours..":"..minutes..":"..seconds
end

local function output(newOutput)
	table.insert(console,newOutput)
	table.remove(console,1)
end

local function outputError(string)
	output("E: "..string.." "..tostring(coord.x)..","..tostring(coord.y))
end

local function refuel()
	turtle.select(16)
	if turtle.refuel(1) then
		output("Refueled")
	else
		outputError("No fuel")
	end
	turtle.select(1)
end

local function face(goal)
	--print("face",goal)
	if facing == goal then return end
	if goal == "f" then
		if facing == "l" then
			turtle.turnRight()
		elseif facing == "r" then
			turtle.turnLeft()
		elseif facing =="b" then
			turtle.turnLeft() turtle.turnLeft()
		end
	elseif goal == "l" then
		if facing == "f" then
			turtle.turnLeft()
		elseif facing == "b" then
			turtle.turnRight()
		elseif facing == "r" then
			turtle.turnLeft() turtle.turnLeft()
		end
	elseif goal == "r" then
		if facing == "f" then
			turtle.turnRight()
		elseif facing == "b" then
			turtle.turnLeft()
		elseif facing == "l" then
			turtle.turnLeft() turtle.turnLeft()
		end
	elseif goal == "b" then
		if facing == "l" then
			turtle.turnLeft()
		elseif facing == "r" then
			turtle.turnRight()
		elseif facing == "f" then
			turtle.turnLeft() turtle.turnLeft()
		end
	end
	facing = goal
end

local function goto(x,y)
	if coord.y ~= y then
		if coord.y < y then
			face("f")
			for i = coord.y,y-1 do
				if not turtle.forward() then
					outputError("Path blocked")
				end
			end
		else
			face("b")
			for i = y,coord.y-1 do
				if not turtle.forward() then
					outputError("Path blocked")
				end
			end
		end
		coord.y = y
	end

	if coord.x ~= x then
		if coord.x < x then
			face("r")
			for i = coord.x,x-1 do
				if not turtle.forward() then
					outputError("Path blocked")
				end
			end
		else
			face("l")
			for i = x,coord.x-1 do
				if not turtle.forward() then
					outputError("Path blocked")
				end
			end
		end
		coord.x = x
	end
end

local function dropOff(x,y)
	goto(1,0)
	output("Unloading items")
	for i = 2,15 do
		turtle.select(i)
		local item = turtle.getItemDetail()
		if item and item.name == "minecraft:wheat" then
			face("b")
			turtle.drop()
		elseif item and item.name == "minecraft:wheat_seeds" then
			face("b")
			turtle.dropDown()
		elseif item then
			face("r")
			turtle.drop()
		end
	end	
	goto(x,y)
	turtle.select(1)
end

local function findChest()
	local packet = 0
	local prevDistance = 0
	network.open(server)
	
	for i = 1,4 do
		network.transmit(server,server,{protocol = "ping",ack = false})
		repeat
			packet = {os.pullEvent("modem_message")}
		until packet[5].protocol == "ping" and packet[5].ack
	
		repeat
			prevDistance = packet[6]
			turtle.forward()
			network.transmit(server,server,{protocol = "ping",ack = false})
			repeat
				packet = {os.pullEvent("modem_message")}
			until packet[5].protocol == "ping" and packet[5].ack	
		until packet[6] >= prevDistance
		if packet[6] > prevDistance then
			turtle.turnLeft() turtle.turnLeft()
			turtle.forward()
			turtle.turnLeft() turtle.turnLeft()
		end
		turtle.turnRight()
	end
	
	--face forward, chest must be behind turtle
	while not turtle.inspect() do
		turtle.turnLeft()
	end
	turtle.turnLeft() turtle.turnLeft()
	
	network.close(server)
end

local function updateDisplay() --Turtle terminal is 39x13 characters
	while true do
		term.clear()
		term.setTextColor(colors.lime)
		term.setCursorPos(1,1)  term.write("                     Hold PAUSE to exit")
		term.setCursorPos(1,2)  term.write("                                       ")
		term.setCursorPos(1,3)  term.write(" Wheat Farmed:                         ")
		term.setCursorPos(1,4)  term.write("                                       ")
		term.setCursorPos(1,5)  term.write(" Fuel Level:                           ")
		term.setCursorPos(1,6)  term.write("                                       ")
		term.setCursorPos(1,7)  term.write("                                       ")
		term.setCursorPos(1,8)  term.write("                                       ")
		term.setCursorPos(1,9)  term.write("                                       ")
		term.setCursorPos(1,10) term.write("                                       ")
		term.setCursorPos(1,11) term.write("                                       ")
		term.setCursorPos(1,12) term.write("                                       ")
		term.setCursorPos(1,13) term.write(">                                      ")
		paintutils.drawImage(wheat,25,2)
		term.setCursorPos(1,1)  term.write(timeString())
		term.setCursorPos(16,3) term.write(tostring(counter))
		term.setCursorPos(14,5) term.write(tostring(turtle.getFuelLevel()))
		
		term.setTextColor(colors.red)
		term.setCursorPos(3,7)  term.write(console[1])
		term.setCursorPos(3,8)  term.write(console[2])
		term.setCursorPos(3,9)  term.write(console[3])
		term.setCursorPos(3,10) term.write(console[4])
		term.setCursorPos(3,11) term.write(console[5])
		term.setCursorPos(3,12) term.write(console[6])
		term.setCursorPos(3,13) term.write(console[7])
		
		sleep(0.05)
	end
end

local function eventCatcher()
	local timerID = os.startTimer(1)
	while true do
		local event = {os.pullEvent()}
		
		if event[1] == "timer" and event[2] == timerID then
			timerID = os.startTimer(1)
			upTime = upTime + 1
			
		elseif event[1] == "key" or event[1] == "modem_message" then
			table.insert(eventQueue,event)	
		end
		
	end
end

local function eventHandler()
	while true do
		local event = table.remove(eventQueue)
		if event then
		
			if event[1] == "key" and event[2] == keys.r and event[3] == false then
				refuel()
				
			elseif event[1] == "key" and event[2] == keys.pause and event[3] == true then
				term.clear()
				term.setCursorPos(1,1)
				network.closeAll()
				return
			
			elseif event[1] == "modem_message" and event[5].protocol == "ping" and not event[5].ack then
				output("ping")
				network.transmit(client,0,{protocol = "ping",ack = true})
				
			end
		end
		sleep(0.05)
	end
end

local function checker()
	while true do
		if turtle.getFuelLevel() < 100 then
			output("Fuel level low")
			refuel()
		end
		sleep(5)
	end
end

local function main()
	sleep(0.2)
	output(tostring(dim.x).."x"..tostring(dim.y).." Wheat Farmer")
	sleep(0.2)
	output("By Eidolon_2003")
	sleep(0.2)
	output("")
	sleep(0.2)
	output("Seeds in slot 1")
	sleep(0.2)
	output("Fuel in slot 16")
	sleep(0.2)
	output("Press R to force refuel")
	sleep(0.5)

	turtle.select(1)
	while true do
		output("Starting farming")
		for x = 1,dim.x do
			for y = 1,dim.y do
			
				if x%2 == 1 then
					goto(coord.x,coord.y+1)
				else
					goto(coord.x,coord.y-1)
				end
				
				local inspect = {turtle.inspectDown()}
				
				if inspect[1] and inspect[2].state.age == 7 then --if grown wheat
					turtle.digDown()
					counter = counter + 1
					local item = turtle.getItemDetail()		
					if not item or item.name ~= "minecraft:wheat_seeds" then
						outputError("No seeds")
						
					elseif item.count == 1 then
						outputError("Low seeds")
						
					elseif not turtle.placeDown() then
						turtle.digDown() --Till the land
						if not turtle.placeDown() then
							outputError("No farmland")
						end
					end	
					
				elseif inspect[1] and not inspect[2].name == "minecraft:wheat" then --if block in the way
					if not inspect[2].name == "minecraft: stone_bricks" then
						outputError("Blocked")
					end
					
				elseif not inspect[1] then --if no plant
					local item = turtle.getItemDetail()			
					if not item or item.name ~= "minecraft:wheat_seeds" then
						outputError("No seeds")
						
					elseif item.count == 1 then
						outputError("Low on seeds")
						
					elseif not turtle.placeDown() then
						turtle.digDown() --Till the land
						if not turtle.placeDown() then
							outputError("No farmland")
						end
					end	
				end
	
				turtle.select(15)
				if turtle.getItemCount() > 0 then
					output("Inventory full")
					dropOff(coord.x,coord.y)
					output("Continuing farming")
				end
				turtle.select(1)
			end
			
			if	x%2 == 1 then
				goto(coord.x+1,dim.y+1)
			else
				goto(coord.x+1,0)
			end	
		end
		output("Done Farming")
		dropOff(1,0)
		face("f")
		output("Waiting 5 mins "..timeString())
		sleep(300)
	end
end

print("Finding the chests")
findChest()
parallel.waitForAny(main,checker,eventCatcher,eventHandler,updateDisplay)