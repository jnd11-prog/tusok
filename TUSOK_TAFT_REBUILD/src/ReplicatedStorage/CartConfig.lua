-- TUSOK! / TAFT CART. Balancing values for a deliberately compact one-vendor shift.
local Config = {}
Config.ORDERS_PER_SHIFT = 8
Config.SHIFT_SECONDS = 510
Config.INITIAL_CASH = 278
Config.STARTING_STOCK = {kwek=5,fishball=6,kikiam=5}
Config.RESTOCK_QUANTITY = 3
Config.RESTOCK_COST = 28
Config.MAX_STOCK = 10
Config.FRY_GOOD_FROM = 4.0
Config.FRY_PERFECT_FROM = 4.8
Config.FRY_PERFECT_TO = 6.9
Config.FRY_BURN_AT = 9.0
Config.FLIP_FROM = 1.5
Config.FLIP_TO = 6.8
Config.DRAIN_TAPS = 2
Config.FOOD = {
 kwek={label="KWEK-KWEK",menu="2 PIECES",price=25,icon="● ●",color={237,116,37}},
 fishball={label="FISH BALL",menu="5 PIECES",price=18,icon="○ ○ ○",color={226,203,154}},
 kikiam={label="KIKIAM",menu="3 PIECES",price=22,icon="▰ ▰",color={166,97,54}},
}
Config.SAUCE = {Sweet="MATAMIS",Spicy="MAANGHANG",Vinegar="SUKA"}
Config.INITIAL_COINS = {[1]=18,[5]=10,[10]=8,[20]=4,[50]=1,[100]=0}
Config.CUSTOMERS = {
 {name="Mika",line="Ate, kwek-kwek. Suka lang, please. May quiz pa ako."},
 {name="Andre",line="Five fishball. Yung matamis. Sakto lang, may class."},
 {name="Paolo",line="Kikiam. Yung maanghang. Barya po."},
 {name="Iya",line="Pabili! Suka, tapos pakidamihan."},
 {name="Trish",line="Miss, isang fishball order. Do you have sukli?"},
 {name="Ren",line="Kwek-kwek na maanghang. Nagmamadali ako."},
 {name="Bea",line="Kikiam. Sweet sauce. May pila sa photocopy."},
 {name="Sam",line="Fishball ulit. Suka please. Last na 'to."},
}
-- Fixed first-order tutorial, with varied food and denomination pressure later.
Config.SHIFT_ORDERS = {
 {food="kwek",sauce="Vinegar",tender=50,wait=110},
 {food="fishball",sauce="Sweet",tender=20,wait=105},
 {food="kikiam",sauce="Spicy",tender=50,wait=100},
 {food="kwek",sauce="Vinegar",tender=100,wait=100},
 {food="fishball",sauce="Vinegar",tender=50,wait=94},
 {food="kwek",sauce="Spicy",tender=50,wait=90},
 {food="kikiam",sauce="Sweet",tender=100,wait=85},
 {food="fishball",sauce="Vinegar",tender=20,wait=88},
}
Config.DENOMINATIONS={1,5,10,20,50}
return Config
