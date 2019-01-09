
$ErrorActionPreference = 'Stop'

. $PSScriptRoot\parameters.ps1
if (Get-Module("xm1-helpers")) {
    Remove-Module "xm1-helpers"
}
Import-Module "$PSScriptRoot\scripts\xm1-helpers.psm1"

Extract-XM1-Packages -XM1PackagePath $xm1ZipFile -AssetsFolder $assetsFolder -XM1_SIF_ZipFile $SitecoreXM1.SIFPackages
Initialize-Temporary-Folders -Folders @($logPath, $certificatesPath, $assetsFolder, $tempLocation)
Install-SitecoreInstallFramework

Write-Host "**************************************************************************" -ForegroundColor Yellow
Write-Host "Install Prerequisites for Sitecore 9.1 - XM1" -ForegroundColor Green
Write-Host "**************************************************************************" -ForegroundColor Yellow

$PrerequisitesJsonFile = Join-Path -Path $assetsFolder -ChildPath "Prerequisites.json"
    $Parameters = @{
        Path            = $PrerequisitesJsonFile
        TempLocation    = $tempLocation
    }
    
Install-SitecoreConfiguration @Parameters *>&1 | Tee-Object (Join-Path -Path $logPath -ChildPath XM1-Prerequisites.log)