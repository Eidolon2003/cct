--Pulls specified files from the repo
--list files in "/pull.list"

base = "https://raw.githubusercontent.com/Eidolon2003/cct/refs/heads/main/DW1.21/"

file = fs.open("/pull.list", "r")
if not file then
	print("Couldn't open /pull.list")
	return
end

while true do
	local line = file.readLine()
	if not line or line == "" then break end
	
	local url = base .. line
	local tempName = "." .. line
	shell.execute("wget", url, tempName)
	
	if fs.exists(tempName) then
		print("Replacing " .. line)
		shell.execute("rm", line)
		shell.execute("mv", tempName, line)
	end
end

file.close()