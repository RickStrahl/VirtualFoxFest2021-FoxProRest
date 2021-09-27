CLEAR
DO wwhttp
DO wwJsonSerializer

loClient = CREATEOBJECT("wwJsonServiceClient")
loArtists = loClient.CallService("https://albumviewer.west-wind.com/api/artists")


FOR	EACH loArtist IN loArtists FoxObject
	? loArtist.ArtistName + " (" +  TRANSFORM(loArtist.AlbumCount) + ")"
ENDFOR


