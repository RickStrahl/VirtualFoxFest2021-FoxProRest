CLEAR
DO wwJsonSerializer && Load libs

IF !USED("Customers")
   USE Customers IN 0
ENDIF
SELECT Customers

SELECT TOP 2 * FROM CUSTOMERS ORDER BY LastName INTO CURSOR TQUery

LOCAL loSer as wwJsonSerializer
loSer = CREATEOBJECT("wwJsonSerializer")

*** Serialize a top level cursor to a JSON Collection
lcJson =  loSer.Serialize("cursor:TQuery",.T.)
? PADR(lcJson,1000)


*** Cursor as a Property of a complex object
loCust = CREATEOBJECT("Empty")
ADDPROPERTY(loCust,"Name","Rick")
ADDPROPERTY(loCust,"Company","West Wind Technologies")
ADDPROPERTY(loCust,"Entered",DATETIME())

*** Cursor as collection property of Customer obj
SELECT TOP 2 * FROM CUSTOMERS ORDER BY LastName INTO CURSOR TQUery
ADDPROPERTY(loCust,"CustomerList", "cursor:TQuery")

loSer.PropertyNameOverrides = "firstName,lastName,customerList,billRate,shipAddr"

lcJson =  loSer.Serialize(loCust, .T.)
ShowJson(lcJson)


*** read back from JSON into an object
loCust2 = loSer.DeserializeJson(lcJson)

? loCust2.Name
? loCust2.Company
? loCust2.Entered

SELECT * FROM Customers WHERE .F. INTO CURSOR TCustomers READWRITE
CollectionToCursor(loCust2.CustomerList,"TCustomers")

SELECT TCustomers
BROWSE nowait




