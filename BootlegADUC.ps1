<#
Work in progress. 

simple functions to perform simplified wildcard searches for resources in Active Directory.
Some, if not all of the follwoing commands and functions will be used to eventually build a
"technician's dashboard" that will allow them to perform commonly used tasks and searches in 
Active Directory
#>

## defines the remoteUser object.  
class remoteUser {

    # boolean values used to determine if user has access to remoteapp and/or vpn
    [bool]$remoteAppUser
    [bool]$vpnUser

}



# splats used for fomratting inputs & outputs for "find-aduser" function 
$queryProperties = @{ 

    Properties = "DisplayName", "SamAccountName", "Department", "Description", "LockedOut", "PasswordExpired", "EmployeeID", "MemberOf"  

}

$userProperties = @{

    Property = "CN", "DisplayName", "Description", "EmailAddress", "EmployeeID", "PhysicalDeliveryOfficeName", "StreetAddress", "Title", "TelephoneNumber", "LockedOut", "PasswordExpired", "MemberOf"

}

# Array containing properties used when displaying results of query
$tableProperties = @{

    Property = "DisplayName", "SamAccountName", "EmployeeID", "Description", "PasswordExpired", "LockedOut"

}

<#### Find-ADUser ####

.SYNOPSIS
Custom function that is used to find an AD user object using search methods less strict or complex when compared to
the "Get-ADUser" cmdlet. 

.DESCRIPTION
Find-ADUser works similar to Get-ADUser, the main difference is that it supports wildcard searches. 
Currently, the only parameter is the -Name Parameter, and is able to accept a variety of search criteria using ANR.
Ambigious Name Resolution (ANR) is used to search mulitple properties (See the link below for supported attributes.)  
https://social.technet.microsoft.com/wiki/contents/articles/22653.active-directory-ambiguous-name-resolution.aspx

.PARAMETER Name
-Name Accepts multiple types of name based search terms like: Username, last or first name, email address, UPN, EmployeeID, and more.
All search terms are considered wildcard searches. 

.EXAMPLE
Find-ADUser -Name "[searchterm]" 
-Name is the only parameter and used by default.

As long as a single string is used, search term can be entered without quotes. 

Last Name ->   PS C:\ Find-ADuser morgan
First Name ->  PS C:\ Find-ADuser justin
UPN or email  ->   PS C:\ Find-Aduser justin.morgan@norfolk.gov
SamAccountName -> PS C:\ Find-ADuser mmorgan06
EmployeeID -> PS C:\ Find-ADuser 123456

Single or double quotes are required if there is a space in the search term.
PS C:\ Find-Aduser "morgan, j"

The AD property "physicalDeliveryOfficeName" is covered by ANR and can be used.
PS C:\ Find-ADuser "Services & Support"

Example: Find-ADUser grimes

DisplayName     SamAccountName EmployeeID Description               PasswordExpired LockedOut
-----------     -------------- ---------- -----------               --------------- ---------
Grimes, Frank   FGRIMES        12345      Information Technology              False     False

.NOTES
ADuser is an alias that can be used.
example: PS C:\ ADuser morgan

#>
function Find-ADuser {
    
    # alias "ADuser can be used instead of full command"
    [alias ("ADuser")]
    
    # Parameter "$Name" will be used by default if paramter is not used in the command 
    param(
        [Parameter()]
        $Name
    )

    #Runs Get-ADUser command using LDAP filter and performs an ANR query for the $Name parameter. Assigns results to $returnUser variable.
    $returnUser = Get-ADUser -LDAPFilter "(anr=$Name)" @userProperties

    # if above search returns nothing then retry command using a filter that will search employeeID properties.
    if ( $returnUser.count -eq 0 ) {

        #fixes syntax of $Name parameter so -Filter can use it. Turns $Name into '*$Name*'  
        $Name = "'*" + $Name + "*'"

        #Runs Get-ADUser command but only searches EmployeeID properties for users.
        $returnUser = Get-ADUser -Filter "EmployeeID -like $Name" @userProperties

    }

    # returns results formatted as a table using the properties from $tableProperties array.
    return $returnUser 
}


# protype function that uses unlock-aduser and allows simple "unlock" alias to be used
function Unlock-User {
    
    [alias ("Unlock")]

    param(
        [Parameter()]
        $Name
    )

    Unlock-ADAccount -Identity $Name

}

# function inspects specified users group memberships and to determine if they are members of any groups 
# that allow remote access

function Get-RemoteStatus {

    # Parameter "$Name" will be used by default if parameter is not used in the command 
    param(
        [Parameter()]
        $Name
    )

    # creates a "remoteUser" class object and assigns it to the $statusTable variable
    $statusTable = [remoteUser]::new()

    # for each group that a user is a member of "vpn" or "remoteApp" type groups if so, then the 
    # corresponding "user" property will be set to True, if not it will remain the default value (False)
    # iterates user's group membership and checks if it's a vpn or remoteapp group

    foreach ($var in $Name.MemberOf) {
        
        $groupCheck = $var -match "vpn"

        if ($groupCheck -eq $true) {
            $statusTable.vpnUser = $true
        }

        $groupCheck = $var -match "RemoteApp"

        if ($groupCheck -eq $true) {
            $statusTable.remoteAppUser = $true
        }

    }
   
    return $statusTable 
}    

 
<#
.SYNOPSIS
Function that works similar to Get-ADComputer, but allows wildcard searches without using the -Filter paramter and syntax.

.DESCRIPTION
Long description

.PARAMETER compSearch
Parameter description

.EXAMPLE
An example

.NOTES
Rebuild function using Find-ADUser as a template.
#> 
function Find-Computer ($compSearch) {

    $compSearch = "'*" + $compSearch + "*'"
    
    Get-ADComputer -Filter "name -like $compSearch"

}

