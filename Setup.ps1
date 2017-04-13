# TODO: Add retrie input instead of error

#### FUNCTIONS ####

function Create-Shortcut
{
    param
    (
        [Parameter()]
        [string]$Name,

        [Parameter()]
        [string]$Destination,

        [Parameter()]
        [string]$Environment,

        [Parameter()]
        [string]$Icon


    )

    $WshShell = New-Object -ComObject WScript.Shell

    $target = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
    $lnk = [Environment]::GetFolderPath($Destination) + "\$Name.lnk"
    $Shortcut = $WshShell.CreateShortcut($lnk)
    $Shortcut.TargetPath = $target
    $Shortcut.Arguments = "-NoExit -File " + "`"$PSScriptRoot\Env\" + $Environment +"`""
    $Shortcut.IconLocation = "$PSScriptRoot\Icons\" + $Icon;
    $Shortcut.WorkingDirectory =$PSScriptRoot
    
    $Shortcut.Save()
}

#### BEGIN ####

# LNK NAME
Write-Host "Set shortcut name: " -NoNewline 
$name = Read-Host
Write-Host

# LNK ICON
while ($true)
{
    Write-Host "Available icons: "
    $icons = Get-ChildItem -Path "$PSScriptRoot\Icons" 
    $icons | % {$i = 0} {"[$i] $_"; $i++ }

    Write-Host "Select ico index: " -NoNewline
    [System.Int32] $icon = Read-Host 
    Write-Host

    if (($icon -lt 0) -OR ($icon -ge $icons.Length))
    {
        Write-Host "Wrong icon index!!" -ForegroundColor Red
        continue;
    }
    else
    {
        break
    }
}

# LNK ENV
while ($true)
{
    Write-Host "Available environments: "
    $environments = Get-ChildItem -Path "$PSScriptRoot\Env" 
    $environments | % {$i = 0} {"[$i] $_"; $i++ }

    Write-Host "Select environment index: " -NoNewline
    [System.Int32] $environment = Read-Host 
    Write-Host

    if (($environment -lt 0) -OR ($environment -ge $environments.Length))
    {
        Write-Host "Wrong environment index!!" -ForegroundColor Red
        continue
    }
    else
    {
        break
    }
}

# LNK AUTOSTART
while ($true)
{
    Write-Host "Add shortcut to autostart?(y\n): " -NoNewline 
    $autostart = Read-Host
    Write-Host

    if (($autostart.ToLower() -notlike "y") -AND ($autostart.ToLower() -notlike "n"))
    {
        Write-Host "Wrong unswer!!" -ForegroundColor Red
        continue
    }
    else
    {
        break
    }
}


# LNK CREATE

Create-Shortcut -Name $name -Destination "Desktop" -Environment  $environments[$environment] -Icon $icons[$icon]

if ($autostart.ToLower() -like "y")
{
    Create-Shortcut -Name $name -Destination "Startup" -Environment  $environments[$environment] -Icon $icons[$icon]
}