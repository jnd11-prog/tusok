from pathlib import Path
from lxml import etree as ET
R=Path(__file__).resolve().parents[1]
path=R/'TUSOK_TAFT_CART_REBUILT.rbxlx'
root=ET.parse(str(path))
counts={cl:len(root.xpath(f'//Item[@class="{cl}"]')) for cl in ['Part','SurfaceGui','ClickDetector','SpawnLocation','Script','ModuleScript','LocalScript']}
assert counts['Part']>=300
assert counts['ClickDetector']==6
assert counts['LocalScript']==1
assert counts['Script']==2
assert counts['ModuleScript']==2
assert root.xpath('//Item[@class="Folder"][Properties/string[@name="Name"]="TaftCart"]')
for parent,cls,name,script_path in [
 ('','ModuleScript','CartConfig','src/ReplicatedStorage/CartConfig.lua'),
 ('','ModuleScript','CartRules','src/ReplicatedStorage/CartRules.lua'),
 ('','Script','CartServer','src/ServerScriptService/CartServer.server.lua'),
 ('','Script','CartSelfTest','src/ServerScriptService/CartSelfTest.server.lua'),
 ('','LocalScript','CartClient','src/StarterPlayer/StarterPlayerScripts/CartClient.client.lua')]:
 sources=root.xpath(f'//Item[@class="{cls}"][Properties/string[@name="Name"]="{name}"]/Properties/ProtectedString[@name="Source"]')
 assert len(sources)==1,name
 assert sources[0].text==(R/script_path).read_text('utf-8'),name
for legacy in ['JobService','RestaurantJobs','TaftShift','TaftClient','Fry_kwek']:
 assert not root.xpath(f'//Item[Properties/string[@name="Name"]="{legacy}"]'),legacy
print('PASS saved place content',counts, 'bytes',path.stat().st_size)
