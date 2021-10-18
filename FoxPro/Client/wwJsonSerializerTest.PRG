CLEAR
DO wwJsonSerializer && Load libs

*** Create a complex object
loCust = CREATEOBJECT("Empty")
ADDPROPERTY(loCust,"Name","Rick")
ADDPROPERTY(loCust,"Entered",DATETIME())

*** Create a nested object
ADDPROPERTY(loCust,"Address", CREATEOBJECT("Empty"))
ADDPROPERTY(loCust.Address,"Street","17 Aluui Place")
ADDPROPERTY(loCust.Address,"City","Paia")
ADDPROPERTY(loCust,"Number",32)

loSer = CREATEOBJECT("wwJsonSerializer")

*** Serialize into JSON
lcJson =  loSer.Serialize(loCust,.t.)

? lcJson
* {"address": {"city": "Paia","street": "17 Aluui Place"},"entered": "2021-09-25T01:07:05Z","name": "Rick","number": 32}


*** read back from JSON into an object
loCust2 = loSer.DeserializeJson(lcJson)

? loCust2.Name
? loCust2.Entered
? loCust2.Address.Street
? loCust2.Number


