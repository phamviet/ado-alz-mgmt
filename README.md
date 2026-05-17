Azure Landing Zone

## Fixed issues from original `starter` module

1. Runner lack of permission to read `identity` Management Group

```bash
az role assignment create \
  --assignee "14d526fd-489b-4844-ac91-402f62b2613c" \
  --role "Management Group Contributor" \
  --scope "/"
```

2. VNet deployment fails when DDOS protection is disabled due to invalid reference to non-existent DDOS resource in `dependsOn` and `ddosProtectionPlanResourceId`

