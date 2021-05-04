
###global variables and objects

# defines the remoteUser object.  Whenever it is created it will contain the properties liseted below.
class remoteUser {
    [bool]$remoteAppUser
    [bool]$vpnUser
}

###splats for various commands and functions

# requests all properties that will be used when by other functions working with users.
$usersComplete = @{

    Property = "CN", "DisplayName", "Description", "EmailAddress", "EmployeeID", "PhysicalDeliveryOfficeName", "StreetAddress", "Title", "TelephoneNumber", "LockedOut", "PasswordExpired", "MemberOf"

}

$simpleProperties = @{

    Property = "DisplayName", "SamAccountName", "EmployeeID", "Description", "PasswordExpired", "LockedOut"

}

### Functions ###

<### Find-ADUser ####

.SYNOPSIS
Custom function that is used to find an AD user object using search methods less strict or complex when compared to
the "Get-ADUser" cmdlet. 

.DESCRIPTION
Find-ADUser works similar to Get-ADUser, the main difference is that it is more friendly to wildcard searches. 
The only parameter is the -Name Parameter, and is able to accept a variety of search criteria using ANR.
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

    #Runs Get-ADUser command using LDAP filter and performs an ANR query for the $Name parameter. Assigns results to $userResults variable.
    $userResults = Get-ADUser -LDAPFilter "(anr=$Name)" @usersComplete

    # if above search returns nothing then retry command using a filter that will search employeeID properties.
    if ( $userResults.count -eq 0 ) {

        #fixes syntax of $Name parameter so -Filter can use it. Turns $Name into '*$Name*'  
        $Name = "'*" + $Name + "*'"

        #Runs Get-ADUser command but only searches EmployeeID properties for users.
        $userResults = Get-ADUser -Filter "EmployeeID -like $Name" @usersComplete

    }

    # returns results formatted as a table using the properties from $tableProperties array.
    return $userResults 
}

function Unlock-User {
    
    [alias ("Unlock")]

    param(
        [Parameter()]
        $Name
    )

    Unlock-ADAccount -Identity $Name

}

function Reset-Password {
    
    [alias ("Reset")]

    [Parameter()]
    $Name



}

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


function Format-Simple {

    [alias ("SimpleLayout")]

    param(
        [Parameter()]
        $Name
        )

    return $Name | Format-Table @simpleProperties

}






