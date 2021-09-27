CLEAR
DO wwHttp

loHttp = CREATEOBJECT("wwHttp")
lcResult = loHttp.Get("https://albumviewer.west-wind.com/api/artist/1")
*ShowJson(lcResult)
? PADR(lcResult,1200)
?
?

TEXT TO lcJson NOSHOW
{
  "username": "test",
  "password": "test"
}
ENDTEXT

loHttp = CREATEOBJECT("wwHttp")
loHttp.cContentType = "application/json"
lcResult = loHttp.Post("https://albumviewer.west-wind.com/api/authenticate",lcJson)

IF loHttp.nError # 0
   ? loHttp.cErrorMsg
   RETURN
ENDIF
IF loHttp.cResultcode # "200"
   ? "Invalid HTTP response code: " + loHttp.cResultCode
ENDIF   

? lcResult  