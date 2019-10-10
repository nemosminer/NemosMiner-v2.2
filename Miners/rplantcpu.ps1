if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-Opt4020\cpuminer-sse42.exe" #Intel
#$Path = ".\Bin\CPU-Opt4020\cpuminer-ryzen.exe" #AMD
$Uri = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/4.0.20/cpuminer-opt-win.zip"

$Commands = [PSCustomObject]@{
    "yescryptr8" = " -a yescryptr8" #YescryptR8
    "power2b" = " -a power2b" #power2b
    
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    $ThreadCount = $Variables.ProcessorCount - 2 
    

    $Algo = Get-Algorithm($_)
        If ($Algo -eq "yescryptr8" -and $Pools.($Algo).Host -like "*nlpool*") { return }
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
