# https://learn.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/publish-service-catalog-app?tabs=azure-cli#create-the-managed-application-definition
# https://learn.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/deploy-service-catalog-quickstart?tabs=azure-cli

az login --tenant b0a60979-d5b1-4ed0-8f4d-d2a08559efce

az group create --name packageStorageGroup --location westus3

az storage account create \
    --name <demostorageaccount> \
    --resource-group packageStorageGroup \
    --location westus3 \
    --sku Standard_LRS \
    --kind StorageV2

# After you create the storage account, add the role assignment Storage Blob Data Contributor to the storage account scope. 
# Assign access to your Microsoft Entra user account. Depending on your access level in Azure, you might need other permissions 
# assigned by your administrator. For more information, see Assign an Azure role for access to blob data.
# After you add the role to the storage account, it takes a few minutes to become active in Azure. 
# You can then use the parameter --auth-mode login in the commands to create the container and upload the file.

az storage container create \
    --account-name <demostorageaccount> \
    --name appcontainer \
    --auth-mode login \
    --public-access blob

az storage blob upload \
    --account-name <demostorageaccount> \
    --container-name appcontainer \
    --auth-mode login \
    --name "ManagedApplicationSilverPlan.zip" \
    --file "ManagedApplicationSilverPlan.zip"