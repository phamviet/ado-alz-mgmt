#!/usr/local/bin/pwsh

Import-Module Az.Resources

# Prepare environment variables from parameters.json
$fileName = "parameters.json"
Write-Host "Getting variables from $fileName"
$json = Get-Content -Path $fileName | ConvertFrom-Json

foreach ($key in $json.PSObject.Properties) {
    $envVarName = $key.Name
    $envVarValue = $key.Value
    Set-Item -Path "env:$envVarName" -Value $envVarValue
    echo "Set $envVarName to $envVarValue"
}

$displayName = "Networking-Hub Networking"
$name = "networking-hubnetworking"
$deploymentType = "subscription"
$templateFilePath = "templates/networking/hubnetworking/main.bicep"
$templateParametersFilePath = "templates/networking/hubnetworking/main.bicepparam"
$subscriptionId = $ENV:SUBSCRIPTION_ID_CONNECTIVITY
$tenantId = "28cb1194-6cd9-4b16-ba7b-e10a71c8059c"
$location = $ENV:LOCATION


$intRootMgId = $env:MANAGEMENT_GROUP_ID_PREFIX + $env:INTERMEDIATE_ROOT_MANAGEMENT_GROUP_ID + $env:MANAGEMENT_GROUP_ID_POSTFIX
$deploymentPrefix = $intRootMgId
$deploymentNameBase = $name.Replace(" ", "-")
$deploymentNameMaxLength = 64 - $deploymentPrefix.Length - 1
if ($deploymentNameBase.Length -gt $deploymentNameMaxLength) {
    $deploymentNameBase = $deploymentNameBase.Substring(0, $deploymentNameMaxLength)
}
$deploymentName = "$deploymentPrefix-$deploymentNameBase"

Write-Host "================================================" -ForegroundColor Blue
Write-Host "Starting Deployment Stack for $deploymentName" -ForegroundColor Blue
Write-Host "================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Display Name: $displayName" -ForegroundColor DarkGray
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

$result = New-AzSubscriptionDeploymentStack @stackParameters -Location $location

if ($result.ProvisioningState -eq "Succeeded") {
    $finalSuccess = $true
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "✓ Deployment Stack Succeeded: $deploymentName" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Error "Deployment stack finished with state: $($result.ProvisioningState)"
    exit 1
}