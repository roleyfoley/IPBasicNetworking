# Basic Network Module 
# --- This module consists of a set of basic powershell functions for some common network based work you might want to do 

function Get-IPNetDetails {
    <#
    .SYNOPSIS 
    Provides Basic network information about a given IP Adddress

    .DESCRIPTION 
    Given an IP Address in CIDR format calculate and return the following details about the Network the IP is part of:
    - The CidrMask for the Network
    - The Subnet Mask for the Network of the IP 
    - The Network ID for the Network 
    - The First usable host IP address in the Network
    - The Last usable host IP address in the Network 

    .EXAMPLE 
    Get-GatewayAddress -IPCidr 10.1.1.3/24 

    IP         : 10.1.1.3
    CidrMask   : 22
    SubnetMask : 255.255.252.0
    NetworkId  : 10.1.0.0
    FirstIP    : 10.1.0.1
    LastIP     : 10.1.3.254


    .PARAMETER IPCidr 
    A host IP Address with CIDR Mask 

    .INPUTS 
    None. You cannont pipe objects 

    .OUTPUTS
    PSObject. Returns a Custom PS object with the IP Details 
    #>
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory=$true,Position=0)][string]$IPCidr
    )

    # Split IP into IP and Mask
    $IPAddress = $IPCidr.Split('/')[0]
    $CidrMask = $IPCidr.Split('/')[1]

    if ( $IPAddress -eq $null -or $CidrMask -eq $null -or $CidrMask -NotIn 8..32  ) {
        throw "IP Address invalid - Check that you have submitted the IP in CIDR format"
    }  

    # Convert the IP to Binary 
    $HostBinary = ([Convert]::toString(([IPAddress][String]([IPAddress]$($IPAddress)).Address).Address,2)).PadLeft(32, "0") 

    if ($HostBinary -eq $null) {
        throw "Invalid IP Address"
    }

    #Split the Binary IP into Network/Host based on the Interfaces subnet mask - Keep the Network Binary part (the First part of the string)
    $NetworkSection = ($HostBinary | Where {$_ -match "^(.{$($CidrMask)})"} | ForEach{ [PSCustomObject]@{ 'BinaryNet' = $Matches[0] } }).BinaryNet

    $NetworkId = $NetworkSection
    $FirstIP = $NetworkSection
    $LastIP = $NetworkSection
    

    #Tell us what the Network ID is 
    While ( $NetworkId.Length -le 31 ) {
        $NetworkId = [string]$NetworkId + "0"
    }

     # Find the First usable IP in the network - Fill the host section with 0 except the last Number  
    While ( $FirstIP.Length -le 30 ) {
        $FirstIP = [String]$FirstIP + 0
    }  

    if ($FirstIP.Length -eq 31) {
        $FirstIP = [string]$FirstIP + 1
    }

    # Find the Last usable IP in the network - Fill the host section with 0 except the last Number   
    While ( $LastIP.Length -le 30 ) {
        $LastIP = [String]$LastIP + 1
    }  

    if ($LastIP.Length -eq 31) {
        $LastIP = [string]$LastIP + 0
    }

    # Tell me the Subnet Mask
    $SubnetMask = ""
    While ($SubnetMask.Length -le ([int]$CidrMask -1 ) ) {
        $SubnetMask = [String]$SubnetMask + 1 
    } 

    While ($SubnetMask.Length -le 31 ) {
        $SubnetMask = [string]$SubnetMask + 0
    }

    # Convert the Binary IP back into Dotted Quad 
    $GatewayDetails = New-Object psobject
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name IP -Value $IPAddress
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name CidrMask -Value $CidrMask
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name SubnetMask -Value  $(([System.Net.IPAddress]"$([System.Convert]::ToInt64($SubnetMask,2))").IPAddressToString)
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name NetworkId -Value $(([System.Net.IPAddress]"$([System.Convert]::ToInt64($NetworkId,2))").IPAddressToString) 
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name FirstIP -Value $(([System.Net.IPAddress]"$([System.Convert]::ToInt64($FirstIP,2))").IPAddressToString)
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name LastIP -Value $(([System.Net.IPAddress]"$([System.Convert]::ToInt64($LastIP,2))").IPAddressToString)
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name NetworkBinary -Value $NetworkId
    $GatewayDetails | Add-Member -MemberType NoteProperty -Name HostBinary -Value $HostBinary

    return $GatewayDetails
}


function Test-IPInRange { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)][string]$IPAddress,
        [Parameter(Mandatory=$true)][string[]]$Networks
    )
    $IPSubjectBinary = Get-IPNetDetails -IPCidr "$($IPAddress)/32" 
    $IPInRange = New-Object System.Collections.ArrayList
    $IPOutRange = New-Object System.Collections.ArrayList

    foreach ($Network in $Networks ) { 
        $NetworkDetails = Get-IPNetDetails -IPCidr $Network 
        if ( ($NetworkDetails.NetworkBinary).Substring(0,$($NetworkDetails.CidrMask)) -eq (($IPSubjectBinary.HostBinary).Substring(0,$($NetworkDetails.CidrMask))) ) {
            [void]$IPInRange.Add("$($Network)")
        }
        else {
            [void]$IPOutRange.Add("$($Network)")
        }
    }

    $ReturnObject = New-Object psobject
    $ReturnObject | Add-Member -MemberType NoteProperty -Name InRange -Value $IPInRange
    $ReturnObject | Add-Member -MemberType NoteProperty -Name OutRange -Value $IPOutRange 
    $ReturnObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress 

    return $ReturnObject
}

function Get-IPRangeDetails { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)][string]$FirstIP,
        [Parameter(Mandatory=$true)][string]$LastIP
    )

    # Add CIDR mask if its not added
    If ( $FristIP -notlike "*/*") { 
        $FirstIP = "$($FirstIP)/32"
    }
    If ( $LastIP -notlike "*/*") { 
        $LastIP = "$($LastIP)/32"
    }

    # Grab the Basic Network Details 
    $FirstIPDetails = Get-IPNetDetails -IPCidr $FirstIP
    $LastIPDEtails = Get-IPNetDetails -IPCidr $LAstIP 

    # Convert it to an Integer so we can treat them like numbers 
    $FirstIPInt = [Convert]::ToInt32( $($FirstIPDetails.HostBinary), 2)
    $LastIPInt = [Convert]::ToInt32( $($LastIPDetails.HostBinary), 2)

    # Create a return Object 
    $IPRangeObject = New-Object PSObject 
    $IPRangeObject | Add-Member -MemberType NoteProperty -Name FirstIP -Value $FirstIP
    $IPRangeObject | Add-Member -MemberType NoteProperty -Name LastIP -Value $LastIP

    # The Difference between the Int's will be the number of IP's in the range 
    $IPRangeObject | Add-Member -MemberType NoteProperty -Name IPCount -Value $( $LastIPInt - $FirstIPInt )
    $IPIntRange = $FirstIPInt..$LastIPInt 

    # Lets suggest a subnet that would cover these networks 
    # Convert the Binary Network details to an array 
    $FirstIPBinArray = ($FirstIPDetails.HostBinary).ToCharArray()
    $LastIPBinArray = ($LastIPDEtails.HostBinary).ToCharArray()
    $Counter = 0
    $DiffFound = $False 

    # Loop through the array till we find a difference between the binary of the first and last IP 
    # This will give us the number of bits required for a host that spans these ranges 
    foreach ( $FirstIPBin in $FirstIPBinArray ) {
        if ( $FirstIPBin -ne $LastIPBinArray[$Counter] -and $DiffFound -eq $False ) { 
            $DiffIndex = $Counter
            $DiffFound = $True
        }
        $Counter++
    }

    # Calculate the subnet that jumps both of these 
    $SuperNet = Get-IPNetDetails -IPCidr "$($FirstIPDetails.IP)/$($DiffIndex )"
    $IPRangeObject | Add-Member -MemberType NoteProperty -Name SuperNet -Value "$($SuperNet.NetworkId)/$($SuperNet.CidrMask)"

    # Calculate each IP in the range 
    #### LIMITED TO 500 IP's in range to fix up performance in conversion 
    if ( $IPIntRange.Count -le 500 ) { 
        $IPRange = New-Object System.Collections.ArrayList 
        Foreach ( $IPInt in $IPIntRange ) { 
            $IPIntBinary = ([Convert]::toString( $($IPInt),2)).PadLeft(32, "0")    
            $IPAddress = $(([System.Net.IPAddress]"$([System.Convert]::ToInt64($IPIntBinary,2))"))
            [void]$IPRange.Add( $($IPAddress.IPAddressToString))
        }

        $IPRangeObject | Add-Member -MemberType NoteProperty -Name IPAdddresses -Value $IPRange
    }

    return $IPRangeObject
}




