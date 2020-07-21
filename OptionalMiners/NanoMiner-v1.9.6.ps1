using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nanominer.exe"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v1.9.6/nanominer-windows-1.9.6.zip"
$DeviceEnumerator = "Type_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; MinMemGB = 16; Type = "AMD"; Fee = 0.02; Command = "Cuckaroo30" } #Cortex
    [PSCustomObject]@{ Algorithm = "Ethash";        MinMemGB = 4;  Type = "AMD"; Fee = 0.01; Command = "Ethash" }
    [PSCustomObject]@{ Algorithm = "KawPoW";        MinMemGB = 4;  Type = "AMD"; Fee = 0.02; Command = "Kawpow" } #Broken???
    [PSCustomObject]@{ Algorithm = "UbqHash";       MinMemGB = 4;  Type = "AMD"; Fee = 0.01; Command = "Ubqhash" }

    [PSCustomObject]@{ Algorithm = "Ethash";      Type = "CPU"; Fee = 0.01; Command = "Ethash" }
    [PSCustomObject]@{ Algorithm = "RandomHash2"; Type = "CPU"; Fee = 0.05; Command = "RandomHash2" }
    [PSCustomObject]@{ Algorithm = "RandomX";     Type = "CPU"; Fee = 0.02; Command = "RandomX" }
    [PSCustomObject]@{ Algorithm = "UbqHash";     Type = "CPU"; Fee = 0.01; Command = "Ubqhash" }

    [PSCustomObject]@{ Algorithm = "Ethash";  MinMemGB = 4; Type = "NVIDIA"; Fee = 0.01; Command = "Ethash" }
    [PSCustomObject]@{ Algorithm = "UbqHash"; MinMemGB = 4; Type = "NVIDIA"; Fee = 0.01; Command = "Ubqhash" }
)

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -eq $_.Type | ForEach-Object { $Algo = $_.Algorithm | Select-Object -Index 0; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
            If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -like "ZergPool*") { return }
            $MinMemGB = $_.MinMemGB

            If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ([math]::Round((10 * $_.OpenCL.GlobalMemSize / 1GB), 0) / 10) -ge $MinMemGB })) { 
                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                $ConfigFileName = "$((@("Config") + @($_.Algorithm) + @($($Pools.($_.Algorithm).Name -replace "-Coins" -replace "24hr")) + @($Pools.($_.Algorithm).User) + @($Pools.($_.Algorithm).Pass) + @(($Miner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model($(($Miner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').ini"
                $Arguments = [PSCustomObject]@{ 
                    ConfigFile = [PSCustomObject]@{ 
                    FileName = $ConfigFileName
                    Content  = "
; NemoMiner autogenerated config file (c) nemosminer.com
checkForUpdates=false
$(If (($SelectedDevices.Vendor | Select-Object -Unique) -eq "NVIDIA") { 
    "coreClocks=+0"
    "memClocks=+0"
})
$(If (($SelectedDevices.Vendor | Select-Object -Unique) -eq "AMD") { 
    "memTweak=0"
})
mport=0
noLog=true
rigName=$($Config.WorkerName)
watchdog=false
webPort=$($MinerAPIPort)
useSSL=$($Pools.($_.Algorithm).SSL)
[$($_.Command)]
devices=$(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')
pool1=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)
wallet=$($Pools.($_.Algorithm).User)"
                    }
                    Commands = "$ConfigFileName"
                }

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Path       = $Path
                    Arguments  = $Arguments
                    Algorithm  = $_.Algorithm
                    API        = "NanoMiner"
                    Port       = $MinerAPIPort
                    URI        = $Uri
                    Fee        = $_.Fee
                    MinerUri   = "http://localhost:$($MinerAPIPort)/#/"
                }
            }
        }
    }
}
