SET PROCEDURE TO wwBusinessObject ADDITIVE
SET PROCEDURE TO wwCollections ADDITIVE
SET PROCEDURE TO musicstore.prg ADDITIVE


*************************************************************
DEFINE CLASS cartist AS wwBusinessObject
*************************************************************

cAlias = "artists"
cDataPath = ""
cFileName = "artists"

cPkField = "Pk"  
cIdTable = "ms_id"

*** Sql Connection String 
cConnectString = ""

*** 0 - fox 2 - Sql 4-Web
nDataMode = 0

************************************************************************
* cArtist ::  GetArtistList
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetArtistList()
RETURN this.Query("select *,(select COUNT(*) from albums where pk == artists.pk) as albumCount from artists order by artistname","TArtists")
ENDFUNC
*  cArtist ::  GetArtistList

************************************************************************
* cArtist ::  Load
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Load(lvPk)

IF !DODEFAULT(lvPk)
  RETURN .F.
ENDIF

ADDPROPERTY(this.oData,"Albums",NULL)  

RETURN .T.
ENDFUNC
*  cArtist ::  Load

************************************************************************
* cArtist ::  GetBlankRecord
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetBlankRecord()

IF !DODEFAULT()
  RETURN .F.
ENDIF

ADDPROPERTY(this.oData,"Albums",NULL)  

RETURN .T.
ENDFUNC
*  cAlbum ::  GetBlankRecord


************************************************************************
* cArtist ::  LoadAlbums
****************************************
***  Function: Returns a collection of 
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadAlbums()
loAlbum = CREATEOBJECT("cAlbum")
this.oData.Albums = loAlbum.LoadAlbums(this.oData.pk)
ENDFUNC
*  cArtist ::  LoadAlbums

*************************************************************
FUNCTION CreateTable(lcFileName)
*************************************************************
LOCAL lxFields

IF EMPTY(lcFileName)
   lcFileName = THIS.cDataPath + THIS.cFileName
ENDIF

IF THIS.nDataMode = 0

*** Generated on: 09/07/2014
DIMENSION lxFields[  2,4]

lxFields[  1,1]='PK'
lxFields[  1,2]='I'
lxFields[  1,3]=  4
lxFields[  1,4]=  0
lxFields[  2,1]='ARTISTNAME'
lxFields[  2,2]='C'
lxFields[  2,3]=120
lxFields[  2,4]=  0

CREATE TABLE (lcFileName) FROM ARRAY lxFields


  USE
ENDIF

ENDFUNC
* CreateTable

*************************************************************
FUNCTION Reindex()
*************************************************************

IF THIS.nDataMode = 0
   IF !OpenExclusive(THIS.cDataPath + THIS.cFileName,THIS.cAlias)
      THIS.SetError("Unable to open Customer file due to exclusive use.")
      RETURN .F.
   ENDIF

   DELETE TAG ALL
   PACK

   USE
ENDIF
ENDFUNC
* Reindex

ENDDEFINE
* cartist


*************************************************************
DEFINE CLASS calbum AS wwBusinessObject
*************************************************************

cAlias = "albums"
cDataPath = ""
cFileName = "albums"

cPkField = "Pk"
cIdTable = "ms_id"

*** Sql Connection String
cConnectString = ""

*** 0 - fox 2 - Sql 4-Web
nDataMode = 0

************************************************************************
* cAlbum ::  Load
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Load(lnPk)
PRIVATE pnPk

IF !DODEFAULT(lnPk)
	RETURN .F.
ENDIF

ADDPROPERTY(this.oData,"Artist",NULL)
ADDPROPERTY(this.oData,"Tracks",NULL)
this.LoadSongs(this.oData.Pk)
this.LoadArtist()

RETURN .T.
ENDFUNC
*  cAlbum ::  Load

************************************************************************
* cAlbum ::  GetBlankRecord
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetBlankRecord()

IF !DODEFAULT()
  RETURN .F.
ENDIF

ADDPROPERTY(this.oData,"Artist",NULL)
ADDPROPERTY(this.oData,"Tracks",NULL)

RETURN
ENDFUNC
*  cAlbum ::  GetBlankRecord

************************************************************************
* cAlbum ::  Save
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Save()

loTracks = CREATEOBJECT("cTrack")
loTracks.SaveTracksFromCollection(this.oData.Tracks, this.oData.Pk)

*** Reload songs so that we get new PKs and validated
*** saved data
this.LoadSongs()

loArtist = CREATEOBJECT("cArtist")

IF this.oData.Artist.Pk = 0 OR !loArtist.Load(this.oData.Artist.Pk)    
   lnId = this.GetArtistPk(this.oData.Artist.ArtistName)
   IF lnId < 1
	   lnId = loArtist.CreateNewId()
   ENDIF
   this.oData.Artist.Pk = lnId
   this.oData.ArtistPk = lnId
ENDIF

loArtist.oData = this.oData.Artist
loArtist.Save()


IF !DODEFAULT()
   RETURN .F.
ENDIF
   
ENDFUNC
*  cAlbum ::  Save


************************************************************************
* cAlbum ::  GetAlbumPkList
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetAlbumPkList
PARAMETERS pnArtistpk

lcFilter = ""
IF !EMPTY(pnArtistPk)
   lcFilter = " albums.artistPk == pnArtistPk AND "
ENDIF

lcSql = ;
"Select albums.pk From Albums, Artists where " + lcFilter +;
   " Artists.Pk = Albums.ArtistPk " +  ;
   " INTO CURSOR TAlbums order by Title"

RETURN THIS.Query(lcSql,"TAlbums")
ENDFUNC
*  cAlbum ::  GetAlbumPkList

************************************************************************
*  GetAlbumList
****************************************
***  Function: Returns a collection of objects for each of the albums
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetAlbumList(lnArtistPk)

this.GetAlbumPkList()
SCAN 
    loAlbum.Load(TAlbums.pk)
ENDSCAN
ENDFUNC
*   GetAlbumList

************************************************************************
* cAlbum ::  LoadSongs
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadSongs()
PARAMETERS pnAlbumPk
LOCAL loBusTrack 

IF EMPTY(pnAlbumPk)
   pnAlbumPk = this.oData.Pk
ENDIF   

IF !ISNULL(this.oData)
	loBusTrack = CREATEOBJECT("cTrack")
    lnResult = loBusTrack.Query("select * from tracks where albumpk = ?pnAlbumPk","TTracks",64)
    IF lnResult > -1
    	THIS.oData.Tracks = loBusTrack.vResult
    ENDIF
ENDIF

ENDFUNC
*  cAlbum ::  LoadSongs

************************************************************************
* cAlbum ::  LoadArtist
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadArtist()
PARAMETERS pnArtistPk
LOCAL loAlbum

IF EMPTY(pnArtistPk)
  pnArtistPk = this.oData.ArtistPk
ENDIF  

IF !ISNULL(this.oData)
   loAlbum = CREATEOBJECT("cArtist")
   IF !loAlbum.Load(pnArtistPk)
      loAlbum.New()
   ENDIF
   this.oData.Artist = loAlbum.oData

ENDIF

ENDFUNC
*  cAlbum ::  LoadArtist


************************************************************************
*  cAlbum :: LoadAlbums
****************************************
***  Function: Returns a collection of albums for a given artist pk
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadAlbums(lnArtistPk)
LOCAL loAlbum, loBusAlbum, loAlbums

loBusAlbum = CREATEOBJECT("cAlbum")
loAlbums = CREATEOBJECT("Collection")

*** Load Pks then load each item for detailed list
loBusAlbum.GetAlbumPkList(lnArtistPk)
SCAN 
	loBusAlbum.Load(TAlbums.pk)
    loAlbums.Add( loBusAlbum.oData )
ENDSCAN

RETURN loAlbums
ENDFUNC
*   cAlbum :: LoadAlbums

************************************************************************
* cAlbum ::  CheckForArtist
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetArtistPk(lcArtist)
PRIVATE pcArtist

pcArtist = LOWER(lcArtist)
loBusArtist = CREATEOBJECT("cArtist")
IF loBusArtist.Find("lower(artistname) == pcArtist")
   RETURN loBusArtist.oData.pk
ENDIF
RETURN -1
ENDFUNC
*  cAlbum ::  CheckForArtist


*************************************************************
FUNCTION CreateTable(lcFileName)
*************************************************************
LOCAL lxFields

IF EMPTY(lcFileName)
   lcFileName = THIS.cDataPath + THIS.cFileName
ENDIF

IF THIS.nDataMode = 0

*** Generated on: 09/07/2014
DIMENSION lxFields[  7,4]

lxFields[  1,1]='PK'
lxFields[  1,2]='I'
lxFields[  1,3]=  4
lxFields[  1,4]=  0
lxFields[  2,1]='TITLE'
lxFields[  2,2]='C'
lxFields[  2,3]=160
lxFields[  2,4]=  0
lxFields[  3,1]='ARTISTID'
lxFields[  3,2]='I'
lxFields[  3,3]=  4
lxFields[  3,4]=  0
lxFields[  4,1]='YEAR'
lxFields[  4,2]='N'
lxFields[  4,3]= 10
lxFields[  4,4]=  0
lxFields[  5,1]='IMAGEURL'
lxFields[  5,2]='M'
lxFields[  5,3]=  4
lxFields[  5,4]=  0
lxFields[  6,1]='AMAZONURL'
lxFields[  6,2]='M'
lxFields[  6,3]=  4
lxFields[  6,4]=  0
lxFields[  7,1]='DESCRIPT'
lxFields[  7,2]='M'
lxFields[  7,3]=  4
lxFields[  7,4]=  0

CREATE TABLE (lcFileName) FROM ARRAY lxFields


  USE
ENDIF

ENDFUNC
* CreateTable

*************************************************************
FUNCTION Reindex()
*************************************************************

IF THIS.nDataMode = 0
   IF !OpenExclusive(THIS.cDataPath + THIS.cFileName,THIS.cAlias)
      THIS.SetError("Unable to open Customer file due to exclusive use.")
      RETURN .F.
   ENDIF

   DELETE TAG ALL
   PACK



   USE
ENDIF
ENDFUNC
* Reindex

ENDDEFINE
* calbum

*************************************************************
DEFINE CLASS ctrack AS wwBusinessObject
*************************************************************

cAlias = "tracks"
cDataPath = ""
cFileName = "tracks"

cPkField = "Pk"
cIdTable = "ms_id"

*** Sql Connection String
cConnectString = ""

*** 0 - fox 2 - Sql 4-Web
nDataMode = 0

************************************************************************
* cTrack ::  SaveTracksFromCollection
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION SaveTracksFromCollection(loTrackCollection, lnAlbumPk)

IF !this.Open()
   RETURN .F.
ENDIF   

FOR EACH loTrack IN loTrackCollection
   IF loTrack.Pk == 0
   	  *** Must create a new Id
      loTrack.Pk = this.CreateNewId()
   ENDIF
   IF EMPTY(loTrack.AlbumPk)
      loTrack.AlbumPk = lnAlbumPk
   ENDIF
ENDFOR

IF !CollectionToCursor(loTrackCollection,"Tracks","tracks.pk = item.pk")
	RETURN .F.
ENDIF

RETURN .T.
ENDFUNC
*  cTrack ::  SaveTracksFromCollection

*************************************************************
FUNCTION CreateTable(lcFileName)
*************************************************************
LOCAL lxFields

IF EMPTY(lcFileName)
   lcFileName = THIS.cDataPath + THIS.cFileName
ENDIF

IF THIS.nDataMode = 0

*** Generated on: 09/07/2014
DIMENSION lxFields[  7,4]

lxFields[  1,1]='PK'
lxFields[  1,2]='I'
lxFields[  1,3]=  4
lxFields[  1,4]=  0
lxFields[  2,1]='ATISTID'
lxFields[  2,2]='I'
lxFields[  2,3]=  4
lxFields[  2,4]=  0
lxFields[  3,1]='ALBUMID'
lxFields[  3,2]='I'
lxFields[  3,3]=  4
lxFields[  3,4]=  0
lxFields[  4,1]='SONGNAME'
lxFields[  4,2]='C'
lxFields[  4,3]=200
lxFields[  4,4]=  0
lxFields[  5,1]='LENGTH'
lxFields[  5,2]='C'
lxFields[  5,3]= 10
lxFields[  5,4]=  0
lxFields[  6,1]='BYTES'
lxFields[  6,2]='I'
lxFields[  6,3]=  4
lxFields[  6,4]=  0
lxFields[  7,1]='UNITPRICE'
lxFields[  7,2]='N'
lxFields[  7,3]= 12
lxFields[  7,4]=  2

CREATE TABLE (lcFileName) FROM ARRAY lxFields


  USE
ENDIF

ENDFUNC
* CreateTable

*************************************************************
FUNCTION Reindex()
*************************************************************

IF THIS.nDataMode = 0
   IF !OpenExclusive(THIS.cDataPath + THIS.cFileName,THIS.cAlias)
      THIS.SetError("Unable to open Customer file due to exclusive use.")
      RETURN .F.
   ENDIF

   DELETE TAG ALL
   PACK



   USE
ENDIF
ENDFUNC
* Reindex

ENDDEFINE
* ctrack


*************************************************************
DEFINE CLASS cAuth AS wwBusinessObject
*************************************************************
*: Author: Rick Strahl
*:         (c) West Wind Technologies, 2021
*:Contact: http://www.west-wind.com
*:Created: 9/29/2021
*************************************************************

*** Custom Properties

*** Stock Properties


************************************************************************
*  Authenticate
****************************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION AuthenticateAndIssueToken(lcUsername, lcPassword)

IF EMPTY(lcUsername) OR EMPTY(lcPassword)
   this.SetError("Username or password can't be empty.")
   RETURN NULL
ENDIF
   
*** Validate here with real logic   
IF lcUsername == "test" AND lcPassword == "test"
   loToken = CREATEOBJECT("EMPTY")
   ADDPROPERTY(loToken, "token", GetUniqueId() )
   ADDPROPERTY(loToken, "isCallbackError", .F.)
   RETURN loToken	

ENDIF

this.SetError("Invalid Username or password")
RETURN null
ENDFUNC
*   Authenticate


ENDDEFINE
*EOC cAuth 

FUNCTION MsToTime(lnMs)

lnSecs = INT(lnMs/1000)
lnMins = INT(lnSecs/60)
lnSecs = lnSecs % 20

RETURN TRANSFORM(lnMins) + ":" + PADL(TRANSFORM(lnSecs),2,"0")
ENDFUNC