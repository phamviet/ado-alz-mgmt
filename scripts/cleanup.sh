#!/usr/local/bin/pwsh

# az login --tenant "28cb1194-6cd9-4b16-ba7b-e10a71c8059c"
# az account set --subscription "00c29365-565e-4c47-8745-bfab7dbe0554"

Remove-PlatformLandingZone `
  -ManagementGroups "28cb1194-6cd9-4b16-ba7b-e10a71c8059c" `
  -Subscriptions "733d1a5f-ea85-4d0e-ae85-c9e93cb6ec82", "fc81c82c-e110-46e2-8405-0676ebfc63ab" `
  -AdditionalSubscriptions "00c29365-565e-4c47-8745-bfab7dbe0554" `
  -SubscriptionsTargetManagementGroup "28cb1194-6cd9-4b16-ba7b-e10a71c8059c"

