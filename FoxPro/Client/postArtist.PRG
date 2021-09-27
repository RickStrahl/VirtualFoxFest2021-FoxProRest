CLEAR
DO wwJsonSerializer

LOCAL loHttp as wwHttp, loSer as wwJsonSerializer
loHttp = CREATEOBJECT("wwHttp")
loSer = CREATEOBJECT("wwJsonSerializer")

loUser = CREATEOBJECT("EMPTY")
ADDPROPERTY(loUser,"Username", "test")
ADDPROPERTY(loUser, "Password", "test")
lcJson = loSer.Serialize(loUser)

loHttp.cContentType = "application/json"
lcJson = loHttp.Post("https://albumviewer.west-wind.com/api/Authenticate", lcJson)

IF loHttp.nError # 0
   ? "Failed: " + loHttp.cErrorMsg
ENDIF
IF loHttp.cResultCode = "401"
   ? "Login failed. Invalid credentials"
   RETURN
ENDIF   
IF loHttp.cResultCode # "200"
   ? "Failed: " + loHttp.cResultCode + "  " + loHttp.cResultCodeMessage
   RETURN
ENDIF   

loAuth = loSer.Deserialize(lcJson)
lcToken = loAuth.Token
IF EMPTY(lcToken)
   ? "Authentication failed. Invalid token."
   RETURN
ENDIF

loArtist = CREATEOBJECT("EMPTY")
ADDPROPERTY(loArtist, "Id", 33)
ADDPROPERTY(loArtist, "ArtistName", "Anti-Trust")
ADDPROPERTY(loArtist, "Description",;
			"Anti-Trust is a side project by ex-Attitude Adjustment members " +;
            "Chris Kontos, Rick Strahl and Andy Andersen. This collaboration " +;
            "produced a handful of songs that were garage recorded in " +;
            "Oakland, CA and Maui, HI in 2001 and 2002 by Rick and Chris. " +;
            "Several additional songs were recorded in late 2020 and early 2021 " +;
            "which resulted in a the songs being officially put out and released " + ;
            "online and in album form." + CHR(10) + CHR(10) + ;
            "Anti-Trust's music features diverse influences from old school hardcore punk, " +;
            "metal cross over and NWOFBHM, all driven by heavy guitar rhythms " +;
            "and catchy choruses with a unique and edgy sound.")
ADDPROPERTY(loArtist, "ImageUrl", "https://anti-trust.rocks/images/Photo6.jpg")
ADDPROPERTY(loArtist, "AmazonUrl",  "https://amzn.to/3ucZlPk")
ADDPROPERTY(loArtist, "SpotifyUrl", "https://anti-trust.rocks")

loSer.PropertyNameOverrides = "Id,ArtistName,Description,ImageUrl,AmazonUrl,ImageUrl,SpotifyUrl"
lcJson = loSer.Serialize(loArtist)

lohttp.AddHeader("Authorization", "Bearer " + lcToken)
loHttp.cContentType = "application/json"
*** Update existing record PUT. New record POST but backend handles either
lcJson = loHttp.Post("https://albumviewer.west-wind.com/api/Artist", lcJson)
IF loHttp.nError # 0
   ? "Failed: " + loHttp.cErrorMsg
ENDIF
IF loHttp.cResultCode # "200"
   ? "Failed: " + loHttp.cResultCode + "  " + loHttp.cResultCodeMessage
   RETURN
ENDIF   

*? lcJson
*ShowJson(lcJson)

loArtist = loSer.Deserialize(lcJson)

? loArtist.Artist.ArtistName
? loArtist.Artist.Description

FOR EACH loAlbum in loArtist.Albums FOXOBJECT
    ? " -- " + loAlbum.Title  + " (" + TRANSFORM(loAlbum.Year) + ")"
    FOR EACH loTrack IN loAlbum.Tracks FOXOBJECT
      ? "    -- " + loTrack.SongName
    ENDFOR
ENDFOR


