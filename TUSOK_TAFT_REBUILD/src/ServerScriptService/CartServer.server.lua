-- TUSOK! / one vendor, one cart, one fryer. The server is the source of truth.
-- The action handler never yields between validating and changing a transaction.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local Config=require(ReplicatedStorage:WaitForChild("CartConfig"))
local Rules=require(ReplicatedStorage:WaitForChild("CartRules"))

local signals=Instance.new("Folder")
signals.Name="CartSignals";signals.Parent=ReplicatedStorage
local Request=Instance.new("RemoteEvent")
Request.Name="Request";Request.Parent=signals
local Push=Instance.new("RemoteEvent")
Push.Name="Push";Push.Parent=signals

local vendor=nil
local shift=nil
local transactionSequence=0
local lastRemote={}
local lastSnapshot=0
local cart=Workspace:WaitForChild("TaftCart")
local interact=cart:WaitForChild("Hotspots")

local function cloneMap(t)
 local copy={}
 for k,v in pairs(t) do copy[k]=v end
 return copy
end
local function notify(message)
 if vendor and vendor.Parent==Players then
  Push:FireClient(vendor,{kind="Toast",text=message})
 end
end
local function readyCounts()
 local counts={kwek=0,fishball=0,kikiam=0}
 if shift then
  for food,portions in pairs(shift.prepared) do counts[food]=#portions end
 end
 return counts
end
local function snapshot()
 if not shift then return {phase="idle"} end
 local coinView={}
 -- RemoteEvent dictionaries are sent with STRING keys. Numeric sparse keys can be lost.
 for _,denom in ipairs(Config.DENOMINATIONS) do
  coinView[tostring(denom)]=shift.coins[denom] or 0
 end
 local c=shift.cooking
 local cooking=nil
 if c then
  cooking={food=c.food,stage=c.stage,session=c.session,drained=c.drained,
   flipped=c.flipped,elapsed=c.started and math.max(0,os.clock()-c.started) or 0,
   quality=c.quality}
 end
 local o=shift.order
 local order=nil
 if o then
  order={id=o.id,number=o.number,food=o.food,sauce=o.sauce,
   price=o.price,tender=o.tender,change=o.tender-o.price,
   name=o.name,line=o.line,remaining=math.max(0,o.expires-os.clock()),
   duration=o.duration}
 end
 return {phase=shift.phase,order=order,cooking=cooking,
  stock=cloneMap(shift.stock),prepared=readyCounts(),coins=coinView,
  sauce=shift.sauce,served=shift.served,missed=shift.missed,burnt=shift.burnt,
  sales=shift.sales,tips=shift.tips,spent=shift.spent,cash=shift.cash,
  count=shift.count,shiftLeft=math.max(0,Config.SHIFT_SECONDS-(os.clock()-shift.started)),
  paymentOpen=shift.pending~=nil}
end
local function sync()
 if vendor and vendor.Parent==Players then
  Push:FireClient(vendor,{kind="State",data=snapshot()})
 end
end
local function finishShift()
 if not shift or shift.phase~="active" then return end
 shift.phase="ended";shift.order=nil;shift.cooking=nil;shift.pending=nil
 notify("SARADO NA. Bumalik si Ate Bebang. May dala siyang yelo.")
 sync()
end
local function nextOrder()
 if not shift or shift.phase~="active" then return end
 if shift.count>=Config.ORDERS_PER_SHIFT or os.clock()-shift.started>=Config.SHIFT_SECONDS then
  finishShift();return
 end
 shift.count+=1
 transactionSequence+=1
 local n=shift.count
 local spec=Config.SHIFT_ORDERS[n]
 local customer=Config.CUSTOMERS[n]
 local price=Config.FOOD[spec.food].price
 shift.order={id=transactionSequence,number=n,food=spec.food,
  sauce=spec.sauce,price=price,tender=spec.tender,
  name=customer.name,line=customer.line,paid=false,
  duration=spec.wait,expires=os.clock()+spec.wait}
 shift.sauce=nil;shift.pending=nil
 sync()
 if n==5 then notify("Rush hour. May bagong dismissal sa gate.") end
end
local function startShift(player)
 if player~=vendor then return end
 if shift and shift.phase=="active" then sync();return end
 shift={phase="active",started=os.clock(),cash=Config.INITIAL_CASH,
  sales=0,tips=0,spent=0,served=0,missed=0,burnt=0,count=0,
  stock=cloneMap(Config.STARTING_STOCK),prepared={kwek={},fishball={},kikiam={}},
  coins=cloneMap(Config.INITIAL_COINS),cooking=nil,order=nil,
  pending=nil,sauce=nil,cookSequence=0}
 notify("5:17 PM. Ate Bebang went to buy ice. Ikaw muna.")
 nextOrder()
end
local function startFry(food)
 if not Config.FOOD[food] then return end
 if shift.cooking then notify("May nakasalang na. Isa lang ang kawali.");return end
 if shift.stock[food]<=0 then notify("Ubos ang "..Config.FOOD[food].label..". Mag-restock muna.");return end
 if #shift.prepared[food]>=4 then notify("Puno na ang tray. Serve muna.");return end
 shift.stock[food]-=1
 shift.cookSequence+=1
 shift.cooking={food=food,stage="READY",session=shift.cookSequence,
  drained=0,flipped=false,quality=nil,started=nil}
 sync()
end
local function drop(session)
 local c=shift.cooking
 if not c or c.session~=session or c.stage~="READY" then return end
 c.stage="FRYING";c.started=os.clock()
 sync()
end
local function flip(session)
 local c=shift.cooking
 if not c or c.session~=session or c.stage~="FRYING" then return end
 local elapsed=os.clock()-c.started
 if not Rules.canFlip(elapsed,c.flipped,Config.FLIP_FROM,Config.FLIP_TO) then
  notify("Hintay ng konti bago baliktarin. Isang beses lang.");return
 end
 c.flipped=true
 notify("Nabaliktad. Bantayan ang oil.")
 sync()
end
local function lift(session)
 local c=shift.cooking
 if not c or c.session~=session or c.stage~="FRYING" then return end
 local q=Rules.quality(os.clock()-c.started,c.flipped,
  Config.FRY_GOOD_FROM,Config.FRY_PERFECT_FROM,Config.FRY_PERFECT_TO,Config.FRY_BURN_AT)
 if q=="RAW" then notify("Hilaw pa. Hintayin mong umangat at magkulay.");return end
 if q=="BURNT" then
  shift.burnt+=1;shift.cooking=nil
  notify("Sunog. Sayang ang stock. Try ulit.")
 else
  c.stage="DRAIN";c.quality=q;c.drained=0;c.lastDrain=0
  notify(q=="PERFECT" and "Ang ganda ng luto. Patuluin muna ang mantika." or "Pwede na. Patuluin muna.")
 end
 sync()
end
local function drain(session)
 local c=shift.cooking
 if not c or c.session~=session or c.stage~="DRAIN" then return end
 if os.clock()-(c.lastDrain or 0)<.19 then return end
 c.lastDrain=os.clock();c.drained+=1
 if c.drained>=Config.DRAIN_TAPS then
  table.insert(shift.prepared[c.food],c.quality)
  local food=Config.FOOD[c.food].label
  shift.cooking=nil
  notify(food.." on the tray. Pili ng sawsawan.")
 end
 sync()
end
local function cancelCook()
 local c=shift.cooking
 if not c then return end
 if c.stage=="READY" then
  shift.stock[c.food]+=1
 else
  shift.burnt+=1
 end
 shift.cooking=nil
 notify("Tinabi ang batch.")
 sync()
end
local function selectSauce(sauce)
 if not Config.SAUCE[sauce] then return end
 shift.sauce=sauce;shift.pending=nil
 notify("SAWSAWAN: "..Config.SAUCE[sauce])
 sync()
end
local function restock(food)
 if not Config.FOOD[food] then return end
 if not Rules.canRestock(shift.stock[food],shift.cash,Config.RESTOCK_COST,
  Config.RESTOCK_QUANTITY,Config.MAX_STOCK) then
  notify("Kulang sa kaha o puno na ang stock.");return
 end
 local paidDrawer=Rules.payFromDrawer(shift.coins,Config.RESTOCK_COST)
 if not paidDrawer then notify("Walang eksaktong ₱28 sa kaha. Kailangan ng barya.");return end
 shift.coins=paidDrawer
 shift.cash-=Config.RESTOCK_COST;shift.spent+=Config.RESTOCK_COST
 shift.stock[food]=math.min(Config.MAX_STOCK,shift.stock[food]+Config.RESTOCK_QUANTITY)
 notify("+3 portions: "..Config.FOOD[food].label..". ₱28 gastos.")
 sync()
end
local function beginSale()
 local o=shift.order
 if not o then notify("Wala pang customer.");return end
 if #shift.prepared[o.food]<1 then notify("Wala pang lutong "..Config.FOOD[o.food].label..".");return end
 if not shift.sauce then notify("Sawsawan muna. Anong sauce ang gusto niya?");return end
 if shift.sauce~=o.sauce then
  notify("Ibang sauce! Kailangan "..Config.SAUCE[o.sauce]..".")
  return
 end
 shift.pending={orderId=o.id,opened=os.clock()}
 Push:FireClient(vendor,{kind="Payment",orderId=o.id,price=o.price,
  tender=o.tender,due=o.tender-o.price})
 sync()
end
local function settle(id,coins)
 local o=shift.order
 if not o or o.id~=id then notify("Lumang resibo na 'yan.");return end
 if not shift.pending or shift.pending.orderId~=id or
  os.clock()-shift.pending.opened>45 then notify("Serve muna bago bilang ng barya.");return end
 if type(coins)~="table" then return end
 local sanitized={}
 for i,denom in ipairs(Config.DENOMINATIONS) do
  local n=coins[i] or 0
  if type(n)~="number" or n<0 or n>30 or n%1~=0 then return end
  sanitized[denom]=n
 end
 -- Whitelist exact keys; ignore rogue keys rather than allow crafted denominations.
 if shift.sauce~=o.sauce then
  notify("Sawsawan mali! Gusto niya "..Config.SAUCE[o.sauce]..".")
  shift.pending=nil
  sync()
  return
 end
 local ok,reason=Rules.isServeable(o,readyCounts(),shift.sauce,sanitized,
  shift.coins,os.clock())
 if not ok then
  notify(reason=="wrong change" and "Mali ang sukli. Bilang ulit." or
   reason=="not enough coins" and "Kulang ang barya sa kaha." or
   "Hindi pa ready ang order: "..reason)
  return
 end
 -- Atomic: no yielding after validation, no second client request can settle it.
 o.paid=true
 local quality=table.remove(shift.prepared[o.food],1)
 local correctSauce=true
 local tip=quality=="PERFECT" and 2 or 0
 for denom,n in pairs(sanitized) do
  shift.coins[denom]-=n
 end
 shift.coins[o.tender]=(shift.coins[o.tender] or 0)+1
 if tip>0 then shift.coins[1]=(shift.coins[1] or 0)+tip end
 shift.cash+=o.price+tip;shift.sales+=o.price;shift.tips+=tip
 shift.served+=1;shift.order=nil;shift.pending=nil;shift.sauce=nil
 notify("Salamat po! ₱"..o.price..(tip>0 and " + ₱2 tip" or "")..".")
 sync()
 task.delay(1.1,function()
  if shift and shift.phase=="active" and not shift.order then nextOrder() end
 end)
end
local function handle(player,data)
 if player~=vendor then return end
 local action=data.action
 if action=="Sync" then sync();return end
 if action=="StartShift" then startShift(player);return end
 if not shift or shift.phase~="active" then return end
 if os.clock()-shift.started>=Config.SHIFT_SECONDS then finishShift();return end
 if action=="StartFry" and type(data.food)=="string" then startFry(data.food)
 elseif action=="Drop" then drop(data.session)
 elseif action=="Flip" then flip(data.session)
 elseif action=="Lift" then lift(data.session)
 elseif action=="Drain" then drain(data.session)
 elseif action=="Cancel" then cancelCook()
 elseif action=="Sauce" and type(data.sauce)=="string" then selectSauce(data.sauce)
 elseif action=="Serve" then beginSale()
 elseif action=="Settle" and type(data.orderId)=="number" then settle(data.orderId,data.coins)
 elseif action=="Restock" and type(data.food)=="string" then restock(data.food)
 end
end
Request.OnServerEvent:Connect(function(player,data)
 if type(data)~="table" or type(data.action)~="string" or #data.action>18 then return end
 local now=os.clock()
 if now-(lastRemote[player] or 0)<.07 then return end
 lastRemote[player]=now
 local ok,err=pcall(handle,player,data)
 if not ok then warn("[TUSOK CART]",err);notify("May problem sa cart. View → Output.") end
end)
local hotspots={Kwek="kwek",Fish="fishball",Kikiam="kikiam"}
for name,food in pairs(hotspots) do
 local obj=interact:FindFirstChild(name)
 local click=obj and obj:FindFirstChildOfClass("ClickDetector")
 if click then
  click.MouseClick:Connect(function(player)
   if player==vendor and shift and shift.phase=="active" then startFry(food) end
  end)
 end
end
for name,sauce in pairs({Sweet="Sweet",Spicy="Spicy",Vinegar="Vinegar"}) do
 local obj=interact:FindFirstChild(name)
 local click=obj and obj:FindFirstChildOfClass("ClickDetector")
 if click then
  click.MouseClick:Connect(function(player)
   if player==vendor and shift and shift.phase=="active" then selectSauce(sauce) end
  end)
 end
end
Players.PlayerAdded:Connect(function(p)
 if not vendor then vendor=p end
 task.delay(1.6,function()
  if p.Parent~=Players then return end
  if p==vendor then Push:FireClient(p,{kind="State",data=snapshot()})
  else Push:FireClient(p,{kind="State",data={phase="spectator"}}) end
 end)
end)
Players.PlayerRemoving:Connect(function(p)
 lastRemote[p]=nil
 if p==vendor then
  vendor=nil;shift=nil
  for _,other in ipairs(Players:GetPlayers()) do
   if other~=p then vendor=other;Push:FireClient(other,{kind="State",data={phase="idle"}});break end
  end
 end
end)
task.spawn(function()
 while true do
  task.wait(.3)
  if shift and shift.phase=="active" then
   local t=os.clock()
   if t-shift.started>=Config.SHIFT_SECONDS then finishShift()
   else
    local c=shift.cooking
    if c and c.stage=="FRYING" and t-c.started>=Config.FRY_BURN_AT then
     shift.cooking=nil;shift.burnt+=1
     notify("NASUNOG! Nalimutan mo ang kawali.")
    end
    local order=shift.order
    if order and t>=order.expires then
     shift.missed+=1;shift.order=nil;shift.pending=nil;shift.sauce=nil
     notify("Umalis na ang customer. May next pa.")
     task.delay(1.3,function()
      if shift and shift.phase=="active" and not shift.order then nextOrder() end
     end)
    end
    if t-lastSnapshot>.6 then lastSnapshot=t;sync() end
   end
  end
 end
end)
