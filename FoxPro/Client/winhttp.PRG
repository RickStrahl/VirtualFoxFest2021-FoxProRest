************************************************************************
*  WinHttp
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION WinHttp(lcUrl, lcVerb, lcPostData, lcContentType)
LOCAL lcResult

*** FOR DEMOS ONLY!
IF EMPTY(lcUrl) 
   lcUrl = "https://albumviewer.west-wind.com/api/artist/1"
   RETURN null
ENDIF
IF EMPTY(lcVerb)
   lcVerb = "GET"
   IF !EMPTY(lcPostData)
      lcVerb = "POST"
   ENDIF
ENDIF   

*** Example of using simplistic WinHttp client to retreive HTTP content
LOCAL loHttp as WinHttp.WinHttpRequest.5.1, lcResult
loHTTP = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")    

loHTTP.Open(lcVerb, lcUrl,.F.)

IF !EMPTY(lcContentType) AND lcVerb = "POST" OR lcVerb = "PUT" 
	loHttp.SetRequestHeader("Content-Type",lcContentType)
ENDIF	

*** If using POST you can post content as a parameter
IF !EMPTY(lcPostData)
	loHTTP.Send(lcPostData)
ELSE
   loHttp.Send()	
ENDIF

lcResult = loHttp.ResponseText

loHttp = NULL

RETURN lcResult
