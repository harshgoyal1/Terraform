provider "azurerm" { 
    version = "=2.0.0"
  features {}

    subscription_id = "b616044f-0c6e-46e7-87e8-3ba295723db7"
    client_id = "d75ff049-5a9d-40bc-a60c-1c5be2d1ad51"
    client_secret = "5du_7hT3_72z-Tgse.hB797V84vV4JHE-v"
    tenant_id = "d08718f4-1a78-4344-bf15-2a283cb16d36"
  
}
 
resource "azurerm_resource_group" "resource_gp" {
name = "hello"
location = "eastus2"
  
}
