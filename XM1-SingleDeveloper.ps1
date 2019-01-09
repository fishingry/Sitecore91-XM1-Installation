param (
    [switch] $Uninstall
)

. $PSScriptRoot\parameters.ps1
if (Get-Module("xm1-helpers")) {
    Remove-Module "xm1-helpers"
}
Import-Module "$PSScriptRoot\scripts\xm1-helpers.psm1"

$ErrorActionPreference = 'Stop'

Function Confirm-Prerequisites {
    ### Verify Solr
    Write-Host "Verifying Solr connection" -ForegroundColor Green
    $solrUrl = $solr.SolrUrl.ToLower()
    if (-not $solrUrl.StartsWith("https")) {
        throw "Solr URL ($solrUrl) must be secured with https"
    }
    Write-Host "Solr URL: $($solrUrl)"
    $SolrRequest = [System.Net.WebRequest]::Create($solrUrl)
    $SolrResponse = $SolrRequest.GetResponse()
    try {
        If ($SolrResponse.StatusCode -ne 200) {
            Write-Host "Could not contact Solr on '$($solrUrl)'. Response status was '$SolrResponse.StatusCode'" -ForegroundColor Red
            
        }
    }
    finally {
        $SolrResponse.Close()
    }
    
    Write-Host "Verifying Solr directory" -ForegroundColor Green
    if (-not (Test-Path "$($solr.SolrRoot)\server")) {
        throw "The Solr root path '$($solr.SolrRoot)' appears invalid. A 'server' folder should be present in this path to be a valid Solr distributive."
    }

    Write-Host "Verifying Solr service" -ForegroundColor Green
    try {
        $null = Get-Service $solr.SolrService
    }
    catch {
        throw "The Solr service '$($solr.SolrService)' does not exist. Perhaps it's incorrect in settings.ps1?"
    }

    Initialize-Temporary-Folders -Folders @($logPath, $certificatesPath, $assetsFolder, $tempLocation)
}

Function Modify-SIF-WebRoot {

    try {
        $JsonFiles = @(
        $SitecoreXM1.SIF_Files.IdentityServer,
        $SitecoreXM1.SIF_Files.CD,
        $SitecoreXM1.SIF_Files.CM
        )

        $JsonFiles | ForEach-Object {
            $json = Get-Content -Raw $_ -Encoding Ascii | ConvertFrom-Json
            $Parameters = $json.Parameters
            $Variables = $json.Variables

            # Add WebRoot Parameter
            If ($null -eq $Parameters.WebRoot) {
                $WebRoot = @{
                    Type         = 'string'
                    DefaultValue = 'c:\inetpub\wwwroot'
                    Description  = 'The physical path of the configured Web Root for the environment'
                }
                
                $Parameters | Add-Member -Name "WebRoot" -Value $WebRoot -Type NoteProperty
            }
            
            # Modify Site.PhysicalPath Variable
            
            $Variables.'Site.PhysicalPath' = "[joinpath(parameter('WebRoot'), parameter('SiteName'))]"

            $json | ConvertTo-Json -Depth 100 | % Replace "\u0027" "'" | Set-Content $_
        }
    }
    catch {
        write-host "Modify-SIF-WebRoot Failed" -ForegroundColor Red
        throw
    }
}

Function Modify-XM1-SIF-Config {
    try {
        $XM_Config = Get-Content -Raw $SitecoreXM1.SIF_Files.XM_SingleDeveloper -Encoding Ascii | ConvertFrom-Json
        
        $Parameters = $XM_Config.Parameters

        # Add WebRoot Parameter
        If ($null -eq $Parameters.WebRoot) {
            $WebRoot = @{
                Type         = 'string'
                DefaultValue = 'c:\inetpub\wwwroot'
                Description  = 'The physical path of the configured Web Root for the environment'
            }
            $Parameters | Add-Member -Name "WebRoot" -Value $WebRoot -Type NoteProperty
        }
        
        # Add RootCertFileName Parameter
        If ($null -eq $Parameters.RootCertFileName) {
            $RootCertFileName = @{
                Type         = 'string'
                DefaultValue = "SitecoreRootCert"
                Description  = "The file name of the root certificate to be created."
            }
            $Parameters | Add-Member -Name "RootCertFileName" -Value $RootCertFileName -Type NoteProperty
        }

        # Add SitecoreCM:WebRoot
        If ($null -eq $Parameters."SitecoreCM:WebRoot") {
            $SitecoreCMWebRoot = @{
                Type        = "String"
                Reference   = "WebRoot"
                Description = "Override to pass WebRoot"
            }
            $Parameters | Add-Member -Name "SitecoreCM:WebRoot" -Value $SitecoreCMWebRoot -Type NoteProperty
        }

        # Add SitecoreCD:WebRoot
        If ($null -eq $Parameters."SitecoreCD:WebRoot") {
            $SitecoreCDWebRoot = @{
                Type        = "String"
                Reference   = "WebRoot"
                Description = "Override to pass WebRoot"
            }
            $Parameters | Add-Member -Name "SitecoreCD:WebRoot" -Value $SitecoreCDWebRoot -Type NoteProperty
        }

        # Add IdentityServer:WebRoot
        If ($null -eq $Parameters."IdentityServer:WebRoot") {
            $IdentityServerWebRoot = @{
                Type        = "String"
                Reference   = "WebRoot"
                Description = "Override to pass WebRoot"
            }
            $Parameters | Add-Member -Name "IdentityServer:WebRoot" -Value $IdentityServerWebRoot -Type NoteProperty
        }

        # Add IdentityServerCertificates:RootCertFileName
        If ($null -eq $Parameters."IdentityServerCertificates:RootCertFileName") {
            $IdentityServerCertificatesRootCertFileName = @{
                Type        = "String"
                Reference   = "RootCertFileName"
                Description = "Override to pass RootCertFileName"
            }
            $Parameters | Add-Member -Name "IdentityServerCertificates:RootCertFileName" -Value $IdentityServerCertificatesRootCertFileName -Type NoteProperty
        }

        # Add CertPath
        If ($null -eq $Parameters.CertPath) {
            $CertPath = @{
                Type = "String"
                Description = "The physical path on disk where certificates will be stored."
                DefaultValue =  "C:\certificates"
            }
            $Parameters | Add-Member -Name "CertPath" -Value $CertPath -Type NoteProperty
        }

        # Add IdentityServerCertificates:CertPath
        If ($null -eq $Parameters."IdentityServerCertificates:CertPath") {
            $IdentityServerCertificatesCertPath = @{
                Type = "String"
                Description = "Override to pass CertPath"
                Reference =  "CertPath"
            }
            $Parameters | Add-Member -Name "IdentityServerCertificates:CertPath" -Value $IdentityServerCertificatesCertPath -Type NoteProperty
        }

        # Add ExportPassword
        If ($null -eq $Parameters.ExportPassword) {
            $ExportPassword = @{
                Type = "String"
                Description = "Password to export certificates with."
                DefaultValue = "SIF-Default"
            }
            $Parameters | Add-Member -Name "ExportPassword" -Value $ExportPassword -Type NoteProperty
        }

        # Add IdentityServerCertificates:CertPath
        If ($null -eq $Parameters."IdentityServerCertificates:ExportPassword") {
            $IdentityServerCertificatesExportPassword = @{
                Type = "String"
                Description = "Override to pass ExportPassword"
                Reference =  "ExportPassword"
            }
            $Parameters | Add-Member -Name "IdentityServerCertificates:ExportPassword" -Value $IdentityServerCertificatesExportPassword -Type NoteProperty
        }

        $Includes = $XM_Config.Includes
        $Includes.IdentityServerCertificates.Source = $SitecoreXM1.SIF_Files.CreateCert
        $Includes.IdentityServer.Source = $SitecoreXM1.SIF_Files.IdentityServer
        $Includes.SitecoreSolr.Source = $SitecoreXM1.SIF_Files.Solr
        $Includes.SitecoreCM.Source = $SitecoreXM1.SIF_Files.CM
        $Includes.SitecoreCD.Source = $SitecoreXM1.SIF_Files.CD

        $XM_Config | ConvertTo-Json -Depth 100 | % Replace "\u0027" "'" | Set-Content $SitecoreXM1.SIF_Files.XM_SingleDeveloper
    }
    catch {
        write-host "Modify-XM1-SIF-Config Failed" -ForegroundColor Red
        throw
    }
}



Function Install-XM1 {
    try {
        Write-Host "**************************************************************************" -ForegroundColor Yellow
        Write-Host "Install Sitecore 9.1 - XM1" -ForegroundColor Green
        Write-Host "**************************************************************************" -ForegroundColor Yellow


        Install-SitecoreConfiguration @singleDeveloperParams *>&1 | Tee-Object (Join-Path -Path $logPath -ChildPath XM1-SingleDeveloper.log)
        # Add-AppPoolMembership -hostName $SitecoreContentManagementSitename
        # Add-AppPoolMembership -hostName $SitecoreContentDeliverySitename

        Write-Host "**************************************************************************" -ForegroundColor Yellow
        Write-Host "Install Sitecore 9.1 - XM1 Successfully" -ForegroundColor Green
        Write-Host "Instance CM: $($SitecoreContentManagementSitename)" -ForegroundColor Green
        Write-Host "Instance CD: $($SitecoreContentDeliverySitename)" -ForegroundColor Green
        Write-Host "Indentity Server: $($IdentityServerSiteName)" -ForegroundColor Green
        Write-Host "Sitecore Admin Password: $($sitecore.SitecoreAdminPassword)" -ForegroundColor Green
        Write-Host "Identity Server Export Password: $($IdentityServerExportPassword)" -ForegroundColor Green
        Write-Host "**************************************************************************" -ForegroundColor Yellow
    }
    catch {
        write-host "Install Sitecore 9.1 - XM1 Failed" -ForegroundColor Red
        throw
    }
}

Function Uninstall-XM1 {
    try {
        Write-Host "**************************************************************************" -ForegroundColor Yellow
        Write-Host "UN-install Sitecore 9.1 - XM1" -ForegroundColor Green
        Write-Host "Instance CM: $($SitecoreContentManagementSitename)" -ForegroundColor Green
        Write-Host "Instance CD: $($SitecoreContentDeliverySitename)" -ForegroundColor Green
        Write-Host "Indentity Server: $($IdentityServerSiteName)" -ForegroundColor Green
        Write-Host "**************************************************************************" -ForegroundColor Yellow

        Uninstall-SitecoreConfiguration @singleDeveloperParams *>&1 | Tee-Object (Join-Path -Path $logPath -ChildPath XM1-SingleDeveloper-Uninstall.log)
        Remove-AppPoolMembership -hostName $SitecoreContentManagementSitename
        # Remove-AppPoolMembership -hostName $SitecoreContentDeliverySitename
    }
    catch {
        write-host "Uninstall Sitecore 9.1 - XM1 Failed: " -ForegroundColor Red
        throw
    }
}

Write-Host "Extracting XM1 package ...................." -ForegroundColor Green
Extract-XM1-Packages -XM1PackagePath $xm1ZipFile -AssetsFolder $assetsFolder -XM1_SIF_ZipFile $SitecoreXM1.SIFPackages


Write-Host "Confirm Prerequisites" -ForegroundColor Green
Confirm-Prerequisites

Write-Host "Install SIF ..............................." -ForegroundColor Green
Install-SitecoreInstallFramework

Write-Host "Modifying SIFs ............................" -ForegroundColor Green
Modify-SIF-WebRoot

Write-Host "Modifying XM1 SIF ........................." -ForegroundColor Green
Modify-XM1-SIF-Config

Push-Location $PSScriptRoot
If ($Uninstall) {
    Uninstall-XM1      
} Else {
    Install-XM1
}
Pop-Location