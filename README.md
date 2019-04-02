# API Management integration with Azure Key Vault

## Design

<img src="https://github.com/kevinhillinger/azure-api-management-keyvault/raw/master/docs/diagram.png" width="400" />

## Overview

The integration requires that a service principal is registered in the Azure AD tenant for the subscription that the Key Vault instance belongs to. Then we're going to authorize it to talk to key vault.

```bash
keyvault=$(az keyvault list -g $rg --query '[?name.starts_with(@, `apim`)].name' --output tsv)

# create the service principal
sp_name="apim-${keyvault}"
sp=$(az ad sp create-for-rbac -n $sp_name --skip-assignment --output json)
sp_id=$(echo $sp | jq .appId -r)

```

Here is the assignments to allow the read of certs and secrets from the vault.

```
az keyvault set-policy --name $keyvault \
  --spn $sp_id \
  --certificate-permissions get \
  --secret-permissions get
  ```

  ## Inbound Policy Flow

API Management can be a real pain, editing XML documents (invalid XML at that) with embedded C#. Here is the flow:

1. Get a minted token (bearer) from Azure AD (make sure the scope is properly set for Key Vault)
2. Get the response and set a variable with the token value
3. Send a request to Key Vault with Authorization header loaded up with the token
4. Get the certificate info
5. Fetch the entire PFX file in base64
6. Send the client certificate along in the payload to the backend

  > Note: Because this is a costly operation (latency rountrip), I'm caching it in this example.