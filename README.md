Azure Landing Zone

## Removed Resources

* Azure Firewall
* Bastion
* ExpressRouteGateway
* VPNGateway
* DDOS Protection https://azure.github.io/Azure-Landing-Zones/bicep/howtos/modifyingpolicyassignments/#ddos-protection

## Scripts

### Manual Deploy Script

```bash

./scripts/deploy.sh managementGroup governance-landingzones templates/core/governance/mgmt-groups/landingzones
./scripts/deploy.sh managementGroup governance-platform-connectivity templates/core/governance/mgmt-groups/platform/platform-connectivity
./scripts/deploy.sh subscription networking-hubnetworking templates/networking/hubnetworking

./scripts/deploy.sh managementGroup governance-landingzones-rbac templates/core/governance/mgmt-groups/landingzones
./scripts/deploy.sh managementGroup governance-platform-connectivity-rbac templates/core/governance/mgmt-groups/platform/platform-connectivity
```

1. Runner lack of permission to read `identity` Management Group

```bash
az role assignment create \
  --assignee "14d526fd-489b-4844-ac91-402f62b2613c" \
  --role "Management Group Contributor" \
  --scope "/"
```
