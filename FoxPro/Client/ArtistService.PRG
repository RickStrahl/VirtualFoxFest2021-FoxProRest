DO wwhttp
DO wwJsonSerializer
SET PROCEDURE TO artistService ADDITIVE

*************************************************************
DEFINE CLASS ArtistService AS wwJsonServiceClient
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2021
*:Contact: http://www.west-wind.com
*:Created: 9/26/2021
*************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class ArtistService

*:Description:

*:Example:

*:Remarks:

*:SeeAlso:


*:ENDHELP
#ENDIF

*** Custom Properties

*** This allows easy switching to other servers
cServiceBaseUrl = "https://albumviewer.west-wind.com/"

*** AUTHENTICATION 

cBearerToken = ""
cUsername = ""
cPassword = ""

*** Stock Properties
************************************************************************
*  Init
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Init(lcBaseUrl, lcUsername, lcPassword)

IF !EMPTY(lcBaseUrl)   
   this.cServiceBaseUrl = RTRIM(lcBaseUrl,"/") + "/"
ENDIF
IF !EMPTY(lcUserName)
   this.cUsername = lcUsername
ENDIF
IF !EMPTY(lcPassword)
  this.cPassword = lcPassword
ENDIF

ENDFUNC
*   Init

************************************************************************
*  Authenticate
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Authenticate(lcUsername, lcPassword)

IF EMPTY(lcUsername) AND EMPTY(lcPassword)
   lcUsername = this.cUsername
   lcPassword = this.cPassword
ENDIF
IF EMPTY(lcUsername) AND EMPTY(lcPassword)
   this.cErrorMsg = "Username and password cannot be empty."
   RETURN .F.
ENDIF

loLogin = CREATEOBJECT("EMPTY")
ADDPROPERTY(loLogin, "userName", lcUsername)
ADDPROPERTY(loLogin, "password", lcPassword)

loAuth = this.CallService(this.cServiceBaseUrl + "api/authenticate",loLogin,"POST")
IF this.lError
   RETURN .F.
ENDIF

THIS.cBearerToken = loAuth.Token
RETURN .T.
ENDFUNC
*   Authenticate

************************************************************************
*  GetArtists
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetArtists()
LOCAL loArtists
  
loArtists =  this.CallService( this.cServiceBaseurl + "api/artists")
IF this.lError
   RETURN NULL
ENDIF
  
RETURN loArtists
ENDFUNC
*   GetArtists

************************************************************************
*  GetArtist
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetArtist(lnId)
LOCAL loArtist

loArtist = this.CallService( this.cServiceBaseUrl + "api/artist/" + TRANSFORM(lnId) )
IF THIS.lError
   RETURN NULL
ENDIF   

RETURN loArtist
ENDFUNC
*   GetArtist


************************************************************************
*  UpdateArtist
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION UpdateArtist(loArtist)
LOCAL loUpdated  

IF EMPTY(THIS.cBearerToken)
  IF !this.Authenticate()
     RETURN NULL
  ENDIF
ENDIF

IF THIS.lError
   RETURN NULL
ENDIF

THIS.Addheader("Authorization", "Bearer " + this.cBearerToken)
loUpdated = THIS.CallService( THIS.cServiceBaseUrl + "api/artist", loArtist, "POST")
IF this.lError 
   RETURN NULL
ENDIF   

RETURN loUpdated
ENDFUNC
*   UpdateArtist

ENDDEFINE
*EOC ArtistService 