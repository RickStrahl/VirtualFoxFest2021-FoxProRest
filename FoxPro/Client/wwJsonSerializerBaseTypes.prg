CLEAR
DO wwjsonSerializer

loSer = CREATEOBJECT("wwJsonSerializer")


? loSer.Serialize("One" + CHR(10) + "Two" + Chr(10) + "Three") && "One\nTwo\nThree"
? loSer.Serialize(1.22)         && 1.22
? loSer.Serialize(.T.)          && true
? loSer.Serialize(DateTime())   && "2020-10-01T01:22:15Z"
? loSer.Serialize( CAST("Hello World" as Blob))        && base64

loCol = CREATEOBJECT("Collection")

loCust = CREATEOBJECT("Empty")
ADDPROPERTY(loCust,"Name","Rick")
ADDPROPERTY(loCust,"Company","West Wind Technologies")
ADDPROPERTY(loCust,"Entered",DATETIME())

loCol.Add(loCust)

loCust = CREATEOBJECT("Empty")
ADDPROPERTY(loCust,"Name","Kevin")
ADDPROPERTY(loCust,"Company","OakLeaf")
ADDPROPERTY(loCust,"Entered",DATETIME())
loCol.Add(loCust)

lcJson = loSer.Serialize(loCol, .T.)
? lcJson


