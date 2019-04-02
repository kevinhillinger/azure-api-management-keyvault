#!/bin/bash

# Resources
# https://docs.microsoft.com/en-us/azure/key-vault/key-vault-manage-with-cli2

keyvault=$(az keyvault list -g $rg --query '[?name.starts_with(@, `apim`)].name' --output tsv)

# create the service principal
sp_name="apim-${keyvault}"
sp=$(az ad sp create-for-rbac -n $sp_name --skip-assignment --output json)
sp_id=$(echo $sp | jq .appId -r)

# assign the service principal to the vault to allow read permission on the certificates
az keyvault set-policy --name $keyvault \
  --spn $sp_id \
  --certificate-permissions get \
  --secret-permissions get