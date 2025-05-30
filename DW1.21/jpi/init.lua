local jpi = {}

local function merge(t1, t2)
	for key,val in pairs(t2) do
		t1[key] = val
	end
end

merge(jpi, dofile("/jpi/network.lua"))
if turtle then 
	merge(jpi, dofile("/jpi/turtle.lua")) 
end

local function bindCall(program)
	local result = false

	local runner = function()
		local env = {myLabel, myID, modem}
		merge(env, getfenv())
		result = os.run(env, program)
	end
	
	local getResult = function()
		return result
	end
	
	return runner,getResult
end

function jpi.execute(program)
	initNetwork()
	
	local runner,getResult = bindCall(program)
	
	parallel.waitForAny(
		handleEvents,
		runner
	)
	
	if getResult() then
		print("jpi: " .. program .. " exited successfully")
	else
		print("jpi: " .. program .. " exited with error")
	end
	
	deinitNetwork()
	
	return getResult()
end

return jpi