# create-demo-ad-users

![example](/example_users.png)

## About
Creates 1000 unique users in Active Directory, for testing purposes in Sopra Steria IMCS. Puts all users in default OU/DC by default with description `test`. Contains no sensitive data. Names and addresses are generated from fakenamegenerator.com. All other numbers used are randomly generated. 

## How-to
- Run the Powershell-script on a computer with Active Directory set up. 

## Options
- Change departments, roles to get a more specific userset.
- Change number of users
- Set OU/DC for all users by uncommenting and specifying decleration of $ou-variable and include `-Path $ou`in `New-ADuser`-cmdlet
- ... and add other attributes and include corresponding parameters in `New-ADuser`-cmdlet

## Extra information
- To set up a test Active Directory Domain Controll in Azure: https://auth0.com/docs/connector/test-dc

- A more complete guide from which this script was forked: https://helgeklein.com/blog/2015/02/creating-realistic-test-user-accounts-active-directory/
