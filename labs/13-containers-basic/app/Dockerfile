# Lab 13 · optional cloud build with ACR Tasks
#
#   az acr build --registry "$ACR_NAME" --image storefront:v1-built ./app
#
# The image starts from the same Microsoft sample the lab imports and adds one small
# layer: a new default page title. Your layer sits on top of someone else's layers,
# which is exactly how most real images are built.
FROM mcr.microsoft.com/azuredocs/aks-helloworld:v1

# The sample app shows the TITLE environment variable as its page title.
ENV TITLE="Nusantara Retail storefront (built with ACR Tasks)"

# Documents the port the web server listens on. The target port in Container Apps
# (or --ports in Container Instances) is what actually routes traffic to it.
EXPOSE 80
