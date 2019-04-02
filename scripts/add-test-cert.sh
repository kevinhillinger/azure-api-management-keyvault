# references
# https://www.noelbundick.com/posts/importing-certificates-to-key-vault/

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

# Download the secret (private key information) associated with the cert to verify
# az keyvault secret download --vault-name $keyvault -n $cert -e base64 -f private_key.pem
