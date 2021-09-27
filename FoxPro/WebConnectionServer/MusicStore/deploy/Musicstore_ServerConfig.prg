************************************************************************
*  Musicstore_ServerConfig
****************************************
***  Function: Templated Installation program that can configure the
***            Web Server automatically.
***
***            You can modify this script to fit your exact needs
***            by modifying existing behavior or adding additional
***            configuration steps.
***
***            The base script is driven by the [ServerConfig] section in
***            Musicstore.ini and you can customize operation there.
***
***            [ServerConfig]
***            Virtual=Musicstore            
***            ScriptMaps=wc,wcs,wcsx,ms    
***            IISPath=IIS://localhost/w3svc/1/root
***
***            For root Web sites leave Virtual blank. To pick a specific
***            Web site to install to, use the IIS Site Id in the IISPath
***            the number of which you can look up in IIS Service Manager
***            and the Site list Tab.
***
***    Assume: Called from MusicstoreMain.prg startup code
***            with lcAction parameter:
***            DO MusicstoreMain with "CONFIG"
***
***            Or launch your Exe from the Windows Command Line:
***            Musicstore.exe config
***
***            or with a specific IIS site/virtual
***            Musicstore.exe config "IIS://localhost/w3svc/12/root"
***
***            This program assumes you're running out of the Web Connection
***            EXE folder and assumes the Web Folder lives relative at `..\Web`.
***
***      Pass: lcIISPath  -  IIS Configuration Path (optional)
***                          IIS://localhost/w3svc/1/root
************************************************************************
LPARAMETERS lcIISPath
LOCAL lcAppName, lcDefaultVirtual, lcScriptMap

lcAppName = "Musicstore"
lcDefaultVirtual = "MusicStore"
lcScriptMap = "ms"

IF FILE("WCONNECT.APP")
   MessageBox("This feature only works in the full version of Web Connection",48,lcAppName)
   RETURN
ENDIF

DO wwUtils	
SET PROCEDURE TO wwWebServer ADDITIVE
SET PROCEDURE TO wwXML ADDITIVE

IF !IsAdmin() 
   MESSAGEBOX("Admin privileges are required to configure the IIS Web Server." + CHR(13) +;
              "Please make sure you run this exe using 'Run As Administrator'",;
              48, lcAppName + " Server Configuration")
   RETURN
ENDIF

*** Try to read from Musicstore.ini [ServerConfig] section
loApi = CREATEOBJECT("wwAPI")
lcIniPath = FULLPATH(lcAppName + ".ini")
lcVirtual = loApi.GetProfileString(lcIniPath,"ServerConfig","Virtual")
IF ISNULL(lcVirtual)
  lcVirtual = lcDefaultVirtual
ENDIF
lcScriptMaps = loApi.GetProfileString(lcIniPath,"ServerConfig","ScriptMaps")
IF ISNULLOREMPTY(lcScriptMaps)
  lcScriptMaps = "wc,wcs,wcsx," + lcScriptMap  
ENDIF
IF EMPTY(lcIISPath)
  lcIISPath = loApi.GetProfileString(lcIniPath,"ServerConfig","IISPath")
  IF ISNULLOREMPTY(lcIISPath)
     *** Typically this is the root site path
    lcIISPath = "IIS://localhost/w3svc/1/root"
  ENDIF
ENDIF  


*** Other relative configurable settings
lcVirtualPath = LOWER(FULLPATH("..\Web"))
lcScriptPath = lcVirtualPath + "\bin\wc.dll"
lcTempPath = LOWER(FULLPATH(".\temp"))
lcApplicationPool = "West Wind Web Connection"
lcServerMode = "IIS7HANDLER"     && "IIS7" (ISAPI) / IISEXPRESS


loWebServer = CREATEOBJECT("wwWebServer")
loWebServer.cServerType = UPPER(lcServerMode)
loWebServer.cApplicationPool = lcApplicationPool
IF !EMPTY(lcIISPath)
   loWebServer.cIISVirtualPath = lcIISPath
ENDIF

WAIT WINDOW NOWAIT "Creating virtual directory " + lcVirtual + "..."
*** Create the virtual directory
IF !loWebServer.CreateVirtual(lcVirtual,lcVirtualPath)   
   WAIT WINDOW TIMEOUT 5 "Couldn't create virtual."
   RETURN
ENDIF


*** Create the Script Maps
lnMaps = ALINES(laMaps,lcScriptMaps,1 + 4,",")
FOR lnx=1 TO lnMaps
    lcMap = laMaps[lnX]
    WAIT WINDOW NOWAIT "Creating Scriptmap " + lcMap + "..."
	  llResult = loWebServer.CreateScriptMap(lcMap, lcScriptPath)	    
    IF !llResult
       WAIT WINDOW TIMEOUT 2 "Failed to create scriptmap " + lcMap
    ENDIF
ENDFOR


WAIT WINDOW NOWAIT "Setting folder permissions..."

lcAnonymousUserName = ""
loVirtual = GETOBJECT(lcIISPath)
lcAnonymousUserName = loVirtual.AnonymousUserName
loVirtual = .NULL.

*** Set access on the Web directory -  should match Application Pool identity
SetAcl(lcVirtualPath,"Administrators","F",.T.)
SetAcl(lcVirtualPath,"Interactive","F",.T.)
SetAcl(lcVirtualPath,"NETWORKSERVICE","F",.T.)
* SetAcl(lcVirtualPath,"OtherUser","F",.T.)

*** Remove IUSR from Admin folder
SetAcl(ADDBS(lcVirtualPath) + "Admin","IUSR","N",.T.)


*** IUSR Anonymous Access
IF !EMPTY(lcAnonymousUserName)
    llResult = SetAcl(lcVirtualPath,lcAnonymousUserName,"R",.T.)

    *** No unauthorized access to admin folder
    lcAdminPath = ADDBS(lcVirtualPath) + "Admin"
    IF DIRECTORY(lcAdminPath)
   	   llResult = SetAcl(lcAdminPath,lcAnonymousUserName,"N",.t.)
    ENDIF
ENDIF

*** Set access on the Temp directory - should match Application Pool Identity
SetAcl(lcTempPath,"Administrators","F",.T.)
SetAcl(lcTempPath,"Interactive","F",.T.)
SetAcl(lcTempPath,"NETWORKSERVICE","F",.T.)
* SetAcl(lcTempPath,"OtherUser","F",.T.,"username","password")

*** COM Server Registration
lcExe = lcAppName + ".exe"
IF FILE(lcExe)
   RUN /n4 &lcExe /regserver

   *** Optionally set DCOM permission - only set if needed!
   *** requires that DComLaunchPermissions.exe is available in .\tools\
   * DCOMLaunchPermissions(lcAppName + "." + lcAppName + "Server","INTERACTIVE")
   * DCOMLaunchPermissions(lcAppName + "." + lcAppName + "Server","username","password")
ENDIF

WAIT WINDOW Nowait "Configuration completed..."
RETURN