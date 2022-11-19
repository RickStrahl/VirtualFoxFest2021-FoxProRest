# FoxPro REST Session Notes

## Server Code

#### Server Setup

* Load Handler  
```foxpro  
DO MusicStoreBusiness`   
SET PATH TO '.data\ ADDITIVE'
```  

* Copy Data Folder from Saved Sample

#### Artist List

```foxpro
FUNCTION Artists()

loArtistBus = CREATEOBJECT("cArtist")
lnArtistCount = loArtistBus.GetArtistList()

IF lnArtistCount < 0
    THIS.ErrorResponse("Couldn't retrieve artists","404 Not Found")
    RETURN
ENDIF

Serializer.PropertyNameOverrides = "artistName,imageUrl,amazonUrl,albumCount,"

RETURN "cursor:TArtists"
ENDFUNC
```

#### Individual Artist

```foxpro
FUNCTION Artist(loArtist)
LOCAL lnId, lcVerb, loArtistBus

lnId = VAL(Request.QueryString("id"))
lcVerb = Request.GetHttpVerb()

if (lcVerb == "POST" or lcVerb == "PUT")
   RETURN this.UpdateArtist(loArtist)   
ENDIF   

IF lcVerb = "DELETE"
   loArtistBus = CREATEOBJECT("cArtist")   
   RETURN loArtistBus.Delete(lnId)  && .T. or .F.
ENDIF

*** GET Operation
IF lnId == 0
  RETURN this.ErrorResponse("Invalid Artist Id","404 Not Found")  
ENDIF

loArtistBus = CREATEOBJECT("cArtist")
IF !loArtistBus.Load(lnId)   
    RETURN this.ErrorResponse("Artist not found.","404 Not Found")
ENDIF 

*** Lazy load the albums
loArtistBus.LoadAlbums()

Serializer.PropertyNameOverrides = "artistName,imageUrl,amazonUrl,albumCount,albumPk, artistPk,songName,unitPrice,"

return loArtistBus.oData 
ENDFUNC
```