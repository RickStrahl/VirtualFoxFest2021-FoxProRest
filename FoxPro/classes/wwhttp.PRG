#INCLUDE "wconnect.h"

*** Load Library
SET PROCEDURE TO wwHTTP ADDITIVE

** Load Dependencies
SET PROCEDURE TO wwUtils ADDITIVE
SET PROCEDURE TO wwAPI ADDITIVE


*** Also required:
* wwipstuff.dll  (UrlEncoding and Async operation only)
* zlib1.dll  (for GZIP content only)

*************************************************************
DEFINE CLASS wwHTTP AS Custom 
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2000
*:Contact: http://www.west-wind.com
*************************************************************
#IF .F.
*:Help Documentation
*:Topic:
Class wwHTTP

*:Description:
A standalone HTTP client library. Same HTTP interfaces
as wwIPStuff, but provided here for lighter environment.

*:Example:

*:Remarks:
Requires wwIPStuff.dll for URLEncoding and Decoding of 
strings larger than 80 characters.

*:SeeAlso:

*:ENDHELP
#ENDIF
**************************************************************
PROTECTED cdllpath
cDllPath = ""

*** Last Error Message Text for the last operation. Implemented only for SMTP and HTTP operations.
cErrorMsg = ""

*** Password to log on to server (applies to FTP and HTTP)
cPassword = ""

*** Username for log in operations (FTP and HTTP).
cUsername = ""

*** Determines whether SSL is used
lSecureLink = .F.

*** Connection timeout for Connection, Send and Read operations
*** if any take longer than the number of seconds here operation will abort
nConnectTimeout = 30

PROTECTED hIPSession, hhttpsession
hhttpsession = 0
hipsession = 0

*** The last error code.
nError = 0

*** Allows to specify how the connection is opened: 1 - Direct, 3 - Proxy (IE 4 and later) and 0 - PreConfig (using IE settings)*
nHttpConnectType = 0

*** HTTP Server Address. Format: www.west-wind.com, or 111.111.111.111
cServer = ""

*** HTTP Link to visit on a site. Site relative URL. Example: /default.asp, /, /wconnect.dll?wwDemo~TestPage
cLink = ""

*** Optional property to allow overriding the HTTP Verb. Defaults to empty
*** which auto-determines between GET and POST depending on whether POST 
*** data is provided
*** Use this option to set other verbs PUT,DELETE etc.
cHttpVerb = ""


*** HTTP Post mode determines how requests are posted to the server. 
*** 1 - Form URLEncoded (default)  2 - Multipart forms. 4 - XML or raw buffer This property must be set prior to calling AddPostKey and HTTPGetEx
nHttpPostmode = 1

*** The port to use for HTTP Connections. If the default value of 0 is used, the HTTP and HTTPS default ports (80 and 443) are used.
nHttpPort = 0

*** Size of the download HTTP buffer used while downloading dynamically sized requests with HTTPGetEx. This is the size of chunks that will be pulled at a time and also determines how often OnHTTPBufferUpdate is called.
nHttpWorkBuffersize = 65556

*** Any extra headers to send to the server. 
cExtraHeaders = ""

*** Any response HTTP headers returned by the request from the server
cHttpHeaders = ""

*** The Content Size based on the HTTP header. Set while reading the header at the
*** beginning of the request. Note this can be 0 if the server is chunking output
*** and isn't returning a content-length.
nContentSize = 0

*** Flag that can be set in OnHTTPBufferUpdate to allow cancellation of the current HTTP download
lHttpCancelDownload = .F.

*** The content type of any data to be posted to the server. 
cContentType = ""

*** The POST buffer used internally 
cPostBuffer = ""

*** Set this flag to .T. if you plan on uploading
*** files or data >16mb
lUseLargePostBuffer = .F.

*** Large Post BUffer Stream
oPostStream = null
FUNCTION oPostStream_Access()
	IF ISNULL(THIS.oPostStream)
	  THIS.oPostStream = CREATEOBJECT("wwFileStream")
	ENDIF
	RETURN this.oPostStream
ENDFUNC	
	
*** Version of the wwIPStuff library. This value should match the DLL Version number.
cversion = TRANSFORM(WWVERSION_NUMBER)

*** The browser name (User Agent) that wwHTTP sends to the server
cUserAgent = "West Wind Internet Protocols " + TRANSFORM(WWVERSION_NUMBER)

*** String that specifies the name or IP address of the proxy server and its port.
cHttpProxyName = ""

*** Address of a string variable that contains an optional list of host names or IP addresses, or both, that should not be routed through the proxy
chttpproxybypass = ""

*** Proxy Authentication info (make sure you use nHTTPConnectType=3)
cHttpProxyUserName = ""
cHttpProxyPassword = ""

*** Optional flags used for InternetOpen calls.
nServiceFlags = 0
nHttpServiceFlags = 0

*** if .T. ignores sercurity certificate warnings
lIgnoreCertificateWarnings = .F.

*** Client certificate index to use
nClientCertNumberIndex = 0

*** The HTTP result code returned by this response - 200, 500, 404 etc.
cResultCode = "" 

cResultCodeMessage = ""

*** Determines whether GET requests cached - defaults to not
lCacheRequest = .F.

*** If .T. allows GZip content to be requested. Requires ZLib1.dll
lAllowGZip = .F.

*** Decodes UTF 8 when true
lDecodeUtf8 = .T.


************************************************************************
* wwHTTP :: Init
*********************************
***  Function: Loads the DLL
***      Pass: lcPath  -  Path where to find the DLL. If "" is used
***                       SYSTEM path or local is assumed. Path must
***                       be terminated with a trailing backslash
************************************************************************
FUNCTION Init
LPARAMETER lcPath

#IF SHAREWARE
   WAIT WINDOW NOWAIT ;
      "Welcome to West Wind Client Tools." + CHR(13) + ;
      "This is a shareware copy of wwHTTP." + CHR(13)+ CHR(13) +;
      "Please register your copy."
#ENDIF

lcPath=IIF(VARTYPE(lcPath)="C",lcPath,"")

THIS.cdllpath=lcPath+"wwIPStuff.dll"

DECLARE INTEGER GetLastError;
   IN WIN32API

IF !EMPTY(lcPath)
	DO PATH WITH lcPath
ENDIF

RETURN


************************************************************************
* wwHTTP :: AddPostKey
*********************************
***  Function: Adds POST variables to the HTTP request
***    Assume: depends on nHTTPPostMode setting
***      Pass: 
***    Return:
************************************************************************
FUNCTION AddPostKey(tcKey as string, tcValue as string,;
                    llFileName as Boolean,  ;
                    lcContentType as string, lcExtraHeaders as string,;
                    lcFileName  as string) as void
LOCAL lcOldAlias
tcKey=IIF(VARTYPE(tcKey)="C",tcKey,"")

IF tcKey="RESET" OR PCOUNT() = 0
   IF THIS.lUseLargePostBuffer
	   IF !ISNULL(THIS.oPostStream)
	   	   this.oPostStream.Clear()
	   ENDIF
   ELSE
	   THIS.cPostBuffer = ""
   ENDIF
   
   RETURN
ENDIF

*** If we post a raw buffer swap parms
IF PCOUNT() < 2
   tcValue = tcKey
   tcKey = ""
ENDIF

*** Force to string
IF(VARTYPE(tcValue)!="C")
  tcValue = TRANSFORM(tcValue)
ENDIF

IF !THIS.lUseLargePostBuffer

	IF !EMPTY(tcKey)
	   DO CASE
	    *** Url Encoded
	    CASE THIS.nhttppostmode = 1         
	         THIS.cPostBuffer = this.cPostBuffer + IIF(!EMPTY(this.cPostBuffer),"&","") + ;
	                            tcKey +"="+ URLEncode(tcValue) 
	      *** Multi-part formvars and file
	    CASE this.nHttpPostMode = 2
	    
	      IF !EMPTY(lcExtraHeaders)
	      	 lcExtraHeaders = RTRIM(lcExtraHeaders,0,CHR(13),CHR(10)," ") + CRLF
	      ELSE
	         lcExtraHeaders = ""
	      ENDIF
	      
	      *** Check for File Flag -  HTTP File Upload - Second parm is filename
	      IF llFileName
	         IF EMPTY(lcFilename)
  	            lcFilename = LOWER(JUSTFNAME(tcValue))
  	         ENDIF
	      
	      	 THIS.cPostBuffer = THIS.cPostBuffer + "--" + MULTIPART_BOUNDARY + CRLF + ;
	            [Content-Disposition: form-data; name="]+tcKey+["; filename="] + lcFileName + ["]+CRLF
	         IF !EMPTY(lcContentType)
	            this.cPostBuffer =	this.cPostBuffer + "Content-Type: " + lcContentType + CRLF + lcExtraHeaders
	         ENDIF
	         this.cPostBuffer = this.cPostBuffer + CRLF
		     this.cPostBuffer = this.cPostBuffer + FILETOSTR(FULLPATH(tcValue))
		     this.cPostBuffer = this.cPostBuffer + CRLF
	      ELSE
	         IF !EMPTY(lcFilename)
	            lcFilename = [; filename="] + lcFilename + ["]
	         ELSE
	            lcFilename = ""
	         ENDIF
	         
	      	 this.cPostBuffer = this.cPostBuffer +"--" + MULTIPART_BOUNDARY + CRLF + ;
	            [Content-Disposition: form-data; name="]+ tcKey+ ["] +  lcFilename + CRLF
	         IF !EMPTY(lcContentType)
	            this.cPostBuffer =	this.cPostBuffer + "Content-Type: " + lcContentType + CRLF + lcExtraHeaders
	         ENDIF
	         this.cPostBuffer = this.cPostBuffer + CRLF
	         this.cPostBuffer = this.cPostBuffer + tcValue + CRLF
	      ENDIF
	   ENDCASE
	ELSE
	   *** If there's no Key post the raw buffer
	   this.cPostBuffer = this.cPostBuffer +tcValue
	ENDIF
ELSE
	IF !EMPTY(tcKey)
	   DO CASE
	    *** Url Encoded
	    CASE THIS.nhttppostmode = 1         
	         THIS.oPostStream.Write(IIF(!EMPTY(this.cPostBuffer),"&","") + ;
	                            tcKey +"="+ URLEncode(tcValue) )
	      *** Multi-part formvars and file
	    CASE this.nHttpPostMode = 2	    
	      IF !EMPTY(lcExtraHeaders)
	      	 lcExtraHeaders = RTRIM(lcExtraHeaders,0,CHR(13),CHR(10)," ") + CRLF
	      ELSE
	         lcExtraHeaders = ""
	      ENDIF	    	
	      
	      *** Check for File Flag -  HTTP File Upload - Second parm is filename
	      IF llFileName
	      	 THIS.oPostStream.Write( "--" + MULTIPART_BOUNDARY + CRLF + ;
	            [Content-Disposition: form-data; name="]+tcKey+["; filename="] + LOWER(JUSTFNAME(tcValue)) + ["]+CRLF)
	         IF !EMPTY(lcContentType)
	            THIS.oPostStream.Write( "Content-Type: " + lcContentType + CRLF + lcExtraHeaders)
	         ENDIF
	         
	         
	         THIS.oPostStream.Write(CRLF)
		     THIS.oPostStream.Write( FILETOSTR(FULLPATH(tcValue)) )
		     THIS.oPostStream.Write(CRLF)
	      ELSE
	      	 THIS.oPostStream.Write("--" + MULTIPART_BOUNDARY + CRLF + ;
	            [Content-Disposition: form-data; name="]+tcKey+["]+CRLF)
	         IF !EMPTY(lcContentType)
	            THIS.oPostStream.Write("Content-Type: " + lcContentType + CRLF + lcExtraHeaders)
	         ENDIF
	         THIS.oPostStream.Write(CRLF)
	         THIS.oPostStream.Write(tcValue + CRLF)
	      ENDIF
	   ENDCASE
	ELSE
	   *** If there's no Key post the raw buffer
	   THIS.oPostStream.Write(tcValue)
	ENDIF
ENDIF
ENDFUNC


************************************************************************
* wwHttp ::  AddPostFile
****************************************
***  Function: Explicit function to upload a file. Forwards to 
***            AddPostKey but makes it more obvious we're sending
***            a file.
***    Assume: expects nHttpPostMode = 2
***      Pass:
***    Return:
************************************************************************
FUNCTION AddPostFile(lcKey, lcFileOrFileData, llIsFile, lcFilename, lcContentType, lcExtraHeaders)
IF !this.nHttpPostMode = 2
   ERROR "You can't post a file unless nHttpPostMode = 2"
ENDIF
this.AddPostKey(lcKey, lcFileOrFileData, llIsFile, lcContentType, lcExtraHeaders, lcFilename)
ENDFUNC
*  wwHttp ::  AddPostFile



************************************************************************
* wwHttp :: AddHeader
****************************************
***  Function: Adds an HTTP to the HTTP request.
***    Assume:
***      Pass: lcKey   -   Header key
***            lcValue -   Value for the header as string
************************************************************************
FUNCTION AddHeader(lcKey, lcValue)

lnParmCount = PCOUNT()

DO CASE
  CASE lnParmCount = 0 OR EMPTY(lcKEY)
      this.cExtraheaders = ""
  CASE lnParmCount = 1
      this.cExtraHeaders = this.cExtraHeaders + lcKey + CRLF   
  OTHERWISE
      this.cExtraHeaders = this.cExtraHeaders + lcKey + ": " + lcValue + CRLF
ENDCASE

ENDFUNC
*  wwHttp :: AddHeader

************************************************************************
* wwhttp ::  AppendHeader
****************************************
***  Function: Provided for common naming similar to .NET same as
***            AddHeader().
***      Pass: lcKey   -   Header key
***            lcValue -   Value for the header as string
************************************************************************
FUNCTION AppendHeader(lcKey, lcValue)
RETURN this.AddHeader(lcKey, lcValue)
ENDFUNC
*  wwhttp ::  AppendHeader

************************************************************************
* wwHttp ::  GetHttpHeader
****************************************
***  Function: Retrieves an HTTP header after an HTTP call has been 
***            made.
***    Assume:
***      Pass: lcHeader - the name of hte header to retrieve
***    Return:
************************************************************************
FUNCTION GetHttpHeader(lcHeader)
RETURN ALLTRIM(Extract(this.cHttpHeaders, lcHeader + ":",CHR(13)))
ENDFUNC
*  wwHttp ::  GetHttpHeader



********************************************************
* wwHTTP :: HTTPConnect
*********************************
***  Function: Connect to an HTTP server.
***    Assume: Sets two handle values in this class Each
***            instance of this class can only manage
***            one HTTP session at a time. Use this low
***            level function for quick repeated access
***            to HTTP pages.
***      Pass: lcServer   - Server name
***            lcUsername - Optional Username
***            lcPassword - Optional Password
***            llHTTPS    - .T. for secure connections
***    Return: 0 on success or WinAPI Errorcode
********************************************************
FUNCTION HTTPConnect
LPARAMETER lcServer, lcUserName, lcPassword, llHTTPS
LOCAL lhIP, lhHTTP, lnError, lnHTTPPort

this.cResultCode = ""
this.cHttpHeaders = ""

lcServer=TRIM(IIF(!EMPTY(lcServer),lcServer,THIS.cserver))
THIS.cserver = lcServer
lcServer = LOWER(lcServer)
lcUserName=TRIM(IIF(!EMPTY(lcUserName),lcUserName,THIS.cusername))
lcPassword=TRIM(IIF(!EMPTY(lcPassword),lcPassword,THIS.cpassword))

*** Strip out HTTP:// prefix since this is a common error
IF lcServer = "http://"
   lcServer = STRTRAN(lcServer,"http://","")
ENDIF

IF ATC("http:",lcServer) > 0
   This.nError = -1
   THIS.cerrormsg="You must provide a server name (ie. www.somedomain or 111.111.111.121), not a URL."
   RETURN -1
ENDIF

*** Assign Default Ports
IF THIS.nhttpport = 0
   lnHTTPPort = IIF(llHTTPS or THIS.lSecureLink,;
                    INTERNET_DEFAULT_HTTPS_PORT,;
                    INTERNET_DEFAULT_HTTP_PORT)
ELSE
   lnHTTPPort = THIS.nhttpport
ENDIF

THIS.lsecurelink = llHTTPS OR THIS.lsecurelink

THIS.nerror=0
THIS.cerrormsg=""

DECLARE INTEGER InternetCloseHandle ;
   IN WinInet.DLL ;
   INTEGER

DECLARE INTEGER GetLastError;
   IN WIN32API

DECLARE INTEGER InternetOpen ;
   IN WININET.DLL ;
   STRING,;
   INTEGER,;
   STRING, STRING, INTEGER
   
DECLARE INTEGER InternetSetOption ;
   IN WININET.DLL ;
   INTEGER HINTERNET,;
   INTEGER dwFlags,;
   INTEGER @dwValue,;
   INTEGER dwSize

*** Force to Proxy Operation
IF !EMPTY(THIS.cHttpProxyName)
   THIS.nHTTPConnectType = 3  && Proxy
ENDIF

hInetConnection=;
   InternetOpen(THIS.cUserAgent,;
   THIS.nhttpconnecttype,;
   THIS.chttpproxyname,THIS.chttpproxybypass,0)

IF hInetConnection = 0
   THIS.nerror=GetLastError()
   THIS.cerrormsg=THIS.getsystemerrormsg(THIS.nerror)
   RETURN THIS.nerror
ENDIF

THIS.hipsession=hInetConnection

DECLARE INTEGER InternetConnect ;
   IN WININET.DLL ;
   INTEGER hIPHandle,;
   STRING lpzServer,;
   INTEGER dwPort, ;
   STRING lpzUserName,;
   STRING lpzPassword,;
   INTEGER dwServiceFlags,;
   INTEGER dwFlags,;
   INTEGER dwReserved


lhHTTPSession=;
   InternetConnect(hInetConnection,;
   lcServer,;
   lnHTTPPort,;
   lcUserName,;
   lcPassword,;
   INTERNET_SERVICE_HTTP,;
   THIS.nserviceflags,0)


IF (lhHTTPSession = 0)
   =InternetCloseHandle(hInetConnection)
   THIS.nerror = GetLastError()
   THIS.cerrormsg = THIS.getsystemerrormsg()
   RETURN THIS.nerror
ENDIF

THIS.hhttpsession = lhHTTPSession

RETURN 0


********************************************************
* wwHTTP :: HTTPClose
*********************************
***  Function: Closes an HTTP Session.
***    Return: nothing
********************************************************
FUNCTION httpclose

DECLARE INTEGER InternetCloseHandle ;
   IN WININET.DLL ;
   INTEGER hIPSession

*** Always clear the POST buffer after a request
IF THIS.lUseLargePostBuffer
	this.oPostStream.Clear()
ENDIF
this.cPostBuffer = ""

IF THIS.hHTTPSession # 0
  InternetCloseHandle(THIS.hhttpsession)
  THIS.hhttpsession=0
ENDIF
IF THIS.hipSession # 0
  InternetCloseHandle(THIS.hipsession)
  THIS.hipsession=0
ENDIF

ENDFUNC

************************************************************************
* wwHTTP :: HTTPGet
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION HTTPGet()
LPARAMETERS lcUrl, lcUserName, lcPassword, lcOutputFile
LOCAL lnError, lnSize, lcBuffer, szHead, loUrl, llHTTPS, lnResult,;
   hInetConnection, hHTTPResult

this.cResultCode = ""

*** Handle www.west-wind.com without http:// prefix
IF ATC("http://",lcUrl) < 1 AND ATC("https://",lcUrl) < 1
   lcUrl = "http://" + lcUrl
ENDIF   

THIS.nerror = 0
THIS.cerrormsg = ""

IF VARTYPE(lcUserName) = "N"
   tnBufferSize=lcUserName
   lcUserName = ""
   lcPassword = ""
ELSE
   tnBufferSize = 0
   lcUserName=IIF(EMPTY(lcUserName),"",lcUserName)
   lcPassword=IIF(EMPTY(lcPassword),"",lcPassword)
ENDIF


loUrl = THIS.InternetCrackUrl(lcUrl)
IF VARTYPE(loUrl) # "O" 
   THIS.nError = -1
   THIS.cerrormsg = "Invalid URL passed."
   RETURN ""
ENDIF

llHTTPS = IIF(LOWER(loUrl.cProtocol)="https",.T.,.F.)
this.lSecureLink = llHttps
THIS.nHttpPort=VAL(loUrl.cPort)

lnResult = THIS.HTTPConnect(loUrl.cserver,lcUserName,lcPassword,llHTTPS)
IF lnResult # 0
   RETURN ""
ENDIF

IF tnBufferSize # 0
   lcData=SPACE(tnBufferSize)
   lnSize=tnBufferSize
ELSE
   lcData = ""
   lnSize = 0
ENDIF

lnResult = THIS.HTTPGetEx(loUrl.cPath + loUrl.cQueryString,@lcData,@lnSize,,lcOutputFile)

THIS.HTTPClose()

RETURN lcData
ENDFUNC


************************************************************************
* wwHttp ::  Get
****************************************
FUNCTION Get(lcUrl, lcOutputFile)
THIS.cHttpVerb = ""
THIS.nHttpPostMode = 1
RETURN this.HttpGet(lcUrl,"","",lcOutputFile)
*  wwHttp :: Get

************************************************************************
* wwHttp ::  Post
****************************************
FUNCTION Post(lcUrl, lcPostData, lcOutputFile)
IF (this.nHttpPostMode # 2)
   this.cHttpVerb = "POST"
ENDIF
IF (!IsNullOrEmpty(lcPostData))
   THIS.ClearPostBuffer()
   THIS.AddPostKey(lcPostData)
ENDIF   
RETURN this.HttpGet(lcUrl,"","",lcOutputFile)
*  wwHttp :: Post

************************************************************************
* wwHttp ::  Put
****************************************
FUNCTION Put(lcUrl, lcPostData, lcOutputFile)
THIS.cHttpVerb = "PUT"
IF (!IsNullOrEmpty(lcPostData))
   THIS.ClearPostBuffer()
   THIS.AddPostKey(lcPostData)
ENDIF 
RETURN this.HttpGet(lcUrl,"","",lcOutputFile)
*  wwHttp :: Put

************************************************************************
* wwHttp ::  Delete
****************************************
FUNCTION Delete(lcUrl, lcOutputFile)
this.cHttpVerb = "DELETE"
RETURN this.HttpGet(lcUrl,"","",lcOutputFile)
*  wwHttp :: Delete


********************************************************
* wwHTTP :: HTTPGetEx
*********************************
***  Function: Retrieves an HTTP request from the
***            network and returns a string. Read an
***            HTML or data file across the net.
***    Assume: Blocking call - waits for completion
***            before returning. Use AddPostKey
***            to post data to server
***            Must call HTTPConnect/HTTPClose to
***            manage connection to Server.
***      Pass: tcURL        - URL to retrieve
***            tcBuffer     - HTTP result (by Reference)
***            tnBufferSize - Size of the buffer (ref)
***            tcHeaders    - HTTP Headers sent from
***                           client request. Separate
***                           key:value pairs with CRLF
***            tcFileName   - Optional filename to save
***                           content to to avoid keeping
***                           the entire content in memory
***    Return: WinAPI Error Code (check THIS.cErrorMsg)
*******************************************************
FUNCTION HTTPGetEx(tcPage, tcBuffer, tnBufferSize, tcHeaders, tcFileName)
LOCAL hHTTPResult, lcOldAlias, lhFile, lcVerb

tcPage=IIF(EMPTY(tcPage),THIS.clink,tcPage)
tnBufferSize=IIF(VARTYPE(tnBufferSize)="N",;
   tnBufferSize,LEN(tcBuffer))

lcOldAlias=ALIAS()

IF THIS.lAllowGZip
	this.AppendHeader("Accept-Encoding","gzip")
ENDIF

IF EMPTY(tcHeaders)
   tcHeaders = this.cExtraHeaders 
ENDIF   

IF ATC("http:",This.cServer) > 0
   This.nError = -1
   THIS.cerrormsg="You must provide a server name (ie. www.somedomain or 111.111.111.121), not a URL."
   RETURN -1
ENDIF

THIS.lhttpcanceldownload = .F.
this.nContentSize = 0

THIS.clink = tcPage

THIS.nerror=0
THIS.cerrormsg=""

*** Force ignoring of Offline Mode
this.SetOption(THIS.hhttpsession,INTERNET_OPTION_IGNORE_OFFLINE,1)

DECLARE INTEGER HttpOpenRequest ;
   IN WININET.DLL ;
   INTEGER hHTTPHandle,;
   STRING lpzReqMethod,;
   STRING lpzPage,;
   STRING lpzVersion,;
   STRING lpzReferer,;
   STRING lpzAcceptTypes,;
   INTEGER dwFlags,;
   INTEGER dwContextw

*** Keep alive must be used for Proxies
IF !This.lCacheRequest AND (!EMPTY(THIS.cHTTPProxyName) OR this.nHTTPConnectType = 3)
   THIS.nHTTPServiceFlags = THIS.nHTTPServiceFlags + INTERNET_FLAG_KEEP_CONNECTION 
ENDIF

*** Create an empty stream if none exists just so code doesn't bonk

*** Set the verb if none is set
IF EMPTY(this.cHttpVerb)
    IF THIS.lUseLargePostBuffer
   		lcVerb = IIF( this.oPostStream.nLength > 0, "POST","GET")
   	else
		lcVerb = IIF( !EMPTY(this.cPostBuffer), "POST","GET")
	ENDIF
ELSE
	lcVerb = this.cHttpVerb
ENDIF	

hHTTPResult=HttpOpenRequest(THIS.hhttpsession,;
   lcVerb,;
   tcPage,;
   NULL,NULL,NULL,;
   INTERNET_FLAG_RELOAD + ;
   IIF(THIS.lsecurelink,INTERNET_FLAG_SECURE,0) + ;
   this.nHTTPServiceFlags,0) 

*** Reset the HttpVerb
this.cHttpVerb = ""

IF (hHTTPResult = 0)
   THIS.nerror=GetLastError()
   THIS.cerrormsg=THIS.getsystemerrormsg()
   RETURN THIS.nerror
ENDIF

*** Apply timeout to the HTTP connection handle
THIS.wininetsettimeout(THIS.nConnectTimeOut,hHTTPResult)
THIS.wininetsettimeout(THIS.nConnectTimeOut)

*** This shouldn't be necessary
* THIS.hhttpsession=hHTTPResult

IF this.lIgnoreCertificateWarnings
	this.SetOption(hHttpResult,;
				   INTERNET_OPTION_SECURITY_FLAGS,;
                   SECURITY_FLAG_IGNORE_UNKNOWN_CA + ;
	               SECURITY_FLAG_IGNORE_CERT_DATE_INVALID  +;
	               SECURITY_FLAG_IGNORE_CERT_CN_INVALID + ;
	               SECURITY_FLAG_IGNORE_REVOCATION +;
	               SECURITY_FLAG_IGNORE_WRONG_USAGE)
ENDIF

THIS.OnHttpPostConnect(hHTTPResult)


DECLARE INTEGER HttpSendRequest    ;
   IN WININET.DLL ;
   INTEGER hHTTPHandle,;
   STRING lpzHeaders,;
   INTEGER cbHeaders,;
   STRING lpzPost,;
   INTEGER cbPost


LOCAL llHasPostData
llHasPostData = .F.
IF !this.lUseLargePostBuffer
   llHasPostData = !EMPTY(this.cPostBuffer)
ELSE
   IF !ISNULL(this.oPostStream) AND FSEEK(this.oPostStream.nHandle,0,1) > 0
      llHasPostData = .T.
   ENDIF
ENDIF

IF llHasPostData
   DO CASE
      *** Explicit content type overrides manual content type
      CASE !EMPTY(this.cContentType)
		 	tcHeaders = "Content-Type: " + this.cContentType + CRLF + tcHeaders      
      CASE THIS.nhttppostmode = 1
         tcHeaders = "Content-Type: application/x-www-form-urlencoded"  + CRLF +;
            IIF(!EMPTY(tcHeaders),CRLF+tcHeaders,"")
      CASE THIS.nhttppostmode = 2
         tcHeaders = "Content-Type: multipart/form-data; boundary=" + MULTIPART_BOUNDARY + CRLF + CRLF +;
            IIF(EMPTY(tcHeaders),"",tcHeaders)

		 *** Add ending content bounda
         *** NOTE: leading and trailing extra two dashes required!
         IF !THIS.lUseLargePostBuffer
			 this.cPostBuffer = this.cPostBuffer +"--" + MULTIPART_BOUNDARY + "--"  + CRLF
		 ELSE			 
			 this.oPostStream.Write("--" + MULTIPART_BOUNDARY + "--"  + CRLF)
		 ENDIF
         
      OTHERWISE      && CASE THIS.nhttppostmode = 4  && XML or Raw
         tcHeaders = "Content-Type: text/xml" + CRLF + tcHeaders		 
   ENDCASE
ELSE
   tcHeaders =  IIF(!EMPTY(tcHeaders),tcHeaders,"")
ENDIF


IF !EMPTY(THIS.cHTTPProxyUserName)
  IF !THIS.SetProxyLogin()
      RETURN THIS.nError
  ENDIF
ENDIF

lnRetval=0

LOCAL llLoop
llLoop = .T.
DO WHILE llLoop
	llLoop = .F. && Exit loop
	this.nError = 0
	
	if(this.lUseLargePostBuffer)
	   this.cPostBuffer = this.oPostStream.ToString()
	   THIS.oPostStream.Clear()
	ENDIF
	
	lnRetval=HttpSendRequest(hHTTPResult,;
	   tcHeaders,LEN(tcHeaders),;
	   this.cPostBuffer,LEN(this.cPostBuffer))

	IF lnRetval = 0
	   THIS.nerror=GetLastError()

	   IF this.nError = 12044 && ERROR_INTERNET_CLIENT_AUTH_CERT_NEEDED
			***  http://www.codeguru.com/cpp/i-n/internet/generalinternet/article.php/c3367
			lnCertNo = this.nClientCertNumberIndex   && the certificate to find by its numeric 0 based order - no API to get cert list

*** For debugging you can uncomment this code to see all certs available				
*!*				DECLARE integer InternetErrorDlg IN WinInet.dll ;
*!*					integer hWindow,;
*!*					integer hInternet,;
*!*					integer hRequest,;
*!*					integer uiflags,;
*!*					DWORD lppvData
*!*			
*!*				lnResult = InternetErrorDlg(_Screen.HWnd,hHttpResult,12044,0x04 + 0x01 + 0x02,0)			
			
	   		DECLARE INTEGER InternetSetOption IN WinInet.dll integer, integer, integer @, integer
			*** INTERNET_OPTION_SECURITY_SELECT_CLIENT_CERT = 47 && 12047
	   		InternetSetOption(hHttpResult,47,@lnCertNo,4)
	   		llLoop = .T.
	   		LOOP  && retry now
	   ENDIF
	   
	   THIS.cerrormsg=THIS.getsystemerrormsg()
	   =InternetCloseHandle(hHTTPResult)
	   RETURN THIS.nerror
	ENDIF
ENDDO

*** This code doesn't work as you need to use HttpSendRequestEx()
*** which requires structures that can't be passed easily from
*** VFP because they are nested. As it stands there are no message
*** events provided to the client. All POST operations are synchronous.
*!*   IF !EMPTY(lcPostBuffer)
*!*      lnWritten = 0
*!*      DECLARE integer InternetWriteFile IN WinInet.dll ;
*!*         INTEGER HttpHandle,STRING PostBuffer,INTEGER PostSize,INTEGER  @Written
*!*      lnRetval = InternetWriteFile(hHttpResult,lcPostBuffer,tnPostSize,@lnWritten)
*!*      IF lnRetval = 0
*!*         THIS.nerror=GetLastError()
*!*         THIS.cerrormsg=THIS.getsystemerrormsg()
*!*         =InternetCloseHandle(hHTTPResult)
*!*         RETURN THIS.nerror
*!*      ENDIF
*!*   ENDIF   


DECLARE INTEGER HttpQueryInfo ;
   IN WININET.DLL ;
   INTEGER hHTTPHandle,;
   INTEGER nType,;
   STRING @cHeaders,;
   INTEGER @cbHeaderSize,;
   STRING cNULL

*** Retrieve the HTTP Headers
lcHeaders = SPACE(2048)
lnHeaderSize = 2048
lnRetval = HttpQueryInfo(hHTTPResult,;
   HTTP_QUERY_RAW_HEADERS_CRLF,;
   @lcHeaders,@lnHeaderSize,NULL)
THIS.chttpheaders = TRIM(STRTRAN(lcHeaders,CHR(0),""))
  

*** Check the HTTP Result Code
lcHeaders = SPACE(7)
lnHeaderSize = 6
lnRetval = HttpQueryInfo(hHTTPResult,;
   HTTP_QUERY_STATUS_CODE,;
   @lcHeaders,@lnHeaderSize,NULL)
THIS.cResultCode = TRIM(STRTRAN(lcHeaders,CHR(0),""))


IF !EMPTY(this.cHttpHeaders)
	THIS.nContentSize = ;
    	 VAL( EXTRACT(this.cHttpHeaders,CHR(13)+CHR(10) + "Content-length: ",CHR(13)) )
ENDIF     

LOCAL lnHttpBufferSize
lnHttpBufferSize = THIS.nhttpworkbuffersize 

*** Dynamically set the buffersize up to the max buffer size
IF THIS.nContentSize > 0
	lnHttpBufferSize = this.nContentSize + 4
	IF THIS.nhttpworkbuffersize > 0 AND lnHttpBufferSize > THIS.nhttpworkbuffersize
	   lnHttpBufferSize = THIS.nhttpworkbuffersize
	ENDIF
ENDIF

*** Call HTTP Event method
THIS.OnHTTPBufferUpdate(0,0,THIS.chttpheaders,THIS)

DECLARE INTEGER InternetReadFile ;
   IN WININET.DLL ;
   INTEGER hHTTPHandle,;
   STRING @lcBuffer,;
   INTEGER cbBuffer,;
   INTEGER @cbBuffer


IF tnBufferSize > 0
   *** Use Fixed Buffer Size
   tcBuffer=SPACE(tnBufferSize)
   lnBufferSize=tnBufferSize
   lnRetval=InternetReadFile(hHTTPResult,;
      @tcBuffer,;
      tnBufferSize,;
      @tnBufferSize)
ELSE
   *** If a filename was specified output to the file instead of string
   IF !EMPTY(tcFileName)
      lhFile = FCREATE(tcFileName)
      IF lhFile = -1
         THIS.nerror=1
         THIS.cerrormsg="Couldn't create output file"
         =InternetCloseHandle(hHTTPResult)
         RETURN THIS.nerror
      ENDIF
   ENDIF

   *** Build the buffer dynamically
   tcBuffer = ""
   tnSize = 0
   lnRetval = 0
   lnBytesRead = 1
   lnBufferReads = 0

   *** Use a new buffer var so we can go over 16mb in size
   *** tcBuffer is passed by ref and it fails at 16mb
   *** assign after instead
   LOCAL lcBuffer
   lcBuffer = ""
   
   DO WHILE .T.
      lcReadBuffer = SPACE(lnHttpBufferSize)
      lnBytesRead = 0
      lnSize = LEN(lcReadBuffer)

      lnRetval=InternetReadFile(hHTTPResult,;
         @lcReadBuffer,;
         lnSize,;
         @lnBytesRead)

      IF lnRetval = 1 AND lnBytesRead > 0
         *** Update the input parameters - result buffer and size of buffer
         IF EMPTY(tcFileName)
            *** Build string
            lcT = LEFT(lcReadBuffer,lnBytesRead)
            lcBuffer = lcBuffer + lcT
         ELSE
            *** Write to file
            FWRITE(lhFile,lcReadBuffer,lnBytesRead)
         ENDIF
         
         tnBufferSize = tnBufferSize + lnBytesRead
         lnBufferReads = lnBufferReads + 1
         
         THIS.OnHTTPBufferUpdate(tnBufferSize,lnBufferReads,lcReadBuffer,THIS)
      ENDIF
      IF THIS.lhttpcanceldownload
         lcBuffer = "Error: Download canceled"
         tnBufferSize = LEN(lcBuffer)
         THIS.nError = -2
         THIS.cErrorMsg = "Download Cancelled"
         EXIT
      ENDIF
      IF (lnRetval = 1 AND lnBytesRead = 0) OR (lnRetval = 0)
         EXIT
      ENDIF
   ENDDO
   lnBufferSize = tnBufferSize

   tcBuffer = lcBuffer
   lcBuffer = ""

   IF !EMPTY(tcFileName)
      FCLOSE(lhFile)
   ENDIF

   THIS.OnHTTPBufferUpdate(0,-1,"",THIS)

ENDIF


IF lnRetval = 0
   THIS.nerror=GetLastError()
   THIS.cerrormsg=THIS.getsystemerrormsg()
ENDIF

*** REQUEST STATUS ERROR HANDLING
*** - Check for error codes on HTTP errors
***   Any status code > 399 is considered an error
***   We set lError and cErrorMsg
***   But we return the full response
IF THIS.nError = 0 AND this.cResultCode > "399"
   this.nError = VAL(this.cResultCode)
   this.cErrorMsg = this.cResultCodeMessage
ENDIF

InternetCloseHandle(hHTTPResult);

tcBuffer = (IIF(tnBufferSize > 0 AND tnBufferSize <= lnBufferSize,SUBSTR(tcBuffer,1,tnBufferSize),""))

IF this.lAllowGzip AND ATC("Content-Encoding: gzip",this.cHttpHeaders) >0
	tcBuffer = GzipUncompressString(tcBuffer)
ENDIF
IF this.lDecodeUtf8 AND ATC("charset=utf-8",this.cHttpHeaders) > 0
   tcBuffer = STRCONV(tcBuffer,11)
ENDIF


RETURN THIS.nerror
ENDFUNC
* HttpGetEx

************************************************************************
* wwHTTP :: HTTPGetAsync
*********************************
***  Function: Sends an HTTP request but doesn't wait for completion.
***            You can use this one for stress testing. Each request
***            fires off a new thread so make sure you let the
***            thread count catch up before overrunning your machine.
***            Why - use for stress testing.
***      Pass: lcUrl   -    Location to open
***    Return: nothing
************************************************************************
FUNCTION HttpGetAsync(lcUrl)
lcUrl=IIF(!EMPTY(lcUrl),lcUrl,"")

DECLARE INTEGER HTTPGetAsync ;
   IN (THIS.cDLLPath) ;
   STRING cURL
HTTPGetAsync(lcUrl)
RETURN



********************************************************
* wwHTTP :: HTTPGetExAsync
*********************************
***  Function: Retrieves an HTTP request from the
***            network asynchronously. This means the
***            request fires and returns immediately
***            without an error code. Operation runs on
***            new thread in the background after returing
***            control to VFP.
***
***            This method is fully self contained.
***            You don't need to call HTTPOpen or HTTPClose.
***
***            This method allows full configuration
***            of the request with: POST data, SSL,
***            Passwords and creation of an output
***            file.
***
***            Use AddPostKey to add POST vars. Use lSecureLink
***            to enable SSL operation. Use cUserName and cPassword
***            for passwords.
***
***            Output file option allows for async
***            downloads and later checking for a result.
***            Using a timer it's possible to fire 'events'
***            when the download is complete.
***
***      Pass: tcURL        - Server relative link (/default.asp)
***            tcResultFile - File where result get stored to
***                           Make sure this is file unique...
***            tnResultSize - If you're saving the result you
***                           can use this to specify the size
***                           Default is a small 256 (used for
***                           not checking results).
***      Used: lSecureLink, cUserName, cPassword, AddPostKey()
***    Return: nothing
***            If tcResultFile is passed you can check
***            for this file. On success you'll get the
***            document. On failure you get:
***            Error: <nAPIErrorCode>
*******************************************************
FUNCTION HttpGetExasync
LPARAMETERS tcPage, tcResultFile, tnResultSize, tcHeaders, tnSecondsBeforeDelete
LOCAL hHTTPResult

*** Post Buffer and lSecureLink also apply via properties
tcServer=THIS.cserver
tcPage=IIF(EMPTY(tcPage),"/",tcPage)
tcUserName=THIS.cusername
tcPassword=THIS.cpassword
tcResultFile=IIF(EMPTY(tcResultFile),"",tcResultFile)
tnResultSize=IIF(EMPTY(tnResultSize),256,tnResultSize)
tnSecondsBeforeDelete = IIF(EMPTY(tnSecondsBeforeDelete),0,tnSecondsBeforeDelete)


IF THIS.lUseLargePostBuffer
   this.cPostBuffer = this.oPostStream.ToString()
   THIS.oPostStream.Clear()
ENDIF

IF !EMPTY(this.cPostBuffer)
   IF EMPTY(tcHeaders)
      IF THIS.nhttppostmode = 1
         tcHeaders = "Content-Type: application/x-www-form-urlencoded"  + CRLF+;
            IIF(!EMPTY(tcHeaders),CRLF+tcHeaders,"")
      ENDIF
      IF this.nHttpPostMode = 2
         tcHeaders = "Content-Type: multipart/form-data; boundary=" + MULTIPART_BOUNDARY + CRLF + CRLF +;
            IIF(EMPTY(tcHeaders),"",tcHeaders)
         
         IF !EMPTY(this.cPostBuffer)
            this.cPostBuffer = this.cPostBuffer + MULTIPART_BOUNDARY + CRLF 
         ENDIF
      ENDIF
   ENDIF
ELSE
   tcHeaders =  IIF(!EMPTY(tcHeaders),tcHeaders,"")
ENDIF

lcOldAlias=ALIAS()

DECLARE INTEGER HTTPGetExAsync ;
   IN WWIPSTUFF.DLL ;
   INTEGER hInternet,;
   INTEGER hHTTP,;
   STRING SERVER,;
   STRING PAGE,;
   STRING BUFFER,;
   INTEGER BufferSize,;
   STRING HEADER,;
   STRING POST,;
   INTEGER POSTSIZE,;
   INTEGER SECURE,;
   INTEGER CONNECTTYPE,;
   STRING Username, STRING PASSWORD,;
   STRING ResultFile,;
   INTEGER ResultSize,;
   INTEGER DeleteFileSeconds

tcBuffer = SPACE(256)
tnBufSize = LEN(tcBuffer)-1
lnRet = HTTPGetExAsync(THIS.hipsession, THIS.hhttpsession,;
   tcServer,;
   tcPage,;
   tcBuffer,tnBufSize,;
   tcHeaders,;
   this.cPostBuffer, LEN(this.cPostBuffer),;
   IIF(THIS.lsecurelink,1,0),;
   THIS.nhttpconnecttype,;
   tcUserName, tcPassword,;
   tcResultFile,tnResultSize, tnSecondsBeforeDelete)

*** Cause HTTPClose() to have no effect on these
*** handles - the C thread code will clean these up
THIS.hIPSession = 0
THIS.hHTTPSession = 0

RETURN


************************************************************************
* wwHttp :: HTTPGetHeader
*********************************
***  Function: Retrieves just the HTTP header of a page request.
***    Assume: Must call HTTPConnect/HTTPClose to manage connection
***            to Server
***      Pass: tcPage    -    The Server relative page to view
***            tcHeader  -    Buffer to receive headers (by reference)
***            tnSize    -    Size of the Buffer (by Reference)
***    Return: Win32API Error Code
************************************************************************
FUNCTION HTTPGetHeader
LPARAMETERS lcUrl, lcUserName, lcPassword
LOCAL lnError, lnSize, lcBuffer, lcHeaders

IF EMPTY(lcUsername)
  lcUsername = ""
ENDIF
IF EMPTY(lcPassword)
  lcPassword = ""
ENDIF

THIS.nError = 0


LOCAL loUrl, llHttps, lnResult
loUrl = THIS.InternetCrackUrl(lcUrl)
IF VARTYPE(loUrl) # "O" 
   THIS.nError = -1
   THIS.cerrormsg = "Invalid URL passed."
   RETURN ""
ENDIF

llHTTPS = IIF(LOWER(loUrl.cProtocol)="https",.T.,.F.)
this.lSecureLink = llHttps
THIS.nHttpPort=VAL(loUrl.cPort)

lnResult = THIS.HTTPConnect(loUrl.cserver,lcUsername,lcPassword,llHTTPS)
IF lnResult # 0
   RETURN ""
ENDIF

DECLARE INTEGER HttpOpenRequest ;
   IN WININET.DLL ;
   INTEGER hHTTPHandle,;
   STRING lpzReqMethod,;
   STRING lpzPage,;
   STRING lpzVersion,;
   STRING lpzReferer,;
   STRING lpzAcceptTypes,;
   INTEGER dwFlags,;
   INTEGER dwContextw

hHTTPResult=HttpOpenRequest(THIS.hHTTPSession,;
   "HEAD",;
   loUrl.cPath + loUrl.cQueryString,;
   NULL,NULL,NULL,;
   INTERNET_FLAG_RELOAD + IIF(THIS.lSecureLink,INTERNET_FLAG_SECURE,0),0)


IF (hHTTPResult = 0)
   THIS.nError=GetLastError()
   THIS.cErrorMsg=THIS.GetSystemErrorMsg()
   InternetCloseHandle(hHttpResult)	
   this.HttpClose()
   RETURN THIS.nError
ENDIF


DECLARE INTEGER HttpSendRequest    ;
   IN WININET.DLL ;
   INTEGER hHTTPHandle,;
   STRING lpzHeaders,;
   INTEGER cbHeaders,;
   STRING lpzPost,;
   INTEGER cbPost


lcHeaders = TRIM(this.cExtraHeaders)

*** send request without POST buffer
lnRetval=HttpSendRequest(hHTTPResult,;
   lcHeaders,LEN(lcHeaders),;
   NULL,0)

IF lnRetval = 0
   THIS.nError=GetLastError()
   THIS.cErrorMsg=THIS.GetSystemErrorMsg()
   InternetCloseHandle(hHttpResult)	
   this.HttpClose()
   RETURN THIS.nError
ENDIF

DECLARE INTEGER HttpQueryInfo ;
   IN WININET.DLL ;
   INTEGER hHTTPHandle,;
   INTEGER nType,;
   STRING @cHeaders,;
   INTEGER @cbHeaderSize,;
   STRING cNULL


*** Capture the headers
lcHeaders = SPACE(50000)
lnHeaderSize = LEN(lcHeaders)
lnRetval = HttpQueryInfo(hHTTPResult,;
   HTTP_QUERY_RAW_HEADERS_CRLF,;
   @lcHeaders,@lnHeaderSize,NULL)

IF (lnRetval = 0)
   THIS.nError=GetLastError()
   THIS.cErrorMsg=THIS.GetSystemErrorMsg()
   RETURN THIS.nError
ENDIF

InternetCloseHandle(hHTTPResult)
this.HttpClose()

tcHeaders = (IIF(lnHeaderSize > 1,SUBSTR(lcHeaders,1,lnHeaderSize-1),""))

this.cHttpHeaders = tcHeaders

RETURN tcHeaders


FUNCTION OnHttpPostConnect
LPARAMETERS lnHTTPHandle
ENDFUNC

*** Gets called whenever the buffer is updated on an HTTPGetEx update. Only applies if the buffer size is set to 0 (Automatic sizing)
FUNCTION OnHTTPBufferUpdate
   LPARAMETER lnBytesDownloaded,lnBufferReads,lcCurrentChunk, loHTTP
ENDFUNC


*** Cancels an HTTPGetEx download if the buffer is sized dynamically
FUNCTION httpcanceldownload
   THIS.lhttpcanceldownload = .T.
ENDFUNC


************************************************************************
* wwHTTP :: UnZipFiles
*********************************
***  Function: Unzips files to a specified directory
***    Assume: Requires DynaZip DLLs (dunzip32.dll)
***      Pass: lcZipFile
***            lcDestination  -  Dir to unzip to
***            lcFileSpec     -  Files to unzip (*.*)
***    Return: DynaZip Error Code or 0 on success
************************************************************************
FUNCTION UnZipFiles
LPARAMETERS lcZipFile, lcDestination, lcFileSpec
* Defer to wwUtils UnzipFiles
RETURN UnzipFiles(lcZipFile,lcDestination,lcFileSpec)
ENDFUNC
* wwHTTP :: UnZipFiles

************************************************************************
* wwHTTP :: ZipFiles
*********************************
***  Function: Zips files
***    Assume: Function requires DynaZip DLLs (dzip32.dll)
***      Pass: lcZipFile   - Fully qualified ZIP file name 
***            lcFileList  - Comma Delimited file list (Wildcards OK)
***    Return: DynaZip error code or 0
************************************************************************
FUNCTION ZipFiles
LPARAMETERS lcZipFile, lcFileList, lnCompression, llRecurse
* defer to wwUtils ZipFiles
RETURN ZipFiles(lcZipFile,lcFileList,lnCompression,llRecurse)
ENDFUNC
* wwHTTP :: ZipFiles


************************************************************************
* wwHTTP :: DecodeDBF
*********************************
FUNCTION DecodeDBF
LPARAMETERS lcBuffer,lcDBF
* defer to wwUtils DecodeDbf
RETURN DecodeDbf(@lcBuffer,lcDbf)
ENDFUNC
* wwHTTP :: DecodeDBF


********************************************************
* wwHTTP :: EncodeDBF
*********************************
FUNCTION EncodeDBF
LPARAMETERS lcDBF, llHasMemo, lcEncodedName
* defer to wwAPI::EncodeDbf
RETURN EncodeDbf(lcDbf,llHasMemo,lcEncodedName)
* eof EncodeDbf
  


************************************************************************
* wwHTTP :: SetProxyLogin
****************************************
***  Function: Sets the HTTP Proxy username and password
***      Pass: tcUserName
***            tcPassword
***            hIPHandle   - HTTP Request handle (optional)
***    Return: .T. or .F.
************************************************************************
PROTECTED FUNCTION SetProxyLogin(tcUserName, tcPassword, hIPHandle)
LOCAL lcUsername, lcPassword, lpBuffer, lpdwBufferLength, nSuccess

lcUserName = IIF(!EMPTY(tcUserName),tcUserName,THIS.cHTTPProxyUserName)
lcPassword = IIF(!EMPTY(tcPassword),tcPassword,THIS.cHTTPProxyPassword)

*hIPHandle = IIF(EMPTY(hIPHandle),THIS.hHTTPSession,hIPHandle)
hIPHandle = IIF(EMPTY(hIPHandle),THIS.hIpSession,hIPHandle)

IF EMPTY(lcUsername)
   RETURN
ENDIF   

DECLARE INTEGER InternetSetOption IN WinInet.dll ;
    INTEGER hInternet, ;
    INTEGER dwOption, ;
    STRING @lpBuffer, ;
    LONG lpdwBufferLength

INTERNET_OPTION_PROXY_USERNAME = 43
INTERNET_OPTION_PROXY_PASSWORD = 44

IF !EMPTY(lcUserName)
    lpBuffer = lcUserName + CHR(0)
    dwBufferLength = LEN(lpBuffer) 
    dwOption = INTERNET_OPTION_PROXY_USERNAME
    nSuccess = InternetSetOption(hIPHandle, dwOption, @lpBuffer, dwBufferLength)
    IF nSuccess <> 1
         THIS.nError = GetLastError()
         THIS.cErrorMsg = THIS.GetSystemErrorMsg(THIS.nError)
         RETURN .F.
     ENDIF
ENDIF

IF !EMPTY(lcPassword)
   lpBuffer = lcpassword + CHR(0)
   dwBufferLength = LEN(lpBuffer) 
   dwOption = INTERNET_OPTION_PROXY_PASSWORD
   nSuccess = InternetSetOption(hIPHandle, dwOption, @lpBuffer, dwBufferLength)
   IF nSuccess <> 1
      THIS.nError = GetLastError()
      THIS.cErrorMsg = THIS.GetSystemErrorMsg(THIS.nError)
      RETURN .F.
   ENDIF
ENDIF

RETURN .T.
ENDFUNC


************************************************************************
* wwHTTP ::  SetOption
****************************************
***  Function: Sets an Internet Option for a given Id.
***    Assume: This option only works with numeric values
***      Pass:
***    Return:
************************************************************************
FUNCTION SetOption(lnHandle,lnOptionId,lnOptionValue)
LOCAL lnResult

DECLARE INTEGER InternetSetOption ;
   IN WININET.DLL ;
   INTEGER HINTERNET,;
   INTEGER dwFlags,;
   INTEGER @dwValue,;
   INTEGER cbSize

*** Set needed SSL flags
lnResult=InternetSetOption(lnHandle,;
   lnOptionId ,;
   @lnOptionValue ,4)

IF lnResult = 1
   RETURN .t.
ENDIF

RETURN .F.   
ENDFUNC
*  wwHTTP ::  SetOption


************************************************************************
* wwHTTP :: HTTPPing
****************************************
***  Function: Checks whether a site is up by a timeout value
***    Assume: IE 5.5 or later is installed
***      Pass: lnTimeout   -   in seconds
***            lcUrl       -   http://www.west-wind.com/somepage.htm
***    Return:
************************************************************************
FUNCTION httpping
LPARAMETER lnTimeout, lcUrl, lcLink
LOCAL lcFile, llSuccess, lnHandle

IF EMPTY(lcLink)
   lcLink = "/"
ENDIF
IF EMPTY(lcUrl)
   RETURN .F.
ENDIF
   
lcUrl = LOWER(lcUrl)

lnSaveTimeout = THIS.nConnectTimeout
THIS.nConnectTimeout = lnTimeout

IF STARTSWITH(lcUrl,"http")
   *** Processing a full Url
   lcResult = this.HttpGet(lcUrl)
ELSE   
   lcResult = THIS.HTTPGet("http://" + lcServer + lcLink)
ENDIF

THIS.nConnectTimeout = lnSaveTimeout

IF THIS.nError = 0 AND this.cResultCode < "400"
   RETURN .T.
ENDIF

RETURN .F.


************************************************************************
* wwHTTP :: InternetCrackUrl
*********************************
***  Function: Breaks out a URL into its component pieces
***      Pass: lcURL  -  URL to crack
***    Return: loUrl  or NULL
************************************************************************
FUNCTION InternetCrackUrl(tcUrl)
LOCAL lnAT, lcProtocol, lcQuerystring, lcPort, lcServer

*** QueryString
lnAT = AT("?", tcURL)
IF lnAT > 0 THEN
	lcQuerystring = SUBSTR(tcURL, lnAT)
	tcURL = LEFT(tcURL, lnAT-1)
ELSE
	lcQuerystring = ""
ENDIF

*** Protocol
lnAT = AT("://", tcURL)
IF lnAT < 1 THEN
	tcURL = "http://" + tcURL
	lnAT = AT("://", tcURL)
ENDIF
lcProtocol = LOWER(LEFT(tcURL,lnAT-1))
DO CASE
	CASE lcProtocol == "http"
		lcPort = "80"
	CASE lcProtocol == "https"
		lcPort = "443"
	CASE lcProtocol == "ftp"
		lcPort = "21"
	OTHERWISE
		lcPort = "80"   
ENDCASE
tcURL = SUBSTR(tcURL, lnAT+3)

*** Server (and Port Number)
lnAT = AT("/", tcURL)
IF lnAT == 0 THEN
	lcServer = tcURL
	tcURL = "/"
ELSE
	lcServer = SUBSTR(tcURL, 1, lnAT-1)
	tcURL = SUBSTR(tcURL, lnAT)
ENDIF

*** Portname
lnAT = AT(":", lcServer)
IF lnAT > 0 THEN
   lcPort = SUBSTR(lcServer, lnAT+1)
   lcServer = LEFT(lcServer, lnAT-1)
ENDIF

loURL = CREATE("EMPTY")
ADDPROPERTY(loURL, "cProtocol", lcProtocol)
ADDPROPERTY(loURL, "cServer", lcServer)
ADDPROPERTY(loURL, "cPath", tcURL)  && What's left of the url
ADDPROPERTY(loURL, "cQuerystring", lcQuerystring)
ADDPROPERTY(loURL, "cPort", lcPort)

RETURN loUrl
ENDFUNC
* wwHTTP :: InternetCrackUrl 

********************************************************
* wwHTTP :: WinInetSetTimeout
*********************************
***  Function: Sets various timeout for use with a
***            WinInet Connection
***      Pass: dwTimeoutSecs - Secs to wait for timeout
********************************************************
FUNCTION wininetsettimeout
LPARAMETERS dwTimeoutSecs, lnHandle

dwTimeoutSecs=IIF(VARTYPE(dwTimeoutSecs)="N",;
   dwTimeoutSecs,THIS.nconnecttimeout)
   
IF dwTimeoutSecs = 0
   *** Just use the default
   RETURN
ENDIF   

IF EMPTY(lnHandle)
   lnHandle = THIS.hIPSession
ENDIF      

dwTimeoutSecs=dwTimeoutSecs * 1000   && to milliseconds
llRetVal=InternetSetOption(lnHandle,;
   INTERNET_OPTION_CONNECT_TIMEOUT,;
   @dwTimeoutSecs,4)

llRetVal=InternetSetOption(lnHandle,;
   INTERNET_OPTION_RECEIVE_TIMEOUT,;
   @dwTimeoutSecs,4)

llRetVal=InternetSetOption(lnHandle,;
   INTERNET_OPTION_SEND_TIMEOUT,;
   @dwTimeoutSecs,4)

*   dwTimeoutSecs=1  &&// Retry only 1 time
*   llRetVal=InternetSetOption(lnHandle,;
*      INTERNET_OPTION_CONNECT_RETRIES,;
*      @dwTimeoutSecs,4)
RETURN


************************************************************************
* wwHttp ::  GetErrorMessageFromHttpErrorCode
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetMessageFromResultCode(lcErrorNumber)
LOCAL lnMemoWidth, lnAt, lcLine, lcResult

IF EMPTY(lcErrorNumber)   
   *** short circuit success results
   IF this.cResultCode = "200"
      RETURN "OK"
   ENDIF
   
   *** Translate header
   IF !EMPTY(this.cHttpHeaders)	
           lnMemoWidth = SET("MEMOWIDTH")
           SET MEMOWIDTH TO 253
   	   lcLine = MLINE(this.cHttpHeaders,1)
   	   SET MEMOWIDTH TO (lnMemoWidth)
   	   
   	   *** Skip over HTTP/1.1 401 (second space) and pick up just the message
   	   lnAt = AT(" ",lcLine,2)
   	   IF lnAt > 0
   	      lcLine = SUBSTR(lcLine,lnAt+1)
   	   ENDIF
   	      
   	   RETURN lcLine
   ELSE
	   RETURN ""  && nothing we can do to figure out the Reslult Code text
   ENDIF
ENDIF

IF VARTYPE(lcErrorNumber) = "N"
   lcErrorNumber = TRANSFORM(lcErrorNumber)
ENDIF

lcResult = ""
DO CASE 
    CASE lcErrorNumber = "200"
        lcResult = "OK"
    CASE lcErrorNumber = "201"
        lcResult = "Created"        
    CASE lcErrorNumber = "202"
        lcResult = "Accepted"                
    CASE lcErrorNumber = "204"
        lcResult = "No Content"        
    CASE lcErrorNumber = "206"
        lcResult = "Partial Content"    
                            
	CASE lcErrorNumber = "500"	
		lcResult = "Internal Server Error"
	CASE lcErrorNumber = "501"	
		lcResult = "Not implemented"
	CASE lcErrorNumber = "502"	
		lcResult = "Bad Gateway"
	CASE lcErrorNumber = "503"	
		lcResult = "Service Unavailable"
	CASE lcErrorNumber = "504"	
		lcResult = "Gateway Timeout"
	CASE lcErrorNumber = "505"	
		lcResult = "HTTP Version Not Supported"		
	CASE lcErrorNumber = "5"
	    lcResult = "Server Error"

	CASE lcErrorNumber = "400"
  	    lcResult = "Bad Request"	    
	CASE lcErrorNumber = "401"
  	    lcResult = "Unauthorized"
  	CASE lcErrorNumber = "403"
  	    lcResult = "Forbidden"  	
  	CASE lcErrorNumber = "404"
  	    lcResult = "Not Found"  	
  	CASE lcErrorNumber = "405"
  	    lcResult = "Method Not Allowed"  	
	CASE lcErrorNumber = "406"
  	    lcResult = "Not Acceptable"  	    
  	CASE lcErrorNumber = "408"
  	    lcResult = "Server Request Timeout"  	
  	CASE lcErrorNumber = "409"
  	    lcResult = "Conflict"  	
  	CASE lcErrorNumber = "4"
  	    lcResult = "Invalid Request Format (Generic HTTP Error)"  	

	CASE lcErrorNumber = "301"
	    lcResult = "Moved Permanently"	    
	CASE lcErrorNumber = "302"
	    lcResult = "Found and Redirected"
	CASE lcErrorNumber = "303"
	    lcResult = "See Other"
	CASE lcErrorNumber = "304"
	    lcResult = "Not Modified"
	CASE lcErrorNumber = "3"
	    lcResult = "Redirected"	
	OTHERWISE
	    lcResult = ""  && unknown
ENDCASE

RETURN lcResult
ENDFUNC
*  wwHttp ::  GetErrorMessageFromHttpErrorCode


************************************************************************
* wwHTTP :: GetLastInternetError
*********************************
***  Function: Retrieves the last WinInet error using WinInet's error
***            responses.
***    Assume: Currently not used by class internally
***            Under Construction
***      Pass: lnError   -  Error Code to resolve(Optional)
***    Return: Error Message or ""
************************************************************************
   FUNCTION getlastinterneterror
   LPARAMETERS lnError

   lnError=IIF(TYPE("lnError")="N",lnError,THIS.nerror)

   DECLARE INTEGER InternetGetLastResponseInfo ;
      IN WININET.DLL ;
      INTEGER @lpdwError,;
      STRING @lpszBuffer,;
      INTEGER @lpcbSize

   lcErrorMsg=SPACE(1024)
   lnSize=LEN(lcErrorMsg)

   =InternetGetLastResponseInfo(@lnError,@lcErrorMsg,@lnSize)

   IF lnSize < 2
      RETURN ""
   ENDIF

   RETURN SUBSTR(lcErrorMsg,1,lnSize)
ENDFUNC

************************************************************************
* wwHTTP :: GetPostBuffer
*********************************
***  Function: Returns the entire Post Buffer as a string
************************************************************************
FUNCTION GetPostBuffer()

IF THIS.lUseLargePostBuffer
   RETURN this.oPostStream.ToString()
ENDIF

RETURN this.cPostBuffer
ENDFUNC

************************************************************************
*  ClearPostBuffer
****************************************
***  Function: Clears the Post Buffer
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ClearPostBuffer()

IF THIS.lUseLargePostBuffer
	this.oPostStream.Clear()
ENDIF
this.cPostBuffer = ""

ENDFUNC
*   ClearPostBuffer

************************************************************************
* wwHttp ::  SelectClientCertificateIndex
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION SelectClientCertificateIndex(lnHttpHandle)

IF VARTYPE(lnHttpHandle) != "N"
	this.HttpConnect("rasxps","","",.T.)
	lnHttpHandle = this.hHttpSession
ENDIF

*!*	DWORD InternetErrorDlg(
*!*	  _In_     HWND hWnd,
*!*	  _Inout_  HINTERNET hRequest,
*!*	  _In_     DWORD dwError,
*!*	  _In_     DWORD dwFlags,
*!*	  _Inout_  LPVOID *lppvData
*!*	);

DECLARE integer InternetErrorDlg IN WinInet.dll ;
	integer hWindow,;
	integer hInternet,;
	integer hRequest,;
	integer uiflags,;
	String@ lppvData
				
lnResult = InternetErrorDlg(_Screen.HWnd,lnHttpHandle,12044,0x04 + 0x01 + 0x02,null)

?lnResult
? THIS.GetSystemErrorMsg()
this.HttpClose()

*!*	       // Return ERROR_SUCCESS regardless of clicking on OK or Cancel
*!*	       if( InternetErrorDlg( 0, 
*!*	                             hReq,
*!*	                             ERROR_INTERNET_CLIENT_AUTH_CERT_NEEDED,
*!*	                             FLAGS_ERROR_UI_FILTER_FOR_ERRORS       |
*!*	                             FLAGS_ERROR_UI_FLAGS_GENERATE_DATA     |
*!*	                             FLAGS_ERROR_UI_FLAGS_CHANGE_OPTIONS, 
*!*	                             NULL) != ERROR_SUCCESS )
*!*	       {
*!*	           return ;
*!*	       }

RETURN lnResult
ENDFUNC
*  wwHttp ::  SelectClientCertificateIndex


************************************************************************
*  GetCertificates
****************************************
***  Function: Returns a list of client certificates
***    Assume: Requires wwDotnetBridge and .NET (silently)
***      Pass: lcStoreName -   *"My", "Root", "TrustedPeople", "TrustedPublisher", "AuthRoot"
***            lnLocation  -   *"CurrentUser", "LocalMachine"
***    Return: NULL on failure, Collection of Certificate objects
***            Subject, SerialNumber, Issuer
************************************************************************
FUNCTION GetCertificates(lcStoreName, lcLocation)
LOCAL loBridge, leMy, leLocation, leReadOnly, loStore, lnX, lnCount

IF EMPTY(lcStoreName)
  lcStoreName = "My"
ENDIF
IF EMPTY(lcLocation)
   lcLocation = "CurrentUser"
ENDIF

loBridge = EVALUATE("GetwwDotnetBridge()")

leMy = loBridge.CreateComValue()
leMy.SetEnum("System.Security.Cryptography.X509Certificates.StoreName." + lcStoreName)


leLocation = loBridge.CreateComValue()
leLocation.SetEnum("System.Security.Cryptography.X509Certificates.StoreLocation." + lcLocation)
? leLocation.Value

loStore = loBridge.CreateInstance("System.Security.Cryptography.X509Certificates.X509Store",leMy, leLocation)
IF ISNULL(loStore)
   this.cErrorMessage = "Couldn't create certificate store"
   RETURN NULL
ENDIF

leReadOnly  = loBridge.Getenumvalue("System.Security.Cryptography.X509Certificates.OpenFlags.ReadOnly")
loStore.Open(leReadOnly)

loCertificates = loBridge.GetProperty(loStore,"Certificates")
lnCount =  loBridge.GetProperty(loCertificates,"Count")

loCerts = CREATEOBJECT("Collection")

FOR lnX = 0 TO lnCount-1
   loCert = loBridge.GetIndexedProperty(loCertificates,lnX)

   * https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509certificate2?view=netframework-4.7.2
   loCerts.Add(loCert)
ENDFOR

loStore.Close()
loStore.Dispose()

RETURN loCerts
ENDFUNC
*   GetCertificates

********************************************************
* wwHTTP :: GetSystemErrorMsg
*********************************
***  Function: Returns an Error Message for the last
***            error value set in nError property.
***    Assume: nError was set by last operation
***    Return: Error String or ""
********************************************************
FUNCTION getsystemerrormsg
LPARAMETERS lnErrorNo, llAPI
LOCAL szMsgBuffer,lnSize

lnErrorNo=IIF(TYPE("lnErrorNo")="N",lnErrorNo,THIS.nerror)

IF lnErrorNo = ERROR_INTERNET_EXTENDED_ERROR
   RETURN THIS.getlastinterneterror()
ENDIF

szMsgBuffer=SPACE(500)
DECLARE INTEGER FormatMessage ;
   IN WIN32API ;
   INTEGER dwFlags ,;
   INTEGER lpvSource,;
   INTEGER dwMsgId,;
   INTEGER dwLangId,;
   STRING @lpBuffer,;
   INTEGER nSize,;
   INTEGER  Arguments

DECLARE INTEGER GetModuleHandle ;
   IN WIN32API ;
   STRING

lnModule=GetModuleHandle("wininet.dll")
IF lnModule # 0 AND !llAPI
   lnSize=FormatMessage(FORMAT_MESSAGE_FROM_HMODULE,lnModule,lnErrorNo,;
      0,@szMsgBuffer,LEN(szMsgBuffer),0)
ELSE
   lnSize=0
ENDIF

IF lnSize > 2
   szMsgBuffer=SUBSTR(szMsgBuffer,1, lnSize -2  )
ELSE
   *** REtry with 12000 less - WinInet return Windows API file error codes
   lnSize=FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,0,lnErrorNo,;
      0,@szMsgBuffer,LEN(szMsgBuffer),0)

   IF lnSize > 2
      szMsgBuffer="Win32 API: " + SUBSTR(szMsgBuffer,1, lnSize-2 )
   ELSE
      szMsgBuffer=""
   ENDIF
ENDIF

RETURN szMsgBuffer
ENDFUNC



************************************************************************
* wwHTTP :: Destroy
*********************************
***  Function: Clears HTTP Session Handles if open
************************************************************************
FUNCTION Destroy

IF THIS.hipsession # 0 OR THIS.hhttpsession # 0
   THIS.httpclose()
ENDIF

ENDFUNC


FUNCTION cResultCodeMessage_Access()
RETURN this.GetMessageFromResultCode()

ENDDEFINE
*** EndDefine: wwHTTP
**************************************************

