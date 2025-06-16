return function(prg, dbg)
	--This table will contain API functions and such
	local jpi = {}
	
	--Define constants
	jpi.EXIT_SUCCESS = true
	jpi.EXIT_FAILURE = false
	jpi.EXIT_SILENT = "silent"

	--Set up debugging if applicable
	--not not reinterprets any input as true or false
	jpi.isDebug = not not dbg
	
	jpi.dbg = function(txt)
		if not jpi.isDebug then return end
	
		local file = fs.open("log", "a")
		if not file then
			error("failed to open log file")
		end
		
		print(txt)
		file.write(os.date() .. ": " .. txt .. "\n")
		file.close()
	end
	
	jpi.dbgPrint = function(txt)
		if jpi.isDebug then
			jpi.dbg(txt)
		else
			print(txt)
		end
	end

	--Include optional modules
	local initNetwork = nil
	local deinitNetwork = nil
	local networkHandler = nil
	if fs.exists("jpi/network.lua") then
		jpi.dbg("including network module")
		deinitNetwork,networkHandler = dofile("jpi/network.lua")(jpi)
	end
	
	if fs.exists("jpi/turtle.lua") and turtle then
		jpi.dbg("including turtle module")
		dofile("jpi/turtle.lua")(jpi)
	end
	
	--Parallel function for properly handling termination events
	local function terminator()
		os.pullEventRaw("terminate")
		jpi.dbgPrint("jpi: execution terminated")
	end

	--Execute the program
	jpi.dbg("beginning execution")

	if type(prg) == "function" then
		local ret = jpi.EXIT_SILENT
		local wrapper = function()
			ret = prg(jpi)
		end
		
		if networkHandler then
			parallel.waitForAny(terminator, networkHandler, wrapper)
		else
			parallel.waitForAny(terminator, wrapper)
		end
		
		if deinitNetwork then deinitNetwork() end
		
		if ret ~= jpi.EXIT_SILENT then
			if ret then
				jpi.dbgPrint("jpi: exited successfully")
			else
				jpi.dbgPrint("jpi: exited with error")
			end
		end
		
		return ret
	end
	
	--string means a path to a lua file to run
	if type(prg) == "string" then
		--todo
	end
	
	--prg has to be either a function or a path
	error("unexpected first argument")
end