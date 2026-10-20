-- Runs when pressing Play in Studio, not in production published servers.
if not game:GetService("RunService"):IsStudio() then return end
local Config=require(game:GetService("ReplicatedStorage"):WaitForChild("CartConfig"))
local R=require(game:GetService("ReplicatedStorage"):WaitForChild("CartRules"))
local n=0
local function ok(condition,message)
 n+=1;assert(condition,"[TUSOK SELF TEST] "..message)
end
ok(R.quality(3,true,4,4.8,6.9,9)=="RAW","no raw sales")
ok(R.quality(5.1,true,4,4.8,6.9,9)=="PERFECT","perfect fry")
ok(R.quality(5.1,false,4,4.8,6.9,9)=="OK","flip affects quality")
ok(R.quality(9,true,4,4.8,6.9,9)=="BURNT","burn timeout")
ok(not R.canFlip(1,false,1.5,6.8),"early flip")
ok(R.canFlip(3,false,1.5,6.8),"valid flip")
ok(not R.canFlip(3,true,1.5,6.8),"one flip only")
ok(R.countChange({[20]=1,[5]=1})==25,"count change")
ok(R.countChange({[2]=1})==nil,"reject unknown denominations")
ok(R.countChange({[1]=-1})==nil,"reject negative denominations")
local drawer=Config.INITIAL_COINS
local c={ [20]=1,[5]=1 }
local valid=R.affordableChange(drawer,c,25,50)
ok(valid,"correct 25 change")
local bad=R.affordableChange(drawer,{[20]=1},25,50)
ok(not bad,"reject incorrect change")
local shortage=R.affordableChange({[20]=0,[5]=0},{[20]=1,[5]=1},25,50)
ok(not shortage,"reject phantom coins")
local order={id=12,food="kwek",sauce="Vinegar",price=25,tender=50,expires=100,paid=false}
ok(R.isServeable(order,{kwek=1},"Vinegar",c,drawer,5),"normal settlement")
order.paid=true
ok(not R.isServeable(order,{kwek=1},"Vinegar",c,drawer,5),"duplicate settlement")
order.paid=false
ok(not R.isServeable(order,{kwek=0},"Vinegar",c,drawer,5),"no phantom food")
ok(not R.isServeable(order,{kwek=1},nil,c,drawer,5),"sauce needed")
ok(not R.isServeable(order,{kwek=1},"Vinegar",c,drawer,100),"expired order")
ok(R.canRestock(0,120,28,3,10),"restock empty")
ok(not R.canRestock(10,120,28,3,10),"cannot overfill")
local initial=R.payFromDrawer(Config.INITIAL_COINS,28)
ok(initial~=nil,"exact supply payment")
ok(R.countChange({[20]=1,[5]=1})==25,"still counts change")
ok(R.payFromDrawer({[1]=2},28)==nil,"cannot create change")
local initialTotal=0
for denom,count in pairs(Config.INITIAL_COINS) do
 initialTotal+=denom*count
end
ok(initialTotal==Config.INITIAL_CASH,"cash drawer matches cash value")
print("[TUSOK SELF TEST] passed "..n.." rules checks")
