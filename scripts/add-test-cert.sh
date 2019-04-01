# references
# https://www.noelbundick.com/posts/importing-certificates-to-key-vault/

keyvault=$(az keyvault list -g $rg --query '[?name.starts_with(@, `apim`)].name' --output tsv)
cert=cert1
pfx=cert1.pfx

# Tell Key Vault to create a certificate with the default policy
az keyvault certificate create --vault-name $keyvault -n $cert -p "$(az keyvault certificate get-default-policy -o json)"
 
# Download the secret (private key information) associated with the cert
az keyvault secret download --vault-name $keyvault -n $cert -e base64 -f $pfx
