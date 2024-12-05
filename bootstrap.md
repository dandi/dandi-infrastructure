# Terraform Bootstrap Process

## Terraform Cloud
TODO

## Project AWS Account
* Add a new IAM User (`dandi-infrastructure-bot`),
  which allows Terraform to make changes
  * Log in to the AWS console for the Project account
  * "Identity and Access Management (IAM)"
  * "Users"
  * "Add user"
  * "Set user details"
    * "User name": `dandi-infrastructure-bot`
  * "Select AWS access type"
    * "Access type": "Programmatic access"
  * "Set permissions"
    * "Add user to group"
  * "Add user to group"
    * "Group": `DANDI`
  * "Create user"
  * Copy the "Access key ID" and "Secret access key" value to a temporary local location

* Add IAM user credentials to Terraform Cloud
  * Log in to Terraform Cloud
  * Workspace: `dandi-prod`
  * "Variables" tab
  * "Environment Variables": "Add variable"
    * Key: `AWS_ACCESS_KEY_ID`
    * Value: <copied "Access key ID" from `dandi-infrastructure-bot`>
  * "Environment Variables": "Add variable"
    * Key: `AWS_SECRET_ACCESS_KEY`
    * Value: <copied "Secret access key" from `dandi-infrastructure-bot`>
    * Sensitive: <checked>

### APL Notes
- We skipped creating `dandi-infrastructure-bot` as we are using a long term keys
- For information on creating long term access keys: https://aplwiki.jhuapl.edu/confluence/pages/viewpage.action?spaceKey=IETP&title=Creating+Long-Term+Access+Keys

## Sponsored AWS Account
* Add a new IAM Role (`dandi-infrastructure`),
  which allows the project account to make changes to this account
  * Log in to the AWS console for the Sponsored account
  * "Identity and Access Management (IAM)"
  * "Roles"
  * "Create role"
  * "Select type of trusted entity"
    * "Another AWS account"
  * "Specify accounts that can use this role"
    * "Account ID": `278212569472`
  * "Attach permissions policies"
    * `AdministratorAccess`
  * "Role name"
    * `dandi-infrastructure`

* Because `dandi-infrastructure-bot` on the Project account has `AdministratorAccess`
  via the `DANDI` group, it does not require an additional explicit grant of `sts:AssumeRole`
  in order to assume the cross-account `dandi-infrastructure` role

## Heroku
TODO

## Sentry
TODO
