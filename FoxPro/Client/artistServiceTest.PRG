DO ArtistService


LOCAL loService as AristService 
loService = CREATEOBJECT("ArtistService")

loArtists = loService.GetArtists()

CLEAR 
? "*** ARTIST LIST"
? 
FOR	EACH loArtist IN loArtists FoxObject
	? loArtist.ArtistName + " (" +  TRANSFORM(loArtist.AlbumCount) + ")"
ENDFOR

WAIT WINDOW TIMEOUT 10

CLEAR 
? "*** SINGLE ARTIST"
?

loArtist = loService.GetArtist(33)

? loArtist.Artist.ArtistName 
? PADR(loArtist.Artist.Description,1000)

FOR EACH loAlbum in loArtist.Albums FOXOBJECT
    ? " -- " + loAlbum.Title  + " (" + TRANSFORM(loAlbum.Year) + ")"
    FOR EACH loTrack IN loAlbum.Tracks FOXOBJECT
      ? "    -- " + loTrack.SongName
    ENDFOR
ENDFOR

WAIT WINDOW TIMEOUT 10



CLEAR
? "*** UPDATE ARTIST"
?

*** Authenticate so service can auto-login
loService.cUsername = "test"
loService.cPassword = "test"

loArtist = CREATEOBJECT("EMPTY")
ADDPROPERTY(loArtist, "Id", 33)
ADDPROPERTY(loArtist, "ArtistName", "Anti-Trust")
ADDPROPERTY(loArtist, "Description",;
			"!!! Anti-Trust is a side project by ex-Attitude Adjustment members " +;
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


loArtist = loService.UpdateArtist(loArtist)

IF ISNULL(loArtist)
   ? loService.cErrorMsg
   RETURN
ENDIF

? loArtist.Artist.ArtistName
? loArtist.Artist.Description


FOR EACH loAlbum in loArtist.Albums FOXOBJECT
    ? " -- " + loAlbum.Title  + " (" + TRANSFORM(loAlbum.Year) + ")"
    FOR EACH loTrack IN loAlbum.Tracks FOXOBJECT
      ? "    -- " + loTrack.SongName
    ENDFOR
ENDFOR


