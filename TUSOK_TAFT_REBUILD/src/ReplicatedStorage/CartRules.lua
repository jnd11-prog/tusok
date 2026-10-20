-- Roblox-independent gameplay rules. All currency uses whole Philippine pesos.
local R={}
function R.quality(elapsed,flipped,good,perfectFrom,perfectTo,burn)
 if type(elapsed)~="number" or elapsed~=elapsed or elapsed<good then return "RAW" end
 if elapsed>=burn then return "BURNT" end
 if flipped and elapsed>=perfectFrom and elapsed<=perfectTo then return "PERFECT" end
 return "OK"
end
function R.canFlip(elapsed,hasFlipped,min,max)
 return type(elapsed)=="number" and elapsed>=min and elapsed<=max and not hasFlipped
end
function R.countChange(coins)
 if type(coins)~="table" then return nil end
 local total=0
 for denomination,n in pairs(coins) do
  if type(denomination)~="number" or type(n)~="number" or n<0 or n%1~=0 then return nil end
  if denomination~=1 and denomination~=5 and denomination~=10 and denomination~=20 and denomination~=50 then return nil end
  total+=denomination*n
 end
 return total
end
function R.affordableChange(drawer,selected,price,tender)
 if type(drawer)~="table" or type(selected)~="table" then return false,"bad drawer" end
 if type(price)~="number" or type(tender)~="number" or tender<price then return false,"invalid amount" end
 local counted=R.countChange(selected)
 if not counted or counted~=tender-price then return false,"wrong change" end
 for denom,n in pairs(selected) do
  if n>(drawer[denom] or 0) then return false,"not enough coins" end
 end
 return true,"ok"
end
function R.isServeable(order,ready,sauce,coins,drawer,now)
 if not order or order.paid or now>=order.expires then return false,"expired" end
 if (ready[order.food] or 0)<1 then return false,"food not ready" end
 if not sauce then return false,"no sauce" end
 return R.affordableChange(drawer,coins,order.price,order.tender)
end
-- Deduct an exact cash payment from the denomination drawer atomically.
-- This makes expenses and physical barya counts agree; no invisible infinite change.
function R.payFromDrawer(drawer,amount)
 if type(drawer)~="table" or type(amount)~="number" or amount<0 or amount%1~=0 then return nil end
 local denominations={100,50,20,10,5,1}
 local nextDrawer={}
 for k,v in pairs(drawer) do nextDrawer[k]=v end
 local function take(index,left)
  if left==0 then return true end
  if index>#denominations then return false end
  local denom=denominations[index]
  local available=nextDrawer[denom] or 0
  local maximum=math.min(available,math.floor(left/denom))
  for count=maximum,0,-1 do
   nextDrawer[denom]=available-count
   if take(index+1,left-denom*count) then return true end
  end
  nextDrawer[denom]=available
  return false
 end
 if take(1,amount) then return nextDrawer end
 return nil
end
function R.canRestock(stock,cash,cost,qty,maxStock)
 return type(stock)=="number" and stock<maxStock and cash>=cost and qty>0
end
function R.readyToLift(elapsed)
 return type(elapsed)=="number" and elapsed>=0
end
return R
