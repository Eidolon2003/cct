args = {...}
iSize = args[1]
for i = 1,iSize do
  for ii = 1,iSize-1 do
    turtle.digUp()
    turtle.dig()
    turtle.forward()
    print(turtle.getFuelLevel())
  end
  if i%2 == 1 then
    turtle.digUp()
    turtle.turnRight()
    turtle.dig()
    turtle.forward()
    print(turtle.getFuelLevel())
    turtle.turnRight()
  else
    turtle.digUp()
    turtle.turnLeft()
    turtle.dig()
    turtle.forward()
    turtle.turnLeft()
  end
end

