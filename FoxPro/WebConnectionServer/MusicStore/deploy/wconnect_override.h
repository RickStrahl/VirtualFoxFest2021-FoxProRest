*** Override file for wconnect.h. 
***
*** Called from the bottom of wconnect.h 
***
*** This file is not overridden by updates
*** while wconnect.h is so changes made here
*** persist across version updates.

*** Common things you might want to set here
*!*	#UNDEFINE WWC_USE_SQL_SYSTEMFILES    
*!*	#DEFINE WWC_USE_SQL_SYSTEMFILES     .F.

*!*	#UNDEFINE DEFAULT_HTTP_VERSION
*!*	#DEFINE DEFAULT_HTTP_VERSION		"1.1"

*!*	#UNDEFINE BOOTSTRAP_VERSION
*!* #DEFINE BOOTSTRAP_VERSION           3

*** If you use Web Controls uncomment this
*!* #UNDEFINE WWC_LOAD_WEBCONTROLS
*!* #DEFINE WWC_LOAD_WEBCONTROLS			.T.

*** If you use Old (v4 and older) Response class methods
*** enables Form methods, HttpHeader etc.
*!* #UNDEFINE INCLUDE_LEGACY_RESPONSEMETHODS
*!* #DEFINE INCLUDE_LEGACY_RESPONSEMETHODS  .T.