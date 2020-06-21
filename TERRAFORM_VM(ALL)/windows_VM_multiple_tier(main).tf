

# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

    subscription_id = "b616044f-0c6e-46e7-87e8-3ba295723db7"
    client_id = "d75ff049-5a9d-40bc-a60c-1c5be2d1ad51"
    client_secret = "5du_7hT3_72z-Tgse.hB797V84vV4JHE-v"
    tenant_id = "d08718f4-1a78-4344-bf15-2a283cb16d36"

}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
    count              = tonumber(var.temp)
  name                 = "internal${count.index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.${count.index}.0/24"
}

resource "azurerm_network_interface" "main" {
    count              = tonumber(var.temp)
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal${count.index}"
    subnet_id                     = element(azurerm_subnet.internal.*.id,count.index)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
    count              = tonumber(var.temp)
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "Password@1234"
  network_interface_ids = [
    element(azurerm_network_interface.main.*.id,count.index)
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}
