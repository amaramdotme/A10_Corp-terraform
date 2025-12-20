environment = "stage"

# Networking Configuration
vnet_address_space    = ["10.1.0.0/16"]
subnet_aks_prefix     = ["10.1.0.0/22"] # 10.1.0.0 - 10.1.3.255
subnet_ingress_prefix = ["10.1.4.0/26"] # 10.1.4.0 - 10.1.4.63