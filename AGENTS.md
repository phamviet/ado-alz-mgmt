# AGENTS.md - Azure Landing Zone (alz-mgmt)

## Project Overview

Azure Landing Zone infrastructure-as-code using **Bicep**. Deploys management group hierarchy, policies, RBAC, and networking via Azure DevOps pipelines.

## Critical Rules

- **`main` branch is protected** -- always create a feature branch and PR
- **`subscriptionsToPlaceInManagementGroup` must never contain empty strings** -- causes invalid ARM resource names like `identity/` for `Microsoft.Management/managementGroups/subscriptions`. Use `[]` when no subscriptions to place.

## Key Commands

```bash
bicep build <file.bicep>           # Compile Bicep to ARM JSON
bicep build-params <file.bicepparam> --stdout  # Validate params
```

## PR Workflow

When asked to "push changes", follow these steps:

```bash
# 1. Create feature branch from main
git checkout -b fix/<short-description>

# 2. Stage and commit
git add <files> && git commit -m "<message>"

# 3. Push branch
git push -u origin <branch-name>

# 4. Create PR via Azure CLI
az repos pr create \
  --repository "alz-mgmt" \
  --source-branch "<branch-name>" \
  --target-branch "main" \
  --title "<title>" \
  --description "<markdown body>"
```

## CI/CD

- **`.pipelines/ci.yaml`** -- manual trigger, runs validation
- **`.pipelines/cd.yaml`** -- auto-triggers on `main`, deploys all governance/platform/networking modules
- Both extend templates from external repo `Azure Landing Zone/alz-mgmt-templates`
- CD has toggle parameters per module (e.g. `governance-platform-identity: true`)

## Architecture

```
templates/
├── core/
│   ├── alzCoreType.bicep              # Shared type for all mgmt group configs
│   ├── governance/
│   │   ├── mgmt-groups/               # One main.bicep + main.bicepparam per mgmt group
│   │   │   ├── int-root/              # Intermediate root (alz)
│   │   │   ├── platform/              # connectivity, identity, management, security
│   │   │   ├── landingzones/          # corp, online, local
│   │   │   ├── sandbox/
│   │   │   └── decommissioned/
│   │   ├── lib/alz/                   # ALZ policy/role JSON definitions
│   │   └── tooling/
│   └── logging/
└── networking/
    ├── hubnetworking/
    └── virtualwan/
```

## Conventions

- Each mgmt group module: `main.bicep` (template) + `main.bicepparam` (params)
- RBAC-only modules: `main-rbac.bicep` + `main-rbac.bicepparam`
- Params files use `using './main.bicep'` to reference their template
- All mgmt group configs conform to `alzCoreType` in `templates/core/alzCoreType.bicep`
- `parameters.json` at root holds subscription IDs and global config (referenced by pipelines)
- Primary region: `southeastasia`

## Bicep Config

`bicepconfig.json` enables linter rules: `use-recent-api-versions`, `use-recent-module-versions`, `no-unused-params`, `no-unused-vars` (all warnings). Uses Microsoft Graph v1.0 extension.
