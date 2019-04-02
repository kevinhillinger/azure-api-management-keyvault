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

API Management can be a tough experience editing XML documents (invalid XML) with embedded C#. It can often be missed is that the XML is "fall through". In other words, treat it as top down execution. Here is the flow for the integration of Azure Key Vault:

1. Get a minted token (bearer) from Azure AD (make sure the scope is properly set for Key Vault)
2. Get the response and set a variable with the token value
3. Send a request to Key Vault with Authorization header loaded up with the token
4. Get the certificate info
5. Fetch the entire PFX file in base64
6. Send the client certificate along in the payload to the backend

  > Note: Because this is a costly operation (latency rountrip), I'm caching it in this example.

## Test API
The client certificate test API uses badssl.

### Client Certificate
* Download the client certificate from [https://badssl.com/download/](https://badssl.com/download/)
* convert the file to a PFX (while you download)
* Import the certificate into key vault

```
rg=apim
keyvault=$(az keyvault list -g $rg --query '[?name.starts_with(@, `apim`)].name' --output tsv)
cert_file=./badssl.com-client.pfx
cert_name=badssl-client
cert_password=badssl.com
# download the p12 cert (password is badssl.com)

curl https://badssl.com/certs/badssl.com-client.p12 --output  $cert_file
cert_password=badssl.com

# import to keyvault
 az keyvault certificate import --vault-name $keyvault -n $cert_name -f $cert_file --password $cert_password -p "$(az keyvault certificate get-default-policy -o json)"
```