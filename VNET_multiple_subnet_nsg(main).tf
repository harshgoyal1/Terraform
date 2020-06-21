variable "vnet_name" {
  description = "Name of the vnet to create"
  default     = "acctvnet"
}

variable "resource_group_name" {
  description = "Name of the resource group to be imported."
}

variable "address_space" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
  default     = ["10.0.0.0/16"]
}

# If no values specified, this defaults to Azure DNS 
variable "dns_servers" {
  description = "The DNS servers to be used with vNet."
  default     = []
}

variable "subnet_prefixes" {
  description = "The address prefix to use for the subnet."
  default     = ["10.0.1.0/24" , "10.0.2.0/24" , "10.0.3.0/24"]
}

variable "subnet_names" {
  description = "A list of public subnets inside the vNet."
  default     = ["subnet1", "subnet2", "subnet3"]
}

variable "nsg_ids" {
  description = "A map of subnet name to Network Security Group IDs"
  type        = map(string)

  default = {
  }
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)

  default = {
    ENV = "test"
  }
}



provider "azurerm" { 
    version = "=2.0.0"
  features {}

    subscription_id = "b616044f-0c6e-46e7-87e8-3ba295723db7"
    client_id = "d75ff049-5a9d-40bc-a60c-1c5be2d1ad51"
    client_secret = "5du_7hT3_72z-Tgse.hB797V84vV4JHE-v"
    tenant_id = "d08718f4-1a78-4344-bf15-2a283cb16d36"
  
}
 
#Azure Generic vNet Module
data azurerm_resource_group "vnet" {
  name = var.resource_group_name
}


resource azurerm_virtual_network "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.vnet.name
  location            = data.azurerm_resource_group.vnet.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  count                = length(var.subnet_names)
  name                 = var.subnet_names[count.index]
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.subnet_prefixes[count.index]
}

data "azurerm_subnet" "import" {
  for_each             = var.nsg_ids
  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.vnet.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = ["azurerm_subnet.subnet"]
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each                  = var.nsg_ids
  subnet_id                 = data.azurerm_subnet.import[each.key].id
  network_security_group_id = each.value

  depends_on = ["data.azurerm_subnet.import"]
}

