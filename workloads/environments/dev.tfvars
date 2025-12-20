environment = "dev"

# Networking Configuration
vnet_address_space    = ["10.0.0.0/16"]
subnet_aks_prefix     = ["10.0.0.0/22"] # 10.0.0.0 - 10.0.3.255
subnet_ingress_prefix = ["10.0.4.0/26"] # 10.0.4.0 - 10.0.4.63