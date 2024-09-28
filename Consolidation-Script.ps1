################################################################################################################################
#
# VERSION 1.0.0
#
################################################################################################################################
#
# WARNING! - USE AT YOUR OWN RISK.
#
# THIS SCRIPT REQUIRES YOUR WALLET TO BE UNLOCKED!
#
# ONLY DOWNLOAD THIS SCRIPT AND ANY FUTURE UPDATES FROM A TRUSTED SOURCE.
#
# TO ALLOW THIS SCRIPT TO RUN:
#
# 1. Open Windows Powershell as Administrator
# 2. type "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Current User" press enter.
# 3. Edit the RPC info below, then run the script.
#
################################################################################################################################
#
# DIRECTROY PATH TO YOUR PULSAR-CLI
$PULSARDIR="C:\Program Files\Pulsar\daemon"
#
# WALLET RPC INFO
startScript -rpcIP "127.0.0.1" -rpcPort "5996" -rpcUser "user" -rpcPass "pass" -minConsolidation 100000
#
# UNCOMMENT TO RUN ON MULTIPLE WALLETS.
# startScript -rpcIP "127.0.0.1" -rpcPort "5996" -rpcUser "user" -rpcPass "pass" -minConsolidation 100000
#
################################################################################################################################
#
#                          DO NOT EDIT BELOW THIS LINE
#
################################################################################################################################



$Global:abandon = 0
$Global:consolidated = 0

function consolidate()
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]$rpcIP,
    [Parameter(Mandatory=$true)]$rpcPort,
    [Parameter(Mandatory=$true)]$rpcUser,
    [Parameter(Mandatory=$true)]$rpcPass,
    [Parameter(Mandatory=$true)]$minConsolidation
    )
    
    $data = ((& $PULSARDIR\pulsar-cli.exe -rpcconnect='"'$rpcIP'"' -rpcport="$rpcPort" -rpcuser="$rpcUser" -rpcpassword="$rpcPass" listunspent | ConvertFrom-Json))
    $data = $data | Where {[String]$_.spendable -eq [String]"True" -and $_.amount -lt $($minConsolidation)}

     

    if ($data.Count -lt 1)
    {
        Write-Host "No Transactions to Consolidate. Total: $Global:consolidated"
    }
    else
    {
        $groupedData = $data | Group-Object -Property address | Sort-Object -Property amount | ForEach-Object {

            $addressGroup = $_         

            $address = $addressGroup.Name

            Write-Host "Consolidating Address $address"

            $batchSize = 100
            $batchCount = [math]::Ceiling($addressGroup.Group.Count / $batchSize)

            for ($i = 0; $i -lt $batchCount; $i++) {
                $start = $i * $batchSize
                $batch = $addressGroup.Group | Select-Object -Skip $start -First $batchSize

                Write-Host "$($batch.txid.count) UTXOs in batch $($i + 1)"

                if ($batch.txid.count -gt 1)
                {
                    $totalAmount = ($batch | Measure-Object -Property amount -Sum).Sum
                    Write-Host "Total Amount for batch $($i + 1): $totalAmount"

                    $Global:consolidated++

                    send -rpcIP "$($rpcIP)" -rpcPort "$($rpcPort)" -rpcUser "$($rpcUser)" -rpcPass "$($rpcPass)" -utxos $batch

                    sleep -Seconds 1
                }
            }
        }
    }
}

function send()
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]$rpcIP,
    [Parameter(Mandatory=$true)]$rpcPort,
    [Parameter(Mandatory=$true)]$rpcUser,
    [Parameter(Mandatory=$true)]$rpcPass,
    [Parameter(Mandatory=$true)]$utxos
    )

    $basefee = 0.00078
    $utxofee = 0.00148

        $amount =  ($utxos | Measure-Object 'amount' -Sum).Sum        

        $inputs = '"['

        $outputvalue = 0
        foreach($utxo in $utxos)
        {
            $inputs = $inputs + '{\"txid\":\"' + $($utxo.txid) + '\",\"vout\":' + $($utxo.vout) + '},'
        }
        $inputs = $inputs.Substring(0,$inputs.Length -1) + ']"'
        $fee = $utxofee * $utxos.count + $basefee

        $outputAmount = $amount - $fee
        $output='{\"' + $($utxo.address) + '\":' + $($outputAmount) + '}'

        $cmd = ((& $PULSARDIR\pulsar-cli.exe -rpcconnect='"'$rpcIP'"' -rpcport="$rpcPort" -rpcuser="$rpcUser" -rpcpassword="$rpcPass" createrawtransaction $inputs $output))

        $hex = '"' + $($cmd) + '"'

        $sign = ((& $PULSARDIR\pulsar-cli.exe -rpcconnect='"'$rpcIP'"' -rpcport="$rpcPort" -rpcuser="$rpcUser" -rpcpassword="$rpcPass" signrawtransaction $hex) | ConvertFrom-Json)

        $signed = '"' + $($sign.hex) + '"'

        $send = ((& $PULSARDIR\pulsar-cli.exe -rpcconnect='"'$rpcIP'"' -rpcport="$rpcPort" -rpcuser="$rpcUser" -rpcpassword="$rpcPass" sendrawtransaction $signed))
}


function abandon()
{

    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]$rpcIP,
    [Parameter(Mandatory=$true)]$rpcPort,
    [Parameter(Mandatory=$true)]$rpcUser,
    [Parameter(Mandatory=$true)]$rpcPass
    )

    $txs = ((& $PULSARDIR\pulsar-cli.exe -rpcconnect='"'$rpcIP'"' -rpcport="$rpcPort" -rpcuser="$rpcUser" -rpcpassword="$rpcPass" listtransactions "*" 100 | ConvertFrom-Json) | where {$_.category -eq "stake-orphan"})

    if ($txs.Count -eq 0)
    {
        Write-Host "No Transactions to Abandon. Total: $Global:abandon"
    }

    foreach ($tx in $txs)
    {
        & $PULSARDIR\pulsar-cli.exe -rpcconnect='"'$rpcIP'"' -rpcport="$rpcPort" -rpcuser="$rpcUser" -rpcpassword="$rpcPass" abandontransaction $tx.txid    
        $Global:abandon++
        Write-Host "$($tx.txid) Abandoned. Total: $Global:abandon"
        
    }
}



function startScript()
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]$rpcIP,
    [Parameter(Mandatory=$true)]$rpcPort,
    [Parameter(Mandatory=$true)]$rpcUser,
    [Parameter(Mandatory=$true)]$rpcPass,
    [Parameter(Mandatory=$true)]$minConsolidation
    )

    while ($true) {

        $currentDateTime = Get-Date -Format "dd-MM-yyyy HH:mm:ss"

        Write-Host "$currentDateTime"

        abandon -rpcIP "$rpcIP" -rpcPort "$rpcPort" -rpcUser "$rpcUser" -rpcPass "$rpcPass" 
        consolidate -rpcIP "$rpcIP" -rpcPort "$rpcPort" -rpcUser "$rpcUser" -rpcPass "$rpcPass" -minConsolidation "$minConsolidation"

        $totalSteps = 60*10

        for ($i = $totalSteps; $i -gt 0; $i--) {
            $percentComplete = ($i / $totalSteps) * 100

            Write-Progress -PercentComplete $percentComplete -Status "Next Process in $i Seconds" -Activity "Waiting..."
            Start-Sleep -Seconds 1
        }
        Write-Progress -Complete -Activity "Processing..."
    }
}


