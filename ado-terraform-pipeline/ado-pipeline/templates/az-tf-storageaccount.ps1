#------------------------------------------------#
# az-tf-storageaccount.ps1
# author: matthew.clark@avanade.com
#   1) First checks the subscription if the storage account exists
#   2) If the storage account doesn't exist in the current subscription
#       -- Verifies storage account name is valid/available using Azure REST API
#       -- Verifies the Resource Group (Creates if it doesn't exist in the current subscription)
#       -- Creates Storage Account
#   3) Verifies the Container exists on the Storage Account
# Params:
#   ResourceGroupName
#       The name of the resource Group
#       Required: Yes
#       Alias: rg
#   Location
#       The location/region your resources will be deployed
#       Required: Yes
#       Alias: l
#   Storage Account Name
#       The name of the storage account. Must follow Azure requirements. This script does not verify the name before attempting to create.
#       Required: yes
#       Alias: sa
#   Container Name
#       The name of the container to store the TFSTATE file.
#       Required: yes
#       Alias: c
# Example: 
#   ./az-tf-storageaccount.ps1 -rg example -l eastus -sa examplestorageaccount -c examplecontainername
#
#   Azure CLI command will output details on errors
#------------------------------------------------#
[CmdletBinding()]
param(
    [Parameter(mandatory=$true)]
    [Alias("rg")] 
    [string] $ResourceGroupName,
    [Parameter(mandatory=$true)]
    [Alias("l")]
    [string] $Location,
    [Parameter(mandatory=$true)]
    [Alias("sa")]
    [string] $StorageAccountName,
    [Parameter(mandatory=$true)]
    [Alias("c")]
    [string] $ContainerName    
)

# Check Storage Account
Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | Checking Storage Account: $($StorageAccountName)"
if(!(az storage account show --name $StorageAccountName --resource-group $ResourceGroupName)) {

# The Storage Account doesn't exist in the Subscription -- Verify Name is Available
    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO |         Checking SA Name: $($StorageAccountName)"
# Verifiy Name
    $AZ_OUTPUT = (az storage account check-name --name $StorageAccountName | ConvertFrom-Json)

    if(!($AZ_OUTPUT.nameAvailable)) {
        Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | $($AZ_OUTPUT.Message)"
        throw "Failed: SA Name is either invalid or unavailable"
    }

    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | Done..."

    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO |  Checking Resource Group: $($ResourceGroupName)"
    if(! (az group show --name $ResourceGroupName)) {
        Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO |  Creating Resource Group: $($ResourceGroupName)"
        az group create --location $Location --name $ResourceGroupName --output none
        if(!$?) {
            throw "Failed: Error Creating Resource Group"
        }
    }
    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | Done..."

    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | Creating Storage Account: $($StorageAccountName)"
    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO |                   Region: $($Location)"
    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO |                      sku: Standard_LRS"

    az storage account create --name $StorageAccountName --resource-group $ResourceGroupName --location $Location --sku Standard_LRS --output none
    if(!$?) {
        throw "Failed: There was an error Creating Storage Account"
    }
    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | Done..."
} else {
    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | Done..."
}

# Check Container
Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO |       Checking Container: $($ContainerName)"
$key = $(az storage account keys list --resource-group $ResourceGroupName --account-name $StorageAccountName --query [0].value -o json)
if(! (az storage container show --name $containerName --account-name $StorageAccountName --account-key $key)) {
    Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO |       Creating Container: $($ContainerName)"
    az storage container create --name $containerName --account-name $StorageAccountName --account-key $key --output none
    if(!$?) {
        throw "Failed Creating Container"
    }
}
Write-Host "$(Get-Date -Format "yyyy-MM-dd | HH:mm:ss") | INFO | Done..."