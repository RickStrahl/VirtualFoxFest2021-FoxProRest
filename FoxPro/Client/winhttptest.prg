CLEAR
SET PROCEDURE TO WinHttp ADDITIVE

lcResult = WinHttp("https://albumviewer.west-wind.com/api/artist/1")
? PADR(lcResult,1000)
?
?

TEXT TO lcJson NOSHOW
{
  "username": "test",
  "password": "test"
}
ENDTEXT

lcResult = WinHttp("https://albumviewer.west-wind.com/api/authenticate","POST",lcJson,"application/json")
? lcResult  