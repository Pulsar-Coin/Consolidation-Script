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
