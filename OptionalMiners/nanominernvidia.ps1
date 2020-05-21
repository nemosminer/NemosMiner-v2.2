using module ..\Includes\Include.psm1
$Path = ".\Bin\NVIDIA-nanominer194\nanominer.exe"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v1.9.4/nanominer-windows-1.9.4.zip"
$Commands = [PSCustomObject]@{ 
    #"Ethash" = "" #GPU Only
    "Ubqhash" = "" #GPU Only
    "Cuckaroo30" = "" #GPU Only
    #"RandomX" = "" #CPU only
    #"RandomHash2" = "" #CPU only
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    If ($Algo -eq "ethash" -and $Pools.$Algo.Host -like "*zergpool*") { return }
    Switch ($_) { 
        "randomhash" { $Fee = 0.05 } # substract devfee
        default { $Fee = 0.01 } # substract devfee
    }

    $ConfigFileName = "$((@("Config") + @($Algo) + @("GPU$($Config.SelGPUCC -replace ',', '')") + @($Algorithm_Norm) + @($Variables.NVIDIAMinerAPITCPPort) + @($Pools.$Algo.User) | Select-Object) -join '-').ini"
    $Arguments = [PSCustomObject]@{ 
        ConfigFile = [PSCustomObject]@{ 
        FileName = $ConfigFileName
        Content  = "
; NemoMiner autogenerated config file (c) nemosminer.com
checkForUpdates=false
mport=0
noLog=true
rigName=$($Config.WorkerName)
watchdog=false
webPort=$($Variables.NVIDIAMinerAPITCPPort)
[$($_)]
devices=$($Config.SelGPUCC)
pool1=$($Pools.$Algo.Host):$($Pools.$Algo.Port)
wallet=$($Pools.$Algo.User)"
        }
        Commands = "$ConfigFileName"
    }

    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = $Arguments
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * (1 - $Fee) } # substract devfee
        API       = "nanominer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}