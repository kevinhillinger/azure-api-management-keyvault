#!/bin/bash

rg=apim
location=eastus2
vnet=apim-vnet

az group create --name $rg --location $location
az network vnet create -n $vnet -g $rg -l $location \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefixes 10.0.0.0/24

# there is no cli support for azure APIM :(
# create it from the portal with developer tier, join to vnet
randomid=$((1 + RANDOM % 10000))

keyvault=apim-vault-$randomid

az keyvault create --name $keyvault -g $rg -l $location

# secure the key vault
az network vnet subnet update --resource-group $rg \
  --vnet-name $vnet \
  --name default \
  --service-endpoints "Microsoft.KeyVault"

subnetid=$(az network vnet subnet show --resource-group $rg --vnet-name $vnet --name default --query id --output tsv)
az keyvault network-rule add --resource-group $rg --name $keyvault --subnet $subnetid
az keyvault network-rule add --resource-group $rg --name $keyvault --ip-address "10.0.0.0/16"

# azure services allow
az keyvault update --resource-group $rg --name $keyvault --bypass AzureServices 

# enable the service endpoint rules
az keyvault update --resource-group $rg --name $keyvault --default-action Deny
  
