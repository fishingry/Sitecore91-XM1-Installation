# Install Sitecore 9.1 Initial Release - XM Scaled (XM1) - OnPremises

## Folders Structure

```
|
|----- assets                       : created automatically, where the XM1 will be extracted
|----- certificates                 : created automatically, where the certificates will be exported
|----- logs                         : created automatically, where the log files will be stored
|----- download                     : put the XM1 package and license file in here
|           |---- Sitecore 9.1.0 rev. 001564 (WDP XM1 packages).zip
|           |---- license.xml
|----- Temp                         : where the download files for prerequisites, i.e. DacFrameworkx64.msi
|----- parameter.ps1                : Need to be modified before installing
|----- Install-Prerequisites.ps1
```

## Preparations

1. Download the [Sitecore 9.1.0 rev. 001564 (WDP XM1 packages).zip](https://dev.sitecore.net/~/media/B6F43F5FC9C54ED9A7425B76F134E08C.ashx). Then copy to `.\download` folder by following structure above.
2. Copy the `license.xml` file into the `.\download` folder as well

## Assumptions

1. [Solr 7.2.1](https://archive.apache.org/dist/lucene/solr/7.2.1/solr-7.2.1.zip) has been installed with the following requirements:
   - Support SSL which means that we only can access via **https**
   - It must be installed as Window Service via [Nssm 2.24](https://nssm.cc/release/nssm-2.24.zip)

2. [Microsoft PowerShell® version 5.1 or later](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
3. **Microsoft SQL Server 2017, 2016 SP2** has been installed
4. **IIS 10.0** has been installed

## (Optional) Install prerequisites for Sitecore 9.1

- Open PowerShell as Administrator
- Execute the command
  
    ```powershell
        .\Install-Prerequisites.ps1
    ```
- **Notes:** It might require restarting the machine. After restarted, just execute the above command again.

## Start Installing Sitecore 9.1 XM1

1. Open the file `parameters.ps1` by any text editor; then modify the corresponding values

    ```powershell
    $solr = @{
        SolrUrl     = "https://localhost:8721/solr"             # The URL of the Solr Server
        SolrRoot    = "E:\Solr\721\solr-7.2.1"                           # The Folder that Solr has been installed in.
        SolrService = "Solr-7.2.1"                              # The Name of the Solr Service.
    }

    $SqlServer = @{
        Address          = "localhost"              # The DNS name or IP of the SQL Instance.
        SqlAdminUser     = "sa"                     # A SQL user with sysadmin privileges.
        SqlAdminPassword = 'sa-password'                       # The password for $SQLAdminUser.
    }

    # The Prefix that will be used on SOLR, Website and Database instances.
    $Prefix = "XM910"

    $sitecore = @{
        WebRoot  = "E:\Inetpub\wwwroot"
        RootCertFileName = "Sitecore_91_XM1"
        # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
        SitecoreAdminPassword = "b"
        ####
        # ..... More code
        ####
    }
    ```
2. Next, execute the below command via PowerShell as Administrator to start installing

    ```powershell
    .\XM1-SingleDeveloper.ps1
    ```

3. After installed successfully, we can verify the CM and CD instance by the following steps (**Note:** assume the Sitecore instance has **XM910** as prefix)
   1. **CM** - Content Management Server
      - Access the Url - https://XM910.cm.local/sitecore
      - The credential account is: **admin/b**
    
   2. **CD** - Content Delivery Server
      - Access the Url - http://XM910.cd.local

## How to Uninstall Sitecore 9.1 XM1

It can be accomplished by simply executing the below command

```powershell
.\XM1-SingleDeveloper.ps1 -Uninstall
```