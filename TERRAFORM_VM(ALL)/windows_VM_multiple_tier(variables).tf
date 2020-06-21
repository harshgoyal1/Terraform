variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "terraharsh"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "eastus"
}
variable "temp" {
    description = "enter total no of vm to be deploy"
    default = 6
}
# variable "eachsub" {
#   description = "enter no of vm to be deploy in each subnet"
#     default = 2
# }

variable "subnet" {
    description = "the name of subnet you need to identify"
    default = ["web", "app" , "db" ]
  
}
variable "substr" {
    default = "/subscriptions/b616044f-0c6e-46e7-87e8-3ba295723db7resourceGroups/terraharsh/providers/Microsoft.Network/virtualNetworks/terraharsh-network/subnets/"
  
}

variable "subnet_ids" {
    default = [
       "app","app","web","web","db","db",
           ]
  
}
