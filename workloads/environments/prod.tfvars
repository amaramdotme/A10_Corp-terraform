environment = "prod"

# Networking Configuration
vnet_address_space    = ["10.2.0.0/16"]
subnet_aks_prefix     = ["10.2.0.0/22"] # 10.2.0.0 - 10.2.3.255
subnet_ingress_prefix = ["10.2.4.0/26"] # 10.2.4.0 - 10.2.4.63