using module ..\Includes\Include.psm1

$Path = ".\Bin\Ethash-Claymore150\EthDcrMiner64.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v15.0/Claymoresethereumv15.0.7z"
$Commands = [PSCustomObject]@{ 
    #"ethash" = " -di $($($Config.SelGPUCC).Replace(',',''))" #Ethash -strap 1 -strap 2 -strap 3 -strap 4 -strap 5 -strap 6
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    If ($Algo -eq "ethash" -and $Pools.$Algo.Host -like "*zergpool*") { return }
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-wd 0 -esm 3 -allpools 1 -allcoins 1 -platform 2 -mode 1 -mport -$($Variables.NVIDIAMinerAPITCPPort) -epool $($Pools.$Algo.Host):$($Pools.$Algo.Port) -ewal $($Pools.$Algo.User) -epsw $($Pools.$Algo.Pass)$($Commands.$_)"
        Algorithm = $Algo
        API       = "ethminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #3333
        Wrap      = $false
        URI       = $Uri
        Fee       = 0.01 #devfee
    }
}
