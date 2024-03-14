Param (

    #Required
    
    [string] $processName = "", #Process Name (pos. 0)           Required.
    [string] $uriOrch = "", #Orchestrator URL (pos. 1)       Required. The URL of the Orchestrator instance.
    [string] $tenantlName = "", #Orchestrator Tenant (pos. 2)    Required. The tenant of the Orchestrator instance.

    #External Apps (Option 1)
    [string] $accountForApp = "", #The Orchestrator CloudRPA account name. Must be used together with id, secret and scope(s) for external application.
    [string] $applicationId = "", #Required. The external application id. Must be used together with account, secret and scope(s) for external application.
    [string] $applicationSecret = "", #Required. The external application secret. Must be used together with account, id and scope(s) for external application.
    [string] $applicationScope = "", #Required. The space-separated list of application scopes. Must be used together with account, id and secret for external application.

    #API Access - (Option 2)
    [string] $accountName = "", #Required. The Orchestrator CloudRPA account name. Must be used together with the refresh token and client id.
    [string] $userKey = "", #Required. The Orchestrator OAuth2 refresh token used for authentication. Must be used together with the account name and client id.
    
    #On prem UserName & Password - (Option 3) 
    [string] $orchestrator_user = "", #Required. The Orchestrator username used for authentication. Must be used together with the password.
    [string] $orchestrator_pass = "", #Required. The Orchestrator password used for authentication. Must be used together with the username.
	
    [string] $input_path = "", #The full path to a JSON input file. Only required if the entry-point workflow has input parameters.
    [string] $jobscount = "", #The number of job runs. (default 1)
    [string] $result_path = "", #The full path to a JSON file or a folder where the result json file will be created.
    [string] $priority = "", #The priority of job runs. One of the following values: Low, Normal, High. (default Normal)
    [string] $robots = "", #The comma-separated list of specific robot names.
    [string] $folder_organization_unit = "", #The Orchestrator folder (organization unit).
    [string] $language = "", #The orchestrator language.  
    [string] $user = "", #The name of the user. This should be a machine user, not an orchestrator user. For local users, the format should be MachineName\UserName
    [string] $machine = "", #The name of the machine.
    [string] $timeout = "", #The timeout for job executions in seconds. (default 1800)
    [string] $fail_when_job_fails = "", #The command fails when at least one job fails. (default true)
    [string] $wait = "", #The command waits for job runs completion. (default true)
    [string] $job_type = "", #The type of the job that will run. Values supported for this command: Unattended, NonProduction. For classic folders do not specify this argument
    [string] $disableTelemetry = "" #Disable telemetry data.   

)
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
$debugLog = "$scriptPath\orchestrator-job-run.log"

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

#Building uipath cli paramters
$ParamList.Add("job")
$ParamList.Add("run")
$ParamList.Add($processName)
$ParamList.Add($uriOrch)
$ParamList.Add($tenantlName)


if($applicationId -ne ""){
    $ParamList.Add("--applicationId")
    $ParamList.Add($applicationId)
}
if($applicationSecret -ne ""){
    $ParamList.Add("--applicationSecret")
    $ParamList.Add($applicationSecret)
}
if($applicationScope -ne ""){
    $ParamList.Add("--applicationScope")
    $ParamList.Add($applicationScope)
}
if($result_path -ne ""){
    $ParamList.Add("--result_path")
    $ParamList.Add($result_path)
}
if($robots -ne ""){
    $ParamList.Add("--robots")
    $ParamList.Add($robots)
}
if($folder_organization_unit -ne ""){
    $ParamList.Add("--organizationUnit")
    $ParamList.Add($folder_organization_unit)
}
if($job_type -ne ""){
    $ParamList.Add("--job_type")
    $ParamList.Add($job_type)
}

#log cli call with parameters
WriteLog "Executing $uipathCLI $ParamMask"
WriteLog "-----------------------------------------------------------------------------"

#call uipath cli 
& "$uipathCLI" $ParamList.ToArray()

if($LASTEXITCODE -eq 0)
{
    WriteLog "Done!"
    Exit 0
}else {
    WriteLog "Unable to run process. Exit code $LASTEXITCODE"
    Exit 1
}
