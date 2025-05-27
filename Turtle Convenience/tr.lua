args = {...}
iNum = args[1]
if not iNum then
	iNum = 1
end
for iCount = 1,iNum do
	turtle.turnRight()
end