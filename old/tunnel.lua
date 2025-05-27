args = {...}
iNum = args[1]
if not iNum then
  iNum = 1
end
for iCount = 1,iNum do
  repeat until not turtle.dig()
  turtle.forward()
  print(turtle.getFuelLevel())
  turtle.digUp()
end
print("Tunnel Complete")
