#!/usr/local/bin/pwsh

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("managementGroup", "subscription")]
    [string]$deploymentType,

    [Parameter(Mandatory = $true)]
    [string]$name,

    [Parameter(Mandatory = $true)]
    [string]$templateDir
)

Import-Module Az.Resources

$templateFilePath = Join-Path $templateDir "main.bicep"
$templateParametersFilePath = Join-Path $templateDir "main.bicepparam"

if (-not (Test-Path $templateFilePath)) {
    Write-Error "Template file not found: $templateFilePath"
    exit 1
}

if (-not (Test-Path $templateParametersFilePath)) {
    Write-Error "Template parameters file not found: $templateParametersFilePath"
    exit 1
}

# Prepare environment variables from parameters.json
$fileName = "parameters.json"
Write-Host "Getting variables from $fileName"
$json = Get-Content -Path $fileName | ConvertFrom-Json

foreach ($key in $json.PSObject.Properties) {
    $envVarName = $key.Name
    $envVarValue = $key.Value
    Set-Item -Path "env:$envVarName" -Value $envVarValue
    Write-Host "Set $envVarName to $envVarValue"
}

$subscriptionId = if ($deploymentType -eq "managementGroup") {
    $ENV:SUBSCRIPTION_ID_MANAGEMENT
} else {
    $ENV:SUBSCRIPTION_ID_CONNECTIVITY
}

$tenantId = $ENV:TENANT_ID
$location = $ENV:LOCATION

$intRootMgId = $env:MANAGEMENT_GROUP_ID_PREFIX + $env:INTERMEDIATE_ROOT_MANAGEMENT_GROUP_ID + $env:MANAGEMENT_GROUP_ID_POSTFIX
$deploymentPrefix = $intRootMgId
$deploymentNameBase = $name.Replace(" ", "-")
$deploymentNameMaxLength = 64 - $deploymentPrefix.Length - 1

if ($deploymentNameMaxLength -lt 1) {
    Write-Error "Deployment prefix is too long to create a valid deployment name: $deploymentPrefix"
    exit 1
}

if ($deploymentNameBase.Length -gt $deploymentNameMaxLength) {
    $deploymentNameBase = $deploymentNameBase.Substring(0, $deploymentNameMaxLength)
}

$deploymentName = "$deploymentPrefix-$deploymentNameBase"

Write-Host "================================================" -ForegroundColor Blue
Write-Host "Starting Deployment Stack for $deploymentName" -ForegroundColor Blue
Write-Host "================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Deployment Name: $deploymentName" -ForegroundColor DarkGray
Write-Host "Template File Path: $templateFilePath" -ForegroundColor DarkGray
Write-Host "Template Parameters File Path: $templateParametersFilePath" -ForegroundColor DarkGray
Write-Host "Management Group Id: $intRootMgId" -ForegroundColor DarkGray
Write-Host "Subscription Id: $subscriptionId" -ForegroundColor DarkGray
Write-Host "Location: $location" -ForegroundColor DarkGray
Write-Host "Deployment Type: $deploymentType" -ForegroundColor DarkGray
Write-Host ""

$stackParameters = @{
    Name                  = $deploymentName
    TemplateFile          = $templateFilePath
    TemplateParameterFile = $templateParametersFilePath
    DenySettingsMode      = "None"
    ActionOnUnmanage      = "DeleteAll"
    Force                 = $true
    Verbose               = $true
}

Connect-AzAccount -TenantId $tenantId -SubscriptionId $subscriptionId

if ($deploymentType -eq "managementGroup") {
    # Clean up all deployments before each management group deployment to avoid quota issues.
    try {
        Write-Host "Cleaning up existing deployments in management group..." -ForegroundColor Cyan
        $allDeployments = Get-AzManagementGroupDeployment -ManagementGroupId $intRootMgId -ErrorAction SilentlyContinue
        if ($allDeployments -and $allDeployments.Count -gt 0) {
            Write-Host "Found $($allDeployments.Count) deployment(s) to clean up" -ForegroundColor Yellow
            $batchSize = 200
            for ($i = 0; $i -lt $allDeployments.Count; $i += $batchSize) {
                $batch = $allDeployments | Select-Object -Skip $i -First $batchSize
                Write-Host "  Deleting batch of $($batch.Count) deployments..." -ForegroundColor Gray
                $batch | ForEach-Object -Parallel {
                    Remove-AzManagementGroupDeployment -ManagementGroupId $using:intRootMgId -Name $_.DeploymentName -ErrorAction SilentlyContinue
                } -ThrottleLimit 100
            }
            Write-Host "All deployments cleaned up" -ForegroundColor Green
        } else {
            Write-Host "No deployments to clean up" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not clean up deployments: $($_.Exception.Message)"
    }

    Write-Host "Creating Management Group Deployment Stack: $deploymentName" -ForegroundColor Cyan
    $result = New-AzManagementGroupDeploymentStack @stackParameters -ManagementGroupId $intRootMgId -Location $location
} else {
    Write-Host "Creating Subscription Deployment Stack: $deploymentName" -ForegroundColor Cyan
    $result = New-AzSubscriptionDeploymentStack @stackParameters -Location $location
}

if ($result.ProvisioningState -eq "Succeeded") {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "Deployment Stack Succeeded: $deploymentName" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Error "Deployment stack finished with state: $($result.ProvisioningState)"
    exit 1
}
