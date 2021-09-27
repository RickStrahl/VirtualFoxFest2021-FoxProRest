CLEAR
DO wwhttp
DO wwJsonSerializer

loHttp = CREATEOBJECT("wwHttp")
loSer = CREATEOBJECT("wwJsonSerializer")


*** Retrieve JSON Artist Array from Server
lcJson = loHttp.Get("https://albumviewer.west-wind.com/api/artists")

*** Turn Array into FoxPro collection
loArtists = loSer.Deserialize(lcJson)


FOR	EACH loArtist IN loArtists FoxObject
	? loArtist.ArtistName + " (" +  TRANSFORM(loArtist.AlbumCount) + ")"
ENDFOR


