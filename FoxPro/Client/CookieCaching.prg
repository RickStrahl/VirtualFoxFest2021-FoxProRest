*** This request demonstrates that cookies are cached
*** across requests, and executions
DO wwHttp

LOCAL loHttp as wwHttp
loHttp = CREATEOBJECT("wwHttp")
? "Read: " + loHttp.Get("http://localhost:5200/ReadCookie.wwd")


? loHttp.Get("http://localhost:5200/SetCookie.wwd")

? 
? loHttp.Get("http://localhost:5200/ReadCookie.wwd")
? loHttp.Get("http://localhost:5200/ReadCookie.wwd")