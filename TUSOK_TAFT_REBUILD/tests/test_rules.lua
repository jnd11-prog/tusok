-- Headless Lua tests. Portable CartRules loaded after mechanical Luau assignment translation.
local root=arg[1] or '.'
local R=dofile(root..'/CartRules.lua')
local C=dofile(root..'/CartConfig.lua')
local counter=0
local function check(value,msg)
 counter=counter+1
 assert(value,'CHECK # '..counter..' failed: '..msg)
end
for i=1,100 do
 local t=(i-1)/10
 local result=R.quality(t,true,4,4.8,6.9,9)
 check(result=='RAW' or result=='BURNT' or result=='OK' or result=='PERFECT','fry quality is a valid state')
 if t<4 then check(result=='RAW','no raw food can be served') end
 if t>=9 then check(result=='BURNT','burning is rejected') end
end
check(R.quality(5.3,true,4,4.8,6.9,9)=='PERFECT','good flip + good lift')
check(R.quality(5.3,false,4,4.8,6.9,9)=='OK','no flip only okay')
check(R.canFlip(2,false,1.5,6.8),'flip after 1.5')
check(not R.canFlip(2,true,1.5,6.8),'only flip once')
check(not R.canFlip(0.5,false,1.5,6.8),'early flip rejected')
check(not R.canFlip(8,false,1.5,6.8),'late flip rejected')
check(R.countChange({[20]=1,[5]=1})==25,'counts denominations')
check(R.countChange({[1]=3,[5]=1})==8,'counts small denominations')
check(R.countChange({[3]=1})==nil,'unknown denomination')
check(R.countChange({[10]=-1})==nil,'negative denomination')
local ok,reason=R.affordableChange(C.INITIAL_COINS,{[20]=1,[5]=1},25,50)
check(ok and reason=='ok','tenders correct 25')
check(not R.affordableChange(C.INITIAL_COINS,{[20]=1},25,50),'wrong change fails')
check(not R.affordableChange(C.INITIAL_COINS,{[50]=2},25,125),'phantom coins fail')
local originalSum=0
for denom,n in pairs(C.INITIAL_COINS) do originalSum=originalSum+denom*n end
check(originalSum==C.INITIAL_CASH,'drawer and initial cash consistent')
local new=R.payFromDrawer(C.INITIAL_COINS,28)
check(new~=nil,'supply purchase 28')
local newSum=0
for denom,n in pairs(new) do newSum=newSum+denom*n end
check(newSum==originalSum-28,'supply purchase conserves cash')
check(new[1]==15 and new[5]==9 and new[20]==3,'expected exact denominations removed')
check(R.payFromDrawer({[20]=1,[5]=1,[1]=1},28)==nil,'cannot create phantom barya')
check(R.payFromDrawer(C.INITIAL_COINS,-1)==nil,'reject negative amount')
local order={food='kwek',paid=false,expires=100,price=25,tender=50}
check(R.isServeable(order,{kwek=1},'Vinegar',{[20]=1,[5]=1},C.INITIAL_COINS,5),'valid settlement')
order.paid=true
check(not R.isServeable(order,{kwek=1},'Vinegar',{[20]=1,[5]=1},C.INITIAL_COINS,5),'duplicate sale rejected')
order.paid=false
check(not R.isServeable(order,{kwek=0},'Vinegar',{[20]=1,[5]=1},C.INITIAL_COINS,5),'no phantom food')
check(not R.isServeable(order,{kwek=1},nil,{[20]=1,[5]=1},C.INITIAL_COINS,5),'sauce required')
check(not R.isServeable(order,{kwek=1},'Vinegar',{[20]=1,[5]=1},C.INITIAL_COINS,100),'expired request')
for _,spec in ipairs(C.SHIFT_ORDERS) do
 local price=C.FOOD[spec.food].price
 check(spec.tender>=price,'payment amount')
 check(spec.wait>=60,'time to serve')
 check(C.SAUCE[spec.sauce]~=nil,'valid condiment')
end
-- Execute the full preset shift's monetary transactions using only initial stock and drawer.
-- This catches an unbeatable late-order sukli requirement before Roblox playtests.
local drawer={}
for d,n in pairs(C.INITIAL_COINS) do drawer[d]=n end
local cash=C.INITIAL_CASH
local demand={kwek=0,fishball=0,kikiam=0}
for _,spec in ipairs(C.SHIFT_ORDERS) do
 local price=C.FOOD[spec.food].price
 local change=spec.tender-price
 local result=R.payFromDrawer(drawer,change)
 check(result~=nil,'order '..spec.food..' change is solvable')
 if not result then break end
 drawer=result
 drawer[spec.tender]=(drawer[spec.tender] or 0)+1
 drawer[1]=(drawer[1] or 0)+2 -- ideal flip means a 2 peso tip, credited in coins
 cash=cash+price+2
 demand[spec.food]=demand[spec.food]+1
 local inDrawer=0
 for denomination,n in pairs(drawer) do inDrawer=inDrawer+denomination*n end
 check(inDrawer==cash,'register balance after order')
end
for food,count in pairs(demand) do
 check(count<=C.STARTING_STOCK[food],'initial stock supports all default orders')
end
print('PASS '..counter..' headless vendor-rule assertions')
