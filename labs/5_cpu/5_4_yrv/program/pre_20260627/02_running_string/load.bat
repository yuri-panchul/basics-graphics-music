rem The port number should be adjusted
set a=1
mode com%a% baud=115200 parity=n data=8 stop=1 to=off xon=off odsr=off octs=off dtr=off rts=off idsr=off
type code_demo.mem32 >\.\COM%a%
