# Azure Landing Zone Documentation

## Overview

This Azure Landing Zone provides a comprehensive infrastructure setup for deploying and managing virtual machines in Azure with governance, monitoring, backup, patching, and configuration management. This repository focuses on establishing the supporting services and management plane - VM deployments are handled separately.

Everything needed for establishing VM management for one customer/environment is contained in this repository.

## What main.bicep Deploys

The main Bicep template (`bicep/main.bicep`) deploys a complete VM management infrastructure at subscription and resource group scope:

### 1. User-Assigned Managed Identities (UAMIs)

- **VM AMA UAMI**: Used by Azure Monitor Agent policies for VM monitoring setup
- **Guest Configuration UAMI**: Used to access Guest Configuration packages from blob storage

### 2. Role Assignments for Policy Remediation

- **Contributor & User Access Administrator**: For UAMI assignment policies
- **Virtual Machine Contributor**: For AMA deployment and policy remediation
- **Monitoring Contributor & Log Analytics Contributor**: For Data Collection Rule associations
- **Storage Blob Data Reader**: For Guest Configuration package access

### 3. Resource Groups

- Configurable resource groups for VM organization (defined in parameter files)

### 4. Monitoring Infrastructure

- **Log Analytics Workspace**: Centralized logging and monitoring
- **Data Collection Rule (DCR)**: VM performance metrics collection configured for VM Insights
- Streams performance counters to Log Analytics

### 5. Backup Infrastructure

- **Recovery Services Vault**: Centralized backup storage
- **VM Backup Policy**: Configurable backup schedule with:
  - Daily backups with custom retention (default: 30 days)
# Azure Landing Zone (VM) Docs

This README reflects the current repo contents and explains how to use and deploy the VM-focused landing zone.

## Overview

The project delivers a minimal Azure Landing Zone for managing VM estates with governance, observability, backup, and configuration. It uses Bicep for IaC, Azure Policy for enforcement, and PowerShell DSC for VM configuration.

## Structure

```
azure-landing-zone/
   bicep/
      main.bicep
      modules/
         addResourceGroup.bicep
         addUpdateResourceGroups.bicep
         backup.bicep
         backupPolicy.bicep
         builtinPolicyAssignment.bicep
         configurationAssignment.bicep
         dataCollectionRule.bicep
         loganalytics.bicep
         maintenanceconf.bicep
         policy.bicep
         policyAssignment.bicep
         policySetDefinition.bicep
         resourceGroup.bicep
         rgRoleAssignment.bicep
         storageAccount.bicep
         subRoleAssignment.bicep
         userAssignedId.bicep
      params/
         prod.bicepparam
   docs/
      onboarding.md
      README.md
   policies/
      policyDefinitions/
         assign-guest-configuration.json
         assignAMA-vm.json
         assignDCR-vm.json
         assignUAMI-vm.json
         deployAMA-custom-set.json
   pwsh/
      dsc/
         AzureLandingZoneVM.ps1
```

### Bicep
- `bicep/main.bicep`: Subscription-scope entry point for deploying core components.
- `bicep/modules/`: Modular building blocks for resource groups, policy (definitions, sets, and assignments), observability (Log Analytics, DCR/AMA), backup (vault and policy), maintenance configuration, RBAC role assignments, storage, and user-assigned identities.
- `bicep/params/prod.bicepparam`: Example parameter file for production-like deployments.

### Policies
- `policies/policyDefinitions/*.json`: JSON payloads for VM governance (e.g., AMA/DCR assignment, Guest Configuration, custom set deployment, UAMI assignment).

### Docs
- `docs/onboarding.md`: Onboarding guidance and prerequisites.
- `docs/README.md`: This file.

### PowerShell DSC
- `pwsh/dsc/AzureLandingZoneVM.ps1`: DSC script for VM configuration alignment.

## Deploy

Prereqs: Azure CLI and Bicep CLI installed; access to the target subscription.

From `azure-landing-zone/bicep`:

```powershell
# Sign in and set subscription
az login
az account set --subscription "<SUBSCRIPTION_NAME_OR_ID>"

# Optional: build for validation
bicep build .\main.bicep

# Deploy at subscription scope using parameters
az deployment sub create \
   --location "<Azure Region>" \
   --template-file .\main.bicep \
   --parameters .\params\prod.bicepparam
```

Notes:
- If `main.bicep` scope differs, adjust the `az deployment` command accordingly.
- Replace placeholders for subscription and region.

## Customize

- Edit `params/prod.bicepparam` to fit naming, tagging, and policy inputs.
- Enable/disable modules via references in `main.bicep`.
- Update or add policy definitions under `policies/policyDefinitions` as needed.

## Operations

- Policy: Validate assignments and remediation in Azure Policy.
- Observability: Confirm Log Analytics + DCR/AMA ingestion paths.
- Backup: Verify vault and policy assignment coverage.
- Maintenance: Check schedules meet operational windows.
- RBAC: Confirm role assignments for principals and scopes.

## Onboarding

See `docs/onboarding.md` for environment prerequisites, RBAC, and onboarding steps.

## Contributing

Open issues/PRs against `main` for improvements. This repo is owned by the maintainer listed in repository metadata.

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Deploy the landing zone (resource group scope)
az deployment group create \
  --resource-group "LzDemo02" \
  --template-file bicep/main.bicep \
  --parameters bicep/params/prod.bicepparam \
  --name "landing-zone-deployment"
```

### Using PowerShell Scripts

```powershell
# Navigate to the scripts directory
cd pwsh/scripts

# Run the bootstrap script
.\Bootstrap-AzureLandingZone.ps1 -Environment prod -SubscriptionId "your-subscription-id"
```

## Configuration

### Environment Parameters

Each environment (dev, test, prod) has its own parameter file in `bicep/params/`:

- **dev.bicepparam**: Development environment settings
- **test.bicepparam**: Test environment settings
- **prod.bicepparam**: Production environment settings

### Key Configurable Parameters

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| `location` | Azure region for deployment | Sweden Central |
| `environmentName` | Environment identifier | prod |
| `projectName` | Project name for resource naming | lz |
| `sharedResourceGroupName` | Resource group for shared resources | LzDemo02 |
| `resourceGroups` | Array of resource groups to create | `[{name: 'lz-vms-prod', location: 'Sweden Central'}]` |
| `backupTagName` | Tag name for backup targeting | Backup |
| `backupTagValues` | Tag values for backup targeting | `['Standard']` |
| `guestConfigTagName` | Tag name for guest configuration targeting | guestConfig |
| `guestConfigTagValues` | Tag values for guest configuration targeting | `['Applied']` |
| `guestConfigurationName` | Guest Configuration package name | TimeZone |
| `guestConfigurationVersion` | Guest Configuration package version | 1.0.0 |
| `guestConfigurationContentUri` | URI to Guest Configuration package (.zip) | https://storage.../TimeZone.zip |
| `guestConfigurationContentHash` | SHA256 hash of the package | DF7EB0234D... |

### Tag-Based Targeting

The landing zone uses tags to control which VMs receive specific configurations:

#### Backup Tag

- **Tag Name**: `Backup` (configurable)
- **Tag Value**: `Standard` (configurable, array)
- **Effect**: VMs with this tag will be automatically enrolled in backup

#### Guest Configuration Tag

- **Tag Name**: `guestConfig` (configurable)
- **Tag Value**: `Applied` (configurable, array)
- **Effect**: VMs with this tag will receive the Guest Configuration package

### Guest Configuration Packages

The Guest Configuration policy is generic and can deploy any custom package:

1. **Create your Guest Configuration package** (e.g., timezone, security baseline, compliance)
2. **Upload to blob storage** and generate SHA256 hash
3. **Configure parameters** in your environment parameter file:
   - Package name
   - Version
   - Content URI
   - Content hash
4. **Tag VMs** with `guestConfig: Applied` to receive the configuration

## Key Features

### Comprehensive VM Management

- **Monitoring**: Complete Azure Monitor Agent deployment with VM Insights
- **Backup**: Automated backup enrollment via tags
- **Configuration Management**: Guest Configuration for compliance and settings
- **Patching**: Infrastructure ready for Azure Update Management

### Policy-Driven Automation

- **DeployIfNotExists policies**: Automatically configure VMs as they're deployed
- **Remediation tasks**: Automatically fix existing non-compliant VMs
- **Tag-based targeting**: Precise control over which VMs receive configurations

### Identity and Security

- **Managed Identities**: No credential management required
- **Role-Based Access Control**: Least privilege role assignments
- **Secure Configuration Delivery**: Guest Configuration packages via managed identity

### Flexibility

- **Generic Guest Configuration Policy**: Deploy any configuration package
- **Modular Design**: Easy to extend with additional modules
- **Parameter-Driven**: Customize per environment without code changes

## Using the Deployed Infrastructure

### For New VMs

When you deploy a new Windows VM in the subscription:

1. **Azure Monitor Agent** will be automatically deployed (via policy)
2. If you tag the VM with `Backup: Standard`, it will be enrolled in backup
3. If you tag the VM with `guestConfig: Applied`, it will receive the Guest Configuration package

### Policy Compliance and Remediation

View policy compliance:

```bash
az policy state list --resource-group "your-rg-name"
```

Trigger manual remediation:

```bash
az policy remediation create \
  --policy-assignment "assign-lz-guest-config-prod" \
  --name "remediation-task-name"
```

### Applying DSC Configuration to VMs

The included DSC configuration provides additional VM hardening:

```powershell
# Import the configuration
. .\pwsh\dsc\AzureLandingZoneVM.ps1

# Generate MOF files
AzureLandingZoneVM -ComputerName "VM-Name" -OutputPath "C:\DSC"

# Apply configuration
Start-DscConfiguration -Path "C:\DSC" -Wait -Verbose
```

## Troubleshooting

### Common Issues

1. **Deployment Failures**
   - Verify you have the correct permissions (Contributor or Owner at subscription level)
   - Ensure the shared resource group exists before deployment
   - Check parameter file values for correctness
   - Review deployment logs in Azure portal

2. **Policy Not Applying**
   - Allow 15-30 minutes for policy evaluation cycle
   - Check that VMs have the correct tags
   - Verify policy assignment is in "Default" enforcement mode
   - Review policy compliance in Azure portal

3. **Guest Configuration Issues**
   - Ensure the Guest Configuration package URI is accessible
   - Verify the content hash matches the package
   - Check that the UAMI has Storage Blob Data Reader role on the storage account
   - Confirm VMs have the `guestConfig: Applied` tag

4. **Backup Not Enrolling**
   - Verify VMs have the `Backup: Standard` tag
   - Check that backup policy remediation task has completed
   - Ensure the Recovery Services Vault is in the same region as VMs

### Viewing Logs and Diagnostics

- **Deployment logs**: Azure Portal > Resource Group > Deployments
- **Policy compliance**: Azure Portal > Policy > Compliance
- **Policy remediation**: Azure Portal > Policy > Remediation
- **VM extensions**: Azure Portal > Virtual Machine > Extensions + applications

## Extending the Landing Zone

### Adding New Policies

1. Create policy definition JSON in `policies/policyDefinitions/`
2. Add policy deployment to `bicep/modules/policy.bicep`
3. Create policy assignment in `main.bicep`
4. Add necessary role assignments for remediation

### Customizing Guest Configuration

1. **Create a custom Guest Configuration package**:
   - Build DSC configuration or use Chef InSpec
   - Package as .zip file
   - Upload to blob storage
2. **Update parameters**:
   - Set `guestConfigurationContentUri`
   - Calculate and set `guestConfigurationContentHash`
   - Update `guestConfigurationName` and version
3. **Deploy** and tag target VMs

### Adding Monitoring Rules

Add additional Data Collection Rules in `main.bicep`:

- Windows Event Logs
- Performance counters
- Syslog (for Linux)
- Custom logs

## Outputs

The deployment provides the following outputs:

- **resourceGroupNames**: Names of created resource groups
- **monitoringInfo**: Log Analytics and DCR resource IDs
- **backupInfo**: Recovery Services Vault and policy IDs
- **policyInfo**: Policy set and assignment IDs
- **identityInfo**: Managed identity resource IDs
- **guestConfigPolicyInfo**: Guest Configuration policy and assignment IDs

## Support

For questions and issues:

- Review documentation in the `docs/` folder
- Check Azure Policy compliance for configuration issues
- Review deployment logs in Azure Portal
- Create GitHub issues for bugs or feature requests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in a dev environment
5. Submit a pull request
