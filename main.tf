module "vnet-hub" {
  source  = "./modules/terraform-azure-virtual-hub-network/"
  # version = "2.2.0"

  # By default, this module will create a resource group, proivde the name here
  # to use an existing resource group, specify the existing resource group name, 
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG. 
  resource_group_name = "rg-hub-vnet-eus-001"
  location            = "eastus"
  hub_vnet_name       = "default-hub"

  # Provide valid VNet Address space and specify valid domain name for Private DNS Zone.  
  vnet_address_space             = ["10.1.0.0/16"]
  firewall_subnet_address_prefix = ["10.1.0.0/26"]
  gateway_subnet_address_prefix  = ["10.1.1.0/27"]
  # private_dns_zone_name          = "privatecloud.ashutoshkrm.com"

  # (Required) To enable Azure Monitoring and flow logs
  # Log Retention in days - Possible values range between 30 and 730
  log_analytics_workspace_sku          = "PerGB2018"
  log_analytics_logs_retention_in_days = 30

  # Adding Standard DDoS Plan, and custom DNS servers (Optional)
  dns_servers = []

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # NSG association to be added automatically for all subnets listed here.
  # First two address ranges from VNet Address space reserved for Gateway And Firewall Subnets. 
  # ex.: For 10.1.0.0/16 address space, usable address range start from 10.1.2.0/24 for all subnets.
  # subnet name will be set as per Azure naming convention by defaut. expected value here is: <App or project name>
  subnets = {
    mgnt_subnet = {
      subnet_name           = "management"
      subnet_address_prefix = ["10.1.2.0/24"]
      service_endpoints     = ["Microsoft.Storage"]

      nsg_inbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        ["ssh", "100", "Inbound", "Allow", "Tcp", "22", "*", ""],
        ["rdp", "200", "Inbound", "Allow", "Tcp", "3389", "*", ""],
      ]

      nsg_outbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        ["ntp_out", "300", "Outbound", "Allow", "Udp", "123", "", "0.0.0.0/0"],
      ]
    }

    dmz_subnet = {
      subnet_name           = "appgateway"
      subnet_address_prefix = ["10.1.3.0/24"]
      service_endpoints     = ["Microsoft.Storage"]
      nsg_inbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        # 65200-65335 port to be opened if you planning to create application gateway
        ["http", "100", "Inbound", "Allow", "Tcp", "80", "*", "0.0.0.0/0"],
        ["https", "200", "Inbound", "Allow", "Tcp", "443", "*", ""],
        ["appgwports", "300", "Inbound", "Allow", "Tcp", "65200-65335", "*", ""],

      ]
      nsg_outbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        ["ntp_out", "400", "Outbound", "Allow", "Udp", "123", "", "0.0.0.0/0"],
      ]
    }
  }

  # (Optional) To enable the availability zones for firewall. 
  # Availability Zones can only be configured during deployment 
  # You can't modify an existing firewall to include Availability Zones
  # firewall_zones = [1, 2, 3]

  # (Optional) specify the application rules for Azure Firewall
  # firewall_application_rules = [
  #   {
  #     name             = "microsoft"
  #     action           = "Allow"
  #     source_addresses = ["10.0.0.0/8"]
  #     target_fqdns     = ["*.microsoft.com"]
  #     protocol = {
  #       type = "Http"
  #       port = "80"
  #     }
  #   },
  # ]

  # (Optional) specify the Network rules for Azure Firewall
  # firewall_network_rules = [
  #   {
  #     name                  = "ntp"
  #     action                = "Allow"
  #     source_addresses      = ["10.0.0.0/8"]
  #     destination_ports     = ["123"]
  #     destination_addresses = ["*"]
  #     protocols             = ["UDP"]
  #   },
  # ]

  # (Optional) specify the NAT rules for Azure Firewall
  # Destination address must be Firewall public IP
  # `fw-public` is a variable value and automatically pick the firewall public IP from module.
  # firewall_nat_rules = [
  #   {
  #     name                  = "testrule"
  #     action                = "Dnat"
  #     source_addresses      = ["10.0.0.0/8"]
  #     destination_ports     = ["53", ]
  #     destination_addresses = ["fw-public"]
  #     translated_port       = 53
  #     translated_address    = "8.8.8.8"
  #     protocols             = ["TCP", "UDP", ]
  #   },
  # ]

  # Adding TAG's to your Azure resources (Required)
  # ProjectName and Env are already declared above, to use them here, create a varible. 
  tags = {
    ProjectName  = "CR0068"
    Env          = "prod"
    Owner        = "ashutoshkrm@gmail.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}

data "azurerm_virtual_network" "hub-vnet" {
  name                = "vnet-default-hub-eastus"
  resource_group_name = "rg-hub-vnet-eus-001"
}

# data "azurerm_storage_account" "hub-st" {
#   name                = "stdiaglogs3hfeutdh"
#   resource_group_name = "rg-hub-demo-internal-shared-westeurope-001"
# }

# data "azurerm_log_analytics_workspace" "hub-logws" {
#   name                = "logaws-3hfeutdh-default-hub-westeurope"
#   resource_group_name = "rg-hub-vnet-eus-001"
# }

module "vnet-spoke" {
  source  = "./modules/terraform-azure-virtual-spoke-network"
 # version = "2.2.0"

  # By default, this module will create a resource group, proivde the name here
  # to use an existing resource group, specify the existing resource group name,
  # and set the argument to `create_resource_group = false`. Location will be same as existing RG.
  resource_group_name = "rg-spoke-vnet-eus-001"
  location            = "eastus"
  spoke_vnet_name     = "corp-spoke"

  # Specify if you are deploying the spoke VNet using the same hub Azure subscription
  is_spoke_deployed_to_same_hub_subscription = true

  # Provide valid VNet Address space for spoke virtual network.  
  vnet_address_space = ["10.2.0.0/16"]

  # Hub network details to create peering and other setup
  hub_virtual_network_id          = data.azurerm_virtual_network.hub-vnet.id
  # hub_firewall_private_ip_address = "10.1.0.4"
  # private_dns_zone_name           = "privatecloud.exashutoshkrmample.com"
  # hub_storage_account_id          = data.azurerm_storage_account.hub-st.id

  # (Required) To enable Azure Monitoring and flow logs
  # pick the values for log analytics workspace which created by Hub module
  # Possible values range between 30 and 730
  # log_analytics_workspace_id           = data.azurerm_log_analytics_workspace.hub-logws.id
  # log_analytics_customer_id            = data.azurerm_log_analytics_workspace.hub-logws.workspace_id
  # log_analytics_logs_retention_in_days = 30

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # Route_table and NSG association to be added automatically for all subnets listed here.
  # subnet name will be set as per Azure naming convention by defaut. expected value here is: <App or project name>
  subnets = {

    app_subnet = {
      subnet_name           = "applicaiton"
      subnet_address_prefix = ["10.2.1.0/24"]
      service_endpoints     = ["Microsoft.Storage"]

      nsg_inbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        ["ssh", "200", "Inbound", "Allow", "Tcp", "22", "*", ""],
        ["rdp", "201", "Inbound", "Allow", "Tcp", "3389", "*", ""],
      ]

      nsg_outbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        ["ntp_out", "203", "Outbound", "Allow", "Udp", "123", "", "0.0.0.0/0"],
      ]
    }

    db_subnet = {
      subnet_name           = "database"
      subnet_address_prefix = ["10.2.2.0/24"]
      service_endpoints     = ["Microsoft.Storage"]
      nsg_inbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        ["http", "100", "Inbound", "Allow", "Tcp", "80", "*", "0.0.0.0/0"],
        ["sql_port", "101", "Inbound", "Allow", "Tcp", "1433", "*", ""],
      ]

      nsg_outbound_rules = [
        # [name, priority, direction, access, protocol, destination_port_range, source_address_prefix, destination_address_prefix]
        # To use defaults, use "" without adding any value and to use this subnet as a source or destination prefix.
        ["ntp_out", "102", "Outbound", "Allow", "Udp", "123", "", "0.0.0.0/0"],
      ]
    }
  }

  # Adding TAG's to your Azure resources (Required)
  # ProjectName and Env are already declared above, to use them here, create a varible.
  tags = {
    ProjectName  = "CR0068"
    Env          = "prod"
    Owner        = "ashutoshkrm@gmail.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}