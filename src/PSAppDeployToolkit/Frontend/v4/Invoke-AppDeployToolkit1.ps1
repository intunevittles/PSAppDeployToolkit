[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [string]$DeploymentType = 'Install',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [string]$DeployMode = 'Interactive',

    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru,

    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode,

    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging
)

##================================================
## MARK: Variables
##================================================
## TODO Variables: Application metadata overrides
$adtSession = @{
    AppVendor           = ''     ## TODO: Set publisher, e.g. 'VideoLAN'
    AppName             = ''     ## TODO: Set product name, e.g. 'VLC Media Player'
    AppVersion          = ''     ## TODO: Set version, e.g. '3.0.20'
    AppArch             = ''
    AppLang             = 'EN'
    AppRevision         = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes  = @(1641, 3010)
    AppScriptVersion    = '1.0.0'
    AppScriptDate       = '2000-12-31'
    AppScriptAuthor     = '<author name>'
    InstallName         = ''
    InstallTitle        = ''
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptVersion      = '4.0.5'
    DeployAppScriptParameters   = $PSBoundParameters
}

function Install-ADTDeployment {
    ##================================================
    ## MARK: Pre-Install
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    ## TODO UI Prompt: Customize welcome message/deferral behavior
    Show-ADTInstallationWelcome -CloseProcesses iexplore -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
    Show-ADTInstallationProgress

    ## TODO Pre-Install: Insert any pre-install tasks here


    ##================================================
    ## MARK: Install
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## TODO Installer logic: Insert actual install call here
    # Example:
    # Start-Process -FilePath "$envProgramData\win32app\$ctx.Application\Files\vlc.exe" -ArgumentList "/S" -Wait

    ## TODO: Handle MSI logic only if using MSI
    if ($adtSession.UseDefaultMsi) {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile) {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
        if ($adtSession.DefaultMspFiles) {
            $adtSession.DefaultMspFiles | Start-ADTMsiProcess -Action Patch
        }
    }

    ##================================================
    ## MARK: Post-Install
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    ## TODO Post-Install: Insert any cleanup or config tasks here

    ## TODO UI Prompt: Customize or remove success message
    if (!$adtSession.UseDefaultMsi) {
        Show-ADTInstallationPrompt -Message 'Installation complete.' -ButtonRightText 'OK' -Icon Information -NoWait
    }
}

function Uninstall-ADTDeployment {
    ##================================================
    ## MARK: Pre-Uninstall
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"
    ## TODO UI Prompt: Customize for close apps and countdown
    Show-ADTInstallationWelcome -CloseProcesses iexplore -CloseProcessesCountdown 60
    Show-ADTInstallationProgress

    ##================================================
    ## MARK: Uninstall
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## TODO Uninstall logic: Add custom uninstall logic if needed
    if ($adtSession.UseDefaultMsi) {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile) {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }

    ##================================================
    ## MARK: Post-Uninstallation
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"
    ## TODO Post-Uninstall: Cleanup tasks, logging, UI
}

function Repair-ADTDeployment {
    ##================================================
    ## MARK: Pre-Repair
    ##================================================
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"
    Show-ADTInstallationWelcome -CloseProcesses iexplore -CloseProcessesCountdown 60
    Show-ADTInstallationProgress

    ##================================================
    ## MARK: Repair
    ##================================================
    $adtSession.InstallPhase = $adtSession.DeploymentType

    ## TODO Repair logic: if applicable
    if ($adtSession.UseDefaultMsi) {
        $ExecuteDefaultMSISplat = @{ Action = $adtSession.DeploymentType; FilePath = $adtSession.DefaultMsiFile }
        if ($adtSession.DefaultMstFile) {
            $ExecuteDefaultMSISplat.Add('Transform', $adtSession.DefaultMstFile)
        }
        Start-ADTMsiProcess @ExecuteDefaultMSISplat
    }

    ##================================================
    ## MARK: Post-Repair
    ##================================================
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"
    ## TODO Post-Repair: cleanup or confirmation
}

##================================================
## MARK: Initialization
##================================================

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 1

try {
    $moduleName = if (Test-Path "$PSScriptRoot\..\..\..\PSAppDeployToolkit\PSAppDeployToolkit.psd1") {
        Get-ChildItem -LiteralPath $PSScriptRoot\..\..\..\PSAppDeployToolkit -Recurse -File | Unblock-File -ErrorAction Ignore
        "$PSScriptRoot\..\..\..\PSAppDeployToolkit\PSAppDeployToolkit.psd1"
    } else {
        'PSAppDeployToolkit'
    }

    Import-Module -FullyQualifiedName @{
        ModuleName    = $moduleName
        Guid          = '8c3c366b-8606-4576-9f2d-4051144f7ca2'
        ModuleVersion = '4.0.5'
    } -Force

    $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
    $adtSession = Open-ADTSession -SessionState $ExecutionContext.SessionState @adtSession @iadtParams -PassThru
}
catch {
    Remove-Module -Name PSAppDeployToolkit* -Force
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([int]::MaxValue)))
    exit 60008
}

##================================================
## MARK: Invocation
##================================================

try {
    Get-Item -Path "$PSScriptRoot\PSAppDeployToolkit.*" | & {
        process {
            Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Unblock-File -ErrorAction Ignore
            Import-Module -Name $_.FullName -Force
        }
    }

    & "$($adtSession.DeploymentType)-ADTDeployment"
    Close-ADTSession
}
catch {
    Write-ADTLogEntry -Message ($mainErrorMessage = Resolve-ADTErrorRecord -ErrorRecord $_) -Severity 3
    Show-ADTDialogBox -Text $mainErrorMessage -Icon Stop | Out-Null
    Close-ADTSession -ExitCode 60001
}
finally {
    Remove-Module -Name PSAppDeployToolkit* -Force
}