-- TUSOK! / TAFT CART. All-UI solo vendor controls + 3D clickable food/sauces.
-- Completely new screen architecture: translucent ink panels, analog receipt and oil timing.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Config=require(ReplicatedStorage:WaitForChild("CartConfig"))
local player=Players.LocalPlayer
local signals=ReplicatedStorage:WaitForChild("CartSignals")
local Request=signals:WaitForChild("Request")
local Push=signals:WaitForChild("Push")

-- Values sampled/selected from the actual reference collage, never a neon stock game palette.
local C={
 ink=Color3.fromRGB(26,29,28), steel=Color3.fromRGB(57,65,64),
 concrete=Color3.fromRGB(129,113,89), paper=Color3.fromRGB(216,193,159),
 ivory=Color3.fromRGB(251,237,210), orange=Color3.fromRGB(225,110,39),
 fried=Color3.fromRGB(195,65,21), blue=Color3.fromRGB(39,80,125),
 fadedRed=Color3.fromRGB(146,24,13), green=Color3.fromRGB(51,112,78),
 acid=Color3.fromRGB(199,214,18), white=Color3.fromRGB(250,246,234),
 warm=Color3.fromRGB(178,137,95), fish=Color3.fromRGB(224,200,155),
}
local function add(cls,parent,properties)
 local obj=Instance.new(cls)
 if obj:IsA("GuiObject") and parent and parent:IsA("GuiObject") then
  obj.ZIndex=parent.ZIndex+1
 end
 for k,v in pairs(properties or {}) do obj[k]=v end
 obj.Parent=parent
 return obj
end
local function rounded(obj,r)
 add("UICorner",obj,{CornerRadius=UDim.new(0,r or 10)})
 return obj
end
local function line(obj,color,thickness,alpha)
 add("UIStroke",obj,{Color=color or C.warm,Thickness=thickness or 1,Transparency=alpha or .55})
 return obj
end
local function panel(parent,pos,size,alpha,bg,r,z)
 local obj=add("Frame",parent,{Position=pos,Size=size,BackgroundColor3=bg or C.ink,
  BackgroundTransparency=alpha or 0,BorderSizePixel=0,ZIndex=z or 2})
 rounded(obj,r or 13)
 return obj
end
local function label(parent,str,x,y,w,h,size,color,bold,align)
 return add("TextLabel",parent,{Text=str,Position=UDim2.fromOffset(x,y),Size=UDim2.new(w==0 and 1 or w,(w==0 or w==1) and (-x-12) or 0,0,h),
  BackgroundTransparency=1,TextColor3=color or C.white,
  Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
  TextSize=size or 16,TextWrapped=true,
  TextXAlignment=align or Enum.TextXAlignment.Left,
  TextYAlignment=Enum.TextYAlignment.Center})
end
local function btn(parent,str,pos,size,bg,fg)
 local b=add("TextButton",parent,{Text=str,Position=pos,Size=size,
  BackgroundColor3=bg or C.steel,TextColor3=fg or C.white,
  Font=Enum.Font.GothamBold,TextSize=14,TextWrapped=true,
  AutoButtonColor=true,BorderSizePixel=0})
 rounded(b,9)
 return b
end
local function send(action,additional)
 local d=additional or {}
 d.action=action
 Request:FireServer(d)
end
local ui=add("ScreenGui",player:WaitForChild("PlayerGui"),{
 Name="TUSOK_TAFT_REBUILT_UI",IgnoreGuiInset=true,ResetOnSpawn=false,
 DisplayOrder=55,ZIndexBehavior=Enum.ZIndexBehavior.Global})
local root=add("Frame",ui,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
local scale=add("UIScale",root,{Scale=1})

-- GROUND-LEVEL CAMERA: a compact cart in foreground, Taft traffic and students beyond.
-- This isn't a fake background image: it is the real saved editable Workspace.
local camera=workspace.CurrentCamera
local function setCamera()
 camera=workspace.CurrentCamera
 if not camera then return end
 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=64
 camera.CFrame=CFrame.lookAt(Vector3.new(0,7.25,-17.4),Vector3.new(0,3.25,2.8))
end
setCamera()

local brand=panel(root,UDim2.fromOffset(20,16),UDim2.fromOffset(267,112),.13,C.ink,11,3)
local orangeStripe=panel(brand,UDim2.fromOffset(12,13),UDim2.fromOffset(6,77),0,C.orange,2,5)
label(brand,"TUSOK!",31,10,1,52,42,C.orange,true)
label(brand,"TAFT / ONE-MAN SHIFT",32,62,1,21,12,C.ivory,true)
label(brand,"ate bebang's cart · vito cruz side",32,83,1,18,11,C.paper)
local topBar=panel(root,UDim2.new(1,-266,0,17),UDim2.fromOffset(246,66),.18,C.ink,12,3)
label(topBar,"DAY 01    ·    DLSU TAFT",15,8,1,18,11,C.paper,true)
local currentTime=label(topBar,"5:17 PM",15,24,1,34,23,C.ivory,true)

local ticket=panel(root,UDim2.fromOffset(20,143),UDim2.fromOffset(302,271),.15,C.ink,13,3)
line(ticket,C.warm,1,.72)
label(ticket,"●  CURRENT ORDER",16,8,1,24,12,C.ivory,true)
local ticketNumber=label(ticket,"#001",230,8,0,25,12,C.paper,true,Enum.TextXAlignment.Right)
local ticketDivider=add("Frame",ticket,{Position=UDim2.fromOffset(15,39),Size=UDim2.new(1,-30,0,1),BackgroundColor3=C.warm,BackgroundTransparency=.72})
local customerLabel=label(ticket,"WAITING...",16,46,1,29,18,C.ivory,true)
local quoteLabel=label(ticket,"'Ate, bukas na ba?'",16,78,1,64,13,C.paper,false)
local dishLabel=label(ticket,"KWEK-KWEK  ·  2 PCS",16,144,1,31,18,C.orange,true)
local sauceLabel=label(ticket,"SAWSAWAN  ·  SUKA",16,181,1,23,12,C.ivory,true)
local patienceLabel=label(ticket,"PATIENCE",16,217,1,18,10,C.paper,true)
local patienceBack=panel(ticket,UDim2.fromOffset(16,246),UDim2.new(1,-32,0,8),0,C.steel,4,6)
local patienceFill=panel(patienceBack,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),0,C.green,4,7)

local inventory=panel(root,UDim2.new(1,-296,0,99),UDim2.fromOffset(276,273),.12,C.ink,13,3)
line(inventory,C.warm,1,.7)
label(inventory,"TRAY  /  STOCK",15,8,1,27,14,C.ivory,true)
local invRows={}
local foodKeys={"kwek","fishball","kikiam"}
local foodColors={kwek=C.orange,fishball=C.fish,kikiam=C.warm}
for i,food in ipairs(foodKeys) do
 local y=41+(i-1)*72
 local frame=panel(inventory,UDim2.fromOffset(10,y),UDim2.new(1,-20,0,65),.65,C.steel,7,4)
 local icon=panel(frame,UDim2.fromOffset(10,15),UDim2.fromOffset(27,27),0,foodColors[food],14,5)
 local name=label(frame,Config.FOOD[food].label,48,5,1,20,12,C.ivory,true)
 local counts=label(frame,"raw 0 / ready 0",48,26,1,20,11,C.paper)
 local buy=btn(frame,"+ ₱28",UDim2.new(1,-74,0,15),UDim2.fromOffset(65,34),C.blue,C.white)
 buy.MouseButton1Click:Connect(function()send("Restock",{food=food})end)
 invRows[food]={counts=counts,buy=buy}
end

local cash=panel(root,UDim2.new(1,-296,1,-204),UDim2.fromOffset(276,185),.11,C.ink,13,3)
line(cash,C.warm,1,.72)
label(cash,"KAHON NG BARYA",15,7,1,22,12,C.ivory,true)
local cashTotal=label(cash,"₱278",15,29,1,40,30,C.white,true)
local cashMeta=label(cash,"0 / 8 served    ·    ₱0 sales",15,72,1,25,12,C.paper)
local serveButton=btn(cash,"SERVE / SUKLI   →",UDim2.fromOffset(13,111),UDim2.new(1,-26,0,52),C.green,C.white)
serveButton.TextSize=16
serveButton.MouseButton1Click:Connect(function()send("Serve")end)

local infoBar=panel(root,UDim2.fromOffset(20,431),UDim2.fromOffset(302,79),.2,C.ink,12,3)
local narrative=label(infoBar,"5:17  ·  AFTER CLASS",13,7,1,19,12,C.orange,true)
local hint=label(infoBar,"Use the cart below: cook → sauce → serve → count change.",13,28,1,42,12,C.ivory)

-- Bottom control shelf: three food trays, one set of sauce jars, no job menus.
local dock=panel(root,UDim2.new(.5,-445,1,-146),UDim2.fromOffset(890,128),.09,C.ink,13,3)
line(dock,C.warm,1,.65)
label(dock,"01   FRY ONE BATCH",14,6,0,22,11,C.paper,true)
label(dock,"02   CHOOSE SAWSAWAN",454,6,0,22,11,C.paper,true)
local foodButtons={}
for i,food in ipairs(foodKeys) do
 local x=13+(i-1)*145
 local b=btn(dock,Config.FOOD[food].label,UDim2.fromOffset(x,31),UDim2.fromOffset(136,74),C.steel,C.ivory)
 b.TextSize=14
 local dot=panel(b,UDim2.fromOffset(9,11),UDim2.fromOffset(9,9),0,foodColors[food],8,7)
 b.MouseButton1Click:Connect(function()send("StartFry",{food=food})end)
 foodButtons[food]=b
end
local sauceButtons={}
for i,sc in ipairs({"Sweet","Spicy","Vinegar"}) do
 local labelTxt=Config.SAUCE[sc]
 local x=454+(i-1)*140
 local b=btn(dock,labelTxt,UDim2.fromOffset(x,31),UDim2.fromOffset(132,74),sc=="Spicy" and C.fadedRed or (sc=="Vinegar" and C.warm or C.blue),C.white)
 b.MouseButton1Click:Connect(function()send("Sauce",{sauce=sc})end)
 sauceButtons[sc]=b
end
local dockNote=label(dock,"TIP: click trays or sauce jars on the actual cart, too.",15,110,1,14,10,C.paper)

local toast=panel(root,UDim2.new(.5,-236,0,22),UDim2.fromOffset(472,54),.05,C.ink,12,60)
toast.Visible=false
local toastText=label(toast,"",13,7,1,40,15,C.ivory,true,Enum.TextXAlignment.Center)
local toastSeq=0
local function flash(s)
 toastSeq+=1
 local id=toastSeq
 toastText.Text=s or ""
 toast.Visible=true
 task.delay(3,function()if id==toastSeq then toast.Visible=false end end)
end

local overlay=add("Frame",root,{Size=UDim2.fromScale(1,1),BackgroundColor3=C.ink,BackgroundTransparency=.40,Visible=true,ZIndex=15})
local welcome=panel(root,UDim2.fromScale(.5,.5),UDim2.fromOffset(492,409),.01,C.ink,16,18)
welcome.AnchorPoint=Vector2.new(.5,.5);line(welcome,C.warm,1,.25)
local welcomeBand=panel(welcome,UDim2.fromOffset(0,0),UDim2.new(1,0,0,11),0,C.orange,1,19)
local introBadge=label(welcome,"TAFT AVE.  ·  WEDNESDAY  ·  5:17 PM",27,25,1,27,12,C.paper,true)
local welcomeTitle=label(welcome,"IKAW MUNA.",27,65,1,76,44,C.orange,true)
local welcomeText=label(welcome,
 "Ate Bebang went out to buy ice. 'Saglit lang,' she said.\n\nYou've got one fryer, three trays, sticky sauce lids, and a queue of students who all have somewhere to be.\n\nFry. Flip. Lift. Drain. Sauce. Sukli.",
 27,149,1,151,16,C.ivory,false)
local startBtn=btn(welcome,"BUKAS NA   /   START SHIFT   →",UDim2.fromOffset(25,323),UDim2.new(1,-50,0,59),C.green,C.white)
startBtn.TextSize=17
startBtn.MouseButton1Click:Connect(function()send("StartShift")end)

-- COOKING workbench: batch preparation is realistic, not egg-peeling during a rush.
local cook=panel(root,UDim2.new(.5,-298,.5,-173),UDim2.fromOffset(596,346),.045,C.ink,17,24)
cook.Visible=false;line(cook,C.orange,1,.42)
label(cook,"THE ONE FRYER  /  01",19,11,1,21,12,C.paper,true)
local cookTitle=label(cook,"KWEK-KWEK",19,35,1,46,27,C.ivory,true)
local cookExplain=label(cook,"Prepared stock. Drop the batch into hot oil.",19,83,1,53,14,C.paper)
local oilBackdrop=panel(cook,UDim2.fromOffset(18,154),UDim2.new(1,-36,0,53),.0,C.steel,11,26)
local oilProgress=panel(oilBackdrop,UDim2.fromOffset(0,0),UDim2.fromScale(0,1),0,C.orange,10,27)
local timerLabel=label(oilBackdrop,"OIL  /  0.0s",14,5,1,42,18,C.white,true)
local flipBtn=btn(cook,"FLIP / BALIKTAD",UDim2.fromOffset(17,227),UDim2.fromOffset(177,70),C.blue,C.white)
local cookMain=btn(cook,"DROP IN OIL",UDim2.fromOffset(207,227),UDim2.fromOffset(369,70),C.orange,C.white)
cookMain.TextSize=19
local cookHint=label(cook,"Ideal: flip after 1.5s, lift between 4.8–6.9s.",20,301,1,33,12,C.paper)
local cookStage="";local cookSession=nil;local cookClock=0
flipBtn.MouseButton1Click:Connect(function()
 if cookSession then send("Flip",{session=cookSession}) end
end)
cookMain.MouseButton1Click:Connect(function()
 if not cookSession then return end
 if cookStage=="READY" then send("Drop",{session=cookSession})
 elseif cookStage=="FRYING" then send("Lift",{session=cookSession})
 elseif cookStage=="DRAIN" then send("Drain",{session=cookSession}) end
end)

local payment=panel(root,UDim2.fromScale(.5,.5),UDim2.fromOffset(523,474),.02,C.ink,16,30)
payment.AnchorPoint=Vector2.new(.5,.5)
payment.Visible=false;line(payment,C.warm,1,.3)
local payHead=label(payment,"RESIBO / PANUKLI",22,14,1,28,15,C.paper,true)
local priceText=label(payment,"TOTAL   ₱25",22,56,1,43,27,C.ivory,true)
local paidText=label(payment,"BAYAD   ₱50",22,101,1,36,19,C.paper,true)
local dueText=label(payment,"SUKLI   ₱25",22,151,1,40,25,C.orange,true)
local countText=label(payment,"NAIBILANG  ₱0",22,208,1,29,17,C.ivory,true)
local state
local coinsPicked={}
local paymentId=nil
local coinButtons={}
for i,denom in ipairs(Config.DENOMINATIONS) do
 local b=btn(payment,"₱"..denom,UDim2.fromOffset(18+(i-1)*99,255),UDim2.fromOffset(93,62),i==4 and C.blue or C.steel,C.white)
 b.TextSize=17
 b.MouseButton1Click:Connect(function()
  if not paymentId then return end
  local available=(state and state.coins and state.coins[tostring(denom)]) or 0
  if (coinsPicked[denom] or 0)>=available then flash("Wala nang ₱"..denom.." sa kaha.");return end
  coinsPicked[denom]=(coinsPicked[denom] or 0)+1
  local total=0
  for d,n in pairs(coinsPicked) do
   total+=d*n
  end
  countText.Text="NAIBILANG  ₱"..total
 end)
 coinButtons[i]=b
end
local resetChange=btn(payment,"ULIT / RESET",UDim2.fromOffset(19,341),UDim2.fromOffset(160,58),C.fadedRed,C.white)
resetChange.MouseButton1Click:Connect(function()
 coinsPicked={};countText.Text="NAIBILANG  ₱0"
end)
local settleBtn=btn(payment,"IBIGAY ANG SUKLI   →",UDim2.fromOffset(189,341),UDim2.fromOffset(315,58),C.green,C.white)
settleBtn.TextSize=17
settleBtn.MouseButton1Click:Connect(function()
 if paymentId then
  local asList={}
  for i,denom in ipairs(Config.DENOMINATIONS) do
   asList[i]=coinsPicked[denom] or 0
  end
  send("Settle",{orderId=paymentId,coins=asList})
 end
end)
local returnButton=btn(payment,"BACK TO STALL",UDim2.fromOffset(18,420),UDim2.fromOffset(487,36),C.steel,C.paper)
returnButton.MouseButton1Click:Connect(function()payment.Visible=false;overlay.Visible=false end)

state={phase="idle",stock={kwek=5,fishball=6,kikiam=5},prepared={kwek=0,fishball=0,kikiam=0},coins={}}
local fryLastServer=0;local orderLastServer=0;local shiftLastServer=0
local lastOrderId=nil
local function showState(d)
 state=d
 local phase=d.phase or "idle"
 if phase=="idle" or phase=="spectator" or phase=="ended" then
  overlay.Visible=true;welcome.Visible=true;cook.Visible=false;payment.Visible=false
  if phase=="idle" then
   welcomeTitle.Text="IKAW MUNA."
   welcomeText.Text="Ate Bebang went out to buy ice. 'Saglit lang,' she said.\n\nYou've got one fryer, three trays, sticky sauce lids, and a queue of students who all have somewhere to be.\n\nFry. Flip. Lift. Drain. Sauce. Sukli."
   startBtn.Visible=true;startBtn.Text="BUKAS NA   /   START SHIFT   →"
  elseif phase=="spectator" then
   welcomeTitle.Text="PUNO ANG KART."
   welcomeText.Text="One vendor per server. Start a private server to operate your own cart."
   startBtn.Visible=false
  else
   welcomeTitle.Text="SARADO NA."
   welcomeText.Text=string.format("Orders served: %d / 8   ·   Walkouts: %d   ·   Burnt: %d\n\nSales ₱%d   +   tips ₱%d\nSupplies ₱%d\nNet sales after supplies ₱%d\n\nAte Bebang came back with ice. Of course.",
    d.served or 0,d.missed or 0,d.burnt or 0,d.sales or 0,d.tips or 0,d.spent or 0,
    (d.sales or 0)+(d.tips or 0)-(d.spent or 0))
   startBtn.Visible=true;startBtn.Text="ISA PANG SHIFT   →"
  end
 else
  welcome.Visible=false
  if not payment.Visible then overlay.Visible=false end
 end
 cashTotal.Text="₱"..tostring(d.cash or 278)
 cashMeta.Text=string.format("%d / 8 served     ·     ₱%d sales",d.served or 0,d.sales or 0)
 for _,food in ipairs(foodKeys) do
  local stock=(d.stock and d.stock[food]) or 0
  local ready=(d.prepared and d.prepared[food]) or 0
  invRows[food].counts.Text="raw "..stock.."   /   ready "..ready
  foodButtons[food].BackgroundColor3=stock==0 and C.fadedRed or C.steel
 end
 for i,denom in ipairs(Config.DENOMINATIONS) do
  coinButtons[i].Text="₱"..denom.."\n"..tostring((d.coins and d.coins[tostring(denom)]) or 0).." left"
 end
 for k,b in pairs(sauceButtons) do
  b.Text=Config.SAUCE[k]..(d.sauce==k and "  ✓" or "")
  b.BackgroundTransparency=d.sauce==k and 0 or .15
 end
 local o=d.order
 if o then
  ticketNumber.Text="#"..string.format("%03d",o.number)
  customerLabel.Text=o.name:upper().."  /  ₱"..o.price
  quoteLabel.Text='“'..o.line..'”'
  dishLabel.Text=Config.FOOD[o.food].label.."  ·  "..Config.FOOD[o.food].menu
  sauceLabel.Text="SAWSAWAN  ·  "..Config.SAUCE[o.sauce]
  if lastOrderId~=o.id then lastOrderId=o.id end
  orderLastServer=os.clock()+(o.remaining or 0)
  patienceFill.Size=UDim2.fromScale(math.clamp((o.remaining or 0)/(o.duration or 90),0,1),1)
 else
  ticketNumber.Text="—";customerLabel.Text="NO CUSTOMER"
  quoteLabel.Text="Next order is on the way..."
  dishLabel.Text="—";sauceLabel.Text="SAWSAWAN  ·  —"
  orderLastServer=0
 end
 shiftLastServer=os.clock()+(d.shiftLeft or Config.SHIFT_SECONDS)
 local c=d.cooking
 if c then
  cook.Visible=true
  overlay.Visible=true
  if cookSession~=c.session or cookStage~=c.stage then
   cookSession=c.session;cookStage=c.stage
  end
  if c.stage=="FRYING" then fryLastServer=os.clock()-(c.elapsed or 0) end
  cookTitle.Text=Config.FOOD[c.food].label
  if c.stage=="READY" then
   cookExplain.Text="Prepared portions are ready. Lower this batch into the hot oil."
   cookMain.Text="DROP IN OIL  ↓";cookMain.BackgroundColor3=C.orange
   flipBtn.Visible=false
   cookHint.Text="Real stalls prep food ahead. No egg-peeling between customers."
  elseif c.stage=="FRYING" then
   cookExplain.Text=c.flipped and "Flipped! Lift when the oil timer is in the green zone." or
    "One flip after 1.5s. Lift around 5–7s. Don't let it burn."
   cookMain.Text="LIFT / SALUKIN  ↑";cookMain.BackgroundColor3=C.orange
   flipBtn.Visible=not c.flipped
   cookHint.Text="GREEN = best lift window  /  RED = burnt after 9s."
  else
   cookExplain.Text="Patuluin muna ang mantika. Tap twice to drain the batch."
   cookMain.Text="DRAIN / PATULUIN   "..tostring(c.drained or 0).." / 2"
   cookMain.BackgroundColor3=C.green;flipBtn.Visible=false
   oilProgress.Size=UDim2.fromScale((c.drained or 0)/2,1)
   timerLabel.Text="DRAIN THE OIL"
  end
 else
  cook.Visible=false;cookSession=nil;cookStage=""
  if phase=="active" and not payment.Visible then overlay.Visible=false end
 end
 if phase=="active" then
  narrative.Text=(d.count or 0)>=5 and "RUSH HOUR  ·  TAFT" or "AFTER CLASS  ·  TAFT"
  hint.Text=c and "Bantayan ang kawali. Hindi pwedeng iwanan." or
   "1 fryer → 1 batch → sauce → serve → exact change."
 end
 if paymentId and (not o or o.id~=paymentId) then
  payment.Visible=false;paymentId=nil;coinsPicked={}
  if not cook.Visible then overlay.Visible=false end
 end
end
Push.OnClientEvent:Connect(function(m)
 if type(m)~="table" then return end
 if m.kind=="Toast" then flash(m.text or "")
 elseif m.kind=="State" and type(m.data)=="table" then showState(m.data)
 elseif m.kind=="Payment" then
  paymentId=m.orderId;coinsPicked={}
  payment.Visible=true;overlay.Visible=true
  priceText.Text="TOTAL    ₱"..m.price
  paidText.Text="BAYAD    ₱"..m.tender
  dueText.Text="SUKLI    ₱"..m.due
  countText.Text="NAIBILANG  ₱0"
 end
end)
RunService.RenderStepped:Connect(function()
 if workspace.CurrentCamera and workspace.CurrentCamera.CameraType~=Enum.CameraType.Scriptable then setCamera() end
 if state.phase~="active" then return end
 local remain=math.max(0,shiftLastServer-os.clock())
 local elapsed=Config.SHIFT_SECONDS-remain
 local hour=17;local minute=17+math.floor(elapsed/29)
 if minute>=60 then
  hour+=math.floor(minute/60)
  minute=minute%60
 end
 currentTime.Text=string.format("%d:%02d PM",hour>12 and hour-12 or hour,minute)
 if state.order and orderLastServer>0 then
  local patient=math.max(0,orderLastServer-os.clock())
  patienceFill.Size=UDim2.fromScale(math.clamp(patient/(state.order.duration or 90),0,1),1)
  patienceFill.BackgroundColor3=patient<22 and C.fadedRed or (patient<45 and C.orange or C.green)
  patienceLabel.Text="PATIENCE  ·  "..math.floor(patient).."s"
 end
 local c=state.cooking
 if c and c.stage=="FRYING" then
  local t=math.max(0,os.clock()-fryLastServer)
  timerLabel.Text=string.format("HOT OIL    %.1fs",t)
  oilProgress.Size=UDim2.fromScale(math.clamp(t/Config.FRY_BURN_AT,0,1),1)
  local ideal=t>=Config.FRY_PERFECT_FROM and t<=Config.FRY_PERFECT_TO
  oilProgress.BackgroundColor3=t>=7.5 and C.fadedRed or (ideal and C.green or C.orange)
  cookMain.BackgroundColor3=ideal and C.green or C.orange
 end
end)

-- FIT narrow screens without clipping payment / fry controls; intended best in landscape.
local function resize()
 local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1440,810)
 local factor=math.clamp(math.min(v.X/1300,v.Y/730),.51,1.07)
 scale.Scale=factor
 local W=v.X/factor;local H=v.Y/factor
 root.Size=UDim2.fromOffset(W,H)
 local narrow=W<1120
 if narrow then
  brand.Size=UDim2.fromOffset(215,98)
  ticket.Size=UDim2.fromOffset(247,258)
  ticket.Position=UDim2.fromOffset(12,123)
  infoBar.Visible=false
  inventory.Size=UDim2.fromOffset(220,273)
  inventory.Position=UDim2.new(1,-231,0,99)
  topBar.Position=UDim2.new(1,-231,0,15);topBar.Size=UDim2.fromOffset(220,66)
  cash.Size=UDim2.fromOffset(220,184);cash.Position=UDim2.new(1,-231,1,-204)
  dock.Size=UDim2.fromOffset(890,128)
  dock.Position=UDim2.new(.5,-445,1,-146)
  if W<920 then
   inventory.Visible=false;topBar.Visible=false
   cash.Position=UDim2.new(1,-230,1,-355)
   dock.Position=UDim2.new(.5,-445,1,-145)
  else inventory.Visible=true;topBar.Visible=true end
 else
  brand.Size=UDim2.fromOffset(267,112)
  ticket.Size=UDim2.fromOffset(302,271);ticket.Position=UDim2.fromOffset(20,143)
  infoBar.Visible=true
  inventory.Visible=true;topBar.Visible=true
  inventory.Size=UDim2.fromOffset(276,273);inventory.Position=UDim2.new(1,-296,0,99)
  topBar.Position=UDim2.new(1,-266,0,17);topBar.Size=UDim2.fromOffset(246,66)
  cash.Size=UDim2.fromOffset(276,185);cash.Position=UDim2.new(1,-296,1,-204)
  dock.Position=UDim2.new(.5,-445,1,-146)
 end
 if W<900 then
  local f=math.max(.66,(W-20)/890)
  local dScale=dock:FindFirstChild("ResponsiveScale")
  if not dScale then dScale=Instance.new("UIScale");dScale.Name="ResponsiveScale";dScale.Parent=dock end
  dScale.Scale=f
  dock.Position=UDim2.new(.5,-445*f,1,-146*f)
  local winScale=math.min(1,(W-18)/596)
  local cs=cook:FindFirstChild("ResponsiveScale")
  if not cs then cs=Instance.new("UIScale");cs.Name="ResponsiveScale";cs.Parent=cook end
  cs.Scale=winScale
  local ps=payment:FindFirstChild("ResponsiveScale")
  if not ps then ps=Instance.new("UIScale");ps.Name="ResponsiveScale";ps.Parent=payment end
  ps.Scale=math.min(1,(W-20)/523)
 else
  local dScale=dock:FindFirstChild("ResponsiveScale")
  if dScale then dScale.Scale=1 end
  local cs=cook:FindFirstChild("ResponsiveScale")
  if cs then cs.Scale=1 end
  local ps=payment:FindFirstChild("ResponsiveScale")
  if ps then ps.Scale=1 end
 end
 local ws=welcome:FindFirstChild("ResponsiveScale")
 if not ws then ws=Instance.new("UIScale");ws.Name="ResponsiveScale";ws.Parent=welcome end
 ws.Scale=math.min(1,(W-25)/492)
end
resize()
if workspace.CurrentCamera then
 workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
send("Sync")
