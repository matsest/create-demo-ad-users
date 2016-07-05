#Adapted from Helge Klein https://helgeklein.com/blog/2015/02/creating-realistic-test-user-accounts-active-directory/

Set-StrictMode -Version 2

Import-Module ActiveDirectory

# Set the working directory to the script's directory
Push-Location (Split-Path ($MyInvocation.MyCommand.Path))

#
# Global variables
#
# User properties
#$ou = "DC=imcs-test" # Which OU to create the user in: specify with -Path $ou in New-ADUser
$initialPassword = "Passord12356"             # Initial password set for the user
$orgShortName = "ST"                         # This is used to build a user's sAMAccountName
$dnsDomain = "soprasteria.com"                      # Domain is used for e-mail address and UPN
$company = "Sopra Steria (test)"                      # Used for the user object's company attribute
$departments = (                             # Departments and associated job titles to assign to the users
                  @{"Name" = "IMCS"; Positions = ("Senior Infrastructure Engineer", "Junior Infrastructure Engineer", "Senior Infrastructure Architect")},
                  @{"Name" = "Applications"; Positions = ("Software Developer", "Senior Software Developer", "Project Leader")},
                  @{"Name" = "Business Consulting"; Positions = ("Manager", "Assistant", "Specialist")},
                  @{"Name" = "Management"; Positions = ("Business Owner", "Director")}
               )
$phoneCountryCodes = @{"NO" = "+47"}         # Country codes for the countries used in the address file
 
# Other parameters
$userCount = 1000                            # How many users to create
$locationCount = 1                          # How many different offices locations to use
 
# Files used
$firstNameFileMale = "NO-firstnames-m.txt"      # Format: FirstName
$firstNameFileFemale = "NO-firstnames-f.txt"    # Format: FirstName
$lastNameFile = "NO-lastnames.txt"              # Format: LastName
$addressFile = "NO-addresses.txt"               # Format: City,Street,State,PostalCode,Country

#
# Read input files
#
$firstNamesMale = Import-CSV $firstNameFileMale
$firstNamesFemale = Import-CSV $firstNameFileFemale
$lastNames = Import-CSV $lastNameFile
$addresses = Import-CSV $addressFile


#
# Preparation
#
$securePassword = ConvertTo-SecureString -AsPlainText $initialPassword -Force

# Select the configured number of locations from the address list
$locations = @()
$addressIndexesUsed = @()
for ($i = 0; $i -le $locationCount; $i++)
{
   # Determine a random address
   $addressIndex = -1
   do
   {
      $addressIndex = Get-Random -Minimum 0 -Maximum $addresses.Count
   } while ($addressIndexesUsed -contains $addressIndex)
   
   # Store the address in a location variable
   $street = $addresses[$addressIndex].Street
   $city = $addresses[$addressIndex].City
   $postalCode = $addresses[$addressIndex].PostalCode
   $country = $addresses[$addressIndex].Country
   $locations += @{"Street" = $street; "City" = $city; "PostalCode" = $postalCode; "Country" = $country}
   
   # Do not use this address again
   $addressIndexesUsed += $addressIndex
}

#
# Create the users
#
for ($i = 0; $i -lt $userCount; $i++)
{
   #
   # Randomly determine this user's properties
   #
   
   # Sex & name
   [bool] $male = Get-Random -Minimum 0 -Maximum 2
   $firstName = ""
   if ($male)
   {
      $firstName = $firstNamesMale[$(Get-Random -Minimum 0 -Maximum $firstNamesMale.Count)].FirstName
   }
   else
   {
      $firstName = $firstNamesFemale[$(Get-Random -Minimum 0 -Maximum $firstNamesFemale.Count)].FirstName
   }
   $lastName = $lastNames[$(Get-Random -Minimum 0 -Maximum $lastNames.Count)].LastName
   $displayName = "$firstName $lastName"

   # Address
   $locationIndex = Get-Random -Minimum 0 -Maximum $locations.Count
   $street = $locations[$locationIndex].Street
   $city = $locations[$locationIndex].City
   $postalCode = $locations[$locationIndex].PostalCode
   $country = $locations[$locationIndex].Country
   
   # Department & title
   $departmentIndex = Get-Random -Minimum 0 -Maximum $departments.Count
   $department = $departments[$departmentIndex].Name
   $title = $departments[$departmentIndex].Positions[$(Get-Random -Minimum 0 -Maximum $departments[$departmentIndex].Positions.Count)]

   # Phone number
   if (-not $phoneCountryCodes.ContainsKey($country))
   {
      "ERROR: No country code found for $country"
      continue
   }
   $officePhone = $phoneCountryCodes[$country] + (Get-Random -Minimum 10000000 -Maximum 100000000)
   
   # Build the sAMAccountName: $orgShortName + employee number
   $employeeNumber = Get-Random -Minimum 100000 -Maximum 1000000
   $sAMAccountName = $orgShortName + $employeeNumber
   $userExists = $false
   Try   { $userExists = Get-ADUser -LDAPFilter "(sAMAccountName=$sAMAccountName)" }
   Catch { }
   if ($userExists)
   {
      $i--
      continue
   }

   #
   # Create the user account
   #
   New-ADUser -SamAccountName $sAMAccountName -Description "test-user" -Name $displayName -AccountPassword $securePassword -Enabled $true -GivenName $firstName -Surname $lastName -DisplayName $displayName -EmailAddress "$firstName.$lastName@$dnsDomain" -StreetAddress $street -City $city -PostalCode $postalCode -Country $country -UserPrincipalName "$sAMAccountName@$dnsDomain" -Company $company -Department $department -EmployeeNumber $employeeNumber -Title $title -OfficePhone $officePhone

   "Created user #" + ($i+1) + ", $displayName, $sAMAccountName, $title, $department, $street, $city"
}