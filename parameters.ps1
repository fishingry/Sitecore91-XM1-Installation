$downloadFolder = Join-Path -Path $PSScriptRoot -ChildPath "download"
$assetsFolder = Join-Path -Path $PSScriptRoot -ChildPath "assets"
$logPath = Join-Path -Path $PWD -ChildPath "logs"
$certificatesPath = Join-Path -Path $PWD -ChildPath "certificates"
$tempLocation = Join-Path -Path $PWD -ChildPath "Temp"
$xm1ZipFile = Join-Path -Path $downloadFolder -ChildPath "Sitecore 9.1.0 rev. 001564 (WDP XM1 packages).zip"

$WebRoot = "E:\Inetpub\wwwroot"
# The Prefix that will be used on SOLR, Website, Database instances and Publishing Service.
$Prefix = "XM910"

$SitecoreXM1 = @{
    SitecoreContentDeliveryPackage             = Join-Path -Path $assetsFolder -ChildPath "Sitecore XM 9.1.0 rev. 001564 (OnPrem)_cd.scwdp.zip"
    SiteCoreContentManagementPackage            = Join-Path -Path $assetsFolder -ChildPath "Sitecore XM 9.1.0 rev. 001564 (OnPrem)_cm.scwdp.zip"
    IdentityServerPackage  = Join-Path -Path $assetsFolder -ChildPath "Sitecore.IdentityServer 2.0.0 rev. 00157 (OnPrem)_identityserver.scwdp.zip"
    SIFPackages            = Join-Path -Path $assetsFolder -ChildPath "XM1 Configuration files 9.1.0 rev. 001564.zip"
    SIF_Files              = @{
        CreateCert         = Join-Path -Path $assetsFolder -ChildPath "createcert.json"
        IdentityServer     = Join-Path -Path $assetsFolder -ChildPath "identityServer.json"
        Solr               = Join-Path -Path $assetsFolder -ChildPath "sitecore-solr.json"
        CD                 = Join-Path -Path $assetsFolder -ChildPath "sitecore-XM1-cd.json"
        CM                 = Join-Path -Path $assetsFolder -ChildPath "sitecore-XM1-cm.json"
        XM_SingleDeveloper = Join-Path -Path $assetsFolder -ChildPath "XM1-SingleDeveloper.json"
    }
}

$solr = @{
    SolrUrl     = "https://localhost:8721/solr"             # The URL of the Solr Server
    SolrRoot    = "E:\Solr\721\solr-7.2.1"                           # The Folder that Solr has been installed in.
    SolrService = "Solr-7.2.1"                              # The Name of the Solr Service.
}


$SqlServer = @{
    Address          = "localhost"              # The DNS name or IP of the SQL Instance.
    SqlAdminUser     = "sa"                     # A SQL user with sysadmin privileges.
    SqlAdminPassword = 'Kimcu@123'                       # The password for $SQLAdminUser.
}


# The name for the Sitecore Content Delivery server.
$SitecoreContentManagementSitename = "$Prefix.cm.local"
# The name for the Sitecore Content Management Server.
$SitecoreContentDeliverySitename = "$Prefix.cd.local"
# Identity Server site name
$IdentityServerSiteName = "$Prefix.identityserver"
$IdentityServerExportPassword = $IdentityServerSiteName

$sitecore = @{
    WebRoot  = $WebRoot
    RootCertFileName = "Sitecore_91_XM1"
    # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
    SitecoreAdminPassword = "b"
     # The Identity Server password recovery URL, this should be the URL of the CM Instance
    PasswordRecoveryUrl = "http://$SitecoreContentManagementSitename"
    # The URL of the Identity Authority
    SitecoreIdentityAuthority = "https://$IdentityServerSiteName"
    # The random string key used for establishing connection with IdentityService. This will be regenerated if left on the default.
    ClientSecret = "SIF-Default"
    # Pipe-separated list of instances (URIs) that are allowed to login via Sitecore Identity.
    AllowedCorsOrigins = "https://$SitecoreContentManagementSitename"
    # The Path to the license file
    LicenseFile = Join-Path -Path $downloadFolder -ChildPath "license.xml"
}

$singleDeveloperParams = @{
    Path                              = $SitecoreXM1.SIF_Files.XM_SingleDeveloper
    SiteCoreContentManagementPackage  = $SitecoreXM1.SiteCoreContentManagementPackage
    SitecoreContentDeliveryPackage    = $SitecoreXM1.SitecoreContentDeliveryPackage
    IdentityServerPackage             = $SitecoreXM1.IdentityServerPackage
    SqlServer                         = $SqlServer.Address
    SqlAdminUser                      = $SqlServer.SqlAdminUser
    SqlAdminPassword                  = $SqlServer.SqlAdminPassword
    SolrUrl                           = $solr.SolrUrl
    SolrRoot                          = $solr.SolrRoot
    SolrService                       = $solr.SolrService
    Prefix                            = $Prefix
    SitecoreAdminPassword             = $sitecore.SitecoreAdminPassword
    IdentityServerCertificateName     = $IdentityServerSiteName
    IdentityServerSiteName            = $IdentityServerSiteName
    LicenseFile                       = $sitecore.LicenseFile
    SitecoreContentManagementSitename = $SitecoreContentManagementSitename
    SitecoreContentDeliverySitename   = $SitecoreContentDeliverySitename
    PasswordRecoveryUrl               = $sitecore.PasswordRecoveryUrl
    SitecoreIdentityAuthority         = $sitecore.SitecoreIdentityAuthority
    ClientSecret                      = $sitecore.ClientSecret
    AllowedCorsOrigins                = $sitecore.AllowedCorsOrigins
    WebRoot                           = $sitecore.WebRoot
    RootCertFileName                  = $sitecore.RootCertFileName
    CertPath                          = $certificatesPath
    ExportPassword                    = $IdentityServerExportPassword
}

####################### PUBLISHING SERVICE ###################################
$PublishingServiceInstance = "$($Prefix)_PublishingService"
$PublishingServicePort = 5001
$PublishingServiceConfig = @{
    PackagePath = Join-Path -Path $downloadFolder -ChildPath "Sitecore Publishing Service 4.0.0 rev. 00521-x64.zip"
    ContentPath = Join-Path -Path $WebRoot -ChildPath $PublishingServiceInstance
    CheckStatusUrl = "http://$($PublishingServiceInstance):$($PublishingServicePort)/api/publishing/operations/status"
}