# Assumes you have 7zip (7z.exe) in your path 
# to build the final zip file. Otherwise you can
# manually zip uo the contents of the build folder


# Change this manually if necessary ("c:\webconnectionprojects\myproject\")

$curDir = "$PSScriptRoot"
cd $curDir

# Your Web Connection Install Path
$src="C:\WEBCONNECTION\FOX"

# The Project Path
$tgt=$curDir

$appname="Musicstore"

# Remove the Build folder
if ( Test-Path "$tgt\build" -PathType Container ) {    
    remove-item $tgt\build -force -recurse    
}

# force to current path even when running as Admin
mkdir $tgt\build
mkdir $tgt\build\deploy
cd $tgt\build\deploy


#  copy EXE and config file and IIS Install
Copy-Item $tgt\deploy\$appname.exe
Copy-Item $tgt\deploy\$appname.ini
Copy-Item $tgt\deploy\config.fpw
Copy-Item $tgt\install-iis-features.ps1 

# copy Web Connection DLLs from WWWC install
Copy-Item $src\*.dll

# change back to build folder
cd $tgt\build


# Copy data and Web Folders
# Comment if you don't want to package those
robocopy $tgt\data .\data /MIR
robocopy $tgt\web .\web /MIR
robocopy $tgt\WebConnectionWebServer WebConnectionWebServer /MIR

# Deployed apps shouldn't have prg/fxp files
# Let them re-compile on the server
Remove-Item -force -recurse $curDir\web\*.bak 
Remove-Item -force -recurse $curDir\web\*.fxp
Remove-Item -force -recurse $curDir\web\*.prg

Write-Host $appname
$zipfile = "$tgt\build\$appname"  + "_Packaged.zip"
Write-Host $zipfile

if (Get-Command "7z.exe" -ErrorAction SilentlyContinue) 
{
    # add 7zip to your path or in this folder for this to work
    & 7z a -r $zipfile  "*.*"
}
else 
{
    Write-Host "7z.exe - 7zip is not available. No zip file file was created." -ForegroundColor Yellow
}

cd $curdir