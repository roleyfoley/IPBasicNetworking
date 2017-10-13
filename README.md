# Basic Networking
This module contains a collection of functions that provide basic network information. The Module is intended to be generic and provides the general network level information you would need when configuring a network or working with networks. 

# Installation 
The module can be installed as a standard powershell module. Copy the psm1 and psd1 files into your powershell module directory (C:\Program Files\WindowsPowerShell\Modules\IPBasicNetworking) 

When you want to use the module you just need to start your script with import-module IPBasicNetworking 

# Commands

## Get-IPNetDetails 
Given an IP Address in CIDR format this command will provide some details on the network including

    Get-IPNetDetails  -IPCidr 10.1.1.1/24 

    IP            : 10.1.1.1
    CidrMask      : 24
    SubnetMask    : 255.255.255.0
    NetworkId     : 10.1.1.0
    FirstIP       : 10.1.1.1
    LastIP        : 10.1.1.254
    NetworkBinary : 00001010000000010000000100000000
    HostBinary    : 00001010000000010000000100000001

## Test-IPInRange 
From a provided list of networks and a provided IP determine if the IP fits into the provided networks. 

    Test-IPInRange -IPAddress 10.1.1.1 -Networks @('10.1.1.1/24','10.2.1.1/24')
    
    InRange   : {10.1.1.1/24}
    OutRange  : {10.2.1.1/24}
    IPAddress : 10.1.1.1    

## Get-IPRangeDetails
Given a FirstIP address and Last IP calculate the smallest subnets possible to include the first and last IP. Will also return a list of the IP's in the range (up to 500 IP's)

    Get-IPRangeDetails -FirstIP 10.1.1.1 -LastIP 10.1.20.1

    FirstIP  : 10.1.1.1/32
    LastIP   : 10.1.20.1/32
    IPCount  : 4864
    SuperNet : 10.1.0.0/19
