"""TUSOK! TAFT CART: v1 from moodboard, one compact photoreal-inspired workbench.
Original geometry, no Marketplace asset dependencies. To rebuild: python build_place.py
This saves actual Parts / signs / prompts into Workspace; NEVER generates the map at runtime.
"""
from pathlib import Path
from lxml import etree as ET
from math import sin,cos,pi,sqrt
import random
R=Path(__file__).parent
OUT=R/'TUSOK_TAFT_CART_REBUILT.rbxlx'
root=ET.Element('roblox',{'version':'4'},nsmap={'xmime':'http://www.w3.org/2005/05/xmlmime'})
ET.SubElement(root,'External').text='null'
ET.SubElement(root,'External').text='nil'
index=0
registry=[]
def item(parent,cls,name):
    global index
    index+=1
    el=ET.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{index:08d}'})
    props=ET.SubElement(el,'Properties')
    prop(props,'string','Name',name)
    registry.append((cls,name))
    return el

def prop(parent,tag,name,val):
    p=ET.SubElement(parent,tag,{'name':name})
    p.text=str(val)
    return p

def v3(parent,name,xyz):
    p=ET.SubElement(parent,'Vector3',{'name':name})
    for dim,val in zip('XYZ',xyz): ET.SubElement(p,dim).text=str(round(val,5))
    return p

def col(parent,name,c):
    p=ET.SubElement(parent,'Color3',{'name':name})
    for dim,val in zip('RGB',c):ET.SubElement(p,dim).text=str(round(val/255,8))
    return p

def cf(parent,xyz,rot=None):
    p=ET.SubElement(parent,'CoordinateFrame',{'name':'CFrame'})
    for dim,val in zip('XYZ',xyz):ET.SubElement(p,dim).text=str(round(val,6))
    rot=rot or [1,0,0,0,1,0,0,0,1]
    for i,val in enumerate(rot):ET.SubElement(p,f'R{i//3}{i%3}').text=str(round(val,7))
    return p

def ud2(parent,name,a,b,c,d):
    p=ET.SubElement(parent,'UDim2',{'name':name})
    for tag,v in [('XS',a),('XO',b),('YS',c),('YO',d)]: ET.SubElement(p,tag).text=str(v)
    return p

M={'SmoothPlastic':272,'Plastic':256,'Neon':288,'Wood':512,'WoodPlanks':528,
   'Concrete':816,'Pavement':836,'Brick':848,'Metal':1088,'Asphalt':1376,
   'Glass':1568,'Fabric':1312,'Grass':1280,'CorrodedMetal':1040}
P={
'ink':(31,35,33),'shadow':(46,41,38),'deepgreen':(38,75,57),'teal':(45,92,81),
'mint':(104,141,109),'red':(146,24,13),'rust':(195,65,21),'orange':(225,110,39),
'yellow':(199,214,18),'butter':(243,193,86),'cream':(216,193,159),'white':(244,229,199),
'concrete':(177,160,129),'road':(71,69,65),'metal':(129,136,133),'silver':(204,205,198),
'wood':(95,73,45),'woodlight':(178,137,95),'green':(48,103,65),'blue':(39,80,125),
'brown':(95,73,45),'black':(28,30,30),'skin':(178,137,95),'pink':(193,122,101),
'fish':(225,204,164),'steel':(96,114,119),'cardboard':(174,141,91),
}

def color(x):return P[x] if isinstance(x,str) else x
ws=item(root,'Workspace','Workspace')
# Saved editor camera, aimed at the street cart rather than the default empty sky.
cam=item(ws,'Camera','Camera')
cp=cam.find('Properties')
# lookAt(11,18,48) -> (0,5,-8)
x,y,z=(0,15,-28);target=(0,3.8,2)
a=[x-target[0],y-target[1],z-target[2]]
m=(sum(i*i for i in a))**.5; back=[i/m for i in a]
right=[back[2],0,-back[0]];m=(sum(i*i for i in right))**.5;right=[i/m for i in right]
up=[back[1]*right[2]-back[2]*right[1],back[2]*right[0]-back[0]*right[2],back[0]*right[1]-back[1]*right[0]]
cf(cp,(x,y,z),[right[0],up[0],back[0],right[1],up[1],back[1],right[2],up[2],back[2]])
prop(cp,'token','CameraType',0)
pr=ws.find('Properties')
prop(pr,'Ref','CurrentCamera',cam.get('referent'))
prop(pr,'bool','StreamingEnabled','false')
lighting=item(root,'Lighting','Lighting')
prl=lighting.find('Properties')
prop(prl,'float','ClockTime',17.32)
prop(prl,'float','Brightness',2.75)
col(prl,'Ambient',(122,115,104));col(prl,'OutdoorAmbient',(146,131,108))
col(prl,'FogColor',(215,179,145));prop(prl,'float','FogEnd',185)
prop(prl,'bool','GlobalShadows','true')
a=item(lighting,'Atmosphere','Evening haze')
ap=a.find('Properties');col(ap,'Color',(235,197,170));col(ap,'Decay',(111,128,129))
prop(ap,'float','Density',.25);prop(ap,'float','Haze',1.45);prop(ap,'float','Glare',.07)

world=item(ws,'Folder','TaftCart')
scenery=item(world,'Folder','Scene')
interactives=item(world,'Folder','Hotspots')
customers=item(world,'Folder','Pedestrians')

def folder(name,parent=scenery):return item(parent,'Folder',name)
floor=folder('00 / Taft asphalt and footpaths')
buildings=folder('01 / Printshops, dorms and campus')
stall=folder('02 / Ate Bebang solo cart')
props=folder('03 / Merienda micro-details')
bodega=folder('04 / Supply crates')
vehicles=folder('05 / LRT and jeepney')
letters=folder('06 / Hand-painted signage')
lightingbits=folder('07 / Street light fixtures')

PART_COUNTER=0

def part(parent,name,size,xyz,palette,mat='SmoothPlastic',shape='Block',collide=False,trans=0,rot=None):
    global PART_COUNTER
    PART_COUNTER+=1
    if shape=='Cylinder' and rot is None:
        size=(size[1],size[0],size[2])
        rot=[0,-1,0,1,0,0,0,0,1]
    elif shape=='Wheel':
        # Cylinder's native axis is X, rotating it to Z for a vehicle wheel.
        size=(size[2],size[0],size[1])
        rot=[0,0,-1,0,1,0,1,0,0]
        shape='Cylinder'
    el=item(parent,'Part',name)
    pr=el.find('Properties')
    prop(pr,'bool','Anchored','true');prop(pr,'bool','CanCollide',str(collide).lower())
    prop(pr,'bool','CanTouch','false')
    prop(pr,'float','Transparency',trans)
    col(pr,'Color',color(palette));prop(pr,'token','Material',M[mat])
    prop(pr,'token','Shape',{'Ball':0,'Block':1,'Cylinder':2,'Wedge':3}[shape])
    v3(pr,'Size',size);cf(pr,xyz,rot)
    return el

def sign(parent,name,message,size,xyz,bg='ink',fg='cream',px=34):
    face=part(parent,name,size,xyz,bg,'Wood',collide=False)
    sg=item(face,'SurfaceGui','Handpainted letters')
    p=sg.find('Properties');prop(p,'token','Face',5)
    prop(p,'token','SizingMode',1);prop(p,'float','PixelsPerStud',px)
    prop(p,'bool','AlwaysOnTop','false')
    text=item(sg,'TextLabel','Sign text')
    p=text.find('Properties')
    prop(p,'string','Text',message)
    col(p,'TextColor3',color(fg));prop(p,'bool','TextScaled','true')
    prop(p,'bool','TextWrapped','true');prop(p,'float','BackgroundTransparency',1)
    prop(p,'int','BorderSizePixel',0)
    ud2(p,'Size',1,0,1,0)
    return face

def tube(parent,name,a,b,diam,colorname='ink',mat='Metal'):
    direction=[b[i]-a[i] for i in range(3)]
    length=sqrt(sum(n*n for n in direction))
    if length<.0001:return None
    center=[(a[i]+b[i])/2 for i in range(3)]
    ux=[i/length for i in direction]
    cross=[-ux[2],0,ux[0]]
    n=sqrt(sum(x*x for x in cross))
    if n<1e-5: cross=[1,0,0]
    else:cross=[x/n for x in cross]
    z=[cross[1]*ux[2]-cross[2]*ux[1],cross[2]*ux[0]-cross[0]*ux[2],cross[0]*ux[1]-cross[1]*ux[0]]
    return part(parent,name,(diam,length,diam),center,colorname,mat,collide=False,rot=[cross[0],ux[0],z[0],cross[1],ux[1],z[1],cross[2],ux[2],z[2]])

def prompt(station,action='Use',object_text=None):
    node=item(station,'ProximityPrompt','Press E')
    pp=node.find('Properties')
    prop(pp,'string','ObjectText',object_text or station.find('Properties/string[@name="Name"]').text)
    prop(pp,'string','ActionText',action)
    prop(pp,'float','HoldDuration',.12)
    prop(pp,'float','MaxActivationDistance',10)
    prop(pp,'bool','RequiresLineOfSight','false')
    return node

def hotspot(name,title,pos,action):
    p=part(interactives,name,(3.8,1.1,2),pos,'butter',trans=1)
    prompt(p,action,title)
    return p

# --------------------------------------------------------
# ONE SMALL VENDOR CART. Moodboard colors: oxide red, kwek orange,
# faded steel, blue plastic, shadow brown, roadside avocado green.
# Saved primitive geometry: every piece remains editable in Roblox Studio.
# --------------------------------------------------------
random.seed(517)
street=folder('01 / Taft curb and sidewalk')
shops=folder('02 / lived-in neighborhood')
cart=folder('03 / Ate Bebang one cart')
foodmodels=folder('04 / food and utensils')
letters=folder('05 / signage and notes')
vehicles=folder('06 / LRT and traffic')
people=folder('07 / commuters and customers')
lights=folder('08 / golden hour lighting')

part(street,'Uneven asphalt',(126,1,115),(0,-1.05,17),'road','Asphalt',collide=True)
part(street,'Food vendor concrete pavement',(126,.58,45),(0,-.39,-22),'concrete','Concrete',collide=True)
part(street,'Dirty yellow road curb',(126,.38,.8),(0,.1,1.8),'yellow','Concrete',collide=True)
for i in range(11):
 x=-62+i*12
 part(street,'Paving expansion line',(.09,.04,42),(x,-.05,-22),'shadow',trans=.75)
 if i%2==0:
  part(street,'Gutter metal grate',(3,.07,1.2),(x,.1,2.0),'shadow','Metal')
  for n in range(6):part(street,'Grate slots',(.28,.08,.9),(x-1.1+n*.44,.13,2),'metal','Metal')
for z in (12,32):
 for i in range(8):
  part(street,'Aged road lane marker',(6,.03,.4),(-50+i*14,-.53,z),'cream','Pavement',trans=.25)
for i in range(15):
 x=random.uniform(-60,60);z=random.uniform(7,48)
 part(street,'Road dust fleck',(.22,.03,.1),(x,-.51,z),'black',trans=.85)

# Functional cart is just 12.8 studs across and 5 studs deep, not a restaurant.
part(cart,'Cart lower body',(12.8,2.6,5.2),(0,1.51,0),'steel','CorrodedMetal',collide=True)
part(cart,'Steel counter surface',(13.2,.26,5.7),(0,2.88,0),'silver','Metal',collide=True)
part(cart,'Undershelf blue rag',(5,.08,2.7),(0,1.08,-2),'blue','Fabric')
part(cart,'Front scratched skirting',(12.9,1.3,.16),(0,1.53,2.63),'metal','CorrodedMetal')
for x in (-5.7,5.7):
 for z in (-2.05,2.05):
  part(cart,'Cart rubber wheel',(1.55,1.55,.6),(x,.67,z),'black','Metal','Wheel',collide=False)
  part(cart,'Axle rivet',(.32,.32,.7),(x,.67,z),'silver','Metal','Cylinder')
for x in (-6.25,6.25):
 for z in (-2.4,2.4):
  tube(cart,'Rusty awning post',(x,2.9,z),(x,8.2,z),.17,'metal')
  part(cart,'Tarp pole clamp',(.29,.4,.28),(x,7.8,z),'shadow','Metal')
part(cart,'Faded tarp canopy',(14.1,.2,8),(0,8.35,-.1),'red','Fabric')
for j in range(7):
 x=-6+j*2.0
 part(cart,'Scuffed uneven awning stripe',(1.8,.04,7.7),(x,8.48,-.1),
  'red' if j%2 else 'green','Fabric',trans=.15)
part(cart,'Strip hanging towards sidewalk',(14,.98,.16),(0,7.8,3.8),'red','Fabric',trans=.17)
# Functional compact tabletop: large fryer left, colorful open food rack center,
# condiment cluster right; all within touching distance of one seated vendor.
part(cart,'One propane cooker',(4.5,1,.3),( -3.1,3.32,-1.15),'shadow','Metal')
part(cart,'Single wok dark pan',(4.45,.52,4.45),(-3.1,3.93,-1.15),'black','Metal','Cylinder')
part(cart,'Frying oil mirror',(4.08,.1,4.08),(-3.1,4.24,-1.15),(118,87,47),'Glass','Cylinder',trans=.26)
part(cart,'Steam amber edge',(4.1,.09,4.1),(-3.1,4.33,-1.15),'orange','Glass','Cylinder',trans=.79)
for j in range(11):
 theta=2*pi*j/11
 xx=-3.1+1.35*cos(theta);zz=-1.15+1.35*sin(theta)
 part(cart,'Oil bubble',(.18+.1*(j%3),.12,.19),(xx,4.43,zz),'butter','Glass','Ball',trans=.27)
# Heat source visible in underside
part(cart,'Fire ring beneath wok',(3.3,.13,3.3),(-3.1,3.55,-1.1),'orange','Neon','Cylinder',trans=.4)
tube(cart,'Wok handle',(-1.0,4.15,-1.35),(1.2,4.15,-1.1),.26,'black')
# Tray shelf & three individual food sets, fine skewers in realistic tight arrangement.
part(foodmodels,'Perforated cooked food display',(6.75,.26,3.8),(1.9,3.05,1.0),'metal','Metal')
for j,(x,foodtype,shade) in enumerate([(-.3,'KWEK','orange'),(1.7,'FISH','fish'),(3.65,'KIKIAM','woodlight')]):
 part(foodmodels,foodtype+' wire basket',(1.92,.19,3.35),(x,3.24,1.0),'silver','Metal')
 for k in range(4):
  part(foodmodels,foodtype+' basket spoke',(1.8,.06,.07),(x,3.36,-.42+k*.92),'black','Metal',trans=.55)
 for stick in range(3):
  sx=x-.53+stick*.47
  tube(foodmodels,'Bamboo tusok',(sx,3.48,-.58),(sx,3.73,2.55),.068,'woodlight','Wood')
  for b in range(2):
   zz=.18+b*1.0
   if foodtype=='KIKIAM':
    part(foodmodels,'Golden irregular kikiam',( .57,.48,.82),(sx,3.78,zz),shade,'SmoothPlastic')
    part(foodmodels,'Kikiam browned edge',(.13,.47,.73),(sx+.29,3.79,zz),'brown','SmoothPlastic',trans=.16)
   else:
    part(foodmodels,foodtype+' ready food',(.64,.63,.68),(sx,3.83,zz),shade,'SmoothPlastic','Ball')
    if foodtype=='KWEK':
     part(foodmodels,'Crispy uneven batter',(.3,.22,.26),(sx+.19,4.09,zz),'rust','SmoothPlastic','Ball',trans=.18)
# Sauce lids: highly legible and physically clickable from cart view.
part(cart,'Sauce plastic counter shelf',(3.4,.19,3.4),(5.05,3.11,-.55),'blue','Plastic')
for j,(name,clr) in enumerate([('Sweet','wood'),('Spicy','rust'),('Vinegar','fish')]):
 x=4.02+j*1.08
 jar=part(foodmodels,name+' acrylic sauce bottle',(.86,1.35,.86),(x,3.91,-.55),clr,'Glass','Cylinder',trans=.19)
 part(foodmodels,name+' blue bottle lid',(1,.18,1),(x,4.67,-.55),('red' if j==1 else 'blue'),'Plastic','Cylinder')
 tube(foodmodels,name+' sauce ladle',(x,4.4,-.5),(x+.25,5.07,-.4),.085,'silver')
# Order change box, worn plastic fishball cup, receipt pad, tissue dispenser
part(foodmodels,'Blue cash tub',(2.2,.35,1.4),(4.9,3.24,1.56),'blue','Plastic')
for i in range(6):
 x=4.18+(i%3)*.53;z=1.33+(i//3)*.46
 part(foodmodels,'Barya coin',(.35,.065,.35),(x,3.46,z),'silver' if i%3 else 'yellow','Metal','Cylinder')
part(foodmodels,'Scribbled receipt book',(1.4,.17,.88),(3.0,3.29,-2.15),'cream','Fabric')
part(foodmodels,'Ballpen',(.14,.14,1.1),(4.0,3.4,-1.93),'blue','Plastic')
part(foodmodels,'Disposable cup stack',(1.05,1.8,1.05),(5.55,4.02,-1.76),'cream','Glass','Cylinder',trans=.5)
for k in range(4):
 tube(foodmodels,'Unused bamboo sticks',(5.55+k*.13,3.45,-2.12),(5.58+k*.13,5.33,-1.9),.042,'woodlight','Wood')
# A real propane bottle and old hose (all within cart footprint).
part(cart,'Blue small propane can',(1.7,2.8,1.7),(-4.3,1.2,-.7),'blue','Metal','Cylinder')
tube(cart,'Dark gas hose',(-4.15,2.57,-.5),(-3.5,3.4,-1.0),.12,'black')
part(cart,'Vendor faded towel',(1.3,.1,2.2),(-6.05,2.95,-1.0),'cream','Fabric',trans=.1)
# 3D click regions are visible food labels / sauce jars, rather than giant invisible touch blockers.
def clickTarget(name,parent,nameLabel,xyz,shade):
 p=part(interactives,name,(1.5,.45,.75),xyz,shade,'SmoothPlastic',trans=.52)
 detector=item(p,'ClickDetector','Click here')
 prop(detector.find('Properties'),'float','MaxActivationDistance',80)
 sign(letters,'Label '+name,nameLabel,(1.85,.72,.11),(xyz[0],xyz[1]-.08,xyz[2]-.42),'ink','cream',px=54)
 return p
clickTarget('Kwek',interactives,'KWEK',(-.3,4.49,1.25),'orange')
clickTarget('Fish',interactives,'FISH',(1.67,4.49,1.25),'fish')
clickTarget('Kikiam',interactives,'KIKIAM',(3.62,4.49,1.25),'woodlight')
for name,x in [('Sweet',4.02),('Spicy',5.10),('Vinegar',6.18)]:
 p=part(interactives,name,(.9,1.2,.9),(x,4.0,-.53),'cream',trans=1)
 det=item(p,'ClickDetector','Click sauce bottle')
 prop(det.find('Properties'),'float','MaxActivationDistance',80)
# Signs are hand-authored, readable Roblox text rather than AI-garbled image-text.
sign(letters,'Brand sign','TUSOK!\nATE BEBANG · TAFT',(7.8,2.4,.17),(-1,6.35,3.53),'ink','orange',px=53)
sign(letters,'Faded daily price list','KWEK  25  /  FISHBALL  18\nKIKIAM  22   •   TUSOK MO NA',(4.6,1.65,.16),(4.48,6.37,3.5),'cream','shadow',px=40)
sign(letters,'Sukli warning','BARYA LANG PO!\nWAG MO NA KO I-100',(3.65,1.25,.15),(6.0,5.41,-2.29),'yellow','ink',px=44)
sign(letters,'Sawsawan sticky note','SUKA / TAMIS / MAANGHANG',(5.5,.9,.12),(4.5,5.05,2.15),'ink','cream',px=43)
# Sidewalk adjacent to cart, not a fantasy cityscape. Only enough to frame Taft.
part(shops,'DLSU-adjacent deep green campus fence',(48,9,.7),(-15,4.55,62),'deepgreen','Metal',collide=True)
for i in range(15):
 x=-37+i*3.3
 part(shops,'Green gate slat',(.16,8,.14),(x,5,61.58),'green','Metal')
for y in (2.7,6.8):part(shops,'Gate support horizontal',(48,.19,.2),(-15,y,61.49),'green','Metal')
sign(letters,'Campus edge','TAFT AVE   •   UNIVERSITY BELT',(23,2.0,.25),(-14,10.7,61.1),'deepgreen','cream',px=48)
# Mixed use shop fronts on edge of frame
for j,x in enumerate((-41,-26,28,43)):
 shade=['blue','cream','green','rust'][j]
 part(shops,'Old ground-floor shop',(13,14,8),(x,6.95,58),shade,'Concrete',collide=True)
 part(shops,'Shop shutter',(10,6,.2),(x,3.3,53.85),'steel','CorrodedMetal')
 for k in range(7):part(shops,'Shutter dents',(9,.05,.09),(x,1+k*.77,53.72),'shadow','Metal',trans=.6)
 names=['XEROX & PRINT','PALAMIG • YELO','RUSH BINDING','LOAD / GCASH?']
 sign(letters,'Shop sign '+str(j),names[j],(11,1.7,.3),(x,7.75,53.55),'ink','cream',px=53)
# Elevated LRT reads as background; don't fill the small play space with train props.
for x in (-42,0,42):
 part(vehicles,'LRT concrete pillar',(2.9,17,2.9),(x,8.5,43),'concrete','Concrete',collide=True)
 part(vehicles,'LRT support cap',(10,1.4,4.9),(x,17.3,43),'concrete','Concrete')
for z in (39,47):part(vehicles,'LRT horizontal gantry',(120,1.3,2.9),(0,19.1,z),'metal','Metal')
for i in range(18):part(vehicles,'Rail sleeper',(3.5,.18,10),(-53+i*6.1,20.4,43),'brown','Wood')
part(vehicles,'Short parked jeepney',(18,3.6,6),(25,2.42,17),'silver','Metal',collide=True)
part(vehicles,'Jeepney painted side stripe',(17,.65,6.2),(25,2.7,17),'red','Metal')
part(vehicles,'Jeepney roof',(18,.25,6.5),(25,4.45,17),'cream','Metal')
for x in (19,31):
 for z in (13.6,20.4):part(vehicles,'Rubber jeepney wheel',(2.6,2.6,.75),(x,1.25,z),'black','Metal','Wheel')
sign(letters,'Jeepney route','TAFT - BUENDIA',(11,1.3,.19),(24,3.52,13.72),'blue','cream',px=55)
# Customer silhouettes placed forward of cart, at human scale for camera context.
for idx,(xx,zz,shirt) in enumerate([(0,10,'green'),(8,14,'cream'),(-8,17,'blue'),(14,20,'pink'),(-13,22,'rust')]):
 skin=('skin' if idx%2==0 else 'woodlight')
 part(people,'Student torso',(1.55,2,.88),(xx,3,zz),shirt,'Fabric')
 part(people,'Student head',(1.25,1.25,1.2),(xx,4.68,zz),skin,'SmoothPlastic','Ball')
 part(people,'Dark commuter hair',(1.26,.29,1.18),(xx,5.22,zz),'black','SmoothPlastic')
 for side in (-1,1):
  part(people,'Student trousers',(.55,1.8,.66),(xx+side*.44,1.1,zz),'blue' if idx%2 else 'shadow','Fabric')
  part(people,'Student arm',(.35,1.75,.43),(xx+side*1.00,3,zz),skin,'SmoothPlastic')
 part(people,'Canvas backpack',(1.16,1.48,.47),(xx,2.96,zz+.57),'blue' if idx%2 else 'green','Fabric')
# Five o'clock golden bulbs / electrical cables read authentic, don't overpower.
for x in (-27,18,50):
 part(lights,'Curbside pole',(.55,13,.55),(x,6.5,2.4),'shadow','Metal')
 tube(lights,'Cable span',(x,12.7,2.4),(x+10,11.6,5.3),.06,'black')
for x in (-4,0,4):
 part(lights,'Warm bulb',(.32,.34,.3),(x,7.75,1.8),'butter','Neon','Ball')
 tube(lights,'Bulb cord',(x,8.4,1.8),(x,7.95,1.8),.04,'shadow')

# Player spawns behind the cart; fixed camera frames the small cart for easy clicks.
spawn=item(world,'SpawnLocation','Vendor floor mark')
spr=spawn.find('Properties')
prop(spr,'bool','Anchored','true');prop(spr,'bool','Neutral','true')
prop(spr,'bool','CanCollide','true');prop(spr,'float','Transparency',1)
col(spr,'Color',P['cream']);prop(spr,'token','Material',M['Concrete'])
v3(spr,'Size',(5,.35,4));cf(spr,(0,.0,-9),[1,0,0,0,1,0,0,0,1])

# Structured, fully readable scripts embedded in the standalone .rbxlx.
rep=item(root,'ReplicatedStorage','ReplicatedStorage')
server=item(root,'ServerScriptService','ServerScriptService')
starter=item(root,'StarterPlayer','StarterPlayer')
playerScripts=item(starter,'StarterPlayerScripts','StarterPlayerScripts')
scripts=[
 (rep,'ModuleScript','CartConfig','src/ReplicatedStorage/CartConfig.lua'),
 (rep,'ModuleScript','CartRules','src/ReplicatedStorage/CartRules.lua'),
 (server,'Script','CartServer','src/ServerScriptService/CartServer.server.lua'),
 (server,'Script','CartSelfTest','src/ServerScriptService/CartSelfTest.server.lua'),
 (playerScripts,'LocalScript','CartClient','src/StarterPlayer/StarterPlayerScripts/CartClient.client.lua')]
for owner,cls,name,path in scripts:
 obj=item(owner,cls,name)
 source=ET.SubElement(obj.find('Properties'),'ProtectedString',{'name':'Source'})
 source.text=ET.CDATA((R/path).read_text(encoding='utf-8'))
ET.ElementTree(root).write(str(OUT),encoding='utf-8',xml_declaration=True,pretty_print=True)
verify=ET.parse(str(OUT))
assert len(verify.xpath('//Item[@class="ClickDetector"]'))==6
assert len(verify.xpath('//Item[@class="SpawnLocation"]'))==1
assert len(verify.xpath('//Item[@class="Part"]'))>=170
assert len(verify.xpath('//Item[@class="LocalScript"]'))==1
for _,cls,name,path in scripts:
 assert verify.xpath(f'//Item[@class="{cls}"][Properties/string[@name="Name"]="{name}"]/Properties/ProtectedString[@name="Source"]')[0].text==(R/path).read_text('utf-8')
print('TUSOK CART place:',OUT,'parts',PART_COUNTER,'signs',len(verify.xpath('//Item[@class="SurfaceGui"]')),'clickable',6,'embedded scripts',len(scripts))
