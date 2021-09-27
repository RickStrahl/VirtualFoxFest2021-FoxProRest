# ----------------------------------------
# Web Connection Web Server Install Script
# ----------------------------------------
# This install script adds the Web server to the Windows Path so you
# can execute `WebConnectionWebServer` from anywhere in Windows
# 
# It also checks to see that .NET Core 3.x is installed and prompts
# for installation if it is not.


# Check if the .NET SDK is installed
$ver = (dir (Get-Command dotnet).Path.Replace('dotnet.exe', 'shared\Microsoft.NETCore.App')).Name | where-object {$_.StartsWith("5.") } | Sort-Object {$_} -Descending | Select-Object -First 1 
if (!$ver.StartsWith("3.") )
{
    Write-Host "------------------------------------------------------------------------------------"
    Write-Host ".NET Core Runtime 5.x is not installed. Please install the .NET Core SDK or Runtime." -ForegroundColor Red
    Write-Host "------------------------------------------------------------------------------------"
    Write-Host "You can install the .NET Core SDK from: "
    Write-Host "https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    Write-Host "---------------------------------------------------------------------"
    Write-Host ""    
}
else {
    Write-Host "---------------------------------------------------------------------"
    Write-Host ".NET Core Runtime installed: v${ver}"
    Write-Host "---------------------------------------------------------------------"
    Write-Host ""
}

$localPath = $PWD.ToString()
$pathVal = Get-ItemProperty -path HKCU:\Environment\ -Name Path 

if (!$pathVal.Path.Contains($localPath))
{
    # assign permanent path
    Set-ItemProperty -path HKCU:\Environment\ -Name Path -Value "$((Get-ItemProperty -path HKCU:\Environment\ -Name Path).Path);$localPath"
    Write-Host "-----------------------------------------------------" -ForegroundColor Green
    Write-Host "Your PATH Environment variable has been updated with:" -ForegroundColor Green
    Write-Host  $localPath -ForegroundColor Green
    Write-Host "-----------------------------------------------------" -ForegroundColor Green

    # Assign current session path
    $ENV:PATH="$ENV:PATH;$localPath"
}
else {
    Write-Host "--------------------------------------------------" -ForegroundColor Green
    Write-Host "Path is already in your PATH environment variable." -ForegroundColor Green
    Write-Host $localPath -ForegroundColor Green
    Write-Host "--------------------------------------------------" -ForegroundColor Green
}
