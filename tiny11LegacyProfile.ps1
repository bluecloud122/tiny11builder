<#
.SYNOPSIS
    Applies conservative settings for Windows images intended for 1 GB-class PCs.

.DESCRIPTION
    This profile intentionally leaves Windows Update, Microsoft Defender, and the
    component store available in the regular tiny11 image. It only disables
    services and visual/background features that are disproportionately expensive
    on a very low-memory machine.
#>

function Set-Tiny11LegacyRegistryValue {
    param (
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Type,
        [Parameter(Mandatory = $true)][string]$Value
    )

    & 'reg' 'add' $Path '/v' $Name '/t' $Type '/d' $Value '/f' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not set $Path\$Name (exit code $LASTEXITCODE)."
    }
}

function Invoke-Tiny11LowRamProfile {
    param (
        [string]$SystemHive = 'HKLM\zSYSTEM',
        [string]$SoftwareHive = 'HKLM\zSOFTWARE',
        [string]$DefaultHive = 'HKLM\zDEFAULT',
        [string]$UserHive = 'HKLM\zNTUSER'
    )

    Write-Output "Applying the 1 GB-class low-RAM profile..."

    # Keep services in shared host processes on systems below the normal split
    # threshold. This reduces process overhead on machines with 1-2 GB of RAM.
    Set-Tiny11LegacyRegistryValue "$SystemHive\ControlSet001\Control" `
        'SvcHostSplitThresholdInKB' 'REG_DWORD' '3670016'

    # SysMain and Windows Search can create sustained paging/indexing activity on
    # the HDDs commonly found in this class of older laptop. They can be
    # re-enabled later with services.msc if the owner prefers those features.
    foreach ($serviceName in @('SysMain', 'WSearch', 'DiagTrack')) {
        Set-Tiny11LegacyRegistryValue "$SystemHive\ControlSet001\Services\$serviceName" `
            'Start' 'REG_DWORD' '4'
    }

    # Do not let web search, location-aware search, or consumer suggestions
    # start background work on the target device.
    Set-Tiny11LegacyRegistryValue "$SoftwareHive\Policies\Microsoft\Windows\Windows Search" `
        'AllowCortana' 'REG_DWORD' '0'
    Set-Tiny11LegacyRegistryValue "$SoftwareHive\Policies\Microsoft\Windows\Windows Search" `
        'DisableWebSearch' 'REG_DWORD' '1'
    Set-Tiny11LegacyRegistryValue "$SoftwareHive\Policies\Microsoft\Windows\Windows Search" `
        'ConnectedSearchUseWeb' 'REG_DWORD' '0'
    Set-Tiny11LegacyRegistryValue "$SoftwareHive\Policies\Microsoft\Windows\Windows Search" `
        'AllowSearchToUseLocation' 'REG_DWORD' '0'

    foreach ($hive in @($DefaultHive, $UserHive)) {
        Set-Tiny11LegacyRegistryValue "$hive\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
            'EnableTransparency' 'REG_DWORD' '0'
        Set-Tiny11LegacyRegistryValue "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            'VisualFXSetting' 'REG_DWORD' '3'
        Set-Tiny11LegacyRegistryValue "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            'TaskbarAnimations' 'REG_DWORD' '0'
        Set-Tiny11LegacyRegistryValue "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            'TaskbarDa' 'REG_DWORD' '0'
        Set-Tiny11LegacyRegistryValue "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            'SearchboxTaskbarMode' 'REG_DWORD' '0'
        Set-Tiny11LegacyRegistryValue "$hive\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
            'GlobalUserDisabled' 'REG_DWORD' '1'
    }

    Set-Tiny11LegacyRegistryValue "$DefaultHive\Control Panel\Desktop\WindowMetrics" `
        'MinAnimate' 'REG_SZ' '0'
    Set-Tiny11LegacyRegistryValue "$UserHive\Control Panel\Desktop\WindowMetrics" `
        'MinAnimate' 'REG_SZ' '0'

    Write-Output "Low-RAM profile applied; this profile does not change Windows Update or Defender state."
}