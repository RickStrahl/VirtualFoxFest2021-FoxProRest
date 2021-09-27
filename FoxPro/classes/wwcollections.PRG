#INCLUDE WCONNECT.H

SET PROCEDURE TO wwCollections ADDITIVE

*************************************************************
DEFINE CLASS wwCollection AS Relation
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 08/19/2005
*************************************************************

*** Custom Properties

*** Stock Properties
DIMENSION aItems[1] 
Count = 0
RequireUniqueItems = .F.

************************************************************************
* wwCollection :: Add
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Add(lvValue)

IF THIS.RequireUniqueItems
   lnIndex = this.GetIndex(lvValue)
   IF (lnIndex > 0)
      this.aItems[lnIndex] = lvValue
      RETURN
   ENDIF
ENDIF

THIS.Count = THIS.Count + 1
DIMENSION THIS.aItems[this.Count]
this.aItems[this.Count] = lvValue

ENDFUNC


************************************************************************
* wwCollection :: InsertAt
****************************************
***  Function: Inserts an item into the array at the specified
***            Position.
***    Assume:
***      Pass: lvValue
***              lvValue to insert
***
***            Position
***              Position to insert it *before*. New item becomes
***              the item at this position. Existing item is shifted down
***    Return: nothing
************************************************************************
FUNCTION InsertAt(lnPosition,lvValue)
LOCAL lnIndex

IF (THIS.RequireUniqueItems)
    *** If item exists remove it - then add it at beginning
	lnIndex = this.GetIndex(lvValue)
	IF lnIndex > 0
	   lvValue = this.aItems[lnIndex]
	   this.Count = this.Count -1	
	   ADEL(this.aItems,lnIndex)
	ENDIF
ENDIF

DIMENSION this.aItems[this.Count + 1]
IF AINS(this.aItems,lnPosition) = 1 
   this.aItems[lnPosition] = lvValue
   this.Count = this.Count + 1
ENDIF

ENDFUNC
*  wwCollection :: Insert

************************************************************************
* wwCollection :: Item
****************************************
***  Function: Returns an item out of the collection
***    Assume:
***      Pass: lnIndex  -  numeric index to item
***    Return: value or .NULL. if not found
************************************************************************
FUNCTION Item(lnIndex, llThrowError)

IF !llThrowError AND ;
   (lnIndex < 1 OR lnIndex > this.Count)
   RETURN NULL
ENDIF
   
RETURN this.aItems[lnIndex] 
ENDFUNC


************************************************************************
*  Get
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Get(lnIndex)
RETURN THIS.aItems[lnIndex]
ENDFUNC
*   Get

************************************************************************
*  Set
****************************************
***  Function: Assigns a value to the collection. If it exits
***            the value is ignored. If it doesn't exist it's added.
***    Assume: This is the equivalent of the behavior of an array
***            indexer which adds if it doesn't exist and replaces
***            if it does.
***      Pass:
***    Return:
************************************************************************
FUNCTION Set(lvValue)

lnIndex = this.GetIndex(lvValue)
IF lnIndex = 0
   this.Add(lvValue)
ENDIF   

ENDFUNC
*   Set

************************************************************************
*  Find
****************************************
***  Function: Retrieves a value by scanning for the item
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Find(lvItem)
LOCAL lnIndex

IF this.Count = 0
   RETURN null
ENDIF   

FOR lnX = 1 TO this.Count
   IF this.aItems[lnX] == lvItem
      RETURN this.aItems[lnX]
   ENDIF
ENDFOR

RETURN NULL
ENDFUNC
*   Find

************************************************************************
*  wwColleciton :: GetIndex
****************************************
***  Function: Tries to find the first match of a value
***            and returns the index
***    Assume: Strings are search case INSENSITIVE
***      Pass:
***    Return:
************************************************************************
FUNCTION GetIndex(lvItem)
LOCAL llString

IF this.Count = 0
   RETURN 0
ENDIF

llString =  VARTYPE(lvItem) = "C"
IF llString
   lvItem = LOWER(lvItem)
ENDIF


FOR lnX = 1 TO this.Count
   IF (llString)
      IF LOWER(this.aItems[lnX]) == lvItem
         RETURN lnX
      ENDIF
   ELSE
      IF this.aItems[lnX] == lvItem
	      RETURN lnX
	  ENDIF
   ENDIF 
ENDFOR

RETURN 0
ENDFUNC
*  wwCollection ::  GetIndex

************************************************************************
* wwCollection :: Remove
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Remove(lnIndex, llRemoveByValue)
LOCAL lnRow

IF llRemoveByValue
   lnIndex = this.GetIndex(lnIndex)
   IF lnIndex = 0
      RETURN
   ENDIF
ENDIF

*** invalid indexes - item is already removed
IF lnIndex > this.Count OR lnIndex < 1
   RETURN
ENDIF   

THIS.Count = THIS.Count - 1
ADEL(this.aItems,lnIndex)
ENDFUNC

************************************************************************
* wwCollection ::  UpdateItem
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION UpdateItem(lnIndex,lvValue)

IF lnIndex = 0
   RETURN
ENDIF
this.aItems[lnIndex] = lvValue
ENDFUNC
*  wwCollection ::  UpdateItem

FUNCTION Dispose
THIS.aItems=null
ENDFUNC

FUNCTION Destroy
THIS.aItems=null
ENDFUNC

************************************************************************
* wwCollection :: Clear
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Clear(llComplete)
LOCAL lnX

IF llComplete
	FOR lnX = 1 TO this.Count
		this.aItems[lnX] = null		
	ENDFOR
ENDIF	

THIS.Count = 0
THIS.aItems = .f.
this.aItems = null

ENDFUNC
*  wwCollection :: Clear

************************************************************************
* wwCollection ::  Sort
****************************************
***  Function: Sorts the list
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Sort()
	ASORT(this.aItems,1,ALEN(this.Items))
ENDFUNC
*  wwCollection ::  Sort

************************************************************************
* wwCollection ::  ToArray
****************************************
***  Function: Returns the Collection as an array.
***    Assume:
***      Pass: @laList  -  An Array Variable
***    Return: nothing (@laList is set)
************************************************************************
FUNCTION ToArray(laList)
ACOPY(this.aItems,laList)
ENDFUNC
*  wwCollection ::  ToArray


ENDDEFINE
*EOC wwCollection 

*************************************************************
DEFINE CLASS wwNameValueCollection AS RELATION
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 08/18/2005
***************************

DIMENSION aItems[1,2] 
Count = 0

************************************************************************
* wwNameValueCollection :: FastAdd
****************************************
***  Function: FastAdd Adds items without checking for uniqueness first
***    Assume: Considerably faster than regular Add. Use when you know
***            items are added only once.
***      Pass:
***    Return:
************************************************************************
FUNCTION FastAdd(lvKey,lvValue)

THIS.Count = THIS.Count + 1

IF PCOUNT() = 1
   lvValue = lvKey
   lvKey = TRANSFORM(this.Count)
ENDIF
   
DIMENSION THIS.aItems[this.Count,2]
this.aItems[this.Count,1] = lvKey
this.aItems[this.Count,2] = lvValue

ENDFUNC

************************************************************************
* wwNameValueCollection :: Add
****************************************
***  Function: Adds an item to the collection by first checking
***            for existance. If found overwrites existing value
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Add(lvKey,lvValue)
LOCAL lnIndex

lnIndex = THIS.GetIndex(lvKey)
IF lnIndex = 0
   THIS.FastAdd(lvKey,lvValue)
ELSE
   *** Otherwise update exist key
   THIS.aItems[lnIndex,1] = lvKey
   THIS.aItems[lnIndex,2] = lvValue
ENDIF

ENDFUNC
*  wwNameValueCollection :: AddUnique

************************************************************************
* wwNameCollection :: Insert
****************************************
***  Function: Inserts an item into the array at the specified
***            Position.
***    Assume:
***            Position
***              Position to insert it *before*. New item becomes
***              the item at this position. Existing item is shifted down
***            lvKey
***               Key of the value to insert
****           lvValue
***              Value to insert
***
***    Return: nothing
************************************************************************
FUNCTION InsertAt(Position,lvKey,lvValue)

IF PARAMETERS() = 2
   lvValue = lvKey
   lvKey = TRANSFORM(this.Count)
ENDIF

DIMENSION this.aItems[this.Count + 1,2]

IF AINS(this.aItems,Position) = 1 
   this.aItems[Position,1] = lvKey
   this.aItems[Position,2] = lvValue
   this.Count = this.Count + 1
ENDIF

ENDFUNC
*  wwCollection :: Insert

************************************************************************
* wwNameValueCollection :: Item
****************************************
***  Function: Returns an item out of the collection
***    Assume:
***      Pass: lvKey  -  numeric index or Key String value
***    Return: value or .NULL. if not found
************************************************************************
FUNCTION Item(lvKey)
LOCAL lnElement, lvValue

IF VARTYPE(lvKey) = "N"
   TRY
	   lvValue = this.aItems[lvKey,2]
   CATCH
	   lvValue = null       
   ENDTRY   
   RETURN lvValue
ENDIF

lnElement = ASCAN(this.aItems,lvKey,1,this.Count,1,7) && Case insensitive/exact on
IF lnElement = 0
  RETURN null
ENDIF

RETURN this.aItems[lnElement+1]
ENDFUNC


************************************************************************
* wwNameValueCollection ::  Get
****************************************
***  Function: Returns an object with Key and Value properties
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Get(lvKey)

loRes = CREATEOBJECT("Empty")
ADDPROPERTY(loRes,"Key","")
ADDPROPERTY(loREs,"Value","")

loRes.Key = this.GetKey(lvKey)
loRes.Value = this.Item(lvKey)	

IF ISNULL(loRes.Key)
   RETURN null
ENDIF   

RETURN loRes
ENDFUNC
*  wwNameValueCollection ::  Get


************************************************************************
* wwNameValueCollection ::  GetKey
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetKey(lnIndex)
   RETURN THIS.aItems[lnIndex,1]
ENDFUNC

************************************************************************
* wwNameValueCollection ::  GetIndex
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetIndex(lvKey)
LOCAL lnRow
   lnRow = ASCAN(this.aItems,lvKey,1,this.Count,1,15)  && Case insensitive/exact on
   IF lnRow > 0
  RETURN lnRow
   ENDIF
   RETURN 0
ENDFUNC

************************************************************************
*  Find
****************************************
***  Function: Tried to find the first instance of a value
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Find(lvItem)
LOCAL lnIndex

IF this.Count = 0
   RETURN null
ENDIF   

lnIndex = ASCAN(THIS.aItems,lvItem,1,this.Count,2,5)
IF (lnIndex = 0)
   RETURN null
ENDIF

RETURN this.aItems[lnIndex,2]   
ENDFUNC
*   Find

************************************************************************
* wwNameValueCollection :: Remove
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Remove(lvKey)
LOCAL lnRow
   IF VARTYPE(lvKey) = "N"
   	  this.aItems[lvKey,2]= .f. && Clear value
      ADEL(this.aItems,lvKey)
   ELSE
   	  LOCAL lnRow
      lnRow = this.GetIndex(lvKey)
      IF lnRow = 0
         RETURN
      ENDIF
      ADEL(this.aItems,lnRow)
   ENDIF
   THIS.Count = THIS.Count - 1
ENDFUNC

************************************************************************
* wwNameValueCollection ::  UpdateItem
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION UpdateItem(lvKey,lvValue)

IF VARTYPE(lvKey) = "N"
  this.aItems[lvKey,2]= lvValue
ELSE
  LOCAL lnRow
  lnRow = this.GetIndex(lvKey)
  IF lnRow = 0
     RETURN .F.
  ENDIF
  this.aItems[lnRow, 2] =  lvValue
ENDIF

ENDFUNC
*  wwNameValueCollection ::  UpdateItem

************************************************************************
* wwNameValueCollection :: Clear
****************************************
***  Function:
***    Assume:
***      Pass: llComplete - forces each item to be nulled explicitly
***    Return:
************************************************************************
FUNCTION Clear(llComplete)
LOCAL lnX

IF llComplete
	FOR lnX = 1 TO this.Count
		this.aItems[lnX,2] = null		
	ENDFOR
ENDIF	

THIS.Count = 0
THIS.aItems = .f.
this.aItems = null

ENDFUNC
*  wwCollection :: Clear

************************************************************************
* wwNameValueCollection :: ToAttributeString
****************************************
***  Function: Loops through name value pairs and creates attribute
***            strings
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ToAttributeString(lcSeparator)
LOCAL lnX, lcOutput
lcOutput = ""

IF EMPTY(lcSeparator)
  lcSeparator = " "
ENDIF

FOR lnX = 1 TO THIS.Count
   lcOutput = lcOutput + this.aItems[lnX,1] + [="] + TRANSFORM(this.aItems[lnX,2]) + ["] + lcSeparator
ENDFOR 

RETURN lcOutput
ENDFUNC
*  wwNameValueCollection :: ToAttributeString


FUNCTION Dispose
THIS.aItems=null
ENDFUNC

FUNCTION Destroy
THIS.aItems=null
ENDFUNC

ENDDEFINE

*************************************************************
DEFINE CLASS wwStack AS WWC_WWCOLLECTION
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 08/20/2005
*************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class wwStack

*:Description:

*:Example:

*:Remarks:

*:SeeAlso:


*:ENDHELP
#ENDIF

*** Custom Properties
nStackPointer = 0

*** Stock Properties
************************************************************************
* wwStack :: Push
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Push(lvValue)
THIS.Add(lvValue)
ENDFUNC
*  wwStack :: Push

************************************************************************
* wwStack :: Pop
****************************************
***  Function: Pops an item off the stack
***    Assume:
***      Pass:
***    Return: value of the last item on the stack. Null if stack is empty
************************************************************************
FUNCTION Pop()
LOCAL lvValue

IF THIS.Count < 1
   RETURN null
ENDIF

lvValue = THIS.aItems[THIS.Count]
THIS.Remove(THIS.Count)

RETURN lvValue
ENDFUNC
*  wwStack :: Pop

************************************************************************
* wwStack :: Peek
****************************************
***  Function: Returns the last item without popping it off the stack
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Peek()
LOCAL lvValue

IF THIS.Count < 1
   RETURN null
ENDIF

lvValue = THIS.aItems[THIS.Count]

RETURN lvValue
ENDFUNC
*  wwStack :: Peek

*** Hide Other Collection methods
PROTECTED FUNCTION Add(lvValue)
DODEFAULT(lvValue)
ENDFUNC


PROTECTED FUNCTION Remove(lnIndex)
DODEFAULT(lnIndex)
ENDFUNC

ENDDEFINE
*EOC wwStack 



*** wwBusiness Related Collections

*************************************************************
DEFINE CLASS wwValidationError AS Custom
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 11/16/2005
*************************************************************
*** Custom Properties

*** Stock Properties

*** The Error Message for the validation Error
cMessage  = ""

*** Optional name of the object it applies to
cObjectName = ""

ENDDEFINE

*************************************************************
DEFINE CLASS wwValidationErrors AS wwCollection
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2005
*:Contact: http://www.west-wind.com
*:Created: 11/16/2005
*************************************************************

************************************************************************
*  AddError
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION AddError(lcMessage,lcField)
LOCAL loError

loError = CREATEOBJECT("wwValidationError")

lcType = VARTYPE(lcMessage)
IF lcType = "L"
   RETURN
ENDIF   

IF lcType = "O"
   this.Add(lcMessage)
   RETURN
ENDIF

loError.cMessage = lcMessage
IF !EMPTY(lcField) 
   loError.cObjectName = lcField
ENDIF   

THIS.Add(loError)
ENDFUNC
*   AddError

************************************************************************
*  Add
****************************************
***  Function: Adds validation errors from another source to this 
***            validation error instance.
***    Assume: Object passed is also of wwValidationErrors
***      Pass: loErrors   - wwValidationErrors object
***    Return: nothing
************************************************************************
FUNCTION AddErrors(loErrors)
LOCAL lnX, loError

FOR lnX = 1 TO loErrors.Count
   loError = loErrors.aItems[lnX]
   this.AddError(loError)
ENDFOR   

ENDFUNC
*   AddErrors


************************************************************************
* wwValidationErrors :: ToString
****************************************
***  Function: Turns the Validation Errors into a string
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ToString()
LOCAL lcOutput, lnX

lcOutput = ""
FOR lnX = 1 TO this.Count
   IF lnX < this.Count
      lcOutput = lcOutput + this.aItems[lnX].cMessage + CHR(13) + CHR(10)
   ELSE
      lcOutput = lcOutput + this.aItems[lnX].cMessage 
   ENDIF   
ENDFOR

RETURN lcOutput
ENDFUNC

************************************************************************
*  ToHtml
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ToHtml(llAddName)

lcOutput = "<ul>" + CRLF

FOR lnX = 1 TO this.Count
   lcObjectName = this.aItems[lnX].cObjectName   
   
   lcOutput = lcOutput + [<li><a href="javascript:{}" onclick="document.getElementById(']+ lcObjectName + [').focus();">] + this.aItems[lnX].cMessage + ;
   						 IIF(llAddName," for " + PROPER( STRTRAN(lcObjectName,"_"," ") ),"") +;
                         "</a></li>" + CRLF  
ENDFOR

lcOutput = lcOutput + "</ul>" + CRLF

RETURN lcOutput
ENDFUNC
*   ToHtml

ENDDEFINE
