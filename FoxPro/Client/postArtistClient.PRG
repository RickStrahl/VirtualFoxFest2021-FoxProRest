CLEAR
DO wwhttp

*** wwJsonServiceClient live in this PRG
DO wwJsonSerializer

*** Create an object
loUser = CREATEOBJECT("EMPTY")
ADDPROPERTY(loUser,"Username", "test")
ADDPROPERTY(loUser, "Password", "test")


LOCAL loClient as wwJsonServiceClient
loClient = CREATEOBJECT("wwJsonServiceClient")

*** .oSerializer and .oHttp instance can be configured
loClient.oSerializer.PropertyNameOverrides = "userName,passWord"

*** Pass the object for POST and return Auth Object
loAuth = loClient.Callservice("https://albumviewer.west-wind.com/api/Authenticate", loUser, "POST")

IF loClient.lError
   ? "Failed: " + loClient.cErrorMsg
ENDIF

lcToken = loAuth.Token
IF EMPTY(lcToken)
   ? "Authentication failed. Invalid token."
   RETURN
ENDIF

? "Got token: " +  lcToken

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



*** Create new instance
loClient = CREATEOBJECT("wwJsonServiceClient")

*** Use the oHttp client to add a header
loClient.oHttp.AddHeader("Authorization", "Bearer " + lcToken)

*** Pass loArtist directly
loUpdated = loClient.CallService("https://albumviewer.west-wind.com/api/Artist", loArtist,"POST")

IF loClient.lError
   ? "Failed to update: " + loClient.cErrorMsg
   RETURN
ENDIF

*? lcJson
*ShowJson(lcJson)

*** reset loArtist! And for kicks print out info
loArtist = loUpdated

? loArtist.Artist.ArtistName
? loArtist.Artist.Description

FOR EACH loAlbum in loArtist.Albums FOXOBJECT
    ? " -- " + loAlbum.Title  + " (" + TRANSFORM(loAlbum.Year) + ")"
    FOR EACH loTrack IN loAlbum.Tracks FOXOBJECT
      ? "    -- " + loTrack.SongName
    ENDFOR
ENDFOR


