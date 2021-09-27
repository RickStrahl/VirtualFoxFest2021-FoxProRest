************************************************************************
*PROCEDURE MusicStoreProcess
****************************
***  Function: Processes incoming Web Requests for MusicStoreProcess
***            requests. This function is called from the wwServer 
***            process.
***      Pass: loServer -   wwServer object reference
*************************************************************************
LPARAMETER loServer
LOCAL loProcess
PRIVATE Request, Response, Server, Session, Process
STORE NULL TO Request, Response, Server, Session, Process

#INCLUDE WCONNECT.H

loProcess = CREATEOBJECT("MusicStoreProcess", loServer)
loProcess.lShowRequestData = loServer.lShowRequestData

IF VARTYPE(loProcess)#"O"
   *** All we can do is return...
   RETURN .F.
ENDIF

*** Call the Process Method that handles the request
loProcess.Process()

*** Explicitly force process class to release
loProcess.Dispose()

RETURN

*************************************************************
DEFINE CLASS MusicStoreProcess AS WWC_RESTPROCESS
*************************************************************

*** Response class used - override as needed
cResponseClass = [WWC_PAGERESPONSE]

*** Default for page script processing if no method exists
*** 1 - MVC Template (ExpandTemplate()) 
*** 2 - Web Control Framework Pages
*** 3 - MVC Script (ExpandScript())
nPageScriptMode = 3

*!* cAuthenticationMode = "UserSecurity"  && `Basic` is default


*** ADD PROCESS CLASS EXTENSIONS ABOVE - DO NOT MOVE THIS LINE ***


#IF .F.
* Intellisense for THIS
LOCAL THIS as MusicStoreProcess OF MusicStoreProcess.prg
#ENDIF
 
*********************************************************************
* Function MusicStoreProcess :: OnProcessInit
************************************
*** If you need to hook up generic functionality that occurs on
*** every hit against this process class , implement this method.
*********************************************************************
FUNCTION OnProcessInit

*!* LOCAL lcScriptName, llForceLogin
*!*	THIS.InitSession("MyApp")
*!*
*!*	lcScriptName = LOWER(JUSTFNAME(Request.GetPhysicalPath()))
*!*	llIgnoreLoginRequest = INLIST(lcScriptName,"default","login","logout")
*!*
*!*	IF !THIS.Authenticate("any","",llIgnoreLoginRequest) 
*!*	   IF !llIgnoreLoginRequest
*!*		  RETURN .F.
*!*	   ENDIF
*!*	ENDIF

*** Explicitly specify that pages should encode to UTF-8 
*** Assume all form and query request data is UTF-8
Response.Encoding = "UTF8"
Request.lUtf8Encoding = .T.


*** Add CORS header to allow cross-site access from other domains/mobile devices on Ajax calls
*!* Response.AppendHeader("Access-Control-Allow-Origin","*")
*!* Response.AppendHeader("Access-Control-Allow-Origin",Request.ServerVariables("HTTP_ORIGIN"))
*!* Response.AppendHeader("Access-Control-Allow-Methods","POST, GET, DELETE, PUT, OPTIONS")
*!* Response.AppendHeader("Access-Control-Allow-Headers","Content-Type, *")
*!* *** Allow cookies and auth headers
*!* Response.AppendHeader("Access-Control-Allow-Credentials","true")
*!* 
*!* *** CORS headers are requested with OPTION by XHR clients. OPTIONS returns no content
*!*	lcVerb = Request.GetHttpVerb()
*!*	IF (lcVerb == "OPTIONS")
*!*	   *** Just exit with CORS headers set
*!*	   *** Required to make CORS work from Mobile devices
*!*	   RETURN .F.
*!*	ENDIF   

RETURN .T.
ENDFUNC


*********************************************************************
FUNCTION TestPage
***********************
LPARAMETERS lvParm
*** Any posted JSON string is automatically deserialized
*** into a FoxPro object or value

#IF .F. 
* Intellisense for intrinsic objects
LOCAL Request as wwRequest, Response as wwPageResponse, Server as wwServer, ;
      Process as wwProcess, Session as wwSession
#ENDIF

*** Simply create objects, collections, values and return them
*** they are automatically serialized to JSON
loObject = CREATEOBJECT("EMPTY")
ADDPROPERTY(loObject,"name","TestPage")
ADDPROPERTY(loObject,"description",;
            "This is a JSON API method that returns an object.")
ADDPROPERTY(loObject,"entered",DATETIME())

*** To get proper case you have to override property names
*** otherwise all properties are serialized as lower case in JSON
Serializer.PropertyNameOverrides = "Name,Description,Entered"


RETURN loObject

*** To return a cursor use this string result:
*!* RETURN "cursor:TCustomers"


*** To return a raw Response result (non JSON) use:
*!*	JsonService.IsRawResponse = .T.   && use Response output
*!*	Response.ExpandScript()
*!*	RETURN                            && ignored

ENDFUNC


*********************************************************************
FUNCTION HelloScript()
***********************

SELECT TOP 10 time, script, querystr, verb, remoteaddr ;
  FROM wwRequestLog  ;
  INTO CURSOR TRequests ;
  ORDER BY Time Desc

loObj = CREATEOBJECT("EMPTY")

*** Simple Properties
ADDPROPERTY(loObj,"message","Surprise!!! This is not a script response! Instead we'll return you a cursor as a JSON result.")
ADDPROPERTY(loObj,"requestName","Recent Requests")
ADDPROPERTY(loObj,"recordCount",_Tally)

*** Nested Cursor Result as an Array
ADDPROPERTY(loObj,"recentRequests","cursor:TRequests")

*** Normalize property names for case sensitivity
Serializer.PropertyNameOverrides = "requestName,recentRequests,recordCount,"

RETURN loObj
ENDFUNC



*************************************************************
*** PUT YOUR OWN CUSTOM METHODS HERE                      
*** 
*** Any method added to this class becomes accessible
*** as an HTTP endpoint with MethodName.Extension where
*** .Extension is your scriptmap. If your scriptmap is .rs
*** and you have a function called Helloworld your
*** endpoint handler becomes HelloWorld.rs
*************************************************************


************************************************************************
*  Artists
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Artists()

loArtistBus = CREATEOBJECT("cArtist")
lnArtistCount = loArtistBus.GetArtistList()

Serializer.PropertyNameOverrides = "artistName,imageUrl,amazonUrl,albumCount,"

RETURN "cursor:TArtists"
ENDFUNC

************************************************************************
*  Artist
****************************************
***  Function: Displays or updates/adds an artist
***    Assume: 
***      Pass: loArtist - for POST and PUT operations
***    Return: JSON of Artist
************************************************************************
FUNCTION Artist(loArtist)
LOCAL lnId, lcVerb, loArtistBus

lnId = VAL(Request.QueryString("id"))
lcVerb = Request.GetHttpVerb()

if (lcVerb == "POST" or lcVerb == "PUT")
   RETURN this.UpdateArtist(loArtist)   
ENDIF   

IF lcVerb = "DELETE"
   loArtistBus = CREATEOBJECT("cArtist")   
   RETURN loArtistBus.Delete(lnId)  && .T. or .F.
ENDIF

*** GET Operation
IF lnId == 0
  RETURN this.ErrorResponse("Invalid Artist Id","404 Not Found")  
ENDIF

loArtistBus = CREATEOBJECT("cArtist")
IF !loArtistBus.Load(lnId)   
    RETURN this.ErrorResponse("Artist not found.","404 Not Found")
ENDIF 

*** Lazy load the albums
loArtistBus.LoadAlbums()

Serializer.PropertyNameOverrides = "artistName,imageUrl,amazonUrl,albumCount,albumPk, artistPk,songName,unitPrice,"

return loArtistBus.oData 
ENDFUNC


************************************************************************
*  UpdateArtist
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION UpdateArtist(loArtist)

IF VARTYPE(loArtist) # "O"
	ERROR "Invalid data passed."
ENDIF

lnPk = loArtist.pk

loBusArtist = CREATEOBJECT("cArtist")
IF lnPk = 0
	loBusArtist.New()
ELSE
	IF !loBusArtist.Load(lnPk)
	   ERROR "Invalid Artist Id."
	ENDIF
ENDIF 

*** Update just the main properties
loArt = loBusArtist.oData
loArt.Descript = loArtist.Descript
loArt.ArtistName = loArtist.ArtistName
loArt.ImageUrl = loArtist.ImageUrl
loArt.AmazonUrl = loArtist.AmazonUrl

*** Items are not updated in this sample
*** Have to manually update each item or delete/add

IF !loBusArtist.Validate() OR ! loBusArtist.Save()
    ERROR loBusArtist.cErrorMsg
ENDIF

loBusArtist.LoadAlbums()

Serializer.PropertyNameOverrides = "artistName,imageUrl,amazonUrl,albumCount,albumPk, artistPk,songName,unitPrice,"

RETURN loArt
ENDFUNC
*   UpdateArtist






************************************************************************
*  Albums
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Albums()
LOCAL loBusAlbum, loAlbums

loBusAlbum = CREATEOBJECT("cAlbum")
loAlbums = null

*** Load albums individually and then load
*** related artist and songs via bus object
*** this way we get a nested JSON structure
IF loBusAlbum.GetAlbumPkList() > -1
   loAlbums = CREATEOBJECT("Collection")
   SCAN
   	   loBusAlbum.Load(TAlbums.Pk)    
   	   loAlbums.Add(loBusAlbum.oData)
   ENDSCAN
   USE IN TAlbums
ENDIF

Serializer.PropertyNameOverrides = "artistName,imageUrl,amazonUrl,albumCount,albumPk, artistPk,songName,unitPrice,"

RETURN loAlbums
ENDFUNC
*   Albums

************************************************************************
*  Album
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Album(loAlbum)

lcVerb = Request.GetHttpVerb()

*** Handle alternate verbs with same URL with
*** separate method since we don't have method overloading in VFP
IF (lcVerb == "POST" OR lcVerb == "PUT")
	RETURN THIS.SaveAlbum(loAlbum)
ENDIF

IF lcVerb == "DELETE"
   RETURN this.DeleteAlbum()
ENDIF   

lnId = VAL(Request.QueryString("id"))
IF (lnId < 1)
   RETURN this.ErrorResponse("Invalid album id","401 Not Found")
ENDIF

loBusAlbum = CREATEOBJECT("cAlbum")
IF (!loBusAlbum.Load(lnId))
   RETURN this.ErrorResponse(loBusAlbum.cErrorMsg,"401 Not Found")
ENDIF

Serializer.PropertyNameOverrides = "artistName,imageUrl,amazonUrl,albumCount,albumPk, artistPk,songName,unitPrice,"

RETURN loBusAlbum.oData
ENDFUNC
*   Album

************************************************************************
*  SaveAlbum
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION SaveAlbum(loAlbum)
LOCAL lnId, album, loBusAlbum

IF VARTYPE(loAlbum) # "O"
   ERROR "No album provided to save."
ENDIF   

lnId = loAlbum.pk

loBusAlbum = CREATEOBJECT("cAlbum")

IF (lnId < 1 OR !loBusAlbum.Load(lnId))
   *** Create new instance
   loBusAlbum.New()
   lnId = loBusAlbum.oData.Pk
ENDIF

loBusAlbum.oData = loAlbum
loBusAlbum.oData.Pk = lnId

IF !loBusAlbum.Validate()
   ERROR loBusAlbum.cErrorMsg
ENDIF

IF !loBusAlbum.Save()
   ERROR "Unable to save album"
ENDIF

*** Return the album with update data
RETURN loBusAlbum.oData
ENDFUNC
*   SaveAlbum

************************************************************************
*  DeleteAlbum
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION DeleteAlbum()

lnId = VAL(Request.QueryString("id"))

loBusAlbum = CREATEOBJECT("cAlbum")
IF !loBusAlbum.Delete(lnId)
   ERROR loBusAlbum.cErrorMsg
ENDIF

RETURN .T.
ENDFUNC
*   DeleteAlbum





ENDDEFINE