locals {
  resource_group_name="AZ-305-RG"
  location="North Europe"

  virtual_network={
    name="App-VNET"
    address_space="10.0.0.0/16"
  }

  subnet = [
    {
      name="SubnetA"
      address_prefix="10.0.1.0/24"
    },
    {
      name="SubnetB"
      address_prefix="10.0.2.0/24"
    }
  ]
}
