param
(
    [Parameter(Mandatory=$true, Position = 0)]
    [string]$ComputerName,

    [Parameter(Mandatory=$false, Position = 1)]
    [string]$Domain = "iivc.local",

    [Parameter(Mandatory=$false, Position = 2)]
    [string]$Dns = "10.108.100.31",
              
    [Parameter(Mandatory=$True, Position = 4)]
    [ValidateSet(“Trunk”, ”4.2”, ”4.1”, ”4.0”, ”3.5.2”, ”3.5.1”)] 
    $ProductVersion = "Trunk",

    [Parameter(ParameterSetName=’Agent’, Mandatory=$True)]
    [switch]$Agent,

    [Parameter(ParameterSetName=’Agent’, Mandatory=$false)]
    [string]$BrokerName="IIVC-1-BR",

    [Parameter(ParameterSetName=’Broker’, Mandatory=$True)]
    [switch]$Broker
)

# === GLOBAL VARIABLES ===
$server = "\\10.108.13.31\_Norskale"

<#
.Synopsis
   Install Norskale products
#>
function Install-Wem()
{
    [CmdletBinding()]
    param
    (
       [Parameter(Mandatory=$true, Position = 0)]
       [ValidateSet(“Agent”,”Broker”,”Console”)]       
       $Name,
       
       [Parameter(Position = 1)]
       [ValidateSet(“Trunk”, "4.2", ”4.1”, ”4.0”, ”3.5.2”, ”3.5.1”)] 
       $Version = "Trunk"
    )

    $path = $server

    switch ($Version)
    {
        'Trunk' { $path = Join-Path -Path $path -ChildPath "_Trunk" }
        '4.2'   { $path = Join-Path -Path $path -ChildPath "_v4.02.00.00" }
        '4.1'   { $path = Join-Path -Path $path -ChildPath "_v4.01.00.00" }
        '4.0'   { $path = Join-Path -Path $path -ChildPath "_v4.00.00.00" }
        '3.5.2' { $path = Join-Path -Path $path -ChildPath "_v3.50.02.00" }
        '3.5.1' { $path = Join-Path -Path $path -ChildPath "_v3.50.01.00" }
    }

    switch ($Name)
    {
        'Agent'   {$path = Join-Path -Path $path -ChildPath "Agent Host" }
        'Broker'  {$path = Join-Path -Path $path -ChildPath "Infrastructure Services" }
        'Console' {$path = Join-Path -Path $path -ChildPath "Administration Console" }
    }

    $path = (dir -Path $path)[0].FullName
    $installer = ".\Installer-$Name-$Version.exe"
    
    Copy-Item -Path $path -Destination ".\$installer"
    
    Start-Process $installer -ArgumentList "/S /v/qn" -NoNewWindow -Wait
}

function Set-AgentBroker()
{
    param
    (
        [Parameter(Mandatory=$true, Position = 0)]
        $Name
    )
    
    $registryPath = "HKLM:\SOFTWARE\Policies\Norskale\Agent Host"    
    $key = "BrokerSvcName"

    if (-not(Test-Path -Path $registryPath))
    {

        New-Item -Path $registryPath -Force    
    }
    
    New-ItemProperty -Path $registryPath -Name $key -Value $Name -PropertyType String -Force
}

$credentials = Get-Credential

if ($PSCmdlet.ParameterSetName -eq "Agent")
{
    try
    {
        Install-Wem -Name "Agent" -Version $ProductVersion
        Set-AgentBroker -Name $BrokerName
    }
    Catch
    {
        Write-Error $_.Exception
    }
}

if ($PSCmdlet.ParameterSetName -eq "Broker")
{
    try
    {
        Install-Wem -Name "Broker" -Version $ProductVersion
        Install-Wem -Name "Console" -Version $ProductVersion
    }
    Catch
    {
        Write-Error $_.Exception
    }
}

try
{
     ### Configure Network Adapter ###
    $altDns = (Get-DnsClientServerAddress -InterfaceAlias "Ethernet 2").ServerAddresses[0]
    $adapter = Get-NetAdapter -Name "Ethernet 2" 
}
catch
{
    Write-Error $_.Exception
    exit
}

try
{
    # Configure the DNS client server IP addresses
    $adapter | Set-DnsClientServerAddress -ServerAddresses ($DNS,$altDns)
}
Catch
{
    Write-Error $_.Exception    
    exit
}

try
{
    ### Add Machine to the Domain ###
    Add-Computer -DomainName $Domain -Credential $credentials -Force
}
Catch
{
    Write-Error $_.Exception    
    exit
}

# For some reason the sript can't change computer name just after joining to a domain.
Start-Sleep -Seconds 2

try
{
    ### Rename Machine ###
    Rename-Computer -NewName $ComputerName -Force
}
Catch
{
    Write-Error $_.Exception    
    exit
}

try
{
    ### Turn off Firewall ###
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
}
Catch
{
    Write-Error $_.Exception    
    exit
}

Restart-Computer -Force