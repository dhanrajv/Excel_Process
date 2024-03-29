<#
.SYNOPSIS 
    Deploy NuGet package files to orchestrator

.DESCRIPTION 
    This script is to deploy NuGet package files (*.nupkg) to Cloud or On-Prem orchestrator.

.PARAMETER packages_path 
     Required. The path to a folder containing packages, or to a package file.

.PARAMETER orchestrator_url 
    Required. The URL of the Orchestrator instance.

.PARAMETER orchestrator_tenant 
    Required. The tenant of the Orchestrator instance.

.PARAMETER accountForApp 
    The Orchestrator CloudRPA account name. Must be used together with id, secret and scope(s) for external application.

.PARAMETER applicationId 
    The external application id. Must be used together with account, secret and scope(s) for external application.

.PARAMETER applicationSecret 
    The external application secret. Must be used together with account, id and scope(s) for external application.

.PARAMETER applicationScope 
    The space-separated list of application scopes. Must be used together with account, id and secret for external application.

.PARAMETER orchestrator_user
    Required. The Orchestrator username used for authentication. Must be used together with the password.

.PARAMETER orchestrator_pass
    Required. The Orchestrator password used for authentication. Must be used together with the username

.PARAMETER UserKey
    Required. The Orchestrator OAuth2 refresh token used for authentication. Must be used together with the account name and client id.

.PARAMETER account_name
    Required. The Orchestrator CloudRPA account name. Must be used together with the refresh token and client id.

.PARAMETER folder_organization_unit
    The Orchestrator folder (organization unit).

.PARAMETER environment_list
    The comma-separated list of environments to deploy the package to. If the environment does not belong to the default folder (organization unit) it must be prefixed with the folder name, e.g. AccountingTeam\TestEnvironment

.PARAMETER entryPoints
    Define the specific entry points to create or update a process. This is the filePath of the entry point starting from the root of the project. For classic folders only one entry point can be specified, for each environment it will be created or updated a process with the specified entry point.

.PARAMETER language
    The orchestrator language.

.PARAMETER disableTelemetry
    Disable telemetry data.

.PARAMETER uipathCliFilePath
    if not provided, the script will auto download the cli from uipath public feed. the script was testing on version 22.10.8432.18709. if provided, it is recommended to have cli version 22.10.8432.18709 

.EXAMPLE
SYNTAX
    . '\UiPathDeploy.ps1'  <packages_path> <orchestrator_url> <orchestrator_tenant> [-orchestrator_user <orchestrator_user> -orchestrator_pass <orchestrator_pass>] [-UserKey <auth_token> -account_name <account_name>] [-accountForApp <account_for_app> -applicationId <application_id> -applicationSecret <application_secret> -applicationScope <applicationScope>] [-folder_organization_unit <folder_organization_unit>] [-environment_list <environment_list>] [-language <language>]

  Examples:
    . '\UiPathDeploy.ps1' "C:\UiPath\Project 1" "https://uipath-orchestrator.myorg.com" default -orchestrator_user admin -orchestrator_pass 123456
    . '\UiPathDeploy.ps1' "C:\UiPath\Project\Package.1.0.6820.22047.nupkg" "https://uipath-orchestrator.myorg.com" default -orchestrator_user admin -orchestrator_pass 123456 -folder_organization_unit OurOrganization
    . '\UiPathDeploy.ps1' "C:\UiPath\Project\TestsPackage.1.0.6820.22047.nupkg" "https://uipath-orchestrator.myorg.com" default -orchestrator_user admin -orchestrator_pass 123456 -environment_list SAPEnvironment,ExcelAutomationEnvironment -language en-US
    . '\UiPathDeploy.ps1' "C:\UiPath\Project\Package.1.0.6820.22047.nupkg" "https://uipath-orchestrator.myorg.com" default -UserKey a7da29a2c93a717110a82 -account_name myAccount
    . '\UiPathDeploy.ps1' "C:\UiPath\Project\TestsPackage.1.0.6820.22047.nupkg" "https://uipath-orchestrator.myorg.com" default -accountForApp myAccountForExternalApp -applicationId myExternalAppId -applicationSecret myExternalAppSecret -applicationScope "OR.Folders.Read OR.Settings.Read"
    . '\UiPathDeploy.ps1' "C:\UiPath\Project\TestsPackage.1.0.6820.22047.nupkg" "https://uipath-orchestrator.myorg.com" default -orchestrator_user admin -orchestrator_pass 123456 -environment_list SAPEnvironment,ExcelAutomationEnvironment -language en-US -entryPoints EntryPoint1,EntryPoint2
#>
Param (

    #Required
	[string] $packages_path = "", # Required. The path to a folder containing packages, or to a package file.
	[string] $orchestrator_url = "", #Required. The URL of the Orchestrator instance.
	[string] $orchestrator_tenant = "", #Required. The tenant of the Orchestrator instance.

    #External Apps (Option 1)
    [string] $accountForApp = "", #The Orchestrator CloudRPA account name. Must be used together with id, secret and scope(s) for external application.
    [string] $applicationId = "", #Required. The external application id. Must be used together with account, secret and scope(s) for external application.
    [string] $applicationSecret = "", #Required. The external application secret. Must be used together with account, id and scope(s) for external application.
    [string] $applicationScope = "", #Required. The space-separated list of application scopes. Must be used together with account, id and secret for external application.
    #API Access - (Option 2)
    [string] $account_name = "", #Required. The Orchestrator CloudRPA account name. Must be used together with the refresh token and client id.
	[string] $UserKey = "", #Required. The Orchestrator OAuth2 refresh token used for authentication. Must be used together with the account name and client id.
    
    #On prem -  (Option 3)
    [string] $orchestrator_user = "", #Required. The Orchestrator username used for authentication. Must be used together with the password.
	[string] $orchestrator_pass = "", #Required. The Orchestrator password used for authentication. Must be used together with the username
	
	[string] $folder_organization_unit = "", #The Orchestrator folder (organization unit).
	[string] $language = "", #The orchestrator language.  
    [string] $environment_list = "", #The comma-separated list of environments to deploy the package to. If the environment does not belong to the default folder (organization unit) it must be prefixed with the folder name, e.g. AccountingTeam\TestEnvironment
    [string] $entryPoints = "", #Define the specific entry points to create or update a process. This is the filePath of the entry point starting from the root of the project. For classic folders only one entry point can be specified, for each environment it will be created or updated a process with the specified entry point.
    [string] $disableTelemetry = "", #Disable telemetry data.   
    [string] $uipathCliFilePath = "" #if not provided, the script will auto download the cli from uipath public feed. the script was testing on version 22.10.8438.32859
    
    
    

)
#Log function
function WriteLog
{
	Param ($message, [switch] $err)
	
	$now = Get-Date -Format "G"
	$line = "$now`t$message"
	$line | Add-Content $debugLog -Encoding UTF8
	if ($err)
	{
		Write-Host $line -ForegroundColor red
	} else {
		Write-Host $line
	}
}
#Running Path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
#log file
$debugLog = "$scriptPath\orchestrator-package-deploy.log"

#Validate provided cli folder (if any)

    #Verifying UiPath CLI installation
    $cliVersion = "22.10.8438.32859"; #CLI Version (Script was tested on this latest version at the time)

    $uipathCLI = "$scriptPath\uipathcli\$cliVersion\tools\uipcli.exe"
    if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
        WriteLog "UiPath CLI does not exist in this folder. Attempting to download it..."
        try {
            if (-not(Test-Path -Path "$scriptPath\uipathcli\$cliVersion" -PathType Leaf)){
                New-Item -Path "$scriptPath\uipathcli\$cliVersion" -ItemType "directory" -Force | Out-Null
            }
            #Download UiPath CLI
            #Invoke-WebRequest "https://www.myget.org/F/uipath-dev/api/v2/package/UiPath.CLI/$cliVersion" -OutFile "$scriptPath\\uipathcli\\$cliVersion\\cli.zip";
            Invoke-WebRequest "https://uipath.pkgs.visualstudio.com/Public.Feeds/_apis/packaging/feeds/1c781268-d43d-45ab-9dfc-0151a1c740b7/nuget/packages/UiPath.CLI.Windows/versions/$cliVersion/content" -OutFile "$scriptPath\\uipathcli\\$cliVersion\\cli.zip";
            Expand-Archive -LiteralPath "$scriptPath\\uipathcli\\$cliVersion\\cli.zip" -DestinationPath "$scriptPath\\uipathcli\\$cliVersion";
            WriteLog "UiPath CLI is downloaded and extracted in folder $scriptPath\uipathcli\\$cliVersion"
            if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
                WriteLog "Unable to locate uipath cli after it is downloaded."
                exit 1
            }
        }
        catch {
            WriteLog ("Error Occured : " + $_.Exception.Message) -err $_.Exception
            exit 1
        }
        
    }

WriteLog "-----------------------------------------------------------------------------"
WriteLog "uipcli location :   $uipathCLI"
#END Verifying UiPath CLI installation


$ParamList = New-Object 'Collections.Generic.List[string]'

#region Verifying required paramteters
if($packages_path -eq "" -or $orchestrator_url -eq "" -or $orchestrator_tenant -eq "") 
{
    WriteLog "Fill the required paramters (packages_path, orchestrator_url, orchestrator_tenant)"
    exit 1
}

#endregion Verifying required paramteters

#Building uipath cli paramters
$ParamList.Add("package")
$ParamList.Add("deploy")
$ParamList.Add($packages_path)
$ParamList.Add($orchestrator_url)
$ParamList.Add($orchestrator_tenant)

if($applicationId -ne ""){
    $ParamList.Add("--applicationId")
    $ParamList.Add($applicationId)
}
if($applicationSecret -ne ""){
    $ParamList.Add("--applicationSecret")
    $ParamList.Add($applicationSecret)
}
WriteLog $applicationScope
if($applicationScope -ne ""){
    $ParamList.Add("--applicationScope")
    $ParamList.Add($applicationScope)
}


#mask sensitive info before logging 


#log cli call with parameters
WriteLog "Executing $uipathCLI"
WriteLog "-----------------------------------------------------------------------------"

#call uipath cli 
& "$uipathCLI" $ParamList.ToArray()

if($LASTEXITCODE -eq 0)
{
    WriteLog "Done!"
    Exit 0
}else {
    WriteLog "Unable to deploy project. Exit code $LASTEXITCODE"
    Exit 1
}
