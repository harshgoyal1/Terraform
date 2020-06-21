variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}


provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "=2.0.0"
    features {}

    subscription_id = "b616044f-0c6e-46e7-87e8-3ba295723db7"
    client_id = "d75ff049-5a9d-40bc-a60c-1c5be2d1ad51"
    client_secret = "5du_7hT3_72z-Tgse.hB797V84vV4JHE-v"
    tenant_id = "d08718f4-1a78-4344-bf15-2a283cb16d36"

}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = var.prefix
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
    depends_on = ["azurerm_resource_group.myterraformgroup" ]
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    count                = tonumber(var.temp)
    name                 = "mySubnet${count.index}"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.0.${count.index}.0/24"
depends_on = ["azurerm_virtual_network.myterraformnetwork"]
}
# data "azurerm_subnet" "myterraformsubnet" {
#   for_each             = var.nsg_ids
#   name                 = each.key
#   resource_group_name  = azurerm_resource_group.myterraformgroup.name
#     virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
#     depends_on = ["azurerm_subnet.myterraformsubnet"]
# }

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    count                        = tonumber(var.temp)
    name                         = "myPublicIP${count.index}"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
    depends_on = ["azurerm_resource_group.myterraformgroup" ]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    count               = tonumber(var.temp)
    name                = "nsg${count.index}"
    location            = var.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
    depends_on = ["azurerm_resource_group.myterraformgroup" ]
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    count               = tonumber(var.temp)
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       =  azurerm_resource_group.myterraformgroup.name

    ip_configuration {
         
        name                          = "myNicConfiguration"
        subnet_id                     = element(azurerm_subnet.myterraformsubnet.*.id,count.index)
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = element(azurerm_public_ip.myterraformpublicip.*.id,count.index)
    }

    tags = {
        environment = "Terraform Demo"
    }
    depends_on = ["azurerm_subnet.myterraformsubnet","azurerm_public_ip.myterraformpublicip" ]
}

# resource "azurerm_subnet_network_security_group_association" "example" {
#   count                     = tonumber(var.temp)
#   subnet_id                 = each.key
#   network_security_group_id = azurerm_network_security_group.myterraformnsg[each.key].id

#   depends_on = ["data.azurerm_subnet.myterraformsubnet"]
#}

resource "azurerm_subnet_network_security_group_association" "example" {
count               = tonumber(var.temp)
  subnet_id                 = element(azurerm_subnet.myterraformsubnet.*.id,count.index)
  network_security_group_id = element(azurerm_network_security_group.myterraformnsg.*.id,count.index)
  depends_on = ["azurerm_subnet.myterraformsubnet"]
}

# Connect the security group to the network interface
# resource "azurerm_network_interface_security_group_association" "example" {
#     count               = tonumber(var.temp)
#    network_interface_id      = element(azurerm_network_interface.myterraformnic.*.id,count.index)
#     network_security_group_id = element(azurerm_network_security_group.myterraformnsg.*.id,count.index)

#     depends_on = ["azurerm_network_interface.myterraformnic"]
# }

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
   count                       = tonumber(var.temp)
    keepers = {
        
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    count                       = tonumber(var.temp)
    name                        = "diag${element(random_id.randomId.*.hex,count.index)}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
    depends_on = ["random_id.randomId"]
}
# Create virtual machine

resource "azurerm_linux_virtual_machine" "myterraformvm" {

    count                       = tonumber(var.temp)
    name                  = "VM-${count.index}"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [element(azurerm_network_interface.myterraformnic.*.id,count.index)]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk${count.index}"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "azureuser"
    admin_password = "Linux@123456"
    disable_password_authentication = false
        
    

    boot_diagnostics {
        storage_account_uri = element(azurerm_storage_account.mystorageaccount.*.primary_blob_endpoint,count.index)
    }

    tags = {
        environment = "Terraform Demo"
    }

    depends_on = ["azurerm_subnet_network_security_group_association.example","azurerm_storage_account.mystorageaccount"]
}


