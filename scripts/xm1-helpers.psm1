Function Extract-XM1-Packages {
param (
    [string] $XM1PackagePath,
    [string] $AssetsFolder,
    [string] $XM1_SIF_ZipFile
)
    try{

        If (-Not (Test-Path -Path $XM1PackagePath)){
            throw "Missing XM1 package."
        }

        Remove-Item -Path $assetsFolder -Recurse -Force
        Expand-Archive -Path $XM1PackagePath -DestinationPath $AssetsFolder
        Expand-Archive -Path $XM1_SIF_ZipFile -DestinationPath $AssetsFolder
    }
    catch
    {
        write-host "Extract-XM1-Packages Failed: " $_.Exception.Message -ForegroundColor Red
        throw
    }
}

Function Initialize-Temporary-Folders {
param (
    [string[]] $Folders
)
    $Folders | ForEach-Object {
        If (-Not (Test-Path -Path $_)){
            New-Item -Path $_ -ItemType Directory -Force
        }
    }
}

Function Install-SitecoreInstallFramework {
    $PSRepository = @{
        Repository = "https://sitecore.myget.org/F/sc-powershell/api/v2/"
        Name = "SitecoreGallery"
    }

    #Register Assets PowerShell Repository
    if ((Get-PSRepository | Where-Object {$_.Name -eq $PSRepository.Name}).count -eq 0) {
        Register-PSRepository -Name $PSRepository.Name -SourceLocation $PSRepository.Repository -InstallationPolicy Trusted 
    }

    #Sitecore Install Framework dependencies
    Import-Module WebAdministration
    
    #Install SIF
    $sifVersion = "2.0.0"
    
    $module = Get-Module -FullyQualifiedName @{ModuleName = "SitecoreInstallFramework"; ModuleVersion = $sifVersion }
    if (-not $module) {
        write-host "Installing the Sitecore Install Framework, version $($sifVersion)" -ForegroundColor Green
        Install-Module SitecoreInstallFramework -Repository $PSRepository.Name -Scope CurrentUser -Force
        Import-Module SitecoreInstallFramework -Force
    }
}

Function Add-AppPoolMembership ([string] $hostName) {
    
    #Add ApplicationPoolIdentity to performance log users to avoid Sitecore log errors (https://kb.sitecore.net/articles/404548)
    
    try {
        Add-LocalGroupMember "Performance Log Users" "IIS AppPool\$($hostName)"
        Write-Host "Added IIS AppPool\$($hostName) to Performance Log Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($hostName) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }
    try {
        Add-LocalGroupMember "Performance Monitor Users" "IIS AppPool\$($hostName)"
        Write-Host "Added IIS AppPool\$($hostName) to Performance Monitor Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($hostName) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }
}

Function Remove-AppPoolMembership ([string] $hostName)
{
    try {
        Remove-LocalGroupMember "Performance Log Users" "IIS AppPool\$($hostName)"
        Write-Host "Removed IIS AppPool\$($hostName) from Performance Log Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't remove IIS AppPool\$($hostName) from Performance Log Users -- user may not exist" -ForegroundColor Yellow
    }

    try {
        Remove-LocalGroupMember "Performance Monitor Users" "IIS AppPool\$($hostName)"
        Write-Host "Removed IIS AppPool\$($hostName) from Performance Monitor Users" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Couldn't remove IIS AppPool\$($hostName) from Performance Monitor Users -- user may not exist" -ForegroundColor Yellow
    }
}