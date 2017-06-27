#$ErrorActionPreference= 'silentlycontinue'

 # Installs PSSQLite Module
Install-Module PSSQLite

# Import PSSQLite Module
Import-Module PSSQLite

# Import ActiveDirectory
Import-Module ActiveDirectory

while($true)
{
    #clear user variables
    $aduser = ""
    $user = ""
    $emplid = ""
    $names = ""

    # prompt user to swipe ID or enter username
    $user = Read-Host "`nSwipe ID Card or Type username"

    # database file
    $database = "$PSScriptRoot\Names.SQLite"

    # check if database file exists
    $databaseExist = Test-Path $database

    # Create-tables Query
    $tableQuery = "CREATE TABLE NAMES (EmplID VARCHAR(20) PRIMARY KEY UNIQUE, Fullname TEXT, Username TEXT, Email TEXT, Won BOOLEAN)"

    if (!$databaseExist)
    {
        # SQLite will create Names.SQLite for us
        Invoke-SqliteQuery -Query $tableQuery -DataSource $database
    }

    if ($user.length -lt 16)
    {
        #Write-Host "Entered username: $user"
        $aduser = Get-ADUser -Searchbase "OU=Staff,OU=People,DC=Domain,DC=EDU" -SearchScope Subtree -Filter {samaccountname -eq $user} -Properties employeeID, description
        Write-Host $aduser.EmployeeID
    }
    else
    {
        # since it appears this is a card swipe, we need to trim some characters
        # example card swipe: ;001234567=1111?
    
        #remove last 6 characters from input
        $emplid = $user.Substring(0,$user.Length-6)

        #remove first character from emplid variable
        $emplid = $emplid.Replace(";00","")

        #Write-Host "Entered Employee ID: $emplid"
        $aduser = Get-ADUser -Searchbase "OU=Staff,OU=People,DC=Domain,DC=EDU" -SearchScope Subtree -Filter {employeeid -eq $emplid} -Properties employeeID, description
        #$aduser.EmployeeID
    }

    if (!$aduser)
    {
        Write-Host "Could not find AD account with input: $user!" -ForegroundColor "Red"
    }
    else
    {
        if ($($aduser.EmployeeID) -like "")
        {
            Write-Host "`nAccount not eligible for drawing!" -foregroundcolor "red"
        }
        else
        {
              # Insert Query called by Invoke-SQLQuery
            $userInsert = "INSERT INTO NAMES (EmplID, Fullname, Username, Email, Won) VALUES (@empl, @full, @user, @email, 0)"

            #check if already entered
            $names = Invoke-SqliteQuery -DataSource $database -Query "SELECT * FROM NAMES"

            if ($names.Username -eq $aduser.Name)
            {
                Write-Host "`n$($aduser.description) already has been entered!" -foregroundcolor "magenta"
            }
            else
            {
                Invoke-SqliteQuery -DataSource $database -Query $userInsert -OutVariable $insertResult -SqlParameters @{
                    empl  = $($aduser.EmployeeID)
                    full  = $($aduser.description)
                    user  = $($aduser.SamAccountName)
                    email = $($aduser.UserPrincipalName)
                }

                Write-Host "`n$($aduser.description) has been entered!" -foregroundcolor "green"
            }  
        }
    }
}
