# Azure web application deployment instructions

## Create a resource group

```bash
az group create --location northeurope --name itis
```

## Builing an image

```bash
docker build . -t hws
```

Test your build:
```bash
docker run --rm -p 8000:80 hws
```

And open [localhost:8000](http://localhost:8000).
You should see

```plain
Hello, world! Running ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-linux-musl]
```

## Publish your image to Azure Registry
https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli

```bash
# Create remote registry
az acr create --resource-group itis --name cosmoreg --sku Basic --admin-enabled true

# Sign in to the registry
az acr login -n cosmoreg

# Upload new image to the registry
docker tag hws cosmoreg.azurecr.io/hws:v1
docker push cosmoreg.azurecr.io/hws:v1

# list containers
az acr repository list -n cosmoreg
```

## Creating plan

```bash
az appservice plan create --name paid --resource-group itis --sku B1 --is-linux
```

## Deploy your app

```bash
az webapp create --name hello-world-sinatra \
    --plan paid --resource-group itis \
    --deployment-container-image-name cosmoreg.azurecr.io/hws:v1

# VVV YOU DON'T NEED THIS VVV
# Set environment variables if needed
# az webapp config appsettings set \
#     --resource-group itis --name hello-world-sinatra \
#     --settings PORT=8000

az webapp identity assign --resource-group itis \
    --name hello-world-sinatra --query principalId --output tsv
# Remember the id ^^^
export PRINCIPAL_ID="..."

az account show --query id --output tsv
# Remember this id too ^^^
export SUBSCRIPTION_ID="..."

az ad sp create-for-rbac --name AppServiceReadFromParticularACR

az role assignment create --assignee $PRINCIPAL_ID \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/itis/providers/Microsoft.ContainerRegistry/registries/cosmoreg" \
    --role "AcrPull"
# Maybe you need it, it shows credentails for container registry
az acr credential show --resource-group itis --name cosmoreg

az webapp config container set \
    --name hello-world-sinatra --resource-group itis \
    --docker-custom-image-name cosmosreg.azurecr.io/hws:v1 \
    --docker-registry-server-url https://cosmosreg.azurecr.io \
    --docker-registry-server-user cosmoreg \
    --docker-registry-server-password "w=R504dEut8c3yxnaLat8CPmFCjhfGX2"

# YOU DON'T NEED THIS ^^^
```

## DNS

```bash
az network dns zone create --name d.itiscloud.ru -g itis

az network dns record-set a add-record \
    -g itis --zone-name d.itiscloud.ru \
    --record-set-name "@" \
    --ipv4-address "13.74.252.44"

az network dns record-set txt add-record \
    -g itis --zone-name d.itiscloud.ru \
    --record-set-name "@" \
    --value "6BFD40F178DB4984CD9382873DA90DCBDE9A4E6D99A55B737C5CFFD49411EA8B"

az network dns record-set cname set-record \
    -g itis --zone-name d.itiscloud.ru \
    --record-set-name www \
    --cname d.itiscloud.ru

az network dns record-set txt add-record \
    -g itis --zone-name d.itiscloud.ru \
    --record-set-name asuid \
    --value "6bfd40f178db4984cd9382873da90dcbde9a4e6d99a55b737c5cffd49411ea8b"
```
