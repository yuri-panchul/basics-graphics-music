rem The port number should be adjusted
set a=21
mode com%a% baud=115200 parity=n data=8 stop=1 to=off xon=off odsr=off octs=off dtr=off rts=off idsr=off
type \.\CON >\.\COM%a%
