#INCLUDE wconnect.h

SET PROCEDURE TO wwUtils Additive
SET PROCEDURE TO wwApi ADDITIVE
SET PROCEDURE TO wwCollections ADDITIVE

*** If you use DeserializeJson you'll also need this in your code
SET PROCEDURE TO wwDotnetBridge ADDITIVE
SET PROCEDURE TO wwJsonSerializer Additive

************************************************************************
*  JsonSerialize
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION JsonSerialize(lvValue, llFormatJson, loSerializer)

IF ISNULLOREMPTY(loSerializer)
   loSerializer = CREATEOBJECT("wwJsonSerializer")
ENDIF
loSerializer.FormattedOutput = llFormatJson
RETURN loSerializer.Serialize(lvValue)
ENDFUNC
*   JsonSerializer

************************************************************************
*  JsonDeserialize
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION JsonDeserialize(lcJson, loSerializer)
IF ISNULLOREMPTY(loSerializer)
   loSerializer = CREATEOBJECT("wwJsonSerializer")
ENDIF
RETURN loSerializer.DeserializeJson(lcJson)
ENDFUNC
*   JsonDeserialize


*** NOTE: wwIPStuff.dll dependency for JSON encoding
*** For JsonEncode() API function to encode strings efficiently
*** since VFP's char by char parsing is too slow

*************************************************************
DEFINE CLASS wwJsonSerializer AS Custom
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2006
*:Contact: http://www.west-wind.com
*:Created: 09/19/2006
*************************************************************

PROTECTED cOutput
cOutput = ""

TrimStringValues = .T.

*** Exclude Custom Property Exclusions
PropertyExclusionList = ;
 ",activecontrol,classlibrary,baseclass,comment,docked,dockposition,controls,objects,controlcount,"+;
 "class,parent,parentalias,parentclass,helpcontextid,whatsthishelpid," +;
 "width,height,top,left,tag,picture,onetomany,childalias,childorder,relationalexpr,timestamp_column," 

*** Overrides property naming by using the
*** names specified here with proper case 
*** instead of the properties 
PropertyNameOverrides = ""

*** If .t. doesn't convert dates to UTC first
*** Assumes that any date is already UTC formatted
AssumeUtcDates = .F.

*** Offset between UTC and local time in minues
*** Automatically set on first date conversion or
*** you can set this value explicitly
nUtcTimeOffsetMinutes =  -1

*** 0 - ISO Date String, 1 - new Date('ISO') 2 - ISODate('ISO')
OutputDateType = 0

*** Ignore variables that start with $
IgnoreDollarVars = .F.

*** if .T. pretty formats the JSON
FormattedOutput = .F.

*** Characters filtered from generated property names
PropertyNameCharacterFilter = ""

FUNCTION PropertyNameCharacterFilter_Access()
IF EMPTY(this.PropertyNameCharacterFilter)   
	lcCharFilter = ""
	FOR lnX = 1 TO 255
		IF (lnX >= 65 AND lnX <= 90) OR ;
		   (lnX >= 97 AND lnX <= 122) OR ;
		   (lnX >=48 AND lnX <=57) OR ;
		   lnX = 95 
		   loop
		ENDIF
		lcCharFilter = lcCharFilter + CHR(lnX)
	ENDFOR
	THIS.PropertyNameCharacterFilter = lcCharFilter
ENDIF
RETURN this.PropertyNameCharacterFilter
ENDFUNC


*** wwDotnetBridge Instance
oBridge = null

*** Internal wwCollection instance of Property names
PROTECTED oPropertyNames, nDecimals
oPropertyNames = null
nDecimals = SET("DECIMAL")


************************************************************************
* wwJSONSerializer ::  Serialize
****************************************
***  Function: Serializes a VFP value, object or array/collection to
***            a JSON string.
***    Assume:
***      Pass: lvValue  -  Value to serialize
***            llFormat -  if .T. formats the 
***    Return:
************************************************************************
FUNCTION Serialize(lvValue, llFormat)
LOCAL lcOldPoint, lcJson

IF PARAMETERS() != 2
  llFormat = THIS.FormattedOutput
ENDIF

lcOldPoint = SET("POINT")
SET POINT TO "."

this.cOutput = ""
this.WriteValue(@lvValue)

SET POINT TO lcOldPoint

IF llFormat 
   this.cOutput = this.FormatJson(this.cOutput)
ENDIF

RETURN THIS.cOutput
ENDFUNC
*  wwJSONSerializer ::  Serialize


************************************************************************
*  DeserializeJson
****************************************
***  Function: Deserializes a JSON object, value or array into a Fox object
***    Assume: Requires wwDotnetBridge 
***      Pass:
***    Return:
************************************************************************
FUNCTION DeserializeJson(lcJson)
LOCAL loSer, loRes

IF IsNullOrEmpty(lcJson)
   RETURN lcJson
ENDIF
IF VARTYPE(lcJson) # "C"
   ERROR "Json Deserialization requires string input"
ENDIF   

IF ISNULL(THIS.oBridge)
	THIS.oBridge = GetwwDotnetBridge()
ENDIF
loSer = THIS.oBridge.CreateInstance("Westwind.WebConnection.wwJsonSerializer")
IF VARTYPE(loSer) # "O"
   ERROR this.oBridge.cErrorMsg
ENDIF

loRes = loSer.DeserializeJsonNet(lcJson)

IF ISNULL(loRes)
   RETURN null
ENDIF   

DO CASE
   CASE loRes.Type = "O"
	   RETURN THIS.ParseObjectJson(loRes)
   CASE loRes.Type = "A"
       RETURN THIS.ParseArrayJson(loRes)
   OTHERWISE
       RETURN this.ParseValueJson(loRes)
ENDCASE          

ENDFUNC
*   DeserializeJson


************************************************************************
*  Deserialize
****************************************
***  Function: Deserializes JSON
***    Return:
************************************************************************
FUNCTION Deserialize(lcJson)
RETURN THIS.DeserializeJson(lcJson)
ENDFUNC
*   Deserialize



************************************************************************
*  DeserializeCursor
****************************************
***  Function: Special Deserialize overload that assumes the result
***            is an object array that can be deserialized into an
***            open cursor
***    Assume:
***      Pass: lcJson           - JSON with Object Array
***            lcWritableCursor - Cursor name that is open and writable
***    Return: Number of records in the cursor
************************************************************************
FUNCTION DeserializeCursor(lcJson, lcWritableCursor)
LOCAL loCol as Collection

loCol = THIS.Deserialize(lcJson)

IF TYPE("loCol.Count") # "N"
   RETURN -1
ENDIF

CollectionToCursor(loCol, lcWritableCursor)

RETURN loCol.Count
ENDFUNC
*   DeserializeCursor

************************************************************************
* wwJSONSerializer ::  WriteValue
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteValue(lvValue)
LOCAL lcType, lnX
LOCAL ARRAY la_array[1]
LOCAL ARRAY lvValArray[1]

lcType = TYPE([lvValue])
		
DO CASE
	CASE TYPE([ALEN(lvValue)]) = "N"
		this.WriteArray(@lvValue)		
	CASE ISNULL(lvValue)		
		this.cOutput = this.cOutput + "null"
	CASE INLIST(lcType,"C","M","V")
		DO CASE
		 CASE LEFT(lvValue,6) == "cursor"		 
		    IF LEFT(lvValue,7) == "cursor:" OR  LEFT(lvValue,16) == "cursor_rawarray:" OR LEFT(lvValue, 13) == "cursor_legacy"
				this.WriteCursor(@lvValue)
			ELSE
				this.WriteString(@lvValue)
			ENDIF
		OTHERWISE			
			this.WriteString(@lvValue)
		ENDCASE
	CASE lcType == "Y"
		this.cOutput = this.cOutput + ALLTRIM(TRANSFORM(lvValue,"@N"))
	CASE INLIST(lcType,"I","N","F")
		this.cOutput = this.cOutput + TRANSFORM(lvValue)
	CASE lcType = "L"
		IF lvValue 
			this.cOutput = this.cOutput + "true"
		ELSE
			this.cOutput = this.cOutput + "false"
		ENDIF
	CASE INLIST(lcType,"D","T")
		this.WriteDate(@lvValue)
	*** Base 64 encode binary values
	CASE lcType = "W" OR lcType = "Q"
		this.cOutput = this.cOutput + ["] + STRCONV(lvValue,13) + ["]
	
	CASE lcType = "G"	
         * General field - do nothing
	CASE lcType = "O"
		LOCAL lcValueType, llHasKeys
		lcValueType = TYPE("lvValue.Class")	
		
		*** Special Object - wwCollection: Serialize as array
		DO CASE
		CASE lcValueType = "C" AND LOWER(lvValue.Class) == "collection"
		    IF lvValue.Count = 0
		        this.cOutput = this.cOutput + "[]"
			ELSE
				llHasKeys = !EMPTY(EVALUATE("lvValue.GetKey(1)"))
				IF llHasKeys
					THIS.WriteKeyCollection(@lvValue)
				ELSE			
					*** Turn collection into Array and parse as Array
					this.WriteCollection(@lvValue)
				ENDIF
			ENDIF
		CASE lcValueType = "C" AND LOWER(lvValue.Class) == "wwcollection"
			DIMENSION la_array[1]
			ACOPY(lvValue.aItems,la_array)
			this.WriteArray(@la_array)
			
		CASE lcValueType = "C" AND LOWER(lvValue.Class) == "wwdynamic"
		    this.WriteDynamicObject(@lvValue)
		OTHERWISE
			this.WriteObject(@lvValue)
		ENDCASE
	OTHERWISE 
	    this.cOutput = this.cOutput + "null"
ENDCASE
ENDFUNC
*  wwJSONSerializer ::  WriteValue


************************************************************************
* wwJSONSerializer ::  WriteString
****************************************
***  Function: serializes string
***    Assume: Thanks to Lauren Clarke for his help in 
***            optimization.
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteString(lcValue)
LOCAL lnK, lcResult, lcValue,lcOutput

IF THIS.TrimStringValues
   lcValue = TRIM(m.lcValue)
ENDIF

IF EMPTY(lcValue)
	this.cOutput = this.cOutput + [""]
	RETURN 
ENDIF	

*** Optimized for perf with C code in wwIPStuff.dll
*** JsonEncodeString
LOCAL lcOutput, lnBufferSize
lnBufferSize = LEN(lcValue) * 5 + 3
IF (lnBufferSize < 16750000)
	lcOutput = REPLICATE(" ",lnBufferSize)
ELSE 
    *** Set to max string size and hope for the best!
    *** The calculated value is overly pessimistic so
    *** as long as the output is under 16 megs it'll still work
	lcOutput = REPLICATE(" ",16750000)
ENDIF	

PUBLIC __JsonEncodeStringAPI
IF !__JsonEncodeStringAPI
	DECLARE INTEGER JsonEncodeString ;
	        IN wwipstuff.dll ;
	        string  json,string@  output
	__JsonEncodeStringAPI = .T.
ENDIF	

lnPointer = JsonEncodeString(lcValue,@lcOutput)   
IF (lnPointer = 0)
   ERROR "JSON Encoding failed: result string exceeds 16 meg string limit."
ENDIF

this.cOutput = this.cOutput  + WinApi_NullString(@lcOutput)
ENDFUNC
* WriteString

************************************************************************
* wwJsonSerializer ::  WriteDate
****************************************
***  Function: Turns a date into an ISO formatted date value string
***    Assume: Input dates are assumed to be local dates
***            If you have UTC dates to start you'll need to convert
***            them to local dates first
***      Pass: Date Value
***    Return: Json Date 
************************************************************************
FUNCTION WriteDate(lvValue)
LOCAL loNow

IF VARTYPE(lvValue) = "D"
	lvValue = DTOT(lvValue)
ENDIF	
IF EMPTY(lvValue)
	lvValue = {^1970-1-1 :}
ENDIF

IF ISNULL(this.oBridge)
	THIS.oBridge = GetwwDotnetBridge()
ENDIF
this.cOutput = this.cOutput + THIS.oBridge.oDotnetBridge.ToJsonUtcDate(lvValue, this.AssumeUtcDates)

ENDFUNC
*  wwJsonSerializer ::  WriteDate


************************************************************************
* wwJsonSerializer ::  SerializeArray
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteArray(laItems)
LOCAL lnRows, lnX, lvItem
EXTERNAL ARRAY laItems

lnRows = ALEN(laItems)
this.cOutput = this.cOutput + "["

FOR lnX = 1 TO lnRows
	lvItem = laItems[lnX]
		
	this.WriteValue( @lvItem ) 
	
	this.cOutput = this.cOutput + ","	
ENDFOR

this.cOutput = TrimWhiteSpace(this.cOutput,",")

this.cOutput = this.cOutput + "]"
ENDFUNC
*  wwJsonSerializer ::  SerializeArray

************************************************************************
* wwJsonSerializer ::  WriteCollection
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteCollection(loCol)
LOCAL lnRows, lnX, lvItem

lnRows = loCol.Count
this.cOutput = this.cOutput + "["

FOR lnX = 1 TO lnRows
	lvItem = loCol.Item(lnx)
	this.WriteValue( @lvItem ) 	
	this.cOutput = this.cOutput + ","	
ENDFOR

this.cOutput = TrimWhiteSpace(this.cOutput,",")

this.cOutput = this.cOutput + "]"
ENDFUNC
*  wwJsonSerializer ::  SerializeArray



************************************************************************
*  WriteKeyCollection
****************************************
***  Function: Writes a key/value collection as a JSON object
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteKeyCollection(loCollection)
LOCAL loResult, lnRows
lnRows = loCollection.Count

THIS.cOutput = THIS.cOutput +  "{"
FOR lnX = 1 TO lnRows 
	this.cOutput = this.cOutput + ["] + loCollection.GetKey(lnX) + [":]
	this.WriteValue(loCollection.Item[lnx])
	IF lnX < loCollection.Count
		this.cOutput = this.cOutput + ","
	ENDIF
ENDFOR

this.cOutput = this.cOutput + "}"
ENDFUNC
*   WriteKeyCollection

************************************************************************
* wwJSONSerializer ::  WriteObject
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteObject(loObject)
LOCAL lnX, lnProperties, llPropNames, lcFieldName, lnIndex
LOCAL ARRAY laMembers[1], la_array[1]

lnProperties = AMEMBERS(laMembers,loObject)

this.cOutput = this.cOutput + [{]

THIS.EnsurePropertyNameOverrides()

llPropNames = !ISNULL(this.oPropertyNames)

FOR lnX = 1 TO lnProperties
	  lcFieldName=LOWER(laMembers[lnX])
      
	   *** Handle property exclusions
	   IF AT("," + lcFieldName + ",","," + THIS.PropertyExclusionList + ",")>0
	      LOOP
	   ENDIF
      
	  IF llPropNames	  
	  	 lnIndex = this.oPropertyNames.GetIndex(lcFieldName)
	  	 IF lnIndex > 0
	  	    lcFieldName = this.oPropertyNames.aItems[lnIndex]
	  	 ENDIF
	  ENDIF	  
 
      this.cOutput = this.cOutput + ["] + lcFieldName + [": ]
      
	  IF TYPE([ALEN(loObject.] + lcFieldName + [)]) = "N"
	     *** Special Array handling - have to copy it to var first so we can pass by ref
         DIMENSION la_array[1]
         ACOPY(loObject.&lcFieldName,la_array)
	     this.WriteArray( @la_Array )
	  ELSE  
	     this.WriteValue( EVAL("loObject."+lcFieldName) )
	  ENDIF
	  
	  this.cOutput = this.cOutput + ","
ENDFOR

#IF wwVFPVersion > 8
	this.cOutput = RTRIM(this.cOutput,0,",")
#ELSE
	this.cOutput = TrimWhiteSpace(this.cOutput,",")
#ENDIF

this.cOutput = this.cOutput + [}]
ENDFUNC
*  wwJSONSerializer ::  WriteObject


************************************************************************
*  WriteDynamicObject
****************************************
***  Function: Special handling for wwDynamic object instance
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteDynamicObject(lvValue)
LOCAL lnX, lnCount, lcOldExclusionList

IF !EMPTY(lvValue.__PropertyNameOverrides) AND ;
   ATC(lvValue.__PropertyNameOverrides,this.PropertyNameOverrides) < 1

	lnCount = ALINES(laItems,lvValue.__PropertyNameOverrides,1 + 4,",")
	IF lnCount > 0 AND ISNULL(this.oPropertyNames)
        THIS.oPropertyNames = CREATEOBJECT("wwCollection")
    ENDIF

	FOR lnX = 1 TO lnCount
	   this.oPropertyNames.Add(laItems[lnX])
	ENDFOR
	this.PropertyNameOverrides = this.PropertyNameOverrides + lvValue.__PropertyNameOverrides
ENDIF

lcOldExclusions = this.PropertyExclusionList
this.PropertyExclusionList = ""
this.WriteObject( EVALUATE("lvValue.__Reference"))		    		    
this.PropertyExclusionList = lcOldExclusions

ENDFUNC
*   WriteDynamicObject

************************************************************************
* wwJSONSerializer ::  WriteCursor
****************************************
***  Function: Writes out a cursor
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteCursor(lcCursor)
LOCAL lnFieldCount, lnX, lcOldCursor, lcField, llNoRows, llExclusions,lnCount

llNoRows = .T.
IF AT("cursor_rawarray:",lcCursor) > 0
   lcCursor = STRTRAN(lcCursor,"cursor_rawarray:","")
ELSE
   lcCursor = STRTRAN(lcCursor,"cursor:","")
ENDIF
IF AT("cursor_legacy",lcCursor) > 0
   llNoRows = .F.
   lcCursor = STRTRAN(lcCursor,"cursor_legacy:","")
ENDIF

lcOldCursor = ALIAS()

IF EMPTY(lcCursor)
	lcCursor = ALIAS()
ENDIF
IF EMPTY(lcCursor)
   this.cOutput = this.cOutput + "null"	
   RETURN
ENDIF

IF USED(lcCursor)
   SELECT (lcCursor)
ELSE
   RETURN   
ENDIF   

lnFieldCount = AFIELDS(laFields,lcCursor)


this.EnsurePropertyNameOverrides()

llExclusions = !ISNULL(this.oPropertyNames)


*** Note: Inconsistency Exception here - 
***       use upper case so it works with the script library
***       for automatic databinding.
IF !llNoRows
	this.cOutput = this.cOutput +  '{"Rows":'
ENDIF

this.cOutput = this.cOutput + "["

lnCount = 0
LOCAL lcType
SCAN
	this.cOutput = this.cOutput + [{]	
	
	FOR lnX = 1 TO lnFieldCount
		lcField = LOWER(laFields[lnX,1])
		lcType = laFields[lnX,2]
		IF lcType = "G"
		   LOOP
		ENDIF
		
		  IF llExclusions
		  	 lnIndex = this.oPropertyNames.GetIndex(lcField)
		  	 IF lnIndex > 0
		  	    lcField = this.oPropertyNames.aItems[lnIndex]
		  	 ENDIF
		  ENDIF	  		
		
		this.cOutput = this.cOutput + ["] +  lcField+ [":]
		
		this.WriteValue( EVALUATE(lcField) )
		
		IF lnX < lnFieldCount
			this.cOutput = this.cOutput + ","
		ENDIF
	ENDFOR

	this.cOutput = this.cOutput + [},]
	lnCount = lnCount + 1 
ENDSCAN

IF USED(lcOldCursor)
	SELECT (lcOldCursor)
ENDIF	

#IF wwVFPVersion > 8
	this.cOutput = RTRIM(this.cOutput,0,",") +  "]"
#ELSE
	this.cOutput = TrimWhiteSpace(this.cOutput,",") +  "]"
#ENDIF

IF !llNoRows
  this.cOutput = this.cOutput + ',"Count": '  +  TRANSFORM(lnCount) + "}"
ENDIF

ENDFUNC
*  wwJSONSerializer ::  WriteCursor

************************************************************************
* wwJSONSerializer ::  WriteRow
****************************************
***  Function:
***    Assume: Record is loaded and ready to go
***      Pass:
***    Return:
************************************************************************
FUNCTION WriteRow(lvValue)
LOCAL lnFieldCount, lnX, lcOldCursor, lcField

lcCursor = STRTRAN(lcCursor,"cursorrow:","")

lcOldCursor = ALIAS()

IF EMPTY(lcCursor)
	lcCursor = ALIAS()
ENDIF
IF EMPTY(lcCursor)
   this.cOutput = this.cOutput + "null"	
   RETURN
ENDIF

IF USED(lcCursor)
   SELECT (lcCursor)
ELSE
   RETURN   
ENDIF   

lnFieldCount = AFIELDS(laFields,lcCursor)
this.cOutput = this.cOutput +  '{'

FOR lnX = 1 TO lnFieldCount
	lcField = laFields[lnX,1]	
	this.cOutput = this.cOutput + ["] +  lcField+ [": ]
	this.WriteValue( EVALUATE( lcField ) )
	this.cOutput = this.cOutput + ","
ENDFOR

#IF wwVFPVersion > 8
	this.cOutput = RTRIM(this.cOutput,0,",") +  "}"
#ELSE
	this.cOutput = TrimWhiteSpace(this.cOutput,",") +  "}"
#ENDIF

IF USED(lcOldCursor)
	SELECT (lcOldCursor)
ENDIF	

ENDFUNC
*  wwJSONSerializer ::  WriteRow


************************************************************************
*  EnsurePropertyNameOverrides
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION EnsurePropertyNameOverrides()

IF !EMPTY(this.PropertyNameOverrides) AND ISNULL(this.oPropertyNames)
   this.oPropertyNames = CREATEOBJECT("wwCollection")
   this.oPropertyNames.Count = ALINES(this.oPropertyNames.aItems,this.PropertyNameOverrides,1 + 4,",")
ENDIF

ENDFUNC
*   EnsurePropertyNameOverrides

************************************************************************
*  AddPropertyNameOverride
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION AddPropertyNameOverride(lcProperty)

*** Add only if prop isn't already lower case
IF (!(lcProperty == LOWER(lcProperty)))
   this.cPropertyNameOverrides = this.cPropertyNameOverrides + lcProperty + ","
ENDIF

ENDFUNC
*   AddPropertyNameOverride

************************************************************************
* wwJsonSerializer ::  Deserialize
***********************************
* Uses DeserializeJson() - see docs there
****************************************
*!*	FUNCTION Deserialize(lcValue)
*!*	*** ISO, or MS AJAX dates, \/Date(9999999)\/ or new Date(9999999)
*!*	IF (LEN(lcValue) = 22 AND RIGHT(lcValue,2) = 'Z"' AND SUBSTR(lcValue,6,1)="-") OR ;
*!*	   lcValue = ["\/Date] OR lcValue = ["\\/Date] OR lcValue = "new Date("
*!*	   RETURN this.ParseDate(lcValue)
*!*	ENDIF   

*!*	lcValue = ALLTRIM(lcValue)

*!*	*** Check for string values
*!*	IF lcValue = ["]
*!*	   RETURN this.ParseString(lcValue)
*!*	ENDIF

*!*	*** Check for objects - note only limited support
*!*	IF lcValue = [{]
*!*	   RETURN this.ParseObject(lcValue)
*!*	ENDIF

*!*	*** Check for Arrays - not supported at this time: returns null
*!*	IF lcValue = "["
*!*	  RETURN this.ParseArray(lcValue)
*!*	ENDIF     

*!*	*** Check for boolean values
*!*	IF INLIST(lcValue,"true","false")
*!*	  RETURN this.ParseLogical(lcValue)
*!*	ENDIF

*!*	IF lcValue = "null"
*!*	   RETURN null
*!*	ENDIF   

*!*	*** Anything else is a literal numeric
*!*	RETURN VAL(lcValue)
*!* ENDFUNC
*  wwJsonSerializer ::  ParseValue


************************************************************************
*  DeserializeXml
****************************************
***  Function: Deserializes an XML object, value or array into a Fox 
***            object. Limited functionality as it can't figure out
***            type information **unless** there's a schema. All
***            values are returned as a string
***    Assume: Requires wwDotnetBridge 
***      Pass: an XML document
***    Return: parsed object 
************************************************************************
FUNCTION DeserializeXml(lcXml)
LOCAL loSer, loRes

IF ISNULL(THIS.oBridge)
	THIS.oBridge = GetwwDotnetBridge()
ENDIF
loSer = THIS.oBridge.CreateInstance("Westwind.WebConnection.wwJsonSerializer")

loRes = loSer.DeserializeXml(lcXml)

IF ISNULL(loRes)
   RETURN null
ENDIF   


DO CASE
   CASE loRes.Type = "O"
	   RETURN THIS.ParseObjectJson(loRes)
   CASE loRes.Type = "A"
       RETURN THIS.ParseArrayJson(loRes)
   OTHERWISE
       RETURN this.ParseValueJson(loRes)
ENDCASE          

ENDFUNC
*   DeserializeXml

************************************************************************
*  ParseValueJson
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION ParseValueJson(loRes)
LOCAL lvValue
lvValue =  this.oBridge.GetProperty(loRes,"Value")

if(loRes.Type == "Y")
     lvValue = ROUND(lvValue, this.nDecimals)
ENDIF
        
*!*	? lvValue
*!*	? " - " + VARTYPE(lvValue) +  " - " + loRes.Type

RETURN lvValue
ENDFUNC
*   ParseValueJson


************************************************************************
*  ParseObjectJson
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION ParseObjectJson(loObject)
LOCAL loResult, loMembers, loMember, lnCount, lnX, lvValue, lcName, lcName_First

loResult = CREATEOBJECT("EMPTY")

loMembers = this.oBridge.InvokeMethod(loObject,"GetMembers")
lnCount =loMembers.Count



FOR lnX = 0 TO lnCount-1
   loMember = loMembers.Item(lnX)
   lvValue = null
   
   DO CASE 
	CASE loMember.Type = "O"
   	  lvValue = THIS.ParseObjectJson(loMember)
	CASE loMember.Type = "A"
	  lvValue = THIS.ParseArrayJson(loMember)
	OTHERWISE
	  lvValue = this.ParseValueJson(loMember)
   ENDCASE
   
   lcName = loMember.Name
   lcName_First = LEFT(lcName,1)
   IF ISDIGIT(lcName_First)
      lcName = "_" + lcName
   ENDIF
   
   *** Ignore 'temporay names'
   IF THIS.IgnoreDollarVars AND lcName_First = "$"
     LOOP
   ENDIF
  
   *** Normalize Property Name
   *lcName = CHRTRAN(lcName," ~!@#$%^&*()-+={}[]\|/?.,<>:;`'" + ["],"")
   lcName = CHRTRAN(lcName,this.PropertyNameCharacterFilter,"")
   
   ADDPROPERTY(loResult,lcName,lvValue)
ENDFOR   

RETURN loResult
ENDFUNC

************************************************************************
*  ParseArrayJson
****************************************
***  Function:
***    Assume:
***      Pass: 
***    Return: Returns array as a wwCollection object
************************************************************************
PROTECTED FUNCTION ParseArrayJson(loObject)
LOCAL loCollection, loValue, loValues, lvValue, lnCount, lnX

loCollection = CREATEOBJECT("Collection")

loValues = this.oBridge.InvokeMethod(loObject,"GetValues")
lnCount = loValues.Count

FOR lnX = 0 TO lnCount-1
   loValue = loValues.Item(lnX)
   lvValue = null
   
   DO CASE 
	CASE loValue.Type = "O"
   	  lvValue = THIS.ParseObjectJson(loValue)
	CASE loValue.Type = "A"
	  lvValue = THIS.ParseArrayJson(loValue)
	OTHERWISE
	  lvValue = this.ParseValueJson(loValue)
   ENDCASE
   
   loCollection.Add(lvValue)
ENDFOR   

RETURN loCollection
ENDFUNC
*   ParseArray

************************************************************************
* wwJsonSerializer ::  Property
****************************************
***  Function: Custom version of FoxPro's AddProperty that
***            automatically adds the property's name to the
***            PropertyOverrides list
***    Assume:
***      Pass: loObject
***            lcProperty
***            lvValue
***    Return: the value of this object
************************************************************************
FUNCTION Property(loObject, lcProperty, lvValue)
ADDPROPERTY(loObject,lcProperty, lvValue)
THIS.PropertyNameOverrides = THIS.PropertyNameOverrides + ","  +lcProperty
RETURN EVALUATE("loObject." + lcProperty)
ENDFUNC
*  wwJsonSerializer ::  AddProperty

************************************************************************
* wwJsonSerializer ::  PropertyObject
****************************************
***  Function: Custom version of FoxPro's AddProperty that
***            adds an EMPTY object to theproperty specified.
***            automatically adds the property's name to the
***            PropertyOverrides list
***        
***    Assume: sets the value to CREATEOBJECT("EMPTY")
***      Pass: loObject
***            lcProperty
***            lvValue
***    Return: the value of this object
************************************************************************
FUNCTION PropertyObject(loObject, lcProperty)
ADDPROPERTY(loObject,lcProperty, CREATEOBJECT("EMPTY"))
THIS.PropertyNameOverrides = THIS.PropertyNameOverrides + ","  +lcProperty
RETURN EVALUATE("loObject." + lcProperty)
ENDFUNC
*  wwJsonSerializer ::  AddProperty

************************************************************************
* wwJsonSerializer ::  PropertyObject
****************************************
***  Function: Custom version of FoxPro's AddProperty that
***            adds a Collection object to theproperty specified.
***            automatically adds the property's name to the
***            PropertyOverrides list
***        
***    Assume: sets the value to CREATEOBJECT("EMPTY")
***      Pass: loObject
***            lcProperty
***            lvValue
***    Return: the value of this object
************************************************************************
FUNCTION PropertyCollection(loObject, lcProperty)
ADDPROPERTY(loObject,lcProperty, CREATEOBJECT("Collection"))
THIS.PropertyNameOverrides = THIS.PropertyNameOverrides + ","  +lcProperty
RETURN EVALUATE("loObject." + lcProperty)
ENDFUNC
*  wwJsonSerializer ::  AddProperty


************************************************************************
*  FormatJson
****************************************
***  Function: Takes a raw JSON string and turns it into indented
***            JSON fit for easier display.
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION FormatJson(lcJson)
LOCAL loSer

IF ISNULL(THIS.oBridge)
	THIS.oBridge = GetwwDotnetBridge()
ENDIF

loSer = THIS.oBridge.CreateInstance("Westwind.WebConnection.wwJsonSerializer")
RETURN loSer.FormatJson(lcJson)
ENDFUNC
*   FormatJson





*** OBSOLETE FUNCTIONS 

#IF .F.

************************************************************************
* wwJsonSerializer ::  ParseString
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseString(lcJsonString)

IF VARTYPE(poJScript) # "O"
	PUBLIC poJScript
	*** Windows Scripting Host COM Control 
	*** This will fail if not installed or blocked!
	loJScript = CREATEOBJECT("ScriptControl")
	loJScript.Language = "JavaScript"
ENDIF

lcValue = ""
TRY
	lcValue=loJScript.Eval(lcJsonString)
CATCH	
ENDTRY

RETURN lcValue
* wwJsonSerializer :: ParseString

************************************************************************
* wwJsonSerializer ::  ParseNumber
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseNumber(lcNumber)
RETURN VAL(lcNumber)
ENDFUNC
*  wwJsonSerializer ::  ParseNumber

************************************************************************
* wwJsonSerializer ::  ParseLogical
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseLogical(lcLogical)
IF (lcLogical = "true")
	RETURN .t.
ENDIF
RETURN .F.
ENDFUNC
*  wwJsonSerializer ::  ParseLogical

************************************************************************
* wwJsonSerializer ::  ParseDate
****************************************
***  Function: Converts a JSON Date String to a VFP Time Value
***    Assume: 
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseDate(lcDate, llReturnUtcTime)
LOCAL lnCount, lcDate, ldDate
LOCAL ARRAY laNums[1]

IF EMPTY(lcDate)
   RETURN  {/ /  : }
ENDIF

IF LEN(lcDate) != 22
   RETURN {/ / : }
ENDIF   

*** ISO format: 2009-01-03T18:10:00Z
IF RIGHT(lcDate,2) = 'Z"' AND SUBSTR(lcDate,6,1) = "-"
	lcDate = STRTRAN(lcDate,'"',"")
	lcDate = STRTRAN(lcDate,"T"," ")
	lcDate = SUBSTR(lcDate,1,LEN(lcDate)-1)
	lcDate = "{^" + lcDate + "}"
	ldDate = EVALUATE(lcDate)
	
	IF llReturnUtcTime
	   RETURN ldDate
	ENDIF   	
	
	*** Subtract TimeZone Offset in Minutes
	ldDate = ldDate - (GetTimeZone() * 60)	
	RETURN ldDate
ENDIF

*** MS AJAX Date Format: "\/Date(1012341)\/"
IF lcDate = ["\/] OR lcDate = ["\\/]
   lnMSecs = VAL(STREXTRACT(lcDate,"Date(",")"))
   RETURN {^1970/01/01 0:0} - (GetTimeZone() * 60) +  (lnMSecs/1000) 
ENDIF

** Input: new Date(2007,0,2,9,58,17,254)
lcDateNums = STREXTRACT(lcDate,"new Date(",")")

lnCount = ALINES(laNums,lcDateNums,1,",")

** String Output:  "{^2007-01-01 22:15:10}"
lcDate = "{^" + laNums[1] + "-" + TRANSFORM(VAL(laNums[2]) + 1) + "-" + laNums[3] +;
		 " " + laNums[4] + ":" + laNums[5] + ":" + laNums[6] + "}"

ldDate = EVALUATE(lcDate)

IF llReturnUtcTime
   RETURN ldDate
ENDIF   

*** Subtract TimeZone Offset in Minutes
ldDate = ldDate - (GetTimeZone() * 60)

RETURN ldDate
ENDFUNC
*  wwJsonSerializer ::  ParseDate

************************************************************************
* wwJsonSerializer ::  ParseObject
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseObject(lcObjectString,loObject)
LOCAL lnCurPos,llDone,lnAt,lnAt2, lcProperty, lcObject, lcValue

IF LEN(lcObjectString) < 3
	RETURN null
ENDIF
	
lcObject = SUBSTR(lcObjectString,3,LEN(lcObjectString)-3)

IF VARTYPE(loObject) # "O"
	loObject = CREATEOBJECT("EMPTY")
ENDIF	

lnCurPos = 0
llDone = .f.
DO WHILE .T.
	IF StartsWith(lcObject,",")
	   lcObject = ALLTRIM(SUBSTR(lcObject,2)) && Skip over comma
   	   lcObject = ALLTRIM(SUBSTR(lcObject,2)) && leading "
	ENDIF
	
	lnAt = AT([":],lcObject)
	IF lnAt = 0
		EXIT
	ENDIF

	lcProperty = SUBSTR(lcObject,1,lnAt-1)
	lcObject = ALLTRIM(SUBSTR(lcObject,lnAT+2))
	
	DO CASE 
		CASE lcObject = "{"
			*** NESTED OBJECT				
			lcValue = this.FindMatchingBrace(lcObject,"{","}")
			IF EMPTY(lcObject)
				lcValue = null
			ENDIF
		CASE lcObject = "["
			*** Nested Array			
			lcValue = this.FindMatchingBrace(lcObject,"[","]")
			IF EMPTY(lcObject)
			    lcValue = null
			ENDIF
		CASE lcObject = ["]
			*** String
			LOCAL loRegEx,loMatches
			loRegEx = GetwwRegExObject()
			loMatches = loRegEx.Match(lcObject,'".*?((^")|[^\\]")')
			IF !ISNULL(loMatches) AND loMatches.Count > 0
			   lcValue = loMatches.Item(0).Value
			ENDIF
			
		    *lvValue = this.ParseString(lcValue)	
		OTHERWISE
		    lnAt2 = AT([,"],lcObject)
			IF lnAt2 = 0
			   lcValue = lcObject
			ELSE
			   lcValue = SUBSTR(lcObject,1,lnAt2-1)
			ENDIF
	ENDCASE
	
	lcObject = ALLTRIM(STRTRAN(lcObject,lcValue,"",1,1))
		
	ADDPROPERTY(loObject,lcProperty, this.Deserialize(lcValue) )

	IF EMPTY(lcObject)
	   EXIT
	ENDIF
*!*		IF lnAt2 = 0
*!*			EXIT
*!*		ENDIF
	
	*lcObject = SUBSTR(lcObject,lnAt2+2)
ENDDO

RETURN loObject
ENDFUNC
*  wwJsonSerializer ::  ParseObject

************************************************************************
* wwJsonSerializer ::  ParseArray
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ParseArray(lcObjectString)
LOCAL lcData, lcFirst, lcValue, loCol, lnAt

lcData = ALLTRIM(lcObjectString)

IF lcObjectString == "null"
  RETURN null
ENDIF
  
IF LEN(lcData) < 3
   *** Empty array
   RETURN CREATEOBJECT("Collection")
ENDIF   

*** Strip off []
lcData = ALLTRIM(SUBSTR(lcData,2,LEN(lcObjectString)-2))

loCol = CREATEOBJECT("Collection")

DO WHILE .T.
	IF LEN(lcData) = 0
	   EXIT
	ENDIF
	
	*** Strip off leading ,
	IF SUBSTR(lcData,1,1) = ","
	   lcData = ALLTRIM(SUBSTR(lcData,2))
	ENDIF	

	lcFirst = SUBSTR(lcData,1,1)
	lvValue = null

	DO CASE
		*** Object
		CASE lcFirst = "{"
		   lcValue = this.FindMatchingBrace(lcData,"{","}")		   
		   lvValue = this.ParseObject(lcValue)
		CASE lcFirst = "["
		   lcValue = this.FindMatchingBrace(lcData,"[","]")
		   lvValue = this.ParseArray(lcValue)
		*** String
		CASE lcFirst = ["]
			LOCAL loRegEx,loMatches
			loRegEx = GetwwRegExObject()
			loMatches = loRegEx.Match(lcData,'".*?((^")|[^\\]")')
			IF !ISNULL(loMatches) AND loMatches.Count > 0
			   lcValue = loMatches.Item(0).Value
			ENDIF
			
		   lvValue = this.ParseString(lcValue)		   
		*** Literal
		OTHERWISE
		   lnAt = AT(",",lcData)
		   IF lnAt = 0
			  lnAt = AT("]",lcData)
		   ENDIF
		   IF lnAt = 0
		      EXIT
		   ENDIF
		      
		   lcValue = SUBSTR(lcData,1,lnAt-1)
		   lvValue = this.Deserialize(lcValue)		
	ENDCASE
	
	*** Trim out the parsed value
	lcData = ALLTRIM(STRTRAN(lcData,lcValue,"",1,1))
	
	loCol.Add(lvValue)
ENDDO

RETURN loCol
ENDFUNC
*  wwJsonSerializer ::  ParseArray


************************************************************************
* wwJsonSerializer ::  FindMatchingBrace
****************************************
***  Function: returns a matching brace for a string
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION FindMatchingBrace(lcCode,lcOpenBrace,lcCloseBrace,lcFollows)
LOCAL lnAt, lcSubCode

lnAT = AT(lcCloseBrace,lcCode)
IF lnAt = 0
	RETURN ""
ENDIF	
lcSubCode = SUBSTR(lcCode,1,lnAt)

lnOccurs = OCCURS(lcOpenBrace,lcSubCode)
IF lnOccurs = 0
	RETURN ""
ENDIF
IF lnOccurs = 1
	RETURN SUBSTR(lcCode,1,lnAT) 
ENDIF

lnAt = AT(lcCloseBrace,lcCode,lnOccurs)
IF lnAT = 0
	RETURN ""
ENDIF	

RETURN SUBSTR(lcCode,1,lnAT) 

#ENDIF





ENDDEFINE





*************************************************************
DEFINE CLASS wwJsonServiceClient AS Custom
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2016
*:Contact: http://www.west-wind.com
*:Created: 01/11/2016
*************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class CustomerServiceClient

*:Description:
A small wrapper class that can make HTTP service calls, and
automatically serialize parameters and deserialize results
when calling JSON APIs.

You can subclass this class and use the CallService method
in your own service wrapper methods that call the service.

*:Example:

************************************************************************
*  GetCustomers
****************************************
FUNCTION Customers(loParms)
LOCAL loCustomers

loCustomers = THIS.CallService(this.cServiceBaseUrl + "customers.csvc", loParms)

IF THIS.lError
   RETURN null
ENDIF   

RETURN loCustomers
ENDFUNC
*   GetCustomers

*:Remarks:

*:SeeAlso:


*:ENDHELP
#ENDIF

*** Custom Properties

*** Stock Properties
cErrorMsg = ""
lError = .F.

cServiceBaseUrl = ""
oSerializer = null
oHttp = null

*** By default JSON responses are  always UTF-8 decoded. Set this .T. if the response *is not* utf-8 encoded
lNoUtf8Decoding = .F.

************************************************************************
*  Init
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION INIT

THIS.CreateSerializer()
THIS.CreateWwHttp()

ENDFUNC
*   Init

************************************************************************
*  CreateSerializer
****************************************
***  Function: Sets or creates a Serializer instance
***            Use this method to customize the serializer settings
***            for things like overriding property values
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION CreateSerializer(loSerializer)

IF VARTYPE(loSerializer) = "O"
   THIS.oSerializer = loSerializer
ENDIF
IF ISNULL(THIS.oSerializer)
   this.oSerializer = CREATEOBJECT("wwJsonSerializer")
ENDIF
   
RETURN this.oSerializer
ENDFUNC
*   CreateSerializer

************************************************************************
*  CreatewwHttp
****************************************
***  Function: Overrides the default wwHttp instance with a preset
***            custom instance. 
***    Assume: Set before making the actual service call
***            Metho
***      Pass: loHttp   -   (optional) Preconfigured wwHttp Instance
***    Return:
************************************************************************
FUNCTION CreatewwHttp(loHttp)

IF VARTYPE(loHttp) = "O"
    this.oHttp = loHttp
ELSE
	IF VARTYPE(this.oHttp) # "O"
		this.oHttp = CREATEOBJECT("wwHttp")
	ENDIF
ENDIF	

RETURN this.oHttp
ENDFUNC
*   CreatewwHttp

************************************************************************
*  AddHeader
****************************************
***  Function: Helper function that lets you add HTTP headers
***            to the request. Same as .oHttp.AddHeader()
***            added to provide more obvious use case
***    Assume:
***      Pass: 
***    Return:
************************************************************************
FUNCTION AddHeader(lcHeader, lcValue)
this.CreatewwHttp()
this.oHttp.AddHeader(lcHeader, lcValue)
ENDFUNC
*   AddHeader

************************************************************************
*  CallService
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION CallService(lcUrl,lvPostData, lcVerb)
LOCAL lcResult, lcJson, loHttp, loSer, loResult

this.lError = .F.

IF EMPTY(lcVerb) 
	IF IsNullOrEmpty(lvPostData)
	   lcVerb = "GET"
	ELSE
	   lcVerb = "POST"
	ENDIF
ENDIF   

loHttp = this.CreatewwHttp()
loHttp.cHttpVerb = lcVerb

*** Serialize single value/object
IF !IsNullOrEmpty(lvPostData)
    loSer = THIS.CreateSerializer()
    lcJson = loSer.Serialize(lvPostData)
	loHttp.cContentType = "application/json; charset=utf-8"	
	loHttp.AddPostKey(STRCONV(lcJson,9))
ENDIF

lcResult = loHttp.HttpGet(lcUrl)

IF loHttp.nError != 0
   this.cErrorMsg = loHttp.cErrorMsg
   this.lError = .T.
ENDIF

*** If the response has JSON in it
IF ATC("application/json",loHttp.cHttpHeaders) > 0
    IF !this.lNoUtf8Decoding
       lcResult = STRCONV(lcResult,11)
    ENDIF
    loSer = THIS.CreateSerializer()
    loResult = loSer.DeserializeJson(lcResult)    
    RETURN loResult
ENDIF

RETURN lcResult
ENDFUNC
*   CallService

ENDDEFINE
*EOC wwJsonServiceClient